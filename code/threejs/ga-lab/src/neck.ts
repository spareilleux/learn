// GuitarAlchemist's neck built without React, from lesson 13's measurements (src/13-fretboard/guitar.ts): the same
// objects as Fretboard3D (board, 22 frets, 10 inlays, 6 strings, one texture of fret numbers, note markers), arranged
// three ways for experiment 1 (batched, merged) and experiment 14 (instanced, as Fretboard3D does in React).
import * as THREE from 'three/webgpu';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';
import { boardLength, BOARD_THICKNESS, DOUBLE_INLAYS, FRETS, fretDistance, fretX, INLAYS, markerX, NUT_WIDTH, SCALE, STRINGS, stringZ, type Position } from '../../src/13-fretboard/guitar.ts';

export const TUNING = ['E', 'B', 'G', 'D', 'A', 'E'];
export const NECK_SPACING = 8;
export const stringLength = (): number => fretDistance(FRETS) + (fretDistance(FRETS) - fretDistance(FRETS - 1)) * 3;
// Lesson 13's port: the gauge in inches is a diameter, so the radius is half of GA's
export const stringRadius = (s: number): number => ([0.01, 0.013, 0.017, 0.026, 0.036, 0.046][s] * 2.54) / 20;
export const inlayPlaces = (): [number, number][] => [
  ...INLAYS.filter((n) => n <= FRETS).map((n): [number, number] => [n, 0]),
  ...DOUBLE_INLAYS.filter((n) => n <= FRETS).flatMap((n): [number, number][] => [[n, -0.8], [n, 0.8]]),
];

// Where neck i of n sits: side by side along Z
export const neckOffset = (i: number): THREE.Vector3 => new THREE.Vector3(0, 0, i * NECK_SPACING);

// GA's camera for one neck; for more necks, the same direction from further away, aimed at their middle
export function necksCamera(necks: number, width: number, height: number): THREE.PerspectiveCamera {
  const center = new THREE.Vector3(0, 0, ((necks - 1) * NECK_SPACING) / 2);
  const camera = new THREE.PerspectiveCamera(35, width / height, 0.1, 2000);
  camera.position.copy(center).add(new THREE.Vector3(-12, 18, 40).multiplyScalar(1 + (necks - 1) * 0.15));
  camera.lookAt(center);
  camera.updateMatrixWorld();
  return camera;
}

export function addLights(scene: THREE.Scene): void {
  // GA's background and two lights (ThreeFretboard.tsx, as GaFretboard condenses it)
  scene.background = new THREE.Color(0x2a2a2a);
  scene.add(new THREE.AmbientLight(0xffffff, 0.6));
  const light = new THREE.DirectionalLight(0xffffff, 2);
  light.position.set(10, 30, 20);
  scene.add(light);
}

type PartKind = 'board' | 'fret' | 'inlay' | 'string' | 'marker';
export type Part = { kind: PartKind; matrix: THREE.Matrix4; color: THREE.Color };

// The geometries, one per kind of object, as Fretboard3D creates them
export function partGeometries(): Record<PartKind, THREE.BufferGeometry> {
  return {
    board: new THREE.BoxGeometry(boardLength(), BOARD_THICKNESS, NUT_WIDTH),
    fret: new THREE.CapsuleGeometry(0.15, NUT_WIDTH - 0.3, 4, 12).rotateX(Math.PI / 2),
    inlay: new THREE.CylinderGeometry(0.15, 0.15, 0.02, 24),
    // A unit-radius string along Y, scaled and laid along X by its matrix
    string: new THREE.CylinderGeometry(1, 1, stringLength(), 12, 32, true),
    marker: new THREE.SphereGeometry(0.2, 24, 12),
  };
}

