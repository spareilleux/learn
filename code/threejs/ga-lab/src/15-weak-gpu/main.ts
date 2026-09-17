// Experiment 15: GA's neck on a weak GPU. The scene is the instanced neck of src/neck.ts with the C major chord (GA's own
// component asks for 8 MSAA samples, which draws nothing on SwiftShader, lesson 13), 1200 × 400 CSS pixels, 4 samples.
// ?pr= fixed pixel ratio (GA's formula gives 3 at a device pixel ratio of 1); ?power=low-power|high-performance passed to
// the renderer, which forwards it to requestAdapter; ?adaptive=1 starts at a pixel ratio of 2 and, every 10 frames, looks
// at the median wall time of those frames: above 95% of a 16.7 ms budget it multiplies the ratio by 0.8 (down to 0.5),
// under 60% it multiplies it by 1.1 (up to 2).
// Run it in chromium-headless-shell, where WebGPURenderer falls back to WebGL 2 on SwiftShader, Chromium's software
// rasterizer, to stand in for a weak GPU.
import * as THREE from 'three/webgpu';
import { C_MAJOR } from '../../../src/13-fretboard/guitar.ts';
import { ci, counters, createRenderer, finish, gaCamera, gpuDone, guard, measure, params, str, summarize } from '../lab.ts';
import { addLights, buildInstancedNecks } from '../neck.ts';

const WIDTH = 1200;
const HEIGHT = 400;
const BUDGET = 16.7;
const power = params.get('power') as GPUPowerPreference | null;

guard(async () => {
  const adaptive = str('adaptive', '0') === '1';
  const renderer = await createRenderer({ width: WIDTH, height: HEIGHT, pixelRatio: adaptive ? 2 : 1, ...(power ? { powerPreference: power } : {}) });
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.2;
  const scene = new THREE.Scene();
  addLights(scene);
  buildInstancedNecks(scene, 1, C_MAJOR);
  const camera = gaCamera(WIDTH, HEIGHT);

  if (!adaptive) {
    const { stats, counters: c } = await measure(renderer, () => renderer.render(scene, camera), { frames: ci ? 3 : 120, warmup: ci ? 2 : 20 });
    finish(renderer, {
      pixelRatio: renderer.getPixelRatio(),
      powerPreference: power,
      stats,
      counters: { drawCalls: c.drawCalls, triangles: c.triangles },
      info: counters(renderer),
    });
    return;
  }

  // The adaptive loop times each frame itself, the same way as measure(): render, then wait for the GPU
  let ratio = 2;
  const trajectory: { frame: number; pixelRatio: number; medianWallMs: number }[] = [];
  let window: number[] = [];
  const all: number[] = [];
  for (let i = 0; i < (ci ? 20 : 120); i++) {
    renderer.info.reset();
    const start = performance.now();
    renderer.render(scene, camera);
    await gpuDone(renderer);
    const wall = performance.now() - start;
    all.push(wall);
    window.push(wall);
    if (window.length === 10) {
      const median = summarize(window).median;
      trajectory.push({ frame: i + 1, pixelRatio: Math.round(ratio * 1000) / 1000, medianWallMs: median });
      if (median > BUDGET * 0.95) ratio = Math.max(0.5, ratio * 0.8);
      else if (median < BUDGET * 0.6) ratio = Math.min(2, ratio * 1.1);
      renderer.setPixelRatio(ratio);
      window = [];
    }
  }
  finish(renderer, {
    adaptive: true,
    budgetMs: BUDGET,
    finalPixelRatio: Math.round(ratio * 1000) / 1000,
    trajectory,
    wallMs: summarize(all),
    counters: { drawCalls: renderer.info.render.drawCalls },
    info: counters(renderer),
  });
});
