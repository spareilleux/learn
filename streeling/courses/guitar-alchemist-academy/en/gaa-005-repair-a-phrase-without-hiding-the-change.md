---
module_id: gaa-005-repair-a-phrase-without-hiding-the-change
department: guitar-alchemist-academy
course: "Repair a Phrase Without Hiding the Change"
level: early-intermediate
prerequisites: ["gaa-004-choose-a-useful-voicing"]
estimated_duration: "35 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Repair a Phrase Without Hiding the Change

> **Draft scope.** Actual tuning-tool responses, fresh standalone pitch-helper execution and authored phrase alternatives. Human technical, musician, fluent-language and learner reviews and deployed course HTML verification remain pending. No timed GA solver, played phrase or listener preference was observed.

## The project question

You ask an agent for a realization of a phrase. It finds a conflict, changes a note's onset and reports success. The new phrase might be useful, but it has changed your request. This lesson compares alternatives while retaining the musical differences that a guitarist must choose between.

The [actual tuning probes](../../../../code/streeling/evidence/phrase-performance-2026-10-22/ga-tuning-probes.json) returned Standard and Drop D as available names, and Standard notes `E2,A2,D3,G3,B3,E4`. These observations do not attest a deployed source revision or timed solver. The [pinned GA MIDI helpers](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Types/MidiTypes.fs) provide the separately executed pitch candidates. [GTR-005](../../guitar-studies/en/gtr-005-plan-which-string-keeps-ringing.md) explains their conversion into conventional string labels, with string 1 high and string 6 low.

## 1. Keep a copy of the requested phrase

Use Standard tuning and maximum fret 5. Require independent sustain on one string per active event, with each held event retaining its string. The authored request is C4 from beat 0 to 4, E4 from 0 to 2, G4 from 1 to 2 and D4 from 1.5 to 3. C4 means MIDI 60; the other pitches are 64, 67 and 62.

Between 1.5 and 2, the four events together have only three eligible strings. This model has no valid assignment. “No assignment under these constraints” is a useful answer: it gives the musician an explicit choice about what may change. It is not a judgment about their ability.

### Practice exercise 1: preserve the original question

List the original D4 onset and offset, the fret cap and the conflict interval. Why should these values remain in the comparison after the agent proposes a repair?

> **Answer:** D4 begins at 1.5 and ends at 3; the cap is 5. The conflict occurs from 1.5 inclusive to 2 exclusive. Retaining these values distinguishes a solution of the original constraints from a changed phrase or range. Otherwise a successful alternative can conceal which requirement was relaxed.

## 2. Compare two different timing edits

First, delay D's onset to beat 2 while keeping its offset at 3. One assignment then exists at cap 5. The later attack also shortens D's duration from 1.5 beats to 1 beat; it does not simply shift the whole note.

Second, keep D's original onset but end E at beat 1.5 rather than 2. One assignment exists because E releases its string before D begins. This shortens E instead of changing D's attack. Half-open intervals permit the modeled reuse exactly at that boundary; real release behavior and clean playing were not measured.

### Practice exercise 2: quantify the musical edits

At a declared constant 120 quarter-notes per minute, how many milliseconds does each boundary move? Which note's duration changes in each alternative?

> **Answer:** Half a quarter-note beat is 250 ms. The first alternative delays D's onset by 250 ms and, with its offset fixed, shortens D by the same amount. The second releases E 250 ms earlier and shortens E. These are different musical edits, even though both have one model-valid assignment.

## 3. Preserve note times by changing the allowed range

The third alternative retains every requested pitch, onset and offset but allows frets through 10. Exhaustive assignment yields three plans. Their positive-fret spans are 3, 7 and 7. The span-3 candidate uses C4 on string 4 fret 10, E4 on string 1 fret 0, G4 on string 2 fret 8 and D4 on string 3 fret 7.

Ignoring the open string, the span is `10-7=3`. This is a declared fret-number proxy. It is not a millimeter measurement, a full hand model or a universal ease rating. The alternative preserves these timing/pitch fields but changes string realization and potentially timbre; a player must assess it. [GTR-003](../../guitar-studies/en/gtr-003-audit-voicing-playability.md) explains why such proxies require interpretation.

### Practice exercise 3: choose a bounded claim

What does the span-3 candidate preserve, and which constraint did it relax? Why is “lowest span among these three” a narrower statement than “best for the player”?

> **Answer:** It preserves the four requested pitches and all their onset/offset values, while relaxing maximum fret from 5 to 10. Its span is lowest among the three enumerated plans under that proxy. Player comfort, technique, sound and preference are additional unmeasured questions, so the proxy does not select universally.

## 4. Reject repairs that solve another request silently

Omitting D leaves one valid plan, but removes a requested event. Retuning the low string to Drop D while retaining cap 5 leaves zero valid plans for the original upper-note request: its relevant candidates are unchanged. An available tool option is not automatically relevant to the detected conflict.

| Alternative | Model-valid plans | Main change |
| --- | --- | --- |
| Delay D attack, keep its offset | 1 | D onset and duration |
| Release E earlier | 1 | E offset and duration |
| Allow frets through 10 | 3 | Allowed range and string realization |
| Omit D | 1 | Requested event set |
| Drop D tuning, cap 5 | 0 | Low-string tuning; conflict remains |

These counts concern an authored assignment model. They are not service output, listener scores or proof that an edit is authorized.

### Practice exercise 4: diagnose the proposed shortcut

An agent chooses Drop D because the tool lists it, then deletes D4 when the conflict remains. Can it report the original request as solved? Explain both decisions.

> **Answer:** No. The tuning change adds no eligible string for these upper pitches at cap 5 and leaves the conflict. Deleting D4 changes the required event set, even though the remaining three-event phrase has one valid plan. Report that alternative and its omission explicitly rather than calling it a preserved realization.

## 5. Return choices a musician can actually judge

The [fixed alternative record](../../../../code/streeling/evidence/phrase-performance-2026-10-22/repair-options.json) separates feasibility from preserved fields. A useful agent answer can retain the original request, explain the conflicting interval, present a few explicit alternatives and state the missing playing observations. The strongest objection to automated repair is that a small geometric model may optimize away articulation, timbre or intent that the musician values. The simpler alternative is to retain the unresolved request and ask which change is acceptable before applying one.

### Practice exercise 5: write the agent's proposal

Offer two alternatives for a guitarist who has not authorized timing changes. Include what each preserves, what it changes and one observation still needed before playing or release claims.

> **Answer:** Offer the expanded-range candidate as preserving the stated pitches and times while changing range and string realization; its fingering and sound need a musician's check. Offer a delayed D attack or earlier E release only as an explicit proposed musical edit, with the changed boundary and duration disclosed. Neither should be silently applied or described as a played success. The musician's accepted choice and actual trial remain unrecorded.
