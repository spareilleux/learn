// Lesson 9: lesson 5's fretboard as React components for React Three Fiber. Lowercase JSX elements (<mesh>,
// <boxGeometry>) are three.js objects that R3F creates, updates from props, adds to the parent, and disposes on unmount.
import { useEffect, useMemo, useState } from 'react';
import type { ThreeEvent } from '@react-three/fiber';
import * as THREE from 'three';
import { FRETS, NECK_TOP, NUT_X, STRINGS, fretAt, fretX, noteName, pressPoint, stringAt, stringZ } from '../05-picking/fretboard.ts';

const NECK_WIDTH = 0.55;
const NECK_LENGTH = fretX(FRETS) + 0.35 - NUT_X;

export type Marker = { string: number; fret: number };
export type Pick = { fret: number | null; string: number; note: string | null };

// Counters that the page reports and that lesson 12's tests read
export const counters = { fretboardRenders: 0, markerBuilds: 0 };

type FretboardProps = {
  // 'shared': one geometry and one material for all the frets; 'inline': a <cylinderGeometry> in every fret, as a
  // loop that writes JSX usually does
  frets?: 'shared' | 'inline';
  markers?: Marker[];
  onPick?: (pick: Pick) => void;
};

// A default of [] is a new array on every render: any hook that depends on markers runs again each time
export function Fretboard({ frets = 'shared', markers = [], onPick }: FretboardProps) {
  counters.fretboardRenders++;
  const [hover, setHover] = useState<THREE.Vector3 | null>(null);

  // Created once per component, not once per render; R3F doesn't dispose what it didn't create, so the effect does
  const fretGeometry = useMemo(() => new THREE.CylinderGeometry(0.012, 0.012, NECK_WIDTH, 12).rotateX(Math.PI / 2), []);
  const fretMaterial = useMemo(() => new THREE.MeshStandardMaterial({ color: 0xc9c5bd, metalness: 1, roughness: 0.3 }), []);
  useEffect(
    () => () => {
      fretGeometry.dispose();
      fretMaterial.dispose();
    },
    [fretGeometry, fretMaterial],
  );

  // The markers' positions, recomputed only when markers changes identity
  const markerPositions = useMemo(() => {
    counters.markerBuilds++;
    return markers.map(({ string, fret }) => pressPoint(string, fret).toArray());
  }, [markers]);

  function handlePointer(event: ThreeEvent<PointerEvent>) {
    // R3F raycasts for us: event.point is where the ray hit, in world coordinates
    event.stopPropagation();
    setHover(event.point.clone());
    const fret = fretAt(event.point.x);
    const string = stringAt(event.point.z);
    onPick?.({ fret, string, note: fret === null ? null : noteName(string, fret) });
  }

  return (
    <group name="fretboard" onPointerMove={handlePointer} onPointerOut={() => setHover(null)}>
      <mesh name="neck" position={[NUT_X + NECK_LENGTH / 2, NECK_TOP - 0.06, 0]}>
        <boxGeometry args={[NECK_LENGTH, 0.12, NECK_WIDTH]} />
        <meshStandardMaterial color={0x4a2c1d} roughness={0.75} />
      </mesh>
      {Array.from({ length: FRETS }, (_, i) =>
        frets === 'shared' ? (
          <mesh key={i} name={`fret ${i + 1}`} geometry={fretGeometry} material={fretMaterial} position={[fretX(i + 1), NECK_TOP, 0]} />
        ) : (
          <mesh key={i} name={`fret ${i + 1}`} position={[fretX(i + 1), NECK_TOP, 0]} rotation-x={Math.PI / 2}>
            <cylinderGeometry args={[0.012, 0.012, NECK_WIDTH, 12]} />
            <meshStandardMaterial color={0xc9c5bd} metalness={1} roughness={0.3} />
          </mesh>
        ),
      )}
      {Array.from({ length: STRINGS }, (_, i) => (
        <mesh key={i} name={`string ${i + 1}`} position={[NUT_X + NECK_LENGTH / 2, NECK_TOP + 0.02, stringZ(i + 1)]} rotation-z={Math.PI / 2}>
          <cylinderGeometry args={[0.004 + i * 0.0015, 0.004 + i * 0.0015, NECK_LENGTH, 8]} />
          <meshStandardMaterial color={0xd8d2c4} metalness={1} roughness={0.4} />
        </mesh>
      ))}
      {markerPositions.map((position, i) => (
        <mesh key={i} name="marker" position={position as [number, number, number]}>
          <sphereGeometry args={[0.035, 16, 8]} />
          <meshStandardMaterial color={0x5ab0ff} />
        </mesh>
      ))}
      {hover && (
        <mesh name="hover" position={hover} raycast={() => null}>
          <sphereGeometry args={[0.03, 16, 8]} />
          <meshStandardMaterial color={0xffb454} emissive={0x7a4a00} />
        </mesh>
      )}
    </group>
  );
}

