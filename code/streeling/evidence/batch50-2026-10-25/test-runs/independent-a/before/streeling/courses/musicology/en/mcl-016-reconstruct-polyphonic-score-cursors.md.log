---
module_id: mcl-016-reconstruct-polyphonic-score-cursors
department: musicology
course: "Reconstruct Polyphonic Score Cursors"
level: advanced
prerequisites: ["mcl-007-integrate-a-midi-tempo-map-before-scheduling"]
estimated_duration: "60 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Reconstruct Polyphonic Score Cursors

> Authored model and source reading. Human technical, fluent-language, musician and learner decisions remain pending. No new performance, listening, parser execution, engine render or production adoption is claimed.

A serialized score can list a whole upper voice before returning to the beginning for a lower voice. Summing every note duration as consecutive playback changes simultaneity into succession. A [GA](https://github.com/GuitarAlchemist/ga) phrase handoff therefore needs an explicit cursor interpretation before tempo conversion. This lesson reconstructs the event intervals from a short operation stream.

## Read the retained evidence

The notation reference uses backup and forward to coordinate voices and forbids crossing measure or division boundaries with backup. The retained timed-event packet already uses absolute intervals. Our task explains a possible conversion into such intervals, without claiming its parser exists.

[Prerequisite](../../musicology/en/mcl-007-integrate-a-midi-tempo-map-before-scheduling.md)

[Retained project artifact](../../../../code/streeling/evidence/music-phrase-2026-10-22/timed-events.json)

[Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-25/unit-a.json)

[Primary reading](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/backup/)

## Fixed case and prepared quantities

```json
{
  "values": {
    "measure_units": 4,
    "operations": [
      {
        "op": "note",
        "id": "a",
        "duration": 4
      },
      {
        "op": "backup",
        "duration": 4
      },
      {
        "op": "note",
        "id": "b",
        "duration": 2
      },
      {
        "op": "forward",
        "duration": 2
      }
    ]
  },
  "formula": "cursor=0; note records [cursor,cursor+duration) then advances; backup subtracts duration; forward adds duration; valid=all cursor states within [0,measure_units]",
  "expected": {
    "note_intervals": {
      "a": [
        0,
        4
      ],
      "b": [
        0,
        2
      ]
    },
    "cursor_states": [
      0,
      4,
      0,
      2,
      4
    ],
    "final_cursor": 4,
    "valid": true
  },
  "negative_control": {
    "values": {
      "measure_units": 4,
      "operations": [
        {
          "op": "note",
          "id": "a",
          "duration": 4
        },
        {
          "op": "backup",
          "duration": 2
        },
        {
          "op": "note",
          "id": "b",
          "duration": 2
        },
        {
          "op": "forward",
          "duration": 2
        }
      ]
    },
    "expected": {
      "note_intervals": {
        "a": [
          0,
          4
        ],
        "b": [
          2,
          4
        ]
      },
      "cursor_states": [
        0,
        4,
        2,
        4,
        6
      ],
      "final_cursor": 6,
      "valid": false
    }
  }
}
```

## Separate document traversal from musical time

A serialization cursor is a device for locating events as the document is read. It is not necessarily a monotonic playback clock. The backup operation is the simplest witness: the reader moves backward while the music itself has not reversed. Converting the cursor to absolute note intervals before playback lets later analysis use a monotonic event timeline without losing the document’s voice placement.

The fixed division unit must accompany every duration in this example. A change of divisions mid-measure would require another conversion rule and cannot be handled by subtracting an old duration from a cursor expressed in new units. The primary reference’s boundary restrictions are therefore semantically useful, rather than cosmetic validation. Our model avoids such changes so that the arithmetic is directly inspectable.

Final cursor equality is also narrower than full score correctness. An invalid stream could leave the expected final cursor after earlier illegal excursions, and matching note endpoints need not preserve voice labels or articulation. This is why the check retains every cursor state as well as the final one. The manual ledger already catches both changed overlap and overflow in the control. A future importer should preserve these witnesses before adding tempo mapping, voice-leading analysis or guitar allocation, each of which depends on an accurate interval reconstruction.

### Exercise 1

Walk the main stream and record every cursor state. Why is backup not negative-duration music?

<details><summary>Answer 1</summary>

The cursor states are listed below. Backup repositions the serialization cursor; it does not create a note with negative sounding duration.

</details>

### Exercise 2

Derive both note intervals. Are the notes sequential or overlapping?

<details><summary>Answer 2</summary>

They begin together in the main case and overlap for the shorter note’s duration. Document order alone does not establish playback order.

</details>

### Exercise 3

What does the forward operation add?

<details><summary>Answer 3</summary>

It advances the cursor without adding a sounding event in this authored stream. Keep silent time separate from a new note and from the previous note’s duration.

</details>

### Exercise 4

Apply the shortened-backup control. Locate the placement change and the boundary failure.

<details><summary>Answer 4</summary>

The later voice starts later, and the final cursor exceeds the declared measure. Retain both facts rather than clamping the cursor and hiding the invalid stream.

</details>

### Exercise 5

What would reject an export claiming to preserve polyphony?

<details><summary>Answer 5</summary>

An interval list that serializes the main notes or gives the control the same start times loses required timing. An out-of-bounds cursor rejects this bounded input before scheduling.

</details>

## Source-assisted learner task

Reconstruct both cursor tables manually before opening answers. Compare their absolute intervals with the retained event packet. Propose a handoff retaining division units and voice identity, with the measure overflow as a falsifier before any importer or DSL implementation.

First retain your unaided derivation before revealing the answers. Then inspect a specific source passage and its revision, record every kind of assistance, and keep the original and corrected responses separately. Use the direct manual result as the baseline for any calculator, DSL or agent proposal. Missing inputs stay unresolved. The fixed packet holds a prepared criterion for each exercise with no learner decision. A correct model answer supports only the declared case; acceptance needs an actual attempt and review. Record a falsifier before choosing an abstraction, then state the additional runtime or human evidence needed at the next boundary.
