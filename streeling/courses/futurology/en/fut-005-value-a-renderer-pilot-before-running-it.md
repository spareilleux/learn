---
module_id: fut-005-value-a-renderer-pilot-before-running-it
department: futurology
course: "Value a Renderer Pilot before Running It"
level: intermediate
prerequisites: ["fut-004-scenario-test-an-observatory-renderer", "pm-005-interpret-brutal-coexistence-experiments"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Value a Renderer Pilot before Running It

> **Draft scope.** Authored decision and signal models, exact arithmetic and pinned historical source reading. Human technical, fluent-language and learner reviews and deployed course HTML verification remain pending. No live pilot, renderer, GPU or production switch was run.

## The project question

Would another renderer trial change the decision, or merely produce more reports? [FUT-004](fut-004-scenario-test-an-observatory-renderer.md) compared strategies across scenarios. Here we value information before obtaining it, by considering the actions it could change.

The pinned [BRUTAL README](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/README.md) retains an original coexistence failure and an inconclusive follow-up. [PM-005](../../product-management/en/pm-005-interpret-brutal-coexistence-experiments.md) explains those historical observations. They motivate this question but supply none of the probabilities or loss points below. All project source documents use GA commit `76efbffd5af82b46c3146957a6bd4504008eeb89`; no historical binary was reproduced here.

## 1. State the decision without a pilot

Use two authored latent conditions: F, where a candidate fits the intended use, and U, where it does not. The prior probability of each is `1/2`. Actions are K, keep the current setup, and S, switch to the candidate. Assume these actions are admissible under the required quality and coexistence guards before comparing their consequences.

| Action | Loss in F | Loss in U |
| --- | --- | --- |
| K | 4 | 4 |
| S | 0 | 10 |

The numbers are comparable cardinal teaching points, with lower expected loss preferred. They are not money, milliseconds or measured preferences. Prior expected losses are 4 for K and 5 for S, so keep K. If the probability of F is p, S has expected loss `10*(1-p)`. It beats K only when `p>3/5`; at equality our declared policy keeps K.

### Practice exercise 1: locate the action boundary

Compute both prior expected losses. Solve the probability threshold at which S becomes preferable. Does the threshold estimate how often the real candidate fits?

> **Answer:** K gives 4; S gives `(1/2)*0+(1/2)*10=5`. Solving `10*(1-p)<4` gives `p>3/5`. The threshold follows from the authored losses and preference rule; it does not estimate a real host-condition probability.

## 2. Model what the pilot can tell us

Stipulate a passive pilot with positive outcome probabilities `P(+|F)=4/5` and `P(+|U)=1/5`. It does not change the latent condition. Its negative probabilities are the complements. The [NIST Bayes overview](https://www.itl.nist.gov/div898/handbook/apr/section2/apr1a.htm) explains updating a prior using a likelihood and normalizing over possible conditions.

Each outcome has prior probability `1/2`. After a positive result, `P(F|+)=4/5`; after a negative result, `P(F|-)=1/5`. A positive result therefore selects S with conditional expected loss 2. A negative result selects K with loss 4. These likelihoods are explicit premises, not a fitted classifier or the success rate of the historical BRUTAL trials.

### Practice exercise 2: reverse the conditioning

Compute the probability of a positive result and the posterior probability of F after it. Which action follows? Is `P(+|F)` automatically the same quantity as `P(F|+)`?

> **Answer:** `P(+)=(1/2)*(4/5)+(1/2)*(1/5)=1/2`. Then `P(F|+)=((1/2)*(4/5))/(1/2)=4/5`; S has expected loss 2 and is selected. The conditional probabilities happen to have equal values in this symmetric example, but they condition on different events and are not generally interchangeable.

## 3. Compare imperfect and perfect information

Before paying for the pilot, average the best result-dependent decisions: `(1/2)*2+(1/2)*4=3`. The gross expected value of sample information is the prior best loss minus this value: `4-3=1` point.

Perfect information would reveal F or U before acting. Choose S in F, K in U, giving expected loss `(1/2)*0+(1/2)*4=2`. Its gross value is `4-2=2` points. The [MIT decision-analysis lecture](https://ocw.mit.edu/courses/15-053-optimization-methods-in-management-science-spring-2013/b68f3b255275ffa42099958e373248b1_MIT15_053S13_lec19.pdf#page=7) distinguishes original, perfect and imperfect information. We use loss reduction rather than its payoff-increase convention.

### Practice exercise 3: calculate the two values

Calculate gross sample-information and perfect-information values. Why would treating this noisy pilot as perfect overstate its modeled benefit?

> **Answer:** The values are 1 and 2 points respectively. The noisy pilot sometimes gives the unfavorable signal for the actual condition, so its optimized expected loss is 3 rather than the perfect-information value 2. Assigning perfect accuracy to this pilot changes the stipulated information channel.

## 4. Charge for obtaining information

Let the pilot cost 0.6 points on the same declared loss scale. Total expected loss becomes `3+0.6=3.6`, an improvement of `4-3.6=0.4` over keeping K without a pilot. A cost of 1 point would exhaust this pilot's gross benefit. A hypothetical perfect test costing 3 points would also be unattractive here: its gross value is only 2.

The perfect-information value is a ceiling for information about this state under the same action set, losses and timing assumptions. It is not a budget for every possible experiment: a new test could change the available actions, consume time during which the state changes, or alter the workload itself. Those are different decision models.

### Practice exercise 4: reject an overpriced test

What is the net value of the 0.6-point noisy pilot? What about a perfect test costing 3 points? May engineering minutes be added directly to these loss points?

> **Answer:** The noisy pilot's net value is 0.4 points. The perfect test's net value is `2-3=-1` point. Raw minutes cannot be added to the point scale without a declared conversion or a different objective; no actual time or cost was measured here.

## 5. Ask whether any action can change

If only K is permitted, information cannot change the action. The posterior can move while gross decision value remains 0. More generally, information can be ignored under this model, so optimized gross value is nonnegative; it can still be zero, and acquisition costs can make net value negative.

A useful next investigation specifies the real decision, admissible actions, consequence scale, prior basis, signal calibration, timing and stopping rule. The historical [M3 report](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/evidence/m3-20261020-000727.md) has varying controls and its own binary/dirty-state boundary. It does not calibrate this hypothetical passive pilot. [CYB-007](../../cybernetics/en/cyb-007-update-beliefs-without-counting-a-trial-twice.md) checks whether successive reports represent fresh evidence; [PM-006](../../product-management/en/pm-006-test-a-pilot-against-its-decision-horizon.md) adds migration and reuse costs.

### Practice exercise 5: separate learning from decision value

Suppose only K is allowed, but the pilot still changes the posterior from `1/2` to `4/5` after a positive result. What is its gross decision value? What evidence is missing before the original 0.4-point result could justify a real renderer trial?

> **Answer:** Gross decision value is 0 because the permitted action remains K. A real trial decision needs a justified consequence scale, admissible alternatives, calibrated or explicitly defended prior/likelihood assumptions, real acquisition costs, timing and quality/coexistence guards. The 0.4-point result is conditional arithmetic, not authorization or a measured benefit on the machine.

The [fixed decision record](../../../../code/streeling/evidence/pilot-value-2026-10-22/pilot-decision.json) preserves the complete authored model and its exact rational values.
