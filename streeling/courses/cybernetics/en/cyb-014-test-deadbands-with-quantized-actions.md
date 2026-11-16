---
module_id: "cyb-014-test-deadbands-with-quantized-actions"
department: "cybernetics"
course: "Test Deadbands with Quantized Actions"
level: "intermediate"
prerequisites: ["cyb-005-stop-render-policy-flapping", "cyb-011-prevent-integral-accumulation-under-saturation"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Test Deadbands with Quantized Actions

> This lesson uses an authored fixed case and inspected sources. Counts, times, labels and signals are invented teaching inputs. Human technical review, fluent-language review, actual learner attempts, runtime execution, production adoption and publication decisions remain undecided.

An agent proposes correcting every nonzero residual with a whole unit of action. Near the target, the actuator cannot make the small change the residual suggests. It can jump across the target and then jump back. The flapping prerequisite uses stateful hysteresis and timing rules; this lesson instead studies a memoryless deadband with discrete action magnitude. The distinction matters because the model contains no streak, dwell clock or previous mode.

Apply the strict comparison before each action. Inside the deadband, including equality at its boundary, retain the current error. Outside it, subtract a whole step in the direction of the error. That correction can overshoot. A retained residual is an intended consequence of the proposed rule rather than hidden evidence of exact convergence. Report both action count and remaining error when comparing it with an always-correct policy.

The main case takes an action and then rests at a nonzero error. The control narrows the permitted band, causing both visited errors to demand action. A repeating pair appears even though there is no measurement noise. This isolates quantization as sufficient for the constructed cycle, without claiming that quantization causes every real oscillation. Adding integral accumulation or delay would define another model requiring another trace.

The retained project record does not contain a new controller observation. It is linked to keep authored reasoning separate from historical reports. An assistant may help produce a transition table or suggest a DSL predicate, but a quieter trace does not alone justify a product default. The manual baseline should include the tolerance that makes remaining error acceptable and the cost assigned to repeated actions. Those choices require the actual project task and remain unresolved here.

The pinned [BRUTAL](https://raw.githubusercontent.com/GuitarAlchemist/ga/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs) adaptive branch changes `bounces` by a whole step and also includes distinct recovery and reduction thresholds plus a dwell guard. Inspect those actual predicates before comparing them with our memoryless rule. The source demonstrates quantized choice, while the authored deadband isolates a different mechanism.

## Sources and project boundary

Read the prerequisite before using the model. Inspect the linked retained project artifact at the revision recorded in the packet, and identify the field or branch that supports the stated source observation. The source gives a representation or declared behavior; it does not turn the invented case into an observed project result. The primary reading supplies the named concept within its stated scope.

[Prerequisite: cyb-005-stop-render-policy-flapping](../../cybernetics/en/cyb-005-stop-render-policy-flapping.md)

[Prerequisite: cyb-011-prevent-integral-accumulation-under-saturation](../../cybernetics/en/cyb-011-prevent-integral-accumulation-under-saturation.md)

[Retained project artifact](../../../../code/streeling/evidence/pilot-value-2026-10-22/source-observations.json)

[Primary reading: W3C Recommendation 2013-04-30](https://www.w3.org/TR/2013/REC-prov-dm-20130430/)

[Primary reading: GA 76efbffd5af82b46c3146957a6bd4504008eeb89](https://raw.githubusercontent.com/GuitarAlchemist/ga/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs)

## Fixed model and control

```json
{
  "values": {
    "initial_error": 0.6,
    "action_step": 1,
    "deadband": 0.5,
    "updates": 4
  },
  "formula": "If abs(x)>deadband, x_next=x-action_step*sign(x); otherwise x_next=x. Equality retains the state.",
  "expected": {
    "trace": [
      0.6,
      -0.4,
      -0.4,
      -0.4,
      -0.4
    ],
    "final_error": -0.4,
    "action_count": 1
  },
  "negative_control": {
    "values": {
      "initial_error": 0.6,
      "action_step": 1,
      "deadband": 0.3,
      "updates": 4
    },
    "expected": {
      "trace": [
        0.6,
        -0.4,
        0.6,
        -0.4,
        0.6
      ],
      "final_error": 0.6,
      "action_count": 4
    },
    "why": "A narrower deadband excludes both quantized residuals and sustains alternating action."
  },
  "assumptions": [
    "Exact decimal arithmetic and instantaneous fixed-size actions.",
    "No noise, plant lag, integral term or actuator saturation."
  ],
  "limits": "Deadband reduces action in this example at the cost of nonzero residual; no production threshold or stability guarantee follows."
}
```

### Exercise 1

Apply the first action and explain the sign change.

<details><summary>Answer 1</summary>

Starting at `0.6`, subtracting step `1` gives `-0.4`. The sign change results from an action larger than the error. It is consistent with the declared quantized actuator and is not a rounding artifact.

</details>

### Exercise 2

Complete the main trace and count actions.

<details><summary>Answer 2</summary>

The trace is `[0.6,-0.4,-0.4,-0.4,-0.4]` and action count is `1`. Once inside deadband `0.5`, the rule retains the state. It does not drive the remaining error to zero.

</details>

### Exercise 3

Apply the narrower control and explain its alternating behavior.

<details><summary>Answer 3</summary>

With deadband `0.3`, the trace is `[0.6,-0.4,0.6,-0.4,0.6]` and action count is `4`. Both residual magnitudes exceed the band, so the fixed step keeps crossing the target.

</details>

### Exercise 4

Does the deadband have the same memory as the prerequisite’s hysteresis?

<details><summary>Answer 4</summary>

No. This decision depends only on the present error magnitude and the fixed threshold. It contains no retained mode, persistence count or dwell time. Treating those mechanisms as synonyms would change the transition contract.

</details>

### Exercise 5

What would make the quieter main trace useful to a real project?

<details><summary>Answer 5</summary>

A stated acceptable residual, action cost, measured actuator behavior and a retained comparison task are required. Reject a recommendation that calls the nonzero residual exact convergence or adopts the authored band without project evidence.

</details>

## Source-assisted learner task

Start with a paper table before revealing the answers. Copy the inputs and their units, apply the declared operation, and retain intermediate results. This direct calculation is the manual baseline against which an assistant or a proposed composable notation must be compared. A shorter response has no demonstrated advantage if it loses an input identity, a failure category or the counterexample.

Then inspect the precise source passage recorded in the packet. Quote only the small field or branch needed for your explanation and record its revision. Ask an assistant to challenge one assumption after you have saved your first answer. Retain the prompt, reply, accepted corrections and rejected suggestions. Source lookup and calculator use are allowed; record them as assistance so the result cannot be mistaken for unaided recall.

Apply the changed input in the negative control and state an observable falsifier before making a recommendation. An unexpected control result requires checking the calculation and assumptions before changing a project workflow. Submit the original answer, corrected answer, assistance history and remaining uncertainty together. The packet prepares five learner criteria, one per exercise, with undecided decisions. Prepared solutions and author checks do not fill those decisions. A future dogfood comparison needs actual attempts on the same task and a retained manual baseline; no new agent mechanism or DSL implementation is required by this lesson.

[Fixed unit packet](../../../../code/streeling/evidence/batch50-2026-10-24/unit-b.json) · [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
