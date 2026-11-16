---
module_id: aud-022-flush-the-tail-of-a-finite-convolution
department: audio-engineering
course: "Flush the Tail of a Finite Convolution"
level: advanced
prerequisites: ["aud-011-count-valid-frames-separately-from-block-padding"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Flush the Tail of a Finite Convolution

> Authored finite model and bounded source reading. Human technical, fluent-language, musician and learner decisions remain pending. No new engine render, listening, playing, parser execution or production adoption is claimed.

A [GA](https://github.com/GuitarAlchemist/ga) guitar render can end its input while a cabinet response still has pending output. The finite convolution support extends beyond the input support. Calling every later sample padding discards a legitimate tail. Conversely, feeding zeros forever is unnecessary for a finite response. Build the index table and find the last possible product before proposing a streaming adapter. This is an authored convolution, not a newly rendered guitar recording.

The missing operation is the end-of-input transition. The fixed schedule records `input` followed by `flush`, retains delay history newest first and stops only when the pending drain count is zero. No fresh input event is created by feeding a flush zero. Stopping when the caller has no input leaves a nonempty history and pending valid output. The earlier transfer-estimation course already identifies a discarded tail; this lesson makes the drain protocol explicit so a later adapter can preserve state across that boundary.

## Specific assumptions and limits

Use nonempty causal real arrays and zero extension. Output support follows finite linear convolution; the emission count must lie within that support. No cabinet capture or streaming exporter was executed.

## Work from the direct representation

Write the main input table before opening the prepared answers. Identify the coordinate system, physical or logical unit, support and ordering rule for every field. A number without its convention cannot safely cross into an audio graph, a scene or an agent message. Derive intermediate quantities as well as the final decision. The displayed packet deliberately keeps inputs and expected outputs separate so a second reader can recompute the result rather than merely recognize a familiar label.

Repeat the operation with the negative control, keeping its changed inputs visible. Explain which invariant survives and which claim fails. A useful control targets the mechanism under discussion; a different example that only looks plausible may never exercise the risky boundary. Agreement in the main case alone cannot show that a proposed abstraction preserves the operation. Conversely, a rejected control is an expected outcome of the teaching model, not an observed defect in an existing product.

Read the full prerequisite and the retained project artifact below. The prerequisite establishes an earlier operation with its own limits. The retained runner supplies an actual audio comparison workflow and separates raw samples, encoded output and acceptance claims. It does not implement this lesson’s new model. Local source hashes identify complete bytes at the pinned revision; they do not turn a source inspection into runtime execution. Where a primary reference is linked, use only the bounded definition recorded in the packet.

## Prepare a source-assisted project handoff

Create a short GA review note containing your manual calculation, the declared convention and the rejecting witness. Keep that direct result as the baseline before proposing a DSL node, agent instruction or scene control. Such a proposal must explain what information its input preserves and which observation would disprove its fidelity. If a required input is absent, leave the result unresolved instead of filling the gap with a convenient default.

Retain your unaided response before revealing the corrections. Record any calculator, source lookup or agent assistance, then preserve the corrected response alongside the original and explain the change. The packet contains a prepared criterion for each exercise, with no accepted learner decisions. Matching an answer key does not establish independent recall or a successful learner trial. Record actual commands, inputs, outputs, failures and replays in the validation journal when the model is tested. Keep human technical review, fluent-language review, musician judgment, production runtime and publication as separately supported decisions.

[Prerequisite](../../audio-engineering/en/aud-011-count-valid-frames-separately-from-block-padding.md)

[Retained project artifact](../../../../code/streeling/guitar-runtime/run.mjs)

[Fixed authored packet](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-a.json)

[Validation journal](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)

[Primary reading](https://www.dsprelated.com/freebooks/mdft/Convolution.html)

## Fixed case and prepared quantities

```json
{
  "values": {
    "x": [
      1,
      2
    ],
    "h": [
      1,
      0.5,
      0.25
    ],
    "emit_count": 4
  },
  "formula": "y[n]=sum(x[k]*h[n-k] for valid k and n-k); full_length=len(x)+len(h)-1; emitted=full[:emit_count]; lost=full[emit_count:]; after end of input feed exactly len(h)-1 flush frames; history is most recent len(h)-1 fed values newest first; stop at full_length, not at input exhaustion",
  "expected": {
    "full": [
      1,
      2.5,
      1.25,
      0.5
    ],
    "emitted": [
      1,
      2.5,
      1.25,
      0.5
    ],
    "lost": [],
    "complete": true,
    "phases": [
      "input",
      "input",
      "flush",
      "flush"
    ],
    "final_history": [
      0,
      0
    ],
    "pending_flush_frames": 0
  },
  "negative_control": {
    "values": {
      "x": [
        1,
        2
      ],
      "h": [
        1,
        0.5,
        0.25
      ],
      "emit_count": 2
    },
    "expected": {
      "full": [
        1,
        2.5,
        1.25,
        0.5
      ],
      "emitted": [
        1,
        2.5
      ],
      "lost": [
        1.25,
        0.5
      ],
      "complete": false,
      "phases": [
        "input",
        "input"
      ],
      "final_history": [
        2,
        1
      ],
      "pending_flush_frames": 2
    }
  }
}
```

### Exercise 1

Calculate the full output.

> **Answer:** It is `[1,2.5,1.25,0.5]`; the last value comes from the final input and final response coefficient.

### Exercise 2

How much valid output follows the input support?

> **Answer:** The tail has 2 samples. Its validity follows from the convolution support, independently of buffer capacity.

### Exercise 3

Does a zero input after exhaustion imply zero output immediately?

> **Answer:** No. Stored earlier input still contributes through delayed response coefficients.

### Exercise 4

What does the truncated control lose?

> **Answer:** It loses `[1.25,0.5]`, so its emitted vector cannot represent the complete response.

### Exercise 5

What falsifies complete export?

> **Answer:** Any nonzero omitted value inside the declared full convolution support rejects that claim.

## Source-assisted learner task

Apply the direct project handoff above to both fixed cases. Preserve the typed input table, every intermediate result, the negative-control explanation and the final rejecting witness. The prepared answers are checks, not observations of your work.
