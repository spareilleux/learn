// The universe: a guitar neck with the chord's voicings, a pitch-class bracelet that animates the transposition from the
// previous chord, and a spiral galaxy of twelve arms, one per pitch class, whose brightness follows the live chromagram.
// Plain three.js with WebGPURenderer, which falls back to WebGL 2 when WebGPU is missing. The neck's measurements are
// imported from the three.js course (lesson 13, GA's fretboard), not copied.
import * as THREE from 'three/webgpu';
import { BOARD_THICKNESS, DOUBLE_INLAYS, FRETS, INLAYS, NUT_WIDTH, SCALE, STRINGS, boardLength, fretX, markerX, stringZ } from '../../../../threejs/src/13-fretboard/guitar.ts';
import { NOTE_NAMES } from '../dsp/chords.ts';
import { OPEN_MIDI, type Voicing } from '../dsp/voicings.ts';

const hue = (pc: number) => new THREE.Color().setHSL(((pc * 7) % 12) / 12, 0.75, 0.6);
const matrix = new THREE.Matrix4();
const MAX_MARKERS = 18;

export class Universe {
  readonly renderer: THREE.WebGPURenderer;
  private readonly scene = new THREE.Scene();
  private readonly camera = new THREE.PerspectiveCamera(45, 1, 0.1, 400);
  private readonly neck = new THREE.Group();
  private readonly markers: THREE.InstancedMesh;
  private readonly bracelet = new THREE.Group();
  private readonly beads: THREE.Mesh<THREE.SphereGeometry, THREE.MeshStandardMaterial>[] = [];
  private readonly ghosts: THREE.Mesh<THREE.SphereGeometry, THREE.MeshStandardMaterial>[] = [];
  private readonly polygon: THREE.LineLoop;
  private readonly galaxy: THREE.InstancedMesh;
  private readonly galaxyPc: Uint8Array;
  private readonly galaxyBase: THREE.Color[] = [];
  private readonly chroma = new Float64Array(12);
  private lit: number[] = [];
  private animation: { from: number[]; to: number[]; target: number[]; start: number } | null = null;
  readonly braceletRadius = 2.2;

  constructor(canvas: HTMLCanvasElement, forceWebGL: boolean) {
    this.renderer = new THREE.WebGPURenderer({ canvas, antialias: true, forceWebGL });
    this.renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
    this.scene.background = new THREE.Color(0x05060d);
    this.scene.add(new THREE.AmbientLight(0xffffff, 0.6));
    const sun = new THREE.DirectionalLight(0xffffff, 2.2);
    sun.position.set(4, 8, 10);
    this.scene.add(sun);

    this.markers = this.buildNeck();
    this.polygon = this.buildBracelet();
    [this.galaxy, this.galaxyPc] = this.buildGalaxy();
    this.scene.add(this.neck, this.bracelet, this.galaxy);
  }

  async init(): Promise<string> {
    await this.renderer.init();
    return 'isWebGPUBackend' in this.renderer.backend && this.renderer.backend.isWebGPUBackend ? 'WebGPU' : 'WebGL 2';
  }

  resize(width: number, height: number): void {
    this.renderer.setSize(width, height, false);
    this.camera.aspect = width / height;
    // Portrait screens: move back so the neck still fits
    const distance = width / height < 1 ? 16 / (width / height) ** 0.8 : 15;
    this.camera.position.set(0, 0.5, distance);
    this.camera.lookAt(0, 0, 0);
    this.camera.updateProjectionMatrix();
    const narrow = width < 700;
    this.bracelet.position.set(narrow ? 0 : 3.2, narrow ? 0.4 : 1.3, 0);
    this.neck.position.set(narrow ? 0 : 1.2, -3.4, 0);
  }

