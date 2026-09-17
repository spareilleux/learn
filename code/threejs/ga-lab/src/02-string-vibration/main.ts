// Experiment 2: plucked strings three ways, with the same standing wave as lesson 13's Fretboard3D:
// the strings move sideways, parallel to the fretboard:
//   offset(u, t) = 0.12 × sin(πu) × cos(ω t') × exp(−3 t'), t' = t + phase, u along the string.
// ?method=cpu (one geometry per gauge, every vertex rewritten each frame), tsl (an InstancedMesh per gauge, the offset
// computed in the vertex shader from a time uniform), morph (an InstancedMesh per gauge with one morph target, the
// influence set per instance each frame); ?strings=6|600 (a multiple of 6: one guitar's gauges, repeated).
// Time is virtual: frame i shows t = 0.02 + (i mod 60) / 240 s, and the screenshot t = 0.05 s, so every method draws the
// same instants.
import * as THREE from 'three/webgpu';
import { cos, exp, float, instancedBufferAttribute, positionLocal, sin, uniform, uv, vec3 } from 'three/tsl';
import { FRETS, fretDistance, stringZ } from '../../../src/13-fretboard/guitar.ts';
import { counters, createRenderer, finish, guard, measure, num, str } from '../lab.ts';
import { addLights, stringRadius } from '../neck.ts';

const method = str('method', 'tsl');
const strings = num('strings', 6);
const width = num('w', 1280);
const height = num('h', num('strings', 6) <= 6 ? 360 : 720);
const perGauge = Math.ceil(strings / 6);
const columns = Math.ceil(Math.sqrt(perGauge));
const LENGTH = fretDistance(FRETS) + (fretDistance(FRETS) - fretDistance(FRETS - 1)) * 3;
const AMPLITUDE = 0.12;

const omega = (gauge: number) => 60 - gauge * 6;
const phase = (guitar: number) => ((guitar * 7) % 11) * 0.01;
const amplitude = (gauge: number, guitar: number, t: number) => {
  const age = t + phase(guitar);
  return AMPLITUDE * Math.cos(omega(gauge) * age) * Math.exp(-3 * age);
};
const guitarOrigin = (guitar: number) => new THREE.Vector3((guitar % columns) * 70, 0, Math.floor(guitar / columns) * 6);
const timeAt = (i: number) => 0.02 + (i % 60) / 240;

// A string along X, of its real radius, 32 segments along its length
function stringGeometry(gauge: number): THREE.BufferGeometry {
  return new THREE.CylinderGeometry(stringRadius(gauge), stringRadius(gauge), LENGTH, 12, 32, true).rotateZ(Math.PI / 2);
}

