// A whole electric guitar built in code, for the live demos: body, neck, fretboard, frets, inlays, headstock, tuners,
// pickups, bridge, knobs and six strings that vibrate. It uses lesson 13's measurements (1 unit = 10 mm, 648 mm scale,
// 22 frets) and helpers, so a point on the neck turns into a fret and a note the same way as in the lesson.
import * as THREE from 'three/webgpu';
import { clamp, float, Fn, PI, positionLocal, sin, uniform, vec3 } from 'three/tsl';
import { DOUBLE_INLAYS, FRETS, INLAYS, NUT_WIDTH, SCALE, STRINGS, fretX } from '../../src/13-fretboard/guitar.ts';

// Heights, in units of 10 mm: the fretboard's top is y = 0, the body's top below it, the strings above it
export const BODY_TOP = -1.3;
const BODY_THICKNESS = 4.5;
export const SADDLE_X = SCALE / 2;
export const NUT_X = -SCALE / 2;
export const BOARD_END_X = fretX(FRETS) + 1;
const STRING_HEIGHT_AT_NUT = 0.25;
const STRING_HEIGHT_AT_SADDLE = 0.75;
const HEADSTOCK_TOP = -0.6;

// The neck widens from 42 mm at the nut to 56 mm at the end of the fretboard
export const neckWidthAt = (x: number): number => NUT_WIDTH + ((Math.min(x, BOARD_END_X) - NUT_X) / (BOARD_END_X - NUT_X)) * (5.6 - NUT_WIDTH);
// A string's height at x, rising from the nut to the saddle
export const stringY = (x: number): number =>
  STRING_HEIGHT_AT_NUT + ((x - NUT_X) / (SADDLE_X - NUT_X)) * (STRING_HEIGHT_AT_SADDLE - STRING_HEIGHT_AT_NUT);
// String s (0 = high E, on the −z side, as in lesson 13) at x: the strings fan out with the neck
export const stringZAt = (s: number, x: number): number => (s / (STRINGS - 1) - 0.5) * (neckWidthAt(x) - 0.65);

// The string nearest to z at x
export function stringAt(x: number, z: number): number {
  let best = 0;
  for (let s = 1; s < STRINGS; s++) if (Math.abs(stringZAt(s, x) - z) < Math.abs(stringZAt(best, x) - z)) best = s;
  return best;
}

function splineShape(points: number[][]): THREE.Shape {
  const vectors = points.map(([x, y]) => new THREE.Vector2(x, y));
  const shape = new THREE.Shape();
  shape.moveTo(vectors[0].x, vectors[0].y);
  shape.splineThru(vectors.slice(1));
  shape.lineTo(vectors[0].x, vectors[0].y);
  return shape;
}

// The body seen from above: x along the guitar (the neck pocket at x = 9), y across it, bass side positive.
// The shape's y becomes the scene's z once the extrusion is turned to point down.
const BODY = [
  [9, 3.6], [5, 5.8], [1.2, 9.2], [1.8, 11.8], [5.5, 13.4], [11, 13.9], [16.5, 13], [21.5, 11.9], [26.5, 12.9],
  [32, 15.7], [38, 16.3], [43.2, 13.6], [46.2, 7.2], [46.8, 0], [46.2, -7.2], [43.2, -13.6], [38, -16.3], [32, -15.7],
  [26.5, -12.9], [21.5, -11.9], [16.5, -13], [11.5, -13.4], [7.2, -11.8], [4.4, -9.4], [5.4, -6.8], [8.2, -5], [9, -3.6],
];
const PICKGUARD = [
  [9.5, 3.4], [6.5, 6], [4.6, 9], [7, 11.2], [13, 11.4], [20, 9.8], [27, 10.4], [33, 12.6], [36.8, 9.5], [37.5, 4],
  [35.5, -1.5], [38.5, -6.5], [41, -10.8], [37.5, -13.2], [31, -12], [24.5, -10.2], [17, -10.4], [11.5, -10.6],
  [8.6, -8.2], [9.6, -5.4], [9.5, -3.4],
];
// From the nut (x = 0) outwards; the wide side, where the tuners sit, is the bass side
const HEADSTOCK = [
  [0, 2.4], [-3, 2.9], [-7, 4.4], [-11, 4.9], [-15.5, 4.4], [-19, 3.4], [-20.5, 1.6], [-19.5, -0.4], [-16, -1.4],
  [-11, -1.9], [-6, -2.3], [-2.5, -2.3], [0, -2.2],
];

