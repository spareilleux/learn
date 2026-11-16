---
module_id: gtr-016-move-the-boundary-for-an-artificial-harmonic
department: guitar-studies
course: "Move the Boundary for an Artificial Harmonic"
level: advanced
prerequisites: ["gtr-012-select-natural-harmonics-with-a-touch-node"]
estimated_duration: "60 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Move the Boundary for an Artificial Harmonic

> Authored model and source reading. Human technical, fluent-language, musician and learner decisions remain pending. No new performance, listening, parser execution, engine render or production adoption is claimed.

A natural-harmonic touch coordinate cannot simply remain fixed when the left hand creates a new vibrating endpoint. An artificial-harmonic instruction needs the fretted base, the touch location and the sounding result separately. This course turns that distinction into bridge-relative geometry for a future [GA](https://github.com/GuitarAlchemist/ga) diagram.

## Read the retained evidence

The notation reference distinguishes natural and artificial harmonics and pitch roles. The ideal standing-wave reading supports the node calculation. Our geometry supplies the missing explicit coordinate; the retained frequency field does not implement finger contacts.

[Prerequisite](../../guitar-studies/en/gtr-012-select-natural-harmonics-with-a-touch-node.md)

[Retained project artifact](../../../../code/streeling/guitar-runtime/vendor/lib.rs)

[Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-25/unit-a.json)

[Primary reading](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/harmonic/)

[Primary reading](https://www.phys.unsw.edu.au/jw/strings.html)

## Fixed case and prepared quantities

```json
{
  "values": {
    "open_hz": 110,
    "fretted_semitones": 7,
    "touch_mode": 2,
    "fixed_absolute_touch_fraction": 0.5
  },
  "formula": "vibrating_fraction=2^(-fret/12); base_hz=open*2^(fret/12); touch_fraction_from_bridge=vibrating_fraction/mode; sounding_hz=mode*base_hz; fixed_touch_local=fixed_absolute_touch_fraction/vibrating_fraction",
  "expected": {
    "vibrating_fraction": 0.6674199270850172,
    "base_hz": 164.81377845643496,
    "touch_fraction_from_bridge": 0.3337099635425086,
    "sounding_hz": 329.6275569128699,
    "fixed_touch_local": 0.7491535384383408
  },
  "negative_control": {
    "values": {
      "open_hz": 110,
      "fretted_semitones": 0,
      "touch_mode": 2,
      "fixed_absolute_touch_fraction": 0.5
    },
    "expected": {
      "vibrating_fraction": 1,
      "base_hz": 110,
      "touch_fraction_from_bridge": 0.5,
      "sounding_hz": 220,
      "fixed_touch_local": 0.5
    }
  }
}
```

## Keep physical position separate from notation roles

The contact that firmly stops the string and the contact that lightly selects a node play different roles. Their coordinate relationship changes when the firm contact moves. A diagram that labels only a fret distance without saying which contact it describes can therefore be ambiguous even if its intended sounding note is correct. Preserve the action and the coordinate origin alongside each position.

The selected ideal length law assumes that fretting changes the vibrating length while leaving wave speed unchanged. Real contact can also change tension and introduce damping. Those effects would modify the frequency prediction, but they do not justify reusing the old full-length midpoint. The geometry and the acoustic approximations are separate statements that should be challenged separately during review.

The notation vocabulary is useful because a base, a touching pitch and a sounding pitch need not be interchangeable labels. Our case does not prescribe a universal way to notate the touch or prove that a particular reader executes it. A minimal manual drawing with the remaining length and desired mode is enough to catch the fixed-origin error. Before a generator creates practice diagrams, test that each diagram retains these relationships under different fretted bases, then obtain a real musician’s contact and sound evidence. Correct arithmetic alone cannot establish that the suggested hand placement is reachable.

### Exercise 1

Calculate the remaining vibrating fraction after fretting. Which endpoint is fixed in the coordinate?

<details><summary>Answer 1</summary>

The fraction is listed below and the bridge remains the origin. The fretted endpoint moves; a fraction of the original string is not automatically a fraction of the remaining string.

</details>

### Exercise 2

Locate the new midpoint touch and compute the fretted base frequency.

<details><summary>Answer 2</summary>

Use the main results. The touch lies halfway along the remaining segment, and the base frequency follows the stipulated equal-tempered length law.

</details>

### Exercise 3

Give the sounding frequency and distinguish it from base and touching pitch roles.

<details><summary>Answer 3</summary>

The sounding result is the selected mode times the fretted base. A diagram’s touch position and a notated pitch role must not be substituted for the resulting sound frequency.

</details>

### Exercise 4

Apply the open-string control. Why is it too weak to detect the fixed-location mistake?

<details><summary>Answer 4</summary>

The remaining length is the full string, so both midpoint constructions coincide. The fretted case separates them, as its fixed touch has the displayed different local coordinate.

</details>

### Exercise 5

What would reject a diagram claiming the same midpoint instruction for every fret?

<details><summary>Answer 5</summary>

Failure to scale its bridge distance with the remaining length rejects that geometry. Clean excitation and the performer’s technique still require an actual trial.

</details>

## Source-assisted learner task

Draw the open and fretted segments, compute both touch coordinates manually and identify the notation’s separate pitch roles. Propose an instruction that preserves the moving origin relationship. Treat a fixed original midpoint as a falsifying control, without claiming a played result.

First retain your unaided derivation before revealing the answers. Then inspect a specific source passage and its revision, record every kind of assistance, and keep the original and corrected responses separately. Use the direct manual result as the baseline for any calculator, DSL or agent proposal. Missing inputs stay unresolved. The fixed packet holds a prepared criterion for each exercise with no learner decision. A correct model answer supports only the declared case; acceptance needs an actual attempt and review. Record a falsifier before choosing an abstraction, then state the additional runtime or human evidence needed at the next boundary.
