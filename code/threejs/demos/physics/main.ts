// Live demo: guitar picks thrown onto the guitar, simulated by Rapier's deterministic build in WebAssembly (lesson 10).
// The guitar lies on a table; its parts become fixed triangle-mesh colliders, built from the same geometries three.js
// draws. Picks are convex hulls of their shape, drawn as one InstancedMesh. Click to throw a pick from the camera;
// the panel drops a handful, and turns continuous collision detection (CCD) off to watch thin picks go through things.
// ?probe: drops 24 picks from a fixed grid, steps 240 times at 1/60 s, and counts where they came to rest.
import * as THREE from 'three/webgpu';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { RoomEnvironment } from 'three/addons/environments/RoomEnvironment.js';
import GUI from 'three/addons/libs/lil-gui.module.min.js';
import RAPIER_MODULE from '@dimforge/rapier3d-deterministic-compat';
import type RAPIER_API from '@dimforge/rapier3d-compat';
import { backendName, gpuName, probing, publish } from '../../src/probe.ts';
import { createRenderer, followWindow, onClick, overlay, toNdc } from '../common.ts';
import { BODY_TOP, buildGuitar } from '../guitar/model.ts';

const RAPIER = RAPIER_MODULE as unknown as typeof RAPIER_API;
await RAPIER.init();

const STEP = 1 / 60;
const MAX_PICKS = 200;
// The guitar is modeled in units of 10 mm; the physics runs in meters
const UNIT = 0.01;
const TABLE_TOP = (BODY_TOP - 4.5) * UNIT;

const renderer = await createRenderer();
const scene = new THREE.Scene();
scene.background = new THREE.Color(0x2a2e36);
scene.environment = new THREE.PMREMGenerator(renderer).fromScene(new RoomEnvironment(), 0.04).texture;
scene.environmentIntensity = 0.6;
const sun = new THREE.DirectionalLight(0xffffff, 1.6);
sun.position.set(-0.5, 2, 1);
scene.add(sun);

const camera = new THREE.PerspectiveCamera(40, 1, 0.01, 50);
camera.position.set(0.1, 0.62, 0.72);
followWindow(renderer, camera);
const controls = new OrbitControls(camera, renderer.domElement);
controls.target.set(-0.05, 0, 0);
controls.enableDamping = !probing;
controls.maxPolarAngle = Math.PI / 2 - 0.1;
controls.update();

const guitar = buildGuitar();
guitar.group.scale.setScalar(UNIT);
scene.add(guitar.group);
guitar.group.updateMatrixWorld(true);

const table = new THREE.Mesh(new THREE.BoxGeometry(3, 0.04, 1.6), new THREE.MeshStandardMaterial({ color: 0x5b4636, roughness: 0.7 }));
table.position.y = TABLE_TOP - 0.02;
scene.add(table);

const world = new RAPIER.World({ x: 0, y: -9.81, z: 0 });
world.timestep = STEP;
world.createCollider(RAPIER.ColliderDesc.cuboid(1.5, 0.02, 0.8).setTranslation(0, TABLE_TOP - 0.02, 0));

// Every visible part of the guitar becomes one fixed collider: its triangles in world coordinates, one copy per instance
const position = new THREE.Vector3();
const instanceMatrix = new THREE.Matrix4();
let colliderTriangles = 0;
guitar.group.traverse((object) => {
  if (!(object instanceof THREE.Mesh) || !object.visible) return;
  const geometry = object.geometry as THREE.BufferGeometry;
  const source = geometry.attributes.position;
  const index = geometry.index;
  const instances = object instanceof THREE.InstancedMesh ? object.count : 1;
  const vertexCount = source.count;
  const vertices = new Float32Array(vertexCount * instances * 3);
  const indexCount = index ? index.count : vertexCount;
  const indices = new Uint32Array(indexCount * instances);
  for (let i = 0; i < instances; i++) {
    const matrix = object instanceof THREE.InstancedMesh ? object.matrixWorld.clone().multiply((object.getMatrixAt(i, instanceMatrix), instanceMatrix)) : object.matrixWorld;
    for (let v = 0; v < vertexCount; v++) {
      position.fromBufferAttribute(source, v).applyMatrix4(matrix);
      vertices.set([position.x, position.y, position.z], (i * vertexCount + v) * 3);
    }
    for (let k = 0; k < indexCount; k++) indices[i * indexCount + k] = i * vertexCount + (index ? index.getX(k) : k);
  }
  world.createCollider(RAPIER.ColliderDesc.trimesh(vertices, indices).setFriction(0.5));
  colliderTriangles += indices.length / 3;
});

