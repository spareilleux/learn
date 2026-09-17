// Live demo: the guitar on a stand in a small studio. A spotlight casts soft shadows on the floor (lesson 2), the HDR
// environment of lesson 3 lights the lacquer and the chrome, a neon ring behind glows through bloom in a RenderPipeline
// (lesson 7), and ACES tone mapping brings it all to the screen. The panel changes the light, the exposure and the bloom.
// ?probe: the renderer's counts after three frames of the whole chain.
import * as THREE from 'three/webgpu';
import { pass } from 'three/tsl';
import { bloom } from 'three/addons/tsl/display/BloomNode.js';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { HDRLoader } from 'three/addons/loaders/HDRLoader.js';
import GUI from 'three/addons/libs/lil-gui.module.min.js';
import { backendName, gpuName, probing, publish } from '../../src/probe.ts';
import { createRenderer, followWindow, onClick, overlay, toNdc } from '../common.ts';
import { fretAtX, noteAt } from '../../src/13-fretboard/guitar.ts';
import { buildGuitar, stringAt } from '../guitar/model.ts';
import { createPlucker, OPEN_STRINGS } from '../guitar/pluck.ts';

const renderer = await createRenderer({ shadows: true });
renderer.toneMappingExposure = 1;
const scene = new THREE.Scene();
scene.background = new THREE.Color(0x0c0d10);
// Same file as lesson 3, relative to the page: lights the materials, but isn't shown as the background
const environment = await new HDRLoader().loadAsync('../generated/studio.hdr');
environment.mapping = THREE.EquirectangularReflectionMapping;
scene.environment = environment;
scene.environmentIntensity = 0.35;

const camera = new THREE.PerspectiveCamera(35, 1, 1, 2000);
camera.position.set(70, 75, 190);
followWindow(renderer, camera);
const controls = new OrbitControls(camera, renderer.domElement);
controls.target.set(0, 52, 0);
controls.enableDamping = !probing;
controls.maxPolarAngle = Math.PI / 2 - 0.05;
controls.minDistance = 40;
controls.maxDistance = 400;
controls.update();

// The floor: dark and rough, it receives the shadows
const floor = new THREE.Mesh(new THREE.CircleGeometry(600, 64).rotateX(-Math.PI / 2), new THREE.MeshStandardMaterial({ color: 0x141312, roughness: 0.85 }));
floor.receiveShadow = true;
scene.add(floor);

// The guitar stands up: its length (x, body towards +x) points down the y axis, its face (y) towards +z
const guitar = buildGuitar();
guitar.group.traverse((object) => {
  if (object instanceof THREE.Mesh) {
    object.castShadow = true;
    object.receiveShadow = true;
  }
});
guitar.pickTarget.castShadow = false;
const standing = new THREE.Group();
guitar.group.quaternion.setFromRotationMatrix(new THREE.Matrix4().makeBasis(new THREE.Vector3(0, -1, 0), new THREE.Vector3(0, 0, 1), new THREE.Vector3(-1, 0, 0)));
standing.add(guitar.group);
// The body's end (x ≈ 47) is now at y ≈ −47: lift it onto the cradle, and lean the guitar back
standing.position.set(0, 47.3 * Math.cos(0.2) + 4, 6);
standing.rotation.x = -0.2;
const turntable = new THREE.Group();
turntable.add(standing);
scene.add(turntable);

// A stand: a cradle under the body on two short front feet, and a rear post up to a yoke behind the neck
const standMaterial = new THREE.MeshStandardMaterial({ color: 0x1a1a1a, metalness: 0.6, roughness: 0.4 });
function rod(from: THREE.Vector3, to: THREE.Vector3, radius = 0.6) {
  const mesh = new THREE.Mesh(new THREE.CylinderGeometry(radius, radius, from.distanceTo(to), 12), standMaterial);
  mesh.position.copy(from).add(to).multiplyScalar(0.5);
  mesh.quaternion.setFromUnitVectors(new THREE.Vector3(0, 1, 0), to.clone().sub(from).normalize());
  mesh.castShadow = true;
  scene.add(mesh);
}
const V = (x: number, y: number, z: number) => new THREE.Vector3(x, y, z);
rod(V(-16, 3.4, 12), V(-19, 0, 24));
rod(V(16, 3.4, 12), V(19, 0, 24));
rod(V(0, 0, -30), V(0, 58, -2.5), 0.8);
rod(V(-16, 3.4, 12), V(0, 3, -12));
rod(V(16, 3.4, 12), V(0, 3, -12));
const cradle = new THREE.Mesh(new THREE.BoxGeometry(34, 1.2, 5), standMaterial);
cradle.position.set(0, 4, 12);
cradle.castShadow = true;
scene.add(cradle);
const yoke = new THREE.Mesh(new THREE.TorusGeometry(3.4, 0.5, 8, 24, Math.PI), standMaterial);
yoke.position.set(0, 58, -1.5);
yoke.rotation.x = Math.PI / 2 - 0.2;
yoke.rotation.z = Math.PI;
scene.add(yoke);

