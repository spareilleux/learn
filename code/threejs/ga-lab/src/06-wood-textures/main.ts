// Experiment 6: the fretboard's wood four ways, on a board that fills the frame, seen from straight above.
// ?wood=
// - texture: public/generated/wood-2048.png (scripts/wood-texture.ts), RGBA8 with mipmaps;
// - ktx2-uastc, ktx2-basis-lz: the same image compressed by scripts/wood-ktx2.sh, loaded with KTX2Loader, which
//   transcodes to a format the GPU supports (BC7 or ASTC for UASTC, BC1/BC3 or ETC for ETC1S);
// - comfyui: public/generated/comfyui-wood.png, a seamless wood from the ComfyUI GA lab's experiment 4, when it exists;
// - procedural: rings and grain computed per pixel in TSL with MaterialX noise, no texture;
// - flat: a plain color, the baseline.
// ?size= (texture only) regenerates a smaller wood in the page instead of loading the file, for CI.
import * as THREE from 'three/webgpu';
import { color, mix, mx_noise_float, smoothstep, uv, vec3 } from 'three/tsl';
import { KTX2Loader } from 'three/addons/loaders/KTX2Loader.js';
import { ci, counters, createRenderer, finish, guard, measure, num, params, str } from '../lab.ts';

const wood = str('wood', 'procedural');
const width = num('w', 1920);
const height = num('h', 1080);

async function loadTexture(renderer: THREE.WebGPURenderer): Promise<{ texture: THREE.Texture | null; details: Record<string, unknown> }> {
  const start = performance.now();
  if (wood === 'texture' || wood === 'comfyui') {
    const file = wood === 'comfyui' ? 'generated/comfyui-wood.png' : 'generated/wood-2048.png';
    if (params.has('size')) {
      // CI: a small checkerboard of the given size, generated here, so no file is needed
      const size = num('size', 256);
      const data = new Uint8Array(size * size * 4).map((_, i) => (i % 4 === 3 ? 255 : ((i >> 2) % size ^ Math.floor(i / 4 / size)) & 8 ? 90 : 40));
      const texture = new THREE.DataTexture(data, size, size);
      texture.generateMipmaps = true;
      texture.minFilter = THREE.LinearMipmapLinearFilter;
      texture.colorSpace = THREE.SRGBColorSpace;
      texture.needsUpdate = true;
      return { texture, details: { source: `generated ${size}x${size}` } };
    }
    const response = await fetch(file, { method: 'HEAD' });
    if (!response.ok) return { texture: null, details: { pending: `${file} not found` } };
    const texture = await new THREE.TextureLoader().loadAsync(file);
    texture.colorSpace = THREE.SRGBColorSpace;
    texture.anisotropy = 8;
    return { texture, details: { source: file, loadMs: Math.round(performance.now() - start), bytes: Number(response.headers.get('content-length')) } };
  }
  const file = `generated/wood-2048-${wood.replace('ktx2-', '')}.ktx2`;
  const loader = new KTX2Loader().setTranscoderPath('generated/basis/');
  loader.detectSupport(renderer);
  const texture = (await loader.loadAsync(file)) as THREE.CompressedTexture;
  texture.anisotropy = 8;
  const bytes = Number((await fetch(file, { method: 'HEAD' })).headers.get('content-length'));
  loader.dispose();
  return {
    texture,
    details: { source: file, bytes, loadMs: Math.round(performance.now() - start), gpuFormat: texture.format, mipmaps: texture.mipmaps?.length ?? 0 },
  };
}

guard(async () => {
  const renderer = await createRenderer({ width, height });
  const scene = new THREE.Scene();
  scene.background = new THREE.Color(0x1e2127);
  scene.add(new THREE.HemisphereLight(0xfff4e6, 0x302820, 2));

  const material = new THREE.MeshStandardNodeMaterial({ roughness: 0.75 });
  let details: Record<string, unknown> = {};
  if (wood === 'procedural') {
    // The same rings as scripts/wood-texture.ts: along the board, warped by noise, with a fine grain
    const p = uv();
    const warp = mx_noise_float(vec3(p.x.mul(4), p.y.mul(12), 0)).mul(0.4).add(mx_noise_float(vec3(p.x.mul(16), p.y.mul(48), 1)).mul(0.1));
    const ring = p.y.mul(12).add(warp).fract();
    const fine = mx_noise_float(vec3(p.x.mul(256), p.y.mul(32), 2)).mul(0.06).add(0.06);
    material.colorNode = mix(color(0x2a170f), color(0x5a3422), smoothstep(0.2, 0.8, ring).add(fine).clamp(0, 1));
  } else if (wood === 'flat') {
    material.color.set(0x3b2418);
  } else {
    const loaded = await loadTexture(renderer);
    details = loaded.details;
    if (!loaded.texture) {
      finish(renderer, { wood, pending: true, ...details, counters: null });
      return;
    }
    material.map = loaded.texture;
  }

  // A board 4 units long and 2.25 wide, exactly filling a 16:9 frame from above
  const board = new THREE.Mesh(new THREE.PlaneGeometry(4, 2.25).rotateX(-Math.PI / 2), material);
  scene.add(board);
  const camera = new THREE.OrthographicCamera(-2, 2, 1.125, -1.125, 0.1, 10);
  camera.position.set(0, 5, 0);
  camera.up.set(0, 0, -1);
  camera.lookAt(0, 0, 0);

  const { stats, counters: c } = await measure(renderer, () => renderer.render(scene, camera));
  finish(renderer, {
    wood,
    ...details,
    stats,
    counters: { drawCalls: c.drawCalls, textures: c.textures, texturesMB: ci ? undefined : c.texturesMB },
    info: counters(renderer),
  });
});
