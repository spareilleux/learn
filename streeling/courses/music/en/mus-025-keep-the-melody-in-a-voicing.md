---
module_id: mus-025-keep-the-melody-in-a-voicing
department: music
course: Keep the Required Melody in a Voicing
level: intermediate
alchemical_stage: albedo
prerequisites: [mus-012-chord-formulas-essential-tones-doubling, mus-016-recover-voice-correspondence, mus-024-preserve-attacks-and-harmonic-boundaries]
estimated_duration: "60 minutes"
produced_by: codex-project-analysis
version: "1.0.0"
---

# Keep the Required Melody in a Voicing

## Project question and deliverable

An accompaniment suggestion contains the right chord tones, but the tune disappears inside it. For this arrangement exercise, the required melody must be the **highest sounding registered pitch**. Filter candidates by that explicit requirement before comparing a secondary position penalty. This is a chosen arrangement contract, not a universal rule that every melody must be the highest voice.

GA's pinned [tab-solver entry point](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.ML/Tabs/AdvancedTabSolver.cs#L52) receives pitch collections and generates shapes without an explicit melody-role argument in that method signature. Do not infer a highest-voice guarantee from it. This source observation is narrower than a claim about every GA feature. The live voicing request [failed](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/music-phrase-2026-10-22/ga-voicings-probe.json), so every candidate below is deliberately constructed rather than attributed to that tool.

## 1. Decode candidates before ranking them

Use the [pinned standard tuning](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Core/Instruments/Tuning.cs), expressed here from low E to high e as `[40,45,50,55,59,64]`, with C4 = 60. GA's [internal tuning indexing](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Core/Instruments/Tuning.cs#L82) is highest-string-first; this fixture explicitly uses low-to-high order. A fret adds that many semitones; −1 means muted and 0 means open in this fixture. The [retained data](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/music-phrase-2026-10-22/melody-constraints.json) lists every string and pitch.

| Candidate | Frets, low E to high e | Highest sounding pitch |
|---|---|---:|
| A | −1, 3, 2, 0, 0, 0 | 64 |
| B | −1, 3, 5, 4, 5, 3 | 67 |
| C | −1, 3, 2, 0, 0, −1 | 59 |
| D | −1, 3, 5, 4, 8, 0 | 67 |

All four have pitch-class content C, E, G, B: Cmaj7 with different registers and doublings. Chord content alone does not select which pitch is on top.

### Practice exercise 1

Decode the sounding pitches of A and B in string order. Which has E4 on top?

> **Answer:** A gives `[48,52,55,59,64]`; B gives `[48,55,59,64,67]`. Only A has E4 = 64 on top. B contains E4 but also has the higher G4 = 67. These are arithmetic checks of constructed placements, not captured playing or generated voicings.

## 2. Distinguish three melody questions

Every candidate contains pitch class 4, E. Candidates A, B and D contain registered pitch 64. Only A has 64 as the highest sounding pitch. These tests answer different questions: chord-tone membership, presence in the required register, and the specific outer-voice contract.

The [MusicXML](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/duration/) [note model](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Types/MusicXmlTypes.fs#L93) can retain a voice label. Such a label identifies a notated voice; it should not silently be replaced by sorting pitches. If the musical task instead assigns the melody to an inner voice, this lesson's highest-pitch predicate is the wrong contract.

### Practice exercise 2

Which candidates pass each test: contains E at any octave; contains E4; has E4 on top?

> **Answer:** Any E: A, B, C and D. E4 present: A, B and D. E4 on top: A only. Candidate C contains E3 = 52 rather than E4, and its highest pitch is B3 = 59. Do not substitute one test for another.

## 3. A higher string need not carry the highest pitch

In D, the B string at fret 8 sounds 59 + 8 = 67, while the open high-e string sounds 64. The last unmuted string in the array therefore does not contain the highest pitch. Compute the maximum over sounding pitches for this contract, rather than taking the last array entry.

This is possible because string order and sounding pitch order are different. The example does not claim a comfortable fingering, a played string crossing or a particular melody's physical continuity across a phrase. MUS-016 distinguishes voice identities from strings; MUS-024 distinguishes held notes from attacks.

### Practice exercise 3

For D, identify the highest pitch and its string, then the last sounding string's pitch. Would keeping the last sounding entry enforce the required E4-on-top condition?

> **Answer:** The highest is G4 = 67 on the B string, fret 8. The last sounding entry is open high e = 64. No: accepting D on that entry would ignore the higher G4. A string position is not a pitch-order guarantee.

## 4. Enforce the musical requirement before the soft preference

For a deliberately coarse secondary preference, define a candidate's position as its minimum positive fret. With predecessor position 3, define the penalty as the absolute position difference. The positions of A, B, C and D are 2, 3, 2 and 3; the penalties are 1, 0, 1 and 0.

This authored penalty is not GA's difficulty score, its inertia term or its full physical objective. It ignores many aspects of playing. The unconstrained minimum includes B and D, both of which violate the E4-on-top requirement. Filtering first leaves A, whose secondary penalty is 1. A lower soft penalty must not silently override a hard musical requirement.

### Practice exercise 4

Apply the hard melody condition and then the secondary position penalty. Which candidate survives, and what playing claim remains unsupported?

> **Answer:** A alone survives and has penalty 1. Neither the minimum-positive-fret calculation nor the melody test establishes finger choice, stretch comfort or an easy performance. Those require a concrete playing trial and a stated player criterion.

## 5. Preserve register when the candidate pool is empty

Change the required top melody to E5 = 76. No retained candidate reaches it. A pitch-class-only test would still accept A's top E4, but that is an octave below the requested note. Report the empty feasible set; obtaining other candidates or changing the arrangement requirement is a separate decision.

Submit the melody's pitch and role, tuning, decoded candidates, exact filter results, secondary objective and remaining playing questions. The [learner packet](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/music-phrase-2026-10-22/learner-task.md) checks these statements without supplying a participant result or pretending a melody-aware GA extension has shipped.

### Practice exercise 5

An agent responds to the E5 request with A because its highest pitch has the same pitch class. What should the handoff say instead?

> **Answer:** “None of the four constructed candidates has 76 as its highest sounding pitch. A has 64, an octave lower, and does not meet the stated requirement.” Keep the exact register constraint unless a new arrangement decision changes it. No returned live voicing or playing result justifies relaxing it here.
