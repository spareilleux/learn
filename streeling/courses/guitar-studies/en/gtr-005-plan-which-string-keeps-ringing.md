---
module_id: gtr-005-plan-which-string-keeps-ringing
department: guitar-studies
course: "Plan Which String Keeps Ringing"
level: intermediate
prerequisites: ["gtr-003-audit-voicing-playability"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Plan Which String Keeps Ringing

> **Draft scope.** Fresh standalone execution of unchanged F# position helpers, pinned source inspection and authored sustained-event calculations. Musician, human technical, fluent-language and learner reviews and deployed course HTML verification remain pending. No guitar was played and no timed GA planner or audio engine was run.

## The project question

A note can be played at several places on a guitar. Does choosing a valid place independently for each note produce a phrase in which every requested note keeps ringing? We will keep four event identities and test a narrow model: one independently sustained note per string at a time, with no string change inside a held event. This excludes transfers, rearticulation and special techniques; it is not a universal account of physical guitar possibilities.

## 1. Reconcile string labels before composing functions

The pinned [GA MIDI helpers](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Types/MidiTypes.fs) use Standard tuning `[40,45,50,55,59,64]`, with string 1 at the lowest end. The inspected [C# tuning model](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Core/Instruments/Tuning.cs) normalizes its default to the highest string first. Throughout this lesson, conventional guitar labels mean string 1 high E4 and string 6 low E2, with C4 = MIDI 60.

For this six-string case, convert an F# index s into conventional index `7-s`. The [fresh execution receipt](../../../../code/streeling/evidence/phrase-performance-2026-10-22/native-execution.json) records unchanged source loaded through [F# Interactive](https://learn.microsoft.com/dotnet/fsharp/tools/fsharp-interactive/) with SDK 10.0.113. Sixteen input cases cover two tunings, two fret caps and four pitches. The coordinate adapter and temporal search are authored calculations, not an implemented bridge or C# execution.

### Practice exercise 1: translate one returned position

The F# helper returns string 4 fret 5 for MIDI 60. Which conventional string is that, and which open note verifies the pitch? Would keeping string number 4 unchanged preserve its meaning across these inspected conventions?

> **Answer:** `7-4=3`, the conventional G3 string with open MIDI 55. Adding fret 5 gives 60. Keeping the number 4 unchanged would instead identify the conventional D3 string, so the coordinate meaning would change. The adapter is specific to the declared six-string order.

## 2. Keep the valid pitch candidates

With maximum fret 5, the actual helper outputs yield these conventional positions:

| Pitch | Conventional string/fret candidates |
| --- | --- |
| C4, MIDI 60 | string 3 fret 5; string 2 fret 1 |
| E4, MIDI 64 | string 2 fret 5; string 1 fret 0 |
| G4, MIDI 67 | string 1 fret 3 |
| D4, MIDI 62 | string 2 fret 3 |

The source's independent best-position calls choose strings 2, 1, 1 and 2 respectively. Each position produces the requested pitch. The E and G choices use the same string, so their durations will decide whether they can coexist. The helper answers a static question; it is not a failed temporal solver.

### Practice exercise 2: identify the missing constraint

Why can independently selected E4 on string 1 fret 0 and G4 on string 1 fret 3 conflict even though both are valid positions? What observation is needed beyond the pitch list?

> **Answer:** Under the declared model they cannot sustain independently on the same string during an overlap. Their onsets, offsets and event identities determine whether that overlap exists. A list of valid per-note positions alone cannot answer the timed question.

## 3. Plan a held note before the later attack

Use these authored events in absolute quarter-note beats. Each interval includes its onset and excludes its offset.

| Event | MIDI pitch | Onset | Offset |
| --- | --- | --- | --- |
| C | 60 | 0 | 4 |
| E | 64 | 0 | 2 |
| G | 67 | 1 | 2 |
| D | 62 | 2 | 3 |

C and E initially have three unique-string assignments. Only C on string 3 fret 5 and E on string 2 fret 5 can extend through G's attack on string 1 fret 3 without moving a held event. At beat 2, E and G have ended; D can reuse string 2 at fret 3. Exhaustive assignment gives one complete plan under these candidates and assumptions.

### Practice exercise 3: preserve the held events

Give the full plan. Why can a locally valid initial choice of C on string 2 and E on string 1 fail when G arrives? Is silently moving either held note to another string the same event realization?

> **Answer:** C uses string 3 fret 5; E string 2 fret 5; G string 1 fret 3; D string 2 fret 3. The alternative initial choice occupies G's only eligible string while E must continue. Moving a held note would require a separately declared transfer or rearticulation model; it is not permitted silently by this assignment problem.

## 4. Exhibit the conflict instead of inventing a fingering

Move D's onset to beat 1.5 and keep its offset at 3. Between beats 1.5 and 2, all four events are active. At fret cap 5 their eligible strings together are only 1, 2 and 3. Four simultaneous independent events cannot be injected into those three strings. No valid assignment exists in this model, despite every event having at least one pitch position.

The pinned [C# position mapper](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Services/Fretboard/Analysis/FretboardPositionMapper.cs) already filters duplicate strings within one simultaneous chord shape. It does not retain a held event's string across a timed phrase. These are related constraints at different scopes; this course does not execute or replace that mapper.

### Practice exercise 4: state the narrow impossibility

What is the early-D overlap witness? Does it prove that no guitarist can ever play those pitches, or that every GA path is broken?

> **Answer:** Over the half-open interval from 1.5 to 2, four active events have only three eligible strings under the Standard tuning, fret cap and monophonic-per-string assumptions. That proves infeasibility for this declared assignment model. Different ranges, techniques or musical edits are separate possibilities; it establishes no universal physical impossibility or system-wide failure.

## 5. Separate a model solution from a player result

Keeping the early onset but expanding the allowed fret cap to 10 yields three complete assignments; cap 9 still yields none. One expanded plan uses C on string 4 fret 10, E on string 1 open, G on string 2 fret 8 and D on string 3 fret 7. Its positive-fret span is 3. This verifies pitch and occupancy under the model, not the player's reach, muting, timbre or clean execution.

### Practice exercise 5: make the next check concrete

An agent calls that expanded plan “proven playable.” Rewrite the claim and identify the next observations needed for a guitarist's decision.

> **Answer:** The plan satisfies the declared pitch, timing, string-occupancy and expanded-range constraints. A guitarist still needs to check the actual fingering, independent sustain, muting, clean transitions and sound in context. No musician trial occurred here, so those outcomes remain unverified.

The [fixed occupancy record](../../../../code/streeling/evidence/phrase-performance-2026-10-22/string-occupancy.json) retains candidates, plans and the overlap witness. [GAA-005](../../guitar-alchemist-academy/en/gaa-005-repair-a-phrase-without-hiding-the-change.md) compares possible changes to the request rather than hiding them inside a supposed solution.
