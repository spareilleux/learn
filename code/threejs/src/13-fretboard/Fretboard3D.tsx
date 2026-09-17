// Lesson 13: GuitarAlchemist's fretboard ported to React Three Fiber and WebGPURenderer, with what lessons 1 to 12 measured:
// one InstancedMesh per kind of repeated object, shared geometries and materials, one texture for all the fret numbers,
// markers rebuilt only when their content changes, strings that vibrate in TSL when a note is clicked, a pixel ratio
// capped at 2, and everything it creates disposed on unmount.
import { useEffect, useLayoutEffect, useMemo, useRef } from 'react';
import { useFrame, type ThreeEvent } from '@react-three/fiber';
import * as THREE from 'three/webgpu';
import { cos, exp, float, instancedBufferAttribute, instancedDynamicBufferAttribute, max, positionLocal, sin, uniform, uv, vec3 } from 'three/tsl';
import { boardLength, BOARD_THICKNESS, DOUBLE_INLAYS, FRETS, fretAtX, fretDistance, fretX, INLAYS, markerX, noteAt, NUT_WIDTH, SCALE, STRINGS, stringAtZ, stringZ, type Position } from './guitar.ts';

export type NoteClick = { string: number; fret: number; note: string };
export const portStats = { markerBuilds: 0, plucked: [] as number[] };

type Props = { positions?: Position[]; onPositionClick?: (click: NoteClick) => void };

const MAX_MARKERS = 24;
const NO_POSITIONS: Position[] = [];
const matrix = new THREE.Matrix4();
const color = new THREE.Color();

export function Fretboard3D({ positions = NO_POSITIONS, onPositionClick }: Props) {
  const length = boardLength();
  const stringLength = fretDistance(FRETS) + (fretDistance(FRETS) - fretDistance(FRETS - 1)) * 3;

  // Everything created here once, and disposed together
  const assets = useMemo(() => {
    const fretGeometry = new THREE.CapsuleGeometry(0.15, NUT_WIDTH - 0.3, 4, 12).rotateX(Math.PI / 2);
    const fretMaterial = new THREE.MeshStandardMaterial({ color: 0xd8d0c0, metalness: 1, roughness: 0.28 });
    const inlayGeometry = new THREE.CylinderGeometry(0.15, 0.15, 0.02, 24);
    const inlayMaterial = new THREE.MeshStandardMaterial({ color: 0xf5f5dc, roughness: 0.2, metalness: 0.3, emissive: 0xffffff, emissiveIntensity: 0.15 });
    const markerGeometry = new THREE.SphereGeometry(0.2, 24, 12);
    const markerMaterial = new THREE.MeshStandardMaterial({ roughness: 0.3, metalness: 0.2 });
    // The per-marker colors, allocated for every slot up front: the shader reads instance colors only if the attribute
    // exists when it is built, and the first render may have no markers, so setColorAt would create it too late
    const markerColors = new THREE.InstancedBufferAttribute(new Float32Array(MAX_MARKERS * 3).fill(1), 3);
    const labels = fretNumberTexture(length);
    const labelMaterial = new THREE.MeshBasicMaterial({ map: labels, transparent: true });
    const strings = vibratingStrings(stringLength);
    return { fretGeometry, fretMaterial, inlayGeometry, inlayMaterial, markerGeometry, markerMaterial, labels, labelMaterial, markerColors, ...strings };
  }, [length, stringLength]);
  useEffect(
    () => () => {
      for (const value of Object.values(assets)) if ('dispose' in value) value.dispose();
    },
    [assets],
  );
  // The shader's clock: seconds, from the same source as the pluck times
  useFrame(() => void (assets.now.value = performance.now() / 1000));

  const inlayPositions = useMemo(
    () => [...INLAYS.map((n) => [n, 0]), ...DOUBLE_INLAYS.filter((n) => n <= FRETS).flatMap((n) => [[n, -0.8], [n, 0.8]])],
    [],
  );

  const frets = useRef<THREE.InstancedMesh>(null);
  const inlays = useRef<THREE.InstancedMesh>(null);
  const strings = useRef<THREE.InstancedMesh>(null);
  useLayoutEffect(() => {
    // A unit-radius cylinder per string, scaled to the string's radius across its axis, then laid along X
    const alongX = new THREE.Matrix4().makeRotationZ(Math.PI / 2);
    for (let s = 0; s < STRINGS; s++) {
      const radius = assets.radii.getX(s);
      matrix.makeTranslation(stringLength / 2 - SCALE / 2, 0.55, stringZ(s)).multiply(alongX).scale(new THREE.Vector3(radius, 1, radius));
      strings.current!.setMatrixAt(s, matrix);
    }
    strings.current!.computeBoundingSphere();
    for (let n = 1; n <= FRETS; n++) frets.current!.setMatrixAt(n - 1, matrix.makeTranslation(fretX(n), BOARD_THICKNESS / 2 + 0.12, 0));
    inlayPositions.forEach(([n, z], i) => inlays.current!.setMatrixAt(i, matrix.makeTranslation((fretX(n) + fretX(n - 1)) / 2, 0.21, z)));
    frets.current!.computeBoundingSphere();
    inlays.current!.computeBoundingSphere();
  }, [inlayPositions, assets, stringLength]);

  // Markers depend on the positions' content, not on the array's identity: a new [] with the same notes changes nothing
  const positionsKey = positions.map((p) => `${p.string}:${p.fret}:${p.color ?? ''}`).join(',');
  const markers = useRef<THREE.InstancedMesh>(null);
  useLayoutEffect(() => {
    portStats.markerBuilds++;
    const mesh = markers.current!;
    mesh.instanceColor ??= assets.markerColors;
    const list = positionsKey === '' ? [] : positionsKey.split(',').map((item) => item.split(':'));
    list.slice(0, MAX_MARKERS).forEach(([string, fret, hex], i) => {
      mesh.setMatrixAt(i, matrix.makeTranslation(markerX(Number(fret)), 1.0, stringZ(Number(string))));
      mesh.setColorAt(i, color.set(hex || '#ff6b6b'));
    });
    mesh.count = Math.min(list.length, MAX_MARKERS);
    mesh.instanceMatrix.needsUpdate = true;
    if (mesh.instanceColor) mesh.instanceColor.needsUpdate = true;
    mesh.computeBoundingSphere();
  }, [positionsKey, assets]);

  function handleClick(event: ThreeEvent<PointerEvent>) {
    event.stopPropagation();
    const fret = fretAtX(event.point.x);
    if (fret === null) return;
    const string = stringAtZ(event.point.z);
    assets.pluckedAt.setX(string, performance.now() / 1000);
    assets.pluckedAt.needsUpdate = true;
    portStats.plucked.push(string);
    onPositionClick?.({ string, fret, note: noteAt(string, fret) });
  }

  return (
    <group name="fretboard3d">
      <mesh name="board" position={[length / 2 - SCALE / 2, 0, 0]} onPointerDown={handleClick}>
        <boxGeometry args={[length, BOARD_THICKNESS, NUT_WIDTH]} />
        <meshStandardMaterial color={0x3b2418} roughness={0.8} />
      </mesh>
      <instancedMesh ref={frets} name="frets" args={[assets.fretGeometry, assets.fretMaterial, FRETS]} />
      <instancedMesh ref={inlays} name="inlays" args={[assets.inlayGeometry, assets.inlayMaterial, inlayPositions.length]} />
      <instancedMesh ref={markers} name="markers" args={[assets.markerGeometry, assets.markerMaterial, MAX_MARKERS]} />
      <instancedMesh ref={strings} name="strings" args={[assets.stringGeometry, assets.stringMaterial, STRINGS]} raycast={() => null} />
      <mesh name="fret numbers" material={assets.labelMaterial} position={[length / 2 - SCALE / 2, 0.21, NUT_WIDTH / 2 + 0.8]} rotation-x={-Math.PI / 2} raycast={() => null}>
        <planeGeometry args={[length, 1.2]} />
      </mesh>
    </group>
  );
}

