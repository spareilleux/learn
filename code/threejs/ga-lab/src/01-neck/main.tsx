// Experiment 1: GuitarAlchemist's neck four ways, with the C major chord shown, measured with the same frame timer.
// ?strategy=ga (lesson 13's GaFretboard: one mesh per object), instanced (lesson 13's Fretboard3D in React Three Fiber),
// batched (one BatchedMesh), merged (one merged geometry and an InstancedMesh of markers); ?necks=N side by side;
// ?pr= the pixel ratio (1 by default for all four, GA's own 3 with pr=3).
// The two lesson 13 components run their own loops: once they have drawn, the page stops those loops and renders
// their scene with its own camera, frame after frame, as it does for the two vanilla strategies.
import { flushSync } from 'react-dom';
import { createRoot } from 'react-dom/client';
import { Canvas, type RootState } from '@react-three/fiber';
import * as THREE from 'three/webgpu';
import { GaFretboard, type GaStats } from '../../../src/13-fretboard/GaFretboard.tsx';
import { Fretboard3D } from '../../../src/13-fretboard/Fretboard3D.tsx';
import { C_MAJOR } from '../../../src/13-fretboard/guitar.ts';
import { ci, counters, createRenderer, finish, forceWebGL, guard, measure, num, prepare, str } from '../lab.ts';
import { addLights, buildBatchedNecks, buildMergedNecks, neckOffset, necksCamera, TUNING } from '../neck.ts';

const strategy = str('strategy', 'merged');
const necks = num('necks', 1);
const width = num('w', 1200);
const height = num('h', 400);
const pixelRatio = num('pr', 1);

// Stable arrays: GaFretboard rebuilds its scene whenever positions or tuning change identity (lesson 13)
const POSITIONS = C_MAJOR.map((p) => ({ ...p }));
const waitFrames = (n: number) => new Promise<void>((resolve) => {
  let left = n;
  const tick = () => (--left <= 0 ? resolve() : requestAnimationFrame(tick));
  requestAnimationFrame(tick);
});

async function mountGa(): Promise<{ renderer: THREE.WebGPURenderer; scene: THREE.Scene; buildMs: number }> {
  const stats: GaStats = { builds: 0 };
  const host = document.createElement('div');
  host.style.cssText = `width:${width}px;height:${height}px`;
  document.body.append(host);
  const start = performance.now();
  flushSync(() => createRoot(host).render(<GaFretboard positions={POSITIONS} tuning={TUNING} stats={stats} forceWebGL={forceWebGL} />));
  while (!stats.renderer || !stats.scene) await new Promise(requestAnimationFrame);
  const buildMs = performance.now() - start;
  await waitFrames(3);
  const renderer = stats.renderer;
  renderer.setAnimationLoop(null);
  // GA sets Math.min(devicePixelRatio * 3, 6); the lab compares every strategy at the same pixel ratio unless ?pr= says otherwise
  renderer.setPixelRatio(pixelRatio);
  prepare(renderer);
  const scene = stats.scene;
  // More necks: copies of GA's objects (sharing their geometries and materials, so the draw calls grow, not the programs)
  const originals = scene.children.filter((o) => !(o instanceof THREE.Light));
  for (let i = 1; i < necks; i++) {
    const group = new THREE.Group();
    group.position.copy(neckOffset(i));
    for (const o of originals) group.add(o.clone());
    scene.add(group);
  }
  return { renderer, scene, buildMs };
}

async function mountPort(): Promise<{ renderer: THREE.WebGPURenderer; scene: THREE.Scene; buildMs: number }> {
  const host = document.createElement('div');
  host.style.cssText = `width:${width}px;height:${height}px`;
  document.body.append(host);
  let state: RootState | undefined;
  const start = performance.now();
  createRoot(host).render(
    <Canvas
      frameloop="never"
      dpr={pixelRatio}
      flat={false}
      gl={async (props) => {
        const renderer = new THREE.WebGPURenderer({ ...(props as object), antialias: true, forceWebGL });
        await renderer.init();
        renderer.toneMappingExposure = 1.2;
        return renderer;
      }}
      camera={{ position: [-12, 18, 40], fov: 35 }}
      onCreated={(s) => void (state = s)}
    >
      <color attach="background" args={[0x2a2a2a]} />
      <ambientLight intensity={0.6} />
      <directionalLight position={[10, 30, 20]} intensity={2} />
      {Array.from({ length: necks }, (_, i) => (
        <group key={i} position={neckOffset(i).toArray()}>
          <Fretboard3D positions={POSITIONS} />
        </group>
      ))}
    </Canvas>,
  );
  while (!state) await new Promise(requestAnimationFrame);
  await waitFrames(3);
  const buildMs = performance.now() - start;
  const renderer = state.gl as unknown as THREE.WebGPURenderer;
  prepare(renderer);
  return { renderer, scene: state.scene as unknown as THREE.Scene, buildMs };
}

async function mountVanilla(): Promise<{ renderer: THREE.WebGPURenderer; scene: THREE.Scene; buildMs: number }> {
  const renderer = await createRenderer({ width, height, pixelRatio });
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.2;
  const scene = new THREE.Scene();
  addLights(scene);
  const start = performance.now();
  if (strategy === 'batched') buildBatchedNecks(scene, necks, POSITIONS);
  else buildMergedNecks(scene, necks, POSITIONS);
  return { renderer, scene, buildMs: performance.now() - start };
}

guard(async () => {
  const { renderer, scene, buildMs } = strategy === 'ga' ? await mountGa() : strategy === 'instanced' ? await mountPort() : await mountVanilla();
  const camera = necksCamera(necks, width, height);
  // The first frame compiles the shaders: timed apart
  renderer.info.reset();
  const firstStart = performance.now();
  await renderer.renderAsync(scene, camera);
  const firstFrameMs = performance.now() - firstStart;
  const { stats, counters: c } = await measure(renderer, () => renderer.render(scene, camera));
  let triangles = 0;
  scene.traverse((o) => {
    const mesh = o as THREE.Mesh;
    if (mesh.isMesh && mesh.geometry.index) triangles += (mesh.geometry.index.count / 3) * ((o as THREE.InstancedMesh).count ?? 1);
  });
  finish(renderer, {
    strategy,
    necks,
    pixelRatio: renderer.getPixelRatio(),
    buildMs: Math.round(buildMs * 10) / 10,
    firstFrameMs: Math.round(firstFrameMs * 10) / 10,
    stats,
    counters: { ...c, texturesMB: ci ? undefined : c.texturesMB },
    sceneObjects: (() => {
      let n = 0;
      scene.traverse(() => void n++);
      return n;
    })(),
    indexedTrianglesInScene: triangles,
    info: counters(renderer),
  });
});
