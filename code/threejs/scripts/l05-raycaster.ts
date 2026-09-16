// Lesson 5: what a Raycaster finds, without a browser: node scripts/l05-raycaster.ts
// The fretboard and the camera are the page's; the ray goes through the screen point of string 3, fret 5.
import * as THREE from 'three/webgpu';
import { buildFretboard, fretAt, FRETS, fretX, NECK_TOP, noteName, pressPoint, stringAt, stringZ } from '../src/05-picking/fretboard.ts';

const { board, strings } = buildFretboard();
const scene = new THREE.Scene().add(board);
const camera = new THREE.PerspectiveCamera(40, 800 / 450, 0.1, 100);
camera.position.set(-0.2, 2.4, 1.6);
camera.lookAt(-0.2, 0.3, 0);
// A page renders before it raycasts, and rendering updates the world matrices; a script must do it itself, for the
// camera too, which isn't in the scene
scene.updateMatrixWorld();
camera.updateMatrixWorld();

const raycaster = new THREE.Raycaster();
const fixed = (v: THREE.Vector3) => v.toArray().map((n) => Number(n.toFixed(3)));
const list = (hits: THREE.Intersection[]) =>
  hits.length === 0
    ? '(none)'
    : hits.map((h) => `${h.object.name} at ${h.distance.toFixed(3)}${h.instanceId === undefined ? '' : `, instance ${h.instanceId}`}`).join(' | ');

const target = pressPoint(3, 5);
const ndc = new THREE.Vector2().copy(target.clone().project(camera));
console.log('pointer (NDC):', ndc.toArray().map((n) => Number(n.toFixed(4))));
raycaster.setFromCamera(ndc, camera);
console.log('ray origin', fixed(raycaster.ray.origin), 'direction', fixed(raycaster.ray.direction));

const hits = raycaster.intersectObject(board, true);
console.log('intersectObject(board, true):', list(hits));
const [first] = hits;
console.log('first hit:', { point: fixed(first.point), faceIndex: first.faceIndex, uv: first.uv && fixed(new THREE.Vector3(first.uv.x, first.uv.y, 0)).slice(0, 2) });
console.log(`fret ${fretAt(first.point.x)}, string ${stringAt(first.point.z)}: ${noteName(stringAt(first.point.z), fretAt(first.point.x)!)}`);
console.log('intersectObject(board, false):', list(raycaster.intersectObject(board, false)));

// A ray that passes over string 1: the thin string is hit before the neck
const overString = new THREE.Vector3((fretX(2) + fretX(3)) / 2, NECK_TOP + 0.035, stringZ(1));
raycaster.setFromCamera(new THREE.Vector2().copy(overString.clone().project(camera)), camera);
console.log('over string 1:', list(raycaster.intersectObject(board, true)));
// Layers: the raycaster tests layer 0 by default, so objects moved to layer 1 are skipped (and so is their rendering,
// unless the camera enables layer 1 too)
for (const string of strings) string.layers.set(1);
console.log('strings on layer 1:', list(raycaster.intersectObject(board, true)));
raycaster.layers.enable(1);
console.log('raycaster.layers.enable(1):', list(raycaster.intersectObject(board, true)));
raycaster.far = 2;
console.log('far = 2:', list(raycaster.intersectObject(board, true)));
raycaster.far = Infinity;

// No mesh at all: the same ray against the plane of the neck's top face
raycaster.setFromCamera(ndc, camera);
const plane = new THREE.Plane(new THREE.Vector3(0, 1, 0), -NECK_TOP);
console.log('ray.intersectPlane:', fixed(raycaster.ray.intersectPlane(plane, new THREE.Vector3())!));

// The frets as one InstancedMesh: one object, and the hit says which instance
const instanced = new THREE.InstancedMesh(new THREE.BoxGeometry(0.03, 0.03, 0.55), new THREE.MeshStandardMaterial(), FRETS);
const matrix = new THREE.Matrix4();
for (let n = 1; n <= FRETS; n++) instanced.setMatrixAt(n - 1, matrix.makeTranslation(fretX(n), NECK_TOP + 0.01, 0));
instanced.name = 'frets (instanced)';
const onFret4 = new THREE.Vector3(fretX(4), NECK_TOP + 0.02, stringZ(2));
raycaster.setFromCamera(new THREE.Vector2().copy(onFret4.clone().project(camera)), camera);
console.log('over fret 4, InstancedMesh:', list(raycaster.intersectObject(instanced)));

// The cost: 10,000 rays against the fretboard's 19 meshes, and against a plane
const time = (label: string, run: () => void) => {
  const start = performance.now();
  for (let i = 0; i < 10_000; i++) run();
  console.log(`${label}: ${((performance.now() - start) / 10).toFixed(2)} µs per ray`);
};
const out: THREE.Intersection[] = [];
time('10,000 × intersectObject(board, true)', () => {
  out.length = 0;
  raycaster.intersectObject(board, true, out);
});
time('10,000 × ray.intersectPlane', () => raycaster.ray.intersectPlane(plane, new THREE.Vector3()));
