---
module_id: gtr-014-count-legato-notes-separately-from-pick-attacks
department: guitar-studies
course: "Count Legato Notes Separately from Pick Attacks"
level: intermediate
prerequisites: ["gtr-010-separate-muting-from-releasing-a-fretted-note"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Count Legato Notes Separately from Pick Attacks

> Authored example and source reading. No new guitar performance, audio or parser execution, participant response or production adoption is claimed. Human technical, fluent-language and learner decisions remain pending.

A guitar phrase can change pitch without another plectrum stroke. A lesson that counts every new pitch as a pick attack can prescribe the wrong technique, even if its note list is correct. Here we distinguish musical note events from the action used to excite or continue them. The resulting ledger helps GA explain a phrase before anyone claims that a renderer reproduces its articulation. It extends the prerequisite's release-versus-mute distinction to positive pitch changes.

## Read the retained evidence

The retained string-occupancy packet tracks sustained notes and explicitly excludes bending and rearticulation from its model. That exclusion is useful: it prevents inheriting articulation claims from a successful occupancy table. MusicXML gives hammer-on pairs a technical element separate from a broad slur. We retain explicit actions in our authored event plan, without asserting a MusicXML import or a production engine feature.

[Prerequisite](../../guitar-studies/en/gtr-010-separate-muting-from-releasing-a-fretted-note.md)

[Retained project artifact](../../../../code/streeling/evidence/phrase-performance-2026-10-22/string-occupancy.json)

[Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-24/unit-a.json)

[Validation journal](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)

[Primary reading](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/hammer-on/)

### Exercise 1

Use ordered events `pick:64`, `hammer:67`, `pull:64`, `pick:69`. Note numbers describe sounding targets under the declared discrete convention. Each row is a new note event in this authored plan, including the return to an earlier pitch. Unique pitch count would therefore answer another question and discard recurrence.

How many note events are present and what sequence do they specify?

<details><summary>Answer 1</summary>

There are `4` events, with pitches `[64,67,64,69]`. Repeated pitch `64` remains a separate event on its second occurrence.

</details>

### Exercise 2

Only rows whose action is `pick` count as plectrum attacks. The hammer and pull are distinct left-hand actions in this model. They may supply or redistribute energy physically, so saying they lack a pick stroke does not mean their sound has no transient. The model counts instructions, not an acoustic onset detector's peaks.

How many pick attacks and legato changes does the plan contain?

<details><summary>Answer 2</summary>

It contains `2` pick attacks and `2` legato changes. That tally does not predict transient strength, equal volume or successful player execution.

</details>

### Exercise 3

A pitch-only export preserves `[64,67,64,69]` but erases whether the middle changes were picked, hammered or pulled. A receiver cannot infer the original articulation uniquely. Adding an agent after the projection does not recover that information unless another source supplies it; a plausible technique suggestion must be marked as a new proposal.

Can the pitch sequence reconstruct the original action ledger?

<details><summary>Answer 3</summary>

No. Several action ledgers fit `[64,67,64,69]`. Retain the action field and its provenance if the task requires the authored picking pattern.

</details>

### Exercise 4

The negative control replaces `hammer:67` with `pick:67`, leaving every target pitch unchanged. Now there are `3` pick attacks and `1` legato change, while the note-event count remains `4`. A test that compares only pitch lists will treat these plans as equal and miss precisely the technique distinction this lesson is intended to preserve.

Which counts change in the control?

<details><summary>Answer 4</summary>

Pick attacks become `3` and legato changes `1`; note events stay `4` with `[64,67,64,69]`. Identical pitches do not imply identical articulation.

</details>

### Exercise 5

A real performance task also needs string assignment, action timing, fretted geometry and instructions about sustained sound. The occupancy packet can answer string conflict under its assumptions, while our ledger answers attack mechanism. Combining the records requires checking their event identities and boundaries rather than treating either partial model as a complete playable performance.

What would falsify an export's claim to preserve the authored technique?

<details><summary>Answer 5</summary>

An export that gives the main and control cases the same action record, or reports the same pick count for both, loses the required distinction. No listening result is needed to detect that representation failure.

</details>

## Source-assisted learner task

Write both ledgers by hand before inspecting prepared answers. Compare them with the retained occupancy exclusions and the MusicXML technical definition. Propose a phrase handoff that preserves event identity, pitch and action without inventing runtime support. State how a reviewer would reject an export that keeps notes but loses articulation. Leave physical ease, acoustic transients and actual learner performance unassessed.

First retain your answer before revealing the prepared corrections. Use the manual table or calculation as the baseline for any calculator, source lookup or agent assistance, and record that assistance. Keep the original response and the corrected response separately. Match each exercise to a prepared criterion in the fixed packet; those criteria have no learner decisions yet. Record an actual source passage and its revision, then distinguish what it establishes from your proposed next step. Report any missing input as unresolved. A mathematically correct answer supports the stated example; human review, runtime execution and learner acceptance require their own retained observations.
