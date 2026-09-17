// Lesson 10: Rapier without a browser: node scripts/l10-rapier.ts
// 24 picks dropped onto the fretboard, stepped at a fixed 1/60 s, with the two builds of Rapier: the standard one and the
// cross-platform deterministic one. check.sh compares everything the deterministic build prints, and prints the
// standard build's state hash apart, since its README promises determinism on the same machine only.
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { performance } from 'node:perf_hooks';
import { NECK_TOP } from '../src/05-picking/fretboard.ts';
import { createWorld, PICKS, round, stateBytes, STEP, type Rapier } from '../src/10-physics/world.ts';

const hash = (bytes: Uint8Array) => createHash('sha256').update(bytes).digest('hex').slice(0, 16);

// Both packages embed the same kind of WebAssembly module, base64-encoded in their JavaScript (the "compat" builds)
async function load(name: string): Promise<Rapier> {
  const start = performance.now();
  const RAPIER = (await import(name)) as Rapier;
  await RAPIER.init();
  const size = readFileSync(`node_modules/${name}/dist/rapier.mjs`).length;
  console.log(`${name} ${RAPIER.version()}: rapier.mjs is ${size.toLocaleString('en-US')} bytes, loaded and initialized in ${(performance.now() - start).toFixed(1)} ms`);
  return RAPIER;
}

const deterministic = await load('@dimforge/rapier3d-deterministic-compat');
const standard = await load('@dimforge/rapier3d-compat');

// 1. Three seconds at a fixed step
const { world, picks } = createWorld(deterministic);
console.log(`\nfixed step of ${STEP.toFixed(5)} s, ${PICKS} picks, ${world.colliders.len()} colliders`);
for (let step = 1; step <= 180; step++) {
  world.step();
  if (step % 60 === 0) {
    const heights = picks.map((body) => body.translation().y);
    const onNeck = heights.filter((y) => y > NECK_TOP - 0.01 && y < NECK_TOP + 0.1).length;
    const sleeping = picks.filter((body) => body.isSleeping()).length;
    console.log(
      `t = ${(step * STEP).toFixed(1)} s: ${onNeck} on the neck, ${heights.filter((y) => y < 0).length} on the floor, ${sleeping} asleep, lowest y ${round(Math.min(...heights))}`,
    );
  }
}
const first = picks[0].translation();
console.log(`pick 0 at [${round(first.x)}, ${round(first.y)}, ${round(first.z)}]`);
console.log(`deterministic build, state hash after 180 steps: ${hash(stateBytes(picks))}`);

// The same world with the standard build: same machine, same result every run; another OS may differ
const other = createWorld(standard);
for (let step = 1; step <= 180; step++) other.world.step();
console.log(`standard build, state hash after 180 steps: ${hash(stateBytes(other.picks))}`);
const gap = Math.max(...picks.map((body, i) => distance(body.translation(), other.picks[i].translation())));
console.log(`largest distance between a pick in the two builds: ${gap < 1e-6 ? 'under 1 µm' : `${round(gap * 1000, 1)} mm`}`);

// 2. The same three seconds with a variable step, as a loop that passes each frame's duration: 1/144 s to 1/30 s
const variable = createWorld(deterministic);
let seed = 7;
const random = () => ((seed = (seed * 48271) % 2147483647) / 2147483647);
let elapsed = 0;
let frames = 0;
while (elapsed < 3 - 1e-9) {
  const dt = Math.min(1 / 144 + random() * (1 / 30 - 1 / 144), 3 - elapsed);
  variable.world.timestep = dt;
  variable.world.step();
  elapsed += dt;
  frames++;
}
const moved = picks.map((body, i) => distance(body.translation(), variable.picks[i].translation()));
console.log(
  `\nvariable step, ${frames} steps for the same 3 s: ${moved.filter((d) => d > 0.01).length} picks more than 1 cm away from the fixed-step run, the farthest ${round(Math.max(...moved), 2)} m, at y = ${round(variable.picks[moved.indexOf(Math.max(...moved))].translation().y, 2)}`,
);

// 3. A snapshot: the world's bytes, restored into a new world that carries on identically
const again = createWorld(deterministic);
for (let step = 1; step <= 60; step++) again.world.step();
const snapshot = again.world.takeSnapshot();
for (let step = 61; step <= 180; step++) again.world.step();
const restored = deterministic.World.restoreSnapshot(snapshot);
for (let step = 61; step <= 180; step++) restored.step();
const restoredPicks: typeof picks = [];
restored.forEachRigidBody((body) => {
  if (body.isDynamic()) restoredPicks.push(body);
});
console.log(`\nsnapshot at step 60: ${snapshot.length.toLocaleString('en-US')} bytes`);
console.log(`step 180, continued: ${hash(stateBytes(again.picks))}; step 180, restored then stepped: ${hash(stateBytes(restoredPicks))}`);

// 4. A small, fast ball and a thin wall, fixed or dynamic, with and without continuous collision detection (CCD)
for (const wall of ['fixed', 'dynamic']) {
  for (const ccd of [false, true]) {
    const R = deterministic;
    const box = new R.World({ x: 0, y: 0, z: 0 });
    const wallBody = wall === 'dynamic' ? box.createRigidBody(R.RigidBodyDesc.dynamic()) : undefined;
    box.createCollider(R.ColliderDesc.cuboid(0.012, 1, 1), wallBody);
    const ball = box.createRigidBody(R.RigidBodyDesc.dynamic().setTranslation(-2.5, 0.3, 0).setLinvel(60, 0, 0).setCcdEnabled(ccd));
    box.createCollider(R.ColliderDesc.ball(0.005), ball);
    const xs: number[] = [];
    for (let step = 0; step < 5; step++) {
      box.step();
      xs.push(round(ball.translation().x, 2));
    }
    console.log(`${wall} 2.4 cm wall, 1 cm ball at 60 m/s, CCD ${ccd ? 'on ' : 'off'}: x = ${xs.join(', ')}`);
  }
}

function distance(a: { x: number; y: number; z: number }, b: { x: number; y: number; z: number }) {
  return Math.hypot(a.x - b.x, a.y - b.y, a.z - b.z);
}
