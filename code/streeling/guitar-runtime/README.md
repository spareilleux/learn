# Native and WebAssembly guitar teaching lab

The lab compiles the unchanged GA engine at `dc2e74cbd992a298f67efb928b5b3754615e1924` twice: a native adapter and a `wasm32-unknown-unknown` module run by Node. `source.json` pins vendor bytes and the MIT notice. It uses `rustc -O`, not the upstream Cargo release profile (`opt-level="z"`, LTO). Neither binary is presented as the deployed browser artifact.

## Reproduce

Required tools: [Rust](https://doc.rust-lang.org/rustc/command-line-arguments.html), an installed [wasm32-unknown-unknown target](https://doc.rust-lang.org/rustc/platform-support/wasm32-unknown-unknown.html), and [Node.js with WebAssembly](https://nodejs.org/en/learn/getting-started/nodejs-with-webassembly). The author used Rust `1.94.0` and Node `v24.12.0` on Windows x64. Linux/WSL and macOS remain to verify. The runner chooses the executable suffix and uses argument arrays; command spelling is the same across these systems.

Download the unmodified recorded reference linked in `source.json` to a local path and check its SHA256 there. Credit: **collegefishiesd**, dataset `collegefishiesd/guitar-fretboard-notes`, revision `a33a26243e88e7ccd4893bee30eac3219ec8bef8`, test row39. The recorded WAV is [CC BY-SA4.0](https://creativecommons.org/licenses/by-sa/4.0/), as documented in the [pinned fixture attribution](https://github.com/GuitarAlchemist/Demerzel/blob/5c4967454ddc740ed937c87719ca4d71a3522e4b/state/streeling/fixtures/guitar-acoustics/gas-001/README.md). It is not recopied into this lab. It uses IEEE float32 WAV encoding; the generated native files use PCM16.

From the Learn repository root, supply an output directory that does not yet exist and the recorded reference path:

```text
node code/streeling/guitar-runtime/run.mjs <new-output-directory> <recorded-wav-path>
```

Replace both placeholders; they are not literal arguments. No dependency install or network call occurs in the runner. It invokes the installed compiler, writes artifacts into the new output directory, and records actual commands/toolchain in `results.json`. A failed run can retain its output directory; investigate and use a different new directory afterwards. Read the separate learner packet before the runner, which includes expectations.

## Protocol and boundaries

Each arm starts a fresh profile0 engine at44100 Hz, E2 frequency82.4069 and velocity0.1. Baseline keeps default decay0.9978; candidate applies0.9976 after initialization and before the note. Main renders have176400 samples. Native uses one block; Node WASM uses128-sample blocks. Fresh4096-sample probes compare one block with128-sample partitions within each runtime, with no event between blocks. Both silence paths and three PCM guard negative controls are checked.

Raw little-endian f32 hashes and maximum native/WASM differences are retained separately from PCM16 WAV hashes. Conversion uses JavaScript `Math.round(sample *32767)`; decoding distinguishes integer PCM16 from IEEE float32. RMS windows match the prior GAS001 method. Exit0 means execution/assertions succeeded even when the candidate fails the1dB decline-improvement criterion; inspect `candidate_passes_decline_gate` in JSON.

The native adapter frees only the allocation made by this exact source's `Box::into_raw`; it does not invent an exported WASM free API. Each WASM case uses a fresh short-lived instance. The experiment does not certify long-running memory lifecycle, browser AudioWorklet behavior, scheduling deadlines, all frequencies/velocities, listening quality or a release.
