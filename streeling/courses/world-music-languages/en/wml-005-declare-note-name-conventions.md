---
module_id: wml-005-declare-note-name-conventions
department: world-music-languages
course: "Declare the Note-Name Convention Before Interpreting B"
level: intermediate
prerequisites: ["wml-003-term-preservation-and-cultural-review"]
estimated_duration: "30 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Declare the Note-Name Convention Before Interpreting B

> **Draft scope.** Primary documentation, pinned public GA source, an authored decision table and actual chord-transposition tool responses. Human technical review, fluent-language review, learner attempts and deployed course HTML verification remain pending. No new language adapter or C# parser execution is delivered.

## The project question

A guitarist sends an agent “B, capo 2.” An impeccable transposition can still answer the wrong musical question if the agent chooses the wrong naming convention. The [LilyPond 2.24 language table](https://lilypond.org/doc/v2.24/Documentation/notation/writing-pitches#note-names-in-other-languages) makes a useful explicit distinction: its English vocabulary has B natural, while its German vocabulary uses H for B natural and B for B flat. The lesson uses those two **declared conventions**; nationality, interface language and a player's location do not establish which convention a particular chart uses.

[WML-003](wml-003-term-preservation-and-cultural-review.md) preserves terms and review responsibility. Here the task is narrower: determine the pitch a token denotes before passing it to GA. The [authored decision table](../../../../code/streeling/evidence/pitch-context-2026-10-22/language-decisions.json) is a teaching artifact, not an installed normalization service.

## 1. Read a token together with its convention

For this table, output spellings use English letter names and pitch classes use C as 0. Octave and chord quality are deliberately absent.

| Declared convention | Input token | English output | Pitch class | Decision |
| --- | --- | --- | --- | --- |
| English | B | B | 11 | resolved |
| English | Bb | Bb | 10 | resolved |
| German | B | Bb | 10 | resolved |
| German | H | B | 11 | resolved |
| unspecified | B | unresolved | unresolved | ask for convention |
| English | H | unresolved | unresolved | outside declared vocabulary |

### Practice exercise 1: resolve the disagreement

Two charts both contain B. One declares English names; the other declares German names. Give the English output and pitch class for each. Is one chart necessarily misspelled?

> **Answer:** English B gives B, class 11; German B gives Bb, class 10. Neither is necessarily misspelled. Their declared conventions give the same token different meanings.

## 2. Inspect GA's actual input boundary

At public GA commit `dc2e74cbd992a298f67efb928b5b3754615e1924`, [NaturalNote](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Core/Primitives/Notes/NaturalNote.cs) recognizes A through G. The generic [PitchParser](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Core/Primitives/Notes/PitchParser.cs) selects sharp or flat accidental syntax and expects an octave. Its pattern has no H alternative. This is source inspection, not a new execution of that C# path. Its unanchored pattern also prevents us from treating inspection as a general certificate of strict whole-input validation.

Canonical English spellings for the declared German examples would be B and Bb. An octave-bearing pitch interface would additionally need a declared octave, for example B4 or Bb4. A chord-symbol interface is a different contract: a bare B can name a chord root without supplying a register. LilyPond's own lowercase note and octave syntax is not GA's input syntax.

### Practice exercise 2: choose the destination representation

A source declares German names and contains H at octave 4. Give an English octave-bearing spelling. What must be established before converting a bare B from an unspecified chart?

> **Answer:** H at octave 4 becomes B4 under the declared convention. For the unspecified B, establish the naming convention first; add an octave only if the destination needs an absolute pitch. A root name alone does not supply register.

## 3. A correct downstream operation cannot repair an earlier guess

The [actual tool probes](../../../../code/streeling/evidence/pitch-context-2026-10-22/theory-tool-probes.json) record GA chord transposition: B up 2 semitones returned C#, and Bb up 2 returned C. These responses agree with pitch-class arithmetic: `(11+2)%12 = 1` and `(10+2)%12 = 0`. The service revision is unknown. These calls do not execute a German-name adapter or prove the deployed parser matches the inspected commit.

The one-semitone disagreement begins at interpretation. Retrying the same transposition, adding a more elaborate agent chain or increasing confidence would preserve the wrong premise.

### Practice exercise 3: trace the error

An agent silently interprets an unspecified B as English and applies capo 2. Compare that answer with the declared German interpretation. Which missing input explains the disagreement?

> **Answer:** English B leads to C#, class 1; German B first becomes Bb and leads to C, class 0. The missing input is the note-name convention. The transposition operation can be arithmetically correct in both branches.

## 4. Preserve enough context to reverse a decision

A proposed handoff should retain the original token, declared convention, canonical spelling, interpretation decision and source evidence. This is an advisory payload design, not a new mandatory ecosystem schema. For German H, retaining only canonical B loses the original spelling even though it preserves the chosen pitch class. For an unresolved B, retain the ambiguity rather than converting it to an arbitrary class with a warning elsewhere.

Do not infer a whole vocabulary from one convenient substitution. A general adapter would need accidentals, octave conventions, valid syntax, unsupported-token behavior and a reviewable source declaration. This small table makes no claim to implement them all.

### Practice exercise 4: retain the right distinction

Compare an English B and a German H after both become canonical B. Are they the same original text? Name the context an agent should retain if it must later explain its decision.

> **Answer:** They are not the same original text. Retain the original token and declared convention, the canonical output and the evidence for the interpretation. Equality of a derived pitch class does not imply equality of provenance or notation.

## 5. Verify ambiguity handling before broadening the vocabulary

Use all six rows as a source-assisted exercise. The four resolved rows must preserve the declared mapping. The unspecified B must remain unresolved; English H is outside this exercise's declared vocabulary. Distinguish these two reasons rather than collapsing them into one successful default.

These decisions are expected behavior for a proposed boundary, not measured behavior of a new GA component. [MCL-005](../../musicology/en/mcl-005-preserve-written-and-sounding-pitch.md) adds a separate distinction after spelling: an encoded written pitch may still need a declared transposition to identify its sound.

### Practice exercise 5: reject a misleading success metric

An adapter returns a pitch class for all six rows and reports complete coverage. It assigns unspecified B to class 11 and English H to class 11. Does this pass the declared table? State the required outcomes.

> **Answer:** No. Only the four resolved rows have declared pitch classes. Unspecified B needs the convention; English H is outside the declared vocabulary. Returning a number for every input conceals two unresolved or unsupported cases and does not prove correct interpretation.

## Source-assisted learner task

Complete the [prepared task](../../../../code/streeling/evidence/pitch-context-2026-10-22/learner-task.md) before opening its rubric. Explain a convention-dependent disagreement and write a handoff preserving the unresolved case. Source and calculator assistance are allowed; actual learner responses and review decisions remain unrecorded.
