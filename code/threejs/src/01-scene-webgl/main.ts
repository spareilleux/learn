// Lesson 1: the same cube with the classic WebGLRenderer, from 'three' instead of 'three/webgpu'
import * as THREE from 'three';
import { probing, publish } from '../probe.ts';

const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.setSize(window.innerWidth, window.innerHeight);
document.body.append(renderer.domElement);

const scene = new THREE.Scene();
scene.background = new THREE.Color(0x1e2127);
const camera = new THREE.PerspectiveCamera(50, window.innerWidth / window.innerHeight, 0.1, 100);
camera.position.set(0, 1.5, 4);
camera.lookAt(0, 0, 0);
const cube = new THREE.Mesh(new THREE.BoxGeometry(1, 1, 1), new THREE.MeshNormalMaterial());
scene.add(cube);

let frames = 0;
renderer.setAnimationLoop((time) => {
  cube.rotation.y = probing ? frames * 0.25 : time / 1000;
  cube.rotation.x = cube.rotation.y / 2;
  renderer.render(scene, camera);
  frames++;
  if (probing && frames === 3) {
    renderer.setAnimationLoop(null);
    // WebGLRenderer's info has no drawCalls: calls counts the draw calls of the last render(), and there is no output pass
    const { render, memory, programs } = renderer.info;
    publish({
      backend: 'WebGLRenderer',
      render: { frame: render.frame, calls: render.calls, triangles: render.triangles },
      memory: { geometries: memory.geometries, textures: memory.textures, programs: programs?.length },
    });
  }
});

window.addEventListener('resize', () => {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
});
