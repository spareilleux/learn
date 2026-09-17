// What every live demo shares: a WebGPURenderer (WebGL 2 when WebGPU is missing, or with ?webgl) that fills the window
// and follows its size, and a small text overlay. Probing works as in the lessons (src/probe.ts).
import * as THREE from 'three/webgpu';
import { forceWebGL } from '../src/probe.ts';

export async function createRenderer(options: { shadows?: boolean } = {}): Promise<THREE.WebGPURenderer> {
  const renderer = new THREE.WebGPURenderer({ antialias: true, forceWebGL });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  if (options.shadows) {
    renderer.shadowMap.enabled = true;
    renderer.shadowMap.type = THREE.PCFShadowMap;
  }
  document.body.append(renderer.domElement);
  await renderer.init();
  return renderer;
}

// Keeps the renderer and a perspective camera in step with the window, which is the iframe in a lesson
export function followWindow(renderer: THREE.WebGPURenderer, camera: THREE.PerspectiveCamera): void {
  const resize = () => {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
  };
  resize();
  window.addEventListener('resize', resize);
}

// A line of text at the bottom left of the page, for what the demo wants to say (the note played, a count)
export function overlay(): (text: string) => void {
  const element = document.createElement('div');
  element.className = 'overlay';
  document.body.append(element);
  return (text) => void (element.textContent = text);
}

// A click that isn't the end of a drag: OrbitControls turns drags into orbits, so a pick waits for the pointer to come
// back up within a few pixels of where it went down
export function onClick(element: HTMLElement, handler: (event: PointerEvent) => void): void {
  let down: { x: number; y: number } | null = null;
  element.addEventListener('pointerdown', (event) => void (down = { x: event.clientX, y: event.clientY }));
  element.addEventListener('pointerup', (event) => {
    if (down && Math.hypot(event.clientX - down.x, event.clientY - down.y) < 5) handler(event);
    down = null;
  });
}

// Normalized device coordinates of a pointer event, from the canvas's own rectangle (lesson 5)
export function toNdc(event: PointerEvent, canvas: HTMLCanvasElement, target = new THREE.Vector2()): THREE.Vector2 {
  const rect = canvas.getBoundingClientRect();
  return target.set(((event.clientX - rect.left) / rect.width) * 2 - 1, -((event.clientY - rect.top) / rect.height) * 2 + 1);
}

// Where a world point lands on the page, in CSS pixels
export function toScreen(point: THREE.Vector3, camera: THREE.Camera, canvas: HTMLCanvasElement): [number, number] {
  const ndc = point.clone().project(camera);
  const rect = canvas.getBoundingClientRect();
  return [Math.round(rect.left + ((ndc.x + 1) / 2) * rect.width), Math.round(rect.top + ((1 - ndc.y) / 2) * rect.height)];
}
