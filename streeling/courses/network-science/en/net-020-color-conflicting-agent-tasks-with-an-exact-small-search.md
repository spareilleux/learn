---
module_id: "net-020-color-conflicting-agent-tasks-with-an-exact-small-search"
department: "network-science"
course: "Color Conflicting Agent Tasks with an Exact Small Search"
title: "Color Conflicting Agent Tasks with an Exact Small Search"
level: "intermediate"
prerequisites: ["net-017-match-simultaneous-roles-without-double-booking", "net-007-separate-dag-readiness-from-admission"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Color Conflicting Agent Tasks with an Exact Small Search

> This is an authored finite mathematical or logical case supported by bounded source reading. Human technical review, fluent-language review, learner attempts, native runtime execution, production adoption and publication decisions remain undecided.

Several ready agent tasks may still be unable to run in the same slot because they edit the same resource. A precedence DAG does not capture every such incompatibility. An undirected conflict graph places an edge between tasks that cannot share a slot. A color identifies a slot; it does not identify a worker or prove that any worker has the required capability.

Search assignments with increasing numbers of colors. Accept an assignment only if every edge has differently colored endpoints. The first feasible color count proves optimality for this fully enumerated small graph. To make the displayed assignment deterministic, keep the lexicographically first color vector in the declared node order. Equivalent color renamings do not change the minimum slot count.

The fixed cycle needs fewer slots than its control, which adds a diagonal and therefore a triangle. A triangle provides a direct lower bound because all its vertices conflict with one another. The documentation describes greedy coloring as an attempt to use few colors; it does not promise the exact optimum supplied by our exhaustive search. Task duration, worker availability, memory limits and dependencies between slots are absent. A future scheduling DSL must not treat this simplified coloring as a complete concurrent-execution plan.

## Sources and project boundary

[Prerequisite: net-017-match-simultaneous-roles-without-double-booking](../../network-science/en/net-017-match-simultaneous-roles-without-double-booking.md)

[Prerequisite: net-007-separate-dag-readiness-from-admission](../../network-science/en/net-007-separate-dag-readiness-from-admission.md)

[Retained project artifact](../../../../scripts/streeling-lib.mjs)

[Primary reading](https://networkx.org/documentation/stable/reference/algorithms/generated/networkx.algorithms.coloring.greedy_color.html)

## Fixed model and negative control

```json
{
  "values": {
    "nodes": [
      "A",
      "B",
      "C",
      "D"
    ],
    "edges": [
      [
        "A",
        "B"
      ],
      [
        "B",
        "C"
      ],
      [
        "C",
        "D"
      ],
      [
        "D",
        "A"
      ]
    ]
  },
  "formula": "For k from 1 to len(nodes), enumerate color vectors in lexicographic order from range(k)^len(nodes); valid iff every undirected edge has different endpoint colors. Return first feasible k and first valid vector.",
  "expected": {
    "chromatic_number": 2,
    "colors": [
      0,
      1,
      0,
      1
    ]
  },
  "negative_control": {
    "values": {
      "nodes": [
        "A",
        "B",
        "C",
        "D"
      ],
      "edges": [
        [
          "A",
          "B"
        ],
        [
          "B",
          "C"
        ],
        [
          "C",
          "D"
        ],
        [
          "D",
          "A"
        ],
        [
          "A",
          "C"
        ]
      ]
    },
    "expected": {
      "chromatic_number": 3,
      "colors": [
        0,
        1,
        2,
        1
      ]
    },
    "why": "A new conflict closes a triangle and raises the required slot count."
  },
  "input_types": {
    "nodes": "ordered distinct node strings",
    "edges": "simple undirected pairs; edge means simultaneous-slot incompatibility"
  },
  "assumptions": [
    "All inputs are stipulated teaching values, not measured project events.",
    "Only the declared finite objective and constraints are represented."
  ],
  "limits": "No actual schedule, capability assignment, equal-duration guarantee, worker availability or greedy-optimality theorem is claimed."
}
```

## Source-assisted task and journal

**Direct manual baseline:** Draw the conflict graph and enumerate small slot assignments, checking every edge.

**Falsifier:** A proposed simultaneous slot contains the endpoints of a conflict edge, or a greedy result is labelled globally minimal without proof.

Read the prerequisite and the retained project representation before treating this example as a proposed feature. The linked Learn source helper extracts metadata, title and body, then indexes English module identities. That is an actual representation boundary to inspect; it supplies neither the invented inputs nor an implementation of this mathematical operation. Keep the source revision attached to the reading note so that a later change cannot silently inherit this inspection.

For the source-assisted task, reproduce the fixed case directly before asking an assistant to explain it. Use the input types and assumptions in the packet as part of the question, preserve intermediate quantities and compare the declared negative control. Ask the assistant to identify which premise makes the two results differ. A plausible explanation that never calculates the changed input has not demonstrated the operation.

Record the exact question, supplied sources, answer, assistance history and any correction in the journal. The prepared corrected answers below are an answer key, not a learner attempt. An independent model check can establish the finite arithmetic while still missing a poor prompt or a misleading translation. Human technical review, fluent-language review, learner acceptance, native runtime behavior, production adoption and publication decisions therefore remain undecided. Retain a failed check and its diagnosis before recording a successful replay; do not replace an original failure with the corrected result.

## Corrected exercises

### Exercise 1

Color the fixed conflict cycle.

> **Answer:** The first minimum coloring is `[0,1,0,1]`, using `2` slots. Every edge has distinct endpoint colors.

### Exercise 2

Explain the diagonal control.

> **Answer:** Adding `[A,C]` creates a triangle. The minimum is `3`, with first coloring `[0,1,2,1]`.

### Exercise 3

Can a greedy result certify the minimum here?

> **Answer:** Not by itself. The exact search and graph lower bounds justify the minimum; a greedy assignment only demonstrates feasibility.

### Exercise 4

What does the retained project helper actually establish?

> **Answer:** It extracts metadata, title and body and indexes English module identities. Reading that code supports this representation claim; it does not execute the authored model or validate a live project feature.

### Exercise 5

Which acceptance decisions can the corrected answer key close?

> **Answer:** None of the human or learner gates. A real attempt needs its actual answer, assistance history and correction; the finite case does not establish native runtime behavior, production adoption or release approval.

## Prepared learner criteria

These criteria are prepared; every learner decision remains undecided.

- Exercise 1: The first minimum coloring is `[0,1,0,1]`, using `2` slots. Every edge has distinct endpoint colors.
- Exercise 2: Adding `[A,C]` creates a triangle. The minimum is `3`, with first coloring `[0,1,2,1]`.
- Exercise 3: Not by itself. The exact search and graph lower bounds justify the minimum; a greedy assignment only demonstrates feasibility.
- Exercise 4: It extracts metadata, title and body and indexes English module identities. Reading that code supports this representation claim; it does not execute the authored model or validate a live project feature.
- Exercise 5: None of the human or learner gates. A real attempt needs its actual answer, assistance history and correction; the finite case does not establish native runtime behavior, production adoption or release approval.

[Fixed unit packet](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-b.json) · [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)
