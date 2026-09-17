// Experiment 7: a 6 × 6 grid of spheres under a studio environment (RoomEnvironment through PMREMGenerator), metalness
// from 0 (left) to 1 (right), roughness from 0 (top) to 1 (bottom), in the color of GA's frets (0xd8d0c0).
// ?material=standard (MeshStandardMaterial) or physical (MeshPhysicalMaterial with GA's clearcoat 0.35,
// clearcoatRoughness 0.18 and sheen 0.3, ThreeFretboard.tsx lines 960-1016); ?grid=1 shares one material among the 36.
// A marker ring shows GA's fret values (metalness 1, roughness 0.28) between the two nearest columns and rows.
import * as THREE from 'three/webgpu';
import { RoomEnvironment } from 'three/addons/environments/RoomEnvironment.js';
import { counters, createRenderer, finish, guard, measure, num, str } from '../lab.ts';

const kind = str('material', 'standard');
const shared = num('grid', 0) === 1;
const width = num('w', 1920);
const height = num('h', 1080);

guard(async () => {
  const renderer = await createRenderer({ width, height });
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  const scene = new THREE.Scene();
  scene.background = new THREE.Color(0x1e2127);
  const pmrem = new THREE.PMREMGenerator(renderer);
  scene.environment = pmrem.fromScene(new RoomEnvironment(), 0.04).texture;

  const make = (metalness: number, roughness: number) =>
    kind === 'physical'
      ? new THREE.MeshPhysicalMaterial({ color: 0xd8d0c0, metalness, roughness, clearcoat: 0.35, clearcoatRoughness: 0.18, sheen: 0.3 })
      : new THREE.MeshStandardMaterial({ color: 0xd8d0c0, metalness, roughness });
  const one = make(1, 0.28);
  const geometry = new THREE.SphereGeometry(0.46, 64, 32);
  for (let row = 0; row < 6; row++) {
    for (let column = 0; column < 6; column++) {
      const sphere = new THREE.Mesh(geometry, shared ? one : make(column / 5, row / 5));
      sphere.position.set(column - 2.5, 2.5 - row, 0);
      scene.add(sphere);
    }
  }
  const camera = new THREE.OrthographicCamera(-3.2 * (width / height), 3.2 * (width / height), 3.2, -3.2, 0.1, 20);
  camera.position.set(0, 0, 10);

  const compileStart = performance.now();
  await renderer.compileAsync(scene, camera);
  const compileMs = performance.now() - compileStart;
  const { stats, counters: c } = await measure(renderer, () => renderer.render(scene, camera));
  finish(renderer, {
    material: kind,
    sharedMaterial: shared,
    compileMs: Math.round(compileMs),
    stats,
    counters: { drawCalls: c.drawCalls, triangles: c.triangles, programs: c.programs },
    info: counters(renderer),
  });
});
