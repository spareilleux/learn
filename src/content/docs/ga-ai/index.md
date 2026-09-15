---
title: "GA's AI: OPTIC-K, ML, agents and the chatbot — Mission"
description: The machine learning and agent side of Guitar Alchemist for C# developers — the OPTIC-K embedding, the voicing index and its search, the chatbot's routing and agents, and what the chatbot is meant to become, each part run offline against GA's own code.
sidebar:
  label: Mission
  order: 0
---

:::note[How this course is tested]
Every table of output in the lessons comes from [`code/ga-ai`](https://github.com/spareilleux/learn/tree/main/code/ga-ai), a .NET 10 console program that references three of Guitar Alchemist's projects directly: `GA.Business.ML`, the command-line tool that writes the voicing index, and the chatbot host `GaChatbot.Api`. GA is cloned at commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6). The program needs no API key, no GPU and no model server: it builds a small index itself, and starts the chatbot in its own process with the model's address pointing to a closed port. [`.github/workflows/ga-ai-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/ga-ai-examples.yml) runs it on Linux, Windows and macOS and compares each lesson's output with the files in `expected/`. The outputs were captured in September 2026.
:::

## Why I'm learning this

[Guitar Alchemist](https://github.com/GuitarAlchemist/ga) (GA) has a chatbot for guitarists. Behind it sit a 240-number description of every guitar chord shape, called OPTIC-K, an index of 313,047 of those descriptions, a router that decides which piece of code answers a question, and a handful of agents that call a language model. The documentation around it is large and partly out of date, and the code moves every week.

I want to know what actually happens: which numbers a chord gets, why two chords come out as similar, what the index file contains, and what the chatbot does with a question when no model is reachable. The way to find out is to call GA's own classes from a program, print what they return, and compare it with what the comments and the documents say. Where the two disagree, the difference goes into the [journal](journal/).

## Who this course is for

You write C#. You know `float[]`, LINQ, dependency injection and ASP.NET Core well enough to read a `Program.cs`. You don't need any machine learning: the course uses three ideas, each explained where it first appears.

1. **An embedding** is a fixed-length array of numbers that describes an object, so that similar objects get similar arrays.
2. **Cosine similarity** measures how much two such arrays point the same way: 1 for the same direction, 0 for nothing in common.
3. **Nearest-neighbour search** returns the stored arrays closest to a query array.

Three other courses on this site cover the background, and this one links to them instead of repeating them:

- [Music theory for Guitar Alchemist](../music-theory-ga/): pitch classes, voicings, interval-class vectors and set classes, the vocabulary OPTIC-K encodes;
- [Machine learning, as applied in IX](../machine-learning-ix/): features, distances, nearest neighbours and clustering, written by hand;
- [Agentic coding with Claude Code and Codex](../agentic-coding/): the tool loop, hooks, skills and MCP servers, from the side of a developer who uses agents.

## By the end of this course, I will be able to

- draw GA's AI stack: which project computes embeddings, which writes the index, which routes a chat message, and what ix, Demerzel and TARS do around it;
- read an OPTIC-K vector partition by partition, compute the weighted similarity of two voicings by hand, and say what the vector is and isn't invariant to;
- open an OPTK index file, explain its header, and predict what a search returns and why;
- follow a chat message through GA's hooks, deterministic guards, intent router and agents, and explain why some questions work without a model and others fail;
- tell apart, in GA's AI, what works today, what is being built, and what is only planned.

## Outline

| # | Lesson | In GA | If you write C# |
|---|---|---|---|
| 1 | [The map](01-the-map/) | the five layers, the index pipeline, the chatbot host, the sibling repositories | reading a DI container, `WebApplicationFactory` |
| 2 | [OPTIC-K embeddings](02-optic-k-embeddings/) | `EmbeddingSchema`, `MusicalEmbeddingGenerator`, `VoicingAnalyzer` | positional records, `TensorPrimitives` |
| 3 | [The index and search](03-index-and-search/) | `OptickIndexWriter`, `OptickIndexReader`, `OptickSearchStrategy`, `MusicalQueryEncoder` | binary formats, memory-mapped files, top-k heaps |
| 4 | [The chatbot and its agents](04-chatbot-and-agents/) | `ProductionOrchestrator`, `SemanticIntentRouter`, `SemanticRouter`, skills, hooks | hosted services, fallbacks, testing a host in process |
| — | [Journal](journal/) | | |

## Prerequisites

- The [.NET 10 SDK](https://dotnet.microsoft.com/download/dotnet/10.0) and [Git](https://git-scm.com/downloads). On Windows, run the course scripts from Git Bash.
- About 20 MB of disk for GA's partial clone, and about 1.1 GB once GA's projects and the course program are built.
- A network connection for the first run only, to clone GA and restore the NuGet packages. After that, everything runs offline.
- No guitar needed, but the chord shapes in lesson 2 are the first ones a guitarist learns.

## Resources

- [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga) at `a826864`, in particular its [`CLAUDE.md`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/CLAUDE.md), the [OPTIC-K schema documents](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Documentation/Schema) and the [chatbot roadmap](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/docs/plans/2026-05-07-chatbot-roadmap.md).
- Clifton Callender, Ian Quinn and Dmitri Tymoczko, ["Generalized Voice-Leading Spaces"](https://doi.org/10.1126/science.1153021), *Science* 320, 2008: the paper that named the OPTIC equivalences.
- Jared Updike, [Harmonious](https://harmoniousapp.net/): an exhaustive chord and scale reference for piano and guitar. Its [Equivalence Groups](https://harmoniousapp.net/p/ec/Equivalence-Groups) page illustrates each OPTIC equivalence with chord diagrams, and adds the K of OPTIC-K, for complementarity.
- [Integration tests in ASP.NET Core](https://learn.microsoft.com/aspnet/core/test/integration-tests), for `WebApplicationFactory`, and [Microsoft.Extensions.AI](https://learn.microsoft.com/dotnet/ai/microsoft-extensions-ai), the abstractions GA's chatbot calls models through.
