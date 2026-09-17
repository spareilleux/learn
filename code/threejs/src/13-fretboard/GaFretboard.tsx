// Lesson 13: the structure of GuitarAlchemist's ThreeFretboard.tsx at commit 05c8eda, condensed: the same objects per
// fret, inlay, string, label and marker, the same effect dependencies, the same cleanup, and the same pixel ratio. The
// wood and string textures, the neck's back, the nut, the capo and the lights beyond two are left out; the line numbers
// in comments point to GA's file.
import { useEffect, useRef } from 'react';
import * as THREE from 'three/webgpu';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { boardLength, BOARD_THICKNESS, DOUBLE_INLAYS, FRETS, fretDistance, fretX, INLAYS, markerX, NUT_WIDTH, SCALE, STRINGS, stringZ, type Position } from './guitar.ts';

export type GaStats = { builds: number; renderer?: THREE.WebGPURenderer; scene?: THREE.Scene };

type Props = { positions?: Position[]; tuning?: string[]; stats: GaStats; forceWebGL: boolean };

// GA's defaults: positions = [] (line 58), and a tuning array that its callers pass as a literal (main.tsx:153)
export function GaFretboard({ positions = [], tuning = ['E', 'B', 'G', 'D', 'A', 'E'], stats, forceWebGL }: Props) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const rendererRef = useRef<THREE.WebGPURenderer | null>(null);
  const sceneRef = useRef<THREE.Scene | null>(null);

  useEffect(() => {
    let isMounted = true;
    let controls: OrbitControls | null = null;
    (async () => {
      // The renderer is kept across effect runs (lines 147-150)
      let renderer = rendererRef.current;
      if (!renderer) {
        renderer = new THREE.WebGPURenderer({ canvas: canvasRef.current!, antialias: true, alpha: true, forceWebGL, samples: 8 });
        await renderer.init();
        if (!isMounted) return;
        rendererRef.current = renderer;
      }
      const width = canvasRef.current!.parentElement!.clientWidth;
      const height = canvasRef.current!.parentElement!.clientHeight;
      renderer.setSize(width, height);
      renderer.setPixelRatio(Math.min(window.devicePixelRatio * 3, 6)); // line 204
      renderer.toneMapping = THREE.ACESFilmicToneMapping; // lines 238-239
      renderer.toneMappingExposure = 1.2;

      const scene = new THREE.Scene();
      scene.background = new THREE.Color(0x2a2a2a);
      sceneRef.current = scene;
      scene.add(new THREE.AmbientLight(0xffffff, 0.6));
      const light = new THREE.DirectionalLight(0xffffff, 2);
      light.position.set(10, 30, 20);
      scene.add(light);
      const camera = new THREE.PerspectiveCamera(35, width / height, 0.1, 1000);
      camera.position.set(-12, 18, 40); // lines 222-224
      controls = new OrbitControls(camera, renderer.domElement);
      controls.enableDamping = true;

      buildGaScene(scene, positions, tuning);
      stats.builds++;
      stats.renderer = renderer;
      stats.scene = scene;
      renderer.setAnimationLoop(() => {
        controls?.update();
        renderer.render(scene, camera);
      });
    })();

    // The cleanup of lines 383-423: meshes only, and their map, bumpMap and normalMap
    return () => {
      isMounted = false;
      sceneRef.current?.traverse((object) => {
        if (object instanceof THREE.Mesh) {
          object.geometry.dispose();
          const material = object.material as THREE.MeshStandardMaterial;
          material.map?.dispose();
          material.bumpMap?.dispose();
          material.normalMap?.dispose();
          material.dispose();
        }
      });
      sceneRef.current?.clear();
      rendererRef.current?.setAnimationLoop(null);
      controls?.dispose();
    };
    // Line 424 lists more dependencies (sizes, model, capo…); these two are the arrays
  }, [positions, tuning]);

  // Unmount (lines 427-443)
  useEffect(
    () => () => {
      rendererRef.current?.setAnimationLoop(null);
      rendererRef.current?.dispose();
    },
    [],
  );

  return <canvas ref={canvasRef} />;
}

