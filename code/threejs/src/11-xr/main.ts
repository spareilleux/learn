// Lesson 11: the fretboard in an immersive VR session. Without a headset, IWER (Meta's Immersive Web Emulation Runtime)
// replaces navigator.xr with an emulated Quest 3 whose head and controllers are moved by code.
// ?device=none leaves the browser's own navigator.xr; ?fallback installs three.js's WebGLXRFallback, which swaps the
// WebGPU backend for a WebGL 2 one when the browser can't bind WebXR to WebGPU; ?webgl starts with WebGL 2;
// ?classic draws with the classic WebGLRenderer instead of WebGPURenderer; ?layers installs IWER's WebXR Layers polyfill.
import * as THREE from 'three/webgpu';
import { WebGLRenderer } from 'three';
import { metaQuest3, XRDevice } from 'iwer';
import { setupWebGLXRFallback } from 'three/addons/webxr/WebGLXRFallback.js';
import { backendName, forceWebGL, probing, publish } from '../probe.ts';
import { buildFretboard, fretAt, noteName, pressPoint, stringAt } from '../05-picking/fretboard.ts';

const params = new URLSearchParams(location.search);
const result: Record<string, unknown> = {};
const errors: string[] = [];
const trace = (...args: unknown[]) => params.has('debug') && console.log('[xr]', ...args);

// What the browser offers before any emulation
result.native = {
  navigatorXR: 'xr' in navigator,
  immersiveVR: 'xr' in navigator ? await navigator.xr!.isSessionSupported('immersive-vr').catch((e: Error) => e.name) : null,
  XRGPUBinding: 'XRGPUBinding' in globalThis,
};

// The emulated headset must be installed before the renderer: XRManager checks for XRWebGLBinding in its constructor
let device: XRDevice | null = null;
if (params.get('device') !== 'none') {
  device = new XRDevice(metaQuest3);
  // Chromium already has a navigator.xr, with no device behind it: IWER leaves it alone unless forced
  device.installRuntime({ forceInstall: true, polyfillLayers: params.has('layers') });
  // IWER draws one view on the page unless stereo is on: then the left and right eyes share the canvas
  device.stereoEnabled = true;
  device.position.set(-0.2, 1.6, 0.9);
  // Looking down at the fretboard, 40° below the horizon
  const look = new THREE.Quaternion().setFromAxisAngle(new THREE.Vector3(1, 0, 0), (-40 * Math.PI) / 180);
  device.quaternion.set(look.x, look.y, look.z, look.w);
  result.emulated = { device: device.name, immersiveVR: await navigator.xr!.isSessionSupported('immersive-vr') };
}

let renderer: THREE.WebGPURenderer | WebGLRenderer = params.has('classic')
  ? new WebGLRenderer({ antialias: true })
  : new THREE.WebGPURenderer({ antialias: true, forceWebGL });
const rendererName = (r: typeof renderer) => (r instanceof WebGLRenderer ? 'WebGLRenderer' : `WebGPURenderer, ${backendName(r)}`);
renderer.xr.enabled = true;
document.body.append(renderer.domElement);
renderer.setSize(window.innerWidth, window.innerHeight);
if (renderer instanceof THREE.WebGPURenderer) await renderer.init();
result.rendererBeforeSession = rendererName(renderer);

if (params.has('fallback') && renderer instanceof THREE.WebGPURenderer) {
  setupWebGLXRFallback(
    renderer,
    () => new THREE.WebGPURenderer({ antialias: true, forceWebGL: true }),
    async (fallback, previous) => {
      await fallback.init();
      previous.domElement.replaceWith(fallback.domElement);
      fallback.setSize(window.innerWidth, window.innerHeight);
      renderer = fallback;
      result.fallback = `switched to ${rendererName(fallback)}`;
    },
  );
}

const scene = new THREE.Scene();
scene.background = new THREE.Color(0x1e2127);
scene.add(new THREE.HemisphereLight(0xdde6ff, 0x302820, 1.5));
const sun = new THREE.DirectionalLight(0xffffff, 2.5);
sun.position.set(1, 4, 3);
scene.add(sun);
// In a session, units are meters and y = 0 is the floor ('local-floor'): the fretboard lies on a table, 0.8 m up
const { board } = buildFretboard();
board.scale.setScalar(0.25);
board.position.set(0.3, 0.8, 0);
scene.add(board);

// Outside a session, the page shows the same scene from a regular camera
const camera = new THREE.PerspectiveCamera(50, window.innerWidth / window.innerHeight, 0.05, 50);
camera.position.set(-0.2, 1.6, 0.9);
camera.lookAt(-0.2, 0.8, 0);

