// Lesson 10: the picks of world.ts, simulated by Rapier in WebAssembly and drawn by three.js as one InstancedMesh.
// The loop steps the world at a fixed 1/60 s whatever the frame rate, and draws each pick between its last two states.
// ?build=standard loads @dimforge/rapier3d-compat instead of the deterministic build. When probed, the page steps the
// world 180 times without waiting for the clock, renders once, and reports the same state hash as scripts/l10-rapier.ts.
import * as THREE from 'three/webgpu';
import { backendName, forceWebGL, probing, report } from '../probe.ts';
import { buildFretboard } from '../05-picking/fretboard.ts';
import { createWorld, PICK_SIZE, PICKS, STEP, stateBytes, type Rapier } from './world.ts';

const params = new URLSearchParams(location.search);
const initStart = performance.now();
// A dynamic import: the 2.9 MB module becomes its own chunk, loaded after the page's code. The two packages declare the
// same classes separately, and classes with private members are only compatible with themselves: hence the cast.
const loaded = params.get('build') === 'standard' ? await import('@dimforge/rapier3d-compat') : await import('@dimforge/rapier3d-deterministic-compat');
const RAPIER = loaded.default as unknown as Rapier;
await RAPIER.init();
const initMs = performance.now() - initStart;

const renderer = new THREE.WebGPURenderer({ antialias: true, forceWebGL });
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.setSize(window.innerWidth, window.innerHeight);
document.body.append(renderer.domElement);

const scene = new THREE.Scene();
scene.background = new THREE.Color(0x1e2127);
scene.add(new THREE.HemisphereLight(0xdde6ff, 0x302820, 1.5));
const sun = new THREE.DirectionalLight(0xffffff, 2.5);
sun.position.set(1, 4, 3);
scene.add(sun);
scene.add(buildFretboard().board);
const floor = new THREE.Mesh(new THREE.PlaneGeometry(20, 20).rotateX(-Math.PI / 2), new THREE.MeshStandardMaterial({ color: 0x2b3038 }));
floor.position.y = -1;
scene.add(floor);

const camera = new THREE.PerspectiveCamera(40, window.innerWidth / window.innerHeight, 0.1, 100);
camera.position.set(0, 2.6, 3.4);
camera.lookAt(0, -0.2, 0);

const { world, picks } = createWorld(RAPIER);

// One InstancedMesh for the 24 picks: one draw call, one matrix per pick, written from the bodies every frame
const mesh = new THREE.InstancedMesh(
  new THREE.BoxGeometry(PICK_SIZE.x, PICK_SIZE.y, PICK_SIZE.z),
  new THREE.MeshStandardMaterial({ color: 0xffb454, roughness: 0.4 }),
  PICKS,
);
mesh.frustumCulled = false; // the picks move: the bounding sphere computed from the first matrices would go stale
scene.add(mesh);

// The state before and after the last step, to interpolate between them
type Pose = { position: THREE.Vector3; quaternion: THREE.Quaternion };
const pose = (): Pose => ({ position: new THREE.Vector3(), quaternion: new THREE.Quaternion() });
const previous = picks.map(pose);
const current = picks.map(pose);
function capture(target: Pose[]) {
  picks.forEach((body, i) => {
    const t = body.translation();
    const r = body.rotation();
    target[i].position.set(t.x, t.y, t.z);
    target[i].quaternion.set(r.x, r.y, r.z, r.w);
  });
}
capture(current);

const matrix = new THREE.Matrix4();
const unit = new THREE.Vector3(1, 1, 1);
const drawn = pose();
function draw(alpha: number) {
  for (let i = 0; i < PICKS; i++) {
    drawn.position.lerpVectors(previous[i].position, current[i].position, alpha);
    drawn.quaternion.slerpQuaternions(previous[i].quaternion, current[i].quaternion, alpha);
    mesh.setMatrixAt(i, matrix.compose(drawn.position, drawn.quaternion, unit));
  }
  mesh.instanceMatrix.needsUpdate = true;
}

let steps = 0;
function step() {
  for (let i = 0; i < PICKS; i++) {
    previous[i].position.copy(current[i].position);
    previous[i].quaternion.copy(current[i].quaternion);
  }
  world.step();
  capture(current);
  steps++;
}

// The accumulator: real time goes in, whole steps of 1/60 s come out, and what's left decides the interpolation.
// At most 5 steps per frame, so that a long pause (a background tab) doesn't freeze the page with hundreds of steps.
const timer = new THREE.Timer();
let accumulator = 0;
renderer.setAnimationLoop((time) => {
  if (probing) return;
  timer.update(time);
  accumulator = Math.min(accumulator + timer.getDelta(), 5 * STEP);
  while (accumulator >= STEP) {
    step();
    accumulator -= STEP;
  }
  draw(accumulator / STEP);
  renderer.render(scene, camera);
});

window.addEventListener('resize', () => {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
});

await renderer.init();
document.title = `Lesson 10 — ${backendName(renderer)}`;

if (probing) {
  const stepStart = performance.now();
  for (let i = 0; i < 180; i++) step();
  const stepMs = (performance.now() - stepStart) / 180;
  draw(1);
  renderer.render(scene, camera);
  const bytes = stateBytes(picks);
  const digest = await crypto.subtle.digest('SHA-256', bytes.slice().buffer);
  const hash = [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, '0')).join('').slice(0, 16);
  report(renderer, {
    rapier: RAPIER.version(),
    build: params.get('build') ?? 'deterministic',
    steps,
    asleep: picks.filter((body) => body.isSleeping()).length,
    stateHash: hash,
    initMs: Number(initMs.toFixed(1)),
    stepMs: Number(stepMs.toFixed(3)),
  });
}
