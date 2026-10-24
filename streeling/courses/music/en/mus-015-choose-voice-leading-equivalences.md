---
module_id: mus-015-choose-voice-leading-equivalences
department: music
course: Choose What a Voice-Leading Distance Ignores
level: intermediate
alchemical_stage: albedo
prerequisites: [mus-014-inversions-bass-line]
estimated_duration: "60 minutes"
produced_by: codex-project-lab
version: "1.0.0"
---

# Choose What a Voice-Leading Distance Ignores

## Project question and deliverable

A guitarist asks GA for a nearby voicing. Does “nearby” preserve the order of the voices, the register, or just the collection of pitch classes? Write a comparison contract before interpreting the score. This lesson produces a four-row calculation table and a reproducible lab receipt.

The [GA source](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Services/Atonal/VoiceLeadingSpace.cs) studied here is pinned at `dc2e74cbd992a298f67efb928b5b3754615e1924`. Its [options](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Core/Theory/Atonal/VoiceLeadingOptions.cs) distinguish octave, permutation, transposition and inversion equivalence. We will keep transposition and inversion disabled unless a case explicitly says otherwise. Numeric pitches use semitone spacing and the convention C4 = 60; they carry no string or finger identity.

## 1. State the retained information

With octave equivalence off, the cost of a matched pair is its absolute semitone difference. With octave equivalence on, reduce that difference modulo 12 and take the shorter distance around the pitch-class circle. Thus 60 to 72 costs 12 in the first comparison and 0 in the second. This is a mathematical equivalence choice: it does not mean the player held the same sounding note.

Permutation equivalence asks whether target entries may be reassigned to source entries. With it disabled, entry positions are matched. With it enabled, the pinned implementation sorts the registered pitches; with octave equivalence also enabled, it tries cyclic shifts of those sorted arrays. Section 4 shows why this implementation detail matters.

### Practice exercise 1

For an exercise tracking one labeled melody voice from C4 to C5, should octave equivalence hide the leap?

> **Answer:** No. Keep the register and report the motion of 12 semitones. A pitch-class comparison may separately report 0, but it answers a different question. Neither score states whether a particular guitar fingering is comfortable.

## 2. Calculate the four comparisons

Use source `[60,64,67]` and target `[67,64,60]`. The source notes are C4, E4 and G4. With entry positions fixed, the first and last voices move by 7 semitones in opposite directions. With octave equivalence, each pair costs 5 instead. Allowing reassignment can match each pitch to itself.

| Octave equivalence | Permutation equivalence | Native scalar |
|---|---|---:|
| Off | Off | 14 |
| On | Off | 10 |
| Off | On | 0 |
| On | On | 0 |

These values were reproduced by compiling the unchanged pinned class in the [standalone lab](https://github.com/spareilleux/learn/tree/codex/streeling-craft-transfer-20261022/code/streeling/voice-leading). A compile-only annotation adapter is disclosed there; this is not the original GA assembly or its full test suite.

### Practice exercise 2

An agent quotes 0 for these arrays and concludes that the first labeled voice did not move. What information is missing?

> **Answer:** The equivalence settings and the voice correspondence. A zero after reassignment does not preserve the first entry as the first voice. The fixed-position absolute comparison is 14; its signed motions are +7, 0 and −7 semitones.

## 3. Common pitch classes do not mean sustained notes

Compare `[60,64,67]` with `[72,76,79]`. The registered collections share no pitch, yet all three pitch classes agree. The lab's teaching intersection counts are 0 common registered pitches and 3 common pitch classes. Those counts are simple set calculations, not output from GA's common-tones service. Fixed-position absolute distance is 36; fixed-position octave-equivalent distance is 0.

### Practice exercise 3

Write a truthful annotation for that octave shift, including both distances and the common-note distinction.

> **Answer:** “Registered distance 36; octave-equivalent distance 0; 0 common registered pitches and 3 common pitch classes.” Do not describe the notes as sustained or the hand as stationary. Duration, articulation and physical placement were not measured.

## 4. Reproduce a boundary of the pinned implementation

For `[60,63,65]` and `[60,65,75]`, enable octave and permutation equivalence and disable transposition and inversion. Both collections have the same pitch-class multiset. The pinned implementation returns 4. Its cyclic candidate costs are 4, 10 and 6. Exhaustive enumeration of all target permutations finds the assignment `[60,75,65]`, whose circular costs sum to 0. Sorting registered pitches before restricting the assignment search can miss this match.

Use installed [Node.js](https://nodejs.org/api/cli.html) and [.NET SDK 10.0.113](https://learn.microsoft.com/dotnet/core/tools/dotnet-build). From the Learn checkout, choose a fresh sibling output directory; its parent must already exist. This command has the same spelling on Windows, Linux / WSL and macOS, but only Windows has been assessed:

```sh
node code/streeling/voice-leading/run.mjs ../streeling-voiceleading-new-run
```

The controller checks source hashes, builds outside the checkout and writes `results.json` and `commands.json`. Package sources are cleared, and [background workload-manifest downloads are disabled](https://learn.microsoft.com/dotnet/core/tools/dotnet-environment-variables). The recorded run passed 40 characterization checks. That means it reproduced the declared observations, including the disagreement; `original_expected_equivalence_satisfied` remains false. Inspect the [retained results](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/voice-leading-2026-10-22/native-results.json), not just the process exit code.

### Practice exercise 4

Calculate the circular costs for the assignment `[60,75,65]`. Should a passing lab certify the original equivalence implementation?

> **Answer:** The matched differences are 0, 12 and 0, giving circular costs 0, 0 and 0. No: characterization succeeds by reproducing native 4 versus exhaustive 0. The production method has not been fixed by this lab.

## 5. Submit a comparison contract

Keep the source pin, arrays, all four equivalence choices, calculation table, observed scalar and interpretation in your receipt. Attach the executable results when available. If you cannot run the SDK, complete the hand calculations and label execution as unassessed. The [learner task and review rubric](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/voice-leading-2026-10-22/learner-task.md) separate source-assisted checking from a human learning trial.

### Practice exercise 5

Which additional evidence would justify calling a recommended voicing physically easy?

> **Answer:** An actual string/fret assignment, the player's constraints and a playing trial with a stated criterion. The scalar calculations, source inspection and standalone run provide none of those observations. Continue with [voice correspondence](mus-016-recover-voice-correspondence.md) before treating a minimum as a performance plan.
