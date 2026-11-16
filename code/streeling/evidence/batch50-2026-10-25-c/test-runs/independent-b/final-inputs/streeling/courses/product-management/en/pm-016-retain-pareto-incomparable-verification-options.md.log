---
module_id: "pm-016-retain-pareto-incomparable-verification-options"
department: "product-management"
course: "Retain Pareto-Incomparable Verification Options"
title: "Retain Pareto-Incomparable Verification Options"
level: "intermediate"
prerequisites: ["pm-014-select-a-budgeted-portfolio-with-prerequisite-closure", "pm-004-craft-extension-release-decision"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Retain Pareto-Incomparable Verification Options

> This is an authored finite mathematical or logical case supported by bounded source reading. Human technical review, fluent-language review, learner attempts, native runtime execution, production adoption and publication decisions remain undecided.

A Learn coordinator compares optional verification workflows using setup effort and a stipulated defect count. One option can be cheaper while another has fewer defects. A single headline score would need an explicit exchange rule between those dimensions. Pareto comparison first identifies options that are unambiguously worse under all represented objectives.

Every objective in this case is minimized. An option dominates another when it is no worse in every coordinate and strictly better in at least one. Equality across all coordinates is not strict dominance. Compare every pair and retain the nondominated options. This partial order can leave several candidates, which is an honest result rather than an optimizer failure.

The fixed set contains a dominated option and several genuine tradeoffs. The control worsens another option enough that it becomes dominated too. Removing dominated choices does not decide among the remaining tradeoffs or show that they meet required release gates. Unrepresented dimensions, uncertain measurements and stakeholder priorities could change a real decision. The course uses fictional comparable coordinates, not measured course defects. A planning DSL should expose the nondominated set and the missing preference rule before announcing a unique recommendation.

## Sources and project boundary

[Prerequisite: pm-014-select-a-budgeted-portfolio-with-prerequisite-closure](../../product-management/en/pm-014-select-a-budgeted-portfolio-with-prerequisite-closure.md)

[Prerequisite: pm-004-craft-extension-release-decision](../../product-management/en/pm-004-craft-extension-release-decision.md)

[Retained project artifact](../../../../scripts/streeling-lib.mjs)

[Primary reading](https://web.stanford.edu/~boyd/cvxbook/bv_cvxslides.pdf)

## Fixed model and negative control

```json
{
  "values": {
    "names": [
      "A",
      "B",
      "C",
      "D"
    ],
    "objectives": [
      [
        2,
        5
      ],
      [
        4,
        2
      ],
      [
        5,
        6
      ],
      [
        3,
        4
      ]
    ]
  },
  "formula": "Minimize every coordinate. i dominates j iff all objectives[i]<=objectives[j] coordinatewise and at least one strict inequality. Return nondominated names and all ordered [dominator,dominated] pairs in name order.",
  "expected": {
    "nondominated": [
      "A",
      "B",
      "D"
    ],
    "dominance_pairs": [
      [
        "A",
        "C"
      ],
      [
        "B",
        "C"
      ],
      [
        "D",
        "C"
      ]
    ]
  },
  "negative_control": {
    "values": {
      "names": [
        "A",
        "B",
        "C",
        "D"
      ],
      "objectives": [
        [
          2,
          5
        ],
        [
          4,
          2
        ],
        [
          5,
          6
        ],
        [
          4,
          5
        ]
      ]
    },
    "expected": {
      "nondominated": [
        "A",
        "B"
      ],
      "dominance_pairs": [
        [
          "A",
          "C"
        ],
        [
          "A",
          "D"
        ],
        [
          "B",
          "C"
        ],
        [
          "B",
          "D"
        ],
        [
          "D",
          "C"
        ]
      ]
    },
    "why": "Worsening an option removes its distinct tradeoff without supplying a preference among survivors."
  },
  "input_types": {
    "names": "ordered distinct option strings",
    "objectives": "equal-length finite minimization vectors, one per option"
  },
  "assumptions": [
    "All inputs are stipulated teaching values, not measured project events.",
    "Only the declared finite objective and constraints are represented."
  ],
  "limits": "No observed defects, chosen product policy, approved release or subjective utility scale is supplied."
}
```

## Source-assisted task and journal

**Direct manual baseline:** Compare each option pair in a two-column objective table before constructing any weighted score.

**Falsifier:** A supposedly dominated option improves a represented objective, or the report invents a unique winner from incomparable survivors.

Read the prerequisite and the retained project representation before treating this example as a proposed feature. The linked Learn source helper extracts metadata, title and body, then indexes English module identities. That is an actual representation boundary to inspect; it supplies neither the invented inputs nor an implementation of this mathematical operation. Keep the source revision attached to the reading note so that a later change cannot silently inherit this inspection.

For the source-assisted task, reproduce the fixed case directly before asking an assistant to explain it. Use the input types and assumptions in the packet as part of the question, preserve intermediate quantities and compare the declared negative control. Ask the assistant to identify which premise makes the two results differ. A plausible explanation that never calculates the changed input has not demonstrated the operation.

Record the exact question, supplied sources, answer, assistance history and any correction in the journal. The prepared corrected answers below are an answer key, not a learner attempt. An independent model check can establish the finite arithmetic while still missing a poor prompt or a misleading translation. Human technical review, fluent-language review, learner acceptance, native runtime behavior, production adoption and publication decisions therefore remain undecided. Retain a failed check and its diagnosis before recording a successful replay; do not replace an original failure with the corrected result.

## Corrected exercises

### Exercise 1

Find the fixed nondominated set.

> **Answer:** The survivors are `[A,B,D]`. Each dominates `C`, but none dominates another survivor.

### Exercise 2

Apply the worsened-option control.

> **Answer:** With `D=[4,5]`, both `A` and `B` dominate `D`. The nondominated set is `[A,B]`.

### Exercise 3

Can the surviving set justify a unique choice?

> **Answer:** No. Pareto filtering retains tradeoffs. Choosing among them requires declared priorities and all mandatory constraints.

### Exercise 4

What does the retained project helper actually establish?

> **Answer:** It extracts metadata, title and body and indexes English module identities. Reading that code supports this representation claim; it does not execute the authored model or validate a live project feature.

### Exercise 5

Which acceptance decisions can the corrected answer key close?

> **Answer:** None of the human or learner gates. A real attempt needs its actual answer, assistance history and correction; the finite case does not establish native runtime behavior, production adoption or release approval.

## Prepared learner criteria

These criteria are prepared; every learner decision remains undecided.

- Exercise 1: The survivors are `[A,B,D]`. Each dominates `C`, but none dominates another survivor.
- Exercise 2: With `D=[4,5]`, both `A` and `B` dominate `D`. The nondominated set is `[A,B]`.
- Exercise 3: No. Pareto filtering retains tradeoffs. Choosing among them requires declared priorities and all mandatory constraints.
- Exercise 4: It extracts metadata, title and body and indexes English module identities. Reading that code supports this representation claim; it does not execute the authored model or validate a live project feature.
- Exercise 5: None of the human or learner gates. A real attempt needs its actual answer, assistance history and correction; the finite case does not establish native runtime behavior, production adoption or release approval.

[Fixed unit packet](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-b.json) · [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)
