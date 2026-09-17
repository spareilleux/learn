// What every page of the lab shares: its query parameters, a renderer of a fixed size, a frame timer, and the result it
// hands to scripts/run.mjs through lesson 12's window.probe (src/probe.ts).
//
// Frame timing, the same on every page:
// - no requestAnimationFrame: the page renders frame after frame in a loop, so the display's refresh rate (vsync) never
//   paces it; scripts/run.mjs also starts Chromium with --disable-gpu-vsync and --disable-frame-rate-limit;
// - cpuMs: the time of the page's frame function (JavaScript work and renderer.render(), which records and submits the
//   commands);
// - wallMs: cpuMs plus the wait until the GPU has finished: GPUQueue.onSubmittedWorkDone() on WebGPU, a 1-pixel
//   readPixels() on WebGL 2, which blocks until the queue is done; presentation to the screen isn't included;
// - gpuMs: the render and compute passes' durations from timestamp queries (WebGPU's timestamp-query feature, or WebGL's
//   EXT_disjoint_timer_query_webgl2), resolved after every frame; null when the backend doesn't offer them.
// Counters (renderer.info) are read from the last timed frame; info.autoReset is off, and each frame resets it and
// advances the node frame, as setAnimationLoop would.
import * as THREE from 'three/webgpu';
import { backendName, forceWebGL, gpuName, probing, publish } from '../../src/probe.ts';

export { backendName, forceWebGL, gpuName, probing };
export const params = new URLSearchParams(location.search);
export const num = (key: string, fallback: number): number => (params.has(key) ? Number(params.get(key)) : fallback);
export const str = (key: string, fallback: string): string => params.get(key) ?? fallback;
// ?ci: counters only, with few frames, for the CI runners' software rasterizer
export const ci = params.has('ci');

export type Summary = { median: number; p95: number; mean: number; min: number; max: number };
export type FrameStats = { frames: number; cpuMs: Summary; wallMs: Summary; gpuMs: Summary | null; gpuTimer: string };
export type Counters = { drawCalls: number; triangles: number; points: number; lines: number; geometries: number; textures: number; programs: number; texturesMB: number; renderTargets: number };

export function summarize(values: number[]): Summary {
  const sorted = [...values].sort((a, b) => a - b);
  const at = (q: number) => sorted[Math.min(sorted.length - 1, Math.floor(q * sorted.length))];
  const round = (v: number) => Math.round(v * 1000) / 1000;
  return {
    median: round(at(0.5)),
    p95: round(at(0.95)),
    mean: round(values.reduce((a, b) => a + b, 0) / values.length),
    min: round(sorted[0]),
    max: round(sorted[sorted.length - 1]),
  };
}

export type RendererOptions = { width?: number; height?: number; pixelRatio?: number } & ConstructorParameters<typeof THREE.WebGPURenderer>[0];

// A renderer of a fixed size in CSS pixels (?w=, ?h=) and pixel ratio (?pr=), whatever the window, appended to the page
export async function createRenderer(options: RendererOptions = {}): Promise<THREE.WebGPURenderer> {
  const { width = 1280, height = 720, pixelRatio = 1, ...rest } = options;
  const renderer = new THREE.WebGPURenderer({ antialias: true, forceWebGL, trackTimestamp: !ci, ...rest });
  await renderer.init();
  prepare(renderer);
  renderer.setPixelRatio(num('pr', pixelRatio));
  renderer.setSize(num('w', width), num('h', height));
  document.body.append(renderer.domElement);
  return renderer;
}

// For renderers the lab doesn't create (GaFretboard's, R3F's): the same timing setup after the fact. The WebGPU backend
// asks for every feature the adapter has, so timestamp queries can be turned on after init().
export function prepare(renderer: THREE.WebGPURenderer): void {
  renderer.info.autoReset = false;
  const backend = renderer.backend as unknown as { trackTimestamp: boolean; device?: GPUDevice; disjoint?: unknown };
  if (!ci) backend.trackTimestamp = backend.device ? backend.device.features.has('timestamp-query') : Boolean(backend.disjoint);
}

export function gpuTimer(renderer: THREE.WebGPURenderer): string {
  const backend = renderer.backend as unknown as { trackTimestamp: boolean; device?: GPUDevice };
  if (!backend.trackTimestamp) return ci ? 'off (ci)' : backend.device ? 'none: no timestamp-query feature' : 'none: no EXT_disjoint_timer_query_webgl2';
  return backend.device ? 'WebGPU timestamp-query' : 'EXT_disjoint_timer_query_webgl2';
}

