// Experiment 14, React Three Fiber side: lesson 13's Fretboard3D in a <Canvas> that never renders on its own; frames
// come from R3F's advance(), which runs the useFrame subscribers, then renders.
import { createRoot } from 'react-dom/client';
import { advance, Canvas, type RootState } from '@react-three/fiber';
import * as THREE from 'three/webgpu';
import { Fretboard3D } from '../../../src/13-fretboard/Fretboard3D.tsx';
import { C_MAJOR } from '../../../src/13-fretboard/guitar.ts';

export async function start(width: number, height: number, forceWebGL: boolean): Promise<{ renderer: THREE.WebGPURenderer; draw: (i: number) => void }> {
  const positions = C_MAJOR.map((p) => ({ ...p }));
  const host = document.createElement('div');
  host.style.cssText = `width:${width}px;height:${height}px`;
  document.body.append(host);
  let state: RootState | undefined;
  createRoot(host).render(
    <Canvas
      frameloop="never"
      dpr={1}
      gl={async (props) => {
        const r = new THREE.WebGPURenderer({ ...(props as object), antialias: true, forceWebGL });
        await r.init();
        r.toneMappingExposure = 1.2;
        return r;
      }}
      camera={{ position: [-12, 18, 40], fov: 35 }}
      onCreated={(s) => void (state = s)}
    >
      <color attach="background" args={[0x2a2a2a]} />
      <ambientLight intensity={0.6} />
      <directionalLight position={[10, 30, 20]} intensity={2} />
      <Fretboard3D positions={positions} />
    </Canvas>,
  );
  while (!state) await new Promise(requestAnimationFrame);
  const root = state;
  return { renderer: root.gl as unknown as THREE.WebGPURenderer, draw: (i) => advance(1000 + i * 16.667, true, root) };
}
