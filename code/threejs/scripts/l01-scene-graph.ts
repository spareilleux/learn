// Lesson 1: the scene graph and the camera, without a renderer: node scripts/l01-scene-graph.ts
import * as THREE from 'three';

const scene = new THREE.Scene();

// A guitar body turned a quarter turn, and a tuning peg placed relative to it
const guitar = new THREE.Group();
guitar.name = 'guitar';
guitar.position.set(2, 0, 0);
guitar.rotation.y = Math.PI / 2;
scene.add(guitar);

const peg = new THREE.Mesh(new THREE.BoxGeometry(0.1, 0.1, 0.1), new THREE.MeshBasicMaterial());
peg.name = 'peg';
peg.position.set(1, 0, 0);
guitar.add(peg);

const round = (v: THREE.Vector3) => v.toArray().map((n) => Number(n.toFixed(3)) + 0);

console.log('local position of the peg:', round(peg.position));
// matrixWorld is a cache: render() and getWorldPosition() update it, setting position doesn't
console.log('matrixWorld before any update:', round(new THREE.Vector3().setFromMatrixPosition(peg.matrixWorld)));
console.log('getWorldPosition():', round(peg.getWorldPosition(new THREE.Vector3())));

// Right-handed, Y up: X to the right, Y up, Z towards the viewer
const camera = new THREE.PerspectiveCamera(50, 16 / 9, 0.1, 100);
camera.position.set(0, 0, 5);
camera.updateMatrixWorld();
for (const point of [new THREE.Vector3(0, 0, 0), new THREE.Vector3(1, 0, 0), new THREE.Vector3(0, 1, 0), new THREE.Vector3(0, 0, -95)]) {
  console.log(`${JSON.stringify(round(point))} -> NDC ${JSON.stringify(round(point.clone().project(camera)))}`);
}

// @types/three 0.186.0 declares children as string[] and no geometries or materials, but toJSON() writes
// the children as objects and adds both arrays: errors/l01_tojson_types.ts shows what tsc says without this cast
interface SceneFile {
  metadata: { version: number; type: string; generator: string };
  geometries: unknown[];
  materials: unknown[];
  object: { type: string; children: { type: string; name: string }[] };
}
const json = scene.toJSON() as unknown as SceneFile;
console.log('toJSON:', {
  metadata: json.metadata,
  geometries: json.geometries.length,
  materials: json.materials.length,
  children: json.object.children.map((child) => `${child.type} ${child.name}`),
});
