---
module_id: dv-010-show-pitch-errors-and-missing-estimates
department: data-visualization
course: "Show Pitch Errors and Missing Estimates"
level: intermediate
prerequisites: ["dv-003-instrument-cohorts-and-units", "dv-009-compare-spectrogram-color-scales"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Show Pitch Errors and Missing Estimates

> **Draft scope.** An original six-row diagnostic table and scientific plot, plus a bounded retained-guitar analysis used separately. Human technical, fluent-language and learner reviews and deployed course HTML verification remain pending. The plotted rows are authored; they are not participant data or an actual guitar pitch trace.

## The project question

A pitch dashboard draws a clean line because it replaces missing values with zero, drops an octave outlier and reports accuracy only where the detector answered. Such a display can conceal exactly the failures an audio-improvement loop needs to inspect. This lesson preserves availability, error and denominator as different quantities.

The [complete authored table](../../../../code/streeling/evidence/pitch-estimates-2026-10-22/pitch-trace.json) uses a reference of 100 Hz. It is deliberately separate from [GAS-005](../../guitar-acoustics/en/gas-005-separate-a-partial-peak-from-a-period.md)'s actual retained E2 analysis. Do not merge their references or describe this table as a new engine measurement.

## 1. Make unavailable rows explicit

| Authored time, seconds | Reported frequency, Hz | State |
| --- | --- | --- |
| 0 | 100 | reported |
| 0.1 | 200 | reported |
| 0.2 | absent | missing |
| 0.3 | 100.5 | reported |
| 0.4 | 0 | invalid input |
| 0.5 | 99.5 | reported |

There are four positive finite reports, one missing row and one invalid zero input. Missing and invalid are distinct diagnostic states. Neither becomes a valid zero-frequency estimate, a zero-cent error or an interpolated observation. Filtering for a metric is permitted only when the excluded states and denominator remain visible.

### Practice exercise 1: preserve the two unavailable states

How many rows support a logarithmic frequency-error calculation? Why should the missing row and zero input not both be displayed as zero-cent errors?

> **Answer:** Four rows support the calculation. The missing row has no frequency, while the zero input is invalid for a positive-frequency logarithm. Plotting either at zero cents would falsely assert a valid estimate exactly matching the reference. Keep their states visible without inventing numeric pitch values.

## 2. Convert a frequency ratio to a declared error unit

For a valid reported frequency f and positive reference, define signed error as `1200*log2(f/reference)`. This gives 0 cents at 100 Hz and +1200 at 200 Hz. The 100.5 and 99.5 Hz rows give approximately +8.634601685 and -8.677883077 cents. Equal additive Hz offsets around the reference are not exactly symmetric on a logarithmic scale.

The original plot retains all four valid errors, including the octave outlier, and places availability in a separate categorical panel. There are no connecting pitch segments, invented error bars or interpolated estimates. The [plot-point record](../../../../code/streeling/evidence/pitch-estimates-2026-10-22/plot-points.json) binds the underlying rows and image.

![Authored cent errors with the octave outlier retained and missing/invalid states shown separately](https://raw.githubusercontent.com/spareilleux/learn/c953607dc38126877032dd5919e57d894971b257/code/streeling/evidence/pitch-estimates-2026-10-22/pitch-errors-and-availability.png)

The single English-labelled figure is an original mathematical illustration; the surrounding localized text explains its quantities. Its categorical vertical positions are not pitch-error measurements. The full vertical range includes the +1200-cent point even though this compresses the small-error cluster.

### Practice exercise 2: interpret the octave point

Calculate the 200 Hz error relative to 100 Hz. Should an agent silently divide it by 2 or remove it to make the trace look stable?

> **Answer:** `1200*log2(200/100)=1200` cents. Dividing by 2 or removing the row would change the data or evaluation convention. A separately declared octave-invariant metric can answer another question, but it must not replace the displayed octave-sensitive result silently. Preserve the point and explain any additional view.

## 3. Compare summaries without changing the scale secretly

The arithmetic mean of the four valid frequencies is 125 Hz, whose cent error is approximately 386.313713865. The mean of their signed cent errors is instead approximately 299.989179652 cents; its corresponding geometric-mean frequency is approximately 118.919968239 Hz. These are different operations. The median signed error is approximately 4.317300843 cents, while maximum absolute error remains 1200 cents.

A small median can coexist with a large octave outlier. Mean signed error can also conceal cancellation in another dataset. Choose a summary for a declared question and retain the distribution or relevant failures. None of these four-row summaries supplies a confidence interval or a general detector-quality verdict.

### Practice exercise 3: identify the changed aggregation

Why do converting the mean frequency and averaging signed cents give different answers? Which pair of reported statistics demonstrates that a small median does not remove a large failure?

> **Answer:** The logarithm is nonlinear, so taking the arithmetic mean before the logarithm differs from averaging logarithmic ratios. Here the converted arithmetic mean is approximately 386.313713865 cents, while mean signed error is approximately 299.989179652 cents. Median approximately 4.317300843 and maximum absolute error 1200 coexist; the median does not erase the octave failure.

## 4. Publish availability with the accuracy denominator

Under the authored rule of being within 10 cents, three of four valid reports pass. Conditional accuracy is therefore `3/4`, or 75%. Coverage is `4/6`, approximately 66.666666667%. A joint criterion requiring an available valid report within tolerance passes `3/6`, or 50% of all rows. These three percentages answer different questions.

The joint rule counts missing and invalid rows as not meeting that combined success condition. It does not transform them into numeric pitch errors. State the rule before comparing methods; otherwise abstaining more often can make a conditional-only display look better without improving the recipient's task.

### Practice exercise 4: expose the omitted denominator

A dashboard says “75% accurate” and hides unavailable rows. Give the coverage, conditional and joint results, and explain what each denominator contains.

> **Answer:** Coverage is `4/6`, approximately 66.666666667%, over all rows. Conditional accuracy is `3/4`, or 75%, over valid reports only. Joint success is `3/6`, or 50%, over all rows under the declared availability-and-tolerance rule. These are authored fixture statistics, not measured deployment or listener performance.

## 5. Keep a signal score out of the confidence legend

In the separate [retained guitar windows](../../../../code/streeling/evidence/pitch-estimates-2026-10-22/native-pitch-windows.json), four recurrence scores exceed 0.999 while zero estimates pass the chosen nominal-reference 5-cent check. A legend saying “99.9% probability of correct pitch” would invent calibration. Likewise, adjacent-window variation is not automatically a confidence interval.

The strongest objection to a detailed diagnostic display is its reading cost. A simpler summary can show coverage, a declared error criterion and a link to the complete rows/figure. Reject it as sufficient if it hides failures needed for the actual decision. [COG-005](../../cognitive-science/en/cog-005-separate-pitch-estimates-from-listener-reports.md) explains why even a calibrated signal estimator would not itself establish listener preference or learning.

### Practice exercise 5: repair the dashboard claim

An agent labels the retained recurrence score as probability, joins across missing frames and calls the result a listener-validated improvement. Replace the claim and specify the display repair.

> **Answer:** Label recurrence as the declared signal-similarity score, retain its failed nominal-reference checks and keep actual retained windows separate from authored plotting rows. Show valid estimates and distinct unavailable states without invented connecting observations; disclose denominators and any filtering. Listener validation and an actual improvement trial require additional evidence, so neither is established by this display.
