---
module_id: wml-008-retain-register-in-drone-relative-intervals
department: world-music-languages
course: "Retain Register in Drone Relative Intervals"
level: intermediate
prerequisites: ["wml-007-resolve-scale-degrees-against-tonic-and-mode"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---


# Retain Register in Drone Relative Intervals

> **Draft and evidence boundary.** This lesson contains an authored model and source reading. Human technical, musician, fluent-language and learner decisions remain pending. No new engine render, parser run, playing, listening or learner observation is claimed. Historical failures keep their original status.

## The project question

An agent describes every note relative to a drone but reduces intervals modulo an octave. The resulting labels can hide whether a note lies above or below the reference. We retain signed semitone distance and its reduced class as separate fields. The invented example attributes no system, scale or performance convention to a community.

## Read the project evidence

Read the linked prerequisite and retained project artifact before applying the model. Locate the particular representation, transformation or exclusion that matters to this question. The fixed packet records source identity, reading scope and authored values; a source location is evidence for its contents at that revision, not proof of current deployment. Keep a source-derived observation separate from an inferred proposal. Where a primary reference is linked, use its stated scope rather than extending it to unsupported cases.

[Prerequisite: wml-007-resolve-scale-degrees-against-tonic-and-mode](../../world-music-languages/en/wml-007-resolve-scale-degrees-against-tonic-and-mode.md)

[Retained project artifact](../../../../code/streeling/evidence/capo-spelling-2026-10-22/degree-context.json)

[Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-23/unit-a.json)

[Validation journal](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)

## 1. Exercise 1

Stipulate absolute drone coordinate 60 and melody coordinates `[55,67,79]`. Subtract the same reference without reducing first. The signed intervals are `[-5,7,19]` semitones. Negative distance is meaningful: the first note lies below the reference, while the remaining notes lie above.

Give all signed distances and identify the lower note.

> **Answer.** Distances are `[-5,7,19]`; note 55 lies below drone 60.

## 2. Exercise 2

Reduce each signed interval to a nonnegative class modulo 12. All become 7. This identifies a chosen octave equivalence while discarding direction and register. A reduced-class display may be useful for one task, but it must not claim the three notes occupy the same absolute position or have identical provenance.

What classes result, and what information disappears?

> **Answer.** The classes are `[7,7,7]`; direction and octave displacement are lost.

## 3. Exercise 3

Recover a note with `note=drone+delta` when signed distance is retained. Adding only reduced class would produce 67 for every row, incorrectly replacing 55 and 79. This is the negative control against a proposed reversible class-only adapter. The lost octave coordinate cannot be restored from an attractive label or confidence score.

Reconstruct the three notes from full distances.

> **Answer.** They are `[55,67,79]`; class-only reconstruction would incorrectly yield `[67,67,67]`.

## 4. Exercise 4

The retained degree packet already requires tonic register before resolving absolute notes. A drone-relative interface additionally needs the chosen reference identity and range policy, especially when the melody crosses it. These semitone coordinates deliberately exclude frequency-ratio intonation, continuously changing pitch and conventions absent from the authored example.

Does this model establish a universal drone-relative vocabulary?

> **Answer.** No. It establishes only signed and reduced coordinates for the declared equal-tempered example.

## 5. Exercise 5

A future localized task should retain the original term and declared reference alongside any derived coordinate. Source assistance can verify the subtraction, while a fluent speaker and musician assess terminology and intended realization separately. Our numerical table cannot authorize a cultural equivalence or claim that someone sang or heard the intervals.

What must remain in the handoff to preserve reversibility?

> **Answer.** Reference60, signed distances, coordinate convention and original labels; reduced class7 alone is insufficient.

## Source-assisted learner task

Prepare a short review note from the fixed case before opening the prepared answers. First reproduce the calculation or table manually, keeping the stated units, support and assumptions. That direct result is the baseline for any source-assisted or agent-assisted answer. Then inspect the linked project artifact and identify one precise boundary relevant to the calculation. Record the actual source excerpt or field used, its revision, your proposed answer and every kind of assistance received. A calculator and source lookup are allowed; label them instead of presenting the result as unaided recall.

Apply the negative control as well as the main case. Write the observable result that would falsify your conclusion, and state whether the control actually supplies it. If a model input is absent, retain an unresolved result rather than substituting a plausible value. Compare a proposed abstraction with the manual baseline before recommending a new agent workflow or DSL. The answer key is a prepared check, not a record of your attempt. Keep your original answer before reveal, any correction afterward and the reason for the correction.

The packet contains five prepared learner criteria corresponding to the exercises. Their decisions remain null until actual answers, assistance and review are retained. Correct arithmetic supports only the declared model. A useful project decision still needs the relevant human judgment or runtime observation at its own boundary. Record actual checks, errors and refinements in the linked validation journal; the journal must distinguish executed tests from planned tests.
