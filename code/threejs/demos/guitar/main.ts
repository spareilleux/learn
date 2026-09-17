// Live demo: a whole guitar to orbit around. Click the neck to play a note: the string vibrates from the pressed fret to
// the saddle, a plucked-string sound plays, and the note's name shows. The panel strums open chords.
// ?probe: fixed camera; the probe clicks string 3 (G), fret 5 through real pointer events and reads the note.
import * as THREE from 'three/webgpu';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { RoomEnvironment } from 'three/addons/environments/RoomEnvironment.js';
import GUI from 'three/addons/libs/lil-gui.module.min.js';
import { fretAtX, markerX, noteAt } from '../../src/13-fretboard/guitar.ts';
import { backendName, gpuName, probing, publish } from '../../src/probe.ts';
import { createRenderer, followWindow, onClick, overlay, toNdc, toScreen } from '../common.ts';
import { buildGuitar, stringAt, stringY, stringZAt } from './model.ts';
import { createPlucker, OPEN_STRINGS } from './pluck.ts';

const renderer = await createRenderer();
const scene = new THREE.Scene();
scene.background = new THREE.Color(0x3a3f4a);
// A room lit by a few boxes of light, rendered once into an environment map: reflections for the lacquer and chrome
const pmrem = new THREE.PMREMGenerator(renderer);
scene.environment = pmrem.fromScene(new RoomEnvironment(), 0.04).texture;
scene.environmentIntensity = 0.7;
const key = new THREE.DirectionalLight(0xffffff, 1.5);
key.position.set(-20, 60, 40);
scene.add(key);

const camera = new THREE.PerspectiveCamera(35, 1, 1, 1000);
// ?view=body or ?view=headstock starts close up
const VIEWS: Record<string, [number[], number[]]> = {
  guitar: [[-6, 62, 82], [-7, -2, 0]],
  body: [[22, 28, 34], [26, -1, 0]],
  headstock: [[-40, 16, 20], [-46, -1, 1]],
};
const [eye, look] = VIEWS[new URLSearchParams(location.search).get('view') ?? 'guitar'] ?? VIEWS.guitar;
camera.position.set(eye[0], eye[1], eye[2]);
followWindow(renderer, camera);
const controls = new OrbitControls(camera, renderer.domElement);
controls.target.set(look[0], look[1], look[2]);
controls.enableDamping = !probing;
controls.minDistance = 20;
controls.maxDistance = 250;
controls.update();

const guitar = buildGuitar();
scene.add(guitar.group);

// A small glowing dot where the finger presses
const finger = new THREE.Mesh(new THREE.SphereGeometry(0.45, 16, 8), new THREE.MeshStandardMaterial({ color: 0xffb454, emissive: 0xb86a00 }));
finger.visible = false;
scene.add(finger);

const say = overlay();
say('Drag to orbit, click the neck to play a note');
const plucker = createPlucker();
const settings = { sound: !probing, volume: 0.5, autoRotate: false };

// Pointing at the neck: the ray must cross the invisible target over the fretboard, then the point where it crosses the
// plane of the strings gives the fret (lesson 13's formula) and the nearest string
const raycaster = new THREE.Raycaster();
const stringPlane = new THREE.Plane(new THREE.Vector3(0, 1, 0), -0.45);
const hit = new THREE.Vector3();
type Pick = { string: number; fret: number; note: string };
function pickAt(ndc: THREE.Vector2): Pick | null {
  raycaster.setFromCamera(ndc, camera);
  if (raycaster.intersectObject(guitar.pickTarget).length === 0) return null;
  if (!raycaster.ray.intersectPlane(stringPlane, hit)) return null;
  const fret = fretAtX(hit.x);
  if (fret === null) return null;
  const string = stringAt(hit.x, hit.z);
  return { string, fret, note: noteAt(string, fret) };
}

function play({ string, fret, note }: Pick, delaySeconds = 0) {
  guitar.pluck(string, fret);
  if (settings.sound) plucker.play(OPEN_STRINGS[string] + fret, delaySeconds);
  const x = markerX(fret);
  finger.position.set(x, stringY(x) + 0.2, stringZAt(string, x));
  finger.visible = fret > 0;
  say(`String ${string + 1}, ${fret === 0 ? 'open' : `fret ${fret}`}: ${note}`);
}

const picks: Pick[] = [];
const ndc = new THREE.Vector2();
onClick(renderer.domElement, (event) => {
  const pick = pickAt(toNdc(event, renderer.domElement, ndc));
  if (!pick) return;
  picks.push(pick);
  play(pick);
});

// Open chords, from string 0 (high E) to string 5 (low E); −1 is a string not played
const CHORDS: Record<string, number[]> = {
  C: [0, 1, 0, 2, 3, -1],
  G: [3, 0, 0, 0, 2, 3],
  D: [2, 3, 2, 0, -1, -1],
  Am: [0, 1, 2, 2, 0, -1],
  Em: [0, 0, 0, 2, 2, 0],
  E7: [0, 0, 1, 0, 2, 0],
};
function strum(name: string) {
  // From the low string to the high one, 35 ms apart
  CHORDS[name].map((fret, string) => ({ fret, string })).reverse().filter(({ fret }) => fret >= 0).forEach(({ fret, string }, i) => {
    setTimeout(() => play({ string, fret, note: noteAt(string, fret) }), i * 35);
  });
  say(`${name}: ${CHORDS[name].map((f) => (f < 0 ? 'x' : f)).reverse().join(' ')} (low E to high E)`);
}

if (!probing) {
  const gui = new GUI({ title: 'Guitar' });
  gui.add(settings, 'sound');
  gui.add(settings, 'volume', 0, 1, 0.05).onChange((value: number) => plucker.setVolume(value));
  gui.add(settings, 'autoRotate').name('auto-rotate').onChange((value: boolean) => void (controls.autoRotate = value));
  const chords = gui.addFolder('Strum a chord');
  for (const name of Object.keys(CHORDS)) chords.add({ [name]: () => strum(name) }, name);
}

let frames = 0;
renderer.setAnimationLoop((time) => {
  guitar.update(time / 1000);
  controls.update();
  renderer.render(scene, camera);
  frames++;
  if (probing && frames === 3) {
    const { render, memory } = renderer.info;
    const target = new THREE.Vector3(markerX(5), stringY(markerX(5)), stringZAt(2, markerX(5)));
    const [x, y] = toScreen(target, camera, renderer.domElement);
    window.probeAfter = async (name) => ({ name, picks: picks.map((p) => `string ${p.string + 1}, fret ${p.fret}: ${p.note}`) });
    publish({
      backend: backendName(renderer),
      gpu: gpuName(renderer),
      render: { drawCalls: render.drawCalls, triangles: render.triangles },
      memory: { geometries: memory.geometries, textures: memory.textures },
      actions: [{ name: 'click string 3, fret 5', drag: [x, y, x, y] }],
      shotAfter: 'click string 3, fret 5',
    });
  }
});