// Every object of one neck: its kind, its matrix and its color
export function neckParts(positions: Position[], offset = new THREE.Vector3()): Part[] {
  const parts: Part[] = [];
  const at = (x: number, y: number, z: number) => new THREE.Matrix4().makeTranslation(x + offset.x, y + offset.y, z + offset.z);
  parts.push({ kind: 'board', matrix: at(boardLength() / 2 - SCALE / 2, 0, 0), color: new THREE.Color(0x3b2418) });
  for (let n = 1; n <= FRETS; n++) parts.push({ kind: 'fret', matrix: at(fretX(n), BOARD_THICKNESS / 2 + 0.12, 0), color: new THREE.Color(0xd8d0c0) });
  for (const [n, z] of inlayPlaces()) parts.push({ kind: 'inlay', matrix: at((fretX(n) + fretX(n - 1)) / 2, 0.21, z), color: new THREE.Color(0xf5f5dc) });
  const alongX = new THREE.Matrix4().makeRotationZ(Math.PI / 2);
  for (let s = 0; s < STRINGS; s++) {
    const r = stringRadius(s);
    parts.push({ kind: 'string', matrix: at(stringLength() / 2 - SCALE / 2, 0.55, stringZ(s)).multiply(alongX).scale(new THREE.Vector3(r, 1, r)), color: new THREE.Color(0xd0c8b8) });
  }
  for (const p of positions) parts.push({ kind: 'marker', matrix: at(markerX(p.fret), 1.0, stringZ(p.string)), color: new THREE.Color(p.color ?? '#ff6b6b') });
  return parts;
}

// Fretboard3D's fret numbers: 23 numbers in one canvas texture (a copy, since lesson 13 doesn't export it)
export function fretNumberTexture(): THREE.CanvasTexture {
  const length = boardLength();
  const canvas = document.createElement('canvas');
  canvas.width = 4096;
  canvas.height = 128;
  const context = canvas.getContext('2d')!;
  context.fillStyle = '#ffffff';
  context.font = 'bold 72px Arial';
  context.textAlign = 'center';
  context.textBaseline = 'middle';
  for (let n = 0; n <= FRETS; n++) context.fillText(String(n), ((fretX(n) + SCALE / 2) / length) * canvas.width, 64);
  const texture = new THREE.CanvasTexture(canvas);
  texture.colorSpace = THREE.SRGBColorSpace;
  return texture;
}

export type Labels = { geometry: THREE.PlaneGeometry; material: THREE.MeshBasicMaterial; add(parent: THREE.Object3D, offset: THREE.Vector3): void };
export function fretLabels(): Labels {
  const geometry = new THREE.PlaneGeometry(boardLength(), 1.2);
  const material = new THREE.MeshBasicMaterial({ map: fretNumberTexture(), transparent: true });
  return {
    geometry,
    material,
    add(parent, offset) {
      const mesh = new THREE.Mesh(geometry, material);
      mesh.rotation.x = -Math.PI / 2;
      mesh.position.set(boardLength() / 2 - SCALE / 2, 0.21, NUT_WIDTH / 2 + 0.8).add(offset);
      parent.add(mesh);
    },
  };
}

const MATERIAL = { roughness: 0.5, metalness: 0.3 };

// One BatchedMesh for every board, fret, inlay, string and marker of every neck: one material, a color per instance
export function buildBatchedNecks(parent: THREE.Object3D, necks: number, positions: Position[]): THREE.BatchedMesh {
  const geometries = partGeometries();
  const all = Array.from({ length: necks }, (_, i) => neckParts(positions, neckOffset(i))).flat();
  const kinds = Object.keys(geometries) as PartKind[];
  const vertices = kinds.reduce((sum, k) => sum + geometries[k].attributes.position.count, 0);
  const indices = kinds.reduce((sum, k) => sum + geometries[k].index!.count, 0);
  const batch = new THREE.BatchedMesh(all.length, vertices, indices, new THREE.MeshStandardMaterial(MATERIAL));
  const ids = Object.fromEntries(kinds.map((k) => [k, batch.addGeometry(geometries[k])])) as Record<PartKind, number>;
  for (const part of all) {
    const instance = batch.addInstance(ids[part.kind]);
    batch.setMatrixAt(instance, part.matrix);
    batch.setColorAt(instance, part.color);
  }
  parent.add(batch);
  const labels = fretLabels();
  for (let i = 0; i < necks; i++) labels.add(parent, neckOffset(i));
  return batch;
}

