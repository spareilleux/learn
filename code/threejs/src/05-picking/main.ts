// Lesson 5: pointing at a fretboard. A Raycaster turns the pointer into a ray, the hit point into a fret, a string and a
// note, and OrbitControls turns a drag into a camera orbit.
// ?sidebar puts a 240 px panel left of the canvas, where pointer coordinates computed from the window go wrong.
import * as THREE from 'three/webgpu';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { backendName, forceWebGL, probing, report } from '../probe.ts';
import { buildFretboard, fretAt, noteName, pressPoint, stringAt } from './fretboard.ts';

const params = new URLSearchParams(location.search);

const renderer = createRenderer();
const scene = new THREE.Scene();
scene.background = new THREE.Color(0x1e2127);
scene.add(new THREE.HemisphereLight(0xdde6ff, 0x302820, 1.5));
const sun = new THREE.DirectionalLight(0xffffff, 2.5);
sun.position.set(1, 4, 3);
scene.add(sun);

const camera = new THREE.PerspectiveCamera(40, 1, 0.1, 100);
camera.position.set(-0.2, 2.4, 1.6);

const { board } = buildFretboard();
scene.add(board);

// A small sphere shows where the finger would press
const marker = new THREE.Mesh(new THREE.SphereGeometry(0.03, 16, 8), new THREE.MeshStandardMaterial({ color: 0xffb454, emissive: 0x7a4a00 }));
marker.visible = false;
scene.add(marker);

const controls = new OrbitControls(camera, renderer.domElement);
controls.target.set(-0.2, 0.3, 0);
controls.enableDamping = params.has('damping');
controls.update();

// The pointer in normalized device coordinates (−1 to 1), from the canvas's own rectangle
const pointer = new THREE.Vector2();
let pointerInside = false;
let pointerMoved = false;
renderer.domElement.addEventListener('pointermove', (event) => {
  const rect = renderer.domElement.getBoundingClientRect();
  pointer.set(((event.clientX - rect.left) / rect.width) * 2 - 1, -((event.clientY - rect.top) / rect.height) * 2 + 1);
  pointerInside = true;
  pointerMoved = true;
});
renderer.domElement.addEventListener('pointerleave', () => {
  pointerInside = false;
  pointerMoved = true;
});

// The same pointer computed from the window, as many examples do: wrong as soon as the canvas doesn't start at (0, 0)
const pointerFromWindow = new THREE.Vector2();
window.addEventListener('pointermove', (event) => {
  pointerFromWindow.set((event.clientX / window.innerWidth) * 2 - 1, -(event.clientY / window.innerHeight) * 2 + 1);
});

const raycaster = new THREE.Raycaster();
type Pick = { object: string; point: number[]; fret: number | null; string: number; note: string | null } | null;

function pick(ndc: THREE.Vector2): Pick {
  raycaster.setFromCamera(ndc, camera);
  // Recursive: the fretboard group's children are the neck, the frets and the strings
  const [hit] = raycaster.intersectObject(board, true);
  if (!hit) return null;
  const fret = fretAt(hit.point.x);
  const string = stringAt(hit.point.z);
  return {
    object: hit.object.name,
    point: hit.point.toArray().map((n) => Number(n.toFixed(3))),
    fret,
    string,
    note: fret === null ? null : noteName(string, fret),
  };
}

let hover: Pick = null;
function updateHover() {
  if (!pointerMoved) return;
  pointerMoved = false;
  hover = pointerInside ? pick(pointer) : null;
  marker.visible = hover !== null;
  if (hover) marker.position.fromArray(hover.point);
}

let frames = 0;
renderer.setAnimationLoop(() => {
  // At most one raycast per frame, and only when the pointer moved: pointermove can fire several times per frame
  updateHover();
  controls.update();
  renderer.render(scene, camera);
  frames++;
  if (probing && frames === 3) startProbe();
});

function resize() {
  const canvas = renderer.domElement;
  const { clientWidth, clientHeight } = canvas.parentElement!;
  camera.aspect = clientWidth / clientHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(clientWidth, clientHeight);
  canvas.dataset.size = `${clientWidth}x${clientHeight}`;
}
window.addEventListener('resize', resize);
resize();

// Where a point of the scene is on the page, in CSS pixels
function toPage(point: THREE.Vector3): [number, number] {
  const rect = renderer.domElement.getBoundingClientRect();
  const ndc = point.clone().project(camera);
  return [Math.round(rect.left + ((ndc.x + 1) / 2) * rect.width), Math.round(rect.top + ((1 - ndc.y) / 2) * rect.height)];
}

function startProbe() {
  const rect = renderer.domElement.getBoundingClientRect();
  const center: [number, number] = [Math.round(rect.left + rect.width / 2), Math.round(rect.top + rect.height / 2)];
  report(renderer, {
    canvas: [rect.left, rect.top, rect.width, rect.height],
    // scripts/probe.mjs performs each action with Playwright's mouse, then calls window.probeAfter(name);
    // the screenshot is taken after the action named in shotAfter
    shotAfter: 'string 3, fret 5',
    actions: [
      { name: 'string 3, fret 5', move: toPage(pressPoint(3, 5)) },
      { name: 'string 6, fret 8', move: toPage(pressPoint(6, 8)) },
      { name: 'beside the neck', move: [center[0], Math.round(rect.top + 20)] },
      { name: 'orbit 120 px right', drag: [center[0], center[1], center[0] + 120, center[1]] },
    ],
  });
  renderer.setAnimationLoop(null);
  const round = (v: THREE.Vector3) => v.toArray().map((n) => Number(n.toFixed(3)));
  window.probeAfter = async (name: string) => {
    // Two frames: one for the loop to see the pointer, one to draw the marker
    for (let i = 0; i < 2; i++) {
      updateHover();
      controls.update();
      renderer.render(scene, camera);
      await new Promise(requestAnimationFrame);
    }
    if (name.startsWith('orbit')) return { camera: round(camera.position), target: round(controls.target) };
    return { pick: hover, pickFromWindow: params.has('sidebar') ? pick(pointerFromWindow) : undefined };
  };
}

// A renderer whose canvas fills its container, not the window
function createRenderer(): THREE.WebGPURenderer {
  if (params.has('sidebar')) {
    const sidebar = document.createElement('aside');
    sidebar.className = 'sidebar';
    sidebar.textContent = 'Chords';
    document.body.append(sidebar);
  }
  const container = document.createElement('div');
  container.className = 'viewport';
  document.body.append(container);
  const renderer = new THREE.WebGPURenderer({ antialias: true, forceWebGL });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  container.append(renderer.domElement);
  return renderer;
}

declare global {
  interface Window {
    probeAfter?: (name: string) => Promise<unknown>;
  }
}

await renderer.init();
document.title = `Lesson 5 — ${backendName(renderer)}`;
