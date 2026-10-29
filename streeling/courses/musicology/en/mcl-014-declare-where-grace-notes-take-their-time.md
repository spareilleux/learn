---
module_id: mcl-014-declare-where-grace-notes-take-their-time
department: musicology
course: "Declare Where Grace Notes Take Their Time"
level: intermediate
prerequisites: ["mcl-007-integrate-a-midi-tempo-map-before-scheduling"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Declare Where Grace Notes Take Their Time

> Authored example and source reading. No new guitar performance, audio or parser execution, participant response or production adoption is claimed. Human technical, fluent-language and learner decisions remain pending.

An ornament can be short on the page and still need an explicit playback policy. If a tool inserts grace-note time without saying where it comes from, every later guitar event may drift or a principal note may shrink unexpectedly. This lesson compares two authored allocations in seconds. The goal is to make that policy inspectable before scheduling, rather than infer performance practice from a slash or from a tiny printed notehead.

## Read the retained evidence

The retained timed-event packet defines absolute onset and offset values for an authored phrase. It does not supply a universal ornament policy. MusicXML's grace element distinguishes making time from stealing a percentage of a neighboring note. Those attributes establish separate possibilities; our seconds-based examples are explanatory policies, not a claimed execution or a direct serialized attribute example. The prerequisite's tempo mapping cannot choose between them.

[Prerequisite](../../musicology/en/mcl-007-integrate-a-midi-tempo-map-before-scheduling.md)

[Retained project artifact](../../../../code/streeling/evidence/music-phrase-2026-10-22/timed-events.json)

[Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-24/unit-a.json)

[Validation journal](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)

[Primary reading](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/grace/)

### Exercise 1

The group begins at `1 s`. The principal note's written duration is `0.5 s`, and the authored ornament budget is `0.1 s` for `2` grace notes. Divide the budget equally to obtain `0.05 s` per grace note. Equal division is a local choice, not an assertion about how every guitarist articulates ornaments.

How much time is assigned to each grace note?

<details><summary>Answer 1</summary>

Each receives `0.05 s`. That follows from the explicitly equal allocation of `0.1 s` across `2` notes.

</details>

### Exercise 2

The main policy is `steal_following`. Put the ornament at the group start and subtract its budget from the principal note. The principal begins at `1.1 s` and lasts `0.4 s`. Its later start and shorter sounding duration are both intentional consequences of this policy; hiding either value would make the schedule hard to review.

Give principal-note onset and duration.

<details><summary>Answer 2</summary>

Onset is `1.1 s` and duration `0.4 s`. The ornament consumes part of the following principal's written time.

</details>

### Exercise 3

The next unchanged group boundary remains `1.5 s`. The combined ornament and main time is `0.5 s`, matching the written slot. Duration conservation here applies to that whole slot, not to the principal alone. A future check should name which support it preserves, because both a shortened principal and a preserved boundary can be correct simultaneously.

Which duration is conserved in the main case?

<details><summary>Answer 3</summary>

The complete slot remains `0.5 s`, ending at `1.5 s`. The principal itself is shortened; claiming its original duration was preserved would be false.

</details>

### Exercise 4

The negative control changes policy to `add_time`. The principal still starts at `1.1 s`, but retains its full `0.5 s`, moving the next boundary to `1.6 s`. All pitch labels could remain identical between schedules. A check that looks only at ornament count or principal onset therefore misses the downstream timing difference.

What is the control's next boundary, and why?

<details><summary>Answer 4</summary>

It is `1.6 s`: the `0.1 s` ornament is added to the original `0.5 s` main duration. This is a different allocation, not an arithmetic error within the main policy.

</details>

### Exercise 5

When a source supplies an ornament without a usable allocation, preserve the ambiguity instead of inventing an authoritative style rule. A musician may choose a performance interpretation after reviewing context. A scheduling agent should state the selected policy and preserve the original notation so another interpretation remains possible. An apparent smooth playback does not prove fidelity to an unstated intent.

What would falsify a scheduler's claim to preserve the chosen slot?

<details><summary>Answer 5</summary>

Ending the main-policy group at `1.6 s` rather than `1.5 s` contradicts its declared slot conservation. A different declared policy could legitimately choose the later boundary.

</details>

## Source-assisted learner task

Draw both schedules manually, including each grace interval, principal onset and next boundary. Inspect the retained event endpoints and official grace attributes. Write a handoff note that names the chosen allocation and preserves the original ornament marking. Specify a boundary-based falsifier before proposing a scheduler rule, and leave stylistic suitability, actual playback and learner performance undecided.

First retain your answer before revealing the prepared corrections. Use the manual table or calculation as the baseline for any calculator, source lookup or agent assistance, and record that assistance. Keep the original response and the corrected response separately. Match each exercise to a prepared criterion in the fixed packet; those criteria have no learner decisions yet. Record an actual source passage and its revision, then distinguish what it establishes from your proposed next step. Report any missing input as unresolved. A mathematically correct answer supports the stated example; human review, runtime execution and learner acceptance require their own retained observations.
