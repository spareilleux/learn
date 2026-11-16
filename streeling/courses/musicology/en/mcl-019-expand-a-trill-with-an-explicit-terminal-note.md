---
module_id: mcl-019-expand-a-trill-with-an-explicit-terminal-note
department: musicology
course: "Expand a Trill with an Explicit Terminal Note"
level: advanced
prerequisites: ["mcl-014-declare-where-grace-notes-take-their-time"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Expand a Trill with an Explicit Terminal Note

> Authored model and bounded source reading. Human technical, fluent-language, musician and learner decisions remain pending. No new performance, listening result, engine render, parser execution or production adoption is claimed.

A GA exercise says to alternate two pitches for a fixed duration and finish on the main note, but its event count ends on the alternate. Both pitches are present; the terminal requirement still fails. We expand a finite authored trill policy and check its ending explicitly. This adds ornament sequence semantics beyond the prerequisite’s allocation of time around a principal note.

Declare the starting pitch, alternating pitch, count and total support before generating events. Under the equal-duration policy, each onset is an integer multiple of the event duration, and the last event ends exactly at the support boundary. The terminal pitch follows count parity. Changing count while preserving duration changes both the event spacing and the ending; it is not merely a different printed trill label.

The primary MusicXML reference distinguishes starting note, playback count and an optional terminal turn. Those fields motivate retaining the distinctions, but our equal-spacing policy is independently authored and supplies no default for a historical practice. A terminal turn would add events beyond this model and must not be smuggled into the count. The control changes only the count and lands on the other member of the pair. Keep the expanded pitch and onset arrays in a review note when a practice instruction has an ending constraint. A manual alternation table settles this narrow problem before any ornament-expansion DSL or audio engine feature is proposed.

## Read the retained project evidence

The prerequisite supplies the earlier operation and its evidence boundary. Inspect the linked project artifact before using the authored case to propose a change. Its existing observations keep their original scope: a retained source file or fixture does not establish current deployment. The fixed packet records exact inputs, prepared outputs and reading provenance. Local file hashes identify complete bytes; they do not enlarge the bounded passage actually read. A primary web page supports only the specific definition read, with no invented immutable revision or byte hash.

[Prerequisite](../../musicology/en/mcl-014-declare-where-grace-notes-take-their-time.md)

[Retained project artifact](../../../../code/streeling/evidence/music-phrase-2026-10-22/melody-constraints.json)

[Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-a.json)

[Primary reading](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/trill-mark/)

## Fixed case and prepared quantities

```json
{
  "values": {
    "main_pitch": 60,
    "alternate_pitch": 62,
    "note_count": 6,
    "duration_s": 1.2
  },
  "formula": "pitch[i]=main if i%2==0 else alternate; onset[i]=i*duration/count for i=0..count-1; duration_each=duration/count; terminal=pitch[count-1]",
  "expected": {
    "pitches": [
      60,
      62,
      60,
      62,
      60,
      62
    ],
    "onsets_s": [
      0,
      0.2,
      0.4,
      0.6,
      0.8,
      1
    ],
    "duration_each_s": 0.2,
    "terminal_pitch": 62
  },
  "negative_control": {
    "values": {
      "main_pitch": 60,
      "alternate_pitch": 62,
      "note_count": 5,
      "duration_s": 1.2
    },
    "expected": {
      "pitches": [
        60,
        62,
        60,
        62,
        60
      ],
      "onsets_s": [
        0,
        0.24,
        0.48,
        0.72,
        0.96
      ],
      "duration_each_s": 0.24,
      "terminal_pitch": 60
    }
  }
}
```

## Assumptions and evidence limits

Assume a positive finite count, main-note start, equal event durations and no terminal turn. Pitches and total support are supplied explicitly. No style-specific ornament realization or playing result is established.

## Interpret the operation before choosing an abstraction

Before revealing the answer key, write the input contract in your own words and derive the main result manually. Keep intermediate quantities or state transitions, rather than copying only a final number. Compare the negative control under the same rule and identify the input that changed. The model is a finite authored example. A matching calculation supports this example’s stated claim; it does not supply an observed user outcome or validate a production feature.

### Exercise 1

Expand the main pitch sequence without skipping the first event.

<details><summary>Answer 1</summary>

It begins on the principal pitch and alternates exactly for the declared number of events.

</details>

### Exercise 2

Derive the onset array and event duration.

<details><summary>Answer 2</summary>

Divide total support by count and place onsets at successive multiples; the final event ends at the support boundary.

</details>

### Exercise 3

Does the main case finish on the main pitch?

<details><summary>Answer 3</summary>

No. Its even count, starting on main, ends on the alternate under the stated policy.

</details>

### Exercise 4

What changes in the odd-count control?

<details><summary>Answer 4</summary>

It finishes on the main pitch and uses longer equal event durations while retaining the same total support.

</details>

### Exercise 5

What falsifies a claimed ornament-preserving handoff?

<details><summary>Answer 5</summary>

A different terminal pitch, count or support under the declared policy rejects the corresponding preservation claim.

</details>

## Source-assisted learner task

Expand the ornament by hand and compare the ending against the practice instruction. Propose a record that keeps count, start and any terminal turn separate.

Retain your unaided answer before consulting a source or calculator. Then identify a precise source passage and revision, record every kind of assistance and keep the original answer alongside any correction. A proposed agent workflow or DSL must preserve the manual result and its countercase before its convenience can be assessed. If required inputs are absent, leave the decision unresolved rather than substituting a plausible value.

Write a falsifier as an observable disagreement with the stated rule, then say what additional observation would be needed at the next boundary. Use the exercise answers as prepared checks, not as a record of your attempt. The fixed packet contains a separate prepared criterion for every exercise; all learner decisions remain undecided until an actual response and review are retained. Report assistance, corrections and remaining limits with the final note so that arithmetic correctness is not confused with independent recall, musician judgment or runtime acceptance.
