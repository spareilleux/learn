---
module_id: "cyb-012-test-feedback-delay-before-reusing-a-gain"
department: "cybernetics"
course: "Test Feedback Delay Before Reusing a Gain"
level: "intermediate"
prerequisites: ["cyb-008-check-convergence-before-repeating-a-correction"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Test Feedback Delay Before Reusing a Gain

> This lesson uses an authored fixed case and inspected sources. Counts, times, labels and signals are invented teaching inputs. Human technical review, fluent-language review, actual learner attempts, runtime execution, production adoption and publication decisions remain undecided.

An agent sees a residual fall after a correction and proposes reusing a gain chosen for immediate feedback. The next observation may still describe the state before that correction. The convergence prerequisite uses the current residual in its update. Here the recurrence uses a residual delayed by one update, so the state needed to predict the next value includes the previous value as well as the current one.

Keep the initialization explicit. Both initial error values are stipulated equal, and the sequence begins with the current value. Applying the gain to the previous value creates an overshoot even when the immediate-feedback recurrence would move monotonically toward zero. A sign change is therefore not automatically a failed calculation. The learner must reproduce the recurrence before judging whether the trace contradicts the model.

CYB008 already introduces a delayed residual and derives an unstable characteristic-root counterexample. The new task here is to derive the complete scalar gain interval, rather than introduce delay again. Write g for gain in r^2-r+g=0. For 0<g<=1/4, both roots (1+/-sqrt(1-4*g))/2 lie strictly between 0 and 1; at g=1/4 the repeated root is 1/2 and its possible k*(1/2)^k factor still decays. For 1/4<g<1, the conjugate roots have modulus sqrt(g)<1. At g=0 a unit root prevents asymptotic stability; for g<0 one real root exceeds 1; and for g>=1 the conjugate modulus is at least 1. Thus asymptotic stability for all finite initial pairs holds exactly when 0<gain<1. The six-step examples below illustrate two points of this analytically derived interval; their finite length does not prove it.

The characteristic polynomial comes from substituting a geometric trial solution into the delayed recurrence. For the main gain its roots are complex conjugates with modulus below unity, so this exact linear model converges. For the changed gain the roots lie on the unit circle and the retained trace repeats. The finite values illustrate the distinction; the root condition supplies the asymptotic argument under the stated premises.

The retained project observation file warns that a reread is not a new trial and historical reports do not calibrate an invented controller. That is the relevant project seam: an agent must identify which update produced an observation before using it as fresh corrective evidence. A composable stage card could record that association, but its usefulness remains a hypothesis. First compare the delayed and immediate equations manually; do not introduce a controller or infer real elapsed delay from the example.

In the pinned [BRUTAL](https://raw.githubusercontent.com/GuitarAlchemist/ga/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs) query block, completed timing-query results enter a stored smoothing value before a bounce decision. That is an actual source seam where observation identity and update timing matter. The recurrence below is deliberately different from that source controller; its roots cannot certify the renderer.

## Sources and project boundary

Read the prerequisite before using the model. Inspect the linked retained project artifact at the revision recorded in the packet, and identify the field or branch that supports the stated source observation. The source gives a representation or declared behavior; it does not turn the invented case into an observed project result. The primary reading supplies the named concept within its stated scope.

[Prerequisite: cyb-008-check-convergence-before-repeating-a-correction](../../cybernetics/en/cyb-008-check-convergence-before-repeating-a-correction.md)

[Retained project artifact](../../../../code/streeling/evidence/pilot-value-2026-10-22/source-observations.json)

[Primary reading: W3C Recommendation 2013-04-30](https://www.w3.org/TR/2013/REC-prov-dm-20130430/)

[Primary reading: GA 76efbffd5af82b46c3146957a6bd4504008eeb89](https://raw.githubusercontent.com/GuitarAlchemist/ga/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs)

## Fixed model and control

```json
{
  "values": {
    "gain": 0.5,
    "initial_previous": 1,
    "initial_current": 1,
    "steps": 6,
    "delay_updates": 1
  },
  "formula": "x[k+1]=x[k]-gain*x[k-1], initialized x[-1]=x[0]=1; roots solve r^2-r+gain=0.",
  "expected": {
    "trace_from_k0": [
      1,
      0.5,
      0,
      -0.25,
      -0.25,
      -0.125,
      0
    ],
    "root_modulus": 0.7071067811865476,
    "asymptotically_stable": true
  },
  "negative_control": {
    "values": {
      "gain": 1,
      "initial_previous": 1,
      "initial_current": 1,
      "steps": 6,
      "delay_updates": 1
    },
    "expected": {
      "trace_from_k0": [
        1,
        0,
        -1,
        -1,
        0,
        1,
        1
      ],
      "root_modulus": 1,
      "asymptotically_stable": false
    },
    "why": "Gain that zeros an immediate-feedback scalar error gives a nondecaying delayed cycle."
  },
  "assumptions": [
    "Exact linear scalar recurrence, fixed gain, one-update delay and no saturation or noise.",
    "Update index is dimensionless; no seconds or worker latency are inferred."
  ],
  "limits": "Root argument concerns this recurrence only; finite trace does not establish real fleet stability."
}
```

### Exercise 1

Compute the first three new values using the delayed recurrence.

<details><summary>Answer 1</summary>

They are `0.5`, `0` and `-0.25`. Each correction uses the previous error, including the declared initialization. Using the just-computed current value instead would silently remove the delay.

</details>

### Exercise 2

Explain the characteristic polynomial and the main-case root modulus.

<details><summary>Answer 2</summary>

Substituting a geometric sequence gives `r^2-r+0.5=0`. The conjugate roots have modulus `sqrt(0.5)=0.7071067811865476`, below unity. This supports asymptotic convergence only for the exact fixed linear recurrence.

</details>

### Exercise 3

Apply the control gain and retain the complete declared trace.

<details><summary>Answer 3</summary>

The trace is `[1,0,-1,-1,0,1,1]`. Root modulus is `1`, so convergence for arbitrary starting errors fails. Returning to the initial pair exposes a nondecaying cycle rather than progress.

</details>

### Exercise 4

Would the control gain also fail for the immediate-feedback equation?

<details><summary>Answer 4</summary>

No. For `x[k+1]=(1-gain)*x[k]` and `gain=1`, the next error is zero. A gain conclusion depends on observation timing; the delay changes the state transition being analyzed.

</details>

### Exercise 5

What actual evidence is needed before applying this lesson to an agent loop?

<details><summary>Answer 5</summary>

Retain action identity, observation identity and their causal association, plus the measured delay and real update rule. Source reading and an authored update-index trace do not measure worker latency or establish production stability.

</details>

## Source-assisted learner task

Start with a paper table before revealing the answers. Copy the inputs and their units, apply the declared operation, and retain intermediate results. This direct calculation is the manual baseline against which an assistant or a proposed composable notation must be compared. A shorter response has no demonstrated advantage if it loses an input identity, a failure category or the counterexample.

Then inspect the precise source passage recorded in the packet. Quote only the small field or branch needed for your explanation and record its revision. Ask an assistant to challenge one assumption after you have saved your first answer. Retain the prompt, reply, accepted corrections and rejected suggestions. Source lookup and calculator use are allowed; record them as assistance so the result cannot be mistaken for unaided recall.

Apply the changed input in the negative control and state an observable falsifier before making a recommendation. An unexpected control result requires checking the calculation and assumptions before changing a project workflow. Submit the original answer, corrected answer, assistance history and remaining uncertainty together. The packet prepares five learner criteria, one per exercise, with undecided decisions. Prepared solutions and author checks do not fill those decisions. A future dogfood comparison needs actual attempts on the same task and a retained manual baseline; no new agent mechanism or DSL implementation is required by this lesson.

[Fixed unit packet](../../../../code/streeling/evidence/batch50-2026-10-24/unit-b.json) · [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
