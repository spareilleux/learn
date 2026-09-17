// Experiment 12: GA's neck at real size in an immersive-vr session. GA's unit is 10 mm, so the neck's group is scaled by
// 0.01 to meters, the unit of WebXR's reference spaces, and laid on a table 0.9 m above the floor ('local-floor').
// ?xr=hardware asks the browser's own navigator.xr for immersive-vr and stops there if no device answers;
// ?xr=emulated installs IWER's Quest 3 (as lesson 11), enters the session with the classic WebGLRenderer (the renderer
// lesson 11 found to draw both eyes with IWER), and measures in the reference space: the head position three.js reports
// against the one IWER was given, the distance between the eyes, and the nut-to-12th-fret distance in world meters.
import * as THREE from 'three';
import { metaQuest3, XRDevice } from 'iwer';
import { FRETS, fretX, NUT_WIDTH, SCALE, BOARD_THICKNESS } from '../../../src/13-fretboard/guitar.ts';
import { publish } from '../../../src/probe.ts';
import { str } from '../lab.ts';

const mode = str('xr', 'emulated');
const result: Record<string, unknown> = { xr: mode, userAgent: navigator.userAgent };
const errors: string[] = [];

async function main() {
  result.native = {
    navigatorXR: 'xr' in navigator,
    immersiveVR: 'xr' in navigator ? await navigator.xr!.isSessionSupported('immersive-vr').catch((e: Error) => e.name) : null,
  };
  if (mode === 'hardware') {
    if (!(result.native as { immersiveVR: unknown }).immersiveVR) result.couldNotRun = 'navigator.xr.isSessionSupported("immersive-vr") is false: no XR device on this machine';
    else result.hardwareSessionAvailable = true;
    publish(result);
    return;
  }

  const device = new XRDevice(metaQuest3);
  device.installRuntime({ forceInstall: true });
  device.stereoEnabled = true;
  const head = new THREE.Vector3(-0.1, 1.55, 0.45);
  device.position.set(head.x, head.y, head.z);
  const look = new THREE.Quaternion().setFromAxisAngle(new THREE.Vector3(1, 0, 0), (-45 * Math.PI) / 180);
  device.quaternion.set(look.x, look.y, look.z, look.w);

  const renderer = new THREE.WebGLRenderer({ antialias: true });
  renderer.xr.enabled = true;
  renderer.setSize(1280, 720);
  document.body.append(renderer.domElement);

  const scene = new THREE.Scene();
  scene.background = new THREE.Color(0x1e2127);
  scene.add(new THREE.HemisphereLight(0xdde6ff, 0x302820, 2));
  // The neck in GA's units, then scaled: 1 GA unit = 10 mm = 0.01 m
  const neck = new THREE.Group();
  const board = new THREE.Mesh(new THREE.BoxGeometry(SCALE * 0.8, BOARD_THICKNESS, NUT_WIDTH), new THREE.MeshStandardMaterial({ color: 0x3b2418, roughness: 0.8 }));
  board.position.x = SCALE * 0.4 - SCALE / 2;
  neck.add(board);
  const fretGeometry = new THREE.BoxGeometry(0.2, 0.25, NUT_WIDTH);
  const fretMaterial = new THREE.MeshStandardMaterial({ color: 0xd8d0c0, metalness: 0.8, roughness: 0.3 });
  for (let n = 0; n <= FRETS; n++) {
    const fret = new THREE.Mesh(fretGeometry, n === 12 ? new THREE.MeshStandardMaterial({ color: 0xe8b04a }) : fretMaterial);
    fret.position.set(fretX(n), BOARD_THICKNESS / 2 + 0.12, 0);
    neck.add(fret);
  }
  neck.scale.setScalar(0.01);
  neck.position.set(0, 0.9, 0);
  scene.add(neck);
  const camera = new THREE.PerspectiveCamera(50, 16 / 9, 0.01, 20);

  let xrFrames = 0;
  renderer.setAnimationLoop(() => {
    renderer.render(scene, camera);
    if (renderer.xr.isPresenting) xrFrames++;
  });
  const frames = (n: number) =>
    new Promise<void>((resolve) => {
      const target = xrFrames + n;
      const deadline = performance.now() + 5000;
      const wait = () => (xrFrames >= target || performance.now() > deadline ? resolve() : setTimeout(wait, 10));
      wait();
    });

  const session = await navigator.xr!.requestSession('immersive-vr', { optionalFeatures: ['local-floor'] });
  await renderer.xr.setSession(session);
  await frames(5);
  const xrCamera = renderer.xr.getCamera();
  const [left, right] = xrCamera.cameras;
  neck.updateMatrixWorld(true);
  const nut = neck.localToWorld(new THREE.Vector3(fretX(0), 0, 0));
  const twelfth = neck.localToWorld(new THREE.Vector3(fretX(12), 0, 0));
  // The head position three.js derives from the viewer pose, in the reference space (meters)
  const reported = new THREE.Vector3().setFromMatrixPosition(xrCamera.matrixWorld);
  result.emulated = {
    device: device.name,
    presenting: renderer.xr.isPresenting,
    enabledFeatures: (session as XRSession & { enabledFeatures?: string[] }).enabledFeatures ?? null,
    eyes: xrCamera.cameras.length,
    eyeDistanceMm: right ? Number((left.position.distanceTo(right.position) * 1000).toFixed(1)) : null,
    headGivenM: head.toArray().map((v) => Number(v.toFixed(4))),
    headReportedM: reported.toArray().map((v) => Number(v.toFixed(4))),
    nutTo12thFretM: Number(nut.distanceTo(twelfth).toFixed(4)),
    scaleLengthM: Number((SCALE * 0.01).toFixed(4)),
    xrFrames,
    drawCallsPerFrame: renderer.info.render.calls,
  };
  result.counters = { eyes: xrCamera.cameras.length, nutTo12thFretMm: Math.round(nut.distanceTo(twelfth) * 1000) };
  result.errors = errors;
  publish(result);
}

main().catch((error: Error) => {
  errors.push(`${error.name}: ${error.message}`);
  result.errors = errors;
  publish(result);
});
