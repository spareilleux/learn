---
title: Journal
description: 'Dated progress notes for the Speaking in knots course — the French deck and its English copy, a Python state sum checked against the values IX''s tests assert, six deliberate mistakes it catches, the Knot Atlas printing the trefoil''s mirror image, what an independent review found, and replay blocks that let a person or an agent rerun each entry and check it.'
sidebar:
  order: 99
---

:::note[Replaying an entry]
Each dated entry ends with **Replay** blocks: where to run, the exact command, its input, the output to expect, and the check that decides. A person or an agent can rerun them and say whether the entry still holds. A block that was not run on the author's machine says so.
:::

## Progress

- [x] The French deck, *Parler en nœuds*, and its English copy, *Speaking in Knots*, 52 slides each
- [x] `check.sh`: the state sum against the 26 values IX's tests assert on words of up to 6 crossings, the braid words the lessons quote, and the mutation check
- [x] Lesson 1: braid words and the Jones polynomial
- [x] French and Spanish translations
- [x] An independent review of the course against IX's source, and its seven blocking findings fixed
- [ ] A CI workflow that runs `check.sh` on Windows, Linux and macOS
- [ ] Lesson 2: the Gauss code (waits for IX's Gauss code to be pushed)
- [ ] Lesson 3: what IX refuses, and why
- [ ] Lesson 4: sailors' knots in 3D (waits for IX's laid-down rope to be pushed)

## Experiments