// A pick: a rounded triangle 30 mm tall, 2.5 mm thick (a heavy pick; thinner ones need smaller steps)
const pickShape = new THREE.Shape();
pickShape.moveTo(0, -0.016);
pickShape.bezierCurveTo(0.004, -0.016, 0.016, 0.004, 0.015, 0.009);
pickShape.bezierCurveTo(0.013, 0.015, -0.013, 0.015, -0.015, 0.009);
pickShape.bezierCurveTo(-0.016, 0.004, -0.004, -0.016, 0, -0.016);
const pickGeometry = new THREE.ExtrudeGeometry(pickShape, { depth: 0.0025, bevelEnabled: false, curveSegments: 8 }).translate(0, 0, -0.00125).rotateX(-Math.PI / 2);
const hull = new Float32Array(pickGeometry.attributes.position.array);
const picks = new THREE.InstancedMesh(pickGeometry, new THREE.MeshPhysicalMaterial({ roughness: 0.35, clearcoat: 0.6 }), MAX_PICKS);
// Instance colors must exist before the first render, or the shader is built without them (lesson 13)
picks.instanceColor = new THREE.InstancedBufferAttribute(new Float32Array(MAX_PICKS * 3).fill(1), 3);
picks.count = 0;
picks.frustumCulled = false;
scene.add(picks);
const PALETTE = [0xffb454, 0xff5c5c, 0x5ab0ff, 0x6fd08c, 0xf4c542, 0xb48cff, 0xf2f2f2, 0x222222];

type Pick = { body: RAPIER_API.RigidBody; previous: THREE.Matrix4; current: THREE.Matrix4; color: number };
let thrown = 0;
const bodies: Pick[] = [];
const settings = { ccd: true, 'drop 10': () => dropHandful(10), clear: () => clear() };
const color = new THREE.Color();
const quaternion = new THREE.Quaternion();
const scale = new THREE.Vector3(1, 1, 1);

function addPick(at: THREE.Vector3, velocity: THREE.Vector3, rotation: THREE.Quaternion, spin: THREE.Vector3) {
  if (bodies.length === MAX_PICKS) world.removeRigidBody(bodies.shift()!.body);
  const body = world.createRigidBody(
    RAPIER.RigidBodyDesc.dynamic()
      .setTranslation(at.x, at.y, at.z)
      .setRotation(rotation)
      .setLinvel(velocity.x, velocity.y, velocity.z)
      .setAngvel(spin)
      .setCcdEnabled(settings.ccd),
  );
  world.createCollider(RAPIER.ColliderDesc.convexHull(hull)!.setDensity(1300).setFriction(0.5).setRestitution(0.3), body);
  const matrix = new THREE.Matrix4().compose(at, rotation, scale);
  bodies.push({ body, previous: matrix.clone(), current: matrix, color: PALETTE[thrown++ % PALETTE.length] });
}

// A deterministic sequence for the probe; Math.random otherwise
let seed = 1;
const random = () => (probing ? (seed = (seed * 48271) % 2147483647) / 2147483647 : Math.random());

function dropHandful(n: number) {
  for (let i = 0; i < n; i++) {
    const at = new THREE.Vector3(-0.45 + random() * 0.9, 0.25 + random() * 0.25, -0.12 + random() * 0.24);
    quaternion.setFromEuler(new THREE.Euler(random() * 6.28, random() * 6.28, random() * 6.28));
    addPick(at, new THREE.Vector3(), quaternion.clone(), new THREE.Vector3(random() * 4 - 2, random() * 4 - 2, random() * 4 - 2));
  }
}