  private buildNeck(): THREE.InstancedMesh {
    const length = boardLength();
    const board = new THREE.Mesh(new THREE.BoxGeometry(length, BOARD_THICKNESS, NUT_WIDTH), new THREE.MeshStandardMaterial({ color: 0x3b2418, roughness: 0.8 }));
    board.position.x = length / 2 - SCALE / 2;
    const nut = new THREE.Mesh(new THREE.BoxGeometry(0.3, 0.6, NUT_WIDTH), new THREE.MeshStandardMaterial({ color: 0xf2ead8 }));
    nut.position.set(-SCALE / 2, 0.2, 0);
    const frets = new THREE.InstancedMesh(new THREE.BoxGeometry(0.12, 0.25, NUT_WIDTH), new THREE.MeshStandardMaterial({ color: 0xd8d0c0, metalness: 1, roughness: 0.3 }), FRETS);
    for (let n = 1; n <= FRETS; n++) frets.setMatrixAt(n - 1, matrix.makeTranslation(fretX(n), BOARD_THICKNESS / 2 + 0.1, 0));
    const dots = [...INLAYS.map((n) => [n, 0]), ...DOUBLE_INLAYS.filter((n) => n <= FRETS).flatMap((n) => [[n, -0.8], [n, 0.8]])];
    const inlays = new THREE.InstancedMesh(new THREE.CylinderGeometry(0.18, 0.18, 0.02, 20), new THREE.MeshStandardMaterial({ color: 0xf5f5dc }), dots.length);
    dots.forEach(([n, z], i) => inlays.setMatrixAt(i, matrix.makeTranslation((fretX(n) + fretX(n - 1)) / 2, BOARD_THICKNESS / 2 + 0.01, z)));
    const strings = new THREE.InstancedMesh(new THREE.CylinderGeometry(0.03, 0.03, length + 1, 6).rotateZ(Math.PI / 2), new THREE.MeshStandardMaterial({ color: 0xcfc8b8, metalness: 1, roughness: 0.35 }), STRINGS);
    for (let s = 0; s < STRINGS; s++) strings.setMatrixAt(s, matrix.makeTranslation(length / 2 - SCALE / 2, 0.45, stringZ(s)));
    const markers = new THREE.InstancedMesh(new THREE.SphereGeometry(0.34, 20, 12), new THREE.MeshStandardMaterial({ roughness: 0.35, emissive: 0x222222 }), MAX_MARKERS);
    markers.instanceColor = new THREE.InstancedBufferAttribute(new Float32Array(MAX_MARKERS * 3).fill(1), 3);
    markers.count = 0;
    this.neck.add(board, nut, frets, inlays, strings, markers);
    // GA's units are 10 mm: scale the 70-unit neck to the scene, and tilt its face towards the camera
    this.neck.scale.setScalar(0.16);
    this.neck.rotation.x = 1.05;
    return markers;
  }

  private buildBracelet(): THREE.LineLoop {
    const r = this.braceletRadius;
    const ring = new THREE.Mesh(new THREE.TorusGeometry(r, 0.025, 8, 96), new THREE.MeshStandardMaterial({ color: 0x5a6390 }));
    this.bracelet.add(ring);
    const geometry = new THREE.SphereGeometry(0.2, 24, 12);
    for (let pc = 0; pc < 12; pc++) {
      const bead = new THREE.Mesh(geometry, new THREE.MeshStandardMaterial({ color: 0x2a2f4a, roughness: 0.4, emissive: hue(pc), emissiveIntensity: 0 }));
      bead.position.copy(this.beadPosition(pc));
      this.bracelet.add(bead);
      this.beads.push(bead);
      const label = new THREE.Sprite(new THREE.SpriteMaterial({ map: labelTexture(`${NOTE_NAMES[pc]}`), transparent: true, depthWrite: false }));
      label.position.copy(this.beadPosition(pc, r + 0.55));
      label.scale.set(0.6, 0.3, 1);
      this.bracelet.add(label);
    }
    for (let i = 0; i < 6; i++) {
      const ghost = new THREE.Mesh(geometry, new THREE.MeshStandardMaterial({ color: 0xffffff, emissive: 0xffcf5a, emissiveIntensity: 1.5, transparent: true, opacity: 0.85 }));
      ghost.visible = false;
      ghost.scale.setScalar(0.8);
      this.bracelet.add(ghost);
      this.ghosts.push(ghost);
    }
    const polygon = new THREE.LineLoop(new THREE.BufferGeometry(), new THREE.LineBasicMaterial({ color: 0xffcf5a }));
    this.bracelet.add(polygon);
    return polygon;
  }

  /** Pitch class 0 at the top, clockwise, as in the music theory course's bracelet diagrams */
  private beadPosition(pc: number, radius = this.braceletRadius): THREE.Vector3 {
    const angle = Math.PI / 2 - (pc * Math.PI) / 6;
    return new THREE.Vector3(radius * Math.cos(angle), radius * Math.sin(angle), 0);
  }

  private buildGalaxy(): [THREE.InstancedMesh, Uint8Array] {
    const count = 2400;
    const mesh = new THREE.InstancedMesh(new THREE.OctahedronGeometry(0.09, 0), new THREE.MeshBasicMaterial({ color: 0xffffff }), count);
    const pcs = new Uint8Array(count);
    // A fixed seed, so every visitor sees the same sky
    let seed = 12;
    const random = () => ((seed = (seed * 16807) % 2147483647) - 1) / 2147483646;
    const colors = new Float32Array(count * 3);
    for (let i = 0; i < count; i++) {
      const pc = i % 12;
      pcs[i] = pc;
      const t = random();
      const radius = 3 + t * 38;
      const angle = (pc * Math.PI) / 6 + t * 5.5 + (random() - 0.5) * 0.35;
      const x = radius * Math.cos(angle) + (random() - 0.5) * 2;
      const y = radius * Math.sin(angle) * 0.55 + (random() - 0.5) * 2;
      const z = -40 - random() * 20 + radius * 0.2;
      const s = 0.6 + random() * 1.8;
      matrix.makeScale(s, s, s).setPosition(x, y, z);
      mesh.setMatrixAt(i, matrix);
      const c = hue(pc);
      this.galaxyBase.push(c);
      colors.set([c.r * 0.15, c.g * 0.15, c.b * 0.15], i * 3);
    }
    mesh.instanceColor = new THREE.InstancedBufferAttribute(colors, 3);
    return [mesh, pcs];
  }

