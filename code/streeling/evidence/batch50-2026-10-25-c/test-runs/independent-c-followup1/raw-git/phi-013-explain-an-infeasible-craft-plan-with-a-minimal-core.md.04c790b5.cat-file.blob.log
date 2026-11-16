---
module_id: "phi-013-explain-an-infeasible-craft-plan-with-a-minimal-core"
department: "philosophy"
course: "Explain an Infeasible Craft Plan with a Minimal Core"
level: "advanced"
prerequisites: ["cs-009-composing-origami-panel-constraints", "phi-008-separate-a-test-oracle-from-a-specification"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---


# Explain an Infeasible Craft Plan with a Minimal Core

> Draft for technical and language review. The case is authored, including its numeric inputs, labels and expected results. It is not a physical craft trial, a [Godot](https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html) observation, a [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md) render, a [ComfyUI](https://github.com/Comfy-Org/ComfyUI) run or a learner result. All human and learner decisions remain undecided.

## Project question

A craft plan fails several checks, and an agent proposes deleting a convenient requirement. A useful explanation identifies a subset that is already inconsistent and shows why every member matters. The origami prerequisite establishes composition failures; this lesson adds a minimal-conflict explanation with explicit deletion witnesses in a finite design domain.

Read the committed prerequisite and the retained source passage before calculating. Make an evidence table that separates a source definition, an authored premise, a derived result and a proposed future observation. The source revision and reading scope are recorded in the packet. An inspected parameter is evidence that a representation exposes that parameter; it cannot supply an unmeasured material coefficient, visibility judgement or processing time. Preserve that distinction when an assistant summarizes the source. The primary reference supports only the concept and passage named in the reading record.

## Derive the operation before proposing automation

Keep the domain and each named inequality fixed while testing subsets. An unsatisfiable core explains a contradiction; inclusion-minimality additionally requires every proper subset to be satisfiable. The [Z3](https://microsoft.github.io/z3guide/docs/logic/propositional-logic/) guide describes named cores without promising minimality. Our finite example proves minimality manually and does not run a solver. Atlas dimensions motivate a future design handoff but are not the invented dimensions below. Finding a minimal contradiction still does not decide which requirement should be relaxed or who may authorize that change.

## Fixed authored model and changed-input control

```json
{
  "values": {
    "domain": [
      0,
      10
    ],
    "lower_x": 8,
    "upper_x": 6,
    "lower_y": 1,
    "sum_limit": 10
  },
  "formula": "Integer x,y in inclusive domain; A:x>=lower_x; B:x<=upper_x; C:y>=lower_y; D:x+y<=sum_limit; enumerate full solutions; enumerate nonempty constraint subsets; a minimal core has no solution and every proper subset has one",
  "expected": {
    "full_solution_count": 0,
    "minimal_cores": [
      [
        "A",
        "B"
      ]
    ],
    "core_deletion_witnesses": {
      "remove_A": [
        0,
        0
      ],
      "remove_B": [
        8,
        0
      ]
    }
  },
  "negative_control": {
    "values": {
      "domain": [
        0,
        10
      ],
      "lower_x": 8,
      "upper_x": 9,
      "lower_y": 1,
      "sum_limit": 10
    },
    "expected": {
      "full_solution_count": 3,
      "minimal_cores": [],
      "core_deletion_witnesses": {}
    }
  }
}
```

### Exercise 1

Find the contradiction in the main plan.

<details><summary>Answer 1</summary>

Constraints `[A,B]` demand incompatible bounds on the same dimension, so the full solution count is `0`.

</details>

### Exercise 2

Demonstrate minimality of that core.

<details><summary>Answer 2</summary>

Removing A permits `[0,0]`; removing B permits `[8,0]`. These witnesses satisfy the remaining core member and the domain, not necessarily every other full-plan requirement.

</details>

### Exercise 3

Would deleting the sum constraint fix the original plan?

<details><summary>Answer 3</summary>

No. The incompatible bounds remain. A repair must address at least one core member or change the declared domain semantics.

</details>

### Exercise 4

Apply the relaxed upper-bound control.

<details><summary>Answer 4</summary>

There are `3` full solutions and no minimal cores: `[]`. The feasible points are `[8,1]`, `[8,2]` and `[9,1]`.

</details>

### Exercise 5

Does a minimal core authorize a design change?

<details><summary>Answer 5</summary>

No. It explains infeasibility. Cost, safety, craft intent and authority determine admissible repairs; a smaller explanation is not a preferred relaxation.

</details>

## Source-assisted learner task

List the integer candidates and strike out violations by hand. Find the core, save its deletion witnesses, and inspect the Atlas dimension boundary. Write an explanation that separates contradiction, minimality and repair authority.

Begin with a direct manual baseline: close the answer panels, draw the diagram or table required by the task, and derive intermediate quantities with their units. Retain that first answer before asking an assistant for help. Then use the linked source to challenge a specific assumption, retaining the question, the source location, the assistance received and any rejected suggestion. Compare the assisted answer with your original calculation on the same task and inputs. A shorter explanation is not a demonstrated improvement if it drops a boundary condition or invents an observation.

Apply the structured control as a separate case, rather than editing the main inputs in place. Record what changes and what remains invariant, and state whether a discrepancy concerns arithmetic, an interpretation or the model premises. Preserve any failed attempt and its correction separately. The packet prepares a criterion for each corrected exercise; every learner decision remains null until an actual attempt is retained and reviewed. Source lookup and a prepared answer are not evidence that a learner performed the task. No new DSL, agent workflow, scene adapter or production integration is required to complete this paper exercise.

## Prospective falsifier

A claimed minimal core is refuted by a satisfiable assignment to it or by a proper subset that remains inconsistent; either witness must be retained.

## Sources and validation boundary

- [Committed prerequisite: cs-009-composing-origami-panel-constraints](../../computer-science/en/cs-009-composing-origami-panel-constraints.md)

- [Committed prerequisite: phi-008-separate-a-test-oracle-from-a-specification](../../philosophy/en/phi-008-separate-a-test-oracle-from-a-specification.md)

- [Retained project source](../../../../code/blender/scripts/atlas/kit.py)

- [Primary reading](https://microsoft.github.io/z3guide/docs/logic/propositional-logic/)

- [Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-25/unit-c.json)

- [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
