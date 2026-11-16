import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const [outputArgument, referenceArgument] = process.argv.slice(2);
assert(outputArgument && referenceArgument, 'Supply a NEW output directory and the recorded reference WAV path.');
const output = resolve(outputArgument);
const referencePath = resolve(referenceArgument);
const source = dirname(fileURLToPath(import.meta.url));
const rate = 44100;
const frames = 176400;
const probeFrames = 4096;
const hash = data => createHash('sha256').update(data).digest('hex');
const referenceBytes = readFileSync(referencePath);
assert.equal(hash(referenceBytes), '03a1965f275f0858be70476dab2bf55d2cbf2272ef7a50c61453d45e7f38b248');
mkdirSync(output);
const commands = [];
function execute(command, args, cwd = source) {
  commands.push({ command, args, cwd });
  return execFileSync(command, args, { cwd, encoding: 'utf8', timeout: 60000 });
}
const executable = resolve(output, process.platform === 'win32' ? 'native.exe' : 'native');
const wasmPath = resolve(output, 'engine.wasm');
execute('rustc', ['--edition=2021', '-D', 'warnings', '-O', 'native.rs', '-o', executable]);
execute('rustc', ['--edition=2021', '--crate-type=cdylib', '--target', 'wasm32-unknown-unknown', '-C', 'panic=abort', '-O', 'vendor/lib.rs', '-o', wasmPath]);
const wasmBytes = readFileSync(wasmPath);
const module = await WebAssembly.compile(wasmBytes);
assert.deepEqual(WebAssembly.Module.imports(module), []);

function renderNative(mode, count, block, name) {
  const path = resolve(output, name + '.f32le');
  execute(executable, [String(count), String(block), mode, path]);
  return readFileSync(path);
}
async function renderWasm(mode, count, block) {
  const instance = await WebAssembly.instantiate(module, {});
  const api = instance.exports;
  const engine = api.engine_init(rate);
  assert.notEqual(engine, 0);
  if (mode === 'candidate') api.engine_set_decay(engine, 0.9976);
  if (mode !== 'silence') api.engine_note_on(engine, 82.4069, 0.1);
  const pointer = api.alloc_buffer(block);
  assert.notEqual(pointer, 0);
  const bytes = Buffer.alloc(count * 4);
  for (let at = 0; at < count; at += block) {
    const length = Math.min(block, count - at);
    api.engine_render(engine, pointer, length);
    const view = new Float32Array(api.memory.buffer, pointer, length);
    for (let i = 0; i < length; i++) bytes.writeFloatLE(view[i], (at + i) * 4);
  }
  return bytes;
}
function pcmGuard(bytes, count) {
  assert.equal(bytes.length, count * 4, 'Unexpected f32 sample count');
  let peak = 0;
  for (let at = 0; at < bytes.length; at += 4) {
    const sample = bytes.readFloatLE(at);
    assert(Number.isFinite(sample), 'Nonfinite sample');
    assert(Math.abs(sample) <= 1, 'Sample outside normalized PCM range');
    peak = Math.max(peak, Math.abs(sample));
  }
  return peak;
}
function pcm16Wav(bytes) {
  const payload = Buffer.alloc(bytes.length / 2);
  for (let at = 0; at < bytes.length / 4; at++) payload.writeInt16LE(Math.round(bytes.readFloatLE(at * 4) * 32767), at * 2);
  const header = Buffer.alloc(44);
  header.write('RIFF', 0); header.writeUInt32LE(payload.length + 36, 4); header.write('WAVEfmt ', 8);
  header.writeUInt32LE(16, 16); header.writeUInt16LE(1, 20); header.writeUInt16LE(1, 22);
  header.writeUInt32LE(rate, 24); header.writeUInt32LE(rate * 2, 28); header.writeUInt16LE(2, 32); header.writeUInt16LE(16, 34);
  header.write('data', 36); header.writeUInt32LE(payload.length, 40);
  return Buffer.concat([header, payload]);
}
function decodeWav(bytes) {
  assert.equal(bytes.toString('ascii', 0, 4), 'RIFF');
  assert.equal(bytes.toString('ascii', 8, 12), 'WAVE');
  let format, payload;
  for (let at = 12; at + 8 <= bytes.length;) {
    const name = bytes.toString('ascii', at, at + 4), length = bytes.readUInt32LE(at + 4);
    assert(at + 8 + length <= bytes.length, 'Truncated WAV chunk');
    if (name === 'fmt ') format = bytes.subarray(at + 8, at + 8 + length);
    if (name === 'data') payload = bytes.subarray(at + 8, at + 8 + length);
    at += 8 + length + (length % 2);
  }
  assert(format && payload, 'Missing WAV format or data');
  const encoding = format.readUInt16LE(0), bits = format.readUInt16LE(14);
  assert.equal(format.readUInt16LE(2), 1); assert.equal(format.readUInt32LE(4), rate);
  if (encoding === 1 && bits === 16) {
    assert.equal(payload.length % 2, 0);
    return Array.from({ length: payload.length / 2 }, (_, i) => payload.readInt16LE(i * 2) / 32767);
  }
  assert(encoding === 3 && bits === 32, 'Expected PCM16 or IEEE float32 WAV');
  assert.equal(payload.length % 4, 0);
  const samples = Array.from({ length: payload.length / 4 }, (_, i) => payload.readFloatLE(i * 4));
  assert(samples.every(Number.isFinite), 'Nonfinite WAV input');
  return samples;
}
function rmsDb(samples, start, end) {
  const first = Math.round(start * rate), last = Math.round(end * rate);
  assert(last <= samples.length && last > first);
  let sum = 0;
  for (let i = first; i < last; i++) sum += samples[i] ** 2;
  return 20 * Math.log10(Math.sqrt(sum / (last - first)) + 1e-12);
}
function decline(samples, onset) { return rmsDb(samples, onset + 1, onset + 1.2) - rmsDb(samples, onset + 0.2, onset + 0.4); }

