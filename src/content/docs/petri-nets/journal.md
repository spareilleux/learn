---
title: Journal
description: Dated progress notes for the Petri nets course — the analyser's design, a PNML declaration that lied about its encoding, a coverability tree printed in the wrong order, the Lucas numbers turning up uninvited, and what I could not verify.
sidebar:
  order: 99
---

## Progress

- [x] Lesson 1 — Why Petri nets
- [x] Lesson 2 — The formal definition and the incidence matrix
- [x] Lesson 3 — The reachability graph
- [x] Lesson 4 — Properties
- [ ] Lesson 5 — Invariants
- [ ] Lesson 6 — Structural classes
- [ ] Lesson 7 — Modelling concurrency
- [ ] Lesson 8 — Coloured nets
- [ ] Lesson 9 — Time and probability
- [ ] Lesson 10 — Workflows
- [ ] Lesson 11 — Tools and interoperability
- [ ] Lesson 12 — Industrial applications
- [ ] Lesson 13 — Against other formalisms
- [ ] Lesson 14 — On our own systems
- [ ] Lesson 15 — Limits and what comes next

## 2026-09-15 — Lessons 1 to 4, and the analyser they run on

**Why write an analyser at all.** There are mature tools — TINA, LoLA, CPN Tools, GreatSPN, TAPAAL — and lesson 11 will use them. I wrote a small one anyway, for three reasons. A course whose outputs are compared by CI needs a program whose output I control down to the ordering. A reader who has the firing rule in front of them in C# understands it faster than a reader who has a screenshot of a GUI. And the analyser is the only honest way to write these lessons: the twelve markings, the seventeen tree nodes and the two spurious markings are all printed by it, not remembered by me.

It is about 1 400 lines across ten files in [`code/petri-nets/PetriNets`](https://github.com/spareilleux/learn/tree/main/code/petri-nets/PetriNets): the net and the firing rule, PNML in and out, the reachability graph, the Karp–Miller coverability tree, place and transition invariants by Farkas elimination, the state equation, and a printer. The .NET SDK on this machine is 10.0.112, running on .NET 10.0.12; `global.json` pins the 10.0.1xx band with `rollForward: latestFeature`, so the 11.0.100 preview that is also installed is not picked up.

**Determinism was the constraint that shaped the code.** Everything a lesson quotes has to come out the same on Windows, Linux and macOS, and hash-based collections do not promise that. So the reachability graph is built breadth first and numbers its states in discovery order; the firings are sorted by source state and then by transition before they are returned; the invariants are normalised by their greatest common divisor and sorted; the PNML writer emits LF line endings and a fixed indentation. `check.sh` compares four lesson outputs and eight PNML files, so a change that reorders anything fails immediately instead of quietly making a lesson wrong.

**Surprises:**

- **The buffer with no brake is one place away.** Removing `free` and its two arcs from the producer/consumer turns a twelve-marking net into one with an infinite reachability set. Nothing in the picture warns you; it is the *absence* of a place that does it. I now read "which place stops this transition" as the first question to ask of any net.
- **The Lucas numbers.** The reachability graph of *n* dining philosophers has 3, 4, 7, 11, 18, 29, 47, 76, 123 markings for *n* = 2 … 10. I had expected something like 2ⁿ and got a sequence where each term is the sum of the two before it. It makes sense once you see that a marking is a choice of which philosophers eat, no two of them adjacent — the independent sets of a cycle, which are counted by the Lucas numbers. A pleasant reminder that the state space has structure, which is exactly what the reduction techniques of lesson 15 exploit.
- **The coverability tree is bigger than the graph it replaces.** For the bounded producer/consumer: 56 tree nodes for 12 markings. A tree has no sharing, so every marking is repeated once per path that reaches it. The tree only pays for itself when the graph does not exist at all.
- **Spurious solutions are harder to construct than to describe.** I wanted a marking that satisfies *M* = *M0* + *C x* without being reachable, and my first four attempts all failed for the same reason: every cycle in those nets carried a token, so the state equation and the firing rule agreed. The one that works is the `handshake` net, where `receive` and `reply` hand a single token back and forth and nobody ever sends the first request — the equation lets `receive` borrow the token that `reply` would only produce afterwards. Rather than trust the construction, the analyser now enumerates every marking up to a token budget and reports those the equation accepts and the graph does not; it finds `(0, 0, 1)` and `(0, 0, 2)`. A test also checks the opposite for the producer/consumer, which has none.

**Two bugs of my own, both about output rather than mathematics:**

- **PNML that lied about its encoding.** `XmlWriter.Create(StringBuilder, settings)` writes `encoding="utf-16"` in the declaration whatever `XmlWriterSettings.Encoding` says, because the encoding is taken from the `TextWriter`. The files were written as UTF-8, so every one of them claimed an encoding it did not have — harmless for my own reader, a trap for any tool that believes the declaration. Fixed with a three-line `StringWriter` subclass that overrides `Encoding`.
- **A coverability tree printed in the wrong order.** The first version printed the nodes in creation order and indented them by depth, which looks like a tree and is not one: children of a node created later appeared under an unrelated sibling. The output was nonsense and I nearly wrote a lesson around it. The printer now walks the tree depth first from the root.

**What I could not verify, and have marked as such:**

- Murata's survey is behind the IEEE paywall, and IEEE Xplore refused the request outright. The bibliographic record is confirmed through Crossref — *Proceedings of the IEEE* 77(4), April 1989, pages 541–580, [doi:10.1109/5.24143](https://doi.org/10.1109/5.24143) — and the definitions I attribute to it are the standard ones, but I have not read the paper itself. Where I would have to rely on it for a claim I cannot check another way — that the state equation is necessary *and sufficient* for acyclic nets — lesson 2 says *to verify* instead of asserting it.
- Lipton's 1976 Yale technical report, for the EXPSPACE lower bound on coverability, is cited from secondary sources. Rackoff's matching upper bound is confirmed: *Theoretical Computer Science* 6(2), 1978, pages 223–231.
- Everything about the complexity of reachability is pinned to papers whose records I checked at Crossref: decidability by Mayr (STOC 1981) and Kosaraju (STOC 1982), the Ackermann upper bound by Leroux and Schmitz (LICS 2019), and the matching lower bound by Czerwiński and Orlikowski and, independently, Leroux, both at FOCS 2021. I wanted the *current* state of that question rather than the "decidable, complexity open" answer that older textbooks give, and 2021 closed it.
- ISO/IEC 15909 has three parts, and I checked all three on iso.org: part 1 (2019, concepts), part 2 (2011, the transfer format this course writes, last confirmed in 2024) and part 3 (2021, extensions). The standard itself costs CHF 227 and I have not read it; the PNML the analyser writes follows the public grammar at [pnml.org](https://www.pnml.org/) and round-trips through its own reader, which is all this course claims.

**Still to do:**

- The CI workflow `.github/workflows/petri-nets-examples.yml` is written but **not committed**: the token available here has no `workflow` scope. Nothing in the lessons claims a green CI until it has run.
- The dogfooding of lesson 14 — a `Channel<T>` pipeline from Guitar Alchemist, a RabbitMQ topology, a Kubernetes rolling update, an agent pipeline — has not started. Lot 1 models textbook systems only, and says so.

## 2026-09-15 — Translations

The French and Spanish versions of the mission, lessons 1 to 4 and this journal were produced from the English commit, with the code blocks copied by script and only the prose, the code comments and the Mermaid labels translated. The place and transition names inside the nets are part of the program's output, so they stay in English in all three locales: translating them would make the listings disagree with `expected/`.
