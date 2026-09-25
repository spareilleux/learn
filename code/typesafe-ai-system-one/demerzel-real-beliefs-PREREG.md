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
