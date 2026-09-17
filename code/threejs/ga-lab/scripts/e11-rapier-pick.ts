// Experiment 11: a pick strikes a string, in Rapier (the deterministic build lesson 10 compared across OSes), without a
// browser: node scripts/e11-rapier-pick.ts [--ci]
// Units are SI. The string: 0.648 m from the nut (x = 0) to the bridge, 64 capsule segments of 0.5 mm diameter, steel
// density, joined by spherical joints, the first and last segments fixed; no gravity (a real string's tension keeps it
// straight; joints don't model tension). The pick: a kinematic 15 × 12 × 1 mm box at x = 0.55 m that crosses the string
// sideways (along Z) at 2 m/s, from z = +30 mm to −30 mm, then stops. Each time step runs for 0.5 s with CCD off, on the pick, and on
// the string's segments.
// Per run: whether a collision event started between the pick and the string, whether the pick crossed without moving
// the string by more than 0.1 mm (passed through), the largest relative stretch of any segment (distance between
// neighboring segment centers against the rest length), whether anything became NaN or flew beyond 1 m, and the CPU
// time per simulated second (not in --ci output).
import { performance } from 'node:perf_hooks';
import type RAPIER_API from '@dimforge/rapier3d-compat';

const ci = process.argv.includes('--ci');
const RAPIER = (await import('@dimforge/rapier3d-deterministic-compat')) as unknown as typeof RAPIER_API;
await RAPIER.init();

const LENGTH = 0.648;
const SEGMENTS = 64;
const RADIUS = 0.00025;
const SEGMENT = LENGTH / SEGMENTS;
const PICK_X = 0.55;
const SPEED = 2;
const SIMULATED = 0.5;

type Ccd = 'off' | 'pick' | 'string';
function run(dt: number, ccd: Ccd) {
  const world = new RAPIER.World({ x: 0, y: 0, z: 0 });
  world.timestep = dt;
  const events = new RAPIER.EventQueue(true);
  const segments: RAPIER_API.RigidBody[] = [];
  const stringColliders = new Set<number>();
  for (let i = 0; i < SEGMENTS; i++) {
    const desc = (i === 0 || i === SEGMENTS - 1 ? RAPIER.RigidBodyDesc.fixed() : RAPIER.RigidBodyDesc.dynamic().setCcdEnabled(ccd === 'string')).setTranslation((i + 0.5) * SEGMENT, 0, 0);
    const body = world.createRigidBody(desc);
    // A capsule along Y by default: rotated a quarter turn around Z to lie along X
    const collider = world.createCollider(
      RAPIER.ColliderDesc.capsule(SEGMENT / 2 - RADIUS, RADIUS)
        .setRotation({ x: 0, y: 0, z: Math.SQRT1_2, w: Math.SQRT1_2 })
        .setDensity(7850),
      body,
    );
    stringColliders.add(collider.handle);
    segments.push(body);
  }
  for (let i = 1; i < SEGMENTS; i++) {
    world.createImpulseJoint(RAPIER.JointData.spherical({ x: SEGMENT / 2, y: 0, z: 0 }, { x: -SEGMENT / 2, y: 0, z: 0 }), segments[i - 1], segments[i], true);
  }
  const pick = world.createRigidBody(RAPIER.RigidBodyDesc.kinematicPositionBased().setTranslation(PICK_X, 0, 0.03).setCcdEnabled(ccd === 'pick'));
  world.createCollider(RAPIER.ColliderDesc.cuboid(0.0075, 0.006, 0.0005).setActiveEvents(RAPIER.ActiveEvents.COLLISION_EVENTS), pick);

  let contact = false;
  let maxStretch = 0;
  let maxDisplacement = 0;
  let exploded = false;
  const steps = Math.round(SIMULATED / dt);
  const start = performance.now();
  for (let step = 1; step <= steps; step++) {
    const z = Math.max(-0.03, 0.03 - SPEED * step * dt);
    pick.setNextKinematicTranslation({ x: PICK_X, y: 0, z });
    world.step(events);
    events.drainCollisionEvents((h1, h2, started) => {
      if (started && (stringColliders.has(h1) || stringColliders.has(h2))) contact = true;
    });
    for (let i = 0; i < SEGMENTS; i++) {
      const p = segments[i].translation();
      if (!Number.isFinite(p.x + p.y + p.z) || Math.abs(p.y) > 1 || Math.abs(p.z) > 1) exploded = true;
      maxDisplacement = Math.max(maxDisplacement, Math.hypot(p.y, p.z));
      if (i > 0) {
        const q = segments[i - 1].translation();
        maxStretch = Math.max(maxStretch, Math.abs(Math.hypot(p.x - q.x, p.y - q.y, p.z - q.z) - SEGMENT) / SEGMENT);
      }
    }
  }
  const cpuMs = performance.now() - start;
  world.free();
  const moved = maxDisplacement > 0.0001;
  return {
    stepsPerSecond: Math.round(1 / dt),
    ccd,
    pickTravelPerStepMm: Math.round(SPEED * dt * 1000 * 100) / 100,
    contact,
    stringMoved: moved,
    passedThrough: !moved,
    exploded,
    maxDisplacementMm: exploded ? null : Math.round(maxDisplacement * 1e5) / 100,
    maxStretchPercent: exploded ? null : Math.round(maxStretch * 1e4) / 100,
    ...(ci ? {} : { cpuMsPerSimulatedSecond: Math.round((cpuMs / SIMULATED) * 10) / 10 }),
  };
}

const rates = ci ? [30, 240] : [30, 60, 120, 240, 480, 960];
// A first run, discarded, so that the timed ones don't include the JIT's warm-up
run(1 / 60, 'off');
const runs = rates.flatMap((rate) => (['off', 'pick', 'string'] as const).map((ccd) => run(1 / rate, ccd)));
const result = {
  rapier: `${RAPIER.version()} (deterministic build)`,
  segments: SEGMENTS,
  segmentMm: Math.round(SEGMENT * 1e5) / 100,
  solverIterations: new RAPIER.World({ x: 0, y: 0, z: 0 }).numSolverIterations,
  runs,
  checks: runs.map((r) => `${r.stepsPerSecond} Hz ccd=${r.ccd}: contact=${r.contact} passedThrough=${r.passedThrough} exploded=${r.exploded} stretch=${r.maxStretchPercent}%`),
};
console.log(JSON.stringify(result, null, 2));
