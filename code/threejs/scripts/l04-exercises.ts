// Lesson 4, exercises: node scripts/l04-exercises.ts (run make-models.ts first)
import { readFileSync } from 'node:fs';
import { NodeIO } from '@gltf-transform/core';
import { ALL_EXTENSIONS } from '@gltf-transform/extensions';
import draco3d from 'draco3dgltf';
import { MeshoptDecoder } from 'meshoptimizer';
import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';

// Exercise 1: where the vertices went. glTF Transform decodes Draco and meshopt in Node.js, without a browser.
const io = new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({
  'draco3d.decoder': await draco3d.createDecoderModule(),
  'meshopt.decoder': MeshoptDecoder,
});
await MeshoptDecoder.ready;
for (const file of ['metronome.glb', 'metronome-draco.glb', 'metronome-meshopt.glb']) {
  const document = await io.read(`public/generated/${file}`);
  const counts = document
    .getRoot()
    .listMeshes()
    .map((mesh) => {
      const primitive = mesh.listPrimitives()[0];
      return `${mesh.getName()} ${primitive.getAttribute('POSITION')!.getCount()} vertices, ${primitive.getIndices()!.getCount() / 3} triangles`;
    });
  console.log(file.padEnd(22), counts.join(' | '));
}

// Exercise 2: the arm at 0.875 s, and a clip played once with clampWhenFinished
const bytes = readFileSync('public/generated/metronome.glb');
const gltf = await new GLTFLoader().parseAsync(bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength), '');
const arm = gltf.scene.getObjectByName('arm')!;
const angle = () => Number(THREE.MathUtils.radToDeg(new THREE.Euler().setFromQuaternion(arm.quaternion).z).toFixed(2)) + 0;
const mixer = new THREE.AnimationMixer(gltf.scene);
const action = mixer.clipAction(gltf.animations[0]).play();
mixer.update(0.875);
console.log(`t = 0.875 s: arm at ${angle()}°`);
action.stop();
action.setLoop(THREE.LoopOnce, 1);
action.clampWhenFinished = true;
action.play();
let finished = 0;
mixer.addEventListener('finished', () => finished++);
mixer.update(0.2);
mixer.update(1.3);
console.log(`LoopOnce, clampWhenFinished, after 1.5 s: arm at ${angle()}°, action.time ${action.time}, running ${action.isRunning()}, finished events ${finished}`);
