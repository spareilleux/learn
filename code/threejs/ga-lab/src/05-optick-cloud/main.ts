// Experiment 5: the OPTIC-K voicing cloud (scripts/optick-project.ts writes public/generated/optick.bin: two 3D PCA
// projections per voicing). ?count= points: the first ones, or, beyond the file's count, copies with a small
// deterministic offset. ?mode=
// - points: THREE.Points, one pixel per point, static;
// - instanced: an octahedron (8 triangles) per point, from an InstancedBufferGeometry whose offsets are an attribute;
// - cpu-morph: Points whose positions blend projection A into B each frame on the CPU, then upload;
// - compute-morph: the same blend in a compute shader writing a storage buffer the Points read.
// Frame i blends with w = 0.5 − 0.5 cos(0.05 i); the screenshot shows w = 0.3.
import * as THREE from 'three/webgpu';
import { attribute, Fn, instancedArray, instanceIndex, mix, positionLocal, uniform } from 'three/tsl';
import { ci, counters, createRenderer, finish, guard, measure, num, str } from '../lab.ts';

const mode = str('mode', 'points');
const count = num('count', 100_000);
const width = num('w', 1280);
const height = num('h', 720);
const weightAt = (i: number) => 0.5 - 0.5 * Math.cos(0.05 * i);

async function loadCloud(): Promise<{ a: Float32Array; b: Float32Array; available: number; source: string }> {
  const response = await fetch('generated/optick.bin');
  if (!response.ok) throw new Error('generated/optick.bin is missing: run node scripts/optick-project.ts first');
  const bytes = await response.arrayBuffer();
  const [available, flags] = new Uint32Array(bytes, 0, 2);
  const data = new Float32Array(bytes, 8);
  const a = new Float32Array(count * 3);
  const b = new Float32Array(count * 3);
  for (let i = 0; i < count; i++) {
    const j = i % available;
    // Copies beyond the file's count: a small offset from a hash of the index, the same on every run
    const copy = Math.floor(i / available);
    const h = copy === 0 ? 0 : ((Math.imul(i, 2654435761) >>> 0) / 4294967296 - 0.5) * 0.02;
    for (let c = 0; c < 3; c++) {
      a[i * 3 + c] = data[j * 6 + c] + h * (c + 1);
      b[i * 3 + c] = data[j * 6 + 3 + c] + h * (3 - c);
    }
  }
  return { a, b, available, source: flags === 1 ? 'ga-index' : 'synthetic' };
}

guard(async () => {
  const renderer = await createRenderer({ width, height, antialias: false });
  const scene = new THREE.Scene();
  scene.background = new THREE.Color(0x101216);
  const loadStart = performance.now();
  const { a, b, available, source } = await loadCloud();
  const loadMs = performance.now() - loadStart;

  // Color from projection A's position, so clusters keep their color while they move
  const colors = new Float32Array(count * 3);
  for (let i = 0; i < count * 3; i++) colors[i] = 0.35 + 0.3 * Math.max(-1, Math.min(1, a[i]));

  let update: (w: number) => void = () => {};
  let computeNode: THREE.ComputeNode | null = null;
  const weight = uniform(0);

  if (mode === 'points' || mode === 'cpu-morph') {
    const geometry = new THREE.BufferGeometry();
    const position = new THREE.BufferAttribute(Float32Array.from(a), 3);
    geometry.setAttribute('position', position);
    geometry.setAttribute('color', new THREE.BufferAttribute(colors, 3));
    scene.add(new THREE.Points(geometry, new THREE.PointsNodeMaterial({ vertexColors: true })));
    if (mode === 'cpu-morph') {
      position.setUsage(THREE.DynamicDrawUsage);
      const array = position.array as Float32Array;
      update = (w) => {
        for (let i = 0; i < array.length; i++) array[i] = a[i] + (b[i] - a[i]) * w;
        position.needsUpdate = true;
      };
    }
  } else if (mode === 'instanced') {
    const octahedron = new THREE.OctahedronGeometry(0.004);
    const geometry = new THREE.InstancedBufferGeometry();
    geometry.setAttribute('position', octahedron.getAttribute('position'));
    geometry.setAttribute('normal', octahedron.getAttribute('normal'));
    geometry.setAttribute('offset', new THREE.InstancedBufferAttribute(a, 3));
    geometry.setAttribute('pointColor', new THREE.InstancedBufferAttribute(colors, 3));
    geometry.instanceCount = count;
    const material = new THREE.MeshBasicNodeMaterial();
    material.positionNode = positionLocal.add(attribute<'vec3'>('offset', 'vec3'));
    material.colorNode = attribute<'vec3'>('pointColor', 'vec3');
    const mesh = new THREE.Mesh(geometry, material);
    mesh.frustumCulled = false;
    scene.add(mesh);
  } else if (mode === 'compute-morph') {
    // The two projections and the output as storage buffers; the Points read the output as a vertex attribute
    const fromA = instancedArray(a, 'vec3');
    const toB = instancedArray(b, 'vec3');
    const current = instancedArray(Float32Array.from(a), 'vec3');
    computeNode = Fn(() => {
      current.element(instanceIndex).assign(mix(fromA.element(instanceIndex), toB.element(instanceIndex), weight));
    })().compute(count);
    const geometry = new THREE.BufferGeometry();
    geometry.setAttribute('position', new THREE.BufferAttribute(new Float32Array(3), 3));
    const material = new THREE.PointsNodeMaterial();
    material.positionNode = current.toAttribute();
    material.colorNode = instancedArray(colors, 'vec3').toAttribute();
    const points = new THREE.Points(geometry, material);
    points.count = count;
    points.frustumCulled = false;
    scene.add(points);
    update = (w) => {
      weight.value = w;
      renderer.compute(computeNode!);
    };
  }

  const camera = new THREE.PerspectiveCamera(45, width / height, 0.01, 100);
  camera.position.set(1.6, 1.3, 2.4);
  camera.lookAt(0, 0, 0);

  const { stats, counters: c } = await measure(
    renderer,
    (i) => {
      update(weightAt(i));
      renderer.render(scene, camera);
    },
    { compute: mode === 'compute-morph', frames: ci ? 3 : 120, warmup: ci ? 2 : 20 },
  );
  update(0.3);
  renderer.render(scene, camera);
  finish(renderer, {
    mode,
    count,
    source,
    pointsInFile: available,
    loadMs: Math.round(loadMs),
    stats,
    counters: { drawCalls: c.drawCalls, triangles: c.triangles, points: c.points },
    computeCalls: renderer.info.compute.frameCalls,
    info: counters(renderer),
  });
});
