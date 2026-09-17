// The explorer: GA's voicings as a point cloud in their first three principal components.
// Query parameters: ?webgl forces the WebGL 2 backend; ?data=<folder> loads another data folder (the local full-index mode);
// ?probe runs the frame-time measurement instead of waiting for the user (scripts/probe.mjs); ?mode=points draws 1-pixel
// THREE.Points instead of instanced sprites; ?synthetic=<n> replaces the data with n random points (probe only).
import * as THREE from 'three/webgpu';
import { attribute, float, instancedBufferAttribute, length, smoothstep, uniform, uv, vec3 } from 'three/tsl';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { drawDiagram } from './lib/diagram.mjs';
import { decode } from './lib/format.mjs';
import { knnByDot } from './lib/knn.mjs';
import { strum } from './lib/synth.mjs';
import { chartName, midiNotes, NOTE_NAMES, parseChordName, toChartOrder, TUNINGS } from './lib/voicing.mjs';

const params = new URLSearchParams(location.search);
const probing = params.has('probe');
const mode = params.get('mode') === 'points' ? 'points' : 'sprites';
const dataFolder = (params.get('data') ?? 'data').replace(/[^\w-]/g, '');
let resolveProbe;
if (probing) window.probe = new Promise((resolve) => (resolveProbe = resolve));

const $ = (id) => document.getElementById(id);
const status = (text) => ($('status').textContent = text);

const PALETTE = ['#4e79a7', '#e15759', '#f28e2b', '#76b7b2', '#b07aa1', '#edc948', '#59a14f', '#ff9da7', '#9c755f', '#86bcb6', '#bab0ac', '#555b66'];
const RAMP = (t) => new THREE.Color().setHSL(0.66 - 0.66 * Math.min(1, Math.max(0, t)), 0.8, 0.55);

async function loadData() {
  if (params.has('synthetic')) return syntheticData(Number(params.get('synthetic')));
  const t0 = performance.now();
  const manifest = await (await fetch(`./${dataFolder}/manifest.json`)).json();
  const buffer = await (await fetch(`./${dataFolder}/voicings.bin`)).arrayBuffer();
  const data = decode(buffer);
  if (manifest.vectorsFile) {
    const vb = await (await fetch(`./${dataFolder}/${manifest.vectorsFile}`)).arrayBuffer();
    data.vectors = new Float32Array(vb);
  }
  data.loadMs = performance.now() - t0;
  data.bytes = buffer.byteLength + (data.vectors?.byteLength ?? 0);
  return { manifest, data };
}

function syntheticData(n) {
  let s = 12345;
  const random = () => ((s = (Math.imul(s, 1103515245) + 12345) >>> 0) / 4294967296);
  const positions = new Float32Array(n * 3).map(() => random() * 2 - 1);
  const zeros = new Uint8Array(n);
  return {
    manifest: { families: [{ id: 'synthetic', label: 'synthetic' }], names: ['synthetic'], count: n, seed: 0, source: {} },
    data: { count: n, k: 0, positions, family: zeros, tension: zeros, lowFret: zeros, noteCount: zeros, span: zeros, loadMs: 0, bytes: positions.byteLength },
  };
}

const { manifest, data } = await loadData();
const N = data.count;

// Renderer, scene, camera
const canvas = $('scene');
const renderer = new THREE.WebGPURenderer({ canvas, antialias: true, forceWebGL: params.has('webgl'), trackTimestamp: probing });
renderer.setPixelRatio(probing ? 1 : Math.min(devicePixelRatio, 2));
renderer.setSize(canvas.clientWidth, canvas.clientHeight, false);
await renderer.init();
const backend = renderer.backend.isWebGPUBackend ? 'WebGPU' : 'WebGL 2';
const scene = new THREE.Scene();
scene.background = new THREE.Color('#0d1117');
const camera = new THREE.PerspectiveCamera(50, canvas.clientWidth / canvas.clientHeight, 0.01, 100);
camera.position.set(1.6, 1.1, 2.2);
const controls = new OrbitControls(camera, canvas);
controls.enableDamping = !probing;

// Per-point attributes: position, colour, visibility
const colors = new Float32Array(N * 3);
const visible = new Float32Array(N).fill(1);
const positionAttr = new THREE.InstancedBufferAttribute(data.positions, 3);
const colorAttr = new THREE.InstancedBufferAttribute(colors, 3);
const visibleAttr = new THREE.InstancedBufferAttribute(visible, 1);
const pointSize = uniform(3);

