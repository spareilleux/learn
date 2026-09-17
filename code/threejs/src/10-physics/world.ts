// Lesson 10: a Rapier world shared by the page and by scripts/l10-rapier.ts: guitar picks dropped onto a fretboard.
// Rapier's units are meters, kilograms and seconds; the fretboard is lesson 5's, 3.6 m long here, a giant's guitar.
import type RAPIER_API from '@dimforge/rapier3d-compat';
import { FRETS, NECK_TOP, NUT_X, fretX } from '../05-picking/fretboard.ts';

export type Rapier = typeof RAPIER_API;

export const STEP = 1 / 60;
export const PICKS = 24;
export const PICK_SIZE = { x: 0.1, y: 0.02, z: 0.08 };
const NECK_WIDTH = 0.55;

export type PhysicsScene = {
  world: RAPIER_API.World;
  picks: RAPIER_API.RigidBody[];
};

export function createWorld(RAPIER: Rapier): PhysicsScene {
  const world = new RAPIER.World({ x: 0, y: -9.81, z: 0 });
  world.timestep = STEP;

  // The fretboard: fixed colliders, no rigid body needed for what never moves
  const neckLength = fretX(FRETS) + 0.35 - NUT_X;
  world.createCollider(
    RAPIER.ColliderDesc.cuboid(neckLength / 2, 0.06, NECK_WIDTH / 2).setTranslation(NUT_X + neckLength / 2, NECK_TOP - 0.06, 0),
  );
  // Each fret stands 1.2 cm above the neck: a thin box the picks can catch on
  for (let n = 1; n <= FRETS; n++) {
    world.createCollider(RAPIER.ColliderDesc.cuboid(0.012, 0.012, NECK_WIDTH / 2).setTranslation(fretX(n), NECK_TOP + 0.012, 0));
  }
  // A floor under the neck
  world.createCollider(RAPIER.ColliderDesc.cuboid(10, 0.1, 10).setTranslation(0, -1.1, 0));

  // The picks: dynamic bodies in a 6 × 4 grid above the neck, the first and last rows over its edges, each tilted
  // differently, from a fixed formula
  const picks: RAPIER_API.RigidBody[] = [];
  for (let i = 0; i < PICKS; i++) {
    const column = i % 6;
    const row = Math.floor(i / 6);
    const angle = (i * 37) % 90 / 90;
    const body = world.createRigidBody(
      RAPIER.RigidBodyDesc.dynamic()
        .setTranslation(NUT_X + 0.3 + column * 0.55, NECK_TOP + 0.6 + row * 0.25, -0.33 + row * 0.22)
        .setRotation(axisAngle(0.6, 0, 0.8, angle)),
    );
    world.createCollider(RAPIER.ColliderDesc.cuboid(PICK_SIZE.x / 2, PICK_SIZE.y / 2, PICK_SIZE.z / 2).setDensity(1400).setFriction(0.4), body);
    picks.push(body);
  }
  return { world, picks };
}

// A unit quaternion for a rotation of `turns` × π around a normalized axis
function axisAngle(x: number, y: number, z: number, turns: number) {
  const s = Math.sin((turns * Math.PI) / 2);
  return { x: x * s, y: y * s, z: z * s, w: Math.cos((turns * Math.PI) / 2) };
}

// Every pick's position and rotation, as the bytes of 32-bit floats: what a hash of the state covers
export function stateBytes(picks: RAPIER_API.RigidBody[]): Uint8Array {
  const values = new Float32Array(picks.length * 7);
  picks.forEach((body, i) => {
    const t = body.translation();
    const r = body.rotation();
    values.set([t.x, t.y, t.z, r.x, r.y, r.z, r.w], i * 7);
  });
  return new Uint8Array(values.buffer);
}

export const round = (n: number, digits = 3): number => Number(n.toFixed(digits)) + 0;
