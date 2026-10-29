---
module_id: "phi-015-diagnose-a-failed-prediction-with-an-auxiliary-premise"
department: "philosophy"
course: "Diagnose a Failed Prediction with an Auxiliary Premise"
level: "advanced"
prerequisites: ["phi-008-separate-a-test-oracle-from-a-specification"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Diagnose a Failed Prediction with an Auxiliary Premise

> Draft for technical and fluent-language review. The numerical inputs, labels and expected results are authored teaching cases. They are not new physical material tests, native scene runs, learner observations or production outcomes. Human and learner decisions remain undecided.

## Project operation and interpretation

A proposed origami-to-scene test predicts that a crease will be visible when the geometry is preserved and the capture setup is adequate. The capture is hypothetically unsuccessful. An agent blames the geometry immediately, although the camera or illumination premise may have failed. This lesson enumerates the surviving explanations before and after an independently verified auxiliary premise. It does not report a new capture or claim that all scientific failures reduce to Boolean logic.

Define the finite model carefully. Here prediction success is exactly the conjunction of the geometry hypothesis and the setup auxiliary. This is stronger than saying that their conjunction merely implies success; the equivalence is an authored teaching premise. A failed prediction rules out the world where both are true, leaving worlds with either or both false. It does not by itself entail a false main hypothesis. Distinguish logical compatibility from plausibility or posterior probability: the table supplies no prior weights.

The control verifies the auxiliary independently while retaining the failed prediction. Now only the world with false hypothesis and true auxiliary survives. Reusing the same failed image as the supposed setup verification would not provide the independent evidence stipulated by that control. A future craft handoff should therefore name the auxiliary check, its source and the result it could have contradicted. An assistant must preserve unresolved alternatives rather than converting a failed end-to-end test into an unsupported diagnosis of the mesh.

Read the committed prerequisite and the scoped primary passage before calculating. Make a small ledger with separate columns for source definition, authored premise, derived result and future observation. A documentation page supports only the claim within its inspected scope. A source parameter, mathematical answer and runtime observation have different evidential roles; an assistant’s confident summary cannot exchange those roles. The evidence packet retains the source revision and the reading boundary so another reviewer can challenge a precise statement.

Work first with the answer panels closed. Draw the table or diagram required by this operation and retain the intermediate quantities, including units or identity conventions. That handwritten derivation is the direct manual baseline. Only then consult an assistant or translation aid. Keep the question, the source location cited, the suggestion received and the change accepted or rejected. Compare the assisted result with the retained first attempt on identical inputs. A shorter answer is not an improvement when it omits a precondition or invents a completed project trial.

## Fixed model and changed-input control

```json
{
  "values": {
    "observed_prediction": false,
    "auxiliary_verified": null
  },
  "formula": "enumerate Boolean worlds [H,A] lexicographically; retain worlds with (H and A)==observed_prediction and, when auxiliary_verified is not null, A==auxiliary_verified; H_false_entailed=all(not H for retained worlds) with nonempty retained set",
  "expected": {
    "worlds": [
      [
        false,
        false
      ],
      [
        false,
        true
      ],
      [
        true,
        false
      ]
    ],
    "count": 3,
    "H_false_entailed": false
  },
  "negative_control": {
    "values": {
      "observed_prediction": false,
      "auxiliary_verified": true
    },
    "expected": {
      "worlds": [
        [
          false,
          true
        ]
      ],
      "count": 1,
      "H_false_entailed": true
    }
  }
}
```

### Exercise 1

Which world does prediction failure remove?

<details><summary>Answer 1</summary>

It removes `[true,true]`. Under the declared equivalence, that world would necessarily produce success.

</details>

### Exercise 2

List the remaining worlds.

<details><summary>Answer 2</summary>

They are `[[false,false],[false,true],[true,false]]`, a total of `3`. Do not silently choose one without added evidence.

</details>

### Exercise 3

Is the main hypothesis already refuted within the model?

<details><summary>Answer 3</summary>

No. The world `[true,false]` remains. The auxiliary could fail while the main hypothesis remains true.

</details>

### Exercise 4

Apply independent auxiliary verification.

<details><summary>Answer 4</summary>

Only `[[false,true]]` remains, count `1`; the main hypothesis is false in every surviving world. Independence is stipulated, not observed here.

</details>

### Exercise 5

Does compatibility rank explanations by probability?

<details><summary>Answer 5</summary>

No. The model has no likelihoods or priors. Counting logical worlds is not evidence that their real counterparts are equally probable.

</details>

## Source-assisted task and direct baseline

Write a paper failure-diagnosis table for a proposed crease-visibility capture. Name a manual geometry check and an independent setup check, preserving their unperformed status. Ask an assistant which surviving explanation each check would exclude.

Treat the control as a separate input record. Preserve the main case, write a prediction for the changed input and explain which premise changes. When a result disagrees with your first answer, distinguish arithmetic error, interpretation error and a model limitation. Keep a failed attempt beside its correction rather than replacing it. The task asks for a reviewable evidence note before proposing a DSL node or agent workflow; a manual table may already meet the project need.

Submit the baseline, source locations, corrected explanation, control outcome and prospective falsifier together. The prepared criteria below are questions for a future reviewer, not accepted learner results. Actual learner answer, assistance history, corrected answer and learner decision remain empty until a real attempt is retained. Technical review, fluent-language review, runtime execution, production adoption and publication each require their own applicable evidence. A passing finite calculation would establish only the stated operation under its premises.

## Prospective falsifier

A diagnosis asserting a false main hypothesis from failure alone is refuted by the surviving true-hypothesis, false-auxiliary world.

## Prepared learner criteria

- For exercise 1: retain a correct answer, the intermediate reasoning and the stated boundary; learner decision remains undecided.
- For exercise 2: retain a correct answer, the intermediate reasoning and the stated boundary; learner decision remains undecided.
- For exercise 3: retain a correct answer, the intermediate reasoning and the stated boundary; learner decision remains undecided.
- For exercise 4: retain a correct answer, the intermediate reasoning and the stated boundary; learner decision remains undecided.
- For exercise 5: retain a correct answer, the intermediate reasoning and the stated boundary; learner decision remains undecided.

## Sources and claim boundary

- [Committed prerequisite: phi-008-separate-a-test-oracle-from-a-specification](../../philosophy/en/phi-008-separate-a-test-oracle-from-a-specification.md)
- [Retained project source](../../../../code/blender/scripts/atlas/kit.py)
- [Primary reading](https://plato.stanford.edu/entries/scientific-method/)
- [Authored evidence packet](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-c.json)
- [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25-b/journal.md)