guard(async () => {
  const renderer = await createRenderer({ width, height });
  const scene = new THREE.Scene();
  addLights(scene);
  const material = () => new THREE.MeshStandardNodeMaterial({ color: 0xd0c8b8, metalness: 0.5, roughness: 0.3 });
  let update: (t: number) => void = () => {};
  const setupStart = performance.now();

  if (method === 'cpu') {
    const updates: ((t: number) => void)[] = [];
    for (let gauge = 0; gauge < 6; gauge++) {
      const pieces: THREE.BufferGeometry[] = [];
      const one = stringGeometry(gauge);
      for (let guitar = 0; guitar < perGauge; guitar++) {
        const o = guitarOrigin(guitar);
        pieces.push(one.clone().translate(o.x, o.y + 0.55, o.z + stringZ(gauge)));
      }
      const { mergeGeometries } = await import('three/addons/utils/BufferGeometryUtils.js');
      const geometry = mergeGeometries(pieces)!;
      const position = geometry.attributes.position as THREE.BufferAttribute;
      position.setUsage(THREE.DynamicDrawUsage);
      const base = Float32Array.from(position.array);
      const shape = new Float32Array(position.count);
      const uvs = geometry.attributes.uv;
      for (let v = 0; v < position.count; v++) shape[v] = Math.sin(Math.PI * uvs.getY(v));
      const perString = one.attributes.position.count;
      scene.add(new THREE.Mesh(geometry, material()));
      updates.push((t) => {
        const array = position.array as Float32Array;
        for (let guitar = 0; guitar < perGauge; guitar++) {
          const a = amplitude(gauge, guitar, t);
          for (let v = guitar * perString, end = v + perString; v < end; v++) array[v * 3 + 2] = base[v * 3 + 2] + a * shape[v];
        }
        position.needsUpdate = true;
      });
    }
    update = (t) => updates.forEach((u) => u(t));
  } else {
    const time = uniform(0);
    const dummy = new THREE.Mesh();
    dummy.morphTargetInfluences = [0];
    const meshes: THREE.InstancedMesh[] = [];
    for (let gauge = 0; gauge < 6; gauge++) {
      const geometry = stringGeometry(gauge);
      const m = material();
      if (method === 'morph') {
        // One morph target: the fundamental's shape at full amplitude, blended by a per-instance influence
        const base = geometry.attributes.position;
        const delta = new Float32Array(base.count * 3);
        for (let v = 0; v < base.count; v++) delta[v * 3 + 2] = AMPLITUDE * Math.sin(Math.PI * geometry.attributes.uv.getY(v));
        geometry.morphAttributes.position = [new THREE.BufferAttribute(delta, 3)];
        // The target holds displacements, not positions: without this flag the base mesh is scaled by 1 - influence
        geometry.morphTargetsRelative = true;
      }
      const mesh = new THREE.InstancedMesh(geometry, m, perGauge);
      // r186's InstancedMesh has no morphTargetInfluences. With a single instance, the morph node reads them instead of
      // the per-instance texture, and fails on null unless they exist; with more than one, it reads the texture, and
      // setting them fails instead (the unused influence uniform array is updated before it has a buffer)
      if (method === 'morph' && perGauge === 1) mesh.morphTargetInfluences = [0];
      const matrix = new THREE.Matrix4();
      const phases = new Float32Array(perGauge);
      for (let guitar = 0; guitar < perGauge; guitar++) {
        const o = guitarOrigin(guitar);
        mesh.setMatrixAt(guitar, matrix.makeTranslation(o.x, o.y + 0.55, o.z + stringZ(gauge)));
        phases[guitar] = phase(guitar);
        if (method === 'morph') {
          dummy.morphTargetInfluences[0] = 0;
          mesh.setMorphAt(guitar, dummy);
        }
      }
      if (method === 'tsl') {
        const age = time.add(instancedBufferAttribute(new THREE.InstancedBufferAttribute(phases, 1), 'float'));
        const offset = float(AMPLITUDE).mul(sin(uv().y.mul(Math.PI))).mul(cos(age.mul(omega(gauge)))).mul(exp(age.mul(-3)));
        m.positionNode = positionLocal.add(vec3(0, 0, offset));
      }
      mesh.computeBoundingSphere();
      // The vibration leaves the bounding sphere a little: no culling surprises between methods
      mesh.frustumCulled = false;
      scene.add(mesh);
      meshes.push(mesh);
    }
    update =
      method === 'tsl'
        ? (t) => void (time.value = t)
        : (t) => {
            meshes.forEach((mesh, gauge) => {
              for (let guitar = 0; guitar < perGauge; guitar++) {
                dummy.morphTargetInfluences![0] = amplitude(gauge, guitar, t) / AMPLITUDE;
                mesh.setMorphAt(guitar, dummy);
              }
              if (perGauge === 1) mesh.morphTargetInfluences![0] = dummy.morphTargetInfluences![0];
              mesh.morphTexture!.needsUpdate = true;
            });
          };
  }
  const setupMs = performance.now() - setupStart;

  const camera = new THREE.PerspectiveCamera(35, width / height, 0.1, 5000);
  if (strings <= 6) {
    // Straight down on the strings, 36 units above: the whole length in view, a 0.12-unit displacement about 2 pixels
    camera.up.set(0, 0, -1);
    camera.position.set(0, 36, 0);
    camera.lookAt(0, 0, 0);
  } else {
    const rows = Math.ceil(perGauge / columns);
    const center = new THREE.Vector3(((columns - 1) * 70) / 2, 0, ((rows - 1) * 6) / 2);
    camera.position.copy(center).add(new THREE.Vector3(-60, 260, 380));
    camera.lookAt(center);
  }

  const { stats, counters: c } = await measure(renderer, (i) => {
    update(timeAt(i));
    renderer.render(scene, camera);
  });
  // The instant shown in the screenshot, the same for every method
  update(0.05);
  renderer.render(scene, camera);
  finish(renderer, {
    method,
    strings,
    verticesPerString: stringGeometry(0).attributes.position.count,
    setupMs: Math.round(setupMs * 10) / 10,
    stats,
    counters: { drawCalls: c.drawCalls, triangles: c.triangles, geometries: c.geometries, textures: c.textures },
    info: counters(renderer),
  });
});
