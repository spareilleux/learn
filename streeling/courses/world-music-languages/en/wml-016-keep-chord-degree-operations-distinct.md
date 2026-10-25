---
module_id: wml-016-keep-chord-degree-operations-distinct
department: world-music-languages
course: "Keep Chord Degree Operations Distinct"
level: advanced
prerequisites: ["wml-011-preserve-the-kind-of-a-seventh-chord"]
estimated_duration: "60 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Keep Chord Degree Operations Distinct

> Authored model and source reading. Human technical, fluent-language, musician and learner decisions remain pending. No new performance, listening, parser execution, engine render or production adoption is claimed.

A chord label can retain its root and broad kind while losing whether a degree was added, altered or removed. Flattening every instruction to an extra pitch class can keep a note that was meant to disappear. For a [GA](https://github.com/GuitarAlchemist/ga) harmony explanation, we execute a small degree-edit program before projecting its result to pitch classes.

## Read the retained evidence

The notation reference distinguishes addition, alteration and subtraction relative to chord kind. Our strict collision guards are additional authored policy, not a conformance claim. The retained practice packet’s target-specific acceptance provides a concrete reason to preserve more than a broad chord label.

[Prerequisite](../../world-music-languages/en/wml-011-preserve-the-kind-of-a-seventh-chord.md)

[Retained project artifact](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/practice-items.json)

[Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-25/unit-a.json)

[Primary reading](https://www.w3.org/2021/06/musicxml40/musicxml-reference/data-types/degree-type-value/)

## Fixed case and prepared quantities

```json
{
  "values": {
    "degrees": {
      "1": 0,
      "3": 4,
      "5": 7,
      "7": 10
    },
    "operations": [
      {
        "op": "add",
        "degree": 9,
        "semitones": 14
      },
      {
        "op": "alter",
        "degree": 5,
        "delta": -1
      },
      {
        "op": "subtract",
        "degree": 3
      }
    ]
  },
  "formula": "add requires absent degree and inserts declared offset; alter requires present degree and adds delta; subtract requires present degree and removes it; pcs=sorted(set(offset%12))",
  "expected": {
    "degrees": {
      "1": 0,
      "5": 6,
      "7": 10,
      "9": 14
    },
    "pitch_classes": [
      0,
      2,
      6,
      10
    ],
    "valid": true
  },
  "negative_control": {
    "values": {
      "degrees": {
        "1": 0,
        "3": 4,
        "5": 7,
        "7": 10
      },
      "operations": [
        {
          "op": "add",
          "degree": 9,
          "semitones": 14
        },
        {
          "op": "add",
          "degree": 5,
          "semitones": 6
        },
        {
          "op": "subtract",
          "degree": 3
        }
      ]
    },
    "expected": {
      "valid": false,
      "rejected_operation_index": 1,
      "reason": "duplicate_degree",
      "degree": 5
    }
  }
}
```

## Preserve the edit before projecting its result

The degree map retains a relationship to the underlying chord kind. The final pitch-class set answers which classes remain after the declared edits, but cannot uniquely reconstruct the edits that produced it. Different degree spellings or programs can converge on the same set. If the project task is explanation or faithful notation interchange, the operation history is therefore part of the intended meaning rather than expendable calculation detail.

The guard on adding an existing degree is deliberately strict. Another interface might choose replacement or allow duplicate entries, but it would need to declare that behavior. Here rejection makes an ambiguous instruction visible before a receiver invents a resolution. The negative control is not evidence that the primary specification mandates our exact error behavior; it tests the extra policy this teaching program has promised.

The intermediate maps also prevent a subtler mistake: collecting all pitches seen during execution instead of the pitches remaining afterward. That collection would undo subtraction while leaving a superficially rich chord description. A manual edit ledger is enough to reveal the error. Before proposing a composable grammar or agent explanation, preserve root, kind, ordered operations and original display text alongside the projected result. Actual parsing, accepted musician terminology and a usable guitar voicing would each require additional evidence beyond this small symbolic program.

### Exercise 1

Start from the degree map and apply the addition. Why retain the compound degree key?

<details><summary>Answer 1</summary>

The added degree has its stated octave-aware offset. Its pitch class may later coincide with another degree label, so projecting early would erase the edit’s identity.

</details>

### Exercise 2

Apply the alteration to the existing degree. Does this add another copy of it?

<details><summary>Answer 2</summary>

No. It changes the existing degree’s offset under the declared program. Keeping both old and new offsets would perform another musical operation.

</details>

### Exercise 3

Apply subtraction and then derive the pitch-class set.

<details><summary>Answer 3</summary>

The final map and set appear above. The removed degree is absent; deriving a union of every intermediate pitch would incorrectly retain it.

</details>

### Exercise 4

Apply the control with addition instead of alteration. Why reject it?

<details><summary>Answer 4</summary>

The target degree already exists. The strict policy rejects that indexed operation rather than guessing replacement semantics or silently producing another chord.

</details>

### Exercise 5

What falsifies an export claiming to preserve the edit program?

<details><summary>Answer 5</summary>

Treating the main and control programs as the same valid operation loses the required distinction. Retain the original symbol, kind and degree edits before claiming successful interpretation.

</details>

## Source-assisted learner task

Execute both programs manually and retain intermediate maps. Compare their acceptance with the existing task-specific chord rules. Propose a compact handoff preserving operations and provenance, with the collision as a falsifier before any grammar or agent abstraction.

First retain your unaided derivation before revealing the answers. Then inspect a specific source passage and its revision, record every kind of assistance, and keep the original and corrected responses separately. Use the direct manual result as the baseline for any calculator, DSL or agent proposal. Missing inputs stay unresolved. The fixed packet holds a prepared criterion for each exercise with no learner decision. A correct model answer supports only the declared case; acceptance needs an actual attempt and review. Record a falsifier before choosing an abstraction, then state the additional runtime or human evidence needed at the next boundary.