function clear() {
  for (const { body } of bodies) world.removeRigidBody(body);
  bodies.length = 0;
}

// Click: throw a pick from just in front of the camera, along the pointer's ray, at 3 m/s
const raycaster = new THREE.Raycaster();
onClick(renderer.domElement, (event) => {
  raycaster.setFromCamera(toNdc(event, renderer.domElement), camera);
  const { origin, direction } = raycaster.ray;
  quaternion.setFromUnitVectors(new THREE.Vector3(0, 1, 0), direction.clone().negate());
  addPick(origin.clone().addScaledVector(direction, 0.1), direction.clone().multiplyScalar(3), quaternion.clone(), new THREE.Vector3(0, 8, 0));
});

const say = overlay();
say('Drag to orbit, click to throw a pick');
if (!probing) {
  const gui = new GUI({ title: 'Picks' });
  gui.add(settings, 'drop 10');
  gui.add(settings, 'clear');
  gui.add(settings, 'ccd').name('CCD for new picks');
  dropHandful(10);
}

const t = new THREE.Vector3();
function step() {
  world.step();
  for (const pick of bodies) {
    pick.previous.copy(pick.current);
    const p = pick.body.translation();
    const r = pick.body.rotation();
    pick.current.compose(t.set(p.x, p.y, p.z), quaternion.set(r.x, r.y, r.z, r.w), scale);
  }
}

// Each pick drawn between its last two states (lesson 10), with its own color
const a = new THREE.Vector3();
const b = new THREE.Quaternion();
const qa = new THREE.Quaternion();
const qb = new THREE.Quaternion();
const drawn = new THREE.Matrix4();
function draw(alpha: number) {
  bodies.forEach((pick, i) => {
    pick.previous.decompose(a, qa, scale);
    pick.current.decompose(t, qb, scale);
    drawn.compose(a.lerp(t, alpha), b.slerpQuaternions(qa, qb, alpha), scale);
    picks.setMatrixAt(i, drawn);
    // Not from body.handle: Rapier's handles are floats that pack an index and a generation into their bits
    picks.setColorAt(i, color.set(pick.color));
  });
  picks.count = bodies.length;
  picks.instanceMatrix.needsUpdate = true;
  picks.instanceColor!.needsUpdate = true;
}

const timer = new THREE.Timer();
let accumulator = 0;
let frames = 0;
renderer.setAnimationLoop((time) => {
  if (!probing) {
    timer.update(time);
    accumulator = Math.min(accumulator + timer.getDelta(), 5 * STEP);
    while (accumulator >= STEP) {
      step();
      accumulator -= STEP;
    }
  }
  guitar.update(time / 1000);
  controls.update();
  draw(probing ? 1 : accumulator / STEP);
  renderer.render(scene, camera);
  frames++;
  // The probe drops and steps between frames 3 and 4, and reads after two more frames of the loop: instance colors
  // written with setColorAt reach the GPU in the renderer's per-frame update, not in a render() called outside the loop
  if (probing && frames === 3) settle();
  if (probing && frames === 6) {
    renderer.setAnimationLoop(null);
    publish(probe());
  }
});

function settle() {
  dropHandful(24);
  for (let i = 0; i < 240; i++) step();
}

function probe() {
  const resting = bodies.map(({ body }) => body.translation().y);
  const { render, memory } = renderer.info;
  return {
    backend: backendName(renderer),
    gpu: gpuName(renderer),
    colliderTriangles,
    picks: bodies.length,
    sleeping: bodies.filter(({ body }) => body.isSleeping()).length,
    onTheGuitar: resting.filter((y) => y > TABLE_TOP + 0.01).length,
    onTheTable: resting.filter((y) => y <= TABLE_TOP + 0.01 && y > TABLE_TOP - 0.01).length,
    belowTheTable: resting.filter((y) => y <= TABLE_TOP - 0.01).length,
    render: { drawCalls: render.drawCalls, triangles: render.triangles },
    memory: { geometries: memory.geometries, textures: memory.textures },
  };
}
