---
title: Journal
description: 'Dated progress notes for the Speaking in knots course — the French deck and its English copy, a Python state sum checked against every value IX''s tests assert, six deliberate mistakes it catches, the Knot Atlas printing the trefoil''s mirror image, and replay blocks that let a person or an agent rerun each entry and check it.'
sidebar:
  order: 99
---

:::note[Replaying an entry]
Each dated entry ends with **Replay** blocks: where to run, the exact command, its input, the output to expect, and the check that decides. A person or an agent can rerun them and say whether the entry still holds. A block that was not run on the author's machine says so.
:::

## Progress

- [x] The French deck, *Parler en nœuds*, and its English copy, *Speaking in Knots*, 52 slides each
- [x] `check.sh`: the state sum against the 19 values IX's tests assert, the braid words the lessons quote, and the mutation check
- [x] Lesson 1: braid words and the Jones polynomial
- [x] French and Spanish translations
- [ ] A CI workflow that runs `check.sh` on Windows, Linux and macOS
- [ ] Lesson 2: the Gauss code (waits for IX's Gauss code to be pushed)
- [ ] Lesson 3: what IX refuses, and why
- [ ] Lesson 4: sailors' knots in 3D (waits for IX's laid-down rope to be pushed)

## Experiments

Each hypothesis below was written before the measurement, in [`preregistration.md`](https://github.com/spareilleux/learn/blob/main/code/speaking-in-knots/preregistration.md), committed unchanged with the results. Where none was written, the row says so.

| Question | Hypothesis | Result | Verdict | Where |
|---|---|---|---|---|
| Does a state sum computed outside IX give every value IX's tests assert at `e8684cf`? | Yes: every asserted Jones polynomial, written identically in IX's text format, and the asserted components and writhe. | 19 of 19 checks agree. The hypothesis called the script independent: it follows the construction of the `state_sum` helper already in IX's tests, so the agreement shows that the values can be reproduced outside IX, not that they were derived independently. | Confirmed | [2026-10-05](#2026-10-05--the-two-decks-and-the-jones-polynomial-checked-three-ways) · [`jones_state_sum.py`](https://github.com/spareilleux/learn/blob/main/code/speaking-in-knots/jones_state_sum.py) |
| Does the Knot Atlas print, for the trefoil, the polynomial of IX's `s1^3`? | No: it prints the mirror polynomial, −q⁻⁴ + q⁻³ + q⁻¹. | 3_1 prints `- q^{-4} + q^{-3} + q^{-1}`, the polynomial of `s1^-3`. L2a1 does the same for the Hopf link; 4_1 and L6a4 match IX exactly. The reason the hypothesis gave, that the Atlas draws the left-handed trefoil, was not checked separately. | Confirmed | [2026-10-05](#2026-10-05--the-two-decks-and-the-jones-polynomial-checked-three-ways) |
| Does the first check catch deliberate mistakes in the script? | None written in advance. | 6 of 6 mutants make it fail; each still agrees with IX on 12 to 16 of the 19 checks. | No verdict: no hypothesis recorded | [2026-10-05](#2026-10-05--the-two-decks-and-the-jones-polynomial-checked-three-ways) · [`mutants.py`](https://github.com/spareilleux/learn/blob/main/code/speaking-in-knots/mutants.py) |

## 2026-10-05 — The two decks, and the Jones polynomial checked three ways

**The decks.** The French deck, *Parler en nœuds*, was built while IX learned to read, check and draw knots. The English copy follows it slide for slide, from its version `1791174928-7d71`: a later change to the French deck is not carried over by itself. The layout was compared mechanically, slide by slide: the same tags and the same attributes, with only the text, the images' alternative text and the section labels differing, and every image points to a copy kept in the English deck.

**What can be checked.** Only braid words and the Jones polynomial are in IX's pushed code, in [pull request #366](https://github.com/GuitarAlchemist/ix/pull/366) at commit `e8684cf`. Its CI run [37216487957](https://github.com/GuitarAlchemist/ix/actions/runs/37216487957) passed the build-and-test job on Ubuntu and Windows, with stable and nightly Rust. The risk report fails on it: that check fails closed on pull requests that touch protected paths, and the pull request waits for a human review. The rest of what the deck shows (Gauss code, `.knot` files, laid-down rope, the 3D loop) is on local branches that are not pushed, and this entry does not check it.

**A state sum against IX's tests.** Before writing any code, I wrote down the hypothesis in [`preregistration.md`](https://github.com/spareilleux/learn/blob/main/code/speaking-in-knots/preregistration.md). Then [`jones_state_sum.py`](https://github.com/spareilleux/learn/blob/main/code/speaking-in-knots/jones_state_sum.py) recomputed every value IX's tests assert: 19 of 19 agree. The preregistration calls the script independent and written from the textbook definition. That overstates it: its construction (a union-find over the closed diagram, one node per level and position) is the one of the `state_sum` helper in IX's own tests, and those tests already compare it with IX's Temperley–Lieb evaluation on 150 words. What the agreement adds is that the values can be checked without Rust or IX's repository. The independent check is the next one.

**The Knot Atlas.** The trefoil's page, 3_1, prints the polynomial of `s1^-3`, as the second hypothesis predicted, and the Hopf link's, L2a1, that of `s1^-2`. The figure-eight knot (4_1) and the Borromean rings (L6a4), each its own mirror image, match IX's polynomials exactly. A table and IX may draw opposite mirror images under the same name; [lesson 1](../01-braid-words/) makes the reader check both.

**Six mutants.** [`mutants.py`](https://github.com/spareilleux/learn/blob/main/code/speaking-in-knots/mutants.py) changes one line of the script at a time and requires the first check to fail. All six fail it. None of them breaks everything: each mutant still agrees with IX on 12 to 16 of the 19 checks, which is why the check compares all 19 rather than a few.

**Replay 1: the course's check.** Run on the author's machine: Windows 11, Git Bash, Python 3.14.3.

- Where: the root of a clone of [spareilleux/learn](https://github.com/spareilleux/learn), at the commit that adds this entry or later.
- Input: none. Python 3, standard library only; `PYTHON=…` picks another interpreter.
- Command:

  ```bash
  bash code/speaking-in-knots/check.sh
  ```

- Expected output, the first line being your Python version:

  ```text
  Python 3.14.3
  ok   oracle
  ok   unknot-s1-s2
  ok   hopf
  ok   hopf-mirror
  ok   trefoil
  ok   borromean
  ok   torus-3-3
  ok   plait-6
  ok   mutants
  ```

- Check: exit status 0, and every line after the first starts with `ok`. A `FAIL` line follows the diff between the output and the file in `expected/`.

**Replay 2: IX's own tests at the pinned commit.** Not run on the author's machine; run by IX's CI.

- Where: a clone of [GuitarAlchemist/ix](https://github.com/GuitarAlchemist/ix), with a Rust toolchain.
- Input: none.
- Command:

  ```bash
  git fetch origin pull/366/head
  git checkout e8684cf
  cargo test -p ix-knot
  ```

- Expected output: among the passing tests, `jones::tests::known_knots_and_links`, `jones::tests::the_reef_knot_is_symmetric_and_the_granny_is_not` and `jones::tests::the_algebra_agrees_with_the_state_sum_and_the_markov_moves`, then `test result: ok`. The number of tests is not recorded here.
- Check: exit status 0. For comparison, CI run 37216487957 ran `cargo test --workspace` and passed.

**Replay 3: the Knot Atlas.** Run on the author's machine on 2026-10-05; it needs the network.

- Where: anywhere, with `bash`, `curl` and `grep`.
- Input: the four pages 3_1, L2a1, 4_1 and L6a4 of [katlas.org](https://katlas.org/).
- Command:

  ```bash
  for k in 3_1 L2a1 4_1 L6a4; do
    printf '%s: ' "$k"
    curl -s -A "streeling-review/1.0" "https://katlas.org/wiki/$k" | grep -A3 'Jones polynomial' | grep -o 'displaystyle{.*}\[/math\]' | head -1
  done
  ```

- Expected output:

  ```text
  3_1: displaystyle{ - q^{-4} + q^{-3} + q^{-1}  }[/math]
  L2a1: displaystyle{ -\frac{1}{\sqrt{q}}-\frac{1}{q^{5/2}} }[/math]
  4_1: displaystyle{ q^2+ q^{-2} -q- q^{-1} +1 }[/math]
  L6a4: displaystyle{ -q^3- q^{-3} +3 q^2+3 q^{-2} -2 q-2 q^{-1} +4 }[/math]
  ```

- Check: with *q* read as *t*, 3_1 is the `s1^-3` line of Replay 1's `oracle` output and L2a1 is `expected/hopf-mirror.txt`; 4_1 is the `s1 s2^-1 s1 s2^-1` line and L6a4 the `s1 s2^-1 s1 s2^-1 s1 s2^-1` line. A wiki page can change: a different output means comparing again, not that IX is wrong.

## To verify

- Replay 2 on the author's machine: the course only relies on IX's CI for it.
- Whether the Knot Atlas draws the left-handed trefoil under 3_1, the reason the second hypothesis gave; only the polynomial was compared.
- Pull request #366 is still open: the links to IX point to commit `e8684cf`, and stay valid after a merge, but the code may change before then.
- The figures of the deck's 3D part come from local IX commits that are not pushed; the course does not reproduce them.

## Open questions

- Should IX's documentation say which mirror image each named knot is, so that comparing with a table does not need both?
- Should a CI workflow run `check.sh` on three OSes, as the other courses' workflows do? Adding one touches `.github/`, which is for the repository's owner to review.
