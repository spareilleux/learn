---
module_id: wml-015-carry-the-concert-reference-through-a-frequency-handoff
department: world-music-languages
course: "Carry the Concert Reference Through a Frequency Handoff"
level: advanced
prerequisites: ["wml-004-preserve-intonation-beyond-pitch-classes"]
estimated_duration: "60 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Carry the Concert Reference Through a Frequency Handoff

> Authored model and source reading. Human technical, fluent-language, musician and learner decisions remain pending. No new performance, listening, parser execution, engine render or production adoption is claimed.

Two tools can agree on every interval in a phrase while disagreeing on its absolute frequencies. An omitted concert reference is one possible cause. For a [GA](https://github.com/GuitarAlchemist/ga) frequency handoff, we change calibration without changing note numbers or interval structure. This is distinct from transposing the phrase: the written identities stay fixed while the reference changes.

## Read the retained evidence

The primary reading describes the conventional reference and cent relationship. Our alternative reference is authored, without a claim about a particular ensemble. The retained packet stores reference fields and warns that accepting a frequency does not prove its acoustic realization.

[Prerequisite](../../world-music-languages/en/wml-004-preserve-intonation-beyond-pitch-classes.md)

[Retained project artifact](../../../../code/streeling/evidence/intonation-listening-2026-10-22/intonation.json)

[Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-25/unit-a.json)

[Primary reading](https://www.nist.gov/pml/time-and-frequency-division/popular-links/time-frequency-z)

## Fixed case and prepared quantities

```json
{
  "values": {
    "reference_a_hz": 442,
    "comparison_a_hz": 440,
    "midi_notes": [
      69,
      81
    ]
  },
  "formula": "f(n)=reference*2^((n-69)/12); calibration_ratio=reference/comparison; calibration_cents=1200*log2(calibration_ratio); octave_ratio=f(81)/f(69)",
  "expected": {
    "frequencies_hz": [
      442,
      884
    ],
    "calibration_ratio": 1.0045454545454546,
    "calibration_cents": 7.851415040126504,
    "octave_ratio": 2
  },
  "negative_control": {
    "values": {
      "reference_a_hz": 440,
      "comparison_a_hz": 440,
      "midi_notes": [
        69,
        81
      ]
    },
    "expected": {
      "frequencies_hz": [
        440,
        880
      ],
      "calibration_ratio": 1,
      "calibration_cents": 0,
      "octave_ratio": 2
    }
  }
}
```

## Separate calibration from note identity

The reference maps a named note coordinate to a physical frequency. Changing that mapping leaves the written coordinate unchanged. Transposition, in contrast, changes the coordinate under a specified musical transformation. These operations can yield similar frequency shifts for a particular note but preserve different meanings in an interchange record. A receiver should not infer one operation merely because the output happens to sound higher.

Ratios between notes cancel the common reference in this model. That explains why a phrase can retain every internal interval while failing an absolute pitch check. It also explains why octave agreement is an especially weak calibration test. A useful comparison must include at least one absolute-frequency target with the reference and units retained, then distinguish the requested value from an estimated realized value.

Our alternative calibration is a teaching input, not a recommendation that an ensemble adopt it. Actual instruments, contexts and musical practices may choose different references or nonuniform adjustments. A future scale handoff could also combine a concert reference with per-degree ratio information; neither should silently replace the other. The direct frequency table makes this separation visible before a project considers a new tuning abstraction. If a record loses its reference, report that missing input explicitly rather than guessing from a familiar note name or claiming an automatic transposition corrected it.

### Exercise 1

Convert the main note list into frequencies under its declared reference.

<details><summary>Answer 1</summary>

The expected frequencies appear below. The note numbers alone do not determine them unless the receiving tool knows the reference used in the conversion.

</details>

### Exercise 2

Compute the calibration ratio and cent offset against the comparison reference.

<details><summary>Answer 2</summary>

Both apply equally to every note under this model. An additive frequency offset would not preserve the same cent shift across registers.

</details>

### Exercise 3

Check the octave ratio. Can that check detect a forgotten reference?

<details><summary>Answer 3</summary>

The octave remains exact in the main and control cases. An interval-only test therefore cannot identify this absolute-frequency mismatch.

</details>

### Exercise 4

Apply the comparison-reference control. Which discrepancy disappears?

<details><summary>Answer 4</summary>

The calibration offset becomes zero and the absolute frequencies change. Written note identities and the octave ratio remain unchanged.

</details>

### Exercise 5

What rejects a receiver’s claim to retain the original calibration?

<details><summary>Answer 5</summary>

Reconstructing the control frequencies from the main reference-bearing input rejects preservation. A correctly retained request still needs a measured output frequency before claiming renderer fidelity.

</details>

## Source-assisted learner task

Compute both frequency tables manually, then trace the retained reference field. Propose a handoff receipt that distinguishes written identity, calibration and intended frequency. State the absolute-frequency falsifier before an agent recommends tuning or transposition.

First retain your unaided derivation before revealing the answers. Then inspect a specific source passage and its revision, record every kind of assistance, and keep the original and corrected responses separately. Use the direct manual result as the baseline for any calculator, DSL or agent proposal. Missing inputs stay unresolved. The fixed packet holds a prepared criterion for each exercise with no learner decision. A correct model answer supports only the declared case; acceptance needs an actual attempt and review. Record a falsifier before choosing an abstraction, then state the additional runtime or human evidence needed at the next boundary.
