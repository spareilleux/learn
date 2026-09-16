// Lesson 6: node materials written in TSL. The neck gets a procedural rosewood grain (colorNode), and a string vibrates
// in the vertex shader (positionNode), driven by uniforms that JavaScript updates without recompiling anything.
// ?t=0.25 sets the vibration's time in periods, ?harmonic=2 the mode; the probe reads pixels on and beside the moving string.
import * as THREE from 'three/webgpu';
import { color, float, Fn, mix, mx_noise_float, PI, positionLocal, positionWorld, sin, smoothstep, uniform, vec3 } from 'three/tsl';
import { backendName, forceWebGL, probing, report } from '../probe.ts';

const params = new URLSearchParams(location.search);

const renderer = new THREE.WebGPURenderer({ antialias: true, forceWebGL });
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.setSize(window.innerWidth, window.innerHeight);
document.body.append(renderer.domElement);

const scene = new THREE.Scene();
scene.background = new THREE.Color(0x1e2127);
scene.add(new THREE.HemisphereLight(0xdde6ff, 0x302820, 1.5));
const sun = new THREE.DirectionalLight(0xffffff, 2.5);
sun.position.set(1, 4, 3);
scene.add(sun);

// Straight above the neck, so that the string's up-and-down motion shows as a vertical offset on the screen
const camera = new THREE.OrthographicCamera(-2, 2, 1.125, -1.125, 0.1, 10);
camera.position.set(0, 0, 5);

// Rosewood: dark and light bands along the neck, bent by noise, computed per pixel on the GPU
const grain = Fn(() => {
  const p = positionWorld;
  const bend = mx_noise_float(vec3(p.x.mul(0.8), p.y.mul(6), 0)).mul(0.6);
  const bands = sin(p.y.mul(90).add(bend.mul(12))).mul(0.5).add(0.5);
  return mix(color(0x2a160d), color(0x5a3422), smoothstep(0.2, 0.9, bands));
});
const neckMaterial = new THREE.MeshStandardNodeMaterial({ roughness: 0.75 });
neckMaterial.colorNode = grain();
const neck = new THREE.Mesh(new THREE.PlaneGeometry(3.6, 0.9), neckMaterial);
neck.name = 'neck';
scene.add(neck);

// The string: a thin box along X from −1.6 to 1.6, fixed at both ends
const LENGTH = 3.2;
const amplitude = uniform(0.2);
const phase = uniform(0); // 2π × frequency × time, set from JavaScript
const startHarmonic = Number(params.get('harmonic') ?? 1);
const harmonic = uniform(startHarmonic); // 1 = fundamental, 2 = octave: a node at the middle
const vibrate = Fn(() => {
  const u = positionLocal.x.div(LENGTH).add(0.5); // 0 at one end, 1 at the other
  const shape = sin(u.mul(PI).mul(harmonic)); // the standing wave's shape, 0 at both ends
  const offset = amplitude.mul(shape).mul(sin(phase));
  return positionLocal.add(vec3(0, offset, 0));
});
const stringMaterial = new THREE.MeshBasicNodeMaterial();
stringMaterial.colorNode = color(0xf2efe6);
stringMaterial.positionNode = vibrate();
const string = new THREE.Mesh(new THREE.BoxGeometry(LENGTH, 0.03, 0.03, 64, 1, 1), stringMaterial);
string.name = 'string';
string.position.z = 0.05;
scene.add(string);

const t = Number(params.get('t') ?? 0.25);
let frames = 0;
renderer.setAnimationLoop(async (time) => {
  // One period per second, or the fixed ?t when probing
  phase.value = 2 * Math.PI * (probing ? t : time / 1000);
  renderer.render(scene, camera);
  frames++;
  if (probing && frames === 3) {
    renderer.setAnimationLoop(null);
    await probe();
  }
});

// Every material that TSL turns into shader code goes through a node builder: counting them counts shader builds
let nodeBuilds = 0;
renderer.debug.onNodeBuilderCreated = () => nodeBuilds++;

async function probe() {
  const { calls, drawCalls, triangles } = renderer.info.render;
  const buildsBefore = nodeBuilds;
  // A uniform change is a buffer write: the next frame reuses the same shaders
  harmonic.value = 2;
  renderer.render(scene, camera);
  const afterUniform = nodeBuilds;
  // A new node graph is a new shader: the material is built and compiled again
  stringMaterial.colorNode = color(0xffb454).mul(float(1));
  stringMaterial.needsUpdate = true;
  renderer.render(scene, camera);
  const afterNewGraph = nodeBuilds;
  stringMaterial.colorNode = color(0xf2efe6);
  stringMaterial.needsUpdate = true;
  harmonic.value = startHarmonic;
  renderer.render(scene, camera);

  const { vertexShader, fragmentShader } = await renderer.debug.getShaderAsync(scene, camera, string);
  // Screen positions: the string's middle at rest, and where the wave puts it at t
  const toScreen = (x: number, y: number): [number, number] => {
    const v = new THREE.Vector3(x, y, 0).project(camera);
    return [Math.round(((v.x + 1) / 2) * window.innerWidth), Math.round(((1 - v.y) / 2) * window.innerHeight)];
  };
  // The offset at a point u along the string (0 to 1), as the vertex shader computes it
  const offsetAt = (u: number) => amplitude.value * Math.sin(u * Math.PI * startHarmonic) * Math.sin(2 * Math.PI * t);
  const offset = offsetAt(0.5);
  report(renderer, {
    t,
    harmonic: startHarmonic,
    offsetAtMiddle: Number(offset.toFixed(4)) + 0,
    render: { calls, drawCalls, triangles },
    nodeBuilds: { firstFrames: buildsBefore, afterUniformChange: afterUniform, afterNewNodeGraph: afterNewGraph },
    shader: `// vertex\n${vertexShader ?? ''}\n// fragment\n${fragmentShader ?? ''}`,
    samples: {
      'string middle, displaced': toScreen(0, offset),
      'string middle, at rest': toScreen(0, 0),
      'quarter length, displaced': toScreen(-LENGTH / 4, offsetAt(0.25)),
    },
  });
}

window.addEventListener('resize', () => renderer.setSize(window.innerWidth, window.innerHeight));

await renderer.init();
document.title = `Lesson 6 — ${backendName(renderer)}`;
