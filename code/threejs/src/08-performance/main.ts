// Lesson 8: the same 10,000 note markers drawn five ways, and what renderer.info and a timer say about each.
// ?mode=meshes|unshared|instanced|tiles|batched|lod, ?count=10000, ?view=all|close (close leaves most markers out of the frustum).
// Fields whose name ends in Ms are CPU times: they vary between runs and machines, and check.sh doesn't compare them.
import * as THREE from 'three/webgpu';
import { backendName, forceWebGL, probing, report } from '../probe.ts';

const params = new URLSearchParams(location.search);
const mode = params.get('mode') ?? 'meshes';
const count = Number(params.get('count') ?? 10_000);
const view = params.get('view') ?? 'all';

const renderer = new THREE.WebGPURenderer({ antialias: true, forceWebGL });
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.setSize(window.innerWidth, window.innerHeight);
document.body.append(renderer.domElement);

const scene = new THREE.Scene();
scene.background = new THREE.Color(0x1e2127);
scene.add(new THREE.HemisphereLight(0xdde6ff, 0x302820, 1.5));
const sun = new THREE.DirectionalLight(0xffffff, 2.5);
sun.position.set(1, 4, 3);
scene.add(sun);

const camera = new THREE.PerspectiveCamera(50, window.innerWidth / window.innerHeight, 0.1, 100);
if (view === 'close') {
  // Looking down on one corner of the grid, 1.5 units above it
  camera.position.set(-4, 1.5, 4);
  camera.lookAt(-4, 0, 3.9);
} else {
  camera.position.set(0, 9, 8);
  camera.lookAt(0, 0, 0);
}

// A square grid, 0.1 apart, centered on the origin
const side = Math.ceil(Math.sqrt(count));
const positionOf = (i: number, target: THREE.Vector3) =>
  target.set((i % side) * 0.1 - (side - 1) * 0.05, 0, Math.floor(i / side) * 0.1 - (side - 1) * 0.05);

const setupStart = performance.now();
const position = new THREE.Vector3();
const matrix = new THREE.Matrix4();
// 80 triangles (detail 1); detail 2 has 320 and detail 0 has 20, for the levels of detail
const geometry = new THREE.IcosahedronGeometry(0.03, 1);
const material = new THREE.MeshStandardMaterial({ color: 0xffb454, roughness: 0.5 });

if (mode === 'meshes') {
  // One Mesh per marker, all sharing one geometry and one material
  for (let i = 0; i < count; i++) {
    const marker = new THREE.Mesh(geometry, material);
    positionOf(i, marker.position);
    scene.add(marker);
  }
} else if (mode === 'unshared') {
  // The same, but each marker builds its own geometry and material, as a loop that calls new inside does
  for (let i = 0; i < count; i++) {
    const marker = new THREE.Mesh(new THREE.IcosahedronGeometry(0.03, 1), new THREE.MeshStandardMaterial({ color: 0xffb454, roughness: 0.5 }));
    positionOf(i, marker.position);
    scene.add(marker);
  }
} else if (mode === 'instanced') {
  // One object, one geometry, a matrix per instance in a GPU buffer
  const markers = new THREE.InstancedMesh(geometry, material, count);
  for (let i = 0; i < count; i++) markers.setMatrixAt(i, matrix.makeTranslation(positionOf(i, position)));
  markers.computeBoundingSphere();
  scene.add(markers);
} else if (mode === 'tiles') {
  // Exercise: the grid cut into 4 × 4 InstancedMesh tiles, so that frustum culling can skip whole tiles
  const tiles = 4;
  const perTile: number[][] = Array.from({ length: tiles * tiles }, () => []);
  for (let i = 0; i < count; i++) {
    const tile = Math.floor(((i % side) * tiles) / side) + tiles * Math.floor((Math.floor(i / side) * tiles) / side);
    perTile[tile].push(i);
  }
  for (const markers of perTile) {
    const mesh = new THREE.InstancedMesh(geometry, material, markers.length);
    markers.forEach((i, n) => mesh.setMatrixAt(n, matrix.makeTranslation(positionOf(i, position))));
    // The bounding sphere covers the instances, not the geometry at the origin: compute it after setting the matrices
    mesh.computeBoundingSphere();
    scene.add(mesh);
  }
} else if (mode === 'batched') {
  // One object that can hold different geometries; each instance is culled on its own (perObjectFrustumCulled)
  const markers = new THREE.BatchedMesh(count, geometry.attributes.position.count, geometry.index?.count, material);
  const id = markers.addGeometry(geometry);
  for (let i = 0; i < count; i++) markers.setMatrixAt(markers.addInstance(id), matrix.makeTranslation(positionOf(i, position)));
  scene.add(markers);
} else if (mode === 'lod') {
  // A LOD per marker: 320 triangles up close, 80 from 3 units, 20 from 8 units
  const levels = [2, 1, 0].map((detail) => new THREE.IcosahedronGeometry(0.03, detail));
  const distances = [0, 3, 8];
  for (let i = 0; i < count; i++) {
    const lod = new THREE.LOD();
    levels.forEach((level, n) => lod.addLevel(new THREE.Mesh(level, material), distances[n]));
    positionOf(i, lod.position);
    scene.add(lod);
  }
}
const setupMs = performance.now() - setupStart;

let frames = 0;
let firstFrameMs = 0;
renderer.setAnimationLoop(() => {
  const start = performance.now();
  renderer.render(scene, camera);
  if (frames === 0) firstFrameMs = performance.now() - start;
  frames++;
  if (probing && frames === 3) {
    renderer.setAnimationLoop(null);
    // info.render is reset at the start of each animation frame, not at each render() call: read it before timing
    const { calls, drawCalls, triangles } = renderer.info.render;
    const { geometries, textures, programs } = renderer.info.memory;
    // The CPU side of a frame: renderer.render() prepares and submits the commands, the GPU works afterwards
    const timed = 60;
    const timerStart = performance.now();
    for (let i = 0; i < timed; i++) renderer.render(scene, camera);
    const renderMs = (performance.now() - timerStart) / timed;
    report(renderer, {
      mode,
      count,
      view,
      sceneChildren: scene.children.length,
      render: { calls, drawCalls, triangles },
      memory: { geometries, textures, programs },
      setupMs: Number(setupMs.toFixed(1)),
      firstFrameMs: Number(firstFrameMs.toFixed(1)),
      renderMs: Number(renderMs.toFixed(2)),
    });
  }
});

window.addEventListener('resize', () => {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
});

await renderer.init();
document.title = `Lesson 8 — ${backendName(renderer)}, ${mode}`;
