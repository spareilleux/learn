// Lesson 7: post-processing with RenderPipeline. The fretboard of lesson 5 gets glowing inlays; bloom spreads their light.
// ?pipeline=none|bloom|bloom-fxaa|direct picks the chain; the probe reads pixels on an inlay, in its halo, and far away.
// ?threshold=0 lets every pixel into the bloom; ?dispose=pipeline|all disposes the chain and counts the render targets left.
import * as THREE from 'three/webgpu';
import { pass, renderOutput } from 'three/tsl';
import { bloom } from 'three/addons/tsl/display/BloomNode.js';
import { fxaa } from 'three/addons/tsl/display/FXAANode.js';
import { backendName, forceWebGL, probing, report } from '../probe.ts';
import { buildFretboard, fretX, NECK_TOP } from '../05-picking/fretboard.ts';

const params = new URLSearchParams(location.search);
const mode = params.get('pipeline') ?? 'bloom';
const threshold = Number(params.get('threshold') ?? 1);
const dispose = params.get('dispose');

const renderer = new THREE.WebGPURenderer({ antialias: mode !== 'bloom-fxaa', forceWebGL });
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.toneMapping = THREE.ACESFilmicToneMapping;
document.body.append(renderer.domElement);

const scene = new THREE.Scene();
scene.background = new THREE.Color(0x1e2127);
scene.add(new THREE.HemisphereLight(0xdde6ff, 0x302820, 1.2));
const sun = new THREE.DirectionalLight(0xffffff, 2);
sun.position.set(1, 4, 3);
scene.add(sun);

const camera = new THREE.PerspectiveCamera(40, window.innerWidth / window.innerHeight, 0.1, 100);
camera.position.set(-0.2, 2.4, 1.6);
camera.lookAt(-0.2, 0.3, 0);

const { board } = buildFretboard();
scene.add(board);

// Inlays that emit light: an emissive intensity of 6 puts them far above 1, where bloom's threshold lets them through
const inlayMaterial = new THREE.MeshStandardMaterial({ color: 0x000000, emissive: 0x7fd4ff, emissiveIntensity: 6 });
const inlayGeometry = new THREE.CircleGeometry(0.035, 32).rotateX(-Math.PI / 2);
const inlays = [3, 5, 7, 9, 12].map((fret) => {
  const inlay = new THREE.Mesh(inlayGeometry, inlayMaterial);
  inlay.position.set((fretX(fret - 1) + fretX(fret)) / 2, NECK_TOP + 0.001, 0);
  scene.add(inlay);
  return inlay;
});

// The chain, as a graph of nodes: the scene pass's color texture, bloom added on top, then the output transform
let pipeline: THREE.RenderPipeline | null = null;
let direct: THREE.DirectRenderPipeline | null = null;
const disposables: { dispose(): void }[] = [];
if (mode === 'bloom' || mode === 'bloom-fxaa') {
  pipeline = new THREE.RenderPipeline(renderer);
  const scenePass = pass(scene, camera);
  const sceneColor = scenePass.getTextureNode('output');
  const glow = bloom(sceneColor, 1.2, 0.4, threshold);
  disposables.push(scenePass, glow);
  if (mode === 'bloom') {
    pipeline.outputNode = sceneColor.add(glow);
  } else {
    // FXAA expects tone-mapped sRGB values: the pipeline's own output transform is turned off and applied before FXAA
    pipeline.outputColorTransform = false;
    pipeline.outputNode = fxaa(renderOutput(sceneColor.add(glow)));
  }
} else if (mode === 'direct') {
  // No effect, and no output pass: tone mapping and the sRGB conversion move into each material's shader
  direct = new THREE.DirectRenderPipeline(renderer);
}

let frames = 0;
renderer.setAnimationLoop(() => {
  if (pipeline) pipeline.render();
  else if (direct) direct.render(scene, camera);
  else renderer.render(scene, camera);
  frames++;
  if (probing && frames === 3) {
    renderer.setAnimationLoop(null);
    const toScreen = (point: THREE.Vector3): [number, number] => {
      const v = point.clone().project(camera);
      return [Math.round(((v.x + 1) / 2) * window.innerWidth), Math.round(((1 - v.y) / 2) * window.innerHeight)];
    };
    const inlay = inlays[1].position;
    if (dispose && pipeline) {
      // RenderPipeline.dispose() frees its own output quad; the scene pass and the bloom own their render targets
      const before = renderer.info.memory.renderTargets;
      pipeline.dispose();
      const afterPipeline = renderer.info.memory.renderTargets;
      if (dispose === 'all') for (const node of disposables) node.dispose();
      report(renderer, { pipeline: mode, renderTargets: { before, afterPipelineDispose: afterPipeline, afterNodesDispose: dispose === 'all' ? renderer.info.memory.renderTargets : undefined } });
      return;
    }
    report(renderer, {
      pipeline: mode,
      threshold,
      renderTargets: renderer.info.memory.renderTargets,
      samples: {
        'inlay at fret 5': toScreen(inlay),
        'halo, 0.06 beside it': toScreen(inlay.clone().add(new THREE.Vector3(0, 0, 0.06))),
        'neck, 0.15 beside it': toScreen(inlay.clone().add(new THREE.Vector3(0, 0, 0.15))),
        background: [20, 20],
      },
    });
  }
});

window.addEventListener('resize', () => {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
});

await renderer.init();
document.title = `Lesson 7 — ${backendName(renderer)}, ${mode}`;
