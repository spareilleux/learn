// Experiment 14: the same GA fretboard with the C major chord, ?impl=r3f (r3f.tsx: lesson 13's Fretboard3D in React
// Three Fiber) or ?impl=vanilla (vanilla.ts: the same objects without React), each loaded with a dynamic import, so
// that the page's own code is the same for both.
// Differences left in on purpose: Fretboard3D's strings vibrate in TSL (the vanilla strings are plain), and it listens
// to pointer events. Reported: time from navigation start to the first rendered frame, per-frame CPU time, the
// JavaScript heap after a garbage collection (Chromium started with --js-flags=--expose-gc and
// --enable-precise-memory-info), and renderer.info. The bundle sizes come from scripts/bundle-sizes.mjs.
import { counters, finish, forceWebGL, guard, measure, prepare, str } from '../lab.ts';

const impl = str('impl', 'r3f');

function heapMB(): number | null {
  (globalThis as { gc?: () => void }).gc?.();
  const memory = (performance as Performance & { memory?: { usedJSHeapSize: number } }).memory;
  return memory ? Math.round((memory.usedJSHeapSize / 1024 / 1024) * 100) / 100 : null;
}

guard(async () => {
  const heapBefore = heapMB();
  const { start } = impl === 'r3f' ? await import('./r3f.tsx') : await import('./vanilla.ts');
  const { renderer, draw } = await start(1200, 400, forceWebGL);
  prepare(renderer);
  draw(0);
  await (renderer.backend as unknown as { device?: GPUDevice }).device?.queue.onSubmittedWorkDone();
  const firstFrameMs = performance.now();
  const { stats, counters: c } = await measure(renderer, draw);
  finish(renderer, {
    impl,
    firstFrameSinceNavigationMs: Math.round(firstFrameMs),
    heapMB: { beforeScene: heapBefore, afterFrames: heapMB() },
    stats,
    counters: { drawCalls: c.drawCalls, triangles: c.triangles, geometries: c.geometries, textures: c.textures },
    info: counters(renderer),
  });
});
