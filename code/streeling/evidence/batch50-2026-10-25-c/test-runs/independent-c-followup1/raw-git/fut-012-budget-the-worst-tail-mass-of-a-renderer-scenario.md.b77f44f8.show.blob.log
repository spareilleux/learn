---
module_id: "fut-012-budget-the-worst-tail-mass-of-a-renderer-scenario"
department: "futurology"
course: "Budget the Worst Tail Mass of a Renderer Scenario"
level: "advanced"
prerequisites: ["fut-004-scenario-test-an-observatory-renderer", "dv-012-compute-quantiles-before-combining-latency-cohorts"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---


# Budget the Worst Tail Mass of a Renderer Scenario

> Draft for technical and language review. The case is authored, including its numeric inputs, labels and expected results. It is not a physical craft trial, a [Godot](https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html) observation, a [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md) render, a [ComfyUI](https://github.com/Comfy-Org/ComfyUI) run or a learner result. All human and learner decisions remain undecided.

## Project question

A future craft renderer has a favorable average loss but a rare severe outcome. A percentile can locate the start of that tail while hiding its severity. The scenario prerequisite already teaches worst-case regret; this lesson uses a declared probability distribution and averages exactly the worst tail mass, including part of a boundary atom.

Read the committed prerequisite and the retained source passage before calculating. Make an evidence table that separates a source definition, an authored premise, a derived result and a proposed future observation. The source revision and reading scope are recorded in the packet. An inspected parameter is evidence that a representation exposes that parameter; it cannot supply an unmeasured material coefficient, visibility judgement or processing time. Preserve that distinction when an assistant summarizes the source. The primary reference supports only the concept and passage named in the reading record.

## Derive the operation before proposing automation

Sort losses by severity and fill the requested tail probability from the worst end. If the last scenario would overfill the tail, include only the required fraction of its probability mass. This differs from averaging every scenario at or above the quantile. The primary paper supplies the positive-part minimization and finite approximation; the weighted discrete construction here is explicitly authored. The cleanup script supplies capture controls, without scenario probabilities, loss calibration or any new renderer observations.

## Fixed authored model and changed-input control

```json
{
  "values": {
    "losses_a": [
      1,
      2,
      3,
      20
    ],
    "probabilities": [
      0.4,
      0.3,
      0.2,
      0.1
    ],
    "losses_b": [
      4,
      4,
      4,
      4
    ],
    "alpha": 0.8
  },
  "formula": "mean=sum(p_i*loss_i); VaR=smallest loss with cumulative probability>=alpha; tail_mean=min_t(t+sum(p_i*max(loss_i-t,0))/(1-alpha)); integrate exactly the worst 1-alpha probability mass, splitting a cutoff atom; compare lower means and tail means",
  "expected": {
    "mean_a": 3.6,
    "mean_b": 4,
    "var_a": 3,
    "tail_a": 11.5,
    "tail_b": 4,
    "mean_choice": "A",
    "tail_choice": "B"
  },
  "negative_control": {
    "values": {
      "losses_a": [
        1,
        2,
        3,
        4
      ],
      "probabilities": [
        0.4,
        0.3,
        0.2,
        0.1
      ],
      "losses_b": [
        4,
        4,
        4,
        4
      ],
      "alpha": 0.8
    },
    "expected": {
      "mean_a": 2,
      "mean_b": 4,
      "var_a": 3,
      "tail_a": 3.5,
      "tail_b": 4,
      "mean_choice": "A",
      "tail_choice": "A"
    }
  }
}
```

### Exercise 1

Compare expected losses.

<details><summary>Answer 1</summary>

The means are `3.6` for A and `4` for B, so the mean criterion selects `A`. These are authored loss points.

</details>

### Exercise 2

Locate the quantile and compute the tail.

<details><summary>Answer 2</summary>

A has quantile `3`. Its worst probability mass `0.2` contains mass `0.1` at loss `20` and mass `0.1` at loss `3`, giving `11.5`.

</details>

### Exercise 3

Compare the tail-based decision.

<details><summary>Answer 3</summary>

B has tail mean `4`, so the tail criterion selects `B`. This disagreement reflects the declared criterion, not an arithmetic inconsistency.

</details>

### Exercise 4

Apply the reduced-extreme-loss control.

<details><summary>Answer 4</summary>

A has mean `2`, quantile `3` and tail mean `3.5`; both criteria now select `A`. The unchanged quantile misses the tail improvement.

</details>

### Exercise 5

Does this justify a production recommendation?

<details><summary>Answer 5</summary>

No. Probabilities, losses, horizon and admissible strategies need evidence. This finite sensitivity case supplies a planning question rather than a forecast.

</details>

## Source-assisted learner task

Fill the tail mass manually on a probability bar, preserving the split atom. Inspect the pipeline capture controls and name the missing scenario evidence. Compare mean, quantile and tail recommendation before proposing a planner.

Begin with a direct manual baseline: close the answer panels, draw the diagram or table required by the task, and derive intermediate quantities with their units. Retain that first answer before asking an assistant for help. Then use the linked source to challenge a specific assumption, retaining the question, the source location, the assistance received and any rejected suggestion. Compare the assisted answer with your original calculation on the same task and inputs. A shorter explanation is not a demonstrated improvement if it drops a boundary condition or invents an observation.

Apply the structured control as a separate case, rather than editing the main inputs in place. Record what changes and what remains invariant, and state whether a discrepancy concerns arithmetic, an interpretation or the model premises. Preserve any failed attempt and its correction separately. The packet prepares a criterion for each corrected exercise; every learner decision remains null until an actual attempt is retained and reviewed. Source lookup and a prepared answer are not evidence that a learner performed the task. No new DSL, agent workflow, scene adapter or production integration is required to complete this paper exercise.

## Prospective falsifier

The claim that an unchanged percentile implies unchanged tail severity is refuted by the control, whose quantile stays fixed while its tail mean changes.

## Sources and validation boundary

- [Committed prerequisite: fut-004-scenario-test-an-observatory-renderer](../../futurology/en/fut-004-scenario-test-an-observatory-renderer.md)

- [Committed prerequisite: dv-012-compute-quantiles-before-combining-latency-cohorts](../../data-visualization/en/dv-012-compute-quantiles-before-combining-latency-cohorts.md)

- [Retained project source](../../../../code/blender/scripts/glb_pipeline.py)

- [Primary reading](https://sites.math.washington.edu/~rtr/papers/rtr179-CVaR1.pdf)

- [Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-25/unit-c.json)

- [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
