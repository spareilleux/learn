# Pluck coordinates and attack clock

This packet supports GAS006, GTR006 and AUD007. It contains fixed analytical data and primary-source observations, not a synthesis implementation or a new runnable lab. The public GA source revision is `76efbffd5af82b46c3146957a6bd4504008eeb89`.

## What was checked

- `primary-readback.json`: three anonymous public text downloads exactly equal to immutable local Git objects.
- `primary-reading.json`: actual primary reading and transport limits. The Princeton lecture is a scanned PDF: page 5 (printed 228) was visually rendered and read; empty text extraction was not treated as reading its equations.
- `ideal-pluck-modes.json`: 80 ideal triangular-displacement modal coefficients and rational null conditions, with fixed peak displacement and zero initial velocity. These coefficients are neither microphone nor bridge-force spectra.
- `fret-geometry.json`: four authored equal-tempered length cases, including exact octave rows and a non-octave transfer case. No player's hand or guitar was measured.
- `source-excitation-model.json`: real-arithmetic transcription of velocity/index/window expressions. The source uses a compact tent multiplying recursively smoothed noise, not the ideal full-length triangular displacement. A strict bandlimit was not established.
- `attack-clock.json`: six isolated envelope/rate cases, threshold crossings and an effective-coefficient translation. No Rust floating-point execution or complete audio waveform was computed for this packet.
- `source-observations.json`: preserved constructor/profile prediction refutation, comment/expression distinction and source-derived retained attack-state concern. The retained state concern is not a reproduced runtime failure or an implemented fix.
- `data-audit.json`: independent source/download/hash checks and independent numerical integration/recomputation, including threshold neighbors.
- `reviewer-rubric.json` and `learner-task.md`: prepared source-assisted transfer tasks. Their acceptance criteria are not participant outcomes.

## Scope of the decisions

Physical position, normalized position and delay-buffer index have different contracts. The physical-coordinate DSL mapping is a design candidate; the simpler documented synthetic control remains an alternative. The course does not adopt a normative schema or implement either control.

The isolated time-constant translation changes an effective multiplier deliberately. It does not compensate every frequency, setter order, clamp, DSP state or browser path. No audio, player, ComfyUI or perceptual trial occurred here. Human technical, fluent-language, musician and learner results and deployed HTML readback remain pending.

`validation.json` records local generator tests, source sync, full site build, rendered internal links and repeat-sync equality once completed. Anonymous immutable source publication is checked separately after the commit; it must not be presented as deployed course HTML or human approval. Existing source provenance and journals are preserved.
