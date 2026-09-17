// A plucked string, synthesized with the Karplus-Strong algorithm: a burst of noise goes round a delay line one period
// long, and averaging each sample with the next one damps the high partials first, as on a real string.
// The sound is computed once per note into an AudioBuffer, then played by the Web Audio API.

// Open strings, from string 0 (high E) to string 5 (low E), as MIDI note numbers
export const OPEN_STRINGS = [64, 59, 55, 50, 45, 40];

export function createPlucker() {
  let context: AudioContext | null = null;
  let output: GainNode | null = null;
  let volume = 0.5;
  const buffers = new Map<number, AudioBuffer>();

  function buffer(ctx: AudioContext, midi: number): AudioBuffer {
    const cached = buffers.get(midi);
    if (cached) return cached;
    const rate = ctx.sampleRate;
    const frequency = 440 * 2 ** ((midi - 69) / 12);
    const period = Math.round(rate / frequency);
    const seconds = 3;
    const data = new Float32Array(rate * seconds);
    // A loss per period that brings the note down by 60 dB in about 3 s, on top of the averaging's own loss
    const decay = 0.001 ** (1 / (frequency * seconds));
    let seed = midi * 7919;
    const noise = () => ((seed = (seed * 16807) % 2147483647) / 2147483647) * 2 - 1;
    for (let i = 0; i < period; i++) data[i] = noise();
    data[period] = decay * data[0];
    for (let i = period + 1; i < data.length; i++) data[i] = decay * 0.5 * (data[i - period] + data[i - period - 1]);
    const audio = ctx.createBuffer(1, data.length, rate);
    audio.copyToChannel(data, 0);
    buffers.set(midi, audio);
    return audio;
  }

  return {
    // Browsers start audio only after a user gesture: the first call must come from a click or a key
    play(midi: number, delaySeconds = 0) {
      context ??= new AudioContext();
      if (!output) {
        output = context.createGain();
        output.gain.value = volume;
        output.connect(context.destination);
      }
      if (context.state === 'suspended') void context.resume();
      const source = context.createBufferSource();
      source.buffer = buffer(context, midi);
      source.connect(output);
      source.start(context.currentTime + delaySeconds);
    },
    setVolume(value: number) {
      volume = value;
      if (output) output.gain.value = value;
    },
  };
}
