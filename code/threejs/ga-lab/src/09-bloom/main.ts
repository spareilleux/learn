// Experiment 9: the chord's markers glow. GA's neck (instanced, as Fretboard3D) seen close on the first frets, the three
// markers of C major emissive at an intensity of 4, rendered at 1920 × 1080. ?bloom=
// - none: renderer.render, no pipeline;
// - full: RenderPipeline, the scene pass's output plus bloom(output) with threshold 1, at ?scale= of the frame (1 by
//   default; BloomNode's own default is 0.5);
// - half: the same with scale 0.5;
// - selective: the scene pass writes a second target, the emissive color (MRT), and only that feeds the bloom.
import * as THREE from 'three/webgpu';
import { emissive, mrt, output, pass } from 'three/tsl';
import { bloom } from 'three/addons/tsl/display/BloomNode.js';
import { C_MAJOR, SCALE } from '../../../src/13-fretboard/guitar.ts';
import { counters, createRenderer, finish, guard, measure, num, str } from '../lab.ts';
import { addLights, buildInstancedNecks } from '../neck.ts';

const mode = str('bloom', 'none');
const scale = num('scale', mode === 'half' ? 0.5 : 1);
const width = num('w', 1920);
const height = num('h', 1080);

guard(async () => {
  const renderer = await createRenderer({ width, height });
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.2;
  const scene = new THREE.Scene();
  addLights(scene);
  const neck = new THREE.Group();
  buildInstancedNecks(neck, 1, C_MAJOR);
  scene.add(neck);
  const markers = neck.getObjectByName('marker') as THREE.InstancedMesh;
  const markerMaterial = markers.material as THREE.MeshStandardMaterial;
  markerMaterial.emissive.set(0x5ab0ff);
  markerMaterial.emissiveIntensity = 4;

  const camera = new THREE.PerspectiveCamera(40, width / height, 0.1, 200);
  camera.position.set(-SCALE / 2 + 1, 5, 7);
  camera.lookAt(-SCALE / 2 + 7, 0, 0);

  let pipeline: THREE.RenderPipeline | null = null;
  if (mode !== 'none') {
    pipeline = new THREE.RenderPipeline(renderer);
    const scenePass = pass(scene, camera);
    if (mode === 'selective') scenePass.setMRT(mrt({ output, emissive }));
    const color = scenePass.getTextureNode('output');
    const glow = bloom(mode === 'selective' ? scenePass.getTextureNode('emissive') : color, 1, 0.4, mode === 'selective' ? 0 : 1);
    glow.setResolutionScale(scale);
    pipeline.outputNode = color.add(glow);
  }
  const draw = () => (pipeline ? pipeline.render() : renderer.render(scene, camera));

  const { stats, counters: c } = await measure(renderer, draw);
  finish(renderer, {
    bloom: mode,
    resolutionScale: mode === 'none' ? null : scale,
    stats,
    counters: { drawCalls: c.drawCalls, triangles: c.triangles, renderTargets: c.renderTargets },
    info: counters(renderer),
  });
});
