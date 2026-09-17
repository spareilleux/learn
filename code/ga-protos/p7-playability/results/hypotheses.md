# P7 playability model: hypotheses, written before the measurements

Written on 2026-09-17 at 20:10 (UTC-4), committed before `scripts/train.mjs` has been run on any dataset —
synthetic or real — and before `scripts/build-dataset.mjs` has ever opened GA's index.

## What is being predicted, and what it is worth

There is no ready-made label for "how hard is this voicing to play". This prototype builds one and says what it
is worth rather than pretending it is truth.

- **The target** is the cost of the *best* left-hand fingering of a voicing, found by the search in
  `src/lib/fingering.mjs`: every legal way of putting fingers 1 to 4 (and a barre) on the fretted notes, scored
  against an explicit hand model, cheapest wins. The geometry is GA's own (equal temperament, 648 mm scale,
  43/52 mm nut and bridge); every weight is a constant I chose and listed in `WEIGHTS`. It is a *different kind
  of object* from what it is compared against — a combinatorial search over an explicit hand model, not a
  closed-form sum of four flags — but it is still hand-written, and nobody played a note to calibrate it.
- **The reference to beat** is GA's `VoicingPhysicalAnalyzer.CalculatePlayability` difficulty score, ported line
  for line in `src/lib/ga-cost.mjs` from GuitarAlchemist/ga@66bdd049.
- **A third opinion**, `src/lib/rules.mjs`, is a checklist of the rules method books state in words. Nothing is
  trained on it; it exists only to see whether the other two agree with something neither of them is.
- **An external check**, `results/annotations.json`: 32 pairwise judgements on canonical shapes. The annotator is
  the language model that wrote this prototype, not a guitarist, and the file says so with its protocol.

## H0 — the annotation check (seen, not blind)

`scripts/check-annotations.mjs` was run before this file was written, so these three numbers are **not
predictions**, they are already measured and are recorded here for honesty:

| cost | high-confidence pairs (25) | all pairs (32) |
|---|---|---|
| fingering search (the target) | 1.000 | 0.9375 |
| GA's hand-written score | 0.880 | 0.7813 |
| rule checklist | 0.760 | 0.6875 |

The target's perfect score on the high-confidence pairs is **not evidence that it is right**: the same head wrote
the hand model and the annotation protocol, from the same written rules, so the agreement measures internal
consistency. The interesting line of that table is GA's, which was written by someone else.

## Blind predictions

Everything below is about a run on a seeded sample of GA's guitar voicings, split by chord (pitch-class set),
trained on the CPU of a single desktop machine, with no GPU anywhere.

- **H1.** Over the whole sample, Spearman between GA's score and the target is between 0.55 and 0.80.
- **H2.** GA's score cannot tell apart two voicings of the same chord in more than 25 % of within-chord pairs
  (an exact tie), against less than 5 % for the target.
- **H3.** Split by chord, on the test rows: gradient boosting reaches Spearman ≥ 0.93, ridge lands between 0.80
  and 0.92, GA's score stays below 0.80.
- **H4.** Every trained model — ridge, random forest, gradient boosting, MLP — beats GA's score on the chord
  split by at least 0.10 of Spearman.
- **H5.** Pairwise accuracy across chords ("which of these two is harder?"): gradient boosting ≥ 0.92, GA's score
  ≤ 0.82, the mean baseline exactly 0.50.
- **H6 (leakage).** For gradient boosting, Spearman on the naive split by voicing is higher than on the split by
  chord by between 0.005 and 0.05, and the split by transposition-invariant shape is lower than the split by
  chord by between 0.01 and 0.08. For GA's score, which is not trained, the three numbers differ by less
  than 0.02.
- **H7 (time).** The published experiment — building the dataset from the index, then three splits and six
  predictors each — takes under 30 minutes of CPU in total, and gradient boosting alone trains in under
  5 minutes.
- **H8 (size).** The boosted trees serialise to under 1.5 MB of JSON, the MLP to under 25 KB, ridge to
  under 1.5 KB.
- **H9 (what it learns).** The three features holding the largest share of the boosting gain are all geometry of
  the shape (`physicalSpanMm`, `diagonalMm`, `fingerSpreadMm`, `maxAtMinFret` in some order), and
  `barreAdjacent3` — the only barre signal GA has — holds less than 0.10 of the gain.
- **H10 (disagreement).** At least one test voicing sits above GA's 90th percentile and below the model's 50th,
  and it is a voicing with no open string and a small stretch: GA's flat "+1 when nothing is open" is the term I
  expect the model to overrule most often.
- **H11.** Fewer than 2 % of the guitar voicings in GA's index have no legal fingering at all under the search.
- **H12 (why bother).** At prediction time the boosted trees score a voicing at least 50 times faster than the
  search finds its best fingering.

## What would make these wrong in an interesting way

H3 and H4 are close to tautologies — a model trained on the target should beat a formula that was never fitted
to it. The question they actually answer is *how much* structure GA's four terms leave on the table. H6 and H10
are the ones that can embarrass the prototype: if the leakage gap is zero, the classic warning about splitting by
voicing does not apply here and the lesson has to say so; if the model and GA never disagree in an explainable
way, there is nothing to learn from the model beyond a curve fit.
