// What check.sh reads from a page: scripts/probe.mjs opens it with ?probe, waits for window.probe, and prints the result.
// ?webgl asks WebGPURenderer for its WebGL 2 backend (forceWebGL).
import type { WebGPURenderer } from 'three/webgpu';

declare global {
  interface Window {
    probe?: Promise<Record<string, unknown>>;
  }
}

const params = new URLSearchParams(location.search);
export const probing = params.has('probe');
export const forceWebGL = params.has('webgl');

let resolveProbe: (value: Record<string, unknown>) => void = () => {};
if (probing) window.probe = new Promise((resolve) => (resolveProbe = resolve));

export function backendName(renderer: WebGPURenderer): string {
  return (renderer.backend as { isWebGPUBackend?: boolean }).isWebGPUBackend ? 'WebGPU' : 'WebGL 2';
}

// What the page hands to the probe, once
export function publish(result: Record<string, unknown>): void {
  resolveProbe(result);
}

// Call right after renderer.render(): the renderer resets info.render at the start of each animation frame
export function report(renderer: WebGPURenderer, extra: Record<string, unknown> = {}): void {
  const { render, memory } = renderer.info;
  publish({
    backend: backendName(renderer),
    frame: renderer.info.frame,
    render: { calls: render.calls, drawCalls: render.drawCalls, triangles: render.triangles },
    memory: { geometries: memory.geometries, textures: memory.textures, programs: memory.programs },
    ...extra,
  });
}