  setChroma(chroma: ArrayLike<number>): void {
    let max = 0;
    for (let i = 0; i < 12; i++) max = Math.max(max, chroma[i]);
    for (let i = 0; i < 12; i++) this.chroma[i] = this.chroma[i] * 0.7 + 0.3 * (max > 0 ? chroma[i] / max : 0);
  }

  /** Lights the voicings on the neck: the first one bright, root in gold, the next two dimmer. */
  setVoicings(list: Voicing[], root: number): void {
    let i = 0;
    const color = new THREE.Color();
    list.slice(0, 3).forEach((v, rank) => {
      const dim = rank === 0 ? 1 : 0.28;
      const lift = rank === 0 ? 1.0 : 0.7 + rank * 0.25;
      v.frets.forEach((fret, string) => {
        if (fret < 0 || i >= MAX_MARKERS) return;
        const pc = (OPEN_MIDI[string] + fret) % 12;
        const scale = rank === 0 ? 1 : 0.6;
        matrix.makeScale(scale, scale, scale).setPosition(markerX(fret), lift, stringZ(string));
        this.markers.setMatrixAt(i, matrix);
        this.markers.setColorAt(i, color.set(pc === root ? 0xffcf5a : 0x5ab0ff).multiplyScalar(dim));
        i++;
      });
    });
    this.markers.count = i;
    this.markers.instanceMatrix.needsUpdate = true;
    if (this.markers.instanceColor) this.markers.instanceColor.needsUpdate = true;
    this.markers.computeBoundingSphere();
  }

  /**
   * Lights a pitch-class set on the bracelet. With a previous set, ghosts travel from the old beads by the
   * transposition interval (root to root); when the qualities match they land exactly on the new beads.
   */
  setPitchClasses(pcs: number[], interval: number | null): void {
    const from = this.lit;
    this.lit = [...pcs].sort((a, b) => a - b);
    if (interval === null || from.length === 0) {
      this.applyLit();
      return;
    }
    const target = from.map((pc) => pc + (((interval + 6) % 12) - 6));
    this.animation = { from, to: this.lit, target, start: performance.now() };
  }

  private applyLit(): void {
    this.beads.forEach((bead, pc) => {
      const on = this.lit.includes(pc);
      bead.material.emissiveIntensity = on ? 1.6 : 0;
      bead.scale.setScalar(on ? 1.35 : 1);
    });
    const points = this.lit.map((pc) => this.beadPosition(pc));
    this.polygon.geometry.dispose();
    this.polygon.geometry = new THREE.BufferGeometry().setFromPoints(points.length >= 2 ? points : []);
  }

  render(now: number): void {
    // Galaxy: slow rotation, arms brighten with their pitch class
    this.galaxy.rotation.z = now * 0.00002;
    const colors = this.galaxy.instanceColor!;
    for (let i = 0; i < this.galaxyPc.length; i++) {
      const c = this.galaxyBase[i];
      const k = 0.12 + 1.1 * this.chroma[this.galaxyPc[i]];
      colors.setXYZ(i, c.r * k, c.g * k, c.b * k);
    }
    colors.needsUpdate = true;

    this.beads.forEach((bead, pc) => {
      if (!this.lit.includes(pc)) bead.material.emissiveIntensity = 0.6 * this.chroma[pc];
    });

    if (this.animation) {
      const t = Math.min(1, (now - this.animation.start) / 700);
      const ease = t < 0.5 ? 2 * t * t : 1 - (-2 * t + 2) ** 2 / 2;
      this.ghosts.forEach((ghost, i) => {
        const a = this.animation!;
        if (i >= a.from.length) {
          ghost.visible = false;
          return;
        }
        ghost.visible = true;
        const pc = a.from[i] + (a.target[i] - a.from[i]) * ease;
        ghost.position.copy(this.beadPosition(pc));
      });
      this.bracelet.rotation.z = Math.sin(t * Math.PI) * 0.04;
      if (t >= 1) {
        this.animation = null;
        this.ghosts.forEach((g) => (g.visible = false));
        this.applyLit();
      }
    }
    this.renderer.render(this.scene, this.camera);
  }
}

function labelTexture(text: string): THREE.CanvasTexture {
  const canvas = document.createElement('canvas');
  canvas.width = 128;
  canvas.height = 64;
  const context = canvas.getContext('2d')!;
  context.fillStyle = '#c8cce8';
  context.font = 'bold 40px system-ui, sans-serif';
  context.textAlign = 'center';
  context.textBaseline = 'middle';
  context.fillText(text, 64, 34);
  const texture = new THREE.CanvasTexture(canvas);
  texture.colorSpace = THREE.SRGBColorSpace;
  return texture;
}
