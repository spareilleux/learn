---
module_id: gas-009-estimate-tuning-error-from-integer-delay-length
department: guitar-acoustics
course: "Estimate Tuning Error from Integer Delay Length"
level: intermediate
prerequisites: ["gas-005-separate-a-partial-peak-from-a-period"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---


# Estimate Tuning Error from Integer Delay Length

> **Draft and evidence boundary.** This lesson contains an authored model and source reading. Human technical, musician, fluent-language and learner decisions remain pending. No new engine render, parser run, playing, listening or learner observation is claimed. Historical failures keep their original status.

## The project question

A requested frequency does not always fit an integer delay. GAS005 introduced a single ratio; here a reviewer compares rounding policies against a declared tuning tolerance. The clock and targets below are authored constants. The real GA engine also has fractional delay and filters, so this deliberately stripped model cannot predict its rendered pitch.

## Read the project evidence

Read the linked prerequisite and retained project artifact before applying the model. Locate the particular representation, transformation or exclusion that matters to this question. The fixed packet records source identity, reading scope and authored values; a source location is evidence for its contents at that revision, not proof of current deployment. Keep a source-derived observation separate from an inferred proposal. Where a primary reference is linked, use its stated scope rather than extending it to unsupported cases.

[Prerequisite: gas-005-separate-a-partial-peak-from-a-period](../../guitar-acoustics/en/gas-005-separate-a-partial-peak-from-a-period.md)

[Retained project artifact](../../../../code/streeling/guitar-runtime/vendor/lib.rs)

[Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-23/unit-a.json)

[Validation journal](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)

## 1. Exercise 1

At 44100 Hz and target 1000 Hz, the ideal delay is 44.1 samples. Flooring and nearest-integer rounding both select 44 here. Integer length is dimensionless as a sample count; its time is obtained by dividing by the clock.

What ratio does length 44 produce?

> **Answer.** `44100/44` gives approximately 1002.272727273 Hz, above the target.

## 2. Exercise 2

Use signed cents `1200*log2(f/target)`. Length 44 gives approximately 3.930158439 cents; length 45 gives approximately -34.975614791 cents. Sign records direction. A symmetric tolerance tests absolute value, so rounding policy must be evaluated through the ratio rather than sample distance alone.

Which length passes the stipulated 5-cent tolerance?

> **Answer.** Length 44 passes; length 45 fails. This is an authored criterion, not a measured hearing threshold.

## 3. Exercise 3

The interval between adjacent lengths depends on position: `1200*log2((N+1)/N)` gives the positive spacing magnitude. Around shorter delays, a single sample can move the ratio farther. Consequently a policy that suffices at one target is not a tuning certificate across a frequency range.

Does a passing 1000 Hz case certify every target?

> **Answer.** No. The local spacing and location of each target inside the integer interval must be checked.

## 4. Exercise 4

For a negative control, change the target to 1100 Hz while retaining the clock. Nearest length becomes 40, producing 1102.5 Hz. Its cents error again exceeds neither by assumption nor by rounding label: calculate it. It is approximately 3.930158439 cents, so this particular control still passes.

What stronger counterexample should replace that ineffective control?

> **Answer.** Use target 1090 Hz: nearest length 40 gives 1102.5 Hz and exceeds 5 cents.

## 5. Exercise 5

The retained engine source separates integer buffer length from fractional state. Preserve that distinction in any recommendation. A failing bare-delay control motivates inspecting phase and interpolation; it cannot identify a defect in the full loop. The historical failed decay gate remains a separate observation with its original acceptance criterion.

What result may the reviewer claim?

> **Answer.** Only the integer model's calculated tolerance outcomes, with clock, target and policy. Actual engine tuning and musician judgment remain unobserved.

## Source-assisted learner task

Prepare a short review note from the fixed case before opening the prepared answers. First reproduce the calculation or table manually, keeping the stated units, support and assumptions. That direct result is the baseline for any source-assisted or agent-assisted answer. Then inspect the linked project artifact and identify one precise boundary relevant to the calculation. Record the actual source excerpt or field used, its revision, your proposed answer and every kind of assistance received. A calculator and source lookup are allowed; label them instead of presenting the result as unaided recall.

Apply the negative control as well as the main case. Write the observable result that would falsify your conclusion, and state whether the control actually supplies it. If a model input is absent, retain an unresolved result rather than substituting a plausible value. Compare a proposed abstraction with the manual baseline before recommending a new agent workflow or DSL. The answer key is a prepared check, not a record of your attempt. Keep your original answer before reveal, any correction afterward and the reason for the correction.

The packet contains five prepared learner criteria corresponding to the exercises. Their decisions remain null until actual answers, assistance and review are retained. Correct arithmetic supports only the declared model. A useful project decision still needs the relevant human judgment or runtime observation at its own boundary. Record actual checks, errors and refinements in the linked validation journal; the journal must distinguish executed tests from planned tests.
