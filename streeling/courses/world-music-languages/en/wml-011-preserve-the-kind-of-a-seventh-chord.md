---
module_id: wml-011-preserve-the-kind-of-a-seventh-chord
department: world-music-languages
course: "Preserve the Kind of a Seventh Chord"
level: intermediate
prerequisites: ["wml-005-declare-note-name-conventions"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Preserve the Kind of a Seventh Chord

> Authored example and source reading. No new guitar performance, audio or parser execution, participant response or production adoption is claimed. Human technical, fluent-language and learner decisions remain pending.

Translating a chord label requires more than preserving its root letter. A major triad can carry either a minor or major seventh, and a small suffix change alters the intended pitch content. If an agent normalizes every label containing major to the same family, a guitar exercise can silently change harmony. This lesson keeps root convention, chord kind and original displayed symbol separate before proposing a portable representation for GA.

## Read the retained evidence

Read the retained practice packet's C-major candidates and its candidate containing an additional seventh-class note. They illustrate why target-specific acceptance differs from a broad label match. MusicXML's kind-value definitions distinguish dominant, minor-seventh and major-seventh by their triad and seventh qualities. We use only that explicit subset. We did not run a chord parser or claim that every musician uses the same text abbreviation.

[Prerequisite](../../world-music-languages/en/wml-005-declare-note-name-conventions.md)

[Retained project artifact](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/practice-items.json)

[Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-24/unit-a.json)

[Validation journal](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)

[Primary reading](https://www.w3.org/2021/06/musicxml40/musicxml-reference/data-types/kind-value/)

### Exercise 1

Use root pitch class `0` and the authored dictionary `dominant=[0,4,7,10]`, `minor-seventh=[0,3,7,10]`, `major-seventh=[0,4,7,11]`. Offsets are semitone distances from the root in the declared equal-tempered model. Keep this dictionary visible: the word seventh alone does not identify the third or the size of the seventh.

Which offsets define the dominant kind here?

<details><summary>Answer 1</summary>

They are `[0,4,7,10]`: a major-triad third offset `4` and a minor-seventh offset `10`, plus root and fifth.

</details>

### Exercise 2

For the main case choose kind `dominant`. Add the root to each offset modulo `12`, then sort to obtain `[0,4,7,10]`. This determines a pitch-class family, not bass, register, doubling or fingering. A guitarist still needs a voicing and a physical instruction before the family becomes something to play.

What result is justified, and what is still missing?

<details><summary>Answer 2</summary>

The justified family is `[0,4,7,10]`. Absolute notes, bass choice, string allocation and playability remain unspecified.

</details>

### Exercise 3

The dictionary's `minor-seventh` changes the third to `3` while keeping seventh `10`; `major-seventh` keeps third `4` but changes seventh to `11`. Thus the adjective may concern a different component depending on the declared kind. An explanation should name both components instead of asking the learner to infer them from an ambiguous shortened display.

Why are triad quality and seventh quality separate fields of meaning?

<details><summary>Answer 3</summary>

The minor-seventh kind has `[0,3,7,10]`, while major-seventh has `[0,4,7,11]`. Third and seventh change independently in the declared dictionary.

</details>

### Exercise 4

The negative control changes only kind from `dominant` to `major-seventh`. The output becomes `[0,4,7,11]`, retaining root and major triad while raising the seventh by one semitone. A translation audit checking only the root name or the presence of a seventh would miss the altered chord member.

What must the audit detect in the control?

<details><summary>Answer 4</summary>

It must detect seventh offset `11` replacing `10`, with third offset `4` unchanged. The family is different despite the shared root and triad.

</details>

### Exercise 5

A multilingual handoff can retain an explicit kind identifier alongside the original symbol and its declared notation convention. That is an advisory record, not a newly ratified GA schema. If the source uses an unsupported suffix, leave the interpretation unresolved rather than selecting a familiar local convention based on the writer's language or presumed nationality.

What would falsify a claim that translation preserved this chord kind?

<details><summary>Answer 5</summary>

Mapping the main and control symbols to the same pitch-class family loses their seventh distinction. Preserving a root letter alone cannot support the stronger harmony-preservation claim.

</details>

## Source-assisted learner task

Build the small dictionary and main/control pitch-class sets manually. Inspect the retained candidate keys and official kind definitions, then write a bilingual explanation retaining the source symbol, convention and explicit kind. State a one-note falsifier for a lossy translation. Leave actual parser support, idiomatic musician usage and physical voicing selection to their own evidence and review.

First retain your answer before revealing the prepared corrections. Use the manual table or calculation as the baseline for any calculator, source lookup or agent assistance, and record that assistance. Keep the original response and the corrected response separately. Match each exercise to a prepared criterion in the fixed packet; those criteria have no learner decisions yet. Record an actual source passage and its revision, then distinguish what it establishes from your proposed next step. Report any missing input as unresolved. A mathematically correct answer supports the stated example; human review, runtime execution and learner acceptance require their own retained observations.
