---
module_id: "cyb-016-test-feedforward-against-disturbance-mismatch"
department: "cybernetics"
course: "Test Feedforward Against Disturbance Mismatch"
level: "intermediate"
prerequisites: ["cyb-010-separate-derivative-noise-from-plant-motion"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Test Feedforward Against Disturbance Mismatch

> This lesson uses authored fixed inputs and inspected source passages. The numbers, histories and labels are teaching constructions. Human technical review, fluent-language review, learner attempts, runtime execution, production adoption and publication decisions remain undecided.

An agent knows an incoming load is expected and proposes compensating before observing an output error. That is a different information path from residual feedback. The direct baseline ignores the disturbance estimate; the proposed command subtracts it before scaling by the assumed plant gain.

The inspected official Caltech extraction describes measured-disturbance feedforward and its dependence on plant knowledge. Only that extracted passage was available; full-text fetching failed. Our static scalar equation is an authored simplification, with no transfer functions or production tuning inferred from the reading. It makes measurement mismatch visible without hiding it in a controller trace.

Calculate actual output using actual disturbance, not the estimate used to choose the command. Otherwise the model would certify its own prediction. Compare absolute residuals with the direct baseline. The changed-input control deliberately supplies a bad estimate: a mechanism that helps one case can harm another. Any DSL shorthand must retain which quantities are assumed and which would need measurement.

## Sources and project boundary

The retained Learn helper separates frontmatter, heading and body in `parseModule`, and indexes English module names in `englishModuleKeys`. Those inspected representations let a task name its source and metadata; they do not implement the authored operation. The retained practice record instead distinguishes retrieval metrics from learner evidence. Inspect the particular file linked below and retain only the observation it actually supports. No model input in this lesson was estimated from that file.

[Prerequisite: cyb-010-separate-derivative-noise-from-plant-motion](../../cybernetics/en/cyb-010-separate-derivative-noise-from-plant-motion.md)

[Retained project artifact](../../../../scripts/streeling-lib.mjs)

[Retained project artifact](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Primary reading](https://www.cds.caltech.edu/~murray/books/AM08/pdf/cds101-complete_20Sep07.pdf)

## Fixed model and control

```json
{
  "values": {
    "target": 10,
    "plant_gain": 2,
    "disturbance": 4,
    "measured_disturbance": 3,
    "assumed_gain": 2
  },
  "formula": "No compensation: u=target/assumed_gain. Feedforward: u=(target-measured_disturbance)/assumed_gain. Actual y=plant_gain*u+disturbance; error=y-target.",
  "expected": {
    "baseline_command": 5,
    "baseline_output": 14,
    "baseline_error": 4,
    "command": 3.5,
    "output": 11,
    "error": 1
  },
  "negative_control": {
    "values": {
      "target": 10,
      "plant_gain": 2,
      "disturbance": 4,
      "measured_disturbance": 10,
      "assumed_gain": 2
    },
    "expected": {
      "baseline_command": 5,
      "baseline_output": 14,
      "baseline_error": 4,
      "command": 0,
      "output": 4,
      "error": -6
    },
    "why": "Overstating the disturbance makes compensation worse in absolute error than the direct baseline."
  },
  "assumptions": [
    "Static scalar plant, known positive gain, additive disturbance; command unrestricted.",
    "Measurement available before command; no feedback, delay or noise distribution."
  ],
  "limits": "No live GA controller or universal benefit; inaccurate gain or disturbance can reverse the comparison.",
  "input_types": {
    "target": "real output units",
    "plant_gain": "positive real output/command",
    "disturbance": "real output units",
    "measured_disturbance": "real output units",
    "assumed_gain": "positive real output/command"
  }
}
```

### Exercise 1

Compute the uncompensated baseline.

<details><summary>Answer 1</summary>

Command `5` gives output `14` and error `4`. The baseline uses the target and assumed gain, without disturbance subtraction.

</details>

### Exercise 2

Compute the proposed command and output.

<details><summary>Answer 2</summary>

Command `3.5` gives output `11` and error `1`. The actual disturbance remains `4`, although its estimate is `3`.

</details>

### Exercise 3

Why not use the measured disturbance for actual output?

<details><summary>Answer 3</summary>

It would replace the stipulated world with the controller’s estimate and conceal mismatch. Prediction and actual model input occupy different roles.

</details>

### Exercise 4

Apply the overstated-disturbance control.

<details><summary>Answer 4</summary>

Command `0` gives output `4` and error `-6`. Its absolute error exceeds the baseline’s `4`; feedforward is worse here.

</details>

### Exercise 5

What would a project recommendation still need?

<details><summary>Answer 5</summary>

A justified gain, timely disturbance measurement, command limits and actual task evidence. This fixed calculation does not supply those observations.

</details>

## Source-assisted learner task

Compare direct and disturbance-compensated commands in a fictional GA resource-load note.

**Direct manual baseline:** Use separate columns for assumed gain, estimated disturbance and actual output equation.

**Falsifier:** The proposed compensation is declared universally better despite the worse control residual.

Save a first answer before opening the corrected exercises. Copy the input identities and units, write the intermediate quantities, and distinguish the calculation from the interpretation. A correct number with the wrong denominator, state boundary or counting unit does not meet the task. Retain a surprising intermediate result rather than changing the input to make the final answer look plausible.

Read the cited primary passage within the scope recorded in the packet. Compare its actual definition with the authored rule in the fixed model. The reference may motivate a concept without specifying our entire model. Record the version or date, the passage used and the exact assumption you imported. An accessible page or a successful file read is not evidence that a claim has been verified.

Inspect the retained project artifact and one prerequisite. Separate what the file actually represents from what this new task hypothesizes. Preserve source revision and assistance history. Ask an assistant to challenge an assumption only after saving the manual baseline, then keep its prompt, reply, accepted correction and rejected suggestion. Source lookup and calculator use are permitted assistance, not unaided recall.

Run the changed input through the same reasoning on paper. State the falsifier before proposing an agent abstraction or a composable DSL expression. If an abstraction drops the counterexample or changes the accepted endpoint, it fails this task even if its response is shorter. Compare a direct table or typed record first; no new language or production engine is required.

Submit original and corrected answers together with the control result, source passage and remaining uncertainty. The packet prepares a separate criterion for each exercise, with every learner decision undecided. An answer key, a byte hash and an author self-check are different evidence from an actual learner attempt. A future dogfood comparison must retain actual attempts on the same versioned task and the direct baseline before claiming a useful change.

[Fixed unit packet](../../../../code/streeling/evidence/batch50-2026-10-25/unit-b.json) · [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
