---
module_id: aud-024-prewarp-a-bilinear-filter-cutoff
department: audio-engineering
course: "Prewarp a Bilinear Filter Cutoff"
level: advanced
prerequisites: ["aud-013-resample-without-relabeling-the-clock"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Prewarp a Bilinear Filter Cutoff

> Authored finite model and bounded source reading. Human technical, fluent-language, musician and learner decisions remain pending. No new engine render, listening, playing, parser execution or production adoption is claimed.

A filter design request names a digital cutoff, while an analog prototype accepts angular frequency. Copying the requested frequency directly into the prototype ignores the bilinear map. Invert that map before generating coefficients for a future guitar filter. The chosen clock deliberately makes the mismatch easy to see. The mapping preserves a selected target, not every bandwidth or shape in ordinary frequency coordinates; a complete design still needs its own specification.

## Specific assumptions and limits

The clock is positive and the target lies strictly below Nyquist and above zero. Use the stated bilinear factor and the principal real arctangent. This is frequency-map arithmetic, not executed filter coefficient generation.

## Work from the direct representation

Write the main input table before opening the prepared answers. Identify the coordinate system, physical or logical unit, support and ordering rule for every field. A number without its convention cannot safely cross into an audio graph, a scene or an agent message. Derive intermediate quantities as well as the final decision. The displayed packet deliberately keeps inputs and expected outputs separate so a second reader can recompute the result rather than merely recognize a familiar label.

Repeat the operation with the negative control, keeping its changed inputs visible. Explain which invariant survives and which claim fails. A useful control targets the mechanism under discussion; a different example that only looks plausible may never exercise the risky boundary. Agreement in the main case alone cannot show that a proposed abstraction preserves the operation. Conversely, a rejected control is an expected outcome of the teaching model, not an observed defect in an existing product.

Read the full prerequisite and the retained project artifact below. The prerequisite establishes an earlier operation with its own limits. The retained runner supplies an actual audio comparison workflow and separates raw samples, encoded output and acceptance claims. It does not implement this lesson’s new model. Local source hashes identify complete bytes at the pinned revision; they do not turn a source inspection into runtime execution. Where a primary reference is linked, use only the bounded definition recorded in the packet.

## Prepare a source-assisted project handoff

Create a short [GA](https://github.com/GuitarAlchemist/ga) review note containing your manual calculation, the declared convention and the rejecting witness. Keep that direct result as the baseline before proposing a DSL node, agent instruction or scene control. Such a proposal must explain what information its input preserves and which observation would disprove its fidelity. If a required input is absent, leave the result unresolved instead of filling the gap with a convenient default.

Retain your unaided response before revealing the corrections. Record any calculator, source lookup or agent assistance, then preserve the corrected response alongside the original and explain the change. The packet contains a prepared criterion for each exercise, with no accepted learner decisions. Matching an answer key does not establish independent recall or a successful learner trial. Record actual commands, inputs, outputs, failures and replays in the validation journal when the model is tested. Keep human technical review, fluent-language review, musician judgment, production runtime and publication as separately supported decisions.

[Prerequisite](../../audio-engineering/en/aud-013-resample-without-relabeling-the-clock.md)

[Retained project artifact](../../../../code/streeling/guitar-runtime/run.mjs)

[Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-a.json)

[Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)

[Primary reading](https://www.dsprelated.com/freebooks/filters/Frequency_Warping.html)

## Fixed case and prepared quantities

```json
{
  "values": {
    "sample_rate_hz": 8,
    "target_hz": 2,
    "prewarp": true
  },
  "formula": "Omega=2*fs*tan(pi*target/fs) if prewarp else 2*pi*target; achieved=fs/pi*atan(Omega/(2*fs)); error=achieved-target",
  "expected": {
    "analog_rad_s": 16,
    "achieved_hz": 2,
    "error_hz": 0
  },
  "negative_control": {
    "values": {
      "sample_rate_hz": 8,
      "target_hz": 2,
      "prewarp": false
    },
    "expected": {
      "analog_rad_s": 12.566370614359172,
      "achieved_hz": 1.6953789327654465,
      "error_hz": -0.3046210672345535
    }
  }
}
```

### Exercise 1

Find the prewarped analog target.

> **Answer:** It is `16 rad/s`; the tangent argument is `pi/4`.

### Exercise 2

Map it back to digital frequency.

> **Answer:** The inverse gives `2 Hz`, so the selected target error is 0.

### Exercise 3

Can hertz be substituted for angular frequency?

> **Answer:** No. Their units differ; the conversion factor belongs in the declared map.

### Exercise 4

Why does the naive control miss the target?

> **Answer:** Its analog value `4*pi` is smaller than 16 and the monotone map returns a lower digital cutoff.

### Exercise 5

What rejects the requested cutoff claim?

> **Answer:** A mapped achieved frequency differing from the retained requested target rejects it under this map.

## Source-assisted learner task

Apply the direct project handoff above to both fixed cases. Preserve the typed input table, every intermediate result, the negative-control explanation and the final rejecting witness. The prepared answers are checks, not observations of your work.
