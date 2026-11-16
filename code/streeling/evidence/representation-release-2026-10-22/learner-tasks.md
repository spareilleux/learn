# Representation and release learner attempt

Status: protocol prepared; no learner attempt or human approval recorded.

## Administration

Use a learner who did not author these drafts. Record UTC start/end, exact module source SHA-256, prior familiarity, language, timing, confidence, hints and source lookups. Let the learner read the lesson, then close it. Supply the input blocks and linked primary files below during the attempt; withhold lesson answer blocks and the separate reviewer rubric. Preserve the original response before feedback.

These overlapping, source-assisted tasks measure lesson-exposed reasoning only. They do not establish causal learning, independent transfer, full-course mastery, audio quality or live agent improvement. Add unseen transfer tasks and a declared comparison before those claims. Human subject, fluent-language and learner review remain open.

## FUT-002

Source: `streeling/courses/futurology/en/fut-002-routing-embedder-revisit-triggers.md`
SHA-256: `80d8dfa21108fc3ffae971243a53ebfcb5d6d30e8f5289b5c245f0961ccd6042`

Inputs available during the attempt:

Pinned Phase 0 numeric inputs: `bge-large` single-embed p95 = `238.27479999454226 ms`; `nomic-embed-text` single-embed p95 = `101.44889999355655 ms`. The report uses a `500 ms` budget. These measurements concern one embedding call, not a captured end-to-end chat request.

- [Numeric artifact](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/embedder-bakeoff/bakeoff-latest.json)

Task:

Using the numeric Phase 0 artifact, subtract `bge-large`'s single-embed p95 from the report's 500 ms budget. How much slower was its measured single-embed p95 than nomic's? What claim is still unsupported?

Response: ____________________
Confidence (0–100%): ______   Time: ______   Hints / lookups: ______

## FUT-003

Source: `streeling/courses/futurology/en/fut-003-agent-substitution-readiness-drill.md`
SHA-256: `3cdeafbc266a8f0ae39cf5f82a6bc7a22d83ffd58c3a4951a0f73bef8b276683`

Task:

The output reports `fixture-A-v2`, while its input and synthetic review target say `fixture-A-v1`. The build passes. Can the old verdict authorize publication of that output? What must happen next?

Response: ____________________
Confidence (0–100%): ______   Time: ______   Hints / lookups: ______

## INF-003

Source: `streeling/courses/information-theory/en/inf-003-verdict-distribution-drift.md`
SHA-256: `66c84ee111e358835be410e04e44f61b653343d3efd2d9626fd5545ab69a8f27`

Inputs available during the attempt:

Synthetic teaching counts; compare one fixed property in `[holds, fails, unknown]` order.

| Run | Holds | Fails | Unknown | Total |
|---|---:|---:|---:|---:|
| Baseline | 8 | 0 | 2 | 10 |
| Candidate | 6 | 2 | 2 | 10 |

Task:

For the table above, write both normalized vectors in `[holds, fails, unknown]` order. What additional metadata must travel with a real comparison?

Response: ____________________
Confidence (0–100%): ______   Time: ______   Hints / lookups: ______

## MCL-003

Source: `streeling/courses/musicology/en/mcl-003-style-labels-as-evidence.md`
SHA-256: `2d909db9f674ffd2dfb1d44322d0ee38d603efb2d1f3e9cf980869b4be7b3134`

Inputs available during the attempt:

Use the exact catalog entry as input; the catalog is available during the attempt. No recording is supplied for listening.

- [Pinned progression catalog](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.Config/ChordProgressions.yaml)

Task:

From the pinned catalog, give the `ii-V-I` category, key, Roman numerals, and chord names. Then write one permitted caption and one unsupported caption for a recording you have not heard.

Response: ____________________
Confidence (0–100%): ______   Time: ______   Hints / lookups: ______

## PHI-002

Source: `streeling/courses/philosophy/en/phi-002-when-is-an-advisory-decision-justified.md`
SHA-256: `99200375356de40b214a76b3273daf1a51fded6525611f1d7ff768c0589d1c38`

Inputs available during the attempt:

Synthetic input object (PR-EXAMPLE is invented):

```json
{
  "rule_result": {
    "rule_id": "SYNTHETIC-PR-READINESS",
    "subject": "pull_request",
    "decision": "recommend",
    "reason_codes": [],
    "evidence_refs": [],
    "next_actions": ["ask a human to inspect PR-EXAMPLE"],
    "confidence": "high"
  }
}
```

Use the following exact schema and advisory documents to judge the object; no actual CI or PR evidence is supplied.

