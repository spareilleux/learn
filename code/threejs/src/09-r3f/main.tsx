// Lesson 9: the fretboard of Fretboard.tsx in a React Three Fiber <Canvas> drawn by WebGPURenderer, with drei's
// OrbitControls and Html. ?frets=shared|inline, ?markers=stable|literal (a module constant or a new [] literal on each
// render of the parent), ?text adds drei's <Text>. When probed, the page re-renders its parent 10 times, moves the
// pointer over string 3, fret 5 through real pointer events, then unmounts the fretboard and counts what's left.
import { StrictMode, useState, type ReactNode } from 'react';
import { flushSync } from 'react-dom';
import { createRoot } from 'react-dom/client';
import { Canvas, useFrame, useThree, type RootState } from '@react-three/fiber';
import { Html, OrbitControls, Text } from '@react-three/drei';
import * as THREE from 'three/webgpu';
import { backendName, forceWebGL, gpuName, probing, publish } from '../probe.ts';
import { pressPoint } from '../05-picking/fretboard.ts';
import { counters, Fretboard, type Marker, type Pick } from './Fretboard.tsx';

const params = new URLSearchParams(location.search);
const frets = params.get('frets') === 'inline' ? 'inline' : 'shared';
const literalMarkers = params.get('markers') === 'literal';

// A C major chord, as a constant: the same array on every render
const C_MAJOR: Marker[] = [
  { string: 5, fret: 3 },
  { string: 4, fret: 2 },
  { string: 2, fret: 1 },
];

// What the probe drives from outside React
const control: { rerender?: () => void; hideFretboard?: () => void; state?: RootState; frames: number } = { frames: 0 };

function App() {
  const [renders, setRenders] = useState(0);
  const [visible, setVisible] = useState(true);
  const [pick, setPick] = useState<Pick | null>(null);
  control.rerender = () => setRenders((n) => n + 1);
  control.hideFretboard = () => setVisible(false);
  // literal: a new array with the same content on every render, as <Fretboard markers={[...]} /> would pass
  const markers = literalMarkers ? C_MAJOR.map((marker) => ({ ...marker })) : C_MAJOR;

  return (
    <>
      <Canvas
        // R3F 9 accepts a function that returns a renderer, or a promise of one: WebGPURenderer must be initialized
        gl={async (props) => {
          const renderer = new THREE.WebGPURenderer({ ...(props as object), antialias: true, forceWebGL });
          await renderer.init();
          return renderer;
        }}
        camera={{ position: [-0.2, 2.4, 1.6], fov: 40 }}
        onCreated={(state) => {
          state.camera.lookAt(-0.2, 0.3, 0);
          control.state = state;
        }}
      >
        <color attach="background" args={[0x1e2127]} />
        <hemisphereLight args={[0xdde6ff, 0x302820, 1.5]} />
        <directionalLight position={[1, 4, 3]} intensity={2.5} />
        {visible && <Fretboard frets={frets} markers={markers} onPick={setPick} />}
        {pick?.note && (
          <Html position={pressPoint(pick.string, pick.fret ?? 1).setY(0.6)} center>
            <div className="label">{pick.note}</div>
          </Html>
        )}
        {params.has('text') && (
          <Text position={[-0.2, 0.9, -0.4]} fontSize={0.15} color="#e6e1d6">
            C major
          </Text>
        )}
        <OrbitControls target={[-0.2, 0.3, 0]} makeDefault />
        <FrameCounter />
      </Canvas>
      <p className="status">
        parent renders: {renders}, pick: {pick?.note ?? '—'}
      </p>
    </>
  );
}

function FrameCounter(): ReactNode {
  const state = useThree();
  control.state = state;
  useFrame(() => {
    control.frames++;
  });
  return null;
}

const nextFrames = (n: number) =>
  new Promise<void>((resolve) => {
    const target = control.frames + n;
    const wait = () => (control.frames >= target ? resolve() : requestAnimationFrame(wait));
    wait();
  });

// counters: false after a pointer action, whose render count depends on how many pointermove events the browser
// delivered, which it coalesces when frames are slow
function snapshot(counters_ = true) {
  const state = control.state!;
  const renderer = state.gl as unknown as THREE.WebGPURenderer;
  const { render, memory } = renderer.info;
  let meshes = 0;
  state.scene.traverse((object) => void ((object as THREE.Mesh).isMesh && meshes++));
  return {
    drawCalls: render.drawCalls,
    triangles: render.triangles,
    geometries: memory.geometries,
    programs: memory.programs,
    meshes,
    ...(counters_ && { fretboardRenders: counters.fretboardRenders, markerBuilds: counters.markerBuilds }),
  };
}

const root = document.createElement('div');
root.id = 'root';
document.body.append(root);
// StrictMode renders each component twice in development: counters.fretboardRenders counts both
createRoot(root).render(probing ? <App /> : <StrictMode><App /></StrictMode>);

if (probing) {
  while (!control.state || control.frames < 3) await new Promise(requestAnimationFrame);
  const renderer = control.state.gl as unknown as THREE.WebGPURenderer;
  document.title = `Lesson 9 — ${backendName(renderer)}`;
  const first = snapshot();
  // flushSync renders and commits each update before it returns: without it, React batches the updates that arrive within
  // one frame, and a slow renderer (SwiftShader on the CI runners) counted 6 renders instead of 11
  for (let i = 0; i < 10; i++) {
    flushSync(() => control.rerender!());
    await nextFrames(1);
  }
  const afterRerenders = snapshot();
  const camera = control.state.camera;
  const rect = renderer.domElement.getBoundingClientRect();
  const ndc = pressPoint(3, 5).project(camera);
  publish({
    backend: backendName(renderer),
    gpu: gpuName(renderer),
    frets,
    markers: literalMarkers ? 'literal' : 'stable',
    first,
    afterTenParentRenders: afterRerenders,
    shotAfter: 'string 3, fret 5',
    actions: [
      { name: 'string 3, fret 5', move: [Math.round(rect.left + ((ndc.x + 1) / 2) * rect.width), Math.round(rect.top + ((1 - ndc.y) / 2) * rect.height)] },
      // No pointer move: the pointer stays where it was, and the pick with it
      { name: 'unmount the fretboard' },
    ],
  });
  window.probeAfter = async (name: string) => {
    if (name === 'unmount the fretboard') {
      flushSync(() => control.hideFretboard!());
      // R3F disposes removed objects at idle priority
      await new Promise((resolve) => setTimeout(resolve, 250));
    }
    await nextFrames(3);
    return { status: document.querySelector('.status')?.textContent, label: document.querySelector('.label')?.textContent ?? null, ...snapshot(false) };
  };
}

declare global {
  interface Window {
    probeAfter?: (name: string) => Promise<unknown>;
  }
}
