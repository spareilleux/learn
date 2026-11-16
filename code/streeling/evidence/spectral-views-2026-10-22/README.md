# Spectral values, coordinates and displays

This packet supports AUD006, CS013 and DV009. The deliverables are three trilingual course drafts, fixed numerical evidence and a scientific figure. The original goal remains 525 reviewed and publicly readable core courses across 21 departments. Source existence, AI checking, human review and deployed publication are separate stages.

## What was actually measured

Temporary Python analysis decoded the retained baseline.wav and candidate.wav from the adjacent guitar-runtime-2026-10-22 evidence folder. Both are mono PCM16 WAVs with 176400 samples at 44100 Hz. Their published bytes matched the prior render receipt and anonymous reads at Learn commit aa1a71b30ea98b9adce4f70b53c59bbf691ba1cb. The new analysis divides signed integers by 32768; the earlier exporter used a 32767 multiplier. Decoded samples are not the original native floating-point buffers.

The numerical analysis used symmetric Hann windows and an unscaled forward FFT. It followed pinned IX source equations for complete framing, then explicitly added the amplitude normalization described below. No IX binary or editor pipeline was executed, and no new guitar samples were rendered by the engine.

- calibration.json: constructed 0.25-peak cosines at 689.0625 Hz, using window lengths 2048 and 4096. Raw magnitudes change by about 6.02272037 dB while the normalized peak-amplitude estimates remain within 1e-6 of 0.25. DC and Nyquist controls reject blanket endpoint doubling. Direct-summation checks use complex absolute tolerance 1e-10.
- coordinates.json: the retained WAVs produce 341 frame rows and 1025 bins with window 2048 and hop 512. The complete frames leave 272 tail samples. Frame-start time and bin frequency formulas, selected cells, fifteen direct-summation checks and a three-by-five wrong-stride sentinel make the coordinate contract inspectable. The advisory metadata object is not a ratified schema or implemented adapter.
- display-comparison.json: a constructed half-gain baseline loses about 6.02059991 dB on 6359 common non-floored fixed-reference cells. Its per-matrix-peak display equals the baseline's relative display exactly in this calculation. Full amplitude-array hashes bind the numerical values under the recorded evaluation method and NumPy version; mathematically equivalent floating-point evaluations need not produce the same bytes.
- spectrogram-reference-comparison.png: top row uses fixed reference peak amplitude 1; bottom row uses each full matrix's own peak before visible frequency cropping. Columns B, C and 0.5B identify the retained baseline, actual earlier decay candidate and constructed half-gain control. Shared numeric limits of -80 to 0 dB do not give the rows identical references. Each displayed time cell occupies a hop, although its transform analyzes a full window. The image does not show every original sample or frequencies above 2000 Hz.
- primary-readback.json: successful anonymous byte checks for four IX source objects and four retained input/receipt files, plus official documentation request results. A direct Python documentation request returned 403; the official page was separately read with web.open. No successful byte hash is invented for that response.
- execution.json: actual installed Python, NumPy and Matplotlib versions, input receipt hashes, numerical controls and figure hash. No dependency installation occurred.
- data-audit.json: independent numerical and source audit with exact input bindings. This is AI checking, not human approval.
- learner-task.md and reviewer-rubric.json: three prepared source-assisted tasks and fifteen answer criteria. Human, fluent-language, learner and listening outcomes remain null.

## Interpretation limits

The coherent-window normalization estimates the peak amplitude of an isolated coherent real tone, with an interior-bin factor of two and undoubled DC/Nyquist endpoints. It is not a PSD, RMS, loudness, universal dBFS calibration or validated individual-guitar-partial estimator. Closely spaced or off-bin components need additional analysis.

The old candidate's decay-gate improvement remains about 0.11416615 dB against a required 1 dB. The candidate failed; the new picture supplies no replacement gate or listening approval. The half-gain control is a constructed intervention on the decoded baseline, not that actual candidate.

The calculation can be independently reproduced from the two retained WAVs and the declared framing, normalization and display formulas. Calibration and sentinel tasks can also be checked with a calculator. Temporary analysis code is not delivered as a new lab program. Locale checks, rendered-link checks and build receipts are added after those steps run. Public source/asset readback does not establish deployed course HTML or learner benefit.
