// Experiment 8: the shadows of the frets, strings and chord markers on the board, five ways, seen close up on the first
// frets. ?shadow=
// - none;
// - map: a dynamic shadow map of ?size= texels (1024, 2048, 4096) from the directional light, redrawn every frame;
// - once: the same shadow map drawn on the first frame only (shadow.autoUpdate = false);
// - baked: an ambient occlusion texture for the board, baked on the CPU by casting ?rays= rays per texel (16) against the
//   frets, strings and markers as analytic cylinders and spheres, used as the board's aoMap;
// - contact: the occluders drawn from above into a 512 × 128 render target, darker the closer they are to the board,
//   then sampled with a 25-tap blur by a transparent plane lying on the board: one extra pass per frame.
import * as THREE from 'three/webgpu';
import { clamp, float, positionWorld, texture, uv, vec2, vec4 } from 'three/tsl';
import { C_MAJOR } from '../../../src/13-fretboard/guitar.ts';
import { BOARD_THICKNESS, FRETS, fretX, markerX, NUT_WIDTH, SCALE, STRINGS, stringZ, boardLength } from '../../../src/13-fretboard/guitar.ts';
import { counters, createRenderer, finish, guard, measure, num, str } from '../lab.ts';
import { buildInstancedNecks, stringRadius } from '../neck.ts';

const mode = str('shadow', 'none');
const mapSize = num('size', 2048);
const rays = num('rays', 16);
const width = num('w', 1920);
const height = num('h', 1080);
const TOP = BOARD_THICKNESS / 2;

// The board's top as a plane with its own UVs: u along the board (X), v across it (from +Z to −Z)
const length = boardLength();
const centerX = length / 2 - SCALE / 2;

// Analytic ray tests for the bake: frets as cylinders along Z, strings along X, markers as spheres
function occluded(origin: THREE.Vector3, dir: THREE.Vector3): boolean {
  const hitCylinder = (a: number, b: number, da: number, db: number, ca: number, cb: number, r: number) => {
    // A cylinder along the third axis: solve |(a, b) + t (da, db) − (ca, cb)| = r for t > 0
    const oa = a - ca;
    const ob = b - cb;
    const A = da * da + db * db;
    const B = 2 * (oa * da + ob * db);
    const C = oa * oa + ob * ob - r * r;
    const disc = B * B - 4 * A * C;
    if (A === 0 || disc < 0) return false;
    return (-B + Math.sqrt(disc)) / (2 * A) > 1e-4;
  };
  for (let n = 1; n <= FRETS; n++) if (hitCylinder(origin.x, origin.y, dir.x, dir.y, fretX(n), TOP + 0.12, 0.15)) return true;
  for (let s = 0; s < STRINGS; s++) if (hitCylinder(origin.y, origin.z, dir.y, dir.z, 0.55, stringZ(s), stringRadius(s))) return true;
  for (const p of C_MAJOR) {
    const c = new THREE.Vector3(markerX(p.fret), 1.0, stringZ(p.string));
    const oc = origin.clone().sub(c);
    const b = oc.dot(dir);
    const disc = b * b - (oc.lengthSq() - 0.04);
    if (disc >= 0 && -b + Math.sqrt(disc) > 1e-4) return true;
  }
  return false;
}

function bakeAO(texelsX: number, texelsZ: number): THREE.DataTexture {
  const data = new Uint8Array(texelsX * texelsZ * 4);
  const origin = new THREE.Vector3();
  const dir = new THREE.Vector3();
  for (let j = 0; j < texelsZ; j++) {
    for (let i = 0; i < texelsX; i++) {
      origin.set(centerX - length / 2 + ((i + 0.5) / texelsX) * length, TOP + 1e-3, NUT_WIDTH / 2 - ((j + 0.5) / texelsZ) * NUT_WIDTH);
      let hits = 0;
      for (let k = 0; k < rays; k++) {
        // Cosine-weighted directions on a stratified spiral, the same for every texel
        const u = (k + 0.5) / rays;
        const phi = k * 2.399963;
        const r = Math.sqrt(u);
        dir.set(r * Math.cos(phi), Math.sqrt(1 - u), r * Math.sin(phi));
        if (occluded(origin, dir)) hits++;
      }
      const ao = Math.round(255 * (1 - 0.85 * (hits / rays)));
      data.set([ao, ao, ao, 255], (j * texelsX + i) * 4);
    }
  }
  const map = new THREE.DataTexture(data, texelsX, texelsZ);
  map.magFilter = THREE.LinearFilter;
  map.needsUpdate = true;
  return map;
}

