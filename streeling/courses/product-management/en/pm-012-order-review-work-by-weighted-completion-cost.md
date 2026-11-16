---
module_id: "pm-012-order-review-work-by-weighted-completion-cost"
department: "product-management"
course: "Order Review Work by Weighted Completion Cost"
level: "intermediate"
prerequisites: ["pm-003-review-queue-flow-metrics", "net-010-compute-critical-paths-with-resource-assumptions"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Order Review Work by Weighted Completion Cost

> This lesson uses authored fixed inputs and inspected source passages. The numbers, histories and labels are teaching constructions. Human technical review, fluent-language review, learner attempts, runtime execution, production adoption and publication decisions remain undecided.

A Learn review queue has one available reviewer. Two schedules finish the whole queue at the same time but leave different work waiting longer. Throughput and makespan do not choose between them. A prioritization claim needs a declared objective and defensible weights before an agent optimizes an order.

The OR-Tools job-shop reading names nonpreemption, precedence and exclusive resources, and optimizes makespan. Our much smaller case has no precedence constraints and deliberately chooses another objective: each job incurs its stated loss per tick until completion. Enumerate all orders rather than importing a solver or claiming a universal queue policy.

Compute completion, not just start, times. A short high-weight job can reduce total waiting cost when moved forward, but shortest-first alone need not be best once weights change. The control changes only weights and reverses the preferred first job. These fictional loss points are not measured reviewer minutes, moral priorities or permission to bypass review. A future dogfood comparison would need agreed costs and actual completion histories.

## Sources and project boundary

The retained Learn helper separates frontmatter, heading and body in `parseModule`, and indexes English module names in `englishModuleKeys`. Those inspected representations let a task name its source and metadata; they do not implement the authored operation. The retained practice record instead distinguishes retrieval metrics from learner evidence. Inspect the particular file linked below and retain only the observation it actually supports. No model input in this lesson was estimated from that file.

[Prerequisite: pm-003-review-queue-flow-metrics](../../product-management/en/pm-003-review-queue-flow-metrics.md)

[Prerequisite: net-010-compute-critical-paths-with-resource-assumptions](../../network-science/en/net-010-compute-critical-paths-with-resource-assumptions.md)

[Retained project artifact](../../../../scripts/streeling-lib.mjs)

[Retained project artifact](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Primary reading](https://developers.google.com/optimization/scheduling/job_shop)

## Fixed model and control

```json
{
  "values": {
    "jobs": [
      "A",
      "B",
      "C"
    ],
    "duration_ticks": {
      "A": 4,
      "B": 1,
      "C": 2
    },
    "weight_per_tick": {
      "A": 4,
      "B": 3,
      "C": 1
    },
    "baseline_order": [
      "A",
      "B",
      "C"
    ]
  },
  "formula": "Single nonpreemptive reviewer, all jobs ready at time zero. Completion time is cumulative duration. Cost=sum(weight[j]*completion[j]). Enumerate all permutations; choose minimum cost.",
  "expected": {
    "optimal_order": [
      "B",
      "A",
      "C"
    ],
    "optimal_completion": {
      "B": 1,
      "A": 5,
      "C": 7
    },
    "optimal_cost": 30,
    "baseline_cost": 38,
    "makespan": 7
  },
  "negative_control": {
    "values": {
      "jobs": [
        "A",
        "B",
        "C"
      ],
      "duration_ticks": {
        "A": 4,
        "B": 1,
        "C": 2
      },
      "weight_per_tick": {
        "A": 8,
        "B": 1,
        "C": 1
      },
      "baseline_order": [
        "A",
        "B",
        "C"
      ]
    },
    "expected": {
      "optimal_order": [
        "A",
        "B",
        "C"
      ],
      "optimal_completion": {
        "A": 4,
        "B": 5,
        "C": 7
      },
      "optimal_cost": 44,
      "baseline_cost": 44,
      "makespan": 7
    },
    "why": "Changing delay weights reverses the preferred first job despite identical durations and makespan."
  },
  "assumptions": [
    "All work available initially; one exclusive reviewer; no interruptions, deadlines or setup costs.",
    "Weights are stipulated cardinal delay loss per tick, not human importance or measured money."
  ],
  "limits": "No real review capacity, optimal general scheduler, quality tradeoff or authority to skip gates.",
  "input_types": {
    "jobs": "list<unique string>",
    "duration_ticks": "map<job,positive integer>",
    "weight_per_tick": "map<job,nonnegative real>",
    "baseline_order": "permutation<jobs>"
  }
}
```

### Exercise 1

Compute the baseline cost.

<details><summary>Answer 1</summary>

In `ABC`, completion times are `[4,5,7]`; cost is `4*4+3*5+1*7=38`. The makespan is `7`.

</details>

### Exercise 2

Compute the proposed order’s cost.

<details><summary>Answer 2</summary>

In `BAC`, completion times are `[1,5,7]`; cost is `3*1+4*5+1*7=30`. The makespan remains `7`.

</details>

### Exercise 3

How can optimality be checked without a solver?

<details><summary>Answer 3</summary>

Enumerate all `6` permutations and compute the declared objective for each. A feasible favorable order alone is not an optimality proof.

</details>

### Exercise 4

Apply the changed-weight control.

<details><summary>Answer 4</summary>

`ABC` is now optimal with cost `44`, while `BAC` costs `48`. Fixed durations do not imply fixed priority.

</details>

### Exercise 5

Would the best order permit skipping a learner gate?

<details><summary>Answer 5</summary>

No. An objective over eligible review jobs does not change eligibility or authority. Actual gate decisions and costs remain separate.

</details>

## Source-assisted learner task

Prepare a fictional Learn review-order card with an explicit delay-cost objective.

**Direct manual baseline:** Enumerate every order on paper and record completion times and weighted totals.

**Falsifier:** A proposed optimum has a larger cost than another feasible order or silently optimizes makespan instead.

Save a first answer before opening the corrected exercises. Copy the input identities and units, write the intermediate quantities, and distinguish the calculation from the interpretation. A correct number with the wrong denominator, state boundary or counting unit does not meet the task. Retain a surprising intermediate result rather than changing the input to make the final answer look plausible.

Read the cited primary passage within the scope recorded in the packet. Compare its actual definition with the authored rule in the fixed model. The reference may motivate a concept without specifying our entire model. Record the version or date, the passage used and the exact assumption you imported. An accessible page or a successful file read is not evidence that a claim has been verified.

Inspect the retained project artifact and one prerequisite. Separate what the file actually represents from what this new task hypothesizes. Preserve source revision and assistance history. Ask an assistant to challenge an assumption only after saving the manual baseline, then keep its prompt, reply, accepted correction and rejected suggestion. Source lookup and calculator use are permitted assistance, not unaided recall.

Run the changed input through the same reasoning on paper. State the falsifier before proposing an agent abstraction or a composable DSL expression. If an abstraction drops the counterexample or changes the accepted endpoint, it fails this task even if its response is shorter. Compare a direct table or typed record first; no new language or production engine is required.

Submit original and corrected answers together with the control result, source passage and remaining uncertainty. The packet prepares a separate criterion for each exercise, with every learner decision undecided. An answer key, a byte hash and an author self-check are different evidence from an actual learner attempt. A future dogfood comparison must retain actual attempts on the same versioned task and the direct baseline before claiming a useful change.

[Fixed unit packet](../../../../code/streeling/evidence/batch50-2026-10-25/unit-b.json) · [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
