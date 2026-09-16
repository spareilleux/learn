// Lesson 4: what GLTFLoader builds from the metronome, and where the animation puts the arm: node scripts/l04-gltf.ts
// Run make-models.ts first. The Draco copy is loaded in the browser only: DRACOLoader decodes in Web Workers.
import { readFileSync } from 'node:fs';
import * as THREE from 'three';
import { GLTFLoader, type GLTF } from 'three/addons/loaders/GLTFLoader.js';
import { MeshoptDecoder } from 'three/addons/libs/meshopt_decoder.module.js';

function parse(file: string): Promise<GLTF> {
  const bytes = readFileSync(`public/generated/${file}`);
  const loader = new GLTFLoader().setMeshoptDecoder(MeshoptDecoder);
  return loader.parseAsync(bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength), '');
}

function tree(object: THREE.Object3D, depth = 0): void {
  const mesh = object as THREE.Mesh;
  const details = mesh.isMesh
    ? ` — ${mesh.geometry.getAttribute('position').count} vertices, ${(mesh.material as THREE.MeshStandardMaterial).type} "${(mesh.material as THREE.Material).name}"`
    : '';
  console.log(`${'  '.repeat(depth)}${object.type} "${object.name}"${details}`);
  for (const child of object.children) tree(child, depth + 1);
}

const gltf = await parse('metronome.glb');
tree(gltf.scene);
console.log('asset:', gltf.asset);

const [swing] = gltf.animations;
console.log(`clip "${swing.name}": ${swing.duration} s, tracks ${swing.tracks.map((track) => `${track.name} (${track.times.length} keys, ${track.constructor.name})`).join(', ')}`);

// AnimationMixer is AnimationController and Storyboard in one: it plays actions on the objects of a root
const mixer = new THREE.AnimationMixer(gltf.scene);
const action = mixer.clipAction(swing).play();
const arm = gltf.scene.getObjectByName('arm')!;
const angle = () => Number(THREE.MathUtils.radToDeg(new THREE.Euler().setFromQuaternion(arm.quaternion).z).toFixed(2)) + 0;
for (const delta of [0, 0.125, 0.125, 0.25, 0.25, 0.5]) {
  mixer.update(delta);
  console.log(`t = ${mixer.time.toFixed(3)} s: arm at ${angle()}°`);
}
action.timeScale = 2;
mixer.update(0.125);
console.log(`timeScale 2, then 0.125 s more: t = ${action.time.toFixed(3)} s in the clip, arm at ${angle()}°`);

// The meshopt copy: quantized positions come back as integers, with a scale on the node to undo it
const compressed = await parse('metronome-meshopt.glb');
const weight = compressed.scene.getObjectByName('weight') as THREE.Mesh;
const position = weight.geometry.getAttribute('position') as THREE.BufferAttribute;
console.log('meshopt weight position:', position.array.constructor.name, 'normalized', position.normalized, 'scale', weight.scale.toArray().map((n) => Number(n.toFixed(4))));
