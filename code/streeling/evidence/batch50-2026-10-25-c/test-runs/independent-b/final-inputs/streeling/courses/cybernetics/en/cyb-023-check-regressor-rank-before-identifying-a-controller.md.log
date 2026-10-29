---
module_id: "cyb-023-check-regressor-rank-before-identifying-a-controller"
department: "cybernetics"
course: "Check Regressor Rank before Identifying a Controller"
title: "Check Regressor Rank before Identifying a Controller"
level: "intermediate"
prerequisites: ["cyb-018-reconstruct-hidden-state-from-distinct-dynamics", "cyb-016-test-feedforward-against-disturbance-mismatch"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Check Regressor Rank before Identifying a Controller

> This is an authored finite mathematical or logical case supported by bounded source reading. Human technical review, fluent-language review, learner attempts, native runtime execution, production adoption and publication decisions remain undecided.

Before an agent tunes a response rule, it must know whether the recorded experiments can distinguish the unknown parameters. More rows do not necessarily create more independent information. Repeating the same ratio of input components can leave several parameter vectors observationally identical, even when every fitted response is exact.

Write the stipulated response as a design matrix times a parameter vector. Inspect the Gram matrix and its rank before solving the normal equations. A nonsingular Gram matrix gives a unique least-squares solution for this finite linear problem. A singular matrix exposes directions in parameter space that the experiments never distinguish. Reporting an arbitrary inverse or silently adding a regularizer would change the question from identification by data to selection by another assumption.

The fixed design excites independent directions and recovers the declared parameter pair. The control has proportional columns: different pairs with the same relevant sum reproduce every response. The course uses finite full rank as a concrete excitation check; it does not establish a uniform persistent-excitation condition over an infinite signal. Measurement noise, model mismatch and conditioning would need separate evidence. A future experiment DSL should preserve regressors and trial identity, not just a small residual.

## Sources and project boundary

[Prerequisite: cyb-018-reconstruct-hidden-state-from-distinct-dynamics](../../cybernetics/en/cyb-018-reconstruct-hidden-state-from-distinct-dynamics.md)

[Prerequisite: cyb-016-test-feedforward-against-disturbance-mismatch](../../cybernetics/en/cyb-016-test-feedforward-against-disturbance-mismatch.md)

[Retained project artifact](../../../../scripts/streeling-lib.mjs)

[Primary reading](https://underactuated.csail.mit.edu/sysid.html)

## Fixed model and negative control

```json
{
  "values": {
    "X": [
      [
        1,
        0
      ],
      [
        0,
        1
      ],
      [
        1,
        1
      ]
    ],
    "y": [
      2,
      3,
      5
    ]
  },
  "formula": "Compute Gram=X^T*X, rhs=X^T*y, exact rank and determinant. If full column rank solve Gram*theta=rhs; otherwise unique_parameters=null and report rank deficiency without pseudoinverse.",
  "expected": {
    "gram": [
      [
        2,
        1
      ],
      [
        1,
        2
      ]
    ],
    "rhs": [
      7,
      8
    ],
    "determinant": 3,
    "rank": 2,
    "unique_parameters": [
      2,
      3
    ]
  },
  "negative_control": {
    "values": {
      "X": [
        [
          1,
          1
        ],
        [
          2,
          2
        ],
        [
          3,
          3
        ]
      ],
      "y": [
        5,
        10,
        15
      ]
    },
    "expected": {
      "gram": [
        [
          14,
          14
        ],
        [
          14,
          14
        ]
      ],
      "rhs": [
        70,
        70
      ],
      "determinant": 0,
      "rank": 1,
      "unique_parameters": null
    },
    "why": "Repeated proportional regressors identify only a sum of parameters."
  },
  "input_types": {
    "X": "nonempty rational matrix with two columns",
    "y": "same-length rational response vector"
  },
  "assumptions": [
    "All inputs are stipulated teaching values, not measured project events.",
    "Only the declared finite objective and constraints are represented."
  ],
  "limits": "Finite rank is not a uniform infinite-horizon persistent-excitation guarantee, noise robustness or an identified production controller."
}
```

## Source-assisted task and journal

**Direct manual baseline:** Form the design and Gram matrices by hand and exhibit a nonzero null direction when rank is deficient.

**Falsifier:** The report claims unique identification from a singular design, or treats a regularizer-selected vector as uniquely supported by the trials.

Read the prerequisite and the retained project representation before treating this example as a proposed feature. The linked Learn source helper extracts metadata, title and body, then indexes English module identities. That is an actual representation boundary to inspect; it supplies neither the invented inputs nor an implementation of this mathematical operation. Keep the source revision attached to the reading note so that a later change cannot silently inherit this inspection.

For the source-assisted task, reproduce the fixed case directly before asking an assistant to explain it. Use the input types and assumptions in the packet as part of the question, preserve intermediate quantities and compare the declared negative control. Ask the assistant to identify which premise makes the two results differ. A plausible explanation that never calculates the changed input has not demonstrated the operation.

Record the exact question, supplied sources, answer, assistance history and any correction in the journal. The prepared corrected answers below are an answer key, not a learner attempt. An independent model check can establish the finite arithmetic while still missing a poor prompt or a misleading translation. Human technical review, fluent-language review, learner acceptance, native runtime behavior, production adoption and publication decisions therefore remain undecided. Retain a failed check and its diagnosis before recording a successful replay; do not replace an original failure with the corrected result.

## Corrected exercises

### Exercise 1

Compute the fixed Gram matrix.

> **Answer:** The Gram matrix is `[[2,1],[1,2]]`, determinant `3`, rank `2`; the unique parameters are `[2,3]`.

### Exercise 2

Diagnose the collinear control.

> **Answer:** The Gram matrix `[[14,14],[14,14]]` has determinant `0` and rank `1`. Parameter pairs `[2,3]` and `[1,4]` both fit.

### Exercise 3

Would duplicating the control rows identify both parameters?

> **Answer:** No. Duplicating proportional rows changes their weight but not the missing direction. A new independent regressor is needed.

### Exercise 4

What does the retained project helper actually establish?

> **Answer:** It extracts metadata, title and body and indexes English module identities. Reading that code supports this representation claim; it does not execute the authored model or validate a live project feature.

### Exercise 5

Which acceptance decisions can the corrected answer key close?

> **Answer:** None of the human or learner gates. A real attempt needs its actual answer, assistance history and correction; the finite case does not establish native runtime behavior, production adoption or release approval.

## Prepared learner criteria

These criteria are prepared; every learner decision remains undecided.

- Exercise 1: The Gram matrix is `[[2,1],[1,2]]`, determinant `3`, rank `2`; the unique parameters are `[2,3]`.
- Exercise 2: The Gram matrix `[[14,14],[14,14]]` has determinant `0` and rank `1`. Parameter pairs `[2,3]` and `[1,4]` both fit.
- Exercise 3: No. Duplicating proportional rows changes their weight but not the missing direction. A new independent regressor is needed.
- Exercise 4: It extracts metadata, title and body and indexes English module identities. Reading that code supports this representation claim; it does not execute the authored model or validate a live project feature.
- Exercise 5: None of the human or learner gates. A real attempt needs its actual answer, assistance history and correction; the finite case does not establish native runtime behavior, production adoption or release approval.

[Fixed unit packet](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-b.json) · [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)