let cloud;
if (mode === 'sprites') {
  // One Sprite drawn N times: a camera-facing quad per voicing, sized in pixels, round via its UVs
  const material = new THREE.PointsNodeMaterial({ sizeAttenuation: false, transparent: false, alphaTest: 0.5 });
  material.positionNode = instancedBufferAttribute(positionAttr);
  material.colorNode = instancedBufferAttribute(colorAttr);
  material.sizeNode = pointSize.mul(instancedBufferAttribute(visibleAttr));
  material.opacityNode = smoothstep(float(0.5), float(0.42), length(uv().sub(0.5)));
  cloud = new THREE.Sprite(material);
  cloud.count = N;
  cloud.frustumCulled = false;
} else {
  // WebGPU draws point primitives 1 pixel wide whatever the size
  const geometry = new THREE.BufferGeometry();
  geometry.setAttribute('position', new THREE.BufferAttribute(data.positions, 3));
  geometry.setAttribute('color', new THREE.BufferAttribute(colors, 3));
  const material = new THREE.PointsNodeMaterial();
  material.colorNode = attribute('color').mul(vec3(1));
  cloud = new THREE.Points(geometry, material);
}
scene.add(cloud);

// The selection: the chosen voicing and its neighbours, larger, joined by lines
const highlight = new THREE.Group();
scene.add(highlight);

function recolor() {
  const by = $('color-by').value;
  const legend = $('legend');
  legend.replaceChildren();
  const c = new THREE.Color();
  for (let i = 0; i < N; i++) {
    if (by === 'family') c.set(PALETTE[data.family[i] % PALETTE.length]);
    else if (by === 'tension') c.copy(RAMP(data.tension[i] / 8));
    else if (by === 'lowFret') c.copy(RAMP(data.lowFret[i] / 20));
    else c.copy(RAMP((data.noteCount[i] - 2) / 4));
    colors.set([c.r, c.g, c.b], i * 3);
  }
  colorAttr.needsUpdate = true;
  if (by === 'family') {
    const counts = new Array(manifest.families.length).fill(0);
    for (let i = 0; i < N; i++) counts[data.family[i]]++;
    manifest.families.forEach((f, id) => {
      const label = document.createElement('label');
      label.innerHTML = `<input type="checkbox" data-family="${id}" ${hiddenFamilies.has(id) ? '' : 'checked'}><span class="swatch" style="background:${PALETTE[id % PALETTE.length]}"></span>`;
      label.append(`${f.label} (${counts[id].toLocaleString('en')})`);
      legend.append(label);
    });
  } else {
    legend.textContent = { tension: 'blue: consonant → red: 8 or more rubs', lowFret: 'blue: open position → red: fret 20', noteCount: 'blue: 2 notes → red: 6 notes' }[by];
  }
}

const hiddenFamilies = new Set();
function refilter() {
  const maxSpan = Number($('span').value);
  const maxTension = Number($('tension').value);
  $('span-out').textContent = maxSpan;
  $('tension-out').textContent = maxTension;
  let shown = 0;
  for (let i = 0; i < N; i++) {
    const ok = !hiddenFamilies.has(data.family[i]) && data.span[i] <= maxSpan && data.tension[i] <= maxTension;
    visible[i] = ok ? 1 : 0;
    shown += ok;
  }
  visibleAttr.needsUpdate = true;
  status(`${shown.toLocaleString('en')} of ${N.toLocaleString('en')} voicings shown · ${backend}`);
}

// Picking in screen space: project every visible point, keep the closest within 8 pixels
const projected = new THREE.Vector3();
function pick(clientX, clientY) {
  const rect = canvas.getBoundingClientRect();
  const px = clientX - rect.left;
  const py = clientY - rect.top;
  const m = new THREE.Matrix4().multiplyMatrices(camera.projectionMatrix, camera.matrixWorldInverse).elements;
  let best = -1;
  let bestD = 64;
  const w = rect.width / 2;
  const h = rect.height / 2;
  const p = data.positions;
  for (let i = 0; i < N; i++) {
    if (!visible[i]) continue;
    const x = p[i * 3], y = p[i * 3 + 1], z = p[i * 3 + 2];
    const cw = m[3] * x + m[7] * y + m[11] * z + m[15];
    if (cw <= 0) continue;
    const sx = ((m[0] * x + m[4] * y + m[8] * z + m[12]) / cw + 1) * w;
    const sy = (1 - (m[1] * x + m[5] * y + m[9] * z + m[13]) / cw) * h;
    const d = (sx - px) ** 2 + (sy - py) ** 2;
    if (d < bestD) {
      bestD = d;
      best = i;
    }
  }
  return best;
}

function nameOf(i) {
  return manifest.names[data.nameId[i]];
}

function neighboursOf(i) {
  if (data.vectors) {
    // Local full-index mode: exact search over every loaded vector, in the browser
    const dim = manifest.dim;
    const t = performance.now();
    const r = knnByDot(data.vectors, dim, N, [i], 10);
    return { ids: Array.from(r.ids), scores: Array.from(r.scores), ms: performance.now() - t };
  }
  const k = data.k;
  return { ids: Array.from(data.neighbours.subarray(i * k, (i + 1) * k)), scores: Array.from(data.neighbourScores.subarray(i * k, (i + 1) * k)), ms: 0 };
}

