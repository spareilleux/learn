# Pitch estimates, listener reports and plot completeness

This packet supports GAS005, COG005 and DV010. It separates constructed signals, retained native guitar samples, estimator reports, authored plotting rows and unperformed listener/learner tasks. It makes no claim of a new engine render, detector-service run, browser capture, participant result or repaired guitar candidate.

## Actual inputs and execution

`primary-readback.json` binds the publicly retrieved Rust guitar engine to GA commit `dc2e74cbd992a298f67efb928b5b3754615e1924`. Source inspection distinguishes requested frequency and delay/filter state from a measured output pitch.

`input-bindings.json` matches the retained native baseline float32 bytes to the committed guitar-runtime results. `baseline-native.f32le` is a byte-identical copy: 705600 bytes, 176400 little-endian float32 frames, 44100 Hz, four seconds. It contains synthesized baseline samples, not a third-party recorded instrument, the WASM buffer or PCM16 decoding. The copy makes the actual numerical input publicly verifiable. The previous decay candidate still failed its 1 dB improvement gate with approximately 0.114166150 dB improvement; this new analysis does not change that history.

Temporary numerical analysis produced fixed JSON and one original PNG. Installed Python, NumPy and Matplotlib versions, script hash and one-thread numerical limits are in `execution.json`. No new Rust/WASM/IX detector, GPU, playback or dependency installation occurred. The temporary script is not a delivered runnable teaching program.

## Three different data populations

1. `synthetic-periods.json`: original one-second, unfaded, zero-phase cosine controls at 48000 Hz. A has strongest component1000Hz and fundamental repetition200Hz; B has strongest component1050Hz and fundamental repetition150Hz. Coherent spectra and direct projections verify supplied amplitudes and absent fundamental components. Their normalized recurrence curves retain multiple period candidates. These arrays are not prepared listening WAVs or participant responses.
2. `native-pitch-windows.json`: newly selected half-open windows of the actual retained native buffer, with full spectral selection rules, lag curves and local maxima. All four best lag estimates report under the authored score rule, with lags538,539,539,539 and scores above0.999. All four fail the predeclared absolute5cent proximity check against nominal requested82.4069Hz. That failure is retained; the check is neither calibrated physical truth nor a product standard. A signal-similarity score is not a probability of correct pitch.
3. `pitch-trace.json`: a separate authored six-row diagnostic table referenced to100Hz, including an octave outlier, one missing row and one invalid zero input. It is not the actual guitar trace. Valid-report coverage4/6, conditional within10cent accuracy3/4 and joint availability/accuracy3/6 answer distinct questions. Arithmetic-mean frequency, mean signed cents and median cents also differ.

## Figure and public artifacts

`pitch-errors-and-availability.png` is an original1600x960scientific plot of only the authored six-row table. Its upper panel shows every valid error including+1200cents; the horizontal zero line is a reference, not an interpolated estimate. Its lower panel shows categorical reported/missing/invalid states. Category positions are not numerical pitch errors. No error bars, invented intervals, zero-filled estimates, connecting trace or hidden octave repair appears. `plot-points.json` binds actual plotted points, rows, image hash and dimensions. One English-labelled figure is shared by the localized explanations.

The two binary artifacts were published before the course sources. `asset-readback.json` retains their immutable raw URLs and exact-byte checks, including PNG MIME/decode and float-frame verification. A successful GitHub HTML image-page response is retained as a negative control: status200alone does not make its bytes an image.

## Review and missing outcomes

The primary perception reading is only the indexed abstract of Oxenham2012, PubMed23015422. No full-paper protocol, associated stimulus, individual listener classification, anatomy or population inference is reproduced. `learner-task.md` and `reviewer-rubric.json` prepare fifteen source-assisted criteria; no learner answers or reviewer decisions are invented. Future perceptual testing requires actual prepared artifacts, measured playback/level conditions, declared instructions/order/response and participant observations. Adding fades would require remeasuring the actual stimuli.

Independent AI data/content checks remain distinct from human technical, musician/listener, fluent-language and learner review. Generation, build, internal-link/image and repeat-sync receipts concern local artifacts; anonymous immutable source readback is distinct from deployed course HTML. Imported-source metadata and existing journals are preserved. The original525-course objective remains incomplete.
