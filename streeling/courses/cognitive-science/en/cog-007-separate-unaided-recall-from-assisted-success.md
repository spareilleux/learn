---
module_id: cog-007-separate-unaided-recall-from-assisted-success
department: cognitive-science
course: "Separate Unaided Recall From Assisted Success"
level: intermediate
prerequisites: ["cog-002-feedback-integrity-fretboard-recall", "cog-003-calibrating-fretboard-confidence", "gaa-007-turn-a-voicing-result-into-a-practice-item"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Separate Unaided Recall From Assisted Success

> **Draft scope.** One invented learner's binary attempt history, exact denominator calculations and primary/source reading. Human technical, musician, fluent-language and learner reviews and deployed course HTML verification remain pending. No real learner, practice flow, memory model or delayed assessment was observed.

## The project question

A GA practice report says that six of seven final answers are correct. Does that mean the learner recalled six answers without help? We need the event history and the stated endpoint. [GAA-007](../../guitar-alchemist-academy/en/gaa-007-turn-a-voicing-result-into-a-practice-item.md) defines a target, cue policy and acceptance rule. Here all binary outcomes are authored for arithmetic; no user supplied the responses.

The [Roediger and Karpicke publisher abstract](https://www.psychologicalscience.org/journals/psychological-science/j.1467-9280.2006.01693.x/) reports different immediate and delayed outcomes for prose recall under its studied conditions. Only that abstract was read; an attempted author-hosted full-PDF fetch timed out. The study motivates naming the assessment delay, but does not establish a guitar-learning effect or a universal practice schedule. No study effect size is imported into this packet.

## 1. Count eligible first responses

Offer eight practice items to one fictional learner. Seven have an initial answer. Three initial answers are correct, but P03 had the answer visible before responding and cannot count as unaided recall under our rule. P08 has no response. The remaining six observed, eligible first responses contain two correct answers.

| Item | Initial response | Answer visible beforehand | Later response |
| --- | --- | --- | --- |
| P01 | correct | no | none |
| P02 | wrong | no | correct after hint |
| P03 | correct | yes | none |
| P04 | wrong | no | correct after hint |
| P05 | wrong | no | wrong retry without hint |
| P06 | correct | no | none |
| P07 | wrong | no | correct after hint |
| P08 | missing | no | none |

The raw first-answer rate is `3/7`; the observed eligible first-unaided rate is `2/6=1/3`. Excluding P03 protects the declared endpoint. It does not erase the exposure from the history or turn missing P08 into a wrong answer. [COG-002](cog-002-feedback-integrity-fretboard-recall.md) separately audits the answer key; a valid key alone cannot resolve these assistance and sampling choices.

### Practice exercise 1: apply the eligibility rule

Calculate the raw first-answer and eligible observed first-unaided rates. Explain why both the correct P03 response and missing P08 need distinct statuses.

> **Answer:** Raw first answers give `3/7`; removing the answer-exposed P03 leaves `2/6=1/3` among observed eligible responses. P03 is ineligible for this unaided endpoint, not numerically wrong. P08 is missing, not an observed failure. Retain both statuses and their reasons.

## 2. Do not pool attempts as if they were new items

The history contains seven completed initial answers and four retries: eleven completed response rows. Three retries are correct, so pooling every response gives `6/11`. Choosing only each item's final observed answer instead gives `6/7`. The first-unaided endpoint remains `2/6`.

These three fractions answer different questions. Repeated attempts are attached to the same item and learner, often after feedback. They are not eleven independent learners or eleven fresh first-response trials. A dashboard can report several endpoints if it labels their denominator and assistance policy rather than silently selecting the largest rate.

### Practice exercise 2: compare aggregation policies

Give the all-response and final-observed-item rates. Why can neither replace the first-unaided rate merely because it includes more rows or is larger?

> **Answer:** All responses give `6/11`; final observed item answers give `6/7`. Retries, visible answers and assistance change the sampled event. Extra dependent rows do not redefine them as fresh unaided trials, and the final rate answers a different endpoint.

## 3. Preserve useful assisted success without relabelling it

The three hinted retries all succeed, giving `3/3` for that selected assisted endpoint. This can be useful feedback about what happened in the authored trace. It is not evidence that hints cause a benefit, that every hint succeeds, or that the answers can later be recalled unaided.

There are seven practice offers eligible in principle after excluding the leaked item, but only six responses. If the one missing binary result is unconstrained, the complete-offer correctness fraction lies between `2/7` and `3/7`. Treating a nonresponse as failure can define a separate completion-aware endpoint, but it must be declared as that policy, not presented as observed recall.

### Practice exercise 3: retain assistance and missingness

Calculate the hinted-retry success rate and the eligible full-offer bounds. Would the hint rate prove a causal or delayed benefit, or justify erasing the missing response?

> **Answer:** Hinted retries give `3/3`. Eligible full-offer bounds are `2/7` to `3/7`, according to whether the unobserved binary result is wrong or correct. The selected assisted successes establish no causal or delayed benefit, and they do not supply the missing value.

## 4. Bound an incomplete delayed assessment

A separate authored set contains eight held-out offers at a stipulated delay of 24 hours. Six have responses: five correct, one wrong. Two are missing. The observed-response rate is `5/6`. The full eight-offer rate can range from `5/8` to `7/8` when the missing binary outcomes are otherwise unconstrained.

That interval is a deterministic completion bound, not a confidence interval or a model of why people fail to respond. Its four possible missing-value completions are retained in the [trace record](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/recall-trace.json). Neither choosing the optimistic endpoint nor automatically imputing zero creates an observed delayed result. The items' comparability and difficulty also remain unmeasured.

### Practice exercise 4: report a delayed denominator

Give the observed and full-offer bounded results. Why is “five of six responded correctly, therefore five of eight is the measured recall rate” an incomplete report?

> **Answer:** Observed responses give `5/6`; the full-offer bounds are `5/8` to `7/8`. Five of eight is the lower completion bound or an explicitly chosen missing-as-failure policy, not a direct measurement of both missing answers. Report offers, responses, delay, assistance policy and missingness together.

## 5. Keep source metrics and learning evidence separate

GA's pinned [practice tracking vocabulary](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Types/PracticeRoutineTypes.fs#L81-L101) includes accuracy and improvement-rate labels. Its [retrieval evaluation record](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.ML/Rag/RagEvaluationModels.cs#L3-L31) records query metrics. Neither selected definition supplies this history's real before-feedback response, cue status, attempt lineage or delayed observation.

### Practice exercise 5: replace an inflated learning claim

An agent calls final `6/7` “proven unaided retention improved by the hint system.” Write a bounded replacement and specify the missing evidence.

> **Answer:** In the authored trace, final observed item answers are `6/7`, observed eligible first-unaided answers `2/6`, and selected hinted retries `3/3`. The delayed authored record has `5/6` observed with full-offer bounds `5/8` to `7/8`. None is real learner evidence or causal benefit. A future claim needs actual timestamped answers under the declared cue/assistance protocol, a specified comparable delayed endpoint and a justified comparison design.

[PHI-007](../../philosophy/en/phi-007-test-a-learning-gain-against-counterfactuals.md) next explains why even a complete before/after observation would not by itself identify the intervention's effect.
