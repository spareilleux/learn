---
module_id: wml-004-preserve-intonation-beyond-pitch-classes
department: world-music-languages
course: "Preserve Intonation Beyond Pitch Classes"
level: intermediate
prerequisites: ["wml-002-dadgad-layout-and-cultural-claims"]
estimated_duration: "35 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Preserve Intonation Beyond Pitch Classes

> **Draft scope.** Pinned public source inspection and constructed frequency calculations. Human technical review, musician review, fluent-language review, learner attempts and deployed course HTML verification remain pending. No performed tradition, GA audio render or listening outcome is measured here.

## The project question

An agent sends a scale from a catalog to a guitar tool and says that its intonation survived. What information would support that claim? In [Guitar Alchemist's world-scale model](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.Config/WorldScalesConfig.fs), intervals are documented as integer semitone steps, pitch classes as values within a twelve-step system, and tuning as a string annotation. These fields serve catalog search. They do not declare a structured frequency or cents value for every degree.

The model's tuning field is a plain string, not an enforced enumeration in the inspected definition. Reading one model does not establish validation of every catalog value or the behavior of every GA subsystem. This course follows particular boundaries at commit `dc2e74cbd992a298f67efb928b5b3754615e1924`.

## 1. Keep the approximation label attached

The [stored Rast entry](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.Config/WorldScales/MaqamScales.yaml) contains intervals `[2,2,1,2,2,2,1]`, pitch classes `[0,2,4,5,7,9,11]`, mask 2741 and tuning annotation `approx-12tet`. Reconstructing the mask as the sum of `1 << p` for those pitch classes gives 2741. The annotation belongs with the result: the stored twelve-step approximation is not a certified description of performed intonation.

The musician-authored [MaqamWorld Rast page](https://maqamworld.com/en/maqam/rast.php) discusses jins relationships and repertoire examples. A shared pitch-class mask cannot establish those relationships, phrasing, practice or identity. No linked recording was copied, played or analyzed in this packet. Do not convert unreviewed catalog prose into musical authority.

### Practice exercise 1: interpret a matching mask

An agent finds mask 2741 both in this Rast catalog entry and in a major-scale pitch-class set. What has matched, and which annotation must remain visible?

> **Answer:** The selected twelve-step pitch-class set has matched. Keep `approx-12tet`, the entry's tradition and its source identity. The match does not establish equivalent performance practice, exact intonation or interchangeable musical meaning.

## 2. Measure the information a projection loses

Use A4 = 440 Hz and the twelve-step reference formula `f(m)=440*2^((m-69)/12)`. C4, at MIDI 60 under this reference, is 261.625565301 Hz. Construct one tone at `f_a=(5/4)*f(60)` and another at `f_b=f(64)`. They are 327.031956626 Hz and 329.627556913 Hz respectively.

A [musical cent](https://www.nist.gov/pml/time-and-frequency-division/popular-links/time-frequency-z) is a frequency ratio of `2^(1/1200)`. Thus `1200*log2(f_a/f(60))` gives 386.313713865 cents, while the second tone is 400 cents above the reference tonic. The first is 13.686286135 cents below the second. This ratio exercise is an original mathematical construction. **It does not prescribe a 5:4 degree for Rast or any tradition.**

### Practice exercise 2: recover the offset

Calculate the cent distance from the reference tonic for the 5:4 construction and its signed offset from the 400-cent tone. Does this calculation specify Rast performance?

> **Answer:** `1200*log2(5/4)` gives 386.313713865 cents. Subtracting 400 gives -13.686286135 cents. The sign means the constructed first tone is lower. The calculation establishes a ratio relationship only; it specifies no tradition's performance practice.

## 3. Separate an authored projection from an observed converter

Define a teaching projection: calculate `u=69+12*log2(f/440)`, then choose the nearest integer step. The two constructed tones give approximately 63.863137139 and 64, so this policy maps both to MIDI 64. If only that integer survives, their difference is lost. This policy was authored for the lesson; no GA frequency-to-MIDI converter was executed or certified here.

Two advisory handoff alternatives retain the constructed target: frequency 327.031956626 Hz with reference A4 = 440 Hz, or MIDI 64 with offset -13.686286135 cents and the same reference. These are teaching alternatives, not a ratified schema or an implemented cross-repository contract. Reference, units, provenance and approximation status must accompany any intended meaning.

### Practice exercise 3: repair the handoff claim

Both tones arrive as MIDI 64. Can the receiver recover their original difference? Propose a retained value that would distinguish them without claiming a new GA schema exists.

> **Answer:** The integer alone cannot recover the difference. Retain a frequency with its reference, or MIDI 64 plus an explicit cents offset and reference. The first tone's offset is -13.686286135 cents; the second's is 0. Mark these records as advisory examples and preserve provenance. Their existence in this lesson does not establish implementation support.

## 4. Follow each interface's actual representation

The [MidiNote value object](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Core/Primitives/Notes/MidiNote.cs) represents an integer from 0 through 127, with pitch class computed modulo 12. The [fretboard mapper](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Services/Fretboard/Analysis/FretboardPositionMapper.cs) subtracts open-string MIDI from target MIDI and checks the fret range. These particular boundaries are discrete.

In contrast, the [Rust audio entry point](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Rust/guitar-web-wasm-demo/rust-engine/src/lib.rs) accepts `freq:f32` in `engine_note_on` and forwards it to excitation. A floating-frequency argument is a different representation. Its signature alone does not prove that a render realizes the requested pitch accurately. Preserve a target through the whole path, then measure the resulting signal before claiming fidelity.

### Practice exercise 4: locate the remaining test

A receiver accepts a floating frequency. Does this prove that an offset survived catalog lookup, fret mapping and audio synthesis? Name the evidence still needed.

> **Answer:** No. Trace the retained target, reference and units across each interface, identify any discrete projection, and measure the rendered frequency against the intended target. The floating argument demonstrates acceptance at one entry point; it does not attest the preceding handoff or resulting audio.

## 5. Match the conclusion to the probe

The actual [GA interval-name probe](../../../../code/streeling/evidence/intonation-listening-2026-10-22/ga-intervals-probe.json) for C returned `P1, M3, P5`. It returned no frequency, cents, tuning reference, performance or runtime source revision. The [calculation record](../../../../code/streeling/evidence/intonation-listening-2026-10-22/intonation.json) separately contains the authored construction and catalog fields. Do not combine these into an unobserved end-to-end success.

### Practice exercise 5: write the agent's bounded conclusion

An agent says: “The interval probe confirms that Rast intonation is preserved by the guitar engine.” Replace that statement with a conclusion supported by this packet.

> **Answer:** The C probe returned interval names. Pinned source exposes a twelve-step Rast approximation and a separate floating-frequency audio entry point. The constructed calculation shows how an integer projection can lose a cents difference. Preservation through a live pipeline, musical validity and listener outcomes remain unverified.

## Evidence and next experiment

The [public source receipt](../../../../code/streeling/evidence/intonation-listening-2026-10-22/primary-readback.json) binds eight files to the pinned commit. [PHY-007](../../physics/en/phy-007-separate-beating-from-decay.md) uses the same constructed frequencies to examine interference; [COG-004](../../cognitive-science/en/cog-004-score-a-pitch-discrimination-task.md) distinguishes numerical separation from an observed listening result. A future tradition-specific lesson needs musician review and appropriate performed evidence before making performance claims.
