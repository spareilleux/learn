// Experiment 14, vanilla side: the same InstancedMeshes and fret-number texture built by src/neck.ts, without React.
import * as THREE from 'three/webgpu';
import { C_MAJOR } from '../../../src/13-fretboard/guitar.ts';
import { addLights, buildInstancedNecks } from '../neck.ts';

export async function start(width: number, height: number, forceWebGL: boolean): Promise<{ renderer: THREE.WebGPURenderer; draw: (i: number) => void }> {
  const renderer = new THREE.WebGPURenderer({ antialias: true, forceWebGL });
  await renderer.init();
  renderer.setSize(width, height);
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.2;
  document.body.append(renderer.domElement);
  const scene = new THREE.Scene();
  addLights(scene);
  buildInstancedNecks(scene, 1, C_MAJOR);
  const camera = new THREE.PerspectiveCamera(35, width / height, 0.1, 1000);
  camera.position.set(-12, 18, 40);
  camera.lookAt(0, 0, 0);
  return { renderer, draw: () => renderer.render(scene, camera) };
}
