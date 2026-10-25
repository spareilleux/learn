---
module_id: "cyb-015-carry-covariance-through-smoothed-telemetry"
department: "cybernetics"
course: "Carry Covariance Through Smoothed Telemetry"
level: "intermediate"
prerequisites: ["cyb-010-separate-derivative-noise-from-plant-motion"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Carry Covariance Through Smoothed Telemetry

> This lesson uses authored fixed inputs and inspected source passages. The numbers, histories and labels are teaching constructions. Human technical review, fluent-language review, learner attempts, runtime execution, production adoption and publication decisions remain undecided.

A quiet agent dashboard is not necessarily a precise dashboard. Successive measurements can share an error source. Applying an independent-sample variance formula to correlated inputs can understate uncertainty even when the smoothing arithmetic is correct. The earlier derivative course already gives a recurrence; this lesson adds its finite uncertainty accounting.

NIST states an EWMA variance approximation for a long-running sequence and names independence conditions. Here only a short initialized sequence exists. Expand the recurrence into weights first, then apply the full covariance matrix. The off-diagonal terms matter because the errors can move together. A deterministic initial value also retains weight and can cause bias before the weights approach their long-run limit.

Use symbolic monitoring units throughout. Our expected level is a mathematical expectation under stipulated errors, not an observed average of project traces. Before proposing an agent smoothing default, retain initialization, covariance assumptions and the response delay that this constant-level model leaves out.

## Sources and project boundary

The retained Learn helper separates frontmatter, heading and body in `parseModule`, and indexes English module names in `englishModuleKeys`. Those inspected representations let a task name its source and metadata; they do not implement the authored operation. The retained practice record instead distinguishes retrieval metrics from learner evidence. Inspect the particular file linked below and retain only the observation it actually supports. No model input in this lesson was estimated from that file.

[Prerequisite: cyb-010-separate-derivative-noise-from-plant-motion](../../cybernetics/en/cyb-010-separate-derivative-noise-from-plant-motion.md)

[Retained project artifact](../../../../scripts/streeling-lib.mjs)

[Retained project artifact](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Primary reading](https://www.itl.nist.gov/div898/handbook/pmc/section3/pmc324.htm)

## Fixed model and control

```json
{
  "values": {
    "alpha": 0.5,
    "initial": 0,
    "true_level": 4,
    "error_covariance": [
      [
        4,
        2
      ],
      [
        2,
        4
      ]
    ]
  },
  "formula": "After two EWMA updates weights are [alpha*(1-alpha),alpha]; expected=sum(weights)*true_level+(1-alpha)^2*initial; bias=expected-true_level; variance=w^T*Cov*w.",
  "expected": {
    "weights": [
      0.25,
      0.5
    ],
    "expected_level": 3,
    "bias": -1,
    "variance": 1.75
  },
  "negative_control": {
    "values": {
      "alpha": 0.5,
      "initial": 0,
      "true_level": 4,
      "error_covariance": [
        [
          4,
          0
        ],
        [
          0,
          4
        ]
      ]
    },
    "expected": {
      "weights": [
        0.25,
        0.5
      ],
      "expected_level": 3,
      "bias": -1,
      "variance": 1.25
    },
    "why": "Removing cross-covariance changes variance while the initialized mean and bias stay fixed."
  },
  "assumptions": [
    "Two zero-mean errors with the stipulated covariance matrix; deterministic initial state.",
    "No feedback or changing true level."
  ],
  "limits": "Finite authored moments, not estimated GA noise, confidence intervals or closed-loop stability.",
  "input_types": {
    "alpha": "real in (0,1]",
    "initial": "real",
    "true_level": "real",
    "error_covariance": "positive semidefinite 2x2 matrix"
  }
}
```

### Exercise 1

Expand the measurement weights.

<details><summary>Answer 1</summary>

The weights are `[0.25,0.5]`; the initial state retains weight `0.25`. The measurement weights sum to `0.75`, so initialization still matters.

</details>

### Exercise 2

Compute the expectation and bias.

<details><summary>Answer 2</summary>

Expected level is `3`; bias relative to `4` is `-1`. Smoothing has not reached the stipulated true level after this finite history.

</details>

### Exercise 3

Compute variance with covariance.

<details><summary>Answer 3</summary>

Diagonal terms contribute `1.25`; the cross terms contribute `0.5`, giving `1.75`. Dropping covariance changes the calculation.

</details>

### Exercise 4

Apply the independent-error control.

<details><summary>Answer 4</summary>

Variance becomes `1.25`. Expected level remains `3` and bias `-1`; independence does not remove initialization bias.

</details>

### Exercise 5

Can a quieter display establish stability?

<details><summary>Answer 5</summary>

No. This model contains no plant or feedback. A future comparison needs actual errors, timing and task costs before choosing a policy.

</details>

## Source-assisted learner task

Prepare a two-update uncertainty note for fictional GA monitoring values.

**Direct manual baseline:** Expand both updates on paper, keep initial weight, and multiply the full covariance matrix.

**Falsifier:** A favorable variance ignores off-diagonal terms or applies the steady-state formula to this initialized finite case.

Save a first answer before opening the corrected exercises. Copy the input identities and units, write the intermediate quantities, and distinguish the calculation from the interpretation. A correct number with the wrong denominator, state boundary or counting unit does not meet the task. Retain a surprising intermediate result rather than changing the input to make the final answer look plausible.

Read the cited primary passage within the scope recorded in the packet. Compare its actual definition with the authored rule in the fixed model. The reference may motivate a concept without specifying our entire model. Record the version or date, the passage used and the exact assumption you imported. An accessible page or a successful file read is not evidence that a claim has been verified.

Inspect the retained project artifact and one prerequisite. Separate what the file actually represents from what this new task hypothesizes. Preserve source revision and assistance history. Ask an assistant to challenge an assumption only after saving the manual baseline, then keep its prompt, reply, accepted correction and rejected suggestion. Source lookup and calculator use are permitted assistance, not unaided recall.

Run the changed input through the same reasoning on paper. State the falsifier before proposing an agent abstraction or a composable DSL expression. If an abstraction drops the counterexample or changes the accepted endpoint, it fails this task even if its response is shorter. Compare a direct table or typed record first; no new language or production engine is required.

Submit original and corrected answers together with the control result, source passage and remaining uncertainty. The packet prepares a separate criterion for each exercise, with every learner decision undecided. An answer key, a byte hash and an author self-check are different evidence from an actual learner attempt. A future dogfood comparison must retain actual attempts on the same versioned task and the direct baseline before claiming a useful change.

[Fixed unit packet](../../../../code/streeling/evidence/batch50-2026-10-25/unit-b.json) · [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