let audio;
function play(i) {
  audio ??= new AudioContext();
  const gaFrets = Array.from(data.frets.subarray(i * 6, i * 6 + 6));
  // midiNotes follows GA's order (high E first); a strum starts on the low string
  const notes = midiNotes(gaFrets, TUNINGS.guitar).reverse();
  const samples = strum(notes, { sampleRate: audio.sampleRate });
  const buffer = audio.createBuffer(1, samples.length, audio.sampleRate);
  buffer.copyToChannel(samples, 0);
  const source = audio.createBufferSource();
  source.buffer = buffer;
  source.connect(audio.destination);
  source.start();
}

function select(i) {
  const panel = $('panel-right');
  panel.hidden = false;
  const gaFrets = Array.from(data.frets.subarray(i * 6, i * 6 + 6));
  const chart = toChartOrder(gaFrets);
  const name = nameOf(i);
  $('sel-name').textContent = name;
  $('sel-shape').textContent = `chart ${chartName(chart)} (low E first) · GA diagram ${gaFrets.map((f) => (f < 0 ? 'x' : f)).join('-')} (high E first)`;
  const ctx = $('diagram').getContext('2d');
  ctx.clearRect(0, 0, 200, 200);
  drawDiagram(ctx, chart, { scale: 1.3 });
  const notes = midiNotes(gaFrets, TUNINGS.guitar).reverse();
  const root = parseChordName(name).root;
  $('sel-notes').textContent = `notes ${notes.map((n) => NOTE_NAMES[n % 12] + (Math.floor(n / 12) - 1)).join(' ')} · span ${data.span[i]} · tension ${data.tension[i]}${root === null ? '' : ` · root ${NOTE_NAMES[root]}`}`;
  $('play').onclick = () => play(i);

  const nb = neighboursOf(i);
  const list = $('neighbours');
  list.replaceChildren();
  const p = data.positions;
  const dist3 = (j) => Math.hypot(p[i * 3] - p[j * 3], p[i * 3 + 1] - p[j * 3 + 1], p[i * 3 + 2] - p[j * 3 + 2]);
  nb.ids.forEach((j, r) => {
    const li = document.createElement('li');
    const shape = chartName(toChartOrder(Array.from(data.frets.subarray(j * 6, j * 6 + 6))));
    li.textContent = `${nameOf(j)} · ${shape} · score ${nb.scores[r].toFixed(3)} · 3D distance ${dist3(j).toFixed(2)}`;
    li.onclick = () => {
      select(j);
      play(j);
    };
    list.append(li);
  });
  $('sel-note').textContent = `Scores are GA's weighted partition cosine (at most 1.15). Lines join the voicing to its neighbours in the 3D view${nb.ms ? `; search took ${nb.ms.toFixed(1)} ms` : ''}.`;

  highlight.clear();
  const pts = [i, ...nb.ids];
  const linePositions = [];
  for (const j of nb.ids) linePositions.push(p[i * 3], p[i * 3 + 1], p[i * 3 + 2], p[j * 3], p[j * 3 + 1], p[j * 3 + 2]);
  const lines = new THREE.LineSegments(
    new THREE.BufferGeometry().setAttribute('position', new THREE.Float32BufferAttribute(linePositions, 3)),
    new THREE.LineBasicNodeMaterial({ color: '#f0b429' }),
  );
  highlight.add(lines);
  for (const [r, j] of pts.entries()) {
    const dot = new THREE.Mesh(new THREE.SphereGeometry(r === 0 ? 0.018 : 0.012, 12, 8), new THREE.MeshBasicNodeMaterial({ color: r === 0 ? '#ffffff' : '#f0b429' }));
    dot.position.fromArray(p, j * 3);
    highlight.add(dot);
  }
}

