---
module_id: pm-006-test-a-pilot-against-its-decision-horizon
department: product-management
course: "Test a Pilot against Its Decision Horizon"
level: intermediate
prerequisites: ["pm-005-interpret-brutal-coexistence-experiments", "fut-005-value-a-renderer-pilot-before-running-it"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Test a Pilot against Its Decision Horizon

> **Draft scope.** Authored loss/cost/horizon model, exact arithmetic and pinned source reading. Human technical, fluent-language and learner reviews and deployed course HTML verification remain pending. No migration, renderer trial, engineering-time saving or production rollout was measured.

## The project question

A team proposes a pilot because its result might help many future decisions. How many decisions can actually reuse that information, and does switching have a cost? [FUT-005](../../futurology/en/fut-005-value-a-renderer-pilot-before-running-it.md) valued one information channel without migration cost. Here we add a one-time charge and reoptimize the actions rather than append a cost to an old recommendation.

The [BRUTAL README](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/README.md) records a severe original coexistence observation and an inconclusive follow-up. [PM-005](pm-005-interpret-brutal-coexistence-experiments.md) explains why their conditions matter. They do not measure the horizon, charges or probability model below.

## 1. Declare what persists across the horizon

Use the same authored F/U prior `1/2`, action losses K 4 in either condition and S 0 in F or 10 in U, and pilot likelihoods `4/5` and `1/5`. One pilot costs 0.6 points. Its result is reused across N otherwise identical decisions under the same stable latent condition and consequence model. These are strong assumptions, not a count of arbitrary future tasks.

Charge 2 additional points once if S is chosen for the horizon; charge nothing for migration if K is chosen. All quantities use the same cardinal teaching scale. Before a pilot, K costs `4*N`; S has expected cost `5*N+2`, so K remains the prior choice for positive N. There is no measured conversion from minutes, money or frame times into these points.

### Practice exercise 1: include the one-time charge

For N equal to 2, compute the prior total expected losses for K and S, including migration. Why is it wrong to multiply the migration charge by N in this model?

> **Answer:** K costs `4*2=8`; S costs `5*2+2=12`. The model charges migration once when S is selected, not once per decision. A per-use charge would be a different model requiring a different calculation.

## 2. Recompute the result-dependent actions

After a positive signal, posterior F is `4/5`. Compare K cost `4*N` with S cost `2*N+2`. After a negative signal, compare K `4*N` with S `8*N+2`. Ties keep K.

At N equal to 1, the positive branch ties at 4, so K is retained and no migration charge is paid. At N equal to 2, the positive branch selects S at 6 rather than K at 8; the negative branch keeps K at 8 rather than S at 18. Adding migration therefore changes what the pilot can justify, especially for short horizons.

### Practice exercise 2: test the short horizon

Which actions follow a positive signal at N equal to 1 and 2? What migration charge is actually paid in each selected branch? Does the no-migration recommendation from FUT-005 transfer unchanged?

> **Answer:** At N equal to 1, both alternatives cost 4 and the tie policy keeps K, paying no migration charge. At N equal to 2, S costs 6 versus K at 8 and pays the one-time charge 2. The earlier no-migration policy must be recomputed under the new consequences.

## 3. Average the pilot policy and find break-even

The two signal outcomes each have probability `1/2`. For positive integer N, the optimized expected loss before pilot cost is `3*N+1`; after the 0.6 charge it is `3*N+1.6`. At N equal to 1 the tied branch has the same optimal loss, even though the chosen K action pays no migration. Keep that distinction when reporting cost components.

| N | Keep without pilot | Expected total with pilot | Net gain |
| --- | --- | --- | --- |
| 1 | 4 | 4.6 | -0.6 |
| 2 | 8 | 7.6 | 0.4 |
| 5 | 20 | 16.6 | 3.4 |
| 10 | 40 | 31.6 | 8.4 |

The modeled gain is `N-1.6`, positive when `N>1.6`. The first positive integer horizon is 2. This is a conditional break-even calculation, not an observed saving or justification for counting unrelated workloads as identical uses.

### Practice exercise 3: find the useful horizon

Calculate the net gain at N equal to 1 and 2 and identify the first positive integer horizon. At N equal to 5, what total loss is predicted with the pilot?

> **Answer:** Gains are -0.6 and 0.4 points; the first positive integer horizon is 2. At N equal to 5, expected total loss is `3*5+1.6=16.6`. All results rely on the authored stable-state, reusable-signal and comparable-loss assumptions.

## 4. Preserve the same costs in an information ceiling

Perfect information would choose S in F with total cost 2 and K in U with cost `4*N`. Its expected loss is `2*N+1` for positive integer N. Against prior K at `4*N`, the gross perfect-information ceiling is `2*N-1`.

At N equal to 1 the ceiling is 1 point, smaller than FUT-005's 2-point ceiling without migration. The imperfect pilot has zero gross decision value at this horizon before its acquisition charge, because neither signal changes the chosen action. A ceiling is not a promise that an available noisy test attains it. The [MIT value-of-information lecture](https://ocw.mit.edu/courses/15-053-optimization-methods-in-management-science-spring-2013/b68f3b255275ffa42099958e373248b1_MIT15_053S13_lec19.pdf#page=7) defines information value against the same original decision problem; changing costs changes that problem.

### Practice exercise 4: compare like with like

For N equal to 2, calculate the perfect-information expected loss and ceiling with migration. May the no-migration ceiling simply be reused? Does a 3-point ceiling mean the imperfect pilot is worth 3 points?

> **Answer:** Perfect-information expected loss is `2*2+1=5`, versus baseline 8, giving ceiling 3. Reusing a ceiling that omits migration compares different problems. The imperfect pilot's gross value here is only `8-7=1` point before its 0.6 acquisition charge, so it does not attain the perfect-information ceiling.

## 5. Make information reuse a falsifiable assumption

The [historical M2 report](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/evidence/m2-20261019-235218.md) and [M3 report](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/evidence/m3-20261020-000727.md) name different revisions with uncommitted changes and varying controls. They illustrate why one must check comparability before multiplying a result across a horizon. They do not establish the same hidden condition for every future scene, driver or task.

A proposed pilot record should state the decision scope, reuse assumptions, allowed actions, one-time versus per-use charges, cost units, effective mode and evidence-expiry trigger. A new scene or host can invalidate reuse without proving the candidate is bad. The simpler alternative is to keep the current setup while collecting the minimum comparable evidence needed for the actual decision. A new DSL is optional; a clear typed record can express these distinctions.

### Practice exercise 5: challenge exaggerated reuse

An agent applies the N equal to 10 gain of 8.4 points to ten unrelated scenes on different hosts. What assumption failed? State an expiry trigger and the evidence needed before claiming actual savings.

> **Answer:** Ten tasks are not automatically ten identical decisions under one stable latent condition and calibrated signal. A change of scene, workload, host, driver, effective mode or measurement protocol should trigger reassessment of reuse. Actual savings require comparable outcomes, real acquisition/migration costs, a justified consequence scale and the required quality/coexistence guards; no such saving was measured here.

The [fixed horizon record](../../../../code/streeling/evidence/pilot-value-2026-10-22/decision-horizons.json) preserves the exact branch policies, including the N equal to 1 tie and its zero paid migration charge.