- [Pinned schema](https://github.com/GuitarAlchemist/Demerzel/blob/9ba9a29f6424ac8c1a6654c9b979b282a8cf216f/schemas/advisory-decision.schema.json)
- [Advisory document](https://github.com/GuitarAlchemist/Demerzel/blob/9ba9a29f6424ac8c1a6654c9b979b282a8cf216f/docs/architecture/demerzel-advisory-decisions.md)
- [Rule-pack authority scope](https://github.com/GuitarAlchemist/Demerzel/blob/9ba9a29f6424ac8c1a6654c9b979b282a8cf216f/docs/governance/aiw-rule-packs.md)

Task:

Does the synthetic fixture (a) conform to the schema, (b) satisfy the advisory document's specific-evidence principle, and (c) authorize a GA merge? Cite the fields or sentences that decide each answer.

Response: ____________________
Confidence (0–100%): ______   Time: ______   Hints / lookups: ______

## PHI-003

Source: `streeling/courses/philosophy/en/phi-003-what-does-the-same-chord-mean.md`
SHA-256: `bc4e4b3148eb6e10f3809d9275a93f97eedff8aa1e52c9aebc438ce2281fc020`

Inputs available during the attempt:

Reference aid: pitch classes are MIDI numbers modulo 12. For the interval-class vector, count each unordered pair of distinct pitch classes in bins 1–6 using `min(d, 12-d)`, where `d` is the pair distance modulo 12. No guitar fingering, recording or listener result is supplied.

Task:

The fixture compares `c_major_low = [48,52,55]` with `c_major_high = [60,64,67]`. Are the MIDI-note multisets equal? Are the pitch-class sets and ICVs equal? What remains unproven about two guitar fingerings?

Response: ____________________
Confidence (0–100%): ______   Time: ______   Hints / lookups: ______

## PHY-003

Source: `streeling/courses/physics/en/phy-003-sampling-aliasing-guitar-engine.md`
SHA-256: `67f4d2e28ec8cf0ef646eacb4c7629c9f591600202e002f6e29d3668ba04f0f1`

Inputs available during the attempt:

Inspect the native WAV provenance and the browser initialization sources as separate inputs. No browser capture or context-rate observation is supplied.

- [Native fixture provenance](https://github.com/GuitarAlchemist/Demerzel/blob/17f82a4b4b913d7c64942a3d3ff670abf4e6f85c/state/streeling/fixtures/guitar-acoustics/gas-001/README.md)
- [Browser audio bridge](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Rust/guitar-web-wasm-demo/src/audio/audioEngine.js)
- [AudioWorklet](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Rust/guitar-web-wasm-demo/src/audio/guitar-worklet.js)

Task:

A reviewer sees the GAS-001 44.1 kHz render and writes, “GA's browser engine always runs at 44.1 kHz.” What can the sources actually support, and what should a browser test record?

Response: ____________________
Confidence (0–100%): ______   Time: ______   Hints / lookups: ______

## PHY-004

Source: `streeling/courses/physics/en/phy-004-velocity-pick-position-guitar-engine.md`
SHA-256: `30815d970eb5153a4e6d77e9b42a6336fdcfa007d7d2e5c350923c74fc2f8c6d`

Inputs available during the attempt:

Ideal-model reference: a flexible string fixed at both ends starts from a triangular displacement with fixed apex height at normalized position `p`, where `0 < p < 1`. The harmonic coefficient is proportional to `sin(nπp) / [n² p(1-p)]` for positive integer `n`. This is an ideal initial-displacement model; no recorded spectrum is supplied.

Task:

For the ideal triangular-displacement model, which harmonic indices have a zero initial coefficient at `p = 1/4`? Would a missing fourth harmonic in a captured guitar note prove that the player plucked at one-quarter of the string?

Response: ____________________
Confidence (0–100%): ______   Time: ______   Hints / lookups: ______

## PM-004

Source: `streeling/courses/product-management/en/pm-004-craft-extension-release-decision.md`
SHA-256: `31eff99588c7e7a35084aee798280862f745fff617547c66df337af67e92b855`

Inputs available during the attempt:

Use these dated source-experiment records and unchecked integration plan as the available inventory. Each record has its own artifact and measurement scope; no installable package, release receipt or user-installation trace is supplied with this task.

- [Audio-loop experiment](https://github.com/GuitarAlchemist/Demerzel/blob/861b6b1891ef7017c22269d5ec6be4c50953040c/state/streeling/courses/computer-science/en/cs-004-composable-agentic-audio-loop.md)
- [Mesh-cleanup experiment](https://github.com/GuitarAlchemist/Demerzel/blob/861b6b1891ef7017c22269d5ec6be4c50953040c/state/streeling/courses/visual-computing/en/vc-005-craft-details-through-blender-to-godot.md)
- [Weave fixture](https://github.com/GuitarAlchemist/Demerzel/blob/861b6b1891ef7017c22269d5ec6be4c50953040c/state/streeling/courses/visual-computing/en/vc-007-weave-seams-as-scene-contracts.md)
- [Godot plan](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/docs/plans/parked/2026-03-28-feat-godot-integration-plan.md)

Task:

A draft announcement says, “Our ComfyUI, Blender, and Godot craft suite is ready because the audio bridge, GLB script, and weave validator exist.” Repair the statement into one truthful present-tense sentence and one falsifiable proposed task.

Response: ____________________
Confidence (0–100%): ______   Time: ______   Hints / lookups: ______

## SEM-002

Source: `streeling/courses/semiotics/en/sem-002-chord-symbols-and-canonicalization.md`
SHA-256: `40b9a12d2c7fc5c6a07c3b77240370e8f5916c34f3577a64cdb9acae817b5ea6`

Inputs available during the attempt:

Read the pinned tests and renderer as inputs. No fresh parser run or original user recording is supplied.

- [Pinned DSL tests](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Tests/Common/GA.Business.DSL.Tests/ChordDslTests.cs)
- [Pinned renderer](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Generators/ChordRenderer.fs)

Task:

What canonical strings do the pinned tests expect for `Cmi7` and `D-7`? Which part of each written sign changes, and what would be lost if GA stored only the canonical output?

Response: ____________________
Confidence (0–100%): ______   Time: ______   Hints / lookups: ______

## SEM-003

Source: `streeling/courses/semiotics/en/sem-003-status-signs-and-evidence.md`
SHA-256: `3a6a31b47c60b7034cc967132d80c39b8fdaa13c3edec2787c385e3595ff08d8`

Inputs available during the attempt:

Use the schema, SEM-002 production record and AI subject-review scope below. These are historical source records, not a new human review or deployment observation.

- [Pinned production schema](https://github.com/GuitarAlchemist/Demerzel/blob/c453a91d1c4d913af72c28779eff826659c1d654/schemas/course-production.schema.json)
- [SEM-002 production record](https://github.com/GuitarAlchemist/Demerzel/blob/c453a91d1c4d913af72c28779eff826659c1d654/state/streeling/course-productions/cp-semiotics-2026-10-11-002.json)
- [Subject-review scope](https://github.com/GuitarAlchemist/Demerzel/blob/c453a91d1c4d913af72c28779eff826659c1d654/state/streeling/reviews/sem-002-subject-review-2026-10-11.md)

Task:

A handoff says only “SEM-002 is ready.” Identify two materially different objects that `ready` could represent, and rewrite the sentence so one of them can be checked. Do the pinned schema values include `ready`?

Response: ____________________
Confidence (0–100%): ______   Time: ______   Hints / lookups: ______

## VC-003

Source: `streeling/courses/visual-computing/en/vc-003-jitter-and-voicing-cloud-distance.md`
SHA-256: `e66350592803bfe2efb65545e219301026a1e04b49208c0df573b138d4cdb032`

Inputs available during the attempt:

Synthetic input has three XYZ points: `(0,0,0)`, `(0.2,0,0)`, `(10,0,0)`; `meta.total = 3`. The pinned loader reads the binary as a `Float32Array` and uses this exact length check:

```ts
  if (basePositions.length !== meta.total * 3) {
    throw new Error(
      `voicing-positions size mismatch: bin has ${basePositions.length / 3} points, meta says ${meta.total}`,
    );
  }
```

- [Pinned loader](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/ReactComponents/ga-react-components/src/components/PrimeRadiant/VoicingCloud.ts)

Task:

How many floats must the binary contain for this fixture? What does the pinned loader do if it contains only eight floats while `meta.total` remains three?

Response: ____________________
Confidence (0–100%): ______   Time: ______   Hints / lookups: ______

## VC-006

Source: `streeling/courses/visual-computing/en/vc-006-origami-fold-state-scene-trial.md`
SHA-256: `a54d470cccd50cd4b8c8ca97e89651bce5b99a12d9308e05bf3c8cad9a9a3f83`

Inputs available during the attempt:

Declared synthetic trial: panels A/B/C; crease `e1` joins A to B and `e2` joins B to C. The external trial contract must bind a crease ID to its incident panels, signed pose and policy-state meaning. No exported folded scene or interaction trace is supplied.

Task:

A modeler hands over two screenshots labeled `open` and `closed`, plus a GLB. The GLB has a visible ridge, but no crease IDs or panel adjacency record. Can a reviewer verify that `e1` changed state and still represents the policy dependency?

Response: ____________________
Confidence (0–100%): ______   Time: ______   Hints / lookups: ______