// Every static object of every neck merged into one geometry with vertex colors; the markers, which change with the
// chord, stay in an InstancedMesh
export function buildMergedNecks(parent: THREE.Object3D, necks: number, positions: Position[]): THREE.Mesh {
  const geometries = partGeometries();
  const pieces: THREE.BufferGeometry[] = [];
  const markers: Part[] = [];
  for (let i = 0; i < necks; i++) {
    for (const part of neckParts(positions, neckOffset(i))) {
      if (part.kind === 'marker') {
        markers.push(part);
        continue;
      }
      const piece = geometries[part.kind].clone().applyMatrix4(part.matrix);
      const colors = new Float32Array(piece.attributes.position.count * 3);
      for (let v = 0; v < colors.length; v += 3) colors.set([part.color.r, part.color.g, part.color.b], v);
      piece.setAttribute('color', new THREE.BufferAttribute(colors, 3));
      pieces.push(piece);
    }
  }
  const merged = new THREE.Mesh(mergeGeometries(pieces, false)!, new THREE.MeshStandardMaterial({ ...MATERIAL, vertexColors: true }));
  for (const piece of pieces) piece.dispose();
  merged.name = 'merged neck';
  parent.add(merged);
  if (markers.length) {
    const instanced = new THREE.InstancedMesh(geometries.marker, new THREE.MeshStandardMaterial(MATERIAL), markers.length);
    markers.forEach((m, i) => {
      instanced.setMatrixAt(i, m.matrix);
      instanced.setColorAt(i, m.color);
    });
    instanced.computeBoundingSphere();
    parent.add(instanced);
  }
  const labels = fretLabels();
  for (let i = 0; i < necks; i++) labels.add(parent, neckOffset(i));
  return merged;
}

// One InstancedMesh per kind of object, as Fretboard3D, without React (experiment 14's vanilla side)
export function buildInstancedNecks(parent: THREE.Object3D, necks: number, positions: Position[]): void {
  const geometries = partGeometries();
  const all = Array.from({ length: necks }, (_, i) => neckParts(positions, neckOffset(i))).flat();
  const materials: Record<PartKind, THREE.Material> = {
    board: new THREE.MeshStandardMaterial({ color: 0x3b2418, roughness: 0.8 }),
    fret: new THREE.MeshStandardMaterial({ color: 0xd8d0c0, metalness: 1, roughness: 0.28 }),
    inlay: new THREE.MeshStandardMaterial({ color: 0xf5f5dc, roughness: 0.2, metalness: 0.3, emissive: 0xffffff, emissiveIntensity: 0.15 }),
    string: new THREE.MeshStandardMaterial({ color: 0xd0c8b8, metalness: 1, roughness: 0.3 }),
    marker: new THREE.MeshStandardMaterial({ roughness: 0.3, metalness: 0.2 }),
  };
  for (const kind of Object.keys(geometries) as PartKind[]) {
    const parts = all.filter((p) => p.kind === kind);
    if (parts.length === 0) continue;
    const mesh = new THREE.InstancedMesh(geometries[kind], materials[kind], parts.length);
    parts.forEach((p, i) => {
      mesh.setMatrixAt(i, p.matrix);
      if (kind === 'marker') mesh.setColorAt(i, p.color);
    });
    mesh.computeBoundingSphere();
    mesh.name = kind;
    parent.add(mesh);
  }
  const labels = fretLabels();
  for (let i = 0; i < necks; i++) labels.add(parent, neckOffset(i));
}
