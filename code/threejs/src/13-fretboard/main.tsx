// Lesson 13: GA's fretboard as GA builds it (?version=ga, GaFretboard.tsx) and ported (?version=port, Fretboard3D.tsx), in
// the same parent component. When probed, the page counts what the renderer holds after the first frames, after 10 renders
// of the parent that pass a new positions array with the same content, after the C major chord is shown, after a click
// on string 3 (D), fret 2 (E3) through a real pointer event, and after the fretboard is unmounted.
import { useState } from 'react';
import { flushSync } from 'react-dom';
import { createRoot } from 'react-dom/client';
import { Canvas, useFrame, type RootState } from '@react-three/fiber';
import { OrbitControls } from '@react-three/drei';
import * as THREE from 'three/webgpu';
import { backendName, forceWebGL, gpuName, probing, publish } from '../probe.ts';
import { GaFretboard, type GaStats } from './GaFretboard.tsx';
import { Fretboard3D, portStats, type NoteClick } from './Fretboard3D.tsx';
import { C_MAJOR, markerX, stringZ, type Position } from './guitar.ts';

const params = new URLSearchParams(location.search);
const version = params.get('version') === 'ga' ? 'ga' : 'port';
const gaStats: GaStats = { builds: 0 };
const control: { rerender?: () => void; setChord?: (on: boolean) => void; unmount?: () => void; state?: RootState; frames: number } = { frames: 0 };
const clicks: NoteClick[] = [];

function App() {
  const [, setRenders] = useState(0);
  const [chord, setChord] = useState(false);
  const [mounted, setMounted] = useState(true);
  control.rerender = () => setRenders((n) => n + 1);
  control.setChord = setChord;
  control.unmount = () => setMounted(false);
  // As GA's callers write it: a new array literal on every render, with the same content
  const positions: Position[] = chord ? C_MAJOR.map((p) => ({ ...p })) : [];

  if (version === 'ga') {
    return mounted ? <GaFretboard positions={positions} tuning={['E', 'B', 'G', 'D', 'A', 'E']} stats={gaStats} forceWebGL={forceWebGL} /> : null;
  }
  return (
    <Canvas
      dpr={[1, 2]}
      gl={async (props) => {
        const renderer = new THREE.WebGPURenderer({ ...(props as object), antialias: true, forceWebGL });
        await renderer.init();
        // R3F sets ACES Filmic tone mapping unless <Canvas flat>; GA uses it too, with this exposure
        renderer.toneMappingExposure = 1.2;
        return renderer;
      }}
      camera={{ position: [-12, 18, 40], fov: 35 }}
      onCreated={(state) => void (control.state = state)}
    >
      <color attach="background" args={[0x2a2a2a]} />
      <ambientLight intensity={0.6} />
      <directionalLight position={[10, 30, 20]} intensity={2} />
      {mounted && <Fretboard3D positions={positions} onPositionClick={(click) => clicks.push(click)} />}
      <OrbitControls enableDamping makeDefault />
      <FrameCounter />
    </Canvas>
  );
}

function FrameCounter() {
  useFrame(() => void control.frames++);
  return null;
}

const root = document.createElement('div');
root.id = 'root';
document.body.append(root);
createRoot(root).render(<App />);

// The GA version draws in its own loop: count its frames from the renderer
function frameCount(): number {
  return version === 'ga' ? (gaStats.renderer?.info.frame ?? 0) : control.frames;
}
const nextFrames = (n: number) =>
  new Promise<void>((resolve) => {
    const target = frameCount() + n;
    const wait = () => (frameCount() >= target ? resolve() : requestAnimationFrame(wait));
    wait();
  });

function renderer(): THREE.WebGPURenderer | undefined {
  return version === 'ga' ? gaStats.renderer : (control.state?.gl as unknown as THREE.WebGPURenderer | undefined);
}

function snapshot() {
  const r = renderer()!;
  const { render, memory } = r.info;
  const canvas = r.domElement;
  return {
    drawCalls: render.drawCalls,
    triangles: render.triangles,
    geometries: memory.geometries,
    textures: memory.textures,
    programs: memory.programs,
    drawingBuffer: `${canvas.width}x${canvas.height}`,
    sceneBuilds: version === 'ga' ? gaStats.builds : 1,
    markerBuilds: version === 'ga' ? gaStats.builds : portStats.markerBuilds,
  };
}

if (probing) {
  while (!renderer() || frameCount() < 3) await new Promise(requestAnimationFrame);
  await nextFrames(3);
  document.title = `Lesson 13 — ${version} — ${backendName(renderer()!)}`;
  const first = snapshot();
  for (let i = 0; i < 10; i++) {
    // Each render committed before the next, whatever the frame rate (see lesson 9's page)
    flushSync(() => control.rerender!());
    await nextFrames(2);
  }
  await nextFrames(3);
  const afterTenRenders = snapshot();
  flushSync(() => control.setChord!(true));
  await nextFrames(3);
  const withChord = snapshot();

  const r = renderer()!;
  const camera = version === 'ga' ? findCamera() : control.state!.camera;
  const rect = r.domElement.getBoundingClientRect();
  const target = new THREE.Vector3(markerX(2), 0.2, stringZ(3)).project(camera);
  const x = Math.round(rect.left + ((target.x + 1) / 2) * rect.width);
  const y = Math.round(rect.top + ((1 - target.y) / 2) * rect.height);
  publish({
    backend: backendName(r),
    gpu: gpuName(r),
    version,
    first,
    afterTenRenders,
    withChord,
    shotAfter: 'click string 3, fret 2',
    actions: [
      {
        name: 'click string 3, fret 2',
        // A click: pointer down and up at the same point
        drag: [x, y, x, y],
      },
      { name: 'unmount', move: [20, 20] },
    ],
  });
  window.probeAfter = async (name: string) => {
    if (name === 'unmount') {
      flushSync(() => control.unmount!());
      await new Promise((resolve) => setTimeout(resolve, 100));
      // GA's unmount disposes the renderer, whose info is still readable; R3F's canvas keeps rendering
      if (version === 'port') await nextFrames(3);
      return snapshot();
    }
    await nextFrames(3);
    return { clicks: [...clicks], pluckedStrings: version === 'port' ? [...portStats.plucked] : null, ...snapshot() };
  };
}

function findCamera(): THREE.Camera {
  // GaFretboard keeps its camera inside its effect, as GA does; its position is fixed, so an identical camera projects the same
  const r = gaStats.renderer!;
  const camera = new THREE.PerspectiveCamera(35, r.domElement.clientWidth / r.domElement.clientHeight, 0.1, 1000);
  camera.position.set(-12, 18, 40);
  // OrbitControls points it at its target, the origin
  camera.lookAt(0, 0, 0);
  camera.updateMatrixWorld();
  return camera;
}

declare global {
  interface Window {
    probeAfter?: (name: string) => Promise<unknown>;
  }
}
