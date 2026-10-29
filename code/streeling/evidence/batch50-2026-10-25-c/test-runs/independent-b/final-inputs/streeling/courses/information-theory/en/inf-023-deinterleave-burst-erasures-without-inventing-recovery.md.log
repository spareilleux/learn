---
module_id: "inf-023-deinterleave-burst-erasures-without-inventing-recovery"
department: "information-theory"
course: "Deinterleave Burst Erasures without Inventing Recovery"
title: "Deinterleave Burst Erasures without Inventing Recovery"
level: "intermediate"
prerequisites: ["inf-020-separate-parity-detection-from-correction", "inf-012-retain-event-order-in-a-handoff-summary"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Deinterleave Burst Erasures without Inventing Recovery

> This is an authored finite mathematical or logical case supported by bounded source reading. Human technical review, fluent-language review, learner attempts, native runtime execution, production adoption and publication decisions remain undecided.

A future guitar-audio transport may need to spread the effect of a short packet-loss burst. Interleaving changes where consecutive transmitted positions came from in the original block layout. That can reduce concentration of missing symbols within a block. It cannot recreate values that were never received, and no perceptual quality improvement follows from position counts alone.

Write the source blocks as a rectangular array and read columns for the interleaved wire order. Each wire index maps to a unique original row and column. Apply the declared erasure positions on the wire, then invert that position map into the source layout. Preserve an explicit missing marker. The reconstruction is a layout reconstruction, not reconstruction of the missing symbol values.

The control transmits the same symbols in row order. The identical burst now erases an entire original block rather than scattering losses across blocks. The total number of missing symbols stays unchanged. Any later error-correcting stage would need actual redundancy, a code specification and its own decoder tests. Buffering latency and receiver memory are also absent from the model; the RFC cautions that interleaving can add delay. A paper permutation table is the baseline before changing a live low-latency audio path.

## Sources and project boundary

[Prerequisite: inf-020-separate-parity-detection-from-correction](../../information-theory/en/inf-020-separate-parity-detection-from-correction.md)

[Prerequisite: inf-012-retain-event-order-in-a-handoff-summary](../../information-theory/en/inf-012-retain-event-order-in-a-handoff-summary.md)

[Retained project artifact](../../../../scripts/streeling-lib.mjs)

[Primary reading](https://www.rfc-editor.org/rfc/rfc8088.html)

## Fixed model and negative control

```json
{
  "values": {
    "blocks": [
      [
        "A",
        "B",
        "C"
      ],
      [
        "D",
        "E",
        "F"
      ],
      [
        "G",
        "H",
        "I"
      ]
    ],
    "order": "column-major",
    "erased_indices": [
      0,
      1,
      2
    ]
  },
  "formula": "Serialize rectangular blocks in declared row-major or column-major position order. Replace erased zero-based wire indices by null, inverse-map positions, then count nulls per original block. Do not infer erased values.",
  "expected": {
    "wire": [
      "A",
      "D",
      "G",
      "B",
      "E",
      "H",
      "C",
      "F",
      "I"
    ],
    "reconstructed": [
      [
        null,
        "B",
        "C"
      ],
      [
        null,
        "E",
        "F"
      ],
      [
        null,
        "H",
        "I"
      ]
    ],
    "missing_per_block": [
      1,
      1,
      1
    ],
    "missing_total": 3
  },
  "negative_control": {
    "values": {
      "blocks": [
        [
          "A",
          "B",
          "C"
        ],
        [
          "D",
          "E",
          "F"
        ],
        [
          "G",
          "H",
          "I"
        ]
      ],
      "order": "row-major",
      "erased_indices": [
        0,
        1,
        2
      ]
    },
    "expected": {
      "wire": [
        "A",
        "B",
        "C",
        "D",
        "E",
        "F",
        "G",
        "H",
        "I"
      ],
      "reconstructed": [
        [
          null,
          null,
          null
        ],
        [
          "D",
          "E",
          "F"
        ],
        [
          "G",
          "H",
          "I"
        ]
      ],
      "missing_per_block": [
        3,
        0,
        0
      ],
      "missing_total": 3
    },
    "why": "The same burst has different block concentration, but no values are recovered."
  },
  "input_types": {
    "blocks": "rectangular nonempty array of distinct symbol strings",
    "order": "row-major or column-major",
    "erased_indices": "distinct valid zero-based transmitted positions"
  },
  "assumptions": [
    "All inputs are stipulated teaching values, not measured project events.",
    "Only the declared finite objective and constraints are represented."
  ],
  "limits": "No redundancy, erasure correction, packet capture, perceptual benefit, latency measurement or implemented RTP payload is claimed."
}
```

## Source-assisted task and journal

**Direct manual baseline:** Draw the position permutation and inverse map, mark erased wire indices, and count missing cells manually.

**Falsifier:** A deinterleaver reports original lost symbols without a separately specified source of redundancy or retransmission.

Read the prerequisite and the retained project representation before treating this example as a proposed feature. The linked Learn source helper extracts metadata, title and body, then indexes English module identities. That is an actual representation boundary to inspect; it supplies neither the invented inputs nor an implementation of this mathematical operation. Keep the source revision attached to the reading note so that a later change cannot silently inherit this inspection.

For the source-assisted task, reproduce the fixed case directly before asking an assistant to explain it. Use the input types and assumptions in the packet as part of the question, preserve intermediate quantities and compare the declared negative control. Ask the assistant to identify which premise makes the two results differ. A plausible explanation that never calculates the changed input has not demonstrated the operation.

Record the exact question, supplied sources, answer, assistance history and any correction in the journal. The prepared corrected answers below are an answer key, not a learner attempt. An independent model check can establish the finite arithmetic while still missing a poor prompt or a misleading translation. Human technical review, fluent-language review, learner acceptance, native runtime behavior, production adoption and publication decisions therefore remain undecided. Retain a failed check and its diagnosis before recording a successful replay; do not replace an original failure with the corrected result.

## Corrected exercises

### Exercise 1

Write the interleaved wire order.

> **Answer:** Column reading gives `[A,D,G,B,E,H,C,F,I]`; indices `[0,1,2]` erase the first symbol of each block.

### Exercise 2

Compare the control loss counts.

> **Answer:** Interleaving gives `[1,1,1]` missing symbols per block; row order gives `[3,0,0]`. Both totals are `3`.

### Exercise 3

Can inverse permutation fill the missing values?

> **Answer:** No. Missing positions stay `null`; the permutation changes location but adds no redundant information.

### Exercise 4

What does the retained project helper actually establish?

> **Answer:** It extracts metadata, title and body and indexes English module identities. Reading that code supports this representation claim; it does not execute the authored model or validate a live project feature.

### Exercise 5

Which acceptance decisions can the corrected answer key close?

> **Answer:** None of the human or learner gates. A real attempt needs its actual answer, assistance history and correction; the finite case does not establish native runtime behavior, production adoption or release approval.

## Prepared learner criteria

These criteria are prepared; every learner decision remains undecided.

- Exercise 1: Column reading gives `[A,D,G,B,E,H,C,F,I]`; indices `[0,1,2]` erase the first symbol of each block.
- Exercise 2: Interleaving gives `[1,1,1]` missing symbols per block; row order gives `[3,0,0]`. Both totals are `3`.
- Exercise 3: No. Missing positions stay `null`; the permutation changes location but adds no redundant information.
- Exercise 4: It extracts metadata, title and body and indexes English module identities. Reading that code supports this representation claim; it does not execute the authored model or validate a live project feature.
- Exercise 5: None of the human or learner gates. A real attempt needs its actual answer, assistance history and correction; the finite case does not establish native runtime behavior, production adoption or release approval.

[Fixed unit packet](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-b.json) · [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)
