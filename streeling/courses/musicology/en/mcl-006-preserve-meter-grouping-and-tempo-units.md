---
module_id: mcl-006-preserve-meter-grouping-and-tempo-units
department: musicology
course: "Preserve Meter Grouping and Tempo Units"
level: intermediate
prerequisites: ["mcl-004-model-timing-without-inventing-a-style", "mcl-005-preserve-written-and-sounding-pitch"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Preserve Meter Grouping and Tempo Units

> **Draft scope.** Authored complete-bar arithmetic, primary specification reading and pinned source inspection. Human technical, musician, fluent-language and learner reviews and deployed course HTML verification remain pending. No parser, score importer, playback engine or player was tested.

## The project question

A guitarist asks GA to preserve a written grouping when importing a practice pattern. Keeping the total duration is necessary, but it cannot by itself preserve where groups begin. This lesson distinguishes a time signature, a group sequence, score-duration units and a metronome unit before following the project's actual representation boundaries.

The [MusicXML time reference](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/time/) permits an additive numerator in one numerator/denominator pair, and multiple pairs for mixed denominators. A plain 7/8 indication and an explicit 2+2+3 over 8 therefore carry different grouping information even though their total bar durations agree. No performance accent or cultural identity follows automatically from these written fields.

## 1. Name what repeats per minute

Stipulate a complete 7/8 bar, constant quarter-note rate 120 per minute, no pickup and no tempo change. Each quarter lasts 0.5 seconds and each eighth 0.25 seconds. The bar lasts 1.75 seconds. If the metronome instead counts eighth notes at 120 per minute, each eighth lasts 0.5 seconds and the bar lasts 3.5 seconds.

The [MusicXML metronome reference](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/metronome/) combines a beat-unit group with a per-minute value for an ordinary mark. The [beat-unit definition](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/beat-unit/) identifies its graphical note value; [per-minute](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/per-minute/) can also contain text. Here numeric 120 is an explicit premise, not a universal interpretation of arbitrary mark text. The signature's denominator alone does not specify the metronome unit.

### Practice exercise 1: disambiguate the rate

Compare a 7/8 bar at quarter-note rate 120 with the same bar at eighth-note rate 120. Give each duration and identify the missing field in an instruction saying only “7/8, 120 BPM.”

> **Answer:** The first lasts 1.75 seconds; the second 3.5 seconds. The named metronome note unit is missing. A denominator of 8 does not resolve that omission by itself.

## 2. Preserve a grouping as well as a sum

Use authored groups 2+2+3 eighths. Their starts within the bar are eighth-pulse positions 0, 2 and 4. A composite 2/4+3/8 has the same total seven eighths but explicitly separates four eighths from three. Its component starts are 0 and 4. Reducing both to the total 7/8 erases that distinction.

These are declared score groupings. Calling each start a performed loud accent would add an unobserved realization. A useful importer report can show the entered time text, retained group sequence and any approximation separately from audio or player feedback.

### Practice exercise 2: compare equal totals

Give the group lengths and starts in eighth-pulse units for 2+2+3 over 8 and for 2/4+3/8. Does equal total duration establish equal grouping or equal played accents?

> **Answer:** The first has lengths 2, 2, 3 and starts 0, 2, 4. The second has lengths 4, 3 and starts 0, 4. Both total 7 eighths; neither equal grouping nor equal played accents follows from that sum.

## 3. Keep score divisions distinct from the denominator

Stipulate 24 divisions per quarter. The [MusicXML divisions definition](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/divisions/) sets the quarter-note reference for these units. One eighth occupies 12 divisions, so the seven-eighth bar occupies 84. Its 2+2+3 boundaries are 0, 24, 48 and 84 divisions. The mixed-denominator component boundaries are 0, 48 and 84.

Under the same division reference and quarter-note rate 120, a 6/8 bar and a 3/4 bar both span 72 divisions and 1.5 seconds. That arithmetic does not specify the same grouping or conducted pulse. The [duration reference](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/duration/) also has score-position rules: counting every note element as an independent forward step is not a general multi-voice or chord timing algorithm. No such algorithm was run here.

### Practice exercise 3: reconstruct the units

At 24 divisions per quarter, compute an eighth, a 7/8 bar, and the total for each of 6/8 and 3/4. What stronger equivalence does the last equality fail to prove?

> **Answer:** An eighth is 12 divisions; 7/8 is 84; 6/8 and 3/4 are each 72. Equal totals do not establish the same group structure, metronome unit, performed accent or musical interpretation. Score divisions are not automatically the MIDI file's tick resolution.

## 4. Follow the exact importer boundary

At GA commit `76efbffd5af82b46c3146957a6bd4504008eeb89`, the [MusicXML time type](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Types/MusicXmlTypes.fs#L115-L138) retains one integer numerator and one integer denominator. The [time parser](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Parsers/MusicXmlParser.fs#L123-L138) selects the first child of each name and tries to parse their text as integers.

For the fixed selected inputs, static inspection predicts 7 and 8 for plain 7/8; no time value for numerator text `2+2+3`; and only 2 and 4 for the two-pair 2/4+3/8 input. The last prediction discards the second pair, rather than retaining a summed 7/8. These are source-derived predictions, not freshly executed importer results. They identify concrete boundary cases to test before promising faithful import.

### Practice exercise 4: avoid a false normalization claim

State the three predicted results. Why would “the importer normalizes both composite forms faithfully to 7/8” be unsupported by this source?

> **Answer:** Plain 7/8 predicts integers 7 and 8. Additive numerator text `2+2+3` predicts no time value. Two pairs 2/4 and 3/8 predict only 2 and 4. The inspected branch neither retains the additive expression nor sums the pairs; no fresh runtime result was obtained.

## 5. Make the transfer check explicit

The [MIDI types](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Types/MidiTypes.fs#L19-L46) similarly represent a time-signature event as two integers. The [selected metadata branch body](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Parsers/MidiParser.fs#L208-L217) raises 2 to the denominator exponent and skips the remaining two payload bytes. If this body were reached, an authored payload with bytes 7, 3, 24, 8 would construct 7/8. It would not supply a retained ordered grouping 2+2+3.

**Reachability correction.** The surrounding dispatcher masks status to its high nibble before matching a full meta-event status, so this meta-event arm is unreachable through the shown match. The payload example above is conditional body interpretation, not a valid prediction of successful MIDI parsing. [MCL-007](mcl-007-integrate-a-midi-tempo-map-before-scheduling.md) makes that distinction explicit. The MusicXML branch predictions in the previous section are separate source observations.

### Practice exercise 5: specify a useful import check

What can that selected MIDI branch retain from the authored payload? Name the additional comparison needed before an agent says that a guitarist's grouped exercise survived an import/export path.

> **Answer:** If that selected body were reached, it would construct numerator 7 and denominator 8 and skip payload bytes 24 and 8. The actual surrounding dispatch does not reach it, so do not call those values parser output. The event representation also lacks the authored group order. Compare entered and recovered time text, group boundaries, duration units and named metronome unit on a pinned, executed path; inspect the rendered score and intended playback separately. No system-wide loss or successful round trip was measured here.

The [fixed packet](../../../../code/streeling/evidence/meter-picking-2026-10-22/README.md) retains the exact calculations, source predictions and public source hashes. [WML-006](../../world-music-languages/en/wml-006-preserve-the-origin-of-an-additive-cycle.md) follows what a change of cycle origin does to the same grouping.
