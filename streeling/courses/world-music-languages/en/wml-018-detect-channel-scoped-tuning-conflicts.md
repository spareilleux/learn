---
module_id: wml-018-detect-channel-scoped-tuning-conflicts
department: world-music-languages
course: "Detect Channel-Scoped Tuning Conflicts"
level: advanced
prerequisites: ["wml-004-preserve-intonation-beyond-pitch-classes"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Detect Channel-Scoped Tuning Conflicts

> Authored model and bounded source reading. Human technical, fluent-language, musician and learner decisions remain pending. No new performance, listening result, engine render, parser execution or production adoption is claimed.

A tuning handoff keeps each note’s cent offset but sends simultaneous notes through a shared pitch-bend channel. The stored offsets can be individually correct while their realization conflicts. We encode a small declared bend mapping and check concurrency at the channel boundary. This operation goes beyond retaining a ratio or residual: it asks whether the chosen transport scope can carry the simultaneous requests.

The official message overview identifies a channel-scoped pitch-bend message, its byte order and receiver-dependent sensitivity. Declare the sensitivity before converting cents to an integer bend value. Preserve least-significant and most-significant bytes in their specified order; swapping them changes the value. The example’s symmetric rounding convention is authored and avoids the endpoints where a complete implementation would need an explicit range policy.

Under this model a channel has one bend setting at a time. Two overlapping notes requiring unequal encoded bends on that channel therefore conflict. The distinct-channel control preserves both offsets and their bytes while removing the shared-state collision. That does not certify the receiving instrument’s channel independence or configure its sensitivity. Half-open note support makes endpoint coincidence explicit; sustained release tails are excluded. A manual note/channel table is enough to reject a proposed same-channel realization before implementing a channel allocator or extending a tuning DSL. No MIDI message was sent, and no performed or culturally preferred intonation is asserted.

## Read the retained project evidence

The prerequisite supplies the earlier operation and its evidence boundary. Inspect the linked project artifact before using the authored case to propose a change. Its existing observations keep their original scope: a retained source file or fixture does not establish current deployment. The fixed packet records exact inputs, prepared outputs and reading provenance. Local file hashes identify complete bytes; they do not enlarge the bounded passage actually read. A primary web page supports only the specific definition read, with no invented immutable revision or byte hash.

[Prerequisite](../../world-music-languages/en/wml-004-preserve-intonation-beyond-pitch-classes.md)

[Retained project artifact](../../../../code/streeling/evidence/intonation-listening-2026-10-22/intonation.json)

[Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-a.json)

[Primary reading](https://midi.org/summary-of-midi-1-0-messages)

## Fixed case and prepared quantities

```json
{
  "values": {
    "sensitivity_cents": 200,
    "notes": [
      {
        "id": "A",
        "channel": 0,
        "start": 0,
        "end": 1,
        "offset_cents": 0
      },
      {
        "id": "B",
        "channel": 0,
        "start": 0,
        "end": 1,
        "offset_cents": 25
      }
    ]
  },
  "formula": "bend=8192+floor(8192*cents/sensitivity+0.5); LSB=bend%128; MSB=bend//128; conflict iff same channel and max(starts)<min(ends) and unequal bend; note support is half-open",
  "expected": {
    "bend_values": [
      8192,
      9216
    ],
    "lsb_msb": [
      [
        0,
        64
      ],
      [
        0,
        72
      ]
    ],
    "conflict_pairs": [
      [
        "A",
        "B"
      ]
    ]
  },
  "negative_control": {
    "values": {
      "sensitivity_cents": 200,
      "notes": [
        {
          "id": "A",
          "channel": 0,
          "start": 0,
          "end": 1,
          "offset_cents": 0
        },
        {
          "id": "B",
          "channel": 1,
          "start": 0,
          "end": 1,
          "offset_cents": 25
        }
      ]
    },
    "expected": {
      "bend_values": [
        8192,
        9216
      ],
      "lsb_msb": [
        [
          0,
          64
        ],
        [
          0,
          72
        ]
      ],
      "conflict_pairs": []
    }
  }
}
```

## Assumptions and evidence limits

Assume the declared sensitivity, interior encoded bend values and equal receiver settings. Note supports are half-open; sustaining release tails are excluded. Distinct channels remove the modeled conflict but do not certify receiver independence.

## Interpret the operation before choosing an abstraction

Before revealing the answer key, write the input contract in your own words and derive the main result manually. Keep intermediate quantities or state transitions, rather than copying only a final number. Compare the negative control under the same rule and identify the input that changed. The model is a finite authored example. A matching calculation supports this example’s stated claim; it does not supply an observed user outcome or validate a production feature.

### Exercise 1

Encode both cent offsets using the declared sensitivity.

<details><summary>Answer 1</summary>

The displayed integer bends preserve the neutral center and the positive offset under the stated mapping.

</details>

### Exercise 2

Split each bend into the ordered data bytes.

<details><summary>Answer 2</summary>

The low byte contains the remainder under the byte radix and the high byte its integer quotient, as displayed.

</details>

### Exercise 3

Why do the simultaneous main notes conflict?

<details><summary>Answer 3</summary>

Their half-open supports overlap on the same channel while requiring different channel bend values.

</details>

### Exercise 4

What does the distinct-channel control establish?

<details><summary>Answer 4</summary>

It removes this modeled scope conflict without changing offsets or byte values; receiver configuration remains untested.

</details>

### Exercise 5

What falsifies the proposed shared-channel realization?

<details><summary>Answer 5</summary>

Concurrent unequal bend requirements on one conventional channel reject simultaneous independent realization under the declared model.

</details>

## Source-assisted learner task

Build the note/channel/offset table unaided, then draft a GA tuning transport note with sensitivity and byte order. Leave receiver support and channel allocation open.

Retain your unaided answer before consulting a source or calculator. Then identify a precise source passage and revision, record every kind of assistance and keep the original answer alongside any correction. A proposed agent workflow or DSL must preserve the manual result and its countercase before its convenience can be assessed. If required inputs are absent, leave the decision unresolved rather than substituting a plausible value.

Write a falsifier as an observable disagreement with the stated rule, then say what additional observation would be needed at the next boundary. Use the exercise answers as prepared checks, not as a record of your attempt. The fixed packet contains a separate prepared criterion for every exercise; all learner decisions remain undecided until an actual response and review are retained. Report assistance, corrections and remaining limits with the final note so that arithmetic correctness is not confused with independent recall, musician judgment or runtime acceptance.
