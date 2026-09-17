// Experiment 10: a shop wall of ?count= guitar bodies (1,000: 50 columns × 20 rows, 0.5 m apart, on the plane z = 0)
// from public/generated/guitar-body.glb (scripts/guitar-body.ts: LOD0, LOD1, LOD2). The camera walks along the wall,
// 3 m in front of it, looking ahead at 35° to it, over 240 frames. ?lod=on uses a THREE.LOD per body (LOD0 under 2 m,
// LOD1 under 6 m, LOD2 beyond), ?lod=off LOD0 everywhere; ?cull=off sets frustumCulled = false on every mesh.
// The page averages renderer.info's draw calls and triangles over the path.
import * as THREE from 'three/webgpu';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { ci, counters, createRenderer, finish, guard, measure, num, str } from '../lab.ts';

const lod = str('lod', 'on') === 'on';
const cull = str('cull', 'on') === 'on';
const count = num('count', 1000);
const width = num('w', 1280);
const height = num('h', 720);
const FRAMES = ci ? 5 : 240;

guard(async () => {
  const renderer = await createRenderer({ width, height });
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  const scene = new THREE.Scene();
  scene.background = new THREE.Color(0x2b2622);
  scene.add(new THREE.HemisphereLight(0xfff1e0, 0x3a3028, 2));
  const sun = new THREE.DirectionalLight(0xffffff, 1.5);
  sun.position.set(2, 4, 5);
  scene.add(sun);

  const gltf = await new GLTFLoader().loadAsync('generated/guitar-body.glb');
  const level = (name: string) => gltf.scene.getObjectByName(name) as THREE.Mesh;
  const levels = [level('LOD0'), level('LOD1'), level('LOD2')];
  const columns = Math.min(50, Math.ceil(Math.sqrt(count * 2.5)));
  for (let i = 0; i < count; i++) {
    const x = (i % columns) * 0.5 - (columns - 1) * 0.25;
    const y = Math.floor(i / columns) * 0.5 + 0.3;
    let body: THREE.Object3D;
    if (lod) {
      const group = new THREE.LOD();
      [0, 2, 6].forEach((distance, n) => group.addLevel(new THREE.Mesh(levels[n].geometry, levels[n].material), distance));
      body = group;
    } else {
      body = new THREE.Mesh(levels[0].geometry, levels[0].material);
    }
    body.position.set(x, y, 0);
    // Hanging with a slight tilt, different per body
    body.rotation.set(0.15, ((i * 37) % 11) * 0.02 - 0.1, 0);
    if (!cull) body.traverse((o) => void (o.frustumCulled = false));
    scene.add(body);
  }

  const camera = new THREE.PerspectiveCamera(50, width / height, 0.05, 100);
  const half = (columns - 1) * 0.25;
  const at = (i: number) => {
    const t = (i % FRAMES) / FRAMES;
    camera.position.set(-half + t * 2 * half, 1.6, 3);
    // Looking ahead along the wall: 35° between the view direction and the wall
    camera.lookAt(camera.position.x + 3 / Math.tan((35 * Math.PI) / 180), 2.2, 0);
    camera.updateMatrixWorld();
  };

  let drawCalls = 0;
  let triangles = 0;
  let frames = 0;
  const { stats, counters: c } = await measure(
    renderer,
    (i) => {
      at(i);
      renderer.render(scene, camera);
      drawCalls += renderer.info.render.drawCalls;
      triangles += renderer.info.render.triangles;
      frames++;
    },
    { frames: FRAMES, warmup: 0 },
  );
  at(Math.floor(FRAMES / 3));
  renderer.render(scene, camera);
  finish(renderer, {
    lod,
    cull,
    count,
    levels: levels.map((m) => (m.geometry.index!.count / 3)),
    stats,
    pathAverage: { drawCalls: Math.round(drawCalls / frames), triangles: Math.round(triangles / frames) },
    counters: { pathDrawCalls: drawCalls, pathTriangles: triangles, drawCalls: c.drawCalls, triangles: c.triangles },
    info: counters(renderer),
  });
});
