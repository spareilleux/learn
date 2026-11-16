---
module_id: "cyb-017-limit-command-change-separately-from-amplitude"
department: "cybernetics"
course: "Limit Command Change Separately from Amplitude"
level: "intermediate"
prerequisites: ["cyb-011-prevent-integral-accumulation-under-saturation"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Limit Command Change Separately from Amplitude

> This lesson uses authored fixed inputs and inspected source passages. The numbers, histories and labels are teaching constructions. Human technical review, fluent-language review, learner attempts, runtime execution, production adoption and publication decisions remain undecided.

A command can stay inside its allowed range and still jump too quickly. The saturation prerequisite caps magnitude and tracks an integrator. This lesson introduces no integrator: it limits the difference between successive applied commands. An agent must retain the previous applied value and sampling interval to calculate that constraint.

The cited rate-constraint paper’s abstract distinguishes rate constraints as a modeling concern. Our two clipping steps are independently declared and are not that paper’s optimization method. First satisfy the amplitude interval, then the interval reachable from the previous command. Starting inside the amplitude bounds ensures these intervals overlap.

The output need not equal the request at the end of a short sequence. That remaining discrepancy is an intended consequence of the constraint. Reporting only whether the amplitude stayed in range hides the new requirement. A proposed controller DSL should name both units and carry the applied state; substituting the last requested value would change the next feasible interval.

## Sources and project boundary

The retained Learn helper separates frontmatter, heading and body in `parseModule`, and indexes English module names in `englishModuleKeys`. Those inspected representations let a task name its source and metadata; they do not implement the authored operation. The retained practice record instead distinguishes retrieval metrics from learner evidence. Inspect the particular file linked below and retain only the observation it actually supports. No model input in this lesson was estimated from that file.

[Prerequisite: cyb-011-prevent-integral-accumulation-under-saturation](../../cybernetics/en/cyb-011-prevent-integral-accumulation-under-saturation.md)

[Retained project artifact](../../../../scripts/streeling-lib.mjs)

[Retained project artifact](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Primary reading](https://arxiv.org/abs/1903.05508)

## Fixed model and control

```json
{
  "values": {
    "requests": [
      4,
      4,
      0
    ],
    "initial_command": 0,
    "rate_per_second": 2,
    "dt_seconds": 0.5,
    "lower": 0,
    "upper": 4
  },
  "formula": "First clip requested amplitude to [lower,upper]; then clip it to [previous-rate*dt,previous+rate*dt]. Initial command is inside amplitude range.",
  "expected": {
    "amplitude_only": [
      4,
      4,
      0
    ],
    "commands": [
      1,
      2,
      1
    ],
    "deltas": [
      1,
      1,
      -1
    ],
    "final": 1
  },
  "negative_control": {
    "values": {
      "requests": [
        4,
        4,
        0
      ],
      "initial_command": 0,
      "rate_per_second": 8,
      "dt_seconds": 0.5,
      "lower": 0,
      "upper": 4
    },
    "expected": {
      "amplitude_only": [
        4,
        4,
        0
      ],
      "commands": [
        4,
        4,
        0
      ],
      "deltas": [
        4,
        0,
        -4
      ],
      "final": 0
    },
    "why": "A wide rate bound makes these requests feasible without changing the amplitude range."
  },
  "assumptions": [
    "Uniform positive time step, initial command within bounds, no plant.",
    "Rate bound applies to applied command differences, not derivative estimates."
  ],
  "limits": "No physical actuator, settling guarantee or anti-windup policy was tested.",
  "input_types": {
    "requests": "list<real command units>",
    "initial_command": "real",
    "rate_per_second": "nonnegative real command units/second",
    "dt_seconds": "positive real",
    "lower": "real",
    "upper": "real >= lower"
  }
}
```

### Exercise 1

Compute the allowed change per update.

<details><summary>Answer 1</summary>

`2*0.5=1` command unit. A rate per second must be multiplied by the actual interval.

</details>

### Exercise 2

Compute applied commands and differences.

<details><summary>Answer 2</summary>

Commands are `[1,2,1]` and differences `[1,1,-1]`. Every difference satisfies the declared bound.

</details>

### Exercise 3

Why does the final request not produce zero output?

<details><summary>Answer 3</summary>

The previous command is `2`; only a change of magnitude `1` is permitted, so the next applied value is `1`.

</details>

### Exercise 4

Apply the wide-rate control.

<details><summary>Answer 4</summary>

Commands are `[4,4,0]`, differences `[4,0,-4]` and final value `0`. Amplitude bounds are unchanged.

</details>

### Exercise 5

Would halving dt preserve the allowed jump?

<details><summary>Answer 5</summary>

No. At the same rate the per-update allowance halves. This statement concerns the constraint, not a measured actuator response.

</details>

## Source-assisted learner task

Annotate a fictional GA load-control trace with both amplitude and change limits.

**Direct manual baseline:** Make request, amplitude-clipped value, previous applied value and feasible-interval columns.

**Falsifier:** An applied jump exceeds rate times interval or the next interval uses the previous request instead of applied command.

Save a first answer before opening the corrected exercises. Copy the input identities and units, write the intermediate quantities, and distinguish the calculation from the interpretation. A correct number with the wrong denominator, state boundary or counting unit does not meet the task. Retain a surprising intermediate result rather than changing the input to make the final answer look plausible.

Read the cited primary passage within the scope recorded in the packet. Compare its actual definition with the authored rule in the fixed model. The reference may motivate a concept without specifying our entire model. Record the version or date, the passage used and the exact assumption you imported. An accessible page or a successful file read is not evidence that a claim has been verified.

Inspect the retained project artifact and one prerequisite. Separate what the file actually represents from what this new task hypothesizes. Preserve source revision and assistance history. Ask an assistant to challenge an assumption only after saving the manual baseline, then keep its prompt, reply, accepted correction and rejected suggestion. Source lookup and calculator use are permitted assistance, not unaided recall.

Run the changed input through the same reasoning on paper. State the falsifier before proposing an agent abstraction or a composable DSL expression. If an abstraction drops the counterexample or changes the accepted endpoint, it fails this task even if its response is shorter. Compare a direct table or typed record first; no new language or production engine is required.

Submit original and corrected answers together with the control result, source passage and remaining uncertainty. The packet prepares a separate criterion for each exercise, with every learner decision undecided. An answer key, a byte hash and an author self-check are different evidence from an actual learner attempt. A future dogfood comparison must retain actual attempts on the same versioned task and the direct baseline before claiming a useful change.

[Fixed unit packet](../../../../code/streeling/evidence/batch50-2026-10-25/unit-b.json) · [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
