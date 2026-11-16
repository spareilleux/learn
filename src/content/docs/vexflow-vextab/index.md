---
title: VexTab & VexFlow — Mission
description: Guitar notation and tablature in the browser for developers who know C# or Java — VexTab, a small text language, and VexFlow, the JavaScript library that draws it, with every example rendered to SVG and compared in CI on Windows, Linux and macOS, and Guitar Alchemist's own VexTab code put to the test.
sidebar:
  label: Mission
  order: 0
---

:::note[Versions studied]
[VexTab](https://github.com/0xfe/vextab) **4.0.5**, published on npm on 2026-01-18 and built from commit [`3a5e00d`](https://github.com/0xfe/vextab/tree/3a5e00d858ae98934ba545f9bef5eb923e17e402) of `0xfe/vextab`, and the [VexFlow](https://www.vexflow.com/) **5.0.0** it bundles, built from commit [`0ca6f88`](https://github.com/vexflow/vexflow/tree/0ca6f889545c33cce851b420c24945f6eb685aeb) of `vexflow/vexflow`, on [Node.js](https://nodejs.org/) 24.21.0 with [jsdom](https://github.com/jsdom/jsdom) 30.1.1 and [opentype.js](https://opentype.js.org/) 2.0.0. The course's code is in [`code/vexflow-vextab`](https://github.com/spareilleux/learn/tree/20497783691a7e4f4134be79c5531ea7754934e3/code/vexflow-vextab), with its own `package.json` and lock file that pin those versions exactly. [`.github/workflows/vexflow-vextab-examples.yml`](https://github.com/spareilleux/learn/blob/20497783691a7e4f4134be79c5531ea7754934e3/.github/workflows/vexflow-vextab-examples.yml) runs [`check.sh`](https://github.com/spareilleux/learn/blob/20497783691a7e4f4134be79c5531ea7754934e3/code/vexflow-vextab/check.sh) on Linux, Windows and macOS: it renders every example of the lessons to SVG, keeps every error message VexTab raises, runs lesson 4's texts through Guitar Alchemist's F# parser, and compares all of it with [`expected/`](https://github.com/spareilleux/learn/tree/20497783691a7e4f4134be79c5531ea7754934e3/code/vexflow-vextab/expected).
:::

## Why I'm learning this

[Guitar Alchemist](https://github.com/GuitarAlchemist/ga) (GA) shows guitar voicings, and a voicing is easier to read as tablature than as `x-3-2-0-1-0`. GA's chatbot is asked to attach a fenced `vextab` block to every fingering it mentions; GA has a VexTab grammar in EBNF, a parser and a generator in F#, a React viewer, and end-to-end tests that expect an SVG. I wanted to know what VexTab is, what it can and cannot write, and whether the pieces of GA that speak it agree with the real thing. Lesson 4 answers the last question with measurements, and the answer is mostly no.

## Who this course is for

You write C# or Java. You know the JavaScript of [JavaScript for C#/Java developers](../javascript-for-csharp-java/): modules, npm, functions, objects. A little [React](../react-vite/) helps for the second batch. You can read a guitar tab: six lines, one per string, numbers for frets. The music theory the lessons need, note names, octaves, key signatures, is recalled where it appears, with links to [Music theory for Guitar Alchemist](../music-theory-ga/).

## VexTab and VexFlow in one table

| | What it is | The nearest thing you know |
|---|---|---|
| [VexFlow](https://www.vexflow.com/) | A JavaScript library that draws music notation and tablature, in SVG or on a canvas: staves, notes, beams, ties, bends, text | A drawing API with a layout engine, like WPF's `DrawingContext` plus a formatter |
| [VexTab](https://github.com/0xfe/vextab) | A small text language for notation and tab, and the JavaScript that parses it and calls VexFlow | A DSL compiled to calls on an object API, like a Razor template compiled to C# |
| `tabstave`, `notes`, `text`, `options` | The four kinds of VexTab line | Statements of the DSL |
| The Artist | VexTab's object that turns parsed lines into VexFlow staves and notes | The code generator of a compiler |

## By the end of this course, I will be able to

- write VexTab for melodies, chords and guitar techniques, and read the errors it raises;
- set keys, times, clefs and tunings, and know which of them change the notation and which only the tab;
- render VexTab to SVG under Node, without a browser, and test the output;
- say what VexTab cannot express, and when to drop to VexFlow;
- check a program that writes VexTab, a chatbot or a generator, against the real parser;
- *(second batch)* draw the same music with VexFlow's own objects, render it in React without redrawing on every token, and plan a move from VexFlow 4 to 5.

## Outline

| # | Lesson | You already know |
|---|---|---|
| 1 | [First stave, first tab](01-first-stave/) | a DSL compiled to an API, a parse tree, `System.Xml.Linq` |
| 2 | [Guitar techniques](02-guitar-techniques/) | the tab you read: bends, slides, hammer-ons, chords |
| 3 | [Keys, times, clefs and tunings](03-keys-time-tunings/) | key signatures, capos, drop D |
| 4 | [Case study: GA's chatbot writes VexTab](04-ga-chatbot-vextab/) | FParsec or a parser combinator library, LLM prompts |
| 5 | *Second batch.* `Stave`, `StaveNote`, `Voice`, `Formatter`: what VexTab hides, and a strict voice that counts beats | object construction, a layout pass |
| 6 | *Second batch.* `TabStave` and `TabNote`; keeping notation and tab in step | two views of one model |
| 7 | *Second batch.* Rendering in React without redrawing on every streamed token, and testing it with Playwright (GA's `MemoizedVexTab`) | `memo`, effects, end-to-end tests |
| 8 | *Second batch.* Moving GA's components from VexFlow 4 to 5: what changed in the API, fonts and text measurement | a major-version upgrade |
| — | [Journal](journal/) | |

## Resources

- The [VexTab tutorial](https://vexflow.com/vextab/tutorial.html) by Mohit Cheppudira (0xfe), VexTab's author, and its [README](https://github.com/0xfe/vextab/blob/3a5e00d858ae98934ba545f9bef5eb923e17e402/README.md). The grammar is [`src/vextab.jison`](https://github.com/0xfe/vextab/blob/3a5e00d858ae98934ba545f9bef5eb923e17e402/src/vextab.jison).
- [VexFlow's site](https://www.vexflow.com/), its [repository](https://github.com/vexflow/vexflow/tree/0ca6f889545c33cce851b420c24945f6eb685aeb) and [API reference](https://www.vexflow.com/build/docs/).
- [SMuFL](https://w3c.github.io/smufl/latest/), the standard that numbers music glyphs, and [Bravura](https://github.com/steinbergmedia/bravura), the font VexFlow 5 draws them with.
- [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga), pinned on commit [`17ccee6`](https://github.com/GuitarAlchemist/ga/tree/17ccee6885851e4b460ebd14d7f4cfb838f5541e) for lesson 4.