// A sunburst finish drawn once in a canvas: amber in the middle, dark brown at the edges
function sunburstTexture(): THREE.CanvasTexture {
  const canvas = document.createElement('canvas');
  canvas.width = canvas.height = 512;
  const ctx = canvas.getContext('2d')!;
  const gradient = ctx.createRadialGradient(256, 256, 30, 256, 256, 256);
  gradient.addColorStop(0, '#f2b33d');
  gradient.addColorStop(0.45, '#d9751c');
  gradient.addColorStop(0.75, '#6e2410');
  gradient.addColorStop(1, '#1c0a06');
  ctx.fillStyle = gradient;
  ctx.fillRect(0, 0, 512, 512);
  const texture = new THREE.CanvasTexture(canvas);
  texture.colorSpace = THREE.SRGBColorSpace;
  return texture;
}

export type Guitar = {
  group: THREE.Group;
  // What a ray tests to know whether it points at the playable part of the neck (invisible)
  pickTarget: THREE.Mesh;
  // Sets string s (0 = high E) vibrating between fret f and the saddle
  pluck: (string: number, fret: number) => void;
  // Once per frame, with the time in seconds
  update: (seconds: number) => void;
  dispose: () => void;
};

// nodeStrings: false gives the strings plain materials, moved from JavaScript, for the classic WebGLRenderer, which
// can't run node materials (the XR demo uses it, as lesson 11 found WebGPURenderer can't draw with an emulated headset)
export function buildGuitar({ nodeStrings = true }: { nodeStrings?: boolean } = {}): Guitar {
  const group = new THREE.Group();
  group.name = 'guitar';
  const disposables: { dispose: () => void }[] = [];
  const track = <T extends { dispose: () => void }>(item: T): T => (disposables.push(item), item);
  const matrix = new THREE.Matrix4();

  const chrome = track(new THREE.MeshStandardMaterial({ color: 0xd9dde2, metalness: 1, roughness: 0.22 }));
  const cream = track(new THREE.MeshStandardMaterial({ color: 0xeee8d6, roughness: 0.5 }));
  const maple = track(new THREE.MeshStandardMaterial({ color: 0xd9b77e, roughness: 0.55 }));

  // Body: the outline extruded with a rounded edge; the caps get the sunburst, the sides a dark lacquer
  const bodyGeometry = track(
    new THREE.ExtrudeGeometry(splineShape(BODY), { depth: BODY_THICKNESS - 0.8, bevelEnabled: true, bevelThickness: 0.4, bevelSize: 0.5, bevelSegments: 4, curveSegments: 48 }),
  );
  // The caps' UVs are the shape's coordinates: map the body's extent, about 47 × 34, to the texture
  const uv = bodyGeometry.attributes.uv;
  for (let i = 0; i < uv.count; i++) uv.setXY(i, uv.getX(i) / 48, (uv.getY(i) + 17) / 34);
  // Turned so that the extrusion points down: the shape's y becomes z, the top cap ends at BODY_TOP
  bodyGeometry.rotateX(Math.PI / 2).translate(0, BODY_TOP - 0.4, 0);
  const body = new THREE.Mesh(bodyGeometry, [
    track(new THREE.MeshPhysicalMaterial({ map: track(sunburstTexture()), roughness: 0.35, clearcoat: 1, clearcoatRoughness: 0.08 })),
    track(new THREE.MeshPhysicalMaterial({ color: 0x1c0a06, roughness: 0.4, clearcoat: 1, clearcoatRoughness: 0.1 })),
  ]);
  body.name = 'body';
  group.add(body);

  const pickguard = new THREE.Mesh(
    track(new THREE.ExtrudeGeometry(splineShape(PICKGUARD), { depth: 0.15, bevelEnabled: false, curveSegments: 32 }).rotateX(Math.PI / 2).translate(0, BODY_TOP + 0.15, 0)),
    track(new THREE.MeshStandardMaterial({ color: 0x141414, roughness: 0.35 })),
  );
  pickguard.name = 'pickguard';
  group.add(pickguard);

  // Three single-coil pickups on the pickguard, the bridge one slanted, with six pole pieces each
  const PICKUP_Y = BODY_TOP + 0.55;
  const cover = track(new THREE.CapsuleGeometry(0.9, 6, 4, 16).rotateX(Math.PI / 2).scale(1, 0.45, 1));
  const poles = new THREE.InstancedMesh(track(new THREE.CylinderGeometry(0.22, 0.22, 0.3, 12)), chrome, 18);
  poles.name = 'pole pieces';
  const up = new THREE.Vector3(0, 1, 0);
  [
    [16.5, 0],
    [23, 0],
    [29.5, -0.18],
  ].forEach(([x, angle], p) => {
    const pickup = new THREE.Mesh(cover, cream);
    pickup.name = `pickup ${p + 1}`;
    pickup.position.set(x, PICKUP_Y, 0);
    pickup.rotation.y = angle;
    group.add(pickup);
    for (let s = 0; s < STRINGS; s++) {
      const offset = new THREE.Vector3(0, 0, stringZAt(s, x)).applyAxisAngle(up, angle);
      poles.setMatrixAt(p * STRINGS + s, matrix.makeTranslation(x + offset.x, PICKUP_Y + 0.35, offset.z));
    }
  });
  group.add(poles);

  // Bridge plate, and six saddles that reach the strings
  const bridge = new THREE.Mesh(track(new THREE.BoxGeometry(4, 0.35, 7)), chrome);
  bridge.name = 'bridge';
  bridge.position.set(SADDLE_X + 1.4, BODY_TOP + 0.175, 0);
  group.add(bridge);
  const saddleBottom = BODY_TOP + 0.35;
  const saddleTop = stringY(SADDLE_X) - 0.05;
  const saddles = new THREE.InstancedMesh(track(new THREE.BoxGeometry(1.2, saddleTop - saddleBottom, 0.9)), chrome, STRINGS);
  saddles.name = 'saddles';
  for (let s = 0; s < STRINGS; s++) saddles.setMatrixAt(s, matrix.makeTranslation(SADDLE_X + 0.4, (saddleTop + saddleBottom) / 2, stringZAt(s, SADDLE_X)));
  group.add(saddles);

  // Volume and tone knobs, and the pickup selector
  const knobs = new THREE.InstancedMesh(track(new THREE.CylinderGeometry(0.85, 0.95, 1.1, 24)), cream, 3);
  knobs.name = 'knobs';
  [
    [33.5, -7.6],
    [36.3, -9.6],
    [39.1, -11.1],
  ].forEach(([x, z], i) => knobs.setMatrixAt(i, matrix.makeTranslation(x, BODY_TOP + 0.15 + 0.55, z)));
  group.add(knobs);
  const selector = new THREE.Mesh(track(new THREE.CapsuleGeometry(0.3, 0.8, 4, 8)), cream);
  selector.position.set(31, BODY_TOP + 0.5, -4.6);
  selector.rotation.set(0, 0.5, 0.35);
  group.add(selector);

  // Neck: maple, from the nut into the neck pocket, flat on top and round underneath (a half-cylinder, reshaped)
  const neckEnd = BOARD_END_X;
  const neckLength = neckEnd - NUT_X;
  const neckGeometry = track(new THREE.CylinderGeometry(1, 1, neckLength, 32, 16, false, 0, Math.PI).rotateZ(Math.PI / 2));
  // After the rotation the axis is x, the round side is +y and the flat side is the plane y = 0: turn it upside
  // down, give it a depth of 1.8, the neck's width, and move it below the fretboard
  const neckPosition = neckGeometry.attributes.position;
  for (let i = 0; i < neckPosition.count; i++) {
    const x = neckPosition.getX(i) + NUT_X + neckLength / 2;
    neckPosition.setXYZ(i, x, -0.4 - neckPosition.getY(i) * 1.8, (neckPosition.getZ(i) * neckWidthAt(x)) / 2);
  }
  // Flipping y reverses the triangles' winding: swap two indices of each triangle
  const neckIndex = neckGeometry.index!;
  for (let i = 0; i < neckIndex.count; i += 3) {
    const a = neckIndex.getX(i);
    neckIndex.setX(i, neckIndex.getX(i + 1));
    neckIndex.setX(i + 1, a);
  }
  neckGeometry.computeVertexNormals();
  const neck = new THREE.Mesh(neckGeometry, maple);
  neck.name = 'neck';
  group.add(neck);

  // Fretboard: rosewood, a slab 4 mm thick whose width follows the neck
  const boardGeometry = track(new THREE.BoxGeometry(BOARD_END_X - NUT_X, 0.4, 1, 8, 1, 1));
  const boardPosition = boardGeometry.attributes.position;
  for (let i = 0; i < boardPosition.count; i++) {
    const x = boardPosition.getX(i) + (NUT_X + BOARD_END_X) / 2;
    boardPosition.setXYZ(i, x, boardPosition.getY(i) - 0.2, boardPosition.getZ(i) * neckWidthAt(x));
  }
  boardGeometry.computeVertexNormals();
  const fretboard = new THREE.Mesh(boardGeometry, track(new THREE.MeshStandardMaterial({ color: 0x3a2217, roughness: 0.8 })));
  fretboard.name = 'fretboard';
  group.add(fretboard);

  // 22 frets in one InstancedMesh: a wire of length 1 scaled to the neck's width at each fret
  const frets = new THREE.InstancedMesh(track(new THREE.CapsuleGeometry(0.1, 1, 4, 8).rotateX(Math.PI / 2)), chrome, FRETS);
  frets.name = 'frets';
  const scale = new THREE.Matrix4();
  for (let n = 1; n <= FRETS; n++) {
    const x = fretX(n);
    frets.setMatrixAt(n - 1, matrix.makeTranslation(x, 0.05, 0).multiply(scale.makeScale(1, 1, neckWidthAt(x) - 0.3)));
  }
  group.add(frets);

  // Mother-of-pearl dots between frets, two at fret 12
  const dots = [...INLAYS.map((f) => [f, 0]), ...DOUBLE_INLAYS.filter((f) => f <= FRETS).flatMap((f) => [[f, -1.1], [f, 1.1]])];
  const inlays = new THREE.InstancedMesh(track(new THREE.CylinderGeometry(0.35, 0.35, 0.05, 24)), track(new THREE.MeshStandardMaterial({ color: 0xf3efe4, roughness: 0.25 })), dots.length);
  inlays.name = 'inlays';
  dots.forEach(([f, z], i) => inlays.setMatrixAt(i, matrix.makeTranslation((fretX(f) + fretX(f - 1)) / 2, 0.01, z)));
  group.add(inlays);

  const nut = new THREE.Mesh(track(new THREE.BoxGeometry(0.5, 0.55, NUT_WIDTH)), track(new THREE.MeshStandardMaterial({ color: 0xf4efdd, roughness: 0.4 })));
  nut.name = 'nut';
  nut.position.set(NUT_X - 0.25, 0.08, 0);
  group.add(nut);

  // Headstock, a little below the fretboard, 13 mm thick, with six tuners along its bass side
  const headstock = new THREE.Mesh(
    track(
      new THREE.ExtrudeGeometry(splineShape(HEADSTOCK), { depth: 1.3, bevelEnabled: true, bevelThickness: 0.15, bevelSize: 0.2, bevelSegments: 2, curveSegments: 24 })
        .rotateX(Math.PI / 2)
        .translate(NUT_X - 0.5, HEADSTOCK_TOP - 0.15, 0),
    ),
    maple,
  );
  headstock.name = 'headstock';
  group.add(headstock);
  // Low E's tuner is nearest the nut, high E's farthest; the posts follow the headstock's edge
  const tunerX = (s: number) => NUT_X - 3.8 - s * 2.75;
  const tunerZ = (s: number) => 2 + Math.sin((s / 5) * Math.PI) * 1.2;
  const posts = new THREE.InstancedMesh(track(new THREE.CylinderGeometry(0.25, 0.3, 1.2, 12)), chrome, STRINGS);
  posts.name = 'tuner posts';
  const keys = new THREE.InstancedMesh(track(new THREE.BoxGeometry(0.9, 0.35, 1.6)), chrome, STRINGS);
  keys.name = 'tuner keys';
  for (let s = 0; s < STRINGS; s++) {
    // String s's tuner: s = 0 (high E) is the one farthest from the nut
    const t = 5 - s;
    posts.setMatrixAt(s, matrix.makeTranslation(tunerX(t), HEADSTOCK_TOP + 0.5, tunerZ(t)));
    keys.setMatrixAt(s, matrix.makeTranslation(tunerX(t), HEADSTOCK_TOP - 0.7, tunerZ(t) + 2.3));
  }
  group.add(posts, keys);

  // Strings: a thin cylinder from the saddle to the nut, then a straight segment to the tuner post. The part between
  // the pressed fret and the saddle moves in the vertex shader: a standing wave whose amplitude decays in 2.5 s.
  // Without node materials, the whole string moves up and down instead
  const gauges = [0.01, 0.013, 0.017, 0.026, 0.036, 0.046];
  const time = uniform(0);
  const strings: { amplitude: { value: number }; plucked: { value: number }; from: { value: number }; mesh: THREE.Mesh; rest: THREE.Vector3 }[] = [];
  const xAxis = new THREE.Vector3(1, 0, 0);
  const yAxis = new THREE.Vector3(0, 1, 0);
  for (let s = 0; s < STRINGS; s++) {
    // The radius from the gauge in inches, doubled so the thinnest strings stay visible
    const radius = gauges[s] * 2.54 * 0.5 * 2;
    const nutEnd = new THREE.Vector3(NUT_X, stringY(NUT_X), stringZAt(s, NUT_X));
    const saddleEnd = new THREE.Vector3(SADDLE_X, stringY(SADDLE_X), stringZAt(s, SADDLE_X));
    const middle = nutEnd.clone().add(saddleEnd).multiplyScalar(0.5);
    const amplitude = uniform(0);
    const plucked = uniform(-10);
    const from = uniform(NUT_X);
    // Slowed down a lot, so the motion reads as a vibration: faster for thinner strings
    const frequency = float(9 + (5 - s) * 2);
    const look = { color: s < 2 ? 0xd4d8dd : 0xc8b99a, metalness: 1, roughness: 0.3 };
    const plain = track(new THREE.MeshStandardMaterial(look));
    const material = nodeStrings ? track(new THREE.MeshStandardNodeMaterial(look)) : plain;
    if (material instanceof THREE.MeshStandardNodeMaterial) material.positionNode = Fn(() => {
      const p = positionLocal;
      // The geometry lies along x, centered on the string's middle
      const x = p.x.add(middle.x);
      const u = clamp(x.sub(from).div(float(SADDLE_X).sub(from)), 0, 1);
      const elapsed = time.sub(plucked);
      const envelope = amplitude.mul(float(1).sub(clamp(elapsed.div(2.5), 0, 1)));
      const offset = sin(u.mul(PI)).mul(sin(elapsed.mul(frequency).mul(PI.mul(2)))).mul(envelope);
      return p.add(vec3(0, offset, offset.mul(0.5)));
    })();
    const geometry = track(new THREE.CylinderGeometry(radius, radius, saddleEnd.distanceTo(nutEnd), 6, 96).rotateZ(Math.PI / 2));
    const string = new THREE.Mesh(geometry, material);
    string.name = `string ${s}`;
    string.position.copy(middle);
    string.quaternion.setFromUnitVectors(xAxis, saddleEnd.clone().sub(nutEnd).normalize());
    group.add(string);
    strings.push({ amplitude, plucked, from, mesh: string, rest: middle });

    const t = 5 - s;
    const post = new THREE.Vector3(tunerX(t), HEADSTOCK_TOP + 0.9, tunerZ(t));
    // Its own material: behind the nut, the string doesn't vibrate
    const behind = new THREE.Mesh(track(new THREE.CylinderGeometry(radius, radius, nutEnd.distanceTo(post), 6)), plain);
    behind.position.copy(nutEnd).add(post).multiplyScalar(0.5);
    behind.quaternion.setFromUnitVectors(yAxis, post.clone().sub(nutEnd).normalize());
    group.add(behind);
  }

  const pickTarget = new THREE.Mesh(track(new THREE.BoxGeometry(BOARD_END_X - NUT_X + 1.5, 1.2, 5.6)), track(new THREE.MeshBasicMaterial()));
  pickTarget.name = 'neck pick target';
  pickTarget.position.set((NUT_X - 1.5 + BOARD_END_X) / 2, 0.4, 0);
  pickTarget.visible = false;
  group.add(pickTarget);

  let now = 0;
  return {
    group,
    pickTarget,
    pluck(string, fret) {
      const { amplitude, plucked, from } = strings[string];
      from.value = fret === 0 ? NUT_X : fretX(fret);
      plucked.value = now;
      amplitude.value = 0.15;
    },
    update(seconds) {
      now = seconds;
      time.value = seconds;
      if (nodeStrings) return;
      strings.forEach(({ amplitude, plucked, mesh, rest }, s) => {
        const elapsed = seconds - plucked.value;
        const envelope = amplitude.value * Math.max(0, 1 - elapsed / 2.5);
        mesh.position.set(rest.x, rest.y + Math.sin(elapsed * (9 + (5 - s) * 2) * Math.PI * 2) * envelope * 0.5, rest.z);
      });
    },
    dispose() {
      for (const item of disposables) item.dispose();
      for (const mesh of [poles, saddles, knobs, frets, inlays, posts, keys]) mesh.dispose();
    },
  };
}
