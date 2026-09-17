// P2, "Play a chord, see the universe": wires the audio sources, the DSP shared with the Node.js evaluation, GA's
// harmony rules and the three.js scene.
//
// Query parameters: ?webgl forces the WebGL 2 backend; ?source=demo or ?source=mic starts a source on load (for the
// headless Chromium measurement, which grants the fake microphone and allows autoplay). window.__p2 exposes what the
// page detected, for that measurement.
import { chordName, pitchClasses, type Chord } from '../dsp/chords.ts';
import { ChromaExtractor, defaultChromaOptions } from '../dsp/chroma.ts';
import { estimateKey, keyName, suggestNext } from '../dsp/harmony.ts';
import { ChordTracker } from '../dsp/tracker.ts';
import { tab, voicings } from '../dsp/voicings.ts';
import { AudioEngine, FRAME } from './audio.ts';
import { Universe } from './scene.ts';
import { NOTE_NAMES } from '../dsp/chords.ts';

type Probe = {
  backend: string;
  sampleRate: number;
  frames: number;
  computeMs: number[];
  labels: { t: number; name: string; confidence: number }[];
  error?: string;
};
const probe: Probe = { backend: '', sampleRate: 0, frames: 0, computeMs: [], labels: [] };
(window as unknown as { __p2: Probe }).__p2 = probe;

const $ = <T extends HTMLElement>(id: string) => document.getElementById(id) as T;
const params = new URLSearchParams(location.search);
const universe = new Universe($<HTMLCanvasElement>('scene'), params.has('webgl'));

// Chroma bars
const bars = Array.from({ length: 12 }, (_, pc) => {
  const bar = document.createElement('div');
  bar.innerHTML = `<span>${NOTE_NAMES[pc]}</span>`;
  $('chroma').append(bar);
  return bar;
});

let extractor: ChromaExtractor | null = null;
let tracker = new ChordTracker();
let history: Chord[] = [];
let current: Chord | null = null;
let started = 0;

function onFrame(samples: Float32Array, sampleRate: number) {
  if (!extractor || extractor.options.sampleRate !== sampleRate) {
    extractor = new ChromaExtractor(defaultChromaOptions(sampleRate));
    tracker = new ChordTracker();
    probe.sampleRate = sampleRate;
  }
  const t0 = performance.now();
  const state = tracker.push(extractor.process(samples, 0));
  const elapsed = performance.now() - t0;
  probe.frames++;
  if (probe.computeMs.length < 5000) probe.computeMs.push(elapsed);

  let max = 0;
  for (const v of state.chroma) max = Math.max(max, v);
  bars.forEach((bar, pc) => (bar.style.height = `${max > 0 ? (100 * state.chroma[pc]) / max : 0}%`));
  universe.setChroma(state.chroma);

  const top = state.top;
  $('top3').innerHTML = top.map((c) => `<li>${c.name} <small>${(100 * c.probability).toFixed(0)} %</small></li>`).join('');
  const stable = state.stable;
  if (!stable) {
    $('confidence-bar').style.width = '0';
    return;
  }
  $('confidence-bar').style.width = `${Math.round(100 * stable.probability)}%`;
  if (current && chordName(current) === stable.name) return;

  // A new chord
  const previous = current;
  current = stable.chord;
  probe.labels.push({ t: Math.round(performance.now() - started), name: stable.name, confidence: Math.round(stable.probability * 100) / 100 });
  $('chord').textContent = stable.name;
  history = [...history, stable.chord].slice(-8);
  const key = estimateKey(history)!.key;
  $('key').textContent = keyName(key);
  $('next').innerHTML = suggestNext(stable.chord, key)
    .map((s) => `<li><strong>${s.name}</strong> <small>${s.reason}</small></li>`)
    .join('');
  const list = voicings(stable.chord);
  universe.setVoicings(list, stable.chord.root);
  const interval = previous ? (stable.chord.root - previous.root + 12) % 12 : null;
  universe.setPitchClasses(pitchClasses(stable.chord), interval);
  const common = previous ? pitchClasses(previous).filter((pc) => pitchClasses(stable.chord).includes(pc)).length : 0;
  $('status').textContent = previous
    ? `${chordName(previous)} to ${stable.name}: transposition by ${interval} semitone${interval === 1 ? '' : 's'}, ${common} common tone${common === 1 ? '' : 's'}. Shown: ${list.slice(0, 3).map(tab).join(', ')}`
    : `Shown: ${list.slice(0, 3).map(tab).join(', ')}`;
}

const engine = new AudioEngine(onFrame);
engine.onEnded = () => setRunning(false, 'Finished. Choose a source.');

function setRunning(running: boolean, message: string) {
  $<HTMLButtonElement>('stop').disabled = !running;
  $('status').textContent = message;
}

function reset() {
  extractor = null;
  history = [];
  current = null;
  started = performance.now();
}

async function start(kind: 'demo' | 'mic' | 'file', file?: File) {
  reset();
  try {
    if (kind === 'demo') {
      const seconds = await engine.startDemo();
      setRunning(true, `Demo: 16 synthesized chords, ${seconds.toFixed(0)} s.`);
    } else if (kind === 'mic') {
      setRunning(false, 'Asking for the microphone. The audio stays in this page.');
      await engine.startMicrophone();
      setRunning(true, 'Listening on this device only. Strum a chord and let it ring.');
    } else if (file) {
      const seconds = await engine.startFile(file);
      setRunning(true, `Playing ${file.name} (${seconds.toFixed(0)} s), analyzed locally.`);
    }
  } catch (error) {
    probe.error = String(error);
    setRunning(false, `Could not start: ${error instanceof Error ? error.message : String(error)}`);
    // Inside an iframe without allow="microphone", the browser refuses the microphone: offer the page on its own
    if (kind === 'mic' && window.self !== window.top) {
      const link = document.createElement('a');
      link.href = location.href.split('?')[0];
      link.target = '_blank';
      link.rel = 'noopener';
      link.textContent = ' Open the app in its own tab to use the microphone.';
      $('status').append(link);
    }
  }
}

$('demo').addEventListener('click', () => void start('demo'));
$('mic').addEventListener('click', () => void start('mic'));
$<HTMLInputElement>('file').addEventListener('change', (event) => {
  const file = (event.target as HTMLInputElement).files?.[0];
  if (file) void start('file', file);
});
$('stop').addEventListener('click', () => void engine.stop().then(() => setRunning(false, 'Stopped.')));
if (!navigator.mediaDevices?.getUserMedia) {
  $<HTMLButtonElement>('mic').disabled = true;
  $('status').textContent = 'No microphone access here: it needs HTTPS (or localhost). The demo and files still work.';
}

const backend = await universe.init();
probe.backend = backend;
$('backend').textContent = `Renderer: ${backend}. Frames of ${FRAME} samples. Chord qualities from Guitar Alchemist.`;
const resize = () => universe.resize(innerWidth, innerHeight);
addEventListener('resize', resize);
resize();
universe.renderer.setAnimationLoop((now) => universe.render(now));

const auto = params.get('source');
if (auto === 'demo' || auto === 'mic') void start(auto);
