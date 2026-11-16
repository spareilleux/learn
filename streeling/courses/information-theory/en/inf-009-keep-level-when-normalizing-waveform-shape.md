---
module_id: inf-009-keep-level-when-normalizing-waveform-shape
department: information-theory
course: "Keep Level When Normalizing Waveform Shape"
level: intermediate
prerequisites: ["inf-005-quantization-and-indistinguishable-renders", "inf-008-keep-phase-when-waveform-identity-matters"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Keep Level When Normalizing Waveform Shape

> **Draft scope.** Authored real vectors and pinned source reading. Human technical, musician, fluent-language and learner reviews and deployed course HTML verification remain pending. No new audio render, perceptual result or statistical validation was produced.

## The project question

An agent hands off a normalized shape and a perfect correlation score. Can another agent recover the signal level? [INF-005](inf-005-quantization-and-indistinguishable-renders.md) studies quantization loss; [INF-008](inf-008-keep-phase-when-waveform-identity-matters.md) preserves phase. Here positive scaling and offsets disappear under centered normalization.

## 1. Define the descriptor precisely

The [fixed vectors](../../../../code/streeling/evidence/audio-comparison-2026-10-23/normalized-shape.json) use population standard deviation, dividing variance by frame count N rather than N-1:

```text
x = [-.25, 0, .25, .5]
y = .5*x + .25 = [.125, .25, .375, .5]
mu_x = 1/8; sigma_x = sqrt(5)/8
mu_y = 5/16; sigma_y = sqrt(5)/16
z[n] = (sample[n] - mu)/sigma
z_x = z_y = [-3, -1, 1, 3]/sqrt(5)
```

The [NIST Pearson definition](https://www.itl.nist.gov/div898/software/dataplot/refman2/auxillar/correlat.htm) uses centered vectors. The common normalization factors cancel in its ratio. Here correlation is 1, although the raw difference RMS is about .233853587. Correlation is not the probability that two signals are equal.

### Exercise 1 — Identify what the descriptor forgets

Verify the means, population standard deviations and equal normalized vectors. Does correlation 1 imply raw equality?

> **Answer.** The means are .125 and .3125. Centering gives vectors proportional by .5, so their standard deviations are sqrt(5)/8 and sqrt(5)/16. Division produces the same normalized vector. The raw difference is [.375, .25, .125, 0], with nonzero RMS about .233853587. Perfect positive correlation therefore does not imply raw equality, unchanged level or a listening verdict.

## 2. Preserve the inverse metadata

For any nonconstant vector and positive a, centering and normalizing a*x+b gives the same z as x. A shape-only descriptor cannot distinguish that whole family. Retaining every normalized sample, mean, standard deviation and frame count permits the inverse in real arithmetic:

```text
sample[n] = mu + sigma*z[n]
```

This is not a proof that rounding, float serialization, lossy compression or a reduced descriptor preserves original bytes.

### Exercise 2 — Repair the handoff

Which extra values distinguish x from y? Does retaining only the shared normalized vector and N suffice?

> **Answer.** Retain the corresponding mean and population standard deviation along with N, every z sample and their order. The two different mean/standard-deviation pairs reconstruct different raw vectors. Shared z and N alone cannot restore the lost positive scale and offset. A reduced feature vector or rounded storage would require its own reconstruction-error and byte-format analysis.

## 3. Absolute correlation can also erase polarity

Let the inverted vector be -x. Its normalized vector is -z_x, so signed Pearson correlation with x is -1. Applying absolute value gives 1, just as for y. Mathematically, x + (-x) is the zero vector. No playback, routing or audible cancellation was observed.

### Exercise 3 — Choose a score for the claim

Why is absolute correlation unsafe as proof of unchanged waveform polarity? What should be retained?

> **Answer.** It maps both perfectly aligned and perfectly inverted centered shapes to 1. Keep the signed correlation, polarity policy, original samples or a reversible representation, and raw residual. The mathematical cancellation control exposes information discarded by the absolute score. It does not establish perceptual equivalence, measured interference in a room or a probability of correctness.

## 4. Constant signals are a distinct case

For [.25, .25, .25, .25], population standard deviation is zero. The normalized vector and Pearson correlation with it are undefined, while raw RMS is .25. An identical copy can still satisfy raw equality. A separate constant status, mean and count can describe this vector without dividing by zero.

### Exercise 4 — Avoid a fabricated score

An agent writes correlation 1 whenever both inputs are constant. Is that the defined Pearson result?

> **Answer.** No. The denominator vanishes, so Pearson is undefined. Return that status and compare constants directly if equality is the task. Keep mean and N for reconstruction; raw RMS remains valid. An application may define another constant-case rule, but must name it rather than presenting it as Pearson correlation.

## 5. Put metadata before abstraction

The pinned [Learn runner](https://github.com/spareilleux/learn/blob/49ad4cf7db680f031b3a3fb5b6ee118464ad099f/code/streeling/guitar-runtime/run.mjs) keeps raw float and PCM16 comparisons separate. Its RMS calculation includes a numerical floor before logarithms. It does not implement this new normalized-shape or Pearson descriptor. The [source record](../../../../code/streeling/evidence/audio-comparison-2026-10-23/source-observations.json) distinguishes source inspection, authored arithmetic and historical runtime evidence.

### Exercise 5 — Specify a useful agent handoff

Design a minimal comparison record using source locations. How would you decide whether a more abstract DSL helps?

> **Answer.** Retain source revisions, signal boundary, sample clock, channel order, format, N, normalization rule, mean, population standard deviation, constant status, signed/absolute policy and raw level/residual. The present toy vectors have no measured clock or audio format; do not invent one. Locate the runner's float serialization, PCM16 conversion and RMS windows. Compare explicit records against direct sample calculations, including inversion and constant controls, before adding a DSL. Measure omissions, errors and cost on actual tasks; neither new syntax nor a perfect shape score proves improvement. No such user study or new implementation exists here.

## Learner handoff

Use the [source-assisted task](../../../../code/streeling/evidence/audio-comparison-2026-10-23/learner-task.md) and [prepared rubric](../../../../code/streeling/evidence/audio-comparison-2026-10-23/reviewer-rubric.json). Retain actual answers and assistance; learner acceptance remains null. [AUD-009](../../audio-engineering/en/aud-009-declare-alignment-before-a-null-test.md) makes removed gain and timing explicit rather than hiding them in a score.
