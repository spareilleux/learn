---
module_id: phi-007-test-a-learning-gain-against-counterfactuals
department: philosophy
course: "Test a Learning Gain Against Counterfactuals"
level: intermediate
prerequisites: ["phi-001-how-to-argue-well", "cog-007-separate-unaided-recall-from-assisted-success"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Test a Learning Gain Against Counterfactuals

> **Draft scope.** Authored binary outcomes, logical countermodels, exact finite enumeration and primary/source reading. Human technical, fluent-language, musician and learner reviews and deployed course HTML verification remain pending. No participants, intervention, random assignment or causal learning effect were observed.

## The project question

An agent improves a practice workflow and reports a larger posttest score. What premise connects that change to the workflow's benefit? [COG-007](../../cognitive-science/en/cog-007-separate-unaided-recall-from-assisted-success.md) keeps assistance and missingness attached to an endpoint. This lesson asks another question even when every outcome is available: what would the same units have scored at that same later endpoint without the intervention?

The [NIST completely randomized design guide](https://www.itl.nist.gov/div898/handbook/pri/section3/pri331.htm) discusses random assignment of factor levels to experimental units. Its actual web body was read. The binary potential-outcome tables below are our own teaching construction, not NIST observations, a reported study or a recommended sample size.

## 1. Name the unobserved comparison

Use a separate population of eight fictional learners, not the repeated items from COG-007. Their pretest outcomes are `[0,0,1,0,1,0,1,1]`; their later outcomes with the intervention are `[1,1,1,0,1,0,1,1]`. Each binary outcome concerns the same declared type of assessment. The authored before mean is `4/8`, the after mean `6/8`, and their difference `1/4`.

Let `Y1` be each unit's later outcome with the intervention and `Y0` its later outcome without it. The finite-population average effect is the mean of `Y1-Y0` across these eight units. The earlier pretest is observed at a different time. Setting the later `Y0` equal to the pretest requires a substantive assumption about what would otherwise change.

### Practice exercise 1: identify the missing premise

Compute the before/after difference. Which later outcome is missing when everyone receives the intervention, and why is substituting the pretest not a neutral arithmetic step?

> **Answer:** The difference is `6/8-4/8=1/4`. Each unit's later no-intervention `Y0` is unobserved. Equating it to the earlier pretest assumes no relevant change without the intervention; the before/after data alone do not establish that premise.

## 2. Construct worlds that agree on what was observed

Keep the same pretests and treated later outcomes in three authored worlds. In the benefit world, the later no-intervention vector equals the pretest, so the average effect is `1/4`. In the no-effect world, the no-intervention vector equals `Y1`, so the effect is 0. In the harm world, all no-intervention later outcomes are 1, so the effect is `6/8-8/8=-1/4`.

All worlds agree on every supplied before/after observation. They disagree about the missing counterfactual, and therefore the sign of benefit. This is a logical witness of non-identification under these unrestricted premises. It does not assert that all worlds are equally plausible or that the actual workflow helps or harms anyone.

### Practice exercise 2: challenge the causal conclusion

Give the three average effects. Why does agreement on observed improvement fail to distinguish them, and what kind of additional premise or evidence would be needed?

> **Answer:** The effects are `1/4`, 0 and `-1/4`. Their pretests and treated posttests are identical; only the unobserved later no-intervention outcomes differ. A justified assumption about that comparison or an appropriate comparison design is needed. The authored positive change does not choose a world.

## 3. Bound what the binary data alone permit

There are 256 possible binary vectors `Y0` for eight labelled units. With `Y1` fixed at six successes, the smallest possible average effect is `6/8-1=-1/4`; the largest is `6/8-0=3/4`. Both bounds are attainable by a complete `Y0` vector, so the interval is tight for this finite problem with no further restriction.

The [counterfactual record](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/counterfactual-gains.json) enumerates every vector and nine attainable effect levels. Counts of vectors are not a probability distribution over real worlds. The interval is not a confidence interval, and these eight fictional units do not estimate a future learner population.

### Practice exercise 3: derive an honest bound

Derive the unrestricted bounds and name the counterfactual vector attaining each. Does enumerating 256 possibilities give each a probability or make the earlier pretest irrelevant to all possible study designs?

> **Answer:** All-one `Y0` gives the lower bound `-1/4`; all-zero `Y0` gives the upper bound `3/4`. Enumeration assigns no probabilities. Pretests may inform a design or a justified model, but do not constrain the later counterfactual in this unrestricted construction without an added assumption.

## 4. Separate a design's average from one assignment

Now consider a hypothetical future design that assigns four of these eight learners to intervention and four to comparison, uniformly over 70 allocations. This is a different hypothetical observation scheme from the all-treated illustration. Fix each world's potential outcomes and assume a well-defined intervention, consistent observation and no cross-learner interference.

Across all allocations, the mean of the treated-minus-control mean contrast equals the world's finite-population average effect: `1/4`, 0 or `-1/4`. A particular allocation can differ. In the benefit world, assigning learners 1, 2, 4 and 6 to intervention gives treated mean `1/2`; the remaining units' no-intervention outcomes are all 1, giving comparison mean 1 and contrast `-1/2`.

### Practice exercise 4: test a randomization guarantee

Give the number of balanced allocations and the across-allocation mean contrast in the benefit world. Reconstruct the stated negative contrast. Does the design guarantee that each realized contrast has the true effect's sign?

> **Answer:** There are 70 allocations and their mean contrast is `1/4`. Learners 1, 2, 4 and 6 have treated outcomes 1, 1, 0, 0, so their mean is `1/2`; controls 3, 5, 7 and 8 each have no-intervention outcome 1, giving contrast `-1/2`. Unbiasedness across the stipulated assignments does not guarantee the sign or precision of one result. No assignment was actually run here.

## 5. Make the unit and intervention real before attributing progress

If intervention is assigned to learners, repeated item answers from one learner are not additional independently assigned learners. Sharing hints between groups, unequal answer visibility or changing the delayed endpoint can also change the comparison being made. A future design needs explicit intervention/comparison versions, assignment unit and procedure, timing, cue/assistance rules, missingness policy and outcome definition before interpreting a contrast.

GA's [practice-plan tracking labels](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Types/PracticeRoutineTypes.fs#L81-L101) and [RAG evaluation record](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.ML/Rag/RagEvaluationModels.cs#L3-L31) do not provide these hypothetical learner assignments or their observations. This bounds those inspected definitions; it does not claim that every project subsystem lacks richer evidence.

### Practice exercise 5: repair an agent's benefit report

An agent turns eleven response rows from one learner into “eleven randomized participants” and treats a better posttest as proven benefit. Replace the claim and specify the next evidence needed.

> **Answer:** Response rows are attempts linked to their actual learner and item identities, not independently randomized participants. A before/after change describes its recorded endpoint and does not identify benefit without a justified counterfactual comparison. A future claim needs an implemented, versioned comparison and assignment procedure, actual appropriately timed outcomes, assistance/missingness records and checks of its assumptions. Neither this fixed packet nor a practice-plan field supplies that evidence.

The [prepared task and rubric](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/learner-task.md) ask learners to derive the countermodels. Their preparation does not constitute a human review or a causal experiment.