// The six strings, one InstancedMesh: their vertices move in the vertex shader, a standing wave along each string started
// by a click. What differs per string, its radius, its frequency and when it was plucked, is a per-instance attribute.
function vibratingStrings(stringLength: number) {
  // The gauge in inches is a diameter: GA uses it as a radius (line 1079), which draws strings twice as thick
  const radii = new THREE.InstancedBufferAttribute(new Float32Array([0.01, 0.013, 0.017, 0.026, 0.036, 0.046].map((g) => (g * 2.54) / 20)), 1);
  const frequencies = new THREE.InstancedBufferAttribute(new Float32Array(Array.from({ length: STRINGS }, (_, s) => 60 - s * 6)), 1);
  const pluckedAt = new THREE.InstancedBufferAttribute(new Float32Array(STRINGS).fill(-100), 1);
  const now = uniform(0);
  const stringGeometry = new THREE.CylinderGeometry(1, 1, stringLength, 12, 32, true);
  const stringMaterial = new THREE.MeshStandardNodeMaterial({ color: 0xd0c8b8, metalness: 1, roughness: 0.3 });
  const age = max(now.sub(instancedDynamicBufferAttribute(pluckedAt, 'float')), float(0));
  // uv().y runs along the string; the offset is divided by the radius, since the instance matrix scales local X by it
  const amplitude = float(0.12).div(instancedBufferAttribute(radii, 'float'));
  const offset = amplitude.mul(sin(uv().y.mul(Math.PI))).mul(cos(age.mul(instancedBufferAttribute(frequencies, 'float')))).mul(exp(age.mul(-3)));
  stringMaterial.positionNode = positionLocal.add(vec3(offset, 0, 0));
  return { stringGeometry, stringMaterial, radii, pluckedAt, now };
}

// The 23 fret numbers in one canvas: one texture, one material and one draw call, instead of 23 of each
function fretNumberTexture(length: number): THREE.CanvasTexture {
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
