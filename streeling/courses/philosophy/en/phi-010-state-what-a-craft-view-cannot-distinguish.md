---
module_id: phi-010-state-what-a-craft-view-cannot-distinguish
department: philosophy
course: "State What a Craft View Cannot Distinguish"
level: intermediate
prerequisites: ["phi-008-separate-a-test-oracle-from-a-specification"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# State What a Craft View Cannot Distinguish

> Draft for technical and language review. Every scene, count, temperature, timing and outcome introduced below is an authored example. Source inspection and arithmetic do not constitute a physical craft trial, a [Godot](https://docs.godotengine.org/en/4.5/) import, a [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md) render, a [ComfyUI](https://docs.comfy.org/) run or a learner observation. Human and runtime decisions remain undecided.

## Project question

An origami or relief sculpture matches a front-view reference, so an agent declares the entire object faithful. The observation may discard the feature the requirement concerns. This lesson constructs two candidates that produce the same simplified view but disagree on a depth requirement. It extends oracle-versus-specification reasoning by showing exactly which distinction the observation function cannot carry.

## Read the retained boundary

The cleanup pipeline requests turntable frames, but the inspected arguments alone do not bind a view to every semantic feature. Godot documents distinct perspective and orthographic projection modes. Our ideal projection is a mathematical teaching function, not output captured from either host.

Read the prerequisite and the retained project artifact before interpreting the model. The source has its own revision and purpose; it supplies the boundary described here, not the new classroom inputs. Keep a small evidence table separating an inspected field, an assumption, a derived quantity and a proposed scene effect. An agent summary must point back to the field it interprets. A source filename alone cannot establish an earlier result.

## Interpret the model

An observation maps a candidate object to something inspectable. If different candidates map to the same observation, agreement of observations cannot establish a property on which those candidates disagree. Here the map intentionally drops depth. The witness is enough to refute the universal inference from matched front observation to satisfied depth requirement. It does not say that front views are useless; they can answer properties of the retained coordinates. Choosing an additional observation should target the missing distinction. More images without a declared relation to the requirement can multiply evidence volume while leaving the logical gap unchanged.

The direct baseline is a labelled sketch and a hand calculation with the answer panels closed. Preserve intermediate values and units, then apply the changed input in the negative control. A disagreement is useful evidence: locate whether it comes from the definition, arithmetic, representation or intended task before changing the model. Agreement on the main case alone does not establish a universal rule. These finite examples deliberately expose an assumption that a smooth preview could conceal.

```text
{"candidate_a":[0,0,0],"candidate_b":[0,0,1],"projection_axes":[0,1],"required_depth":0}
observe(p)=[p[0],p[1]]; requirement(p)=(p[2]==required_depth); indistinguishable=(observe(a)==observe(b))
```

## Corrected exercises

### Exercise 1

Compute the two main observations under the declared projection.

<details><summary>Answer 1</summary>

Both are `[0,0]`. The candidates are indistinguishable to this exact observation despite their different depth coordinates.

</details>

### Exercise 2

Evaluate the depth requirement for both candidates.

<details><summary>Answer 2</summary>

The requirement is true for candidate A and false for candidate B. Equal observations therefore do not imply equal satisfaction of this requirement.

</details>

### Exercise 3

Apply the changed-position control. What distinction becomes observable?

<details><summary>Answer 3</summary>

The observations become `[0,0]` and `[1,0]`. They are distinguishable, while candidate B still fails the same depth requirement.

</details>

### Exercise 4

Which additional ideal observation would distinguish the main candidates?

<details><summary>Answer 4</summary>

An observation retaining the depth coordinate could distinguish them. That supplies a witness for this pair, not a universal proof that all sculpture properties become identifiable.

</details>

### Exercise 5

What is a justified fidelity statement from the original observation?

<details><summary>Answer 5</summary>

State agreement only under the declared front observation and comparison convention. Keep depth, hidden surfaces, material and craft-process fidelity unresolved unless separately evidenced.

</details>

## Source-assisted learner task

Write an observation table before revealing answers, then identify a proposed relief feature a front view would omit. Trace the pipeline’s capture arguments without claiming a render. Your falsifier for a universal fidelity inference is a same-view candidate that violates the declared hidden-feature requirement.

Retain your original answer, source locations, assistance history and any later correction as separate records. State the observable result that would falsify your recommendation before proposing automation. Compare the source-assisted result with your direct manual baseline, including any extra uncertainty it introduces. The fixed packet contains five prepared criteria; each decision stays null until an actual learner attempt and review exist. Prepared answers are checks, not evidence that a learner performed the task.

## Sources and validation journal

- [Prerequisite: phi-008-separate-a-test-oracle-from-a-specification](../../philosophy/en/phi-008-separate-a-test-oracle-from-a-specification.md)
- [Retained project artifact](../../../../code/blender/scripts/glb_pipeline.py)
- [Primary reading](https://docs.godotengine.org/en/4.5/classes/class_camera3d.html)
- [Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-24/unit-c.json)
- [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