guard(async () => {
  const renderer = await createRenderer({ width, height });
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  const scene = new THREE.Scene();
  scene.background = new THREE.Color(0x2a2a2a);
  scene.add(new THREE.HemisphereLight(0xffffff, 0x404040, 1.2));
  const light = new THREE.DirectionalLight(0xffffff, 2.5);
  light.position.set(centerX - 20, 12, 8);
  light.target.position.set(-SCALE / 2 + 6, 0, 0);
  scene.add(light, light.target);

  const neck = new THREE.Group();
  buildInstancedNecks(neck, 1, C_MAJOR);
  scene.add(neck);
  // The board of buildInstancedNecks is replaced by a box without its top and a plane for the top, which carries the AO
  const top = new THREE.Mesh(new THREE.PlaneGeometry(length, NUT_WIDTH).rotateX(-Math.PI / 2), new THREE.MeshStandardMaterial({ color: 0x5a3a28, roughness: 0.8 }));
  top.position.set(centerX, TOP + 0.001, 0);
  scene.add(top);

  let bakeMs: number | null = null;
  let beforeFrame: () => void = () => {};
  if (mode === 'map' || mode === 'once') {
    renderer.shadowMap.enabled = true;
    light.castShadow = true;
    light.shadow.mapSize.set(mapSize, mapSize);
    // A shadow camera box around the first twelve frets
    Object.assign(light.shadow.camera, { left: -12, right: 12, top: 8, bottom: -8, near: 1, far: 60 });
    light.shadow.bias = -0.0005;
    neck.traverse((o) => void ((o as THREE.Mesh).isMesh && o.name !== 'board' && (o.castShadow = true)));
    top.receiveShadow = true;
    if (mode === 'once') {
      light.shadow.autoUpdate = false;
      light.shadow.needsUpdate = true;
    }
  } else if (mode === 'baked') {
    const start = performance.now();
    (top.material as THREE.MeshStandardMaterial).aoMap = bakeAO(512, 128);
    (top.material as THREE.MeshStandardMaterial).aoMapIntensity = 1;
    bakeMs = performance.now() - start;
  } else if (mode === 'contact') {
    const target = new THREE.RenderTarget(512, 128);
    const above = new THREE.OrthographicCamera(-length / 2, length / 2, NUT_WIDTH / 2, -NUT_WIDTH / 2, 0, 3);
    above.position.set(centerX, TOP + 3, 0);
    above.up.set(0, 0, -1);
    above.lookAt(centerX, TOP, 0);
    above.updateMatrixWorld();
    // Occluders only, black, more opaque the closer to the board (1.2 units of falloff)
    const depthMaterial = new THREE.MeshBasicNodeMaterial({ transparent: true });
    depthMaterial.colorNode = vec4(0, 0, 0, clamp(float(1).sub(positionWorld.y.sub(TOP).div(1.2)), 0, 1));
    const blurred = (() => {
      const texel = vec2(1 / 512, 1 / 128).mul(2);
      const taps = [];
      for (let x = -2; x <= 2; x++) for (let y = -2; y <= 2; y++) taps.push(texture(target.texture, uv().add(vec2(x, y).mul(texel))).a);
      return taps.reduce((sum, tap) => sum.add(tap)).div(25);
    })();
    const contactMaterial = new THREE.MeshBasicNodeMaterial({ transparent: true, depthWrite: false });
    contactMaterial.colorNode = vec4(0, 0, 0, blurred.mul(0.8));
    const contact = new THREE.Mesh(new THREE.PlaneGeometry(length, NUT_WIDTH).rotateX(-Math.PI / 2), contactMaterial);
    contact.position.set(centerX, TOP + 0.002, 0);
    scene.add(contact);
    const board = neck.getObjectByName('board')!;
    beforeFrame = () => {
      top.visible = false;
      board.visible = false;
      contact.visible = false;
      const background = scene.background;
      scene.background = null;
      scene.overrideMaterial = depthMaterial;
      renderer.setRenderTarget(target);
      renderer.setClearColor(0x000000, 0);
      renderer.clear();
      renderer.render(scene, above);
      renderer.setRenderTarget(null);
      renderer.setClearColor(0x000000, 1);
      scene.overrideMaterial = null;
      scene.background = background;
      top.visible = true;
      board.visible = true;
      contact.visible = true;
    };
  }

  const camera = new THREE.PerspectiveCamera(40, width / height, 0.1, 200);
  camera.position.set(-SCALE / 2 + 1, 5, 7);
  camera.lookAt(-SCALE / 2 + 7, 0, 0);

  // The first frame draws the shadow map in both map modes: counted apart
  renderer.info.reset();
  beforeFrame();
  renderer.render(scene, camera);
  const firstFrame = counters(renderer);
  const { stats, counters: c } = await measure(renderer, () => {
    beforeFrame();
    renderer.render(scene, camera);
  });
  finish(renderer, {
    shadow: mode,
    mapSize: mode === 'map' || mode === 'once' ? mapSize : null,
    rays: mode === 'baked' ? rays : null,
    bakeMs: bakeMs === null ? null : Math.round(bakeMs),
    firstFrame: { drawCalls: firstFrame.drawCalls, triangles: firstFrame.triangles },
    stats,
    counters: { firstFrameDrawCalls: firstFrame.drawCalls, drawCalls: c.drawCalls, triangles: c.triangles, renderTargets: c.renderTargets },
    info: counters(renderer),
  });
});
