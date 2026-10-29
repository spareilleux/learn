# Guitar runtime course tranche — 2026-10-22

## Scope and status

New draft courses GAS004 (execute the prior decay candidate), CS012 (native/WASM render boundaries) and AUD005 (PCM guards and format boundaries), in English, French and Spanish. Existing GAS003 receives a narrowly scoped follow-up note while retaining its historical pre-run text. Human subject, fluent-language and learner reviews remain pending. No public course HTML readback, product release, listening result or browser AudioWorklet capture is claimed.

## Source and reproducible artifacts

`public-input-readback.json` binds unchanged public GA sources and license, the archived GAS001 measurement script/metadata, the recorded reference hash and the pre-existing GAS003 protocol at Learn1216cc8c. The original recorded input is collegefishiesd's dataset sample at revisiona33a26243e88e7ccd4893bee30eac3219ec8bef8,testrow39, credited CC BY-SA4.0 in the pinned fixture. It remains in external cache only; this tranche redistributes no recorded reference audio.

`code/streeling/guitar-runtime/` contains teaching adapters, the unchanged pinned engine and MIT notice, and reproduction instructions. Actual `rustc -O` native and wasm32 builds were run with Rust1.94.0 and Nodev24.12.0 on Windowsx64. The upstream Cargoopt-levelz/LTO profile was not applied. These are teaching binaries, not deployed application artifacts.

`execution.json` records repeat observations,3PCM guard controls and a temporary ignored-intervention mutation that correctly fails. `results.json` records full4second renders and4096sample block/prefix probes. Binary/compiler outputs and raw f32 buffers remain in external output directories; `baseline.wav` and `candidate.wav` are generated native PCM16 artifacts with recorded hashes.

The old baseline WAV hash is reproduced exactly. Cross-runtime f32 output differs in2918/2926samples, max2.9802322387695312e-8, although the two runtime outputs quantize to equal PCM16 WAV bytes per arm. This is a bounded observation, not an arbitrary floating-point tolerance or a subjective equivalence claim.

## Candidate and independent measurement

GAS003 already specified candidate0.9976 against default0.9978 and at least1dB smaller absolute reference-decline error. The observed improvement is0.11416614959438576dB: this candidate fails that criterion. Exit0 means the experiment ran successfully, not that the candidate was accepted. All other product/perceptual guards are not thereby approved.

`baseline-primary-measurements.json` exactly reproduces the complete archived GAS001 measurement JSON using its unchanged public Python script. `candidate-primary-measurements.json` measures the candidate with that same script. `primary-measurement-replay.json` records the scripts' successful exits, dependencies and unrounded RMS crosschecks against the Node calculation (differences below1e-10dB). Recorded onset1.1s remains approximate; the later attack is excluded from the chosen windows.

Dogfooding exposed a concrete input-format assumption: the recorded WAV is IEEEfloat32, while generated WAVs are PCM16. The initial narrow decoder rejected the recorded format; explicit decoding for the two supplied formats preserves that distinction. The failed output directory is retained and documented. This does not make the decoder a general audio importer.

## Review and learner boundaries

`learner-task.md` supplies stimuli and primary-source lookups; `reviewer-rubric.json` is separate with null outcomes. Tasks overlap the taught material and permit source assistance; no independent transfer or causal learning is claimed. AI static review is distinct from human approval.

Code review: skipped (ce-code-review unavailable). The earlier top-level CE attempt terminated without a usable receipt and transport/cleanup must not be retried. Native review and host diff checks are recorded separately before delivery. `bindings.json`, `locale-checks.json` and `validation.json` record current sources and completed integration checks when prepared. The original525-course reviewed/published goal remains intact and incomplete.

## Text evidence and Git

The unchanged Python measurement program wrote CRLF in its cached Windows JSON outputs. Repository copies use LF without changing any decoded JSON value. “Complete baseline JSON match” means equality of the parsed JSON objects; WAV reproduction is a separate exact-byte comparison. Normalize copied text before static-audit hash binding, then verify every bound Git-index blob before committing. This staging check caught the two measurement JSON line-ending differences before delivery; the independent auditor refreshed their canonical hashes.
