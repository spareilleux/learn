---
module_id: mcl-020-reset-an-accidental-state-at-the-bar-boundary
department: musicology
course: "Reset an Accidental State at the Bar Boundary"
level: advanced
prerequisites: ["mcl-005-preserve-written-and-sounding-pitch"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Reset an Accidental State at the Bar Boundary

> Authored model and bounded source reading. Human technical, fluent-language, musician and learner decisions remain pending. No new performance, listening result, engine render, parser execution or production adoption is claimed.

A practice generator reads a natural sign, carries it through a bar and accidentally keeps it after the next bar line. The note letter survives while its intended alteration changes. We author a narrow notation-state policy to show exactly what a measure reset preserves. The new operation concerns state scope, beyond the prerequisite’s distinction between written and sounding pitch.

Under this exercise policy, an explicit alteration overrides the key for that letter and octave within the current measure. An absent instruction consults that override and then falls back to the key. The different octave remains independent. At a new measure the overrides clear before the next event is resolved. This policy is stipulated for the exercise rather than presented as every engraving tradition’s rule. Ties and cross-staff cases are excluded.

The negative control disables only the reset. Earlier events stay identical and the first eligible event in the new measure exposes the leak. This makes the bar boundary a concrete falsifier instead of a general warning about notation. MusicXML’s accidental element describes a displayed symbol, while alter specifies pitch alteration. A receiver must not apply this teaching shorthand to explicit encoded pitches or infer a second alteration from a cautionary glyph. A manual event ledger shows where a future exercise generator should retain key context, octave and measure identity. No parser execution, score rendering or musician interpretation was observed in these cases.

## Read the retained project evidence

The prerequisite supplies the earlier operation and its evidence boundary. Inspect the linked project artifact before using the authored case to propose a change. Its existing observations keep their original scope: a retained source file or fixture does not establish current deployment. The fixed packet records exact inputs, prepared outputs and reading provenance. Local file hashes identify complete bytes; they do not enlarge the bounded passage actually read. A primary web page supports only the specific definition read, with no invented immutable revision or byte hash.

[Prerequisite](../../musicology/en/mcl-005-preserve-written-and-sounding-pitch.md)

[Retained project artifact](../../../../code/streeling/evidence/pitch-context-2026-10-22/transposition-arithmetic.json)

[Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-a.json)

[Primary reading](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/accidental/)

[Primary reading](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/alter/)

## Fixed case and prepared quantities

```json
{
  "values": {
    "key_F_alter": 1,
    "reset_at_bar": true,
    "events": [
      {
        "measure": 1,
        "octave": 4,
        "explicit_alter": 0
      },
      {
        "measure": 1,
        "octave": 4,
        "explicit_alter": null
      },
      {
        "measure": 1,
        "octave": 5,
        "explicit_alter": null
      },
      {
        "measure": 2,
        "octave": 4,
        "explicit_alter": null
      }
    ]
  },
  "formula": "state keyed by letter and octave; clear overrides at each new measure iff reset_at_bar; explicit_alter updates state; missing alter uses override else key; F4_base=65; F5_base=77; pitch=base+effective_alter",
  "expected": {
    "effective_alters": [
      0,
      0,
      1,
      1
    ],
    "pitches": [
      65,
      65,
      78,
      66
    ]
  },
  "negative_control": {
    "values": {
      "key_F_alter": 1,
      "reset_at_bar": false,
      "events": [
        {
          "measure": 1,
          "octave": 4,
          "explicit_alter": 0
        },
        {
          "measure": 1,
          "octave": 4,
          "explicit_alter": null
        },
        {
          "measure": 1,
          "octave": 5,
          "explicit_alter": null
        },
        {
          "measure": 2,
          "octave": 4,
          "explicit_alter": null
        }
      ]
    },
    "expected": {
      "effective_alters": [
        0,
        0,
        1,
        0
      ],
      "pitches": [
        65,
        65,
        78,
        65
      ]
    }
  }
}
```

## Assumptions and evidence limits

Assume only the supplied letter, octave-specific overrides and no ties across bars. The teaching fields are not raw MusicXML. Explicit encoded pitch must remain authoritative for decoding, independently of a displayed accidental symbol.

## Interpret the operation before choosing an abstraction

Before revealing the answer key, write the input contract in your own words and derive the main result manually. Keep intermediate quantities or state transitions, rather than copying only a final number. Compare the negative control under the same rule and identify the input that changed. The model is a finite authored example. A matching calculation supports this example’s stated claim; it does not supply an observed user outcome or validate a production feature.

### Exercise 1

Resolve the first explicit instruction and its same-octave continuation.

<details><summary>Answer 1</summary>

Both use the explicit natural override within the current measure under the stipulated policy.

</details>

### Exercise 2

Why does the event in the other octave retain the key alteration?

<details><summary>Answer 2</summary>

Overrides are keyed by letter and octave, so an override in another octave does not match.

</details>

### Exercise 3

Resolve the first event after the bar boundary.

<details><summary>Answer 3</summary>

Clear the prior override, then use the key alteration because no new explicit instruction is present.

</details>

### Exercise 4

Where does the disabled-reset control first differ?

<details><summary>Answer 4</summary>

It differs at the new-measure event, which incorrectly retains the earlier natural override under the intended reset policy.

</details>

### Exercise 5

May display accidental state replace explicit MusicXML pitch alteration?

<details><summary>Answer 5</summary>

No. The display symbol and encoded pitch are distinct; this exercise shorthand must not overwrite explicit pitch information.

</details>

## Source-assisted learner task

Prepare a notation-state trace and identify the first leaking event. Keep a separate column for explicit encoded pitch before proposing a GA importer or practice change.

Retain your unaided answer before consulting a source or calculator. Then identify a precise source passage and revision, record every kind of assistance and keep the original answer alongside any correction. A proposed agent workflow or DSL must preserve the manual result and its countercase before its convenience can be assessed. If required inputs are absent, leave the decision unresolved rather than substituting a plausible value.

Write a falsifier as an observable disagreement with the stated rule, then say what additional observation would be needed at the next boundary. Use the exercise answers as prepared checks, not as a record of your attempt. The fixed packet contains a separate prepared criterion for every exercise; all learner decisions remain undecided until an actual response and review are retained. Report assistance, corrections and remaining limits with the final note so that arithmetic correctness is not confused with independent recall, musician judgment or runtime acceptance.