// Events
$('color-by').onchange = recolor;
$('legend').onchange = (e) => {
  const id = Number(e.target.dataset.family);
  if (e.target.checked) hiddenFamilies.delete(id);
  else hiddenFamilies.add(id);
  refilter();
};
$('span').oninput = refilter;
$('tension').oninput = refilter;
$('size').oninput = () => {
  pointSize.value = Number($('size').value);
  $('size-out').textContent = $('size').value;
};
const tooltip = $('tooltip');
let lastMove = 0;
canvas.addEventListener('pointermove', (e) => {
  const now = performance.now();
  if (now - lastMove < 40 || N === 0 || !data.nameId) return;
  lastMove = now;
  const i = pick(e.clientX, e.clientY);
  tooltip.hidden = i < 0;
  if (i >= 0) {
    tooltip.textContent = `${nameOf(i)} · ${chartName(toChartOrder(Array.from(data.frets.subarray(i * 6, i * 6 + 6))))}`;
    tooltip.style.left = `${e.offsetX + 12}px`;
    tooltip.style.top = `${e.offsetY + 12}px`;
  }
});
let down;
canvas.addEventListener('pointerdown', (e) => (down = [e.clientX, e.clientY]));
canvas.addEventListener('pointerup', (e) => {
  if (!down || Math.hypot(e.clientX - down[0], e.clientY - down[1]) > 4 || !data.nameId) return;
  const i = pick(e.clientX, e.clientY);
  if (i >= 0) {
    select(i);
    play(i);
  }
});
addEventListener('resize', () => {
  renderer.setSize(canvas.clientWidth, canvas.clientHeight, false);
  camera.aspect = canvas.clientWidth / canvas.clientHeight;
  camera.updateProjectionMatrix();
});

recolor();
refilter();
// ?select=<i> opens the panel on voicing i without playing it (screenshots)
if (params.has('select') && data.nameId) select(Number(params.get('select')));

if (probing) {
  await measure();
} else {
  renderer.setAnimationLoop(() => {
    controls.update();
    renderer.render(scene, camera);
  });
}

// Frame time: each frame is rendered, then waited for until the GPU has finished it (WebGPU: onSubmittedWorkDone;
// WebGL 2: a 1-pixel readPixels, which blocks until the queue is drained). Vsync plays no part: nothing is presented in between.
async function measure() {
  const frames = Number(params.get('frames') ?? 120);
  const waitGpu = async () => {
    if (renderer.backend.isWebGPUBackend) await renderer.backend.device.queue.onSubmittedWorkDone();
    else {
      const gl = renderer.backend.gl;
      gl.readPixels(0, 0, 1, 1, gl.RGBA, gl.UNSIGNED_BYTE, new Uint8Array(4));
    }
  };
  let t = performance.now();
  renderer.render(scene, camera);
  await waitGpu();
  const firstFrameMs = performance.now() - t;
  for (let i = 0; i < 10; i++) {
    renderer.render(scene, camera);
    await waitGpu();
  }
  // wall: render() plus the wait for the GPU; cpu: render() alone; gpu: the render pass measured by timestamp queries
  // (WebGPU timestamp-query, WebGL EXT_disjoint_timer_query_webgl2), undefined where the browser doesn't expose them
  const times = [];
  const cpuTimes = [];
  const gpuTimes = [];
  for (let i = 0; i < frames; i++) {
    camera.position.applyAxisAngle(new THREE.Vector3(0, 1, 0), 0.01);
    camera.lookAt(0, 0, 0);
    t = performance.now();
    renderer.render(scene, camera);
    cpuTimes.push(performance.now() - t);
    await waitGpu();
    times.push(performance.now() - t);
    const gpu = await renderer.resolveTimestampsAsync('render');
    if (typeof gpu === 'number' && gpu > 0) gpuTimes.push(gpu);
  }
  const median = (xs) => (xs.length ? +[...xs].sort((a, b) => a - b)[Math.floor(xs.length / 2)].toFixed(3) : null);
  times.sort((a, b) => a - b);
  const pickTimes = [];
  for (let i = 0; i < 20; i++) {
    t = performance.now();
    pick(canvas.clientWidth / 2 + i, canvas.clientHeight / 2);
    pickTimes.push(performance.now() - t);
  }
  pickTimes.sort((a, b) => a - b);
  const knn = data.vectors ? neighboursOf(0).ms : null;
  const adapter = renderer.backend.device?.adapterInfo;
  const gl = renderer.backend.gl;
  const debug = gl?.getExtension('WEBGL_debug_renderer_info');
  resolveProbe({
    backend,
    gpu: adapter ? [adapter.vendor, adapter.architecture, adapter.description].filter(Boolean).join(', ') : debug ? String(gl.getParameter(debug.UNMASKED_RENDERER_WEBGL)) : 'n/a',
    mode,
    points: N,
    viewport: [canvas.width, canvas.height],
    dataBytes: data.bytes,
    loadMs: +data.loadMs.toFixed(1),
    firstFrameMs: +firstFrameMs.toFixed(1),
    frameMsMedian: +times[Math.floor(frames / 2)].toFixed(3),
    frameMsP95: +times[Math.floor(frames * 0.95)].toFixed(3),
    cpuRenderMsMedian: median(cpuTimes),
    gpuPassMsMedian: median(gpuTimes),
    gpuSamples: gpuTimes.length,
    pickMsMedian: +pickTimes[10].toFixed(3),
    knnInBrowserMs: knn === null ? null : +knn.toFixed(1),
    jsHeapMB: performance.memory ? +(performance.memory.usedJSHeapSize / 2 ** 20).toFixed(1) : null,
  });
}
