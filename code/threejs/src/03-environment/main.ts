// Lesson 3: image-based lighting. No light objects: ten spheres lit only by the HDR environment of make-studio-hdr.ts
import * as THREE from 'three/webgpu';
import { HDRLoader } from 'three/addons/loaders/HDRLoader.js';
import { backendName, forceWebGL, probing, report } from '../probe.ts';

const renderer = new THREE.WebGPURenderer({ antialias: true, forceWebGL });
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.toneMapping = THREE.ACESFilmicToneMapping;
document.body.append(renderer.domElement);

const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(35, window.innerWidth / window.innerHeight, 0.1, 100);
camera.position.set(0, 0, 9);

const environment = await new HDRLoader().loadAsync('generated/studio.hdr');
environment.mapping = THREE.EquirectangularReflectionMapping;
scene.environment = environment;
scene.background = environment;
scene.backgroundBlurriness = 0.4;

// Rows: a dielectric (metalness 0) and a metal (metalness 1). Columns: roughness from 0 to 1.
const sphere = new THREE.SphereGeometry(0.45, 64, 32);
for (const [row, metalness] of [0, 1].entries()) {
  for (let column = 0; column < 5; column++) {
    const material = new THREE.MeshStandardMaterial({ color: 0xd4a373, metalness, roughness: column / 4 });
    const mesh = new THREE.Mesh(sphere, material);
    mesh.position.set((column - 2) * 1.2, 0.6 - row * 1.2, 0);
    scene.add(mesh);
  }
}

let frames = 0;
renderer.setAnimationLoop(() => {
  renderer.render(scene, camera);
  frames++;
  if (probing && frames === 3) {
    renderer.setAnimationLoop(null);
    const { image, type } = environment;
    report(renderer, {
      environment: { width: image.width, height: image.height, halfFloat: type === THREE.HalfFloatType, colorSpace: environment.colorSpace },
    });
  }
});

window.addEventListener('resize', () => {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
});

await renderer.init();
document.title = `Lesson 3 — ${backendName(renderer)}, environment`;
