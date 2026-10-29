---
module_id: "pm-014-select-a-budgeted-portfolio-with-prerequisite-closure"
department: "product-management"
course: "Select a Budgeted Portfolio with Prerequisite Closure"
title: "Select a Budgeted Portfolio with Prerequisite Closure"
level: "intermediate"
prerequisites: ["pm-008-size-a-fifty-course-batch-by-review-capacity"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Select a Budgeted Portfolio with Prerequisite Closure

> This is an authored mathematical or logical case supported by bounded source reading. Human technical review, fluent-language review, learner attempts, runtime execution, production adoption and publication decisions remain undecided.

A Learn coordinator must compare optional verification improvements for a future workflow. An attractive feature requires a shared foundation, but its headline estimate lists only the feature’s own cost. Choosing the best-looking value ratio can then produce a portfolio that fits the budget on paper while omitting its prerequisite. Count the whole selected dependency closure before comparing benefit.

The authored catalogue contains a foundation with no independent value, an improvement that requires it, and independent alternatives. Each chosen item contributes its cost and value once. A subset is admissible only when its prerequisites are also selected and its total resource charge fits the budget. Enumerating the small catalogue makes every rejected proposal inspectable and retains ties instead of inventing a unique optimum.

The fixed optimum chooses the independent alternatives. A tempting feature-plus-small-item proposal fails closure once its foundation is included. The control removes the prerequisite and changes the optimum. That altered premise is intentionally consequential: it cannot be justified by renaming the foundation an implementation detail or charging it to an unspecified future budget.

Google’s knapsack guide defines the ordinary capacity-constrained value problem. Our extra closure rule is an explicitly authored extension, not a claim about that solver’s input schema. The capacity prerequisite evaluates a fixed production request; this lesson evaluates optional work under invented comparable points. It does not reduce the user-requested course scope or waive required review. A real portfolio decision would need defensible value scales, measured costs, dependency evidence and authority to choose among admissible alternatives. A direct subset table is the baseline before proposing any agent optimizer or planning DSL.

## Sources and project boundary

The retained Learn helper separates metadata, title and body, and indexes English module identities. Inspect that representation when naming the artifact and its revision. It does not implement this lesson’s model or supply its invented inputs.

[Prerequisite: pm-008-size-a-fifty-course-batch-by-review-capacity](../../product-management/en/pm-008-size-a-fifty-course-batch-by-review-capacity.md)

[Retained project artifact](../../../../scripts/streeling-lib.mjs)

[Primary reading](https://developers.google.com/optimization/pack/knapsack)

## Fixed model and negative control

```json
{
  "values": {
    "items": {
      "A": {
        "cost": 3,
        "value": 0,
        "requires": []
      },
      "B": {
        "cost": 3,
        "value": 8,
        "requires": [
          "A"
        ]
      },
      "C": {
        "cost": 4,
        "value": 7,
        "requires": []
      },
      "D": {
        "cost": 2,
        "value": 3,
        "requires": []
      }
    },
    "budget": 6
  },
  "formula": "Enumerate all item subsets including empty. Feasible iff total cost<=budget and every selected item has all requires selected. Sum each selected item cost/value once. Maximize total value; retain every optimal subset, sorted lexicographically.",
  "expected": {
    "feasible_count": 7,
    "optimal_sets": [
      [
        "C",
        "D"
      ]
    ],
    "optimal_costs": [
      6
    ],
    "optimal_value": 10
  },
  "negative_control": {
    "values": {
      "items": {
        "A": {
          "cost": 3,
          "value": 0,
          "requires": []
        },
        "B": {
          "cost": 3,
          "value": 8,
          "requires": []
        },
        "C": {
          "cost": 4,
          "value": 7,
          "requires": []
        },
        "D": {
          "cost": 2,
          "value": 3,
          "requires": []
        }
      },
      "budget": 6
    },
    "expected": {
      "feasible_count": 9,
      "optimal_sets": [
        [
          "B",
          "D"
        ]
      ],
      "optimal_costs": [
        5
      ],
      "optimal_value": 11
    },
    "why": "Removing the real prerequisite changes which subset is admissible, not merely its display order."
  },
  "input_types": {
    "items": "mapping of item to nonnegative integer cost/value and prerequisite-name list",
    "budget": "nonnegative integer"
  },
  "assumptions": [
    "All named prerequisites are items; acyclic dependency model.",
    "Values are additive stipulated comparable points; costs are charged once per selected item."
  ],
  "limits": "No portfolio value, real review cost, authorization or scope change is measured. This does not alter the user-requested course batch."
}
```

### Exercise 1

Why is the tempting feature pair infeasible?

<details><summary>Answer 1</summary>

Subset `[B,D]` costs `5` directly but omits prerequisite `A`. Its closure `[A,B,D]` costs `8`, exceeding budget `6`. The apparent saving comes from a missing obligation.

</details>

### Exercise 2

Find the fixed optimal portfolio.

<details><summary>Answer 2</summary>

There are `7` feasible subsets. The optimum is `[C,D]`, costing `6` with value `10`. Both prerequisites and budget are satisfied.

</details>

### Exercise 3

Apply the prerequisite-free control.

<details><summary>Answer 3</summary>

There are `9` feasible subsets; `[B,D]` now costs `5` and has value `11`. This result requires the altered dependency premise, not a faster optimizer.

</details>

### Exercise 4

May a shared foundation be charged repeatedly?

<details><summary>Answer 4</summary>

Not under the declared model: each selected item is charged once. Repeated charging would define another cost model and could reverse the portfolio comparison.

</details>

### Exercise 5

Does this optimize the current course delivery scope?

<details><summary>Answer 5</summary>

No. The actual requested batch remains the scope authority. These fictional optional improvements illustrate closure; applying a real selection requires actual costs, values and explicit decision authority.

</details>

## Source-assisted learner task

Compare hypothetical optional verification improvements without dropping their prerequisite work.

**Direct manual baseline:** Enumerate all subsets and mark prerequisite closure and total cost before scoring value.

**Falsifier:** A selected portfolio fits only because a required foundation is missing or charged elsewhere without justification.

Save a first answer before opening the solutions. Identify the input types, the comparison boundary and the quantity that the task asks you to preserve. Draw the smallest table or diagram that permits every intermediate result to be checked. Keep an unexpected result; editing the premises until a preferred conclusion appears would destroy the counterexample.

Read the linked prerequisite and the bounded primary passage. Record the source revision, the definition actually used and the assumptions you imported. The project artifact supplies a real representation to inspect, while the fixed model supplies invented inputs. Neither a document name nor an accessible URL establishes a production result. Explain what would need to be observed before using the calculation in an operational decision.

State the direct manual baseline and its falsifier before proposing a composable DSL or an agent abstraction. Ask an assistant to challenge your manual answer only after saving it. Retain the prompt, the reply, the source passage it cites and the correction you accept or reject. A shorter expression is useful only if it preserves the operation, the control and the refusal boundary. Compare it with a plain table first.

Submit the original answer, intermediate quantities, corrected answer and control together. Label source consultation and calculator use as assistance. A future dogfood comparison should use the same task version and retain failures as well as successes; otherwise changing the question can masquerade as improvement. The prepared criteria below remain undecided until a learner actually attempts the task. An answer key and an author check establish neither learning nor adoption.

## Prepared learner criteria

- Exercise 1: Why is the tempting feature pair infeasible? — Decision undecided.
- Exercise 2: Find the fixed optimal portfolio. — Decision undecided.
- Exercise 3: Apply the prerequisite-free control. — Decision undecided.
- Exercise 4: May a shared foundation be charged repeatedly? — Decision undecided.
- Exercise 5: Does this optimize the current course delivery scope? — Decision undecided.

[Fixed unit packet](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-b.json) · [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25-b/journal.md)
