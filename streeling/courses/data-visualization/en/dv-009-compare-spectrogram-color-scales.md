---
module_id: dv-009-compare-spectrogram-color-scales
department: data-visualization
course: "Compare Spectrograms Without Hiding a Gain Change"
level: intermediate
prerequisites: ["dv-007-optick-partition-small-multiples", "aud-006-calibrate-spectral-amplitudes", "cs-013-preserve-spectral-axes-and-units"]
estimated_duration: "35 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Compare Spectrograms Without Hiding a Gain Change

> **Draft scope.** Measured display analysis on retained WAVs with a constructed gain control. Human technical review, fluent-language review, learner attempts, listening and public course HTML verification remain pending. No new guitar render or IX binary run was performed.

## The project question

A GA improvement agent places two spectrograms side by side and says they have the same intensity. If each image was normalized by its own peak, what did that comparison actually test? A display can preserve a pattern while erasing a gain difference. This lesson makes that failure visible with known inputs, extending the shared-scale principle from [DV-007](dv-007-optick-partition-small-multiples.md).

Open the [six-panel figure](../../../../code/streeling/evidence/spectral-views-2026-10-22/spectrogram-reference-comparison.png) and its [numerical record](../../../../code/streeling/evidence/spectral-views-2026-10-22/display-comparison.json). [Matplotlib's normalization model](https://matplotlib.org/stable/users/explain/colors/colormapnorms.html) maps numeric limits into colors. Sharing a colormap and numeric limits is only part of comparability: the values supplied to it must also share the intended reference.

## 1. Identify the treatments before comparing colors

Columns are labeled `B`, `C` and `0.5B`. The first two are the retained baseline and actual decay candidate from the earlier native guitar experiment. The third is a constructed copy of the decoded baseline multiplied by 0.5. It is a display control, not another physical guitar render or the actual candidate. Samples are decoded PCM16 integers divided by 32768; [AUD-006](../../audio-engineering/en/aud-006-calibrate-spectral-amplitudes.md) explains the amplitude estimator applied before plotting.

The figure shows frequencies through 2000 Hz. Horizontal coordinates use frame-start time and hop-sized display cells; each analyzed frame still spans 2048 samples. [CS-013](../../computer-science/en/cs-013-preserve-spectral-axes-and-units.md) explains that coordinate contract. The letters and formula labels are shared across locales; this prose supplies their interpretation.

### Practice exercise 1: identify the control

Which pair isolates an exact gain change, and which pair compares the earlier decay treatments? Why would calling all three columns separate engine renders weaken the experiment record?

> **Answer:** `B` versus `0.5B` isolates the constructed gain multiplier 0.5. `B` versus `C` compares the earlier baseline and decay candidate. The half-gain array was made from decoded baseline samples without another engine execution. Calling it a separate render would misidentify the intervention and overstate runtime evidence.

## 2. Give the colorbar a reference, not just a range

The upper row uses `20*log10(max(A/1,1e-4))`, with fixed reference peak amplitude 1. All panels use color limits -80 to 0 dB. The lower row first divides each full matrix by its own maximum, then uses `20*log10(max(A/max(A),1e-4))` with the same numeric color limits. Its reference is each panel's own peak. Maxima are computed over the full matrix before cropping the visible frequency range.

These are two distinct questions. The upper row retains amplitude differences relative to the declared common reference where clipping does not hide them. The lower row exposes a pattern relative to each matrix's peak. The same color in different rows therefore need not mean the same amplitude. Neither row is a loudness, realism or preference score, and the amplitude estimator is not a universal measure of individual guitar partials.

### Practice exercise 2: interpret an equal color

Two lower-row cells have the same color and numeric value. What equality can that establish under the stated normalization? Does it establish equality of the original amplitudes or justify comparing that color directly with the upper row?

> **Answer:** It can establish equal displayed level relative to each panel's own maximum, subject to floor clipping. It does not establish equal original amplitudes. The upper row uses common reference 1 while the lower row uses panel maxima, so cross-row color equality is not a shared-amplitude equality claim.

## 3. Use a control that should disappear under normalization

Before flooring, halving amplitude changes its logarithmic value by `20*log10(0.5)`, approximately -6.02059991 dB. In the computed control there are 6359 cells where both fixed-reference values are at or above the -80 dB floor. Their measured differences agree with that shift within `1e-10` dB. Cells hidden by the floor cannot demonstrate an unchanged difference.

For the relative row, `max(0.5*A) = 0.5*max(A)` for this nonzero matrix. Dividing by the panel maximum cancels the gain. The computed maximum difference between the baseline and half-gain relative views is 0 dB. The normalization therefore passes a pattern-invariance test and fails as evidence that input gain was unchanged. The floor is applied after the ratio; moving it earlier changes this argument.

### Practice exercise 3: predict and verify the difference

Calculate the expected fixed-reference shift for multiplier 0.5 and explain why the relative images match. Which cells must be excluded from a claim that every displayed fixed-reference difference equals that shift?

> **Answer:** The shift is `20*log10(0.5)`, approximately -6.02059991 dB. In the relative view both numerator and maximum halve, so their ratio stays the same before the shared floor. Exclude cells clipped by the floor in either fixed-reference panel; their displayed difference need not retain the unmodified shift. This result concerns the constructed control, not the actual decay candidate.

## 4. Keep cropping and normalization order explicit

If a display recomputes its maximum after each frequency crop, zooming can recolor data that did not change. If it retains the full-matrix maximum as this figure does, the crop changes visibility while keeping that reference fixed. Both choices can serve a purpose, but the reader must know which one was used. Otherwise an agent can treat a view manipulation as a change in a guitar render.

### Practice exercise 4: audit a changing display

A reviewer zooms to a narrower frequency range and sees brighter retained cells, even though source values are unchanged. What normalization behavior could explain it? State this figure's policy and what a comparison receipt should bind.

> **Answer:** Recomputing the panel maximum from the smaller visible region can change the reference and brighten unchanged values. This figure uses each full matrix's maximum before frequency cropping. Bind the source values and hashes, quantity estimator, reference domain, crop, floor and color limits so another reader can distinguish a data change from a display change.

## 5. Return to the declared acceptance measure

The actual candidate's earlier [decay-gate result](../../../../code/streeling/evidence/guitar-runtime-2026-10-22/results.json) remains failed: improvement about 0.11416615 dB, required improvement 1 dB. That number is an error improvement in the earlier decay measure; the approximately -6.02059991 dB control shift is a different quantity from a different intervention. Do not combine them into a new acceptance score.

### Practice exercise 5: write a defensible decision

An agent claims “The lower images match, so the candidate is equivalent, the gain is unchanged and the decay gate passes.” Replace that statement with a decision supported by this experiment, and specify the next evidence needed for a broader musical claim.

> **Answer:** The baseline and constructed half-gain control have equal panel-relative views under the stated transform and normalization, even though their fixed-reference amplitudes differ. This does not establish equivalence of the actual candidate, unchanged input gain or a passed decay gate. Keep the failed gate. A broader musical claim needs a separately declared feature or listening question, controlled inputs and an executed comparison appropriate to that question.

## Evidence boundary

The [analysis receipt](../../../../code/streeling/evidence/spectral-views-2026-10-22/execution.json) records installed versions, figure hash and calculation checks. The [protocol](../../../../code/streeling/evidence/spectral-views-2026-10-22/experiment-plan.md) distinguishes predictions, retained audio and constructed controls. This is a scientific display artifact with numerical evidence, not a deployed editor extension, human listening result or measured learning benefit.
