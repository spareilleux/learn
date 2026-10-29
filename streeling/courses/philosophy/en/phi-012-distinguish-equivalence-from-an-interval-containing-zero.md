---
module_id: "phi-012-distinguish-equivalence-from-an-interval-containing-zero"
department: "philosophy"
course: "Distinguish Equivalence from an Interval Containing Zero"
level: "advanced"
prerequisites: ["phi-006-preserve-the-quantifier-in-a-fold-verdict", "phi-011-cross-mesh-and-lighting-before-attributing-a-render-change"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---


# Distinguish Equivalence from an Interval Containing Zero

> Draft for technical and language review. The case is authored, including its numeric inputs, labels and expected results. It is not a physical craft trial, a [Godot](https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html) observation, a [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md) render, a [ComfyUI](https://github.com/Comfy-Org/ComfyUI) run or a learner result. All human and learner decisions remain undecided.

## Project question

A proposed mesh cleanup has a residual-difference interval that contains zero, so a report calls the change equivalent. Containing zero only makes equality compatible with the interval. Equivalence under a declared practical margin requires the whole feasible interval to fit inside that margin. This lesson turns the quantifier distinction into a precise review operation.

Read the committed prerequisite and the retained source passage before calculating. Make an evidence table that separates a source definition, an authored premise, a derived result and a proposed future observation. The source revision and reading scope are recorded in the packet. An inspected parameter is evidence that a representation exposes that parameter; it cannot supply an unmeasured material coefficient, visibility judgement or processing time. Preserve that distinction when an assistant summarizes the source. The primary reference supports only the concept and passage named in the reading record.

## Derive the operation before proposing automation

The intervals below are authored feasible sets, not calibrated confidence intervals or test results. A universal bound over the set is stronger than the existence of an acceptable value. Choose the margin before inspecting a candidate and preserve its task meaning: a screen-space tolerance does not establish perceptual interchangeability. The cleanup script supplies capture settings, without interval evidence or an equivalence criterion. The primary logic reference separates satisfiability from validity, which motivates checking which quantifier the review actually uses.

## Fixed authored model and changed-input control

```json
{
  "values": {
    "difference_interval": [
      -0.1,
      0.15
    ],
    "equivalence_margin": 0.2
  },
  "formula": "contains_zero=(lo<=0<=hi); equivalent=(lo>=-margin and hi<=margin); compatible_with_equivalence=(hi>=-margin and lo<=margin); width=hi-lo",
  "expected": {
    "contains_zero": true,
    "equivalent": true,
    "compatible_with_equivalence": true,
    "width": 0.25
  },
  "negative_control": {
    "values": {
      "difference_interval": [
        -0.5,
        0.5
      ],
      "equivalence_margin": 0.2
    },
    "expected": {
      "contains_zero": true,
      "equivalent": false,
      "compatible_with_equivalence": true,
      "width": 1
    }
  }
}
```

### Exercise 1

Does the main interval contain zero?

<details><summary>Answer 1</summary>

Yes: `contains_zero=true`. This establishes compatibility with equality, without proving exact equality.

</details>

### Exercise 2

Does it satisfy the declared equivalence bound?

<details><summary>Answer 2</summary>

Yes: `equivalent=true`; its width is `0.25`. Both endpoints lie within the prescribed margin.

</details>

### Exercise 3

Apply the wider control.

<details><summary>Answer 3</summary>

It still has `contains_zero=true`, but `equivalent=false` and width `1`. Compatibility with equivalence remains `true`.

</details>

### Exercise 4

Is an inconclusive interval proof of a harmful difference?

<details><summary>Answer 4</summary>

No. The wide set permits acceptable and unacceptable values. Retain that ambiguity rather than asserting either equivalence or harm.

</details>

### Exercise 5

What would a real equivalence claim require?

<details><summary>Answer 5</summary>

Define the task and margin prospectively, justify how the interval was obtained, and retain the relevant observations. These feasible-set calculations are not a statistical equivalence test.

</details>

## Source-assisted learner task

Draw both intervals on the same tolerance band by hand. Inspect the cleanup capture arguments and list the missing measurement contract. Rewrite an interval-containing-zero claim using the correct quantifier.

Begin with a direct manual baseline: close the answer panels, draw the diagram or table required by the task, and derive intermediate quantities with their units. Retain that first answer before asking an assistant for help. Then use the linked source to challenge a specific assumption, retaining the question, the source location, the assistance received and any rejected suggestion. Compare the assisted answer with your original calculation on the same task and inputs. A shorter explanation is not a demonstrated improvement if it drops a boundary condition or invents an observation.

Apply the structured control as a separate case, rather than editing the main inputs in place. Record what changes and what remains invariant, and state whether a discrepancy concerns arithmetic, an interpretation or the model premises. Preserve any failed attempt and its correction separately. The packet prepares a criterion for each corrected exercise; every learner decision remains null until an actual attempt is retained and reviewed. Source lookup and a prepared answer are not evidence that a learner performed the task. No new DSL, agent workflow, scene adapter or production integration is required to complete this paper exercise.

## Prospective falsifier

The assertion that every interval containing zero proves practical equivalence is refuted by the wider control with out-of-margin possibilities.

## Sources and validation boundary

- [Committed prerequisite: phi-006-preserve-the-quantifier-in-a-fold-verdict](../../philosophy/en/phi-006-preserve-the-quantifier-in-a-fold-verdict.md)

- [Committed prerequisite: phi-011-cross-mesh-and-lighting-before-attributing-a-render-change](../../philosophy/en/phi-011-cross-mesh-and-lighting-before-attributing-a-render-change.md)

- [Retained project source](../../../../code/blender/scripts/glb_pipeline.py)

- [Primary reading](https://microsoft.github.io/z3guide/docs/logic/propositional-logic/)

- [Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-25/unit-c.json)

- [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
