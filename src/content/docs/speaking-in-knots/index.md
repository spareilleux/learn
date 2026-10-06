---
title: Speaking in knots — Mission
description: 'Writing knots as text that IX can check — two slide decks first, the French original and its English copy, then braid words, their closures and the Jones polynomial computed by the Kauffman bracket, checked against the values IX''s tests assert and against the Knot Atlas, with a journal whose every entry can be replayed.'
sidebar:
  label: Mission
  order: 0
---

## The two decks

The course starts from a slide deck built while IX learned to read, check and draw knots. It exists in two languages:

- **[Parler en nœuds](https://claude.ai/artifact/7v3cgP2wAARzvxgDgA8iEq)**: the original, in French, 52 slides.
- **[Speaking in Knots](https://claude.ai/artifact/V9yPov2hxYxNWZApXrNxYF)**: its English copy, slide for slide, made from the French deck's version `1791174928-7d71`.

The deck goes through nine parts: why a knot needs a text that IX can check; the four ways to write a knot, with the Gauss code in detail; what IX checks and how it refuses; braid words and the names in the knot table; examples from text to a final render in ComfyUI; sailors' knots in 3D, drawn by hand, checked and given volume by IX, then rendered; what IX draws from knots (tying errors, invention, pipelines, `.knot` files, and Jean-Pierre Petit's comics); the state of the pull requests; and the method, with its adversarial reviews.

:::caution[What the course reproduces, and what it doesn't]
Only part of what the deck shows is in IX's pushed code. Braid words and the Jones polynomial are in [pull request #366](https://github.com/GuitarAlchemist/ix/pull/366), pushed, tested by IX's CI and still open. The Gauss code, the `.knot` language, the laid-down rope and the 3D loop live on local branches that are not pushed yet: their figures come from the deck and the course does not reproduce them. Lesson 1 only teaches what can be checked from pushed code, and the [journal](journal/) says how.
:::

## How this course is tested

The course's code is in [`code/speaking-in-knots`](https://github.com/spareilleux/learn/tree/main/code/speaking-in-knots): a Python script that computes the Jones polynomial of a braid's closure by the Kauffman bracket's state sum, the standard library only. `check.sh` runs it against every value IX's tests assert at commit [`e8684cf`](https://github.com/GuitarAlchemist/ix/tree/e8684cf) (19 checks), runs it on each braid word the lessons quote, runs a mutation check (six deliberate mistakes, each of which must make the first check fail), and compares every output with the files in `expected/`. No CI workflow runs it yet: it was run by hand on Windows 11 with Python 3.14.3. IX's side is tested by IX's own CI.

## Why I'm learning this

A knot drawn on paper is easy to show and hard to check. A knot written as text can be checked by a program: how many strands it has, whether it closes into one loop or several, and whether two texts describe the same knot. IX, the GuitarAlchemist ecosystem's Rust toolbox, learned to do that, and this course follows what it learned, one checkable piece at a time.

## Who this course is for

You write code, and you have never studied knot theory. No mathematics beyond polynomials is needed: the lessons define each object before using it, and every number they quote comes from a run you can repeat. Reading Rust helps to follow IX's code, but isn't required.

## By the end of this course, I will be able to

- write a knot or a link as a braid word, and say what its closure is made of;
- compute a Jones polynomial by the Kauffman bracket, and tell a knot from its mirror image;
- read a knot table, knowing which choices of chirality it makes;
- say what IX checks in a knot's text and when it refuses one;
- replay every entry of the course's journal, and check its result.

## Outline

| # | Lesson | In a developer's terms |
|---|---|---|
| 1 | [Braid words and the Jones polynomial](01-braid-words/) | a parser, a permutation, and a sum over 2^n cases |
| 2 | The Gauss code: a knot as the list of its crossings | a serialization format with a validator |
| 3 | What IX refuses, and why | typed errors |
| 4 | Sailors' knots in 3D: from a drawing to a checked tube | a geometry pipeline with checks at each stage |
| — | [Journal](journal/) | |

Lessons 2 to 4 are the plan: each waits for the IX code it teaches to be pushed.

## Resources

- IX, [pull request #366](https://github.com/GuitarAlchemist/ix/pull/366): the `ix-knot` crate and the `knot.braid` skill, at commit [`e8684cf`](https://github.com/GuitarAlchemist/ix/tree/e8684cf).
- [The Knot Atlas](https://katlas.org/), the knot table the course compares with.
- J. W. Alexander, "A lemma on systems of knotted curves", *Proceedings of the National Academy of Sciences* 9 (1923), 93–95: every knot and link is the closure of a braid.
- L. H. Kauffman, "State models and the Jones polynomial", *Topology* 26 (1987), 395–407: the bracket the lesson computes.
