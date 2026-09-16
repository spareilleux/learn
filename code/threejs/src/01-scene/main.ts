// Lesson 1: a scene, a camera, a renderer, an animation loop, and a canvas that follows the window
import * as THREE from 'three/webgpu';
import { backendName, forceWebGL, probing, report } from '../probe.ts';

const renderer = new THREE.WebGPURenderer({ antialias: true, forceWebGL });
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.setSize(window.innerWidth, window.innerHeight);
document.body.append(renderer.domElement);
// ?linear: write linear values to the canvas, which removes the output pass (lesson 3 explains why it exists)
if (new URLSearchParams(location.search).has('linear')) renderer.outputColorSpace = THREE.LinearSRGBColorSpace;

const scene = new THREE.Scene();
scene.background = new THREE.Color(0x1e2127);

// 50° vertical field of view, the window's aspect ratio, and everything between 0.1 and 100 units is drawn
const camera = new THREE.PerspectiveCamera(50, window.innerWidth / window.innerHeight, 0.1, 100);
camera.position.set(0, 1.5, 4);
camera.lookAt(0, 0, 0);

const cube = new THREE.Mesh(new THREE.BoxGeometry(1, 1, 1), new THREE.MeshNormalMaterial());
scene.add(cube);

// ?cubes=n adds n − 1 cubes that share the first cube's geometry and material (exercise 1)
const cubes = Number(new URLSearchParams(location.search).get('cubes') ?? 1);
for (let i = 1; i < cubes; i++) {
  const copy = new THREE.Mesh(cube.geometry, cube.material);
  copy.position.x = i * 1.5;
  scene.add(copy);
}

const timer = new THREE.Timer();
timer.connect(document);
let frames = 0;

renderer.setAnimationLoop((time) => {
  timer.update(time);
  // Probing: the same angles on every machine, whatever the frame rate
  cube.rotation.y = probing ? frames * 0.25 : timer.getElapsed();
  cube.rotation.x = cube.rotation.y / 2;
  renderer.render(scene, camera);
  frames++;
  if (probing && frames === 3) {
    renderer.setAnimationLoop(null);
    report(renderer, {
      canvas: [renderer.domElement.width, renderer.domElement.height],
      pixelRatio: renderer.getPixelRatio(),
      coordinateSystem: renderer.coordinateSystem === THREE.WebGPUCoordinateSystem ? 'WebGPU' : 'WebGL',
    });
  }
});

window.addEventListener('resize', () => {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
});

await renderer.init();
document.title = `Lesson 1 — ${backendName(renderer)}`;