Each hypothesis below was written before the measurement, in [`preregistration.md`](https://github.com/spareilleux/learn/blob/main/code/speaking-in-knots/preregistration.md). It was committed unchanged, in the same commit as the results, so the history cannot show that it came first: that rests on the author's word. Where no hypothesis was written, the row says so.

| Question | Hypothesis | Result | Verdict | Where |
|---|---|---|---|---|
| Does a state sum computed outside IX give the values IX's tests assert at `e8684cf`? | Yes: every asserted Jones polynomial, written identically in IX's text format, and the asserted components and writhe. | 26 of 26 checks agree: every Jones polynomial, number of components, writhe, permutation and symmetry that IX's tests assert on words of up to 6 crossings. The first run checked 19 of them and called that every value; the review of 2026-10-06 found the other 7. The hypothesis also called the script independent: it follows the construction of the `state_sum` helper already in IX's tests, so the agreement shows that the values can be reproduced outside IX, not that they were derived independently. | Confirmed | [2026-10-05](#2026-10-05--the-two-decks-and-the-jones-polynomial-checked-three-ways) · [2026-10-06](#2026-10-06--what-an-independent-review-found) · [`jones_state_sum.py`](https://github.com/spareilleux/learn/blob/main/code/speaking-in-knots/jones_state_sum.py) |
| Does the Knot Atlas print, for the trefoil, the polynomial of IX's `s1^3`? | No: it prints the mirror polynomial, −q⁻⁴ + q⁻³ + q⁻¹. | 3_1 prints `- q^{-4} + q^{-3} + q^{-1}`, the polynomial of `s1^-3`. L2a1 does the same for the Hopf link; 4_1 and L6a4 match IX exactly. The reason the hypothesis gave, that the Atlas draws the left-handed trefoil, was not checked separately. | Confirmed | [2026-10-05](#2026-10-05--the-two-decks-and-the-jones-polynomial-checked-three-ways) |
| Does the first check catch deliberate mistakes in the script? | None written in advance. | 6 of 6 mutants make it fail; each still agrees with IX on 16 to 23 of the 26 checks. | No verdict: no hypothesis recorded | [2026-10-05](#2026-10-05--the-two-decks-and-the-jones-polynomial-checked-three-ways) · [`mutants.py`](https://github.com/spareilleux/learn/blob/main/code/speaking-in-knots/mutants.py) |

## 2026-10-05 — The two decks, and the Jones polynomial checked three ways

**The decks.** The French deck, *Parler en nœuds*, was built while IX learned to read, check and draw knots. The English copy follows it slide for slide, from its version `1791174928-7d71`: a later change to the French deck is not carried over by itself. The layout was compared mechanically, slide by slide: the same tags and the same attributes, with only the text, the images' alternative text and the section labels differing, and every image points to a copy kept in the English deck.

**What can be checked.** Of what the deck shows, only braid words, the Jones polynomial and a 3D layout of the strands are in IX's pushed code, in [pull request #366](https://github.com/GuitarAlchemist/ix/pull/366) at commit `e8684cf`. Its CI run [37216487957](https://github.com/GuitarAlchemist/ix/actions/runs/37216487957) passed the build-and-test job on Ubuntu and Windows, with stable and nightly Rust. Its risk report fails, and the pull request waits for a human review. The rest (Gauss code, `.knot` files, laid-down rope, the 3D loop) is on local branches that are not pushed, and this entry does not check it.

**A state sum against IX's tests.** Before writing any code, I wrote down the hypothesis in [`preregistration.md`](https://github.com/spareilleux/learn/blob/main/code/speaking-in-knots/preregistration.md). Then [`jones_state_sum.py`](https://github.com/spareilleux/learn/blob/main/code/speaking-in-knots/jones_state_sum.py) recomputed 19 values that IX's tests assert, and all 19 agreed; the next entry adds the 7 it missed. The preregistration calls the script independent and written from the textbook definition. That overstates it: its construction (a union-find over the closed diagram, one node per level and position) is the one of the `state_sum` helper in IX's own tests, and those tests already compare it with IX's Temperley–Lieb evaluation on 150 words. What the agreement adds is that the values can be checked without Rust or IX's repository. The independent check is the next one.

**The Knot Atlas.** The trefoil's page, 3_1, prints the polynomial of `s1^-3`, as the second hypothesis predicted, and the Hopf link's, L2a1, that of `s1^-2`. The figure-eight knot (4_1) and the Borromean rings (L6a4), each its own mirror image, match IX's polynomials exactly. A table and IX may draw opposite mirror images under the same name; [lesson 1](../01-braid-words/) makes the reader check both.

**Six mutants.** [`mutants.py`](https://github.com/spareilleux/learn/blob/main/code/speaking-in-knots/mutants.py) changes one line of the script at a time and requires the first check to fail. All six fail it. None of them breaks everything: each mutant still agrees with IX on most of the checks, which is why the check compares all of them rather than a few.

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

- Check: with *q* read as *t*, 3_1 is the `s1^-3` line of `expected/oracle.txt` and L2a1 is `expected/hopf-mirror.txt`; 4_1 is the `s1 s2^-1 s1 s2^-1` line and L6a4 the `s1 s2^-1 s1 s2^-1 s1 s2^-1` line. A wiki page can change: a different output means comparing again, not that IX is wrong.

## 2026-10-06 — What an independent review found

Before merging, a reviewer who had no part in writing the course read the pull request against IX's source at `e8684cf`. It reported seven blocking problems. Each was checked against the source before being fixed:

- **The reading direction was the mirror one.** Lesson 1 laid the strands out top to bottom. IX lays a braid out with *y* running up, and [`layout.rs`](https://github.com/GuitarAlchemist/ix/blob/e8684cf/crates/ix-knot/src/layout.rs#L26-L39) says that a picture with *y* running down shows the mirror braid: a reader who drew `s1^3` as the lesson said got the left-handed trefoil, where IX computes the right-handed one. The lesson now reads braids from bottom to top, and says why.
- **"Every value IX's tests assert" was 19 values.** The script missed the figure-eight's symmetry, the writhe of a mirror braid, the three identities of the reef and granny test, and the writhe and permutation asserted by the `ix_braid` tool's tests. It now checks all 26, still in agreement, and names the two tests out of its reach (63 and 64 crossings, and IX's own 150 generated words).
- **IX's pushed code also has a 3D layout** of the strands, `layout.rs`, which the previous entry left out.
- **The commands differ between Windows and the other systems** (`python` against `python3`): the lesson is now an `.mdx` page with one tab per system, as AGENTS.md asks.
- **Python and Rust** are now linked at their first mention in the lesson.
- **Linux and macOS were never run**, which is now said under *To verify*.
- **The English deck was private** when the review read it, while the French one was already shared with anyone who has the link. The course is not merged before both are.

The review also noted that the French deck has changed since the copy was made: version `1791213311-03e2` on 2026-10-06, against `1791174928-7d71` for the copy's source. The English copy does not follow it.

**Replay 4: the 26 checks.** Run on the author's machine: Windows 11, Git Bash, Python 3.14.3.

- Where: the root of a clone of [spareilleux/learn](https://github.com/spareilleux/learn), at the commit that adds this entry or later.
- Input: none.
- Command:

  ```bash
  bash code/speaking-in-knots/check.sh > /dev/null && tail -2 code/speaking-in-knots/out/oracle.txt
  ```

- Expected output:

  ```text
  26/26 agree with IX at e8684cf
  exit 0
  ```

- Check: exactly these two lines. `exit 0` is the script's own status, which `check.sh` appends to its output.

## To verify

- `check.sh` on Linux and macOS: it was only run on Windows 11.
- Replay 2 on the author's machine: the course only relies on IX's CI for it.
- Whether the Knot Atlas draws the left-handed trefoil under 3_1, the reason the second hypothesis gave; only the polynomial was compared.
- Pull request #366 is still open: the links to IX point to commit `e8684cf`, and stay valid after a merge, but the code may change before then.
- The figures of the deck's 3D part come from local IX commits that are not pushed; the course does not reproduce them.
- The French deck has moved on since the English copy was made; whether the copy should follow it.

## Open questions

- Should IX's documentation say which mirror image each named knot is, so that comparing with a table does not need both?
- Should a CI workflow run `check.sh` on three OSes, as the other courses' workflows do? Adding one touches `.github/`, which is for the repository's owner to review.