function buildGaScene(parent: THREE.Scene, positions: Position[], tuning: string[]) {
  const length = boardLength();
  const board = new THREE.Mesh(
    new THREE.BoxGeometry(length, BOARD_THICKNESS, NUT_WIDTH),
    new THREE.MeshStandardMaterial({ color: 0x3b2418, roughness: 0.8 }),
  );
  board.position.set(length / 2 - SCALE / 2, 0, 0);
  parent.add(board);

  // Fret numbers 0 to 22: a canvas, a CanvasTexture, a SpriteMaterial and a Sprite each (lines 1257-1300)
  for (let n = 0; n <= FRETS; n++) parent.add(labelSprite(String(n), 256, 128, fretX(n), 0.5, NUT_WIDTH / 2 + 0.8, 1.2, 0.6));
  // Tuning labels: one 64 × 64 canvas per string (lines 1218-1254)
  tuning.forEach((name, s) => parent.add(labelSprite(name, 64, 64, -SCALE / 2 - 0.8, 0.5, stringZ(s), 0.5, 0.5)));

  // Frets: a CapsuleGeometry and a MeshPhysicalMaterial for each of the 22 (lines 960-1016)
  for (let n = 1; n <= FRETS; n++) {
    const geometry = new THREE.CapsuleGeometry(0.15, NUT_WIDTH - 0.3, 8, 24);
    geometry.rotateX(Math.PI / 2);
    const material = new THREE.MeshPhysicalMaterial({ color: 0xd8d0c0, metalness: 1, roughness: 0.28, clearcoat: 0.35, clearcoatRoughness: 0.18, sheen: 0.3 });
    const fret = new THREE.Mesh(geometry, material);
    fret.position.set(fretX(n), BOARD_THICKNESS / 2 + 0.12, 0);
    parent.add(fret);
  }

  // Inlays: a geometry and a material each (lines 1019-1071)
  const inlayAt = (fret: number, z: number) => {
    const inlay = new THREE.Mesh(
      new THREE.CylinderGeometry(0.15, 0.15, 0.02, 32),
      new THREE.MeshStandardMaterial({ color: 0xf5f5dc, roughness: 0.2, metalness: 0.3, emissive: 0xffffff, emissiveIntensity: 0.15 }),
    );
    inlay.position.set((fretX(fret) + fretX(fret - 1)) / 2, 0.39 - 0.18, z);
    parent.add(inlay);
  };
  INLAYS.filter((n) => n <= FRETS).forEach((n) => inlayAt(n, 0));
  DOUBLE_INLAYS.filter((n) => n <= FRETS).forEach((n) => [-0.8, 0.8].forEach((z) => inlayAt(n, z)));

  // Strings: a geometry and a material each, radius = gauge in inches × 2.54 / 10 (lines 1078-1150)
  const gauges = [0.01, 0.013, 0.017, 0.026, 0.036, 0.046];
  const stringLength = fretDistance(FRETS) + (fretDistance(FRETS) - fretDistance(FRETS - 1)) * 3;
  for (let s = 0; s < STRINGS; s++) {
    const radius = (gauges[s] * 2.54) / 10;
    const string = new THREE.Mesh(
      new THREE.CylinderGeometry(radius, radius, stringLength, s >= 2 ? 32 : 16, 1, true),
      s >= 2
        ? new THREE.MeshPhysicalMaterial({ color: 0xb8a070, metalness: 1, roughness: 0.35, clearcoat: 0.3 })
        : new THREE.MeshStandardMaterial({ color: 0xe0e0e0, roughness: 0.1, metalness: 0.98 }),
    );
    string.position.set(stringLength / 2 - SCALE / 2, 0.55, stringZ(s));
    string.rotation.z = Math.PI / 2;
    parent.add(string);
  }

  // Markers: a SphereGeometry(0.2, 32, 32) and a material each (lines 1303-1365)
  for (const { string, fret, color } of positions) {
    const markerColor = color ? parseInt(color.replace('#', '0x')) : 0xff6b6b;
    const marker = new THREE.Mesh(
      new THREE.SphereGeometry(0.2, 32, 32),
      new THREE.MeshStandardMaterial({ color: markerColor, roughness: 0.3, metalness: 0.2, emissive: markerColor, emissiveIntensity: 0.2 }),
    );
    marker.position.set(markerX(fret), 1.0, stringZ(string));
    parent.add(marker);
  }
}

function labelSprite(text: string, width: number, height: number, x: number, y: number, z: number, sx: number, sy: number): THREE.Sprite {
  const canvas = document.createElement('canvas');
  canvas.width = width;
  canvas.height = height;
  const context = canvas.getContext('2d')!;
  context.fillStyle = '#ffffff';
  context.font = `bold ${Math.round(height * 0.56)}px Arial`;
  context.textAlign = 'center';
  context.textBaseline = 'middle';
  context.fillText(text, width / 2, height / 2);
  const sprite = new THREE.Sprite(new THREE.SpriteMaterial({ map: new THREE.CanvasTexture(canvas) }));
  sprite.scale.set(sx, sy, 1);
  sprite.position.set(x, y, z);
  return sprite;
}
