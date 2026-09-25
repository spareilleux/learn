# Pre-registration — real Demerzel beliefs (sanity check)

Written and committed **before any call**. The three synthetic steps left one
definition change worth carrying to Demerzel — the conflict sentence — and the
step-2 note made that conditional on a check against real belief files. This is
that check.

**Corpus:** `demerzel-real-beliefs-corpus.json` — all 8 belief files in
`state/beliefs/` at GuitarAlchemist/Demerzel `50d1163` (public), proposition and
evidence object as recorded; label = the recorded `truth_value` (3 T, 5 P, no U,
D, F or C). The recorded value is Demerzel's own judgement, not ground truth.

**Run:** `--definitions leaning` (step 3, the best-scoring and the one carrying
the conflict sentence), two option orders, 16 calls, no retry.

**Pass** (both arms): 0 answers of F, D or C on any belief (the model must not
invent refutation or conflict in real, mostly-supported evidence) **and** 0
answers of T on a belief recorded P (no upgrade past Demerzel's own threshold).
Exact agreement is reported, not decisive: n = 8 supports no rate.

**Fail** means the conflict sentence is not proposed for
`logic/hexavalent-logic.md` until the disagreement is explained.

---

## Results — 2026-09-25 (appended after the run; the section above is unchanged since e5153b4)

16/16 answered, all `jev-1.13.0`, no retry; 17,292 input tokens reported,
$0.0007 computed. Receipt: `evidence/demerzel-real-beliefs-live.json`.

| Belief (recorded) | canonical | reversed |
|---|---|---|
| b01 behavioral-test-coverage (T) | T 0.91 | T 0.89 |
| b02 framework-integrity (P, confidence 0.82) | **T 0.87** | **T 0.90** |
| b03 consumer-repo-integration (P, 0.85) | **T 0.29** | **T 0.31** |
| b04 cross-reference-integrity (P) | P 0.87 | P 0.90 |
| b05 schema-conformance (T) | T 0.99 | T 0.99 |
| b06 afk-backend-adapter (T) | T 0.98 | T 0.97 |
| b07 confidence-calibration (P) | U 0.82 | U 0.83 |
| b08 remediation-effectiveness (P) | P 0.64 | P 0.65 |

**Verdict: FAIL** — no F, D or C on any real belief (that half passes), but two
beliefs recorded P were answered T in both orders.

Explanation (post hoc, so it changes no verdict): b02's evidence is three
supporting records at reliability 0.95–0.99 and an empty `contradicting` list.
Demerzel keeps it at P because its recorded confidence, 0.82, sits under the
T threshold of its own confidence ladder (`logic/confidence-thresholds.yaml`),
not because the evidence leans only partly. Jev sees the evidence, not the
ladder, and says T. b03's T carries 0.29 confidence — no decision at all.
In Demerzel, the step from P to T is a threshold, not a label a model can
read off the evidence. Side finding: b02's third claim contains mojibake
(`â€”` for an em dash) in the published file.

Consequence: the conflict sentence is not proposed on this evidence alone.
What the four runs support is a division of labour, not a new definition: a
deterministic existence check decides U against F/D, Demerzel's confidence
ladder decides T against P, and a model's label is advice between them.