const pixel = new Uint8Array(4);
export async function gpuDone(renderer: THREE.WebGPURenderer): Promise<void> {
  const backend = renderer.backend as unknown as { device?: GPUDevice; gl?: WebGL2RenderingContext };
  if (backend.device) {
    await backend.device.queue.onSubmittedWorkDone();
  } else if (backend.gl) {
    const gl = backend.gl;
    const framebuffer = gl.getParameter(gl.FRAMEBUFFER_BINDING);
    gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    gl.readPixels(0, 0, 1, 1, gl.RGBA, gl.UNSIGNED_BYTE, pixel);
    gl.bindFramebuffer(gl.FRAMEBUFFER, framebuffer);
  }
}

export function counters(renderer: THREE.WebGPURenderer): Counters {
  const { render, memory } = renderer.info;
  return {
    drawCalls: render.drawCalls,
    triangles: render.triangles,
    points: render.points,
    lines: render.lines,
    geometries: memory.geometries,
    textures: memory.textures,
    programs: memory.programs,
    texturesMB: Math.round((memory.texturesSize / 1024 / 1024) * 100) / 100,
    renderTargets: memory.renderTargets,
  };
}

// Renders `frames` timed frames after `warmup` untimed ones; frame(i) must do the rendering
export async function measure(
  renderer: THREE.WebGPURenderer,
  frame: (i: number) => void | Promise<void>,
  { frames = ci ? 3 : 240, warmup = ci ? 2 : 30, compute = false }: { frames?: number; warmup?: number; compute?: boolean } = {},
): Promise<{ stats: FrameStats; counters: Counters }> {
  const cpu: number[] = [];
  const wall: number[] = [];
  const gpu: number[] = [];
  const backend = renderer.backend as unknown as { trackTimestamp: boolean };
  let last = counters(renderer);
  for (let i = 0; i < warmup + frames; i++) {
    renderer.info.reset();
    // What the renderer's own animation loop does before each frame: nodes updated once per frame (shadow maps,
    // time) see a new frame
    const { nodeFrame } = (renderer as unknown as { _nodes: { nodeFrame: { update(): void; frameId: number } } })._nodes;
    const start = performance.now();
    nodeFrame.update();
    (renderer.info as { frame: number }).frame = nodeFrame.frameId;
    await frame(i);
    const submitted = performance.now();
    last = counters(renderer);
    await gpuDone(renderer);
    const done = performance.now();
    let gpuMs: number | undefined;
    if (backend.trackTimestamp) {
      gpuMs = (await renderer.resolveTimestampsAsync('render')) ?? 0;
      if (compute) gpuMs += (await renderer.resolveTimestampsAsync('compute')) ?? 0;
    }
    if (i < warmup) continue;
    cpu.push(submitted - start);
    wall.push(done - start);
    if (gpuMs !== undefined) gpu.push(gpuMs);
  }
  return {
    stats: { frames, cpuMs: summarize(cpu), wallMs: summarize(wall), gpuMs: gpu.length ? summarize(gpu) : null, gpuTimer: gpuTimer(renderer) },
    counters: last,
  };
}

// What every page reports: the backend and adapter, then the experiment's own fields. `counters` holds what CI compares;
// everything else is printed or written to results.json.
export function finish(renderer: THREE.WebGPURenderer | null, result: Record<string, unknown>): void {
  const adapter = (renderer?.backend as unknown as { device?: { adapterInfo?: GPUAdapterInfo } } | undefined)?.device?.adapterInfo;
  publish({
    backend: renderer ? backendName(renderer) : null,
    gpu: renderer ? gpuName(renderer) : null,
    adapter: adapter ? { vendor: adapter.vendor, architecture: adapter.architecture, device: adapter.device, description: adapter.description } : null,
    drawingBuffer: renderer ? `${renderer.domElement.width}x${renderer.domElement.height}` : null,
    userAgent: navigator.userAgent,
    crossOriginIsolated,
    ...result,
  });
}

// A failure is a result too: the page reports it instead of hanging until the runner's timeout
export function guard(run: () => Promise<void>): void {
  if (!probing) {
    void run();
    return;
  }
  run().catch((error: unknown) => publish({ error: String((error as Error)?.stack ?? error) }));
}

// The camera of GA's ThreeFretboard (lines 222-224) on a canvas of the given size
export function gaCamera(width: number, height: number): THREE.PerspectiveCamera {
  const camera = new THREE.PerspectiveCamera(35, width / height, 0.1, 1000);
  camera.position.set(-12, 18, 40);
  camera.lookAt(0, 0, 0);
  camera.updateMatrixWorld();
  return camera;
}

// A deterministic pseudo-random sequence (mulberry32), so that every run and every backend sees the same points
export function random(seed: number): () => number {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
