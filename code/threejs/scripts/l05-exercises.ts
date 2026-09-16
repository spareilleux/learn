// Lesson 5, exercises: node scripts/l05-exercises.ts
import * as THREE from 'three/webgpu';
import { buildFretboard, fretX, NECK_TOP, pressPoint, stringZ } from '../src/05-picking/fretboard.ts';

const camera = new THREE.PerspectiveCamera(40, 800 / 450, 0.1, 100);
camera.position.set(-0.2, 2.4, 1.6);
camera.lookAt(-0.2, 0.3, 0);
camera.updateMatrixWorld();
const raycaster = new THREE.Raycaster();
const aim = (point: THREE.Vector3) => raycaster.setFromCamera(new THREE.Vector2().copy(point.clone().project(camera)), camera);
const list = (hits: THREE.Intersection[]) => (hits.length === 0 ? '(none)' : hits.map((h) => `${h.object.name} at ${h.distance.toFixed(3)}`).join(' | '));

// Exercise 1: thin strings are hard to hit. Invisible, thicker copies take the hits: the Raycaster tests layers,
// not visible, and the renderer skips them.
const { board, strings } = buildFretboard();
board.updateMatrixWorld();
const beside = new THREE.Vector3((fretX(2) + fretX(3)) / 2, NECK_TOP + 0.035, stringZ(1) - 0.012);
aim(beside);
console.log('0.012 beside string 1:', list(raycaster.intersectObject(board, true)));
const proxyMaterial = new THREE.MeshBasicMaterial();
for (const string of strings) {
  const proxy = new THREE.Mesh(new THREE.CylinderGeometry(0.02, 0.02, 1, 8).rotateZ(Math.PI / 2), proxyMaterial);
  proxy.name = `${string.name} (hit area)`;
  proxy.visible = false;
  proxy.scale.x = (string.geometry as THREE.CylinderGeometry).parameters.height;
  proxy.position.copy(string.position);
  board.add(proxy);
}
board.updateMatrixWorld();
console.log('with invisible hit areas:', list(raycaster.intersectObject(board, true)));

// Exercise 2: Points have no surface; Raycaster.params.Points.threshold is the distance, in world units, that counts as a hit
const dots = new THREE.Points(
  new THREE.BufferGeometry().setFromPoints([1, 3, 5, 7].map((fret) => pressPoint(3, fret))),
  new THREE.PointsMaterial({ size: 0.05 }),
);
dots.name = 'dots';
dots.updateMatrixWorld();
aim(pressPoint(3, 5).add(new THREE.Vector3(0.04, 0, 0)));
for (const threshold of [1, 0.1, 0.05, 0.02]) {
  raycaster.params.Points.threshold = threshold;
  const hits = raycaster.intersectObject(dots);
  console.log(`threshold ${threshold}: ${hits.length} hit(s)${hits.length ? `, nearest to the ray: index ${[...hits].sort((a, b) => a.distanceToRay! - b.distanceToRay!)[0].index}, first: index ${hits[0].index}` : ''}`);
}
