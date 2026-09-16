// Lesson 2: a piece of guitar neck built from primitives, physically based materials, two lights and a shadow
import * as THREE from 'three/webgpu';
import { backendName, forceWebGL, probing, report } from '../probe.ts';

const params = new URLSearchParams(location.search);
const shadows = !params.has('noshadows');

const renderer = new THREE.WebGPURenderer({ antialias: true, forceWebGL });
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.shadowMap.enabled = shadows;
renderer.shadowMap.type = THREE.PCFShadowMap;
document.body.append(renderer.domElement);

const scene = new THREE.Scene();
scene.background = new THREE.Color(0x1e2127);

const camera = new THREE.PerspectiveCamera(40, window.innerWidth / window.innerHeight, 0.1, 100);
camera.position.set(1.2, 2.2, 3.2);
camera.lookAt(0, 0, 0);

// The table: a plane lies in XY, so it is turned to face up
const table = new THREE.Mesh(
  new THREE.PlaneGeometry(8, 8),
  new THREE.MeshStandardMaterial({ color: 0x3a4250, roughness: 0.9 }),
);
table.rotation.x = -Math.PI / 2;
table.receiveShadow = true;
scene.add(table);

// The neck: rosewood is a dielectric (metalness 0) with a rough surface
const neck = new THREE.Mesh(
  new THREE.BoxGeometry(4, 0.12, 0.55),
  new THREE.MeshStandardMaterial({ color: 0x4a2c1d, metalness: 0, roughness: 0.75 }),
);
neck.position.y = 0.3;
neck.castShadow = true;
neck.receiveShadow = true;
scene.add(neck);

// Frets: nickel silver, a metal, so metalness 1 and the color tints the reflections
const fretMaterial = new THREE.MeshStandardMaterial({ color: 0xc9c5bd, metalness: 1, roughness: 0.3 });
const fretGeometry = new THREE.CylinderGeometry(0.012, 0.012, 0.55, 12);
for (let fret = 1; fret <= 5; fret++) {
  // Each fret is at scale length × (1 − 2^(−n/12)) from the nut, here with a scale length of 6.5 units
  const x = -2 + 6.5 * (1 - 2 ** (-fret / 12));
  const mesh = new THREE.Mesh(fretGeometry, fretMaterial);
  mesh.rotation.x = Math.PI / 2;
  mesh.position.set(x, 0.37, 0);
  mesh.castShadow = true;
  scene.add(mesh);
}

// An inlay: mother of pearl, with a clear coat that MeshPhysicalMaterial adds on top of the standard model
const inlay = new THREE.Mesh(
  new THREE.CircleGeometry(0.06, 32),
  new THREE.MeshPhysicalMaterial({ color: 0xf2efe6, roughness: 0.4, clearcoat: 1, clearcoatRoughness: 0.05, iridescence: 0.6 }),
);
inlay.rotation.x = -Math.PI / 2;
// Between the second and the third fret, where a guitar has its first dot
inlay.position.set(-1.13, 0.361, 0);
scene.add(inlay);

// A sky and ground light fills the shadows; a directional light, like the sun, casts them
scene.add(new THREE.HemisphereLight(0xdde6ff, 0x302820, 1.2));
const sun = new THREE.DirectionalLight(0xffffff, 3);
sun.position.set(2, 4, 3);
sun.castShadow = true;
sun.shadow.mapSize.set(1024, 1024);
Object.assign(sun.shadow.camera, { left: -3, right: 3, top: 3, bottom: -3, near: 0.5, far: 12 });
scene.add(sun);

let frames = 0;
renderer.setAnimationLoop(() => {
  renderer.render(scene, camera);
  frames++;
  if (probing && frames === 3) {
    renderer.setAnimationLoop(null);
    report(renderer, { shadows, objects: countObjects(scene) });
  }
});

window.addEventListener('resize', () => {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
});

function countObjects(root: THREE.Object3D): Record<string, number> {
  const counts: Record<string, number> = {};
  root.traverse((object) => (counts[object.type] = (counts[object.type] ?? 0) + 1));
  return counts;
}

await renderer.init();
document.title = `Lesson 2 — ${backendName(renderer)}`;