const referenceDecline = decline(decodeWav(referenceBytes), 1.1);
const observations = {};
for (const mode of ['baseline', 'candidate']) {
  const native = renderNative(mode, frames, frames, 'native-' + mode);
  const wasm = await renderWasm(mode, frames, 128);
  writeFileSync(resolve(output, 'wasm-' + mode + '.f32le'), wasm);
  const nativePeak = pcmGuard(native, frames), wasmPeak = pcmGuard(wasm, frames);
  let differingSamples = 0, maximumDifference = 0;
  for (let at = 0; at < native.length; at += 4) {
    const difference = Math.abs(native.readFloatLE(at) - wasm.readFloatLE(at));
    if (difference !== 0) differingSamples++;
    maximumDifference = Math.max(maximumDifference, difference);
  }
  const oneBlock = renderNative(mode, probeFrames, probeFrames, 'native-' + mode + '-probe');
  const chunked = renderNative(mode, probeFrames, 128, 'native-' + mode + '-chunked');
  assert.deepEqual(oneBlock, chunked, 'Native block partition changed samples');
  assert.deepEqual(oneBlock, native.subarray(0, probeFrames * 4), 'Fresh native prefix differs');
  const wasmOne = await renderWasm(mode, probeFrames, probeFrames);
  const wasmChunked = await renderWasm(mode, probeFrames, 128);
  assert.deepEqual(wasmOne, wasmChunked, 'WASM block partition changed samples');
  assert.deepEqual(wasmOne, wasm.subarray(0, probeFrames * 4), 'Fresh WASM prefix differs');
  const wav = pcm16Wav(native);
  const wasmWav = pcm16Wav(wasm);
  writeFileSync(resolve(output, mode + '.wav'), wav);
  const measuredDecline = decline(decodeWav(wav), 0);
  observations[mode] = { native_f32le_sha256: hash(native), wasm_f32le_sha256: hash(wasm), wav_sha256: hash(wav), wasm_pcm16_wav_sha256: hash(wasmWav), native_wasm_pcm16_wav_bytes_equal: wav.equals(wasmWav), samples: frames, native_peak_abs: nativePeak, wasm_peak_abs: wasmPeak, differing_native_wasm_samples: differingSamples, maximum_abs_native_wasm_difference: maximumDifference, native_and_wasm_bit_exact: native.equals(wasm), fresh_native_prefix_equal: true, native_block_partition_equal: true, fresh_wasm_prefix_equal: true, wasm_block_partition_equal: true, decoded_pcm16_decline_db: measuredDecline, absolute_reference_decline_error_db: Math.abs(measuredDecline - referenceDecline) };
}
assert.notEqual(observations.baseline.native_f32le_sha256, observations.candidate.native_f32le_sha256, 'Native candidate intervention had no sample effect');
assert.notEqual(observations.baseline.wasm_f32le_sha256, observations.candidate.wasm_f32le_sha256, 'WASM candidate intervention had no sample effect');
const silenceNative = renderNative('silence', probeFrames, 128, 'native-silence');
const silenceWasm = await renderWasm('silence', probeFrames, 128);
assert.equal(pcmGuard(silenceNative, probeFrames), 0); assert.equal(pcmGuard(silenceWasm, probeFrames), 0);
const nan = Buffer.alloc(4); nan.writeFloatLE(Number.NaN);
const tooLoud = Buffer.alloc(4); tooLoud.writeFloatLE(1.01);
assert.throws(() => pcmGuard(nan, 1), /Nonfinite sample/);
assert.throws(() => pcmGuard(tooLoud, 1), /outside normalized PCM range/);
assert.throws(() => pcmGuard(Buffer.alloc(3), 1), /Unexpected f32 sample count/);
const improvement = observations.baseline.absolute_reference_decline_error_db - observations.candidate.absolute_reference_decline_error_db;
const results = { scope: 'Pinned GA Rust module, native and Node WebAssembly, offline fixed E2; no AudioWorklet/browser capture or listening result.', source_commit: 'dc2e74cbd992a298f67efb928b5b3754615e1924', node: process.version, platform: process.platform, arch: process.arch, rustc: execFileSync('rustc', ['-vV'], { encoding: 'utf8' }).trim(), commands, sample_rate: rate, frames, probe_frames: probeFrames, frequency_hz_requested: 82.4069, velocity_requested: 0.1, reference_sha256: hash(referenceBytes), reference_decline_db: referenceDecline, observations, candidate_decline_error_improvement_db: improvement, required_improvement_db_from_GAS003: 1, candidate_passes_decline_gate: improvement >= 1, native_and_wasm_silence_peak: 0, pcm_guard_negative_controls_detected: 3, wasm_binary_sha256: hash(wasmBytes), wasm_imports: WebAssembly.Module.imports(module), wasm_exports: WebAssembly.Module.exports(module), limits: ['Comparison is one fixed E2 velocity and profile, one toolchain and OS.', 'PCM16 conversion uses JavaScript Math.round; raw f32 outputs are separately hashed.', 'No listening, pitch, partial-track, attack-preservation or whole-product acceptance claim.', 'No performance, cancellation, memory-lifetime or browser AudioWorklet certification.'] };
writeFileSync(resolve(output, 'results.json'), JSON.stringify(results, null, 2) + '\n');
console.log(JSON.stringify({ output, candidate_decline_error_improvement_db: improvement, candidate_passes_decline_gate: results.candidate_passes_decline_gate, observations }, null, 2));