// Key light: a spotlight from the front left, with a soft shadow
const key = new THREE.SpotLight(0xfff1dc, 18000, 0, 0.45, 0.6, 1.6);
key.position.set(-110, 190, 150);
key.target.position.set(0, 45, 0);
key.castShadow = true;
key.shadow.mapSize.set(2048, 2048);
key.shadow.radius = 6;
key.shadow.bias = -0.0005;
scene.add(key, key.target);
// Rim light from behind, cooler
const rim = new THREE.DirectionalLight(0x9ec9ff, 1.4);
rim.position.set(80, 120, -160);
scene.add(rim);

// A neon ring on the back wall: its emissive intensity is far above 1, so the bloom picks it up
const neonMaterial = new THREE.MeshBasicMaterial({ color: new THREE.Color(0xff3d7f).multiplyScalar(6) });
const neon = new THREE.Mesh(new THREE.TorusGeometry(58, 1.1, 16, 128), neonMaterial);
neon.position.set(0, 70, -70);
scene.add(neon);
const wall = new THREE.Mesh(new THREE.PlaneGeometry(1200, 400), new THREE.MeshStandardMaterial({ color: 0x15161a, roughness: 0.95 }));
wall.position.set(0, 200, -75);
wall.receiveShadow = true;
scene.add(wall);

// The chain: the scene pass, and bloom added on top of it
const pipeline = new THREE.RenderPipeline(renderer);
const scenePass = pass(scene, camera);
const sceneColor = scenePass.getTextureNode('output');
const glow = bloom(sceneColor, 0.8, 0.5, 1);
pipeline.outputNode = sceneColor.add(glow);

const settings = {
  exposure: 1,
  'key light': 18000,
  'environment': 0.35,
  'bloom strength': 0.8,
  'bloom threshold': 1,
  neon: '#ff3d7f',
  turntable: false,
  sound: true,
};
const say = overlay();
say('Drag to orbit, click the neck to play a note');
if (!probing) {
  const gui = new GUI({ title: 'Studio' });
  gui.add(settings, 'exposure', 0.2, 3, 0.05).onChange((v: number) => void (renderer.toneMappingExposure = v));
  gui.add(settings, 'key light', 0, 150000, 1000).onChange((v: number) => void (key.intensity = v));
  gui.add(settings, 'environment', 0, 2, 0.05).onChange((v: number) => void (scene.environmentIntensity = v));
  gui.add(settings, 'bloom strength', 0, 3, 0.05).onChange((v: number) => void (glow.strength.value = v));
  gui.add(settings, 'bloom threshold', 0, 2, 0.05).onChange((v: number) => void (glow.threshold.value = v));
  gui.addColor(settings, 'neon').onChange((v: string) => void neonMaterial.color.set(v).multiplyScalar(6));
  gui.add(settings, 'turntable');
  gui.add(settings, 'sound');
}

// Clicking the neck plays a note, as on the guitar page: the ray is taken into the guitar's own coordinates
const plucker = createPlucker();
const raycaster = new THREE.Raycaster();
onClick(renderer.domElement, (event) => {
  raycaster.setFromCamera(toNdc(event, renderer.domElement), camera);
  if (raycaster.intersectObject(guitar.pickTarget).length === 0) return;
  const local = raycaster.ray.clone().applyMatrix4(guitar.group.matrixWorld.clone().invert());
  const hit = local.intersectPlane(new THREE.Plane(new THREE.Vector3(0, 1, 0), -0.45), new THREE.Vector3());
  const fret = hit && fretAtX(hit.x);
  if (!hit || fret === null) return;
  const string = stringAt(hit.x, hit.z);
  guitar.pluck(string, fret);
  if (settings.sound) plucker.play(OPEN_STRINGS[string] + fret);
  say(`String ${string + 1}, ${fret === 0 ? 'open' : `fret ${fret}`}: ${noteAt(string, fret)}`);
});

let frames = 0;
let last = 0;
renderer.setAnimationLoop((time) => {
  const seconds = time / 1000;
  if (settings.turntable && !probing) turntable.rotation.y += (seconds - last) * 0.4;
  last = seconds;
  guitar.update(seconds);
  controls.update();
  pipeline.render();
  frames++;
  if (probing && frames === 3) {
    const { render, memory } = renderer.info;
    publish({
      backend: backendName(renderer),
      gpu: gpuName(renderer),
      render: { calls: render.calls, drawCalls: render.drawCalls, triangles: render.triangles },
      memory: { geometries: memory.geometries, textures: memory.textures, renderTargets: memory.renderTargets },
    });
  }
});
