// Lesson 4: the metronome three times, as written, with Draco and with meshopt, swinging on the same clock
import * as THREE from 'three/webgpu';
import { DRACOLoader } from 'three/addons/loaders/DRACOLoader.js';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { HDRLoader } from 'three/addons/loaders/HDRLoader.js';
import { MeshoptDecoder } from 'three/addons/libs/meshopt_decoder.module.js';
import { backendName, forceWebGL, probing, report } from '../probe.ts';

const renderer = new THREE.WebGPURenderer({ antialias: true, forceWebGL });
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.toneMapping = THREE.ACESFilmicToneMapping;
document.body.append(renderer.domElement);

const scene = new THREE.Scene();
scene.background = new THREE.Color(0x1e2127);
const camera = new THREE.PerspectiveCamera(35, window.innerWidth / window.innerHeight, 0.1, 100);
camera.position.set(0, 1.4, 6);
camera.lookAt(0, 0.9, 0);

const environment = await new HDRLoader().loadAsync('generated/studio.hdr');
environment.mapping = THREE.EquirectangularReflectionMapping;
scene.environment = environment;

// One loader for the three files: it picks the decoder that each file's extensionsRequired asks for
const loader = new GLTFLoader().setDRACOLoader(new DRACOLoader()).setMeshoptDecoder(MeshoptDecoder);

const files = ['metronome.glb', 'metronome-draco.glb', 'metronome-meshopt.glb'];
const mixers: THREE.AnimationMixer[] = [];
const loaded: Record<string, unknown> = {};
const models = await Promise.all(files.map((file) => loader.loadAsync(`generated/${file}`)));

models.forEach((gltf, i) => {
  gltf.scene.position.x = (i - 1) * 1.6;
  scene.add(gltf.scene);
  const mixer = new THREE.AnimationMixer(gltf.scene);
  mixer.clipAction(gltf.animations[0]).play();
  mixers.push(mixer);
  let vertices = 0;
  gltf.scene.traverse((object) => {
    if ((object as THREE.Mesh).isMesh) vertices += (object as THREE.Mesh).geometry.getAttribute('position').count;
  });
  loaded[files[i]] = { extensionsUsed: gltf.parser.json.extensionsUsed ?? [], vertices, clip: gltf.animations[0].name };
});

const timer = new THREE.Timer();
timer.connect(document);
let frames = 0;
renderer.setAnimationLoop((time) => {
  timer.update(time);
  // Probing: a fixed step of 1/8 s per frame, so the third frame shows the arms at 0.375 s into the clip
  const delta = probing ? 0.125 : timer.getDelta();
  for (const mixer of mixers) mixer.update(delta);
  renderer.render(scene, camera);
  frames++;
  if (probing && frames === 3) {
    renderer.setAnimationLoop(null);
    const arm = models[1].scene.getObjectByName('arm')!;
    report(renderer, {
      loaded,
      dracoArmAngle: Number(THREE.MathUtils.radToDeg(new THREE.Euler().setFromQuaternion(arm.quaternion).z).toFixed(2)),
    });
  }
});

window.addEventListener('resize', () => {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
});

await renderer.init();
document.title = `Lesson 4 — ${backendName(renderer)}`;
