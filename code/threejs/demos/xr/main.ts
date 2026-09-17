// Live demo: the guitar in WebXR. With a headset, "Enter VR" puts it in front of you: point a controller at the neck and
// pull the trigger to play a note, with a short haptic pulse. Without one, ?emulate installs IWER's emulated Quest 3
// (lesson 11) and, once in the session, the right controller plays an arpeggio by itself.
// It draws with the classic WebGLRenderer, the only renderer lesson 11 saw render both eyes with IWER.
// ?probe: emulated session, a controller pick on string 3, fret 5, and the stereo frame.
import * as THREE from 'three/webgpu';
import { WebGLRenderer } from 'three';
import { VRButton } from 'three/addons/webxr/VRButton.js';
import type { XRDevice } from 'iwer';
import { fretAtX, noteAt, markerX } from '../../src/13-fretboard/guitar.ts';
import { probing, publish } from '../../src/probe.ts';
import { overlay } from '../common.ts';
import { buildGuitar, stringAt, stringY, stringZAt } from '../guitar/model.ts';
import { createPlucker, OPEN_STRINGS } from '../guitar/pluck.ts';

const params = new URLSearchParams(location.search);
const emulate = probing || params.has('emulate');
const result: Record<string, unknown> = {};
const errors: string[] = [];

// The emulated headset must be installed before the renderer (lesson 11); IWER is only downloaded when asked for
let device: XRDevice | null = null;
if (emulate) {
  const { XRDevice, metaQuest3 } = await import('iwer');
  device = new XRDevice(metaQuest3);
  device.installRuntime({ forceInstall: true });
  device.stereoEnabled = true;
  device.position.set(0, 1.55, 0.15);
  const look = new THREE.Quaternion().setFromAxisAngle(new THREE.Vector3(1, 0, 0), (-45 * Math.PI) / 180);
  device.quaternion.set(look.x, look.y, look.z, look.w);
}

const renderer = new WebGLRenderer({ antialias: true });
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.xr.enabled = true;
document.body.append(renderer.domElement);
document.body.append(VRButton.createButton(renderer));

const scene = new THREE.Scene();
scene.background = new THREE.Color(0x2a2e36);
scene.add(new THREE.HemisphereLight(0xdde6ff, 0x3a3028, 2));
const sun = new THREE.DirectionalLight(0xffffff, 2);
sun.position.set(1, 3, 2);
scene.add(sun);
// Meters, with y = 0 on the floor ('local-floor')
const floor = new THREE.Mesh(new THREE.CircleGeometry(3, 48).rotateX(-Math.PI / 2), new THREE.MeshStandardMaterial({ color: 0x3a3f4a, roughness: 0.9 }));
scene.add(floor, new THREE.GridHelper(6, 24, 0x5a6070, 0x464b56));

// The guitar at waist height, 45 cm in front, its face tilted towards you, the neck to the left
const guitar = buildGuitar({ nodeStrings: false });
guitar.group.scale.setScalar(0.01);
guitar.group.position.set(0.04, 1.05, -0.3);
guitar.group.rotation.x = 0.9;
scene.add(guitar.group);

const camera = new THREE.PerspectiveCamera(50, window.innerWidth / window.innerHeight, 0.05, 50);
camera.position.set(0, 1.55, 0.35);
camera.lookAt(0, 1.05, -0.3);
window.addEventListener('resize', () => {
  // In a session the headset sets the size: WebGLRenderer refuses a resize and warns
  if (renderer.xr.isPresenting) return;
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
});

const say = overlay();
say(
  'xr' in navigator
    ? 'Enter VR, point a controller at the neck and pull the trigger. No headset? Add ?emulate to the address'
    : 'This browser has no WebXR. Add ?emulate to the address for an emulated Quest 3',
);

// A controller's ray, in the guitar's own coordinates, crossing the plane of the strings: the same pick as on the
// guitar page
const plucker = createPlucker();
const raycaster = new THREE.Raycaster();
const inverse = new THREE.Matrix4();
const picks: string[] = [];
function pickWith(controller: THREE.XRTargetRaySpace, inputSource?: XRInputSource) {
  raycaster.setFromXRController(controller);
  if (raycaster.intersectObject(guitar.pickTarget).length === 0) return;
  const local = raycaster.ray.clone().applyMatrix4(inverse.copy(guitar.group.matrixWorld).invert());
  const hit = local.intersectPlane(new THREE.Plane(new THREE.Vector3(0, 1, 0), -0.45), new THREE.Vector3());
  const fret = hit && fretAtX(hit.x);
  if (!hit || fret === null) return;
  const string = stringAt(hit.x, hit.z);
  const note = noteAt(string, fret);
  guitar.pluck(string, fret);
  if (!probing) plucker.play(OPEN_STRINGS[string] + fret);
  void inputSource?.gamepad?.hapticActuators?.[0]?.pulse(0.6, 40);
  picks.push(`string ${string + 1}, fret ${fret}: ${note}`);
  say(`String ${string + 1}, ${fret === 0 ? 'open' : `fret ${fret}`}: ${note}`);
}

