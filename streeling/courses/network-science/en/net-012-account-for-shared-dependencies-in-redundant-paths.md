---
module_id: "net-012-account-for-shared-dependencies-in-redundant-paths"
department: "network-science"
course: "Account for Shared Dependencies in Redundant Paths"
level: "intermediate"
prerequisites: ["net-003-worker-lane-coverage-and-fragility"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Account for Shared Dependencies in Redundant Paths

> This lesson uses an authored fixed case and inspected sources. Counts, times, labels and signals are invented teaching inputs. Human technical review, fluent-language review, actual learner attempts, runtime execution, production adoption and publication decisions remain undecided.

A coordinator sees two routes to obtain a review and claims that either route can rescue the other. Both may depend on the same repository service or credential provider. The route-coverage prerequisite counts declared choices under a cut. This lesson asks a probabilistic question about those choices when they share a prerequisite. A graph with two paths does not supply two independent opportunities by itself.

Condition first on the shared dependency being available. Within that condition, the branch successes are stipulated independent, so the probability that both fail is the product of their failure probabilities. Subtract from unity to obtain the conditional union. Then multiply by the shared success probability because neither branch can work without it. This factor belongs outside the union; treating it as separate independent copies would change the model.

The tempting shortcut computes each path’s marginal success and then treats those path events as independent. They are dependent through the shared prerequisite, so the shortcut overstates success. The control makes that common prerequisite less reliable while keeping conditional branch behavior unchanged. The resulting gap illustrates the hidden cost of a shared dependency. These probabilities are invented, without estimating any actual provider’s reliability or a user’s failure exposure.

The retained [F#](https://learn.microsoft.com/dotnet/fsharp/) helper composes parallel results and failure outcomes. Its existence supplies a composition boundary to inspect, not measurements or an independence theorem. [W3C](https://www.w3.org/TR/2013/REC-prov-dm-20130430/) provenance keeps activities and used entities distinguishable, which helps draw the shared dependency explicitly. Before proposing a redundant agent workflow, draw the condition tree manually and ask which common prerequisites survive the apparent route split. A route count, a parallel call declaration and observed delivery reliability remain separate pieces of evidence.

## Sources and project boundary

Read the prerequisite before using the model. Inspect the linked retained project artifact at the revision recorded in the packet, and identify the field or branch that supports the stated source observation. The source gives a representation or declared behavior; it does not turn the invented case into an observed project result. The primary reading supplies the named concept within its stated scope.

[Prerequisite: net-003-worker-lane-coverage-and-fragility](../../network-science/en/net-003-worker-lane-coverage-and-fragility.md)

[Retained project artifact](../../../../code/streeling/functional-composition/vendor/GaAsync.fs)

[Primary reading: W3C Recommendation 2013-04-30](https://www.w3.org/TR/2013/REC-prov-dm-20130430/)

[Primary reading: Microsoft F# documentation, read 2026-10-24](https://learn.microsoft.com/dotnet/fsharp/)

## Fixed model and control

```json
{
  "values": {
    "shared_success": 0.95,
    "branch_a_success_given_shared": 0.8,
    "branch_b_success_given_shared": 0.9
  },
  "formula": "success=shared_success*(1-(1-a)*(1-b)); marginal_a=shared_success*a; marginal_b=shared_success*b; naive_independent=1-(1-marginal_a)*(1-marginal_b).",
  "expected": {
    "conditional_branch_union": 0.98,
    "success": 0.931,
    "marginal_a": 0.76,
    "marginal_b": 0.855,
    "naive_independent": 0.9652
  },
  "negative_control": {
    "values": {
      "shared_success": 0.5,
      "branch_a_success_given_shared": 0.8,
      "branch_b_success_given_shared": 0.9
    },
    "expected": {
      "conditional_branch_union": 0.98,
      "success": 0.49,
      "marginal_a": 0.4,
      "marginal_b": 0.45,
      "naive_independent": 0.67
    },
    "why": "A weaker shared dependency worsens both paths together; independent marginal multiplication overstates the union."
  },
  "assumptions": [
    "Branch successes independent conditional on the shared dependency succeeding.",
    "Both paths fail if the shared dependency fails.",
    "Authored probabilities refer to the same window and operation."
  ],
  "limits": "No live provider availability measured; correlation outside this conditional model may differ."
}
```

### Exercise 1

Compute the conditional probability that at least one branch succeeds.

<details><summary>Answer 1</summary>

It is `1-(1-0.8)*(1-0.9)=0.98`. The independence premise applies only after conditioning on the shared dependency succeeding. Without that condition the path events share a common cause of failure.

</details>

### Exercise 2

Calculate total success under the main model.

<details><summary>Answer 2</summary>

It is `0.95*0.98=0.931`. The shared prerequisite must succeed as well as the branch union. The result cannot exceed the shared success probability under these assumptions.

</details>

### Exercise 3

Calculate the misleading independent-marginal shortcut.

<details><summary>Answer 3</summary>

Marginals are `0.76` and `0.855`; the shortcut gives `0.9652`. It overstates `0.931` by ignoring common failure. Correct individual marginals do not make their joint behavior independent.

</details>

### Exercise 4

Apply the weaker shared-dependency control.

<details><summary>Answer 4</summary>

Conditional union remains `0.98`, actual model success becomes `0.49`, and the shortcut becomes `0.67`. Improving the independent branches alone cannot remove the common prerequisite limitation.

</details>

### Exercise 5

What would justify a real redundant-route claim?

<details><summary>Answer 5</summary>

Retain the operation and window, measured shared and branch outcomes, common services and justified dependence assumptions. The source helper and invented probabilities show how to ask the question, without establishing live availability or authorizing a new fallback mechanism.

</details>

## Source-assisted learner task

Start with a paper table before revealing the answers. Copy the inputs and their units, apply the declared operation, and retain intermediate results. This direct calculation is the manual baseline against which an assistant or a proposed composable notation must be compared. A shorter response has no demonstrated advantage if it loses an input identity, a failure category or the counterexample.

Then inspect the precise source passage recorded in the packet. Quote only the small field or branch needed for your explanation and record its revision. Ask an assistant to challenge one assumption after you have saved your first answer. Retain the prompt, reply, accepted corrections and rejected suggestions. Source lookup and calculator use are allowed; record them as assistance so the result cannot be mistaken for unaided recall.

Apply the changed input in the negative control and state an observable falsifier before making a recommendation. An unexpected control result requires checking the calculation and assumptions before changing a project workflow. Submit the original answer, corrected answer, assistance history and remaining uncertainty together. The packet prepares five learner criteria, one per exercise, with undecided decisions. Prepared solutions and author checks do not fill those decisions. A future dogfood comparison needs actual attempts on the same task and a retained manual baseline; no new agent mechanism or DSL implementation is required by this lesson.

[Fixed unit packet](../../../../code/streeling/evidence/batch50-2026-10-24/unit-b.json) · [Validation journal](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
