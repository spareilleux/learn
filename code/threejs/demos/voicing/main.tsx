// Live demo: GuitarAlchemist's fretboard as lesson 13 ported it (instanced frets, inlays and markers, strings that
// vibrate in TSL), showing chord voicings colored by role: root, third, fifth, seventh. Pick a chord and a voicing in
// the panel, strum it, or click the neck to play one note.
// ?probe: the markers' draw calls and builds for the first voicing, then after switching to two other voicings.
import { useState } from 'react';
import { flushSync } from 'react-dom';
import { createRoot } from 'react-dom/client';
import { Canvas, type RootState } from '@react-three/fiber';
import { OrbitControls } from '@react-three/drei';
import * as THREE from 'three/webgpu';
import GUI from 'three/addons/libs/lil-gui.module.min.js';
import { noteAt } from '../../src/13-fretboard/guitar.ts';
import { Fretboard3D, portStats } from '../../src/13-fretboard/Fretboard3D.tsx';
import { backendName, forceWebGL, probing, publish } from '../../src/probe.ts';
import { createPlucker, OPEN_STRINGS } from '../guitar/pluck.ts';
import { CHORDS, positionsOf, role, ROLE_COLORS } from './chords.ts';

const plucker = createPlucker();
const control: { select?: (chord: number, voicing: number) => void; state?: RootState } = {};

function App() {
  const [selection, setSelection] = useState({ chord: 0, voicing: 0 });
  control.select = (chord, voicing) => setSelection({ chord, voicing });
  const chord = CHORDS[selection.chord];
  const voicing = chord.voicings[selection.voicing];
  const positions = positionsOf(chord, voicing.frets);
  const notes = voicing.frets
    .map((fret, string) => (fret < 0 ? null : noteAt(string, fret)))
    .reverse()
    .map((note) => note ?? 'x');

  return (
    <>
      <Canvas
        dpr={[1, 2]}
        gl={async (props) => {
          const renderer = new THREE.WebGPURenderer({ ...(props as object), antialias: true, forceWebGL });
          await renderer.init();
          return renderer;
        }}
        camera={{ position: [-13, 30, 11], fov: 40 }}
        onCreated={(state) => void (control.state = state)}
      >
        <color attach="background" args={[0x2a2e36]} />
        <ambientLight intensity={0.7} />
        <directionalLight position={[10, 30, 20]} intensity={2.2} />
        <Fretboard3D positions={positions} onPositionClick={({ string, fret }) => !probing && plucker.play(OPEN_STRINGS[string] + fret)} />
        <OrbitControls enableDamping={!probing} makeDefault target={[-14, 0, 0]} />
      </Canvas>
      <div className="overlay">
        {`${chord.name}, ${voicing.name}: ${notes.join(' ')} (low E to high E)\n`}
        {Object.entries(ROLE_COLORS)
          .filter(([name]) => name !== 'other')
          .map(([name, hex]) => (
            <span key={name} style={{ color: hex, marginRight: 12 }}>
              ● {name}
            </span>
          ))}
      </div>
    </>
  );
}

createRoot(document.getElementById('root')!).render(<App />);

if (!probing) {
  const gui = new GUI({ title: 'Voicings' });
  const state = { chord: CHORDS[0].name, voicing: CHORDS[0].voicings[0].name, sound: true };
  const chordIndex = () => CHORDS.findIndex((c) => c.name === state.chord);
  let voicingController = gui.add(state, 'voicing', CHORDS[0].voicings.map((v) => v.name));
  const onVoicing = () => control.select?.(chordIndex(), CHORDS[chordIndex()].voicings.findIndex((v) => v.name === state.voicing));
  voicingController.onChange(onVoicing);
  gui.add(state, 'chord', CHORDS.map((c) => c.name)).onChange(() => {
    // Each chord has its own voicings: rebuild the voicing list
    voicingController.destroy();
    state.voicing = CHORDS[chordIndex()].voicings[0].name;
    voicingController = gui.add(state, 'voicing', CHORDS[chordIndex()].voicings.map((v) => v.name)).onChange(onVoicing);
    control.select?.(chordIndex(), 0);
  });
  gui.add(state, 'sound');
  gui.add(
    {
      strum: () => {
        const chord = CHORDS[chordIndex()];
        const frets = chord.voicings.find((v) => v.name === state.voicing)!.frets;
        if (!state.sound) return;
        frets
          .map((fret, string) => ({ fret, string }))
          .reverse()
          .filter(({ fret }) => fret >= 0)
          .forEach(({ fret, string }, i) => plucker.play(OPEN_STRINGS[string] + fret, i * 0.04));
      },
    },
    'strum',
  );
}

if (probing) {
  const nextFrame = () => new Promise((resolve) => requestAnimationFrame(resolve));
  const counts = () => {
    // R3F types gl as a WebGLRenderer; here it is the WebGPURenderer the gl factory returned
    const { render, memory } = (control.state!.gl as unknown as THREE.WebGPURenderer).info;
    return { drawCalls: render.drawCalls, triangles: render.triangles, geometries: memory.geometries, markerBuilds: portStats.markerBuilds };
  };
  while (!control.state) await nextFrame();
  for (let i = 0; i < 3; i++) await nextFrame();
  const first = counts();
  const results: Record<string, unknown> = {};
  for (const [chord, voicing] of [
    [0, 2],
    [13, 0],
  ]) {
    flushSync(() => control.select!(chord, voicing));
    for (let i = 0; i < 3; i++) await nextFrame();
    const c = CHORDS[chord];
    const frets = c.voicings[voicing].frets;
    results[`${c.name}, ${c.voicings[voicing].name}`] = {
      notes: frets.map((fret, string) => (fret < 0 ? 'x' : `${noteAt(string, fret)} ${role(c.root, OPEN_STRINGS[string] + fret)}`)).reverse(),
      ...counts(),
    };
  }
  publish({ backend: backendName(control.state.gl as unknown as THREE.WebGPURenderer), 'C, open': first, ...results });
}