for (const index of [0, 1]) {
  const controller = renderer.xr.getController(index);
  // A thin ray to aim with, 1 m long
  const ray = new THREE.Line(new THREE.BufferGeometry().setFromPoints([new THREE.Vector3(), new THREE.Vector3(0, 0, -1)]), new THREE.LineBasicMaterial({ color: 0xffb454 }));
  controller.add(ray);
  controller.addEventListener('connected', (event) => (controller.userData.inputSource = event.data));
  controller.addEventListener('select', () => pickWith(controller, controller.userData.inputSource));
  scene.add(controller);
}

let xrFrames = 0;
renderer.setAnimationLoop((time) => {
  guitar.update(time / 1000);
  try {
    renderer.render(scene, camera);
  } catch (error) {
    const message = `${(error as Error).name}: ${(error as Error).message}`;
    if (!errors.includes(message)) errors.push(message);
  }
  if (renderer.xr.isPresenting) xrFrames++;
});

// Aims the emulated right controller at string s, fret f, from beside the player, and pulls its trigger
const nextFrames = (n: number) =>
  new Promise<void>((resolve) => {
    const target = xrFrames + n;
    const deadline = performance.now() + 5000;
    const wait = () => (xrFrames >= target || performance.now() > deadline ? resolve() : setTimeout(wait, 10));
    wait();
  });
async function playWithEmulatedController(string: number, fret: number) {
  const right = device!.controllers.right!;
  const from = new THREE.Vector3(0.2, 1.25, -0.05);
  const x = markerX(fret);
  const target = guitar.group.localToWorld(new THREE.Vector3(x, stringY(x), stringZAt(string, x)));
  right.position.set(from.x, from.y, from.z);
  const q = new THREE.Quaternion().setFromUnitVectors(new THREE.Vector3(0, 0, -1), target.sub(from).normalize());
  right.quaternion.set(q.x, q.y, q.z, q.w);
  await nextFrames(2);
  right.updateButtonValue('trigger', 1);
  await nextFrames(2);
  right.updateButtonValue('trigger', 0);
  await nextFrames(1);
}

// With ?emulate, a C major arpeggio, from low to high, again and again while the session lasts
if (emulate && !probing) {
  renderer.xr.addEventListener('sessionstart', async () => {
    const ARPEGGIO: [number, number][] = [[4, 3], [3, 2], [2, 0], [1, 1], [0, 0], [1, 1], [2, 0], [3, 2]];
    for (let i = 0; renderer.xr.isPresenting; i++) {
      await playWithEmulatedController(...ARPEGGIO[i % ARPEGGIO.length]);
      await new Promise((resolve) => setTimeout(resolve, 350));
    }
  });
}

if (probing) {
  try {
    const session = await navigator.xr!.requestSession('immersive-vr', { optionalFeatures: ['local-floor'] });
    await renderer.xr.setSession(session);
  } catch (error) {
    errors.push(`${(error as Error).name}: ${(error as Error).message}`);
  }
  result.presenting = renderer.xr.isPresenting;
  if (renderer.xr.isPresenting) {
    await nextFrames(5);
    await playWithEmulatedController(2, 5);
    const xrCamera = renderer.xr.getCamera();
    result.eyes = xrCamera.cameras.length;
    result.picks = picks;
    result.shotAfter = 'in the session';
    result.actions = [{ name: 'in the session' }, { name: 'end the session' }];
    window.probeAfter = async (name: string) => {
      if (name === 'in the session') {
        await nextFrames(3);
        return { presenting: renderer.xr.isPresenting };
      }
      await renderer.xr.getSession()?.end();
      await new Promise((resolve) => setTimeout(resolve, 50));
      return { presenting: renderer.xr.isPresenting };
    };
  }
  result.errors = errors;
  publish(result);
}
