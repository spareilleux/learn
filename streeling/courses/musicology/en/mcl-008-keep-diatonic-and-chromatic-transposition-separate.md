---
module_id: mcl-008-keep-diatonic-and-chromatic-transposition-separate
department: musicology
course: "Keep Diatonic and Chromatic Transposition Separate"
level: intermediate
prerequisites: ["mcl-005-preserve-written-and-sounding-pitch", "wml-005-declare-note-name-conventions"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Keep Diatonic and Chromatic Transposition Separate

> **Draft scope.** Authored integer-semitone spelling calculations, exact inverse controls and pinned source/primary-document reading. No new parser execution, transposition adapter, MusicXML output, rendered score or playback occurred. Human technical, musician, fluent-language and learner reviews and deployed course HTML verification remain pending.

## The project question

An imported part must sound one semitone higher. Should written C become C# or Db? [MCL-005](mcl-005-preserve-written-and-sounding-pitch.md) distinguishes encoded register from sounding register. This lesson adds the letter-name coordinate needed to preserve a specified enharmonic spelling.

[MusicXML's diatonic field](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/diatonic/) counts written-to-sounding pitch steps. Its [chromatic field](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/chromatic/) counts semitones. Both exclude the separate octave-change contribution. We use these definitions in an authored twelve-tone equal-tempered model, with C4 equal to 60 and integer alterations only.

## 1. Follow two coordinates

Index letters C through B by 0 through 6 and let `j=7*octave+letter_index`. If diatonic offset is `d`, chromatic offset is `c` and octave change is `o`, the target coordinates are `j_new=j+d+7*o` and `m_new=m+c+12*o`, where `m` is the absolute note number.

The new diatonic coordinate chooses a letter and written octave. Its required alteration is the difference between the target note number and that natural letter's note number. The semitone offset alone does not choose the letter.

### Practice exercise 1: produce two enharmonic targets

Start with C4 at 60 and use chromatic offset 1 with no octave change. Compare diatonic offset 0 against diatonic offset 1. Give both spellings and note numbers.

> **Answer:** Diatonic 0 retains the C letter, so alteration +1 gives C#4. Diatonic 1 selects D4, whose natural number is 62, so alteration -1 gives Db4. Both target 61. Equal sounding number does not imply equal spelling.

## 2. Carry letter changes across the octave boundary

B3 at 59 moved by one letter and one semitone becomes C4 at 60. Moving C4 down one letter and one semitone instead gives B3 at 59. If that second operation moves down two semitones, the target is Bb3 at 58.

The written octave belongs to the letter spelling. B#3 has note number 60, while Cb4 has 59. Reducing a natural-note coordinate modulo 12 before preserving its octave can hide these boundary effects.

### Practice exercise 2: audit the boundary cases

Calculate B3 plus one letter/one semitone, then C4 minus one letter/two semitones. Give the numbers of B#3 and Cb4, and explain why written octave alone cannot identify sounding register.

> **Answer:** The first result is C4 at 60; the second is Bb3 at 58. B#3 is 60 and Cb4 is 59 because their alterations cross the natural C boundary. The letter, alteration and octave together determine the number; an isolated written-octave field is insufficient.

## 3. Apply an octave change in both domains

For C4 with zero diatonic and chromatic offsets but octave change -1, subtract seven letter steps and twelve semitones. The target is C3 at 48. Adding only the semitone contribution while keeping the old letter octave would instead require an artificial alteration of -12 on C4. That can match a number while failing the intended spelling representation.

### Practice exercise 3: maintain the representation

Derive the two target coordinates for this downward octave. Why is C4 with alteration -12 not the intended output, and does an integer type alone enforce a small accidental range?

> **Answer:** The diatonic index decreases by 7 and the note number by 12, giving C3 at 48. Keeping C4 and attaching -12 changes the representation instead of carrying the octave change into the written coordinate. An integer type alone enforces no accidental range; any validation must be inspected separately.

## 4. Preserve enough information to reverse the transform

Move C#4 and Db4 each by one letter and two semitones. They become D#4 and Eb4 respectively, both at 63. Reversing both offsets on the retained spelled results recovers the distinct originals. Keeping only 63 loses the distinction needed to recover which spelling was supplied.

The [fixed transposition record](../../../../code/streeling/evidence/capo-spelling-2026-10-22/spelled-transpositions.json) contains ten authored cases with exact inverse controls. This is a bounded arithmetic result, not a general MusicXML implementation, proof about every notation tradition or listening test.

### Practice exercise 4: identify the reversible representation

Show the two forward spellings and their equal projected number. Which inputs must survive for the demonstrated inverse to recover the original spelling? Does retaining only the projected number suffice?

> **Answer:** C#4 becomes D#4 and Db4 becomes Eb4; both project to 63. Preserve the target letter, alteration and octave together with the specified diatonic, chromatic and octave offsets. Negating those offsets recovers C#4 and Db4 in these cases. The single projected number cannot distinguish their origins.

## 5. Distinguish stored spelling from implemented transposition

The pinned [MusicXML types](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Types/MusicXmlTypes.fs#L282-L295) retain step, optional integer alteration and octave, then provide a conversion to an integer note number. The selected [parser attributes](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.DSL/Parsers/MusicXmlParser.fs#L165-L180) contain no transposition field. Retaining a spelled pitch is not evidence that this helper performs our transformation. Its alteration comment also does not itself enforce a range.

The separate [CapoSkill spelling policy](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.ML/Agents/Skills/CapoSkill.cs) chooses a sharp/flat spelling preference for a pitch class. That policy is not the two-coordinate diatonic transposition derived here.

### Practice exercise 5: prepare a source-assisted import check

Read the definitions and source, then propose a bounded comparison before adding a new notation DSL or claiming a successful import.

> **Answer:** Retain original spelled pitch, declared written-to-sounding offsets, intended target spelling and number, source revision and supported alteration policy. Test both enharmonic branches, octave boundaries and inverses against independent expected results; preserve or reject unsupported context explicitly. Compare a small typed transformation before adding a DSL. The current source inspection and arithmetic establish neither a parser correction nor an application import, rendered score or playback result.
