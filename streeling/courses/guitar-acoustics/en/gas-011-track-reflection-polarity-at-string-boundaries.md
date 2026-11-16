---
module_id: gas-011-track-reflection-polarity-at-string-boundaries
department: guitar-acoustics
course: "Track Reflection Polarity at String Boundaries"
level: intermediate
prerequisites: ["gas-006-relate-pluck-position-to-string-modes"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---


# Track Reflection Polarity at String Boundaries

> **Draft and evidence boundary.** This lesson contains an authored model and source reading. Human technical, musician, fluent-language and learner decisions remain pending. No new engine render, parser run, playing, listening or learner observation is claimed. Historical failures keep their original status.

## The project question

A string-model diagram shows a reflection gain but omits which wave variable it describes. That omission can reverse the sign of an otherwise careful explanation. We follow displacement waves at an ideal fixed boundary, verify cancellation directly and keep force conventions outside that calculation. The numerical pulses are authored, with no physical bridge measured.

## Read the project evidence

Read the linked prerequisite and retained project artifact before applying the model. Locate the particular representation, transformation or exclusion that matters to this question. The fixed packet records source identity, reading scope and authored values; a source location is evidence for its contents at that revision, not proof of current deployment. Keep a source-derived observation separate from an inferred proposal. Where a primary reference is linked, use its stated scope rather than extending it to unsupported cases.

[Prerequisite: gas-006-relate-pluck-position-to-string-modes](../../guitar-acoustics/en/gas-006-relate-pluck-position-to-string-modes.md)

[Retained project artifact](../../../../code/streeling/guitar-runtime/vendor/lib.rs)

[Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-23/unit-a.json)

[Validation journal](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)

[Primary reference](https://www.dsprelated.com/freebooks/pasp/Rigid_Terminations.html)

## 1. Exercise 1

Declare incident displacement amplitude .2 mm and one positive transverse axis for both traveling components. At an ideal stationary fixed end, their sum must vanish. Therefore the reflected displacement is -.2 mm. This is a boundary constraint; it does not say the incoming traveling component was itself zero.

What reflection coefficient satisfies the declared boundary?

> **Answer.** The displacement coefficient is -1, producing -.2 mm and total displacement 0 mm.

## 2. Exercise 2

Try coefficient +1 as the negative control while keeping the same displacement convention. The reflected amplitude becomes .2 mm and the boundary sum .4 mm. This violates the fixed-end premise. The failure is reproducible algebra, rather than a claim that an actual GA buffer visibly moved a real bridge.

Why does the positive coefficient fail here?

> **Answer.** It gives .4 mm instead of the required 0 mm at the fixed boundary.

## 3. Exercise 3

A pulse that reflects once at each of two fixed ends receives the product `(-1)*(-1)=+1`. Its round-trip sign is positive even though each local reflection inverted displacement. Propagation time and attenuation would require additional quantities. A positive loop sign alone cannot reveal whether the individual boundary constraints were respected.

Does a positive round-trip sign imply non-inverting endpoints?

> **Answer.** No. Two displacement inversions produce the positive product +1; keep the two local gains separately.

## 4. Exercise 4

The primary termination text distinguishes displacement and velocity from force waves: their sign conventions at a rigid end differ. An unqualified reflection coefficient is therefore incomplete. Before borrowing a formula from a physical model, retain the transported variable, orientation, units and boundary type. A sign copied without those fields may answer another question correctly.

What context prevents a misleading sign comparison?

> **Answer.** Name displacement versus force, common orientation, units and boundary condition before comparing gains.

## 5. Exercise 5

Read the engine's feedback and body-processing state without relabeling every recurrence as a physical boundary. The retained implementation is a synthesis model; this ideal boundary exercise is an interpretation check. A source-assisted note should identify the exact recurrence being discussed and the additional model mapping needed before making a physical claim.

May this calculation validate a real bridge model or repair the decay result?

> **Answer.** No. It validates the stipulated algebra only; physical mapping and the historical decay gate remain separate.

## Source-assisted learner task

Prepare a short review note from the fixed case before opening the prepared answers. First reproduce the calculation or table manually, keeping the stated units, support and assumptions. That direct result is the baseline for any source-assisted or agent-assisted answer. Then inspect the linked project artifact and identify one precise boundary relevant to the calculation. Record the actual source excerpt or field used, its revision, your proposed answer and every kind of assistance received. A calculator and source lookup are allowed; label them instead of presenting the result as unaided recall.

Apply the negative control as well as the main case. Write the observable result that would falsify your conclusion, and state whether the control actually supplies it. If a model input is absent, retain an unresolved result rather than substituting a plausible value. Compare a proposed abstraction with the manual baseline before recommending a new agent workflow or DSL. The answer key is a prepared check, not a record of your attempt. Keep your original answer before reveal, any correction afterward and the reason for the correction.

The packet contains five prepared learner criteria corresponding to the exercises. Their decisions remain null until actual answers, assistance and review are retained. Correct arithmetic supports only the declared model. A useful project decision still needs the relevant human judgment or runtime observation at its own boundary. Record actual checks, errors and refinements in the linked validation journal; the journal must distinguish executed tests from planned tests.