// Each controller's target ray: an object that three.js moves to the controller's pose on every XR frame. Controller n is
// the session's nth input source, whichever hand it is: 'connected' tells which one
const raycaster = new THREE.Raycaster();
const picks: unknown[] = [];
for (const index of [0, 1]) {
  const controller = renderer.xr.getController(index);
  scene.add(controller);
  controller.addEventListener('connected', (event) => (controller.userData.handedness = (event.data as XRInputSource).handedness));
  controller.addEventListener('select', () => {
    raycaster.setFromXRController(controller as THREE.XRTargetRaySpace);
    const [hit] = raycaster.intersectObject(board, true);
    const hand = controller.userData.handedness;
    if (!hit) return void picks.push({ controller: index, hand, hit: null });
    const local = board.worldToLocal(hit.point.clone());
    const fret = fretAt(local.x);
    const string = stringAt(local.z);
    picks.push({ controller: index, hand, object: hit.object.name, fret, string, note: fret === null ? null : noteName(string, fret) });
  });
}

let xrFrames = 0;
const frameInfo: unknown[] = [];
function loop() {
  try {
    renderer.render(scene, camera);
  } catch (error) {
    // WebGPURenderer's WebGL 2 backend throws on every XR frame with IWER, whose XRWebGLLayer has no framebuffer: each
    // message is kept once, and the frames go on, so that the probe finishes instead of waiting for frames forever
    const message = `${(error as Error).name}: ${(error as Error).message}`;
    if (!errors.includes(message)) errors.push(message);
  }
  if (renderer.xr.isPresenting) {
    xrFrames++;
    if (xrFrames < 4 || xrFrames % 30 === 0) trace('xr frame', xrFrames);
    if (xrFrames === 3) {
      const xrCamera = renderer.xr.getCamera();
      const [left, right] = xrCamera.cameras;
      frameInfo.push({
        eyes: xrCamera.cameras.length,
        eyeDistanceMm: right ? Number((left.position.distanceTo(right.position) * 1000).toFixed(1)) : null,
        viewport: xrCamera.cameras.map((eye) => (eye as THREE.PerspectiveCamera & { viewport?: THREE.Vector4 }).viewport?.toArray()),
        calls: renderer.info.render.calls,
        triangles: renderer.info.render.triangles,
      });
    }
  }
}
renderer.setAnimationLoop(loop);

// A session is normally requested from a button click: the browser requires a user gesture. IWER doesn't.
async function startSession() {
  try {
    const session = await navigator.xr!.requestSession('immersive-vr', { optionalFeatures: ['local-floor'] });
    result.session = { mode: 'immersive-vr', enabledFeatures: (session as XRSession & { enabledFeatures?: string[] }).enabledFeatures };
    trace('session granted');
    await renderer.xr.setSession(session);
    trace('setSession resolved');
    result.presenting = renderer.xr.isPresenting;
    result.rendererInSession = rendererName(renderer);
  } catch (error) {
    errors.push(`${(error as Error).name}: ${(error as Error).message}`);
  }
}

// Resolves after n XR frames, or after 5 seconds with an error, if the session stopped producing frames
const nextFrames = (n: number) =>
  new Promise<void>((resolve) => {
    const target = xrFrames + n;
    const deadline = performance.now() + 5000;
    const wait = () => {
      if (xrFrames >= target) return resolve();
      if (performance.now() > deadline) {
        errors.push(`no XR frame for 5 s, after ${xrFrames} frames`);
        return resolve();
      }
      setTimeout(wait, 10);
    };
    wait();
  });

if (probing) {
  if ('xr' in navigator) await startSession();
  if (renderer.xr.isPresenting && device) {
    trace('waiting for frames');
    await nextFrames(5);
    trace('5 frames');
    // Point the right controller at string 3, fret 5, and pull the trigger: IWER turns it into select events
    const right = device.controllers.right!;
    const target = board.localToWorld(pressPoint(3, 5));
    right.position.set(0.1, 1.2, 0.5);
    const direction = target.clone().sub(new THREE.Vector3(0.1, 1.2, 0.5)).normalize();
    const q = new THREE.Quaternion().setFromUnitVectors(new THREE.Vector3(0, 0, -1), direction);
    right.quaternion.set(q.x, q.y, q.z, q.w);
    await nextFrames(2);
    right.updateButtonValue('trigger', 1);
    await nextFrames(2);
    right.updateButtonValue('trigger', 0);
    await nextFrames(3);
    result.frames = frameInfo;
    result.picks = picks;
    result.inputSources = renderer.xr.getSession()?.inputSources.length;
    // probe.mjs takes the screenshot during the session, where IWER shows both eyes on the canvas, then ends it
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
  // Removed from the compared output by check.sh, which picks expected/l11_probe_webgpu.webgl.txt on WebGL 2
  if (renderer instanceof THREE.WebGPURenderer) result.backend = backendName(renderer);
  result.errors = errors;
  document.title = `Lesson 11 — ${rendererName(renderer)}`;
  publish(result);
}

declare global {
  interface Window {
    probeAfter?: (name: string) => Promise<unknown>;
  }
}
