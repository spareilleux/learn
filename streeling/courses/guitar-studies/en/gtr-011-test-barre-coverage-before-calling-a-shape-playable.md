---
module_id: gtr-011-test-barre-coverage-before-calling-a-shape-playable
department: guitar-studies
course: "Test Barre Coverage Before Calling a Shape Playable"
level: intermediate
prerequisites: ["gtr-003-audit-voicing-playability"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---


# Test Barre Coverage Before Calling a Shape Playable

> **Draft and evidence boundary.** This lesson contains an authored model and source reading. Human technical, musician, fluent-language and learner decisions remain pending. No new engine render, parser run, playing, listening or learner observation is claimed. Historical failures keep their original status.

## The project question

The prerequisite showed that two GA barre heuristics answer different questions. This lesson adds an explicit proposed finger interval and checks whether its contact would contradict a requested open string. That operation is more precise than counting repeated fret values. It still cannot certify a player's reach, pressure or tone, and it proposes no replacement heuristic.

## Read the project evidence

Read the linked prerequisite and retained project artifact before applying the model. Locate the particular representation, transformation or exclusion that matters to this question. The fixed packet records source identity, reading scope and authored values; a source location is evidence for its contents at that revision, not proof of current deployment. Keep a source-derived observation separate from an inferred proposal. Where a primary reference is linked, use its stated scope rather than extending it to unsupported cases.

[Prerequisite: gtr-003-audit-voicing-playability](../../guitar-studies/en/gtr-003-audit-voicing-playability.md)

[Retained project artifact](../../../../streeling/courses/guitar-studies/en/gtr-003-audit-voicing-playability.md)

[Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-23/unit-a.json)

[Validation journal](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)

## 1. Exercise 1

Use conventional string labels, with 1 highest and 6 lowest. Propose continuous contact at fret 2 across strings 1 through 3. The requested notes on those strings use frets `[2,0,2]`. The middle string is inside the finger interval, even though it does not share the repeated positive fret value.

Which strings does the proposed contact cover?

> **Answer.** It covers strings `[1,2,3]`, including the requested open middle string.

## 2. Exercise 2

Under the stipulated full-contact model, a covered string cannot retain a sounding fret below the barre. String 2 requests fret 0 while contact is at 2, giving a contradiction. This witness concerns the proposed fingering rather than the pitch shape's existence under every imaginable technique.

Identify the conflict and its assumption.

> **Answer.** String 2 conflicts because `0<2`; the result assumes continuous contact, with no selectively arched finger.

## 3. Exercise 3

For the negative control, replace only the middle request with fret 3. A separate higher-fret contact can override the lower barre in this ideal geometry. The lower-fret contradiction disappears, although a complete finger assignment is still absent. Passing this check is necessary under the model, not sufficient evidence of practical fingering.

What changes for request `[2,3,2]`?

> **Answer.** No requested fret lies below the covered fret 2. The coverage check passes; actual finger allocation remains unresolved.

## 4. Exercise 4

A Boolean repeated-fret detector does not supply endpoints, finger identity or contact policy. Those missing inputs explain why one should not silently transform a heuristic label into a continuous barre. Preserve the original shape and proposed contact separately, so a reviewer can reject a fingering while retaining a useful voicing candidate.

Can a false barre heuristic guarantee no barre is needed?

> **Answer.** No. It only reports its predicate; the explicit fingering and musician evidence answer different questions.

## 5. Exercise 5

The retained prerequisite is an archived transfer, including its unresolved musician boundary. Our coverage calculation does not update that history. For a future trial retain string order, finger interval, intended open notes, observed clean-note count and assistance. A smaller direct table should be checked before extending GA ranking logic or proposing a hand-model abstraction.

What remains pending after the coverage calculation?

> **Answer.** Actual contact, clean sound, transition success and musician acceptance remain pending; no player was tested.

## Source-assisted learner task

Prepare a short review note from the fixed case before opening the prepared answers. First reproduce the calculation or table manually, keeping the stated units, support and assumptions. That direct result is the baseline for any source-assisted or agent-assisted answer. Then inspect the linked project artifact and identify one precise boundary relevant to the calculation. Record the actual source excerpt or field used, its revision, your proposed answer and every kind of assistance received. A calculator and source lookup are allowed; label them instead of presenting the result as unaided recall.

Apply the negative control as well as the main case. Write the observable result that would falsify your conclusion, and state whether the control actually supplies it. If a model input is absent, retain an unresolved result rather than substituting a plausible value. Compare a proposed abstraction with the manual baseline before recommending a new agent workflow or DSL. The answer key is a prepared check, not a record of your attempt. Keep your original answer before reveal, any correction afterward and the reason for the correction.

The packet contains five prepared learner criteria corresponding to the exercises. Their decisions remain null until actual answers, assistance and review are retained. Correct arithmetic supports only the declared model. A useful project decision still needs the relevant human judgment or runtime observation at its own boundary. Record actual checks, errors and refinements in the linked validation journal; the journal must distinguish executed tests from planned tests.
