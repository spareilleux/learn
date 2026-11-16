---
module_id: gaa-009-test-transposition-beyond-a-memorized-fret-pattern
department: guitar-alchemist-academy
course: "Test Transposition Beyond a Memorized Fret Pattern"
level: intermediate
prerequisites: ["gaa-006-separate-capo-shapes-from-sounding-pitches", "gaa-007-turn-a-voicing-result-into-a-practice-item"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---


# Test Transposition Beyond a Memorized Fret Pattern

> **Draft and evidence boundary.** This lesson contains an authored model and source reading. Human technical, musician, fluent-language and learner decisions remain pending. No new engine render, parser run, playing, listening or learner observation is claimed. Historical failures keep their original status.

## The project question

A learner can reproduce a familiar fret diagram without demonstrating a transposition operation. We design a source-assisted probe whose answer key preserves absolute intervals, register and tuning. The examples are authored note lists rather than actual learner responses. The task permits different realizations while requiring a checkable pitch transformation, and leaves learning claims pending.

## Read the project evidence

Read the linked prerequisite and retained project artifact before applying the model. Locate the particular representation, transformation or exclusion that matters to this question. The fixed packet records source identity, reading scope and authored values; a source location is evidence for its contents at that revision, not proof of current deployment. Keep a source-derived observation separate from an inferred proposal. Where a primary reference is linked, use its stated scope rather than extending it to unsupported cases.

[Prerequisite: gaa-006-separate-capo-shapes-from-sounding-pitches](../../guitar-alchemist-academy/en/gaa-006-separate-capo-shapes-from-sounding-pitches.md)

[Prerequisite: gaa-007-turn-a-voicing-result-into-a-practice-item](../../guitar-alchemist-academy/en/gaa-007-turn-a-voicing-result-into-a-practice-item.md)

[Retained project artifact](../../../../code/streeling/evidence/capo-spelling-2026-10-22/degree-context.json)

[Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-23/unit-a.json)

[Validation journal](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)

## 1. Exercise 1

Start with absolute notes `[60,64,67]` and request every note 2 semitones higher. Addition gives `[62,66,69]`. The answer key checks all notes and preserves ordering. A root-only test would be insufficient, even if a candidate's first pitch were correct.

Give the target and its intervals from the first note.

> **Answer.** The target is `[62,66,69]`; intervals are `[0,4,7]`.

## 2. Exercise 2

Use `[62,65,69]` as a negative control. It reaches the requested first note but changes the middle interval from 4 to 3 semitones. A memorized minor-shaped response could therefore pass a tonic check while failing the transposition request. The key must preserve the transformation, not a familiar verbal chord label alone.

Why does this candidate fail?

> **Answer.** Its intervals are `[0,3,7]`; the middle note should be 66 rather than 65.

## 3. Exercise 3

Another control is `[74,78,81]`: its pitch classes match the correct answer, but every note lies an octave above the requested absolute target. Whether octave equivalence is accepted depends on the prompt. This task explicitly requires the stated register, so pitch-class equality cannot silently broaden its accepted answers.

Is the octave-shifted control correct here?

> **Answer.** No. It adds 12 beyond the target, violating the declared absolute-register requirement.

## 4. Exercise 4

To make a transfer probe, withhold the target list before the response and change the starting item from the rehearsed example. Retain permitted sources and calculator assistance. Solving with a displayed key tests another endpoint. This is a task-design distinction, not a claim that this particular probe has validated memory transfer in a learner.

What must precede revealing the key?

> **Answer.** Retain the actual response, input item, source assistance and scoring rule before reveal.

## 5. Exercise 5

The retained degree table distinguishes major and natural-minor offsets at fixed tonic and register. It is useful source support for diagnosing the altered third, not a record that a learner made this error. A future fretboard realization needs string order, tuning, allowed positions and musician review beyond our absolute-note calculation.

Can the correct note list prove a playable fingering or learned transfer?

> **Answer.** No. It proves the authored arithmetic key only; neither playing nor a learner attempt occurred.

## Source-assisted learner task

Prepare a short review note from the fixed case before opening the prepared answers. First reproduce the calculation or table manually, keeping the stated units, support and assumptions. That direct result is the baseline for any source-assisted or agent-assisted answer. Then inspect the linked project artifact and identify one precise boundary relevant to the calculation. Record the actual source excerpt or field used, its revision, your proposed answer and every kind of assistance received. A calculator and source lookup are allowed; label them instead of presenting the result as unaided recall.

Apply the negative control as well as the main case. Write the observable result that would falsify your conclusion, and state whether the control actually supplies it. If a model input is absent, retain an unresolved result rather than substituting a plausible value. Compare a proposed abstraction with the manual baseline before recommending a new agent workflow or DSL. The answer key is a prepared check, not a record of your attempt. Keep your original answer before reveal, any correction afterward and the reason for the correction.

The packet contains five prepared learner criteria corresponding to the exercises. Their decisions remain null until actual answers, assistance and review are retained. Correct arithmetic supports only the declared model. A useful project decision still needs the relevant human judgment or runtime observation at its own boundary. Record actual checks, errors and refinements in the linked validation journal; the journal must distinguish executed tests from planned tests.
