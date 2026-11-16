---
module_id: "phy-022-budget-displacement-for-a-floating-sculpture"
department: "physics"
course: "Budget Displacement for a Floating Sculpture"
level: "advanced"
prerequisites: ["phy-014-preserve-mass-assumptions-when-scaling-a-craft-mesh"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Budget Displacement for a Floating Sculpture

> Draft for technical and fluent-language review. The numerical inputs, labels and expected results are authored teaching cases. They are not new physical material tests, native scene runs, learner observations or production outcomes. Human and learner decisions remain undecided.

## Project operation and interpretation

A hollow metal sculpture is proposed for an Observatory water feature. Its visible shell and its displaced volume answer different questions: the shell contributes mass, while the sealed envelope excludes fluid. The mass-scaling prerequisite does not decide whether a floating equilibrium can exist. Here the operation finds the displacement required to balance weight and checks whether the available envelope can supply it. All dimensions and masses are invented inputs for an asset specification, not measured properties of a fabricated object.

Draw the complete sealed envelope before multiplying density and volume. The required displacement comes from balancing the weight of the object with the weight of excluded fluid. A required fraction below unity is compatible with partial immersion; it is not the actual submerged fraction during acceleration. Full-submersion net force is a separate diagnostic. A positive value says that full immersion would provide an upward net force under these premises. It does not mean the floating equilibrium has that same net force.

For a craft-to-scene handoff, retain shell mass and envelope volume as distinct fields. A mesh surface alone may not establish a sealed interior. An origami boat or sculpted hollow body can change displacement dramatically without changing its material mass in the same proportion. An assistant must identify the excluded region rather than infer buoyancy from a material name or a convincing water render.

Read the committed prerequisite and the scoped primary passage before calculating. Make a small ledger with separate columns for source definition, authored premise, derived result and future observation. A documentation page supports only the claim within its inspected scope. A source parameter, mathematical answer and runtime observation have different evidential roles; an assistant’s confident summary cannot exchange those roles. The evidence packet retains the source revision and the reading boundary so another reviewer can challenge a precise statement.

Work first with the answer panels closed. Draw the table or diagram required by this operation and retain the intermediate quantities, including units or identity conventions. That handwritten derivation is the direct manual baseline. Only then consult an assistant or translation aid. Keep the question, the source location cited, the suggestion received and the change accepted or rejected. Compare the assisted result with the retained first attempt on identical inputs. A shorter answer is not an improvement when it omits a precondition or invents a completed project trial.

## Fixed model and changed-input control

```json
{
  "values": {
    "mass_kg": 0.6,
    "fluid_density_kg_m3": 1000,
    "sealed_volume_m3": 0.001,
    "g_m_s2": 10
  },
  "formula": "weight=m*g; maximum_buoyancy=rho*g*V; required_displacement=m/rho; required_fraction=required_displacement/V; feasible=required_fraction<=1; full_submersion_net=maximum_buoyancy-weight",
  "expected": {
    "weight_N": 6,
    "maximum_buoyancy_N": 10,
    "required_displacement_m3": 0.0006,
    "required_fraction": 0.6,
    "feasible": true,
    "full_submersion_net_N": 4
  },
  "negative_control": {
    "values": {
      "mass_kg": 1.2,
      "fluid_density_kg_m3": 1000,
      "sealed_volume_m3": 0.001,
      "g_m_s2": 10
    },
    "expected": {
      "weight_N": 12,
      "maximum_buoyancy_N": 10,
      "required_displacement_m3": 0.0012,
      "required_fraction": 1.2,
      "feasible": false,
      "full_submersion_net_N": -2
    }
  }
}
```

### Exercise 1

Calculate weight and the largest buoyant force.

<details><summary>Answer 1</summary>

They are `6 N` and `10 N`. The latter uses the entire sealed envelope, not the volume occupied only by the metal.

</details>

### Exercise 2

Find the displacement and required fraction.

<details><summary>Answer 2</summary>

They are `0.0006 m^3` and `0.6`. This is a candidate equilibrium displacement, not a measurement from a frame.

</details>

### Exercise 3

Interpret full-submersion net force.

<details><summary>Answer 3</summary>

It is `4 N` upward. At the proposed floating equilibrium the resultant would instead vanish under the declared static premises.

</details>

### Exercise 4

Apply the heavier control.

<details><summary>Answer 4</summary>

The required fraction is `1.2` and the net force at full immersion is `-2 N`. Partial immersion cannot balance the stipulated weight.

</details>

### Exercise 5

Does feasibility establish stable orientation?

<details><summary>Answer 5</summary>

No. The calculation contains no restoring torque or water ingress model. Stability and sealing require separate evidence at the proposed use boundary.

</details>

## Source-assisted task and direct baseline

Prepare an envelope-versus-shell annotation for one proposed hollow Atlas sculpture. Use a handwritten force balance as the direct baseline; identify which volume a future mesh inspection would have to establish. Leave physical and scene measurements empty.

Treat the control as a separate input record. Preserve the main case, write a prediction for the changed input and explain which premise changes. When a result disagrees with your first answer, distinguish arithmetic error, interpretation error and a model limitation. Keep a failed attempt beside its correction rather than replacing it. The task asks for a reviewable evidence note before proposing a DSL node or agent workflow; a manual table may already meet the project need.

Submit the baseline, source locations, corrected explanation, control outcome and prospective falsifier together. The prepared criteria below are questions for a future reviewer, not accepted learner results. Actual learner answer, assistance history, corrected answer and learner decision remain empty until a real attempt is retained. Technical review, fluent-language review, runtime execution, production adoption and publication each require their own applicable evidence. A passing finite calculation would establish only the stated operation under its premises.

## Prospective falsifier

Any claim that the heavier control can float partially immersed with this unchanged sealed volume is refuted by its required fraction.

## Prepared learner criteria

- For exercise 1: retain a correct answer, the intermediate reasoning and the stated boundary; learner decision remains undecided.
- For exercise 2: retain a correct answer, the intermediate reasoning and the stated boundary; learner decision remains undecided.
- For exercise 3: retain a correct answer, the intermediate reasoning and the stated boundary; learner decision remains undecided.
- For exercise 4: retain a correct answer, the intermediate reasoning and the stated boundary; learner decision remains undecided.
- For exercise 5: retain a correct answer, the intermediate reasoning and the stated boundary; learner decision remains undecided.

## Sources and claim boundary

- [Committed prerequisite: phy-014-preserve-mass-assumptions-when-scaling-a-craft-mesh](../../physics/en/phy-014-preserve-mass-assumptions-when-scaling-a-craft-mesh.md)
- [Retained project source](../../../../code/blender/scripts/atlas/kit.py)
- [Primary reading](https://openstax.org/books/university-physics-volume-1/pages/14-4-archimedes-principle-and-buoyancy)
- [Authored evidence packet](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-c.json)
- [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25-b/journal.md)
