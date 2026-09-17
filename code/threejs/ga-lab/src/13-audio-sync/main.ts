// Experiment 13: a note played with WebAudio and the string's vibration drawn on screen: when does each happen?
// ?notes=20 plucks, one every 250 ms, each in a requestAnimationFrame callback, as a click handler followed by a frame.
// The oscillators play at a gain of 0: the output device is opened and its latency reported, but nothing is heard.
// For each pluck, with the AudioContext's own clock mapping (getOutputTimestamp: the context time that was audible at a
// given performance.now() time):
// - audibleAt: when the note, started at currentTime, reaches the output, in performance.now() milliseconds;
// - naive: the vibration starts on the next frame; lead = audibleAt − that frame's time;
// - compensated: the vibration starts on the first frame at or after audibleAt − half a frame; lead = audibleAt − its time.
// A positive lead means the picture moves before the sound is heard. Presentation to the display adds its own delay,
// which the page can't see, and the acoustic path (speakers, air) isn't measured.
import { finish, num, summarize } from '../lab.ts';

const notes = num('notes', 20);
const frame = () => new Promise<number>((resolve) => requestAnimationFrame(resolve));

async function main() {
  const canvas = document.createElement('canvas');
  canvas.width = 640;
  canvas.height = 160;
  document.body.append(canvas);
  const g = canvas.getContext('2d')!;
  let vibrationStart = -1;
  const draw = (time: number) => {
    g.fillStyle = '#1e2127';
    g.fillRect(0, 0, 640, 160);
    g.strokeStyle = '#d0c8b8';
    g.lineWidth = 2;
    g.beginPath();
    const age = vibrationStart < 0 ? 1e9 : (time - vibrationStart) / 1000;
    for (let x = 0; x <= 640; x += 4) {
      const offset = age >= 0 && age < 5 ? 30 * Math.sin((Math.PI * x) / 640) * Math.cos(2 * Math.PI * 6 * age) * Math.exp(-3 * age) : 0;
      g.lineTo(x, 80 + offset);
    }
    g.stroke();
  };

  const context = new AudioContext({ latencyHint: 'interactive' });
  if (context.state !== 'running') await context.resume().catch(() => undefined);
  const silent = context.createGain();
  silent.gain.value = 0;
  silent.connect(context.destination);
  // Let the output settle: getOutputTimestamp is 0 until the device has played something
  const warm = context.createOscillator();
  warm.connect(silent);
  warm.start();
  // Until the output clock has run for half a second, or 3 seconds at most
  const settle = performance.now() + 3000;
  while ((context.getOutputTimestamp().contextTime ?? 0) < 0.5 && performance.now() < settle) draw(await frame());
  for (let i = 0; i < 30; i++) draw(await frame());
  warm.stop();

  const naive: number[] = [];
  const compensated: number[] = [];
  const frameMs: number[] = [];
  let last = await frame();
  for (let n = 0; n < notes; n++) {
    // The click: a frame callback starts the note now
    const clickFrame = await frame();
    frameMs.push(clickFrame - last);
    const osc = context.createOscillator();
    osc.frequency.value = 110 * 2 ** (n / 12);
    osc.connect(silent);
    const startContextTime = context.currentTime;
    osc.start(startContextTime);
    osc.stop(startContextTime + 0.2);
    const stamp = context.getOutputTimestamp();
    const audibleAt = (stamp.performanceTime ?? 0) + (startContextTime - (stamp.contextTime ?? 0)) * 1000;
    // Naive: the vibration shows on the next frame
    const next = await frame();
    vibrationStart = next;
    draw(next);
    naive.push(audibleAt - next);
    // Compensated: wait for the frame closest to the audible time
    let t = next;
    const half = (next - clickFrame) / 2;
    while (t < audibleAt - half) t = await frame();
    vibrationStart = t;
    draw(t);
    compensated.push(audibleAt - t);
    // 250 ms between plucks
    const until = clickFrame + 250;
    while (t < until) {
      t = await frame();
      draw(t);
    }
    last = t;
  }
  finish(null, {
    audio: {
      sampleRate: context.sampleRate,
      state: context.state,
      baseLatencyMs: Math.round(context.baseLatency * 100000) / 100,
      outputLatencyMs: Math.round((context.outputLatency ?? 0) * 100000) / 100,
    },
    frameMs: summarize(frameMs),
    naiveLeadMs: summarize(naive),
    compensatedLeadMs: summarize(compensated),
    counters: { notes },
  });
  await context.close();
}

main().catch((error: Error) => finish(null, { error: `${error.name}: ${error.message}` }));
