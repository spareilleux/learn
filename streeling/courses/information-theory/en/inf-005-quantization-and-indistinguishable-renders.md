---
module_id: inf-005-quantization-and-indistinguishable-renders
department: information-theory
course: "Quantization and indistinguishable renders"
level: intermediate
prerequisites: ["inf-004-information-loss-in-agent-handoffs", "aud-005-pcm-guards-and-format-boundaries"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Quantization and indistinguishable renders

An engineer receives matching PCM16 artifacts and concludes that two guitar engines produced identical floating-point samples. That conclusion loses the distinction the experiment needs. This lesson teaches how to identify exactly which equality survived conversion, and which source information can no longer be recovered.

Read [INF-004](inf-004-information-loss-in-agent-handoffs.md) for information loss in handoffs and [AUD-005](../../audio-engineering/en/aud-005-pcm-guards-and-format-boundaries.md) for sample guards and format boundaries. Here the deliverable is a short argument about a deterministic many-to-one map. Use the [evidence packet](../../../../code/streeling/evidence/feedback-projections-2026-10-22/README.md) and [learner task](../../../../code/streeling/evidence/feedback-projections-2026-10-22/learner-task.md). Status: AI source draft; human subject, fluent-language, learner and public HTML publication reviews remain pending.

## 1. Locate the information-losing map

The [quantization analysis](../../../../code/streeling/evidence/feedback-projections-2026-10-22/quantization.json) reuses hash-verified retained buffers from the [recorded runtime experiment](../../../../code/streeling/evidence/guitar-runtime-2026-10-22/results.json). It is new analysis, not a new render. In each arm, 176400 native and WASM float32 samples were compared. Baseline has 2918 unequal raw samples; candidate has 2926. After conversion, each arm has 0 unequal PCM16 samples. These are native-versus-WASM comparisons within each arm, not baseline-versus-candidate equality.

The [runner](../../../../code/streeling/guitar-runtime/run.mjs) accepts finite decoded float32 values in `[-1,1]`. It applies [`Math.round`](https://tc39.es/ecma262/multipage/numbers-and-dates.html#sec-math.round) in [Node.js](https://nodejs.org/en/learn/getting-started/introduction-to-nodejs), after [`readFloatLE`](https://nodejs.org/docs/latest-v24.x/api/buffer.html#bufreadfloatleoffset) reads each source value:

```text
Q(x) = Math.round(x * 32767)
```

Signed int16 serialization follows. At zero-based baseline frame 646, native `0.000552888261154294` has little-endian bytes `b4ef103a`; WASM `0.0005528881447389722` has `b2ef103a`. Both produce code 18. The output has erased a real source distinction.

### Exercise 1 — Refute source equality

Which observation disproves “same PCM16 implies same float32”?

> **Answer:** Frame 646 supplies distinct float32 values and byte patterns with the same code 18. One counterexample refutes the universal implication; no listening claim is needed.

## 2. Treat a code as an equivalence class

Define `x ~ y` when their serialized PCM16 codes agree. Equality of outputs makes this relation reflexive, symmetric and transitive. A **fiber** is the set of accepted inputs sharing one code. Observing the code locates a fiber; it does not usually select one member.

For ideal real arithmetic with ties toward positive infinity, the fiber for integer `k` is:

```text
[(k - 0.5) / 32767, (k + 0.5) / 32767) intersect [-1,1]
```

The lower boundary belongs to the cell; the upper belongs to the next. Actual accepted inputs are float32 values processed by JavaScript arithmetic. Near a boundary, evaluate the exact encoder rather than assuming every ideal threshold is represented exactly. `Math.round` resolves ties toward positive infinity: `Math.round(0.5)` is 1, `Math.round(-1.5)` is -1, and `Math.round(-0.5)` is negative zero. Serialization collapses negative and positive zero into the same integer bytes.

The analysis also includes a **constructed toy**, not a captured guitar sample: `0.25` and `0.2500000298023224` both map to 8192. A decoder choosing `k / 32767` returns a representative, not proof of the original input.

### Exercise 2 — Invert the toy

Given only code 8192, can you choose uniquely between the toy inputs?

> **Answer:** No. Both belong to its fiber. An inverse returning either value fails for the other. Unique reconstruction requires additional source information or restrictions that distinguish them.

## 3. Count the encoder's alphabet

The accepted domain and scale give a minimum emitted code of -32767 and maximum of 32767. Including both endpoints gives `32767 - (-32767) + 1 = 65535` possible integer codes. The signed int16 format can store 65536 codes, including -32768, but this encoder never emits that extra code for its accepted inputs.

This alphabet count is not a measured entropy. Entropy needs a probability model over outputs; deterministic sample counts and observed collisions do not supply one. Likewise, 2918 differing samples counts positions in one comparison, not bits of lost information.

### Exercise 3 — Resolve the missing code

Why does a 16-bit container not imply 65536 reachable encoder outputs?

> **Answer:** Storage permits -32768, while `Q(-1)` is -32767. This encoder reaches only -32767 through 32767: 65535 codes. Container capacity and the map's image answer different questions.

## 4. Separate reconstruction error from source distance

With ideal real arithmetic, reconstructing a source as `Q(x) / 32767` has absolute error at most `1 / (2 * 32767)`, approximately 0.000015259254737998596. That half-step bound concerns one source and its chosen representative. Two inputs in the same interior fiber can approach a full step, `1 / 32767`, apart. The half-step is therefore not a general bound on their pairwise distance.

The measured maximum native reconstruction errors are 0.000015258982790783415 for baseline and 0.00001525887933261083 for candidate. Both raw native/WASM maximum differences are 2.9802322387695312e-8. These measure different pairs of quantities. Their small size alone does not guarantee equal codes: values on opposite sides of a threshold can be arbitrarily close in the ideal model.

### Exercise 4 — Match each error to its question

Does the raw maximum difference measure reconstruction error? Does the half-step bound establish PCM equality?

> **Answer:** Neither. Raw difference compares two engine outputs; reconstruction error compares a source with its decoded representative. PCM equality requires comparing encoded outputs. Threshold position matters as well as distance.

## 5. Preserve the strongest supported handoff

The analysis verifies full PCM16 payload hashes against the committed WAV payload for each arm. Combined with direct code comparisons, this supports equality after this specified conversion across all retained frames within each arm. The raw hashes differ. Retaining those buffers preserves distinctions that the WAV cannot recover.

Write a review note naming the encoder, domain, arm, frame count and evidence. This fixed offline experiment does not establish perceptual or timbral equivalence, a noise model, SNR, entropy, performance, browser behavior or all-platform reproducibility. No learner trial or listening test occurred in this analysis.

### Exercise 5 — Write the valid claim

Replace “the engines are identical” with a checkable handoff.

> **Answer:** For 176400 retained frames per arm, native and WASM differ at 2918 baseline and 2926 candidate raw positions, yet have 0 PCM16 code differences under `Q(x) = Math.round(x * 32767)` and signed int16 serialization. Each full payload matches its committed WAV payload. This establishes conversion-level equality for these inputs; unique float32 reconstruction and auditory equivalence remain unsupported. Submit this source-assisted learner packet for the pending reviews.
