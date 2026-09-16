// Lesson 3: color spaces and tone mapping, measured on flat patches
// Top row: linear intensities from 0.05 to 8. Bottom row: the same gray given four ways.
// ?tone=none|aces|agx|neutral picks the renderer's tone mapping; scripts/probe.mjs reads the pixels at the patch centers.
import * as THREE from 'three/webgpu';
import { backendName, forceWebGL, probing, report } from '../probe.ts';

const toneMappings = {
  none: THREE.NoToneMapping,
  aces: THREE.ACESFilmicToneMapping,
  agx: THREE.AgXToneMapping,
  neutral: THREE.NeutralToneMapping,
} as const;
const tone = (new URLSearchParams(location.search).get('tone') ?? 'none') as keyof typeof toneMappings;

const renderer = new THREE.WebGPURenderer({ antialias: true, forceWebGL });
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.toneMapping = toneMappings[tone];
document.body.append(renderer.domElement);

const scene = new THREE.Scene();
scene.background = new THREE.Color(0x1e2127);

// 16 by 9 units, whatever the size of the window
const camera = new THREE.OrthographicCamera(-8, 8, 4.5, -4.5, 0.1, 10);
camera.position.z = 5;

const patches = new Map<string, THREE.Mesh>();
function patch(name: string, material: THREE.Material, x: number, y: number) {
  const mesh = new THREE.Mesh(new THREE.PlaneGeometry(2, 2), material);
  mesh.position.set(x, y, 0);
  scene.add(mesh);
  patches.set(name, mesh);
}

// Linear values, as a light would produce them: 1 is not the brightest a scene can be
[0.05, 0.18, 0.5, 1, 2, 8].forEach((value, i) => {
  const color = new THREE.Color().setRGB(value, value, value, THREE.LinearSRGBColorSpace);
  patch(`linear ${value}`, new THREE.MeshBasicMaterial({ color }), -6.25 + i * 2.5, 2);
});

// A one-pixel texture holding the byte 128, read as sRGB or as raw data
function grayTexture(colorSpace: string) {
  const texture = new THREE.DataTexture(new Uint8Array([128, 128, 128, 255]), 1, 1);
  texture.colorSpace = colorSpace;
  texture.needsUpdate = true;
  return texture;
}
patch('texture 128, SRGBColorSpace', new THREE.MeshBasicMaterial({ map: grayTexture(THREE.SRGBColorSpace) }), -3.75, -2);
patch('texture 128, NoColorSpace', new THREE.MeshBasicMaterial({ map: grayTexture(THREE.NoColorSpace) }), -1.25, -2);
// A hex color is sRGB; setRGB() without a color space takes working-space (linear) values
patch('Color(0x808080)', new THREE.MeshBasicMaterial({ color: new THREE.Color(0x808080) }), 1.25, -2);
patch('setRGB(0.5, 0.5, 0.5)', new THREE.MeshBasicMaterial({ color: new THREE.Color().setRGB(0.5, 0.5, 0.5) }), 3.75, -2);

let frames = 0;
renderer.setAnimationLoop(() => {
  renderer.render(scene, camera);
  frames++;
  if (probing && frames === 3) {
    renderer.setAnimationLoop(null);
    const samples: Record<string, [number, number]> = {};
    for (const [name, mesh] of patches) {
      const ndc = mesh.position.clone().project(camera);
      samples[name] = [Math.round(((ndc.x + 1) / 2) * window.innerWidth), Math.round(((1 - ndc.y) / 2) * window.innerHeight)];
    }
    report(renderer, { tone, samples });
  }
});

window.addEventListener('resize', () => renderer.setSize(window.innerWidth, window.innerHeight));

await renderer.init();
document.title = `Lesson 3 — ${backendName(renderer)}, tone mapping ${tone}`;
