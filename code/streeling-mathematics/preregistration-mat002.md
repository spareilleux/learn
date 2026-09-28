# MAT-002 lab — pre-registration

Written on 2026-09-28, before any code of this part of the lab was compiled or run. Its SHA-256 is recorded in the Learn progress receipt at the moment of writing. A later edit would be a new file with its own date, not a silent correction.

## Where the predictions come from

Most predictions below are those of **§7 "Proposed Experiment (Not Yet Run)"** of the Streeling module MAT-002, *Counterexamples, Witnesses and Exhaustive Checks*, together with two readings, one in §4 and one in §6. They were published before this lab existed, in [Demerzel `a3a07df`](https://github.com/GuitarAlchemist/Demerzel/blob/a3a07df103c1f13a4dec45514fe775bfd4f76e77/state/streeling/courses/mathematics/en/mat-002-counterexamples-and-exhaustive-checks.md), and the file is unchanged on Demerzel's `master` at the time of writing (same blob, `54a76ad`). They are quoted here without change.

This file adds:
- how each prediction is judged;
- one hypothesis of the lab's own, **M2-L1**, marked as such;
- what the lab does not cover.

## What is measured

- **Libraries under test:** IX `ix-bracelet` and `ix-petri`, pinned at `e35138b9d4c707d48f802649a7fcb3f7fc94934d`, the same commit as the module and the other labs.
- **Anchors at the pin:**

  | Anchor | What it is |
  |---|---|
  | `ix-bracelet/src/dihedral.rs:66` `compose` | (i, a) · (k, b) = (i + σ(a) · k mod 12, a ⊕ b) |
  | `dihedral.rs:78` `inverse` | a reflection is its own inverse; (i, 0)⁻¹ = (12 − i mod 12, 0) |
  | `dihedral.rs:137` `group_law_exhaustive_closure_and_inverse` | IX's first test |
  | `ix-bracelet/src/action.rs:40` `apply` | reflect the set if a = 1, then rotate it by i |
  | `action.rs:70` `sample_sets`, `:135` `action_composition_matches_group_composition` | IX's second test, on nine sample sets |
  | `ix-petri/src/analysis.rs:436` `analyze`, `:809` `witness_sequences_are_shortest_and_replayable` | the analyser and the net of its witness test |

- **Elements:** the 24 elements (i, a) of D12, listed as in IX's tests: a = 0 first, then a = 1, each with i from 0 to 11.
- **Product rules:**
  - **IX:** IX's `compose`.
  - **Rule S** (§4 exercise): the sign comes from the second factor, (i, a) · (k, b) = (i + σ(b) · k mod 12, a ⊕ b).
  - **Rule F** (§6 exercise): IX's `compose`, except that (1, 1) · (2, 1) returns (5, 0) instead of (11, 0).
  - **Rule Z** (§4 reading): no sign flip, (i, a) · (k, b) = (i + k mod 12, a ⊕ b).

## Predictions, quoted from the module, and how they are judged

**Step 1, associativity, exhaustively.**
- **M2-P1.** "Check (g · h) · f = g · (h · f) with IX's `compose` for all 13,824 triples and count the failures. Prediction: none."
  - Judged as a count of 0 over 13,824 triples.

**Step 2, negative controls.**
- **M2-P2.** "Run the same checker on the faulty rule of the §4 exercise and on the one-entry fault of the §6 exercise. Prediction: at least one failing triple for each, including the two triples found by hand above."
  - The triples found by hand are ((0, 0), (1, 0), (0, 1)) for rule S and ((1, 0), (0, 1), (2, 1)) for rule F.
  - Judged: the count of failures is ≥ 1 for each rule, and each hand-found triple is among the failures of its rule.
  - The counts are printed. No prediction is made for them.

**Step 3, what IX's tests detect.** The assertions of IX's two tests are restated as checks of a product rule, with IX's `inverse` and IX's `apply` unchanged:
- **Check A** (`group_law_exhaustive_closure_and_inverse`). For each of the 24 elements g, in the order above:
  - g · g⁻¹ = e;
  - g⁻¹ · g = e;
  - e · g = g;
  - g · e = g.
  
  Then, for each of the 576 pairs, the rotation of g · h is below 12. Finally, the 576 products include all 24 elements.
- **Check B** (`action_composition_matches_group_composition`). For each of the 576 pairs and each of the nine sample sets x of `action.rs:70`: (g · h).apply(x) = g.apply(h.apply(x)).
- **M2-P3.** "IX's `compose` passes both; the one-entry fault passes the first and fails the second; the rule of the §4 exercise fails both, the first one already at e · g = g, since e · (1, 1) = (0 − 1, 1) = (11, 1)."
  - Judged: IX passes A and B; rule F passes A and fails B; rule S fails A and B.
  - For rule S, the first assertion of A that fails, in the order of the test, is e · g = g at g = (1, 1), and the product it returns is (11, 1).

**Step 4, replaying a witness.**
- **M2-P4.** "Build the net of `witness_sequences_are_shortest_and_replayable`, run `analyze` with the default limits, and replay the reported witness with `fire`. Prediction: deadlock freedom is `Fails`, the witness is `a_short`, and the replay reaches the reported dead marking."
  - The net is built with the same builder calls, in the same order, as the test.
  - Judged:
    - `deadlock_free` is `Verdict::Fails`;
    - the first reported deadlock has the witness `["a_short"]`;
    - `describe_marking` of the replayed marking equals the reported `marking`.

**Two readings.**
- **M2-P5 (§6).** "One sample set, the C major triad {0, 4, 7}, is sent by the 24 elements to 24 different sets: the 12 major and the 12 minor triads."
  - Judged:
    - the 24 images of {0, 4, 7} under IX's `apply` are distinct;
    - the 12 images by a = 0 are the transpositions of {0, 4, 7};
    - the 12 images by a = 1 are the transpositions of {0, 3, 7}.
- **M2-P6 (§4).** "Drop the sign flip … and the product is still associative … An associativity check cannot see the missing sign. A check of the relation 'reflection, then rotation, then reflection gives the inverse rotation' can."
  - Judged: rule Z has 0 associativity failures over the 13,824 triples.
  - With s = (0, 1) and r = (1, 0), (s · r) · s is (1, 0) under rule Z instead of r⁻¹ = (11, 0), and IX's `compose` gives (11, 0).

## A hypothesis of the lab's own

**M2-L1.** This hypothesis is not in the module. It is derived here by hand, before any run.

Rule F differs from IX only on the pair ((1, 1), (2, 1)), where it returns (5, 0) instead of (11, 0). The two rotations differ by 6. So check B sees the difference only on the sample sets that rotation by 6 does not fix. Of the nine sets, four are fixed by it:
- the empty set;
- the chromatic set;
- the whole-tone scale {0, 2, 4, 6, 8, 10};
- the tritone {0, 6}.

Prediction: check B fails on exactly 5 of the 5,184 (pair, set) combinations. All five are on the pair ((1, 1), (2, 1)), with the sets {0, 4, 7}, {0, 3, 7}, the C major scale, {0, 1, 4, 6} and {0}.

## Negative controls

The known-faulty rules S and F are themselves the controls of step 2, as the module intends. In addition:
- **The associativity checker** counts exactly the failures of a rule whose failures are known in closed form: (i, a) · (k, b) = (i − k mod 12, a ⊕ b). For it, (g · h) · f has the rotation i − k − m and g · (h · f) has i − k + m. They differ unless 2m ≡ 0 (mod 12), that is, unless f has the rotation 0 or 6. Four elements out of 24 have such a rotation, so the prediction is 24 · 24 · 20 = 11,520 failures. This shows the checker counts, rather than only detects.
- **Check A** reports a failure for a rule that returns the identity for every product.

## What would not be claimed

- **Not run:** IX's own tests. The restated checks are the lab's code, and they apply IX's `compose`, `inverse` and `apply`.
- **Not checked:** the §6 statement that no Rust file uses `proptest` at the pin. It is about the repository, not about running code.
- Nothing about other groups, other nets, or IX commits other than `e35138b9`.
- **Platforms.** The expected file is produced on Windows x86-64. CI runs `check.sh` on Linux, Windows and macOS: a diff there would be a measured cross-platform difference.
- **A refuted prediction is a result.** It is recorded in the test and the README, not tuned away.
