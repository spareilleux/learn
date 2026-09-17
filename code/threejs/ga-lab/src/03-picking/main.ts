// Experiment 3: picking one note among many, two ways, at the same pseudo-random screen points.
// ?notes=10000 markers in one InstancedMesh, a square grid seen from above at an angle; ?picks=200.
// - Raycaster: setFromCamera and intersectObject, as lesson 5 does; InstancedMesh.raycast tests every instance.
// - GPU ID pass: the camera's view narrowed to the one pixel under the pointer (setViewOffset), the scene drawn with a
//   material that writes instanceIndex + 1 as a color into a 1 × 1 render target, and the pixel read back with
//   readRenderTargetPixelsAsync. The time of a pick covers the draw and the round trip of the readback.
import * as THREE from 'three/webgpu';
import { float, instanceIndex, vec3, vec4 } from 'three/tsl';
import { ci, counters, createRenderer, finish, guard, measure, num, random, summarize } from '../lab.ts';

const notes = num('notes', 10_000);
const picks = num('picks', ci ? 20 : 200);
const width = num('w', 1280);
const height = num('h', 720);

guard(async () => {
  const renderer = await createRenderer({ width, height });
  const scene = new THREE.Scene();
  scene.background = new THREE.Color(0x1e2127);
  scene.add(new THREE.HemisphereLight(0xdde6ff, 0x302820, 1.5));
  const sun = new THREE.DirectionalLight(0xffffff, 2.5);
  sun.position.set(1, 4, 3);
  scene.add(sun);

  // A square grid, 0.1 apart; markers of radius 0.045 cover about 60% of the grid's area
  const side = Math.ceil(Math.sqrt(notes));
  const geometry = new THREE.IcosahedronGeometry(0.045, 1);
  const markers = new THREE.InstancedMesh(geometry, new THREE.MeshStandardMaterial({ color: 0xffb454, roughness: 0.5 }), notes);
  const matrix = new THREE.Matrix4();
  for (let i = 0; i < notes; i++) {
    markers.setMatrixAt(i, matrix.makeTranslation((i % side) * 0.1 - (side - 1) * 0.05, 0, Math.floor(i / side) * 0.1 - (side - 1) * 0.05));
  }
  markers.computeBoundingSphere();
  scene.add(markers);

  const camera = new THREE.PerspectiveCamera(50, width / height, 0.1, 1000);
  const extent = side * 0.1;
  camera.position.set(0, extent * 0.75, extent * 0.62);
  camera.lookAt(0, 0, 0);
  camera.updateMatrixWorld();

  // The ID material: instanceIndex + 1 in three bytes, so 0 means "nothing"
  const idMaterial = new THREE.MeshBasicNodeMaterial();
  const id = instanceIndex.toFloat().add(1);
  idMaterial.colorNode = vec4(vec3(id.mod(256), id.div(256).floor().mod(256), id.div(65536).floor()).div(255), float(1));
  const target = new THREE.RenderTarget(1, 1, { type: THREE.UnsignedByteType, depthBuffer: true });

  const random01 = random(42);
  const points = Array.from({ length: picks }, () => [Math.floor(random01() * width), Math.floor(random01() * height)] as const);

  const raycaster = new THREE.Raycaster();
  const ndc = new THREE.Vector2();
  function rayPick(x: number, y: number): number {
    ndc.set(((x + 0.5) / width) * 2 - 1, -(((y + 0.5) / height) * 2 - 1));
    raycaster.setFromCamera(ndc, camera);
    const hit = raycaster.intersectObject(markers, false)[0];
    return hit?.instanceId ?? -1;
  }

  const background = scene.background;
  const pickCamera = camera.clone();
  async function gpuPick(x: number, y: number): Promise<number> {
    pickCamera.setViewOffset(width, height, x, y, 1, 1);
    scene.overrideMaterial = idMaterial;
    scene.background = null;
    renderer.setRenderTarget(target);
    renderer.setClearColor(0x000000, 0);
    renderer.clear();
    renderer.render(scene, pickCamera);
    renderer.setRenderTarget(null);
    scene.overrideMaterial = null;
    scene.background = background;
    const pixel = (await renderer.readRenderTargetPixelsAsync(target, 0, 0, 1, 1)) as Uint8Array;
    return pixel[0] + pixel[1] * 256 + pixel[2] * 65536 - 1;
  }

  // Warm up both: the first raycast allocates, the first ID pass compiles its shader and creates the readback buffer
  rayPick(width / 2, height / 2);
  await gpuPick(width / 2, height / 2);

  const rayMs: number[] = [];
  const gpuMs: number[] = [];
  const rayIds: number[] = [];
  let agree = 0;
  const disagreements: { x: number; y: number; ray: number; gpu: number }[] = [];
  for (const [x, y] of points) {
    let start = performance.now();
    const r = rayPick(x, y);
    rayMs.push(performance.now() - start);
    start = performance.now();
    const g = await gpuPick(x, y);
    gpuMs.push(performance.now() - start);
    rayIds.push(r);
    if (r === g) agree++;
    else if (disagreements.length < 10) disagreements.push({ x, y, ray: r, gpu: g });
  }

  renderer.setClearColor(0x000000, 1);
  const { stats, counters: c } = await measure(renderer, () => renderer.render(scene, camera), { frames: ci ? 2 : 60, warmup: ci ? 1 : 10 });
  finish(renderer, {
    notes,
    picks,
    raycasterMs: summarize(rayMs),
    gpuPickMs: summarize(gpuMs),
    agreement: `${agree}/${picks}`,
    hits: rayIds.filter((i) => i >= 0).length,
    disagreements,
    stats,
    counters: { drawCalls: c.drawCalls, triangles: c.triangles },
    checks: { raycasterIds: rayIds.slice(0, 20) },
    info: counters(renderer),
  });
});
