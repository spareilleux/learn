# Spectral values, coordinates and displays

## Project problem and deliverables

A GA/IX audio analyst needs to compare a guitar render without confusing raw FFT magnitude, matrix coordinates or color normalization with a musical improvement. Produce three distinct trilingual lessons: AUD006 on coherent-window amplitude calibration, CS013 on a matrix handoff's axes/units, and DV009 on fixed versus panel-relative spectrogram scales. Use five corrected exercises per course and a separate three-task/fifteen-criterion learner packet. Keep human, fluent-language, participant and listening outcomes null. The full original21-department/525-course reviewed and published goal remains active.

No production or lab program is being added. Temporary numerical/plotting analysis will produce fixed JSON evidence and a standalone figure. Calculations on published samples are new analysis, not a new engine render, IX binary run, ComfyUI node or deployed integration. The source observations come from IX commit bd1336b7c4045e427dcdbe80b102790e45da5ce1, especially spectral.rs, window.rs and the spectrogram handler. Preserve that distinction even when the numerical method follows its equations.

## Inputs and assumptions

Use the retained native baseline/candidate PCM16 WAVs in code/streeling/evidence/guitar-runtime-2026-10-22. Bind their exact published bytes and prior render receipt; expected SHA256 values are a78a70243a81aa79d806d9ef3db7baa1385c479505f7d5e97b8bf0c7866c3f98 and055e03fb6064f62601b1bbc07942d3e2223da6d2fc614c6f63fa9ec8d964be73 respectively. Decode signed PCM16 integers with the explicitly chosen32768 denominator. These are decoded quantized WAV samples, not the raw native float buffers; the prior encoder's32767 multiplier is a distinct step.

Use complete2048-sample frames, hop512 and a symmetric Hann window0.5-0.5cos(2pi*n/(N-1)), at44100Hz. Calculate unnormalized one-sided magnitudes with the forward FFT's default backward normalization. For isolated-bin amplitude estimates, multiply interior bins by2/sum(window), but DC and Nyquist by1/sum(window). That is an explicit peak-amplitude estimator, not a PSD, integrated broadband power, universal dBFS calibration or a guarantee for overlapping guitar partials.

## Before-analysis predictions and controls

- A synthetic0.25-peak cosine at689.0625Hz lies at bin32 for2048samples and bin64 for4096samples. Raw coherent magnitudes should approximately double when the window doubles, even though the cosine amplitude stays0.25. Normalized amplitude estimates should remain within1e-6 of0.25 under this symmetric Hann. Separate constant0.25 and Nyquist0.25*(-1)^n controls should normalize to0.25 with no factor2; deliberately doubling those endpoint bins should fail that expectation.
- Each four-second input has176400samples. Complete2048/512 framing should yield341frames and1025one-sided bins,349525cells. The last frame should begin at174080 and end at176128, leaving272samples outside these complete frames. Report frame-start time j*512/44100 and bin frequency k*44100/2048; do not mistake a hop-sized display column for the full analysis-window support.
- A constructed0.5-gain copy of the decoded baseline should shift non-floored amplitude dB values by20log10(0.5), about-6.0206dB. Normalizing each panel by its own maximum before the same clipping should hide that gain difference. This copy is not the actual decay candidate or a new physical render. A shared fixed amplitude reference should retain the difference where display clipping does not erase it.
- For a constructed3-by-5 frame/bin sentinel with value100*frame+bin, cell[2,4] should be204 at row-major flat offset14. Using stride3 would instead read offset10 and value200. Equal total cell counts do not establish axis identity.

## Falsifiers and interpretation limits

Reject any predicted arithmetic contradicted by numerical calculation. Compare selected FFT bins with direct summation as an independent check and keep tolerances explicit. A normalizing formula validated on isolated calibration signals is not a general partial-amplitude measurement for guitar noise or unresolved components. A picture is not a loudness or preference test; preserve the earlier candidate's failed declared decay gate. A matrix metadata example is an advisory teaching handoff, not a new ecosystem schema or claimed ComfyUI implementation.

The simpler alternative is hand calculation on the small calibration and sentinel examples; the numerical matrices and shared-scale figure earn their cost by showing how a real retained signal is displayed. Do not introduce a new optimizer, parser, protocol generator or plotting framework. Use already installed numerical/plotting libraries, retain versions and input hashes, and perform no dependency installation. Normalize all owned text and reviewer receipts to UTF-8 without BOM and LF before hash binding. Review the actual figure, source-assisted tasks and localized answers, then regenerate/test/build and verify anonymous source/asset readback through the existing draft PR. Deployed course HTML and human review remain separate gates.
