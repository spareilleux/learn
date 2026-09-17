// Experiment 4: pitch-class sets as 3D bracelets of 12 beads, all turning by a transposition step s, 0 to 12 semitones.
// A bead of pitch class k sits at angle (k + s) × 30° on its bracelet; set members are large and gold, the others small
// and dark. ?sets=4096 (every set) or 352 (one per transposition class); ?method=
// - cpu: one InstancedMesh, colors set once, the 12 × sets instance matrices recomputed and uploaded every frame;
// - tsl: one Mesh with an InstancedBufferGeometry (no instance matrices), the bead's center, pitch class, scale and color
//   as instance attributes, and its position computed in the vertex shader from a uniform s.
// Frame i shows s = (i mod 120) / 10; the screenshot shows s = 1.25.
import * as THREE from 'three/webgpu';
import { attribute, cos, float, positionLocal, sin, uniform, vec3 } from 'three/tsl';
import { ci, counters, createRenderer, finish, guard, measure, num, str } from '../lab.ts';
import { setsToDraw } from './pcs.ts';

const method = str('method', 'tsl');
const count = num('sets', 4096);
const width = num('w', 1280);
const height = num('h', 720);
const SPACING = 2.6;
const GOLD = new THREE.Color(0xe8b04a);
const DARK = new THREE.Color(0x69707e);

guard(async () => {
  const renderer = await createRenderer({ width, height });
  const scene = new THREE.Scene();
  scene.background = new THREE.Color(0x1e2127);
  scene.add(new THREE.HemisphereLight(0xdde6ff, 0x302820, 1.5));
  const sun = new THREE.DirectionalLight(0xffffff, 2.5);
  sun.position.set(1, 4, 3);
  scene.add(sun);

  const sets = setsToDraw(count);
  const columns = Math.ceil(Math.sqrt(sets.length));
  const beads = sets.length * 12;
  const center = (i: number) => new THREE.Vector3((i % columns) * SPACING, 0, Math.floor(i / columns) * SPACING);
  const bead = new THREE.SphereGeometry(0.2, 12, 8);
  const member = (i: number, k: number) => (sets[i] & (1 << k)) !== 0;
  let update: (s: number) => void;
  const setupStart = performance.now();

  if (method === 'cpu') {
    const mesh = new THREE.InstancedMesh(bead, new THREE.MeshStandardMaterial({ roughness: 0.4, metalness: 0.2 }), beads);
    mesh.instanceMatrix.setUsage(THREE.DynamicDrawUsage);
    for (let i = 0; i < sets.length; i++) for (let k = 0; k < 12; k++) mesh.setColorAt(i * 12 + k, member(i, k) ? GOLD : DARK);
    const centers = Float32Array.from(sets.flatMap((_, i) => center(i).toArray()));
    const array = mesh.instanceMatrix.array as Float32Array;
    update = (s) => {
      // The matrix of a scaled, translated bead, written directly: no rotation, so no Matrix4.compose needed
      for (let i = 0; i < sets.length; i++) {
        const cx = centers[i * 3];
        const cz = centers[i * 3 + 2];
        for (let k = 0; k < 12; k++) {
          const angle = ((k + s) * Math.PI) / 6;
          const scale = member(i, k) ? 1 : 0.55;
          const o = (i * 12 + k) * 16;
          array[o] = scale;
          array[o + 5] = scale;
          array[o + 10] = scale;
          array[o + 12] = cx + Math.cos(angle);
          array[o + 13] = 0;
          array[o + 14] = cz + Math.sin(angle);
          array[o + 15] = 1;
        }
      }
      mesh.instanceMatrix.needsUpdate = true;
    };
    update(0);
    mesh.computeBoundingSphere();
    mesh.frustumCulled = false;
    scene.add(mesh);
  } else {
    const geometry = new THREE.InstancedBufferGeometry();
    geometry.index = bead.index;
    for (const name of ['position', 'normal', 'uv']) geometry.setAttribute(name, bead.getAttribute(name));
    geometry.instanceCount = beads;
    const centers = new Float32Array(beads * 3);
    const pitchClass = new Float32Array(beads);
    const scales = new Float32Array(beads);
    const colors = new Float32Array(beads * 3);
    for (let i = 0; i < sets.length; i++) {
      const c = center(i);
      for (let k = 0; k < 12; k++) {
        const b = i * 12 + k;
        c.toArray(centers, b * 3);
        pitchClass[b] = k;
        scales[b] = member(i, k) ? 1 : 0.55;
        (member(i, k) ? GOLD : DARK).toArray(colors, b * 3);
      }
    }
    geometry.setAttribute('beadCenter', new THREE.InstancedBufferAttribute(centers, 3));
    geometry.setAttribute('pitchClass', new THREE.InstancedBufferAttribute(pitchClass, 1));
    geometry.setAttribute('beadScale', new THREE.InstancedBufferAttribute(scales, 1));
    geometry.setAttribute('beadColor', new THREE.InstancedBufferAttribute(colors, 3));
    const step = uniform(0);
    const material = new THREE.MeshStandardNodeMaterial({ roughness: 0.4, metalness: 0.2 });
    const angle = attribute<'float'>('pitchClass', 'float').add(step).mul(Math.PI / 6);
    material.positionNode = positionLocal.mul(attribute<'float'>('beadScale', 'float')).add(attribute<'vec3'>('beadCenter', 'vec3')).add(vec3(cos(angle), float(0), sin(angle)));
    material.colorNode = attribute<'vec3'>('beadColor', 'vec3');
    const mesh = new THREE.Mesh(geometry, material);
    mesh.frustumCulled = false;
    scene.add(mesh);
    update = (s) => void (step.value = s);
  }
  const setupMs = performance.now() - setupStart;

  const extent = columns * SPACING;
  const camera = new THREE.PerspectiveCamera(40, width / height, 0.1, 5000);
  const middle = new THREE.Vector3((extent - SPACING) / 2, 0, (Math.ceil(sets.length / columns) * SPACING - SPACING) / 2);
  camera.position.copy(middle).add(new THREE.Vector3(0, extent * 0.95, extent * 0.55));
  camera.lookAt(middle);

  const { stats, counters: c } = await measure(renderer, (i) => {
    update((i % 120) / 10);
    renderer.render(scene, camera);
  });
  update(1.25);
  renderer.render(scene, camera);
  finish(renderer, {
    method,
    sets: sets.length,
    beads,
    setupMs: Math.round(setupMs * 10) / 10,
    stats,
    counters: { drawCalls: c.drawCalls, triangles: c.triangles },
    checks: ci ? { firstSets: sets.slice(0, 12), lastSet: sets[sets.length - 1] } : undefined,
    info: counters(renderer),
  });
});
