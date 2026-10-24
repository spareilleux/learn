---
module_id: "cyb-010-separate-derivative-noise-from-plant-motion"
department: "cybernetics"
course: "Separate Derivative Noise from Plant Motion"
title: "Separate Derivative Noise from Plant Motion"
level: "intermediate"
prerequisites: ["cyb-008-check-convergence-before-repeating-a-correction"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Separate Derivative Noise from Plant Motion

> **Draft scope.** Source-assisted authored fixed models. Human technical, fluent-language and learner decisions remain pending. No live fleet, production controller, user telemetry or learning improvement is claimed. The validation journal distinguishes tests actually executed from source reading and planned checks.

## Sources to inspect

- [cyb-008-check-convergence-before-repeating-a-correction.md](../../cybernetics/en/cyb-008-check-convergence-before-repeating-a-correction.md)
- [discretepidcontroller.html](https://www.mathworks.com/help/simulink/slref/discretepidcontroller.html)

An agent observes a sudden change in a dashboard value and proposes a strong corrective action. Is the system moving, or did the measurement fluctuate? The convergence prerequisite studies exact residuals. Here the true position stays constant while a declared measurement perturbation enters a derivative estimate. The example is an accounting exercise in units and sensitivity, not a model of a measured GA service.

The primary controller documentation describes a derivative contribution and a filter. Our finite-difference and smoothing equations are stated independently below; they are not a transcription of every option in that product. Position units divided by seconds yield position units per second. A derivative gain would need compatible units before this signal could contribute to an actuator command. Calling a number a correction does not provide that dimensional contract.

Compute the measured changes before dividing by the sampling interval. The apparent motion alternates even though the stipulated plant never moves. The smoothing recurrence starts from the declared initial value and retains part of its previous state. Its outputs therefore cannot be compared with a fresh uninitialized average. Retaining the initialization is essential when an agent restarts an analysis or compares two short traces.

Halving the interval while keeping the same measurement jumps doubles the finite differences. That is a statement about this constructed input, not a universal description of sensor noise under faster sampling. A genuine ramp, a delayed sensor and isolated spikes could require different analysis. Smoothing can also delay a real change; lower visible fluctuation alone does not establish better control or correct attribution.

For the source-assisted task, identify the derivative-filter description in the primary documentation, then contrast it with the prerequisite's exact update equation. Calculate the raw and filtered traces by hand and preserve the constant-input control. Ask an assistant to label assumed true motion separately from measured values. Reject its explanation if it infers a real plant response from this perturbation or uses a quieter derivative plot as proof of stability.

## Fixed case and expected calculations

```json
{
  "values": {
    "dt_seconds": 0.1,
    "true_position": [
      10,
      10,
      10
    ],
    "measurement": [
      10,
      10.2,
      10
    ],
    "gain": 1,
    "filter_alpha": 0.5,
    "filter_initial": 0
  },
  "formula": "d[k]=(y[k]-y[k-1])/dt; z[k]=alpha*d[k]+(1-alpha)*z[k-1]",
  "expected": {
    "true_derivative": [
      0,
      0
    ],
    "raw_derivative": [
      2,
      -2
    ],
    "filtered_derivative": [
      1,
      -0.5
    ],
    "half_dt_raw": [
      4,
      -4
    ]
  },
  "negative_control": "A constant measured sequence gives zero raw and filtered derivatives.",
  "assumptions": [
    "Uniform sample intervals, fixed position units, no plant motion, stipulated perturbation, no missing samples."
  ],
  "limits": "No physical sensor, GA controller or noise distribution was measured; smoothing does not establish closed-loop stability."
}
```

## Retain a source-assisted learner attempt

Work from the pinned inputs listed above. Before asking for assistance, write your own prediction for the fixed case and its negative control, including the unit of every quantity and the exact comparison boundary. A short paper table is the direct manual baseline. Keep intermediate values, especially any result that contradicts your first prediction. This is an explanation task using existing sources and fixed data; it does not require installing a package, calling a paid service or introducing a new program.

Next use an assistant to locate the relevant source passage and critique your calculation. Retain the original prompt, the response, the source location it cited and the changes you accepted or rejected. A citation is useful only when its inspected content supports the specific claim. A declared stage, a data type and a prose comment supply different kinds of evidence from an executed outcome. Explain that boundary in the final answer rather than borrowing the authority of a successful-looking label.

Submit the manual baseline, corrected result, control outcome, falsifier and assistance history together. The prepared learner criteria ask whether the scope was identified, the calculation was correct, the counterexample was retained, the source supported the explanation and the conclusion respected its limits. Their decisions remain undecided until an actual learner answer exists. Answer keys below are prepared corrections, not evidence that anyone learned the material. A reviewer should preserve a failed criterion and its reason before any refinement, then judge the revised attempt separately. Runtime evidence and publication evidence, if later collected, need their own revision-bound records.

### Exercise 1

Calculate the raw derivative.

<details>
<summary>Answer 1</summary>

`[2,-2]` position units per second; true derivative is `[0,0]`.

</details>

### Exercise 2

Calculate the filtered sequence.

<details>
<summary>Answer 2</summary>

`[1,-0.5]` with the stated initial state and smoothing recurrence.

</details>

### Exercise 3

Halve the sampling interval.

<details>
<summary>Answer 3</summary>

At `dt=0.05`, the same jumps give `[4,-4]`.

</details>

### Exercise 4

Evaluate the constant-input control.

<details>
<summary>Answer 4</summary>

Both traces remain zero; nonzero output would contradict the declared recurrence or initialization.

</details>

### Exercise 5

Does smoothing prove better control?

<details>
<summary>Answer 5</summary>

No. Motion attribution, delay, actuator behavior and stability remain untested.

</details>

[Fixed evidence packet](../../../../code/streeling/evidence/batch50-2026-10-23/unit-b.json) · [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)
