---
module_id: "cs-017-test-pipeline-rewrites-with-counterexamples"
department: "computer-science"
course: "Test Pipeline Rewrites with Counterexamples"
title: "Test Pipeline Rewrites with Counterexamples"
level: "intermediate"
prerequisites: ["cs-010-compose-fail-fast-ga-computations"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Test Pipeline Rewrites with Counterexamples

> **Draft scope.** Source-assisted authored fixed models. Human technical, fluent-language and learner decisions remain pending. No live fleet, production controller, user telemetry or learning improvement is claimed. The validation journal distinguishes tests actually executed from source reading and planned checks.

## Sources to inspect

- [cs-010-compose-fail-fast-ga-computations.md](../../computer-science/en/cs-010-compose-fail-fast-ga-computations.md)
- [GaAsync.fs](https://raw.githubusercontent.com/GuitarAlchemist/ga/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Closures/GaAsync.fs)

A proposed GA pipeline cleanup combines adjacent stages and moves validation to reduce repetition. The code may become shorter while accepting a formerly rejected input. The prerequisite explains dependent composition and reassociation. This course makes a different demand: retain a small witness that would disprove the proposed rewrite before changing any implementation. Our arithmetic stages are authored functions, not a replacement GA API.

The pinned GA bind matches success and error separately and skips its callback on an error. Read that branch in the actual source. It describes a control boundary that an informal rewrite might cross. Reassociation preserves the order of the dependent functions. Swapping them changes their calculation. Moving a guard changes the value it sees. These are separate transformations and need separate arguments, even when the same notation is used to display their stages.

The fixed model chooses exact integers so rounding cannot explain a discrepancy. Apply both function orders to each supplied input, keeping the intermediate values on paper. The resulting vectors differ at every listed position. This is sufficient to refute equivalence for this model. It does not tell us which order the product specification intended. Correctness still needs the consumer's required behavior and a valid interpretation of the input.

The boundary witness is especially useful. The original validation checks the starting value, whereas the proposed validation checks it after the increment. A rejected starting value can become accepted without any arithmetic error. A demonstration using only a comfortably positive input would miss that change. The negative control leaves the pipeline untouched; a comparison that reports a difference for that control has a broken comparison procedure.

For the source-assisted task, annotate the prerequisite's associativity discussion and the actual bind match. Write a proposed rewrite as a pair of input-to-output tables rather than inventing a DSL. Ask an assistant for a counterexample after retaining your manual calculation. The proposal fails if it changes an allowed result, failure category or required ordering. A passing finite table remains a bounded check; additional claims about effects, cancellation, timing or all integers require additional reasoning.

## Fixed case and expected calculations

```json
{
  "values": {
    "inputs": [
      -2,
      0,
      2
    ],
    "f": "x+1",
    "g": "2*x",
    "guard": "x>0"
  },
  "formula": "original=g(f(x)); swapped=f(g(x)); validation-before versus validation-after",
  "expected": {
    "original": [
      -2,
      2,
      6
    ],
    "swapped": [
      -3,
      1,
      5
    ],
    "guard_witness": 0,
    "before": "reject",
    "after": "accept"
  },
  "negative_control": "Identity rewrite must agree for every supplied witness.",
  "assumptions": [
    "Exact integer arithmetic, no effects, guard evaluates its stated input."
  ],
  "limits": "A finite witness set can refute equality but agreement is not a universal proof."
}
```

## Retain a source-assisted learner attempt

Work from the pinned inputs listed above. Before asking for assistance, write your own prediction for the fixed case and its negative control, including the unit of every quantity and the exact comparison boundary. A short paper table is the direct manual baseline. Keep intermediate values, especially any result that contradicts your first prediction. This is an explanation task using existing sources and fixed data; it does not require installing a package, calling a paid service or introducing a new program.

Next use an assistant to locate the relevant source passage and critique your calculation. Retain the original prompt, the response, the source location it cited and the changes you accepted or rejected. A citation is useful only when its inspected content supports the specific claim. A declared stage, a data type and a prose comment supply different kinds of evidence from an executed outcome. Explain that boundary in the final answer rather than borrowing the authority of a successful-looking label.

Submit the manual baseline, corrected result, control outcome, falsifier and assistance history together. The prepared learner criteria ask whether the scope was identified, the calculation was correct, the counterexample was retained, the source supported the explanation and the conclusion respected its limits. Their decisions remain undecided until an actual learner answer exists. Answer keys below are prepared corrections, not evidence that anyone learned the material. A reviewer should preserve a failed criterion and its reason before any refinement, then judge the revised attempt separately. Runtime evidence and publication evidence, if later collected, need their own revision-bound records.

### Exercise 1

Calculate the original output vector.

<details>
<summary>Answer 1</summary>

`[-2,2,6]` from `2*(x+1)`.

</details>

### Exercise 2

Calculate the swapped vector.

<details>
<summary>Answer 2</summary>

`[-3,1,5]` from `2*x+1`; the rewrite is refuted.

</details>

### Exercise 3

Apply the guard to the boundary witness.

<details>
<summary>Answer 3</summary>

At `x=0`, validation before increment rejects; after increment it accepts `1`.

</details>

### Exercise 4

What should the identity control report?

<details>
<summary>Answer 4</summary>

Equal results for every supplied input; a mismatch invalidates the checker.

</details>

### Exercise 5

Does agreement on these inputs prove a law?

<details>
<summary>Answer 5</summary>

No. A counterexample refutes a universal claim; finite agreement alone does not prove it.

</details>

[Fixed evidence packet](../../../../code/streeling/evidence/batch50-2026-10-23/unit-b.json) · [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)
