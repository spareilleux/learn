// Audio sources, all processed in this page. The microphone stream, a decoded file or the synthesized demo goes through
// an AnalyserNode, and a timer copies its last 8192 samples every hop (2048 samples) for the DSP. Nothing leaves the
// browser: no fetch, no WebSocket, no MediaRecorder upload. The microphone is not connected to the speakers, so there
// is no feedback; the file and the demo are, so you hear what is analyzed.
import { DEMO, DEMO_SECONDS_PER_CHORD } from './demo.ts';
import { strum } from '../dsp/synth.ts';
import { voicings } from '../dsp/voicings.ts';

export const FRAME = 8192;
export const HOP = 2048;

export type FrameListener = (samples: Float32Array, sampleRate: number) => void;


export class AudioEngine {
  private context: AudioContext | null = null;
  private source: AudioNode | null = null;
  private stream: MediaStream | null = null;
  private timer = 0;
  private readonly buffer = new Float32Array(FRAME);
  /** Called when a file or the demo reaches its end */
  onEnded: (() => void) | null = null;

  private readonly listener: FrameListener;

  constructor(listener: FrameListener) {
    this.listener = listener;
  }

  private async open(): Promise<{ context: AudioContext; analyser: AnalyserNode }> {
    await this.stop();
    const context = new AudioContext();
    await context.resume();
    const analyser = context.createAnalyser();
    analyser.fftSize = FRAME;
    analyser.smoothingTimeConstant = 0;
    this.context = context;
    const hopMs = (HOP / context.sampleRate) * 1000;
    this.timer = window.setInterval(() => {
      analyser.getFloatTimeDomainData(this.buffer);
      this.listener(this.buffer, context.sampleRate);
    }, hopMs);
    return { context, analyser };
  }

  async startMicrophone(): Promise<void> {
    // Raw signal: browsers' voice processing (echo cancellation, noise suppression, gain control) damages harmonics
    const stream = await navigator.mediaDevices.getUserMedia({ audio: { echoCancellation: false, noiseSuppression: false, autoGainControl: false } });
    const { context, analyser } = await this.open();
    this.stream = stream;
    const source = context.createMediaStreamSource(stream);
    source.connect(analyser);
    this.source = source;
  }

  async startFile(file: File): Promise<number> {
    const bytes = await file.arrayBuffer();
    const { context, analyser } = await this.open();
    const decoded = await context.decodeAudioData(bytes);
    return this.play(context, analyser, decoded);
  }

  async startDemo(): Promise<number> {
    const { context, analyser } = await this.open();
    const rate = context.sampleRate;
    const per = Math.round(rate * DEMO_SECONDS_PER_CHORD);
    const audio = context.createBuffer(1, per * DEMO.length + rate, rate);
    const data = audio.getChannelData(0);
    DEMO.forEach((chord, i) => {
      const clip = strum(voicings(chord)[0], {
        sampleRate: rate, seconds: DEMO_SECONDS_PER_CHORD, leadSeconds: 0.02, strumMs: 18, detuneCents: 0, stringDetuneCents: 3, snrDb: Infinity, seed: 100 + i,
      });
      for (let t = 0; t < clip.length; t++) data[i * per + t] += clip[t];
    });
    return this.play(context, analyser, audio);
  }

  private play(context: AudioContext, analyser: AnalyserNode, audio: AudioBuffer): number {
    const node = context.createBufferSource();
    node.buffer = audio;
    node.connect(analyser);
    analyser.connect(context.destination);
    node.onended = () => void this.stop().then(() => this.onEnded?.());
    node.start();
    this.source = node;
    return audio.duration;
  }

  async stop(): Promise<void> {
    window.clearInterval(this.timer);
    this.timer = 0;
    this.stream?.getTracks().forEach((track) => track.stop());
    this.stream = null;
    if (this.source instanceof AudioBufferSourceNode) {
      this.source.onended = null;
      try {
        this.source.stop();
      } catch {
        // already stopped
      }
    }
    this.source?.disconnect();
    this.source = null;
    const context = this.context;
    this.context = null;
    if (context && context.state !== 'closed') await context.close();
  }

  get running(): boolean {
    return this.context !== null;
  }
}
