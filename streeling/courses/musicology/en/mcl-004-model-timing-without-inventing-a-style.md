---
module_id: mcl-004-model-timing-without-inventing-a-style
department: musicology
course: "Model Timing Without Inventing a Style"
level: intermediate
prerequisites: ["mcl-003-style-labels-as-evidence", "mus-004-rhythm-and-groove"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Model Timing Without Inventing a Style

> **Draft scope.** Invented score/performance-like annotations, exact calculations and pinned source inspection. Human technical, musician, fluent-language and learner reviews and deployed course HTML verification remain pending. No recording, listener or performed style was assessed.

## The project question

A GA lesson asks an agent to explain a rhythm. Should it report the written grid, fit a timing model, or name a musical style? These are different claims. In their [published abstract](https://online.ucpress.edu/mp/article-abstract/19/3/333/61900/Swing-Ratios-and-Ensemble-Timing-in-Jazz?redirectedFrom=fulltext), Friberg and Sundström report tempo-dependent timing ratios in selected jazz recordings. Their [author-hosted account](https://www.speech.kth.se/music/performance/Texts/ensemble_swing.htm) also distinguishes ensemble roles. Those limited observations caution against treating a fixed ratio as a universal style definition. Only the abstract and author page were read; no associated audio was played or copied.

## 1. Keep the score and the annotation in separate columns

Use the following original teaching data. Beats are absolute quarter-note units; seconds are authored annotations, not measurements extracted from a recording. C4 = MIDI 60 is our pitch convention, but this timing table contains no pitches or instrument attribution.

| Score onset in beats | Authored onset in seconds |
| --- | --- |
| 0 | 0 |
| 0.5 | 0.34 |
| 1 | 0.52 |
| 1.5 | 0.84 |
| 2 | 1.04 |
| 2.5 | 1.37 |
| 3 | 1.56 |
| 3.5 | 1.88 |

The phrase ends at beat 4 and second 2.08. Onbeat intervals last 0.52 seconds, corresponding to approximately 115.384615385 quarter-notes per minute. This reference rate does not make the written offbeats occur halfway through the authored intervals.

### Practice exercise 1: locate an offbeat

Under an equal-subdivision model using the 0.52-second onbeat spacing, where would the first offbeat fall? How far from it is the authored 0.34-second onset, and is that difference an observed performance error?

> **Answer:** The equal subdivision is at 0.26 seconds. The authored onset is 0.08 seconds, or 80 ms, later. That is a residual relative to the chosen model in invented data. It is not an observed mistake, a genre label or evidence that a performer should change.

## 2. Compare models using a stated residual

A straight model places every offbeat halfway through its onbeat interval. A fixed 2:1 model places it two thirds of the way through. A fitted common fraction, estimated from these same offbeats, is `131/208`, giving an offset of 0.3275 seconds within every pair. Onbeats remain at their declared anchors in each model.

Across all eight onsets, mean absolute residual is 33.75 ms for the straight model, approximately 9.583333333 ms for the fixed model and 3.75 ms for the fitted model. The [fixed timing record](../../../../code/streeling/evidence/phrase-performance-2026-10-22/timing-models.json) retains each prediction and signed residual. A lower in-sample residual describes fit to these data; it does not measure musical quality. The fitted model used the same data being scored, so this comparison supplies no independent validation.

### Practice exercise 2: reconstruct the fitted fraction

The within-pair offbeat offsets are 0.34, 0.32, 0.33 and 0.32 seconds. Derive their common least-squares offset and fraction of the 0.52-second pair. What claim would the smallest reported residual still fail to support?

> **Answer:** The mean offset is 0.3275 seconds; dividing by 0.52 gives `131/208`. The resulting model has mean absolute residual 3.75 ms across all eight onsets. The smallest in-sample residual does not establish genre, a preferred groove, a player's skill or a listener benefit.

## 3. A playback instruction is not a performance annotation

The [MusicXML swing element](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/swing/) can specify a ratio for applicable playback. Its positive-integer `first` and `second` fields describe that instruction; they do not identify the source of an observed onset table. A fixed 2:1 instruction would give within-pair offset approximately 0.346666667 seconds under our reference spacing, not all four distinct authored offsets.

Do not infer a complete import/export or playback implementation from the specification. This lesson ran none. Applicability conditions, note types and timing modifications matter when implementing a real conversion. [MUS-024](../../music/en/mus-024-preserve-attacks-and-harmonic-boundaries.md) separately covers note-event continuity and units.

### Practice exercise 3: bound the export claim

An agent replaces the table with one 2:1 playback instruction and promises exact recreation. Which differences remain, and what would an actual fidelity claim require?

> **Answer:** A common offset near 0.346666667 seconds does not reproduce the distinct offsets 0.34, 0.32, 0.33 and 0.32. The instruction is a model, not the original annotations. Exact recreation would need retained timing details, a tested conversion and observed output under the relevant applicability rules. None was executed here.

## 4. Quantify a particular source representation loss

At GA commit `dc2e74cbd992a298f67efb928b5b3754615e1924`, the inspected [MIDI parser](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Parsers/MidiParser.fs) converts microseconds per quarter into integer BPM with `60000000 / microsecondsPerQuarter`. For 520000 microseconds, integer division gives 115, whereas the reference rate is approximately 115.384615385.

If a hypothetical later consumer rebuilt four quarter beats from 115 BPM, it would obtain approximately 2.086956522 seconds instead of 2.08, a difference of approximately 6.956521739 ms. This is conditional source-assisted arithmetic. No parser, importer or playback path was run, and the calculation does not establish actual GA drift or a perceptible difference. The separate [MIDI types](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Types/MidiTypes.fs) also declare delta ticks and a time-division field; those declarations alone are not an accumulated performance timeline.

### Practice exercise 4: distinguish a modeled consequence from a bug capture

Compute the integer BPM and the hypothetical four-quarter duration from the stated microsecond value. May the agent call the resulting difference an observed playback failure?

> **Answer:** Integer BPM is 115. The reconstructed duration is `240/115` seconds, approximately 2.086956522, exceeding 2.08 by approximately 6.956521739 ms. No: the arithmetic characterizes one representation choice under a hypothetical consumer. An actual failure claim needs a tested path and captured output.

## 5. Preserve order when changing time coordinates

Join the authored beat/second anchors with one strictly increasing piecewise-linear map and apply it to every onset and offset. Because the map preserves order, two half-open note intervals overlap before the conversion exactly when they overlap afterward. The [string-occupancy example](../../guitar-studies/en/gtr-005-plan-which-string-keeps-ringing.md) therefore remains infeasible at its early-D overlap and fret cap after that common map.

Changing only D's onset from beat 1.5 to 2 is another operation. In this authored map, it moves from 0.84 to 1.04 seconds, or 200 ms, while its offset remains fixed. It can change overlap and shorten the note. The 250 ms alternative discussed in [GAA-005](../../guitar-alchemist-academy/en/gaa-005-repair-a-phrase-without-hiding-the-change.md) instead assumes a constant 120 quarter-notes per minute. Do not mix these references.

### Practice exercise 5: explain why quantization is not neutral

Does applying the same strictly increasing map to all boundaries solve a string-occupancy conflict? How does moving only one onset differ?

> **Answer:** The common map preserves every overlap and therefore the model's assignment feasibility. Moving only one onset can change overlap, articulation and duration relative to an unchanged offset. That is a musical edit requiring an explicit intention, not merely a change of time units or proof of a better style.
