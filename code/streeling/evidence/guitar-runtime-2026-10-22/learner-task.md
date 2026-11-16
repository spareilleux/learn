# Guitar runtime source-assisted learner task

Prepared only. No learner identity, attempt, score, elapsed time or verdict is recorded. These tasks overlap course material and permit primary-source reading; they do not measure independent transfer or causal learning. Attempt them before opening the course answers, runner or reviewer rubric.

## Primary inputs

Use the unchanged [GA engine](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Rust/guitar-web-wasm-demo/rust-engine/src/lib.rs), its [worklet adapter](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Rust/guitar-web-wasm-demo/src/audio/guitar-worklet.js), and the [GAS003 candidate protocol](https://github.com/spareilleux/learn/blob/1216cc8cce1f87085f2c00fc8f6cb7de7e098221/streeling/courses/guitar-acoustics/en/gas-003-decay-calibration-open-e.md). The [pinned measurement method and input attribution](https://github.com/GuitarAlchemist/Demerzel/blob/5c4967454ddc740ed937c87719ca4d71a3522e4b/state/streeling/fixtures/guitar-acoustics/gas-001/README.md) describe approximate recorded onset1.1s and another attack2.75s. The recorded input is credited to collegefishiesd, CC BY-SA4.0, and is not copied into this tranche.

## GAS004: test a declared candidate

Both fresh engines use profile0,44100Hz,E2 frequency82.4069,velocity0.1 and4seconds. Baseline retains base decay0.9978; candidate applies0.9976 after initialization and before the note. The criterion established by GAS003 is at least1dB smaller absolute error in late-minus-early RMS change against the recorded reference. Use the same onset-relative windows0.2–0.4s and1.0–1.2s.

For this task, use runner values: reference decline -3.922115130444098dB, baseline -1.0848117418372532dB, candidate -1.198977891431639dB. Native raw peaks are0.4601604640483856 and0.46006888151168823; the illustrative peak margin is below0.95. The historical baseline WAV SHA256 and regenerated native baseline WAV SHA256 are identical. These are supplied observations for reasoning, not a learner verdict.

1. Compute both absolute errors and the improvement, then apply the previously declared criterion.
2. Explain why a successful program exit is different from the candidate meeting that criterion.
3. Identify what a fresh engine and fixed call order control, and what reference-recording differences remain uncontrolled.
4. Explain why matching the baseline WAV hash supports a bounded reproduction claim rather than subjective quality.
5. State a justified next experiment and a claim this single-E2 result cannot establish.

## CS012: compare execution boundaries

The same pinned module is compiled with `rustc -O` for native and wasm32-unknown-unknown. Full renders contain176400 samples. Native uses one block; Node WebAssembly uses128-sample blocks. Separate4096-sample probes use one block or128-sample partitions with no intervening event. Within each runtime those probe bytes and fresh prefixes match. Across runtimes,2918 baseline samples and2926 candidate samples differ as raw f32 values, maximum absolute difference2.9802322387695312e-8. Each arm's native and WASM PCM16 WAV bytes match after the same rounding conversion.

1. Distinguish within-runtime block/prefix checks from cross-runtime raw-byte equality.
2. Decide whether identical PCM16 bytes prove identical original float samples, using the supplied observations.
3. Explain which build flags and toolchain/OS facts must accompany a reproducibility claim.
4. State what execution of a module in Node cannot establish about the browser AudioWorklet/device path.
5. Propose a falsifier for a broad deterministic-output claim without selecting a product tolerance after seeing results.

## AUD005: validate format and samples

A reference WAV has encoding tag3 with32bits per sample. Generated native WAVs use tag1,16bits,mono,44100Hz,176400 samples and a44-byte header. Raw synth values are f32,4bytes per sample. The decoder handles these two declared formats; integer PCM16 samples are divided by32767, and output conversion uses `Math.round(sample *32767)`. Guard stimuli are one NaN sample, one finite sample1.01 and a3-byte buffer declared as one f32. An unexcited4096-sample native/WASM probe has peak0. Candidate JSON reports a failed decline criterion even when the runner exits0.

1. Calculate raw f32 byte length and generated PCM16 WAV byte length.
2. Explain why the decoder must inspect format before interpreting a WAV payload.
3. Identify the independent guard each supplied invalid stimulus should trigger, before output encoding.
4. Explain what finite, bounded, nonclipping samples and the silence result do not establish about sound quality or the complete audio host.
5. Interpret the successful execution and failed candidate decision separately, naming the evidence still needed before release.

## Record actual attempts

A learner records predictions, cited source locations, uncertainty and elapsed time. A reviewer compares them with the separate rubric and records actual outcomes. All current identity/time/score/verdict fields remain null. Human subject and fluent-language review, source integration, deployment and public course readback remain separate claims.
