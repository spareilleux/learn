---
module_id: fut-007-test-a-weave-generator-outside-its-preview
department: futurology
course: "Test a Weave Generator Outside Its Preview"
level: intermediate
prerequisites: ["fut-003-agent-substitution-readiness-drill", "vc-007-weave-seams-as-scene-contracts", "sem-008-interpret-layer-order-relative-to-the-reference-normal"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Test a Weave Generator Outside Its Preview

> **Draft scope.** Authored finite grids, exact counts and pinned evaluator/scene reading. No agent was trained or evaluated, and no new Godot, IX or manufacturing trial occurred. Human technical, artisan, fluent-language and actual learner reviews remain pending. Public sources and deployed course HTML have separate verification gates.

## The project question

Does a perfect preview justify replacing a craft rule with an agent? [FUT-003](fut-003-agent-substitution-readiness-drill.md) asks what evidence a substitution needs; [VC-007](../../visual-computing/en/vc-007-weave-seams-as-scene-contracts.md) checks crossings and seams. This lesson constructs two rules that agree throughout a preview and disagree elsewhere. It then shows exactly what an additional structural assumption can prove.

The pinned [Demerzel evaluator](https://github.com/GuitarAlchemist/Demerzel/blob/f23ccae6c049d9066a1be2221c68f3b0bcf48373/state/streeling/fixtures/visual-computing/vc-007/evaluate_weave.py) accepts two named parity variants. Its [fixture](https://github.com/GuitarAlchemist/Demerzel/blob/f23ccae6c049d9066a1be2221c68f3b0bcf48373/state/streeling/fixtures/visual-computing/vc-007/weave-trial.json) defines a particular finite trial. The adversarial rule below is authored for this lesson; it is neither a supported evaluator variant nor an observed learned model.

## 1. Make the unseen domain explicit

Use nonnegative integer coordinates on an 8 by 8 target grid. The preview contains the 6 by 6 region at its origin, with all 36 crossing booleans known exactly. This gives stronger evidence than a picture alone.

Define `G(x,y)=((x+y)%2==0)`. Define `H` to equal `G` inside the preview and return true elsewhere in this finite target. The two rules agree on every preview crossing. At coordinate `(6,1)`, however, `G` is false and `H` is true.

### Practice exercise 1: produce a held-out witness

Evaluate both rules at `(6,1)`. Why would checking all preview booleans still miss the failure? Does this demonstrate failure by a real trained agent?

> **Answer:** The sum is 7, so `G` is false; the coordinate lies outside the preview, so `H` is true. All 36 preview labels agree by construction. This is an authored counterexample to an inference from preview agreement, not an observed failure by a trained agent.

## 2. Count ambiguity without inventing probabilities

The target has 64 cells, leaving 28 outside the preview. Without any rule restricting those booleans, there are `2^28=268435456` compatible completions. This counts finite assignments; it gives neither a probability that one is correct nor an expected error rate for an agent.

### Practice exercise 2: identify the assumption behind the count

Derive the number of unobserved cells and compatible completions. Would this count remain appropriate if every adjacent pair were required to differ?

> **Answer:** There are `64-36=28` unobserved cells and `2^28=268435456` unconstrained completions. Requiring every adjacent pair to differ couples the cells, so they are no longer independent binary choices. That structural restriction defines a different hypothesis class.

## 3. Inspect the complete finite target

An 8 by 8 grid has 112 horizontal/vertical neighboring pairs. The [authored grid record](../../../../code/streeling/evidence/weave-material-2026-10-22/generator-scope.json) gives 14 crossing disagreements between the rules, all outside the preview. `G` has no equal-neighbor violations; `H` has 46. Crossing disagreement count and adjacency violation count measure different things.

For the latter count, the unseen two-column strip contributes 14 vertical and 8 horizontal equal pairs. The remaining bottom strip, 6 columns wide and 2 rows high, contributes 10 horizontal and 6 vertical pairs. Between those two strips are 2 more equal pairs; their interfaces with the preview add 6, totaling 46. These strips partition the unseen region without double counting. This is an authored finite calculation, not output from the existing evaluator or scene.

### Practice exercise 3: choose the right failure count

An agent reports “14 violations” after comparing crossing labels. Correct that report, derive the total number of adjacency pairs and justify the 46 equal-neighbor pairs using the strip partition. What should the evidence say about tool execution?

> **Answer:** There are 14 label disagreements with the target rule, but 46 equal-neighbor violations for `H`. The grid has `8*7+8*7=112` neighboring pairs. The strip partition gives `14+8+10+6+2+6=46` equal pairs, including the interfaces. The report must name the metric and say these are authored finite checks; neither the Demerzel evaluator nor Godot was run on `H`.

## 4. Add a rule and prove only its consequences

Now impose a separate premise: every neighboring pair must differ. The grid graph is connected and bipartite. Choosing the origin value determines every other value by path parity, yielding exactly 2 complete assignments. The observed origin phase selects 1. A graph traversal can construct these assignments; no enumeration of all binary target grids is needed.

This is a conditional proof for the chosen binary-alternation class. It does not show that a trained generator discovered the rule, that every textile must alternate, or that any resulting pattern can be manufactured. [SEM-008](../../semiotics/en/sem-008-interpret-layer-order-relative-to-the-reference-normal.md) explains why the meaning of an order label also needs its reference and roles.

### Practice exercise 4: distinguish a proof from learning evidence

Why are there 2 structural completions before observing the origin and 1 afterward? State the assumptions and one capability claim that the proof does not establish.

> **Answer:** Connectivity propagates a chosen origin value through all adjacency constraints; bipartiteness makes the propagation consistent. Either origin value gives one completion, and the observed phase fixes which one. This assumes the declared connected grid, binary labels and complete neighbor-alternation rule. It establishes no actual learning, physical weave feasibility or unrestricted craft capability.

## 5. Design a falsifiable substitution trial

The existing evaluator reports violation counts; a nonzero count is not by itself an exception that rejects a variant. Its supported names and dimension checks are separate. The pinned [Learn controller](https://github.com/spareilleux/learn/blob/eebf49cb0b69a314bd13015340335a983aa64bfe/code/streeling/weave-godot/trial.gd) admits a particular 36-crossing manifest. Our authored larger table does not thereby become accepted scene input.

### Practice exercise 5: prepare a source-assisted future experiment

Read the evaluator, fixture and controller. Propose a bounded comparison for an agent or composable craft DSL, with a simple baseline, a rejection condition and an honest claim boundary.

> **Answer:** Pin the program, revision, input domain, label semantics and admission rules. Freeze unseen sizes, seams and role/frame transformations before the comparison. Compare against the simple global-parity rule plus an independent validator; retain counterexamples, disagreement and adjacency metrics separately, along with cost and human craft assessment. Reject a claimed advantage if it vanishes outside the preview or fails the declared acceptance criteria. A larger scene also needs an adapter/admission change and its own test. Current arithmetic proves only the finite examples and conditional structural result; no trained agent, new DSL, runtime integration, learner benefit or manufacturing success was demonstrated.
