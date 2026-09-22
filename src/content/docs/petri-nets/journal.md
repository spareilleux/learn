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
- [x] Lesson 5 — Invariants
- [x] Lesson 6 — Structural classes
- [x] Lesson 7 — Modelling concurrency
- [x] Lesson 8 — Coloured nets
- [x] Lesson 9 — Time and probability
- [x] Lesson 10 — Workflows
- [x] Lesson 11 — Tools and interoperability
- [x] Lesson 12 — Industrial applications
- [x] Lesson 13 — Against other formalisms
- [x] Lesson 14 — On our own systems
- [x] Lesson 15 — Limits and what comes next

## QA

This course teaches a formalism and runs on an analyser I wrote, so there is no third-party product to file bugs against. What the table holds instead is what recomputing found: two defects in the analyser, and every claim that turned out to be wrong when the program was asked. Line numbers point at the files in [`code/petri-nets`](https://github.com/spareilleux/learn/tree/main/code/petri-nets).

| Expected | What happens | Where | Measure | Status |
|---|---|---|---|---|
| The PNML declaration states the encoding the file has | `XmlWriter.Create(StringBuilder, settings)` writes `encoding="utf-16"` whatever `XmlWriterSettings.Encoding` says, because the encoding comes from the `TextWriter`; the bytes were UTF-8 | [`Pnml.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Pnml.cs) | All eight files of lot 1 declared an encoding they did not have | Fixed by a three-line `StringWriter` subclass that overrides `Encoding` (2026-09-15) |
| The coverability tree prints as a tree | The first printer walked the nodes in creation order and indented them by depth, so children appeared under unrelated siblings | [`Report.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Report.cs), `Tree` | The 17-node tree of `unbounded-producer` read as nonsense; a lesson was nearly written around it | Fixed: the printer walks the tree depth first from the root (2026-09-15) |
| The farthest marking of the producer/consumer is 6 firings from *M0* | It is 8 | Lesson 3 draft | `PathTo(11)` returns eight transition names | Corrected before publication (2026-09-15) |
| `handshake` has 8 reachable markings | It has 1, and that one is dead | Lesson 2 draft | `ReachabilityGraph.Build` returns a single state | Corrected before publication (2026-09-15) |
| A **trap** with no token is what makes a marking spurious | It is a **siphon**. A trap that is marked stays marked; a siphon that is empty stays empty | Lesson 2 draft | The two definitions are duals and the draft had them the wrong way round | Corrected before publication (2026-09-15) |
| `handshake` has the transition invariant (1, 1) | It has **none**: `receive` drops a token in `served` that nothing removes, so no multiset of firings cancels out | [`Invariants.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Invariants.cs) | `Invariants.Transitions(handshake).Count` is 0, for `handshake-started` too | Corrected before publication; lesson 5 now uses the zero as its own result (2026-09-17) |
| `mutual-exclusion` is outside the asymmetric-choice class | It is **inside** it: `idle1•` and `idle2•` are each contained in `mutex•` | [`Structure.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Structure.cs) | A unit test asserting the opposite failed; the philosophers are the net that does fall out of the class | Test corrected to the measured answer (2026-09-17) |
| `{x, y}` is still a minimal siphon once both threads take `x` first | It is not minimal any more: `{y}` alone becomes a siphon, and `x` sits in `{a_has_x, b_has_x, x}` | Lesson 6, exercise 1 | `two-locks-ordered` has 4 minimal siphons, all with a marked trap | Corrected before publication, and the wrong prediction is published with the right answer (2026-09-17) |
| The siphon with no trap in a lock that is never released is `{critical1, critical2, mutex}` | There are two, `{idle1}` and `{critical2, mutex}`; `{critical1}` turns out to be a trap | Lesson 7, exercise 2 | `Report.Siphons(mutual-exclusion-leaky)` | Corrected before publication (2026-09-17) |
| The coverability tree of a small bounded net is computable | `CoverabilityTree.Build(Nets.Kanban(1))`, a net with 160 reachable markings, does not return: capped at 2 GiB it throws `OutOfMemoryException` after 15.5 s, uncapped it reached 35.7 GB and twelve minutes of CPU | [`CoverabilityTree.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/CoverabilityTree.cs) | 160 markings, no result; the tree never merges two branches reaching the same marking, so its size follows the number of paths | Not a defect and not fixable: lesson 12 prints two bound columns instead of three, and says why (2026-09-22) |
| A model checker says when it checked nothing | TLC with a state constraint that excludes the initial marking prints `Model checking completed. No error has been found.` and `0 distinct states found`, with no line distinguishing it from a complete run | `tla2tools.jar` 2.19, [TLA+ tools](https://github.com/tlaplus/tlaplus) | `queue_5.tla` with `Cap == 2` against an initial marking of 5 tokens: 1 state generated, 0 distinct, exit 0 | Reproduced on 2026-09-22; not reported upstream — reporting it needs the author's go-ahead. The lesson derives the cap from the place invariants instead (2026-09-22) |
| The coverability tree approximates, and errs on the safe side | On a net with one inhibitor arc it answers omega for a place that never holds two tokens. Karp and Miller's acceleration assumes the sequence reaching a covering marking can be repeated, which an inhibitor arc breaks | [`CoverabilityTree.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/CoverabilityTree.cs), [`Inhibitor.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Inhibitor.cs) | `self-inhibited`: tree says unbounded, reachable set is 2 markings with p <= 1 | Not a defect and not fixable — boundedness is undecidable for these nets. `InhibitorNet` ships with no coverability counterpart, and `InhibitorTests` holds the contradiction so nobody adds one (2026-09-22) |

## Experiments

One warning before the table: unlike the [GA Lab](../../ga-lab/journal/), this course does not commit its hypotheses to a file before measuring. The predictions below were written in my notes while building each net and then checked against the program; that is weaker discipline, and where a prediction was wrong the analyser is what caught it, not a reviewer.

| Question | Hypothesis, written before measuring | Result | Verdict |
|---|---|---|---|
| Do the place invariants give the same bounds as the reachability graph? | They give the same six numbers on the producer and consumer | Identical, place by place, and a unit test now fails if they diverge: 0 markings enumerated on one side, 12 on the other | Confirmed (2026-09-17) |
| Does the place that grows have no invariant? | Removing `free` removes the invariant that bounded `full` | `unbounded-producer` has 2 place invariants instead of 3, and `full` is covered by none of them | Confirmed, with the caveat the lesson states: not being covered is a missing proof, not a proof of unboundedness (2026-09-17) |
| Can place invariants exclude a spurious marking? | No — they are consequences of the state equation | Both spurious markings of `handshake`, (0, 0, 1) and (0, 0, 2), satisfy every place invariant | Confirmed (2026-09-17) |
| Does Commoner's condition agree with the reachability graph? | On every free-choice net of the course | Agreement on all four — `producer-consumer` live, `start-once` and `handshake` not, `connection` live — and a unit test asserts it | Confirmed, on four nets only; the theorem itself is taken from secondary sources (2026-09-17) |
| Are the circuits of a marked graph the same sets as its place invariants? | Yes, with the same constants | The three circuits of `producer-consumer` are `{ready, produced}` 1, `{free, full}` 2, `{waiting, taken}` 1 — the three invariants of lesson 5 | Confirmed (2026-09-17) |
| How many transition invariants does the handshake have? | (1, 1): `receive` then `reply` returns the token | **Zero**, and the 500-marking prefix of `handshake-started` contains no marking reachable twice | Refuted, and it became the better result: a net with no T-invariant can never return to a marking it has left (2026-09-17) |
| How much does taking the forks one at a time cost? | A deadlock, and more markings | Exactly **one** dead marking at every size from 2 to 6 philosophers, and 6, 14, 34, 82, 198 markings against 3, 4, 7, 11, 18 for the atomic version | Confirmed, and the constant 1 was a surprise (2026-09-17) |
| What does reversing one philosopher do to the structure? | Removes the deadlock | Removes a **siphon**: three philosophers have 7 minimal siphons, one of them — `{eating1, fork1, eating2, fork2, eating3, fork3}` — with no marked trap; reversed, 6 siphons and none without one | Confirmed, and it is the structural statement of "order your locks" (2026-09-17) |
| Is a live transition safe from starvation? | No | `start_write` is L4 in the readers and writers, and the graph contains a two-marking cycle, `start_read` then `stop_read`, that never fires it | Confirmed: liveness is "always possible", never "eventually happens" (2026-09-17) |
| Does colour shrink the state space? | No — it folds the model only | 4 places and 4 transitions at every attempt limit; the unfolding and the number of reachable markings both grow linearly, 8, 10, 14, 24, 44 markings for limits 2, 3, 5, 10, 20 | Confirmed, and it is the main point of lesson 8 (2026-09-17) |
| Does the chain built from the net agree with the M/M/1/K formula? | To about 1e-12, since the net *is* that queue | The largest gap over the six states is 5.6e-17, five orders of magnitude under the 1e-12 the check asserts | Confirmed, and it is the only independent check the stochastic solver has (2026-09-22) |
| Where does a finite queue sit when arrivals exactly match service? | Somewhere in the middle, with the ends less likely | **Uniform**: every length from 0 to 5 has probability 0.1667, empty as often as full | Refuted, and it became the more useful result: at load 1 there is no tendency at all (2026-09-22) |
| Does soundness agree with the short circuit being live and bounded? | On all four workflow nets, since the theorem says so | Agreement on all four, and a parameterised test now fails if it breaks | Confirmed (2026-09-22) |
| Is the short circuit of the AND-split-XOR-join net bounded but not live? | Bounded: nothing accumulates in a 1-safe process | **Unbounded**: the leftover token of each case accumulates through t-star without limit | Refuted, and it made the lesson: a token left behind and an unbounded short circuit are the same defect (2026-09-22) |
| How many markings does an invoicing step after the join add? | Two, one per branch of the choice | **One**: the marking where the token sits in the new place | Refuted; a step in sequence adds one state whatever precedes it, only concurrency multiplies (2026-09-22) |
| Can the reader read a PNML file written by another tool? | Yes for the P/T ones; the awkward parts of the ISO sample are all handled | 2 of 16 read, 14 correctly refused by type — and the name, which sits on the page rather than the net, was lost | Refuted in part, and it is the only defect eleven lessons of self-checking output had not found (2026-09-22) |
| Does this analyser agree with tools written by other people? | Yes on the small instances; a disagreement somewhere in the middle would not surprise me | **21 instances from the Model Checking Contest, four numbers each, all identical**, plus four larger ones agreed digit for digit | Confirmed, and it is the first external check this course has had (2026-09-22) |
| Does a Kanban net rebuilt from its published description give the contest's answer? | Yes if the modelling is right; this is a harder test than reading the contest's file | 2 546 432 markings and 24 460 016 arcs for five cards, exactly the published numbers | Confirmed: the modelling is validated, not only the PNML reader (2026-09-22) |
| How many place invariants does the Kanban net have? | Four, one per cell | **Six**: cells 2 and 3 are synchronised, so two crossed sums are conserved too, and minimal-support invariants are not a vector-space basis | Refuted, and the exercise asks the reader to derive the two extra ones (2026-09-22) |
| Where does explicit enumeration stop, and what stops it? | Around ten million markings, and it is the markings | It is the **arcs**: 3.4 M markings with 13.6 M arcs fits, 11.5 M markings with 1.2 billion arcs throws `OutOfMemoryException` at an 8 GiB heap after 158 s | Refuted in its cause; `tedd` does the same instance in 2.3 s because a decision diagram stores no arcs (2026-09-22) |
| Does a model checker written by other people find the same state spaces? | Yes on the small nets; a labelling mismatch somewhere would not surprise me | **22 nets with a finite state space, three numbers each, all identical**: TLC's distinct states, states generated and depth equal markings, arcs + 1 and longest-shortest-path + 1 | Confirmed, on a translation whose generator contains no logic (2026-09-22) |
| Does the one marking reachable by two different transitions break `states generated = arcs + 1`? | Yes: TLA+'s next-state relation is a set of states, so `order-sound` should print 7 where the analyser has 8 arcs | It prints 8. TLC counts one state generated per disjunct it evaluates, not per successor it keeps | Refuted, and the reason is the difference between a labelled graph and a transition relation (2026-09-22) |
| Does a state constraint chosen by hand announce what it truncated? | It at least reports a smaller state space | **Nothing at all**: a cap below the initial marking gives `0 distinct states found` under `No error has been found` | Refuted; the cap in the lesson comes from `Invariants.PlaceBounds` because of it (2026-09-22) |
| Are the nets the place invariants fail to bound the nets with no finite state space? | Yes, that is what an invariant is for | No: `handshake` has no invariant over every place and exactly one marking, because it is dead on arrival | Refuted before publication by `TlaTests`; a place invariant proves boundedness and never disproves it (2026-09-22) |
| How does the cost of enumeration grow as components are added? | Like the markings, which is what everyone quotes | Like the **arcs per marking**: 1.3 to 3.9 over six philosophers, 3.9 to 8.8 over four Kanban cards, because each component multiplies the ways every existing state can be left | Confirmed as a shape, and it flattens: the ratio is an average out-degree and cannot exceed the transition count (2026-09-22) |
| What does atomicity cost in state space? | A constant factor | Philosophers taking both forks at once: 29 markings at seven. One fork at a time: 198 at six. The difference is interleaving, and it is what unfoldings remove | Measured; neither unfolding nor partial order reduction is implemented here, and the lesson says so (2026-09-22) |
| Does the coverability tree stay a safe approximation when the net gains an inhibitor arc? | Yes — it over-approximates by construction, so it should answer omega too often, never wrongly | It answers omega for a place that never holds two tokens. `self-inhibited` has 2 reachable markings and the tree says unbounded | Refuted. The acceleration's premise fails, and it fails because boundedness is undecidable here, so there is nothing to fix (2026-09-22) |

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

## 2026-09-17 — Lessons 5 to 8, and the four things the analyser told me I had wrong

The CI question from lot 1 is settled: `.github/workflows/petri-nets-examples.yml` was committed and has been green on Ubuntu, Windows and macOS since 2026-09-16, at `53ceefc`. It now runs eight lessons instead of four.

**What the analyser grew.** 672 lines in three new files, plus additions to four existing ones:

- [`Structure.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Structure.cs) — the classes (state machine, marked graph, free choice, extended free choice, asymmetric choice, ordinary, pure, strongly connected), the elementary circuits, siphons and traps by brute force over the subsets of places, and the largest trap inside a set by the usual fixpoint.
- [`Coloured.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Coloured.cs) — colour sets, guards, arc expressions, a firing rule on coloured markings, and `Unfold()` into an ordinary P/T net.
- In [`Invariants.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Invariants.cs), the bound each place gets from the invariants alone, and the rank of *C* by exact integer elimination.
- In [`ReachabilityGraph.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/ReachabilityGraph.cs), `CycleAvoiding(t)`: a cycle reachable from *M0* that never fires *t*. Two dozen lines, and it is what turns "this transition is live" into "and here is the run in which it never happens".

Seven nets were added to the ones lot 1 exports — `connection`, `handshake-started`, `readers-writers`, `counting-semaphore`, the philosophers taking one fork at a time with and without an imposed order, and the unfolding of the coloured retry net — and an eighth, the lock that is never released, exists only to be broken in lesson 7's exercise and is not exported. Every exported net is regenerated and compared by `check.sh`. Unit tests went from 30 to 52.

**The result I did not expect, and kept.** Lesson 5 was going to end on "a transition invariant exists but cannot fire", with the handshake as the example. The handshake has no transition invariant at all. `receive` puts a token in `served` and nothing ever takes it out, so no non-empty multiset of firings cancels; and once that is true, the net can never return to a marking it has left. The lesson now says that instead, which is a better fact, and `two-locks` carries the original point — it has two T-invariants and a marking from which neither can start.

**Three more predictions the program refused**, all in the QA table above: `mutual-exclusion` *is* an asymmetric-choice net (a unit test asserting the opposite failed), `{x, y}` stops being a minimal siphon once both threads take `x` first, and the lock that is never released has two trap-free siphons rather than the one I named. Lesson 6 publishes the wrong prediction next to the right answer, because the shape of the mistake — assuming a set stays minimal when the structure around it changes — is more useful than the answer.

**Surprises worth keeping:**

- **The philosophers deadlock exactly once.** Two to six philosophers, one fork at a time: 1 dead marking every time, out of 6, 14, 34, 82, 198. I had expected the number to grow with the ring. It does not, because the only way to lose is for *everyone* to hold one fork, and there is one such marking.
- **The starvation is two markings wide.** The readers and writers net is live, and the run in which the writer never gets in is `start_read`, `stop_read`, repeated. Finding it took a depth-first search over the graph with one transition deleted, and seeing it printed made the difference between liveness and fairness concrete in a way the definitions never did.
- **Colour buys nothing in analysis.** The retry net keeps four places and four transitions whether the attempt limit is 2 or 20; the unfolding goes from 8 places to 44 and the reachable markings from 8 to 44. I knew the theory said this; watching the left columns stay flat while the right ones climb is what makes it land.
- **Commoner's condition earns its keep on `handshake-started`.** That net's reachability graph is infinite — the analyser gives up at 500 markings — and the coverability tree can only report that it is unbounded with no dead transition. The siphon-and-trap condition answers *live* anyway, in the time it takes to enumerate the subsets of three places. It is the first place in this course where the structural method does something the enumeration cannot do at all.

**What I could not verify, and have marked as such:**

- **Hack 1972** is where Commoner's liveness theorem for free-choice nets is stated. The record is confirmed on DSpace@MIT — *Analysis of production schemata by Petri nets*, MIT-LCS-TR-094, February 1972, [handle 1721.1/149406](https://dspace.mit.edu/handle/1721.1/149406) — and the PDF is open access, but the download sits behind a bot check that refused every fetch I made, so **I have not read it**. The theorem's wording in lesson 6 comes from secondary sources. What the lesson asserts on its own evidence is narrower and checked: the condition and the reachability graph agree on the four free-choice nets of this course, and a unit test fails if they stop agreeing.
- **Commoner, Holt, Even and Pnueli 1971** for the marked-graph theorems: record confirmed through Crossref (*JCSS* 5(5), pages 511–523, [doi:10.1016/S0022-0000(71)80013-2](https://doi.org/10.1016/S0022-0000(71)80013-2)), article behind the Elsevier paywall, not read.
- **Desel and Esparza 1995**, *Free Choice Petri Nets*: record confirmed at Cambridge Core, [doi:10.1017/CBO9780511526558](https://doi.org/10.1017/CBO9780511526558), not read.
- **Jensen and Kristensen 2009** for coloured nets: record confirmed through Crossref, [doi:10.1007/b95112](https://doi.org/10.1007/b95112), not read. ISO/IEC 15909-1:2019, where the symmetric-net subclass is defined, still costs CHF 227 and is still unread.
- **Dijkstra 1971** for the philosophers and the resource ordering: record confirmed through Crossref, [doi:10.1007/BF00289519](https://doi.org/10.1007/BF00289519), not read.
- Lesson 7's exercise 3 — the philosophers with a timeout — is argued, not built. It is marked *to verify* in the lesson itself.

**One thing that is honestly weaker than it looks.** Every "no markings enumerated" claim in lessons 5 and 6 is true of the *method*, and the same program then builds the reachability graph anyway to check the method. That is the right way round for a course, and it means none of these lessons demonstrates the method on a net where enumeration would actually fail — except `handshake-started`, which is the one net here whose graph does not exist.

## 2026-09-21 — First executable C# lifecycle oracle

Lesson 14 now connects the formal model to the failure shapes measured in Advanced C# lessons 6 and 9. I added a finite one-slot pipeline with explicit `succeeded`, `failed` and `cancelled` places. Its complete graph has eight markings and three dead markings; every dead marking is an intended terminal, so there are zero non-terminal dead markings. Five focused tests preserve that classification and the capacity invariant `free + queued = 1`, and the PNML fixture is regenerated with the rest of the course.

The important correction was semantic: `DeadStates` means that no transition is enabled, so a successful finite workflow is dead too. “Deadlock-free” is therefore the wrong oracle for a terminating pipeline. The executable contract is instead a complete graph whose dead markings each contain exactly one named terminal token. The page also labels the existing GA-shaped Channel examples honestly as mechanism reproductions rather than current-production regression tests. RabbitMQ, Redis and Kubernetes remain later experiments.

## 2026-09-22 — Lesson 9, and a queue solved twice

Lesson 9 turns the reachability graph into a continuous-time Markov chain. `Stochastic.cs` builds the rate matrix from the graph, eliminates the vanishing states an immediate transition creates, and solves piQ = 0 by Gaussian elimination with partial pivoting. The open question of 2026-09-17 is settled by the lesson itself: the course teaches the **stochastic** formalism first, because it is the one whose semantics follows from the untimed net without a new firing rule, and the deterministic delays of Merlin and Ramchandani are named as the harder theory they are.

The design decision worth recording is the one about checking. A queue with one arrival transition, one service transition and exponential delays *is* an M/M/1/K queue, so the same distribution can be computed twice by routes that share no code: the chain built from the net, and the closed form computed from rho. The six probabilities agree to about 1e-16. That agreement is the only reason to trust the analyser on the nets whose answer is not known in closed form — which is all of them, after this lesson.

Two things fell out of writing it that I did not plan. First, the lesson's own check prints a verdict rather than the difference: the gap's digits depend on the order the machine added the floating-point numbers in, so printing it would make `check.sh` fail on one of the three OSes for a reason unrelated to Petri nets. Second, the load-1 case is more interesting than the load-0.75 one — the queue is not concentrated in the middle, it is uniform over every length, which says something about "sized exactly at capacity" that no mean would.

Little's law is used as a third, independent check rather than as a result: it holds for every stable system without assumptions, so if the chain violated it the chain would be wrong.

`check.sh` now runs `l9` and compares it with `expected/l9.txt`. 57 tests pass, and `l1` to `l9`, `l14`, `music`, `chat` and `nets` all match.

## 2026-09-22 — Lesson 10, and soundness decided twice

Lesson 10 adds `Workflow.cs`: the structural check for a workflow net, the three soundness conditions, and the short circuit of van der Aalst's theorem. The theorem is what makes the lesson worth writing — soundness is decided once on its own conditions and once as "the short-circuited net is live and bounded", by code from lesson 4 that knows nothing about processes, and a parameterised test fails if the two ever disagree on the four example nets.

Two things I did not expect, both now in the lesson.

The first is that `order-and-xor` — the AND split joined by an XOR, which is the commonest error in drawn processes — does not merely get stuck sometimes. Its final marking is **unreachable from anywhere**: the correct end state does not exist in the net at all. Every task can still run, so a test suite that exercises each task passes on a process that can never finish correctly. The report was changed to say that in one line rather than list all ten markings as "stuck", which was true and useless.

The second is that its short circuit is **unbounded**. I expected "bounded but not live". The leftover token of each case accumulates through `t-star` without limit, which means "proper completion fails" and "the short circuit is unbounded" are the same defect counted once per case or counted for ever. The mirror net, `order-xor-and`, is bounded and not live — so the two halves of the theorem are each needed by one of the two example failures, which is a better demonstration than I had planned.

I also got an exercise wrong before checking it. Adding an invoicing step after the join, I predicted the marking count would go from 6 to 8; the analyser said 7. A step in sequence adds one marking whatever precedes it, because only concurrency multiplies. The wrong prediction is published with the right answer, and the reason is now the point of the exercise.

`check.sh` runs `l10`; 66 tests pass and l1 to l10, l14, music, chat and nets all match.

## 2026-09-22 — Lesson 11, and the first file this repository did not write

Ten lessons had been checked against an analyser I wrote, on nets I wrote. Lesson 11 breaks that circle: it downloads the sixteen PNML examples shipped with [ePNK](http://www2.imm.dtu.dk/~eki/projects/ePNK/), the reference implementation of the standard's metamodel, and hands them to the reader.

Fourteen were correctly refused — ten high-level nets, three symmetric nets, and one that deserves its own sentence. `simple-dot-net.pnml` is a plain P/T net written in the *high-level* grammar over the one-value colour set `dot`: same behaviour as every net of this course, different language, unreadable. "PNML" names a syntax plus a type URI, not a format.

The two accepted files found the defect I was hoping for. The standard's own sample, as ePNK writes it, puts the net's name on the `<page>` rather than on the `<net>`, gives the transition no name at all, and puts a `<toolspecific>` block inside `<initialMarking>` before its `<text>`. The reader survived three of those and lost the name: the file came back called `n1`, its id. Three lines in `Pnml.cs` fixed it, and a unit test now carries the whole awkward shape as a string, so the fix cannot regress without the ePNK download.

That is the whole argument of the lesson, and it cost three minutes: ten lessons of output that agreed with itself had found nothing, and the first foreign file found something.

Two things I could not do. The P/T grammar is **not** among the `.rng` files published at pnml.org — `pnmlcoremodel.rng`, `anyElement.rng`, `conventions.rng` and the type-independent ones are there, `ptnet.rng` is a 404 — so the analyser's output has still never been validated against a schema. And the ePNK examples are EPL-1.0, so they are not vendored: `check.sh` runs `l11` without them and prints a pointer, and the foreign listing in the lesson is marked as coming from a dated manual run rather than from the comparison.

`check.sh` runs `l11`; 67 tests pass and l1 to l11, l14, music, chat and nets all match.

## 2026-09-22 — Lesson 12, and the first time somebody else's answer was available

Eleven lessons checked this analyser against itself. Lesson 12 checks it against the [Model Checking Contest](https://mcc.lip6.fr/), which publishes both a public collection of industrial models and the answers its entrants computed for them.

The `StateSpace` examination asks four numbers per instance — markings, arcs, most tokens in a place, most tokens in a marking — and `raw-result-analysis.csv` carries an `estimated result` column with the value a majority of tools agree on, weighted by confidence. That is an oracle. I took the twenty-one P/T instances whose four numbers are published in full, from manufacturing, protocols, shared memory, biochemistry and one security model, and ran the analyser on all of them.

**Twenty-one instances, eighty-four numbers, no disagreement.** Then four more above the published-in-full line — `FMS-PT-00005`, `Kanban-PT-00005`, `Peterson-PT-3`, `Dekker-PT-010` — using the digits several tools printed identically. Still no disagreement. That is the first external validation this course has had, and it was available the whole time.

The Kanban net is rebuilt here rather than read from the contest's file, from the picture and place names in the contest's own model summary. It gives 2 546 432 markings and 24 460 016 arcs for five cards, which is what the contest publishes, so the modelling is right and not only the reader. `check.sh` runs it at three cards to stay fast.

Two things I got wrong, both published in the lesson with the measured answer. I expected **four** place invariants, one per cell; there are **six**, because cells 2 and 3 are synchronised and the minimal-support basis is not a vector-space basis. And I expected the wall to be about the number of markings; it is about the number of **arcs**. `Peterson-PT-3` has 3.4 M markings and 13.6 M arcs and fits; `Dekker-PT-020` has 11.5 M markings and 1.2 **billion** arcs and throws `OutOfMemoryException` at an 8 GiB heap after 158 s. `tedd` does that same instance in 2.3 s and 1.2 GB, because a decision diagram never stores an arc.

And one thing the lesson found in this repository's own code: `CoverabilityTree.Build` does not terminate usefully on `kanban-1`, a net with **160 reachable markings**. Capped at 2 GiB it throws after 15.5 s; uncapped it reached 35.7 GB and twelve minutes of CPU without returning. It is not a bug — the tree never merges branches, so its size follows the number of paths — but it means lesson 3's tool is unusable on anything industrial, and the lesson says so instead of printing a third column.

## 2026-09-22 — Lesson 13, and a state space computed twice

Lesson 12 borrowed other people's answers. Lesson 13 borrows their engine: all 25 nets are written out as TLA+ modules and handed to [TLC](https://github.com/tlaplus/tlaplus), which enumerates the same state spaces from the other side.

The translation turned out to be one sentence long. Make the single TLA+ variable a function from places to naturals and a state *is* a marking; the firing rule then fits in six lines, hand-written once in `tla/PetriNet.tla`, and `Tla.cs` generates only the net. Nothing in the generator contains logic, which is the only reason its output is worth comparing.

TLC finishes with three numbers. Before running any of them I wrote down what each should equal: distinct states = markings, states generated = arcs + 1, depth = longest shortest path + 1. **Twenty-two nets with a finite state space, sixty-six numbers, no disagreement.**

Two of the three predictions were right for the wrong reason, and the lesson keeps both.

`order-sound` is the one net where two transitions lead from a marking to the same marking — `ship` and `cancel`. A Petri net's graph is labelled and TLA+'s is not, so that step should have gone missing from TLC's count: 8 against 7. It is 8 against 8, because TLC counts one state generated per **disjunct it evaluates**, not per successor it keeps. The rule survives the collision by accident, and the accident is the difference between the formalisms: ask what can happen next and TLA+ answers with states, ask what can happen and a net answers with transitions.

The first run stopped early on `retry` — three markings out of eight — and on `pipeline-lifecycle`. Not a translation bug: TLC calls a state with no successor a deadlock and halts, because a TLA+ specification describes something that runs for ever. A workflow net's final marking is that state, and lesson 10 spends its length defining soundness as reaching it. `CHECK_DEADLOCK FALSE` is where the two formalisms disagree about whether systems end.

Then the number that should worry anyone who has ever picked a bound by hand. Set `queue-5`'s cap to 2 — its initial marking holds five tokens — and TLC discards the initial state, checks nothing, and prints `Model checking completed. No error has been found.` with `0 distinct states found`. There is no line in that output to distinguish it from a complete run. That is why the cap in this lesson is `Invariants.PlaceBounds`, and why the lesson prints which four nets got one it could not prove.

And a claim of mine the tests refuted before publication: I wrote that the four nets the invariants do not bound are the four with no finite reachability graph. `handshake` has no invariant over every place and exactly **one** marking, because it is dead on arrival. A place invariant proves boundedness and never disproves it.

Statecharts, process algebras and timed automata are compared in prose and marked as not run. The one thing worth carrying forward is the trade they all make: a process algebra composes, `P | Q` is a term, and you may reason about `P` alone — while a net must exist in full before a siphon, a trap or an invariant means anything. That is precisely why lesson 12's Kanban net had to be rebuilt whole rather than assembled from four copies of one cell.

## 2026-09-22 — Lesson 15, and an algorithm that is correct and still wrong

The last lesson of the plan asks what the analyser cannot do. Three of the answers are measurements rather than arguments.

**The growth has a shape.** Lesson 12 found that the memory wall is about arcs. This lesson watches the arcs per marking climb as components are added: 1.3 → 3.9 across six philosophers, 3.9 → 7.6 across three Kanban cards, 8.8 at four cards (454 475 markings, 3 979 850 arcs — the straight-line extrapolation said 8.9 and overshot, as it must, because the ratio is an average out-degree and `Nets.Kanban` has sixteen transitions at any number of cards). Each added component does not only bring its own states; it multiplies the ways every existing state can be left.

**The interleaving is visible.** Philosophers taking both forks atomically: 29 markings at seven. Taking one fork at a time: 198 at six. Same formalism, same machine. The gap is exactly what unfoldings and partial order reduction exist to remove, and neither is implemented here — the lesson says so instead of implying otherwise.

**And the finding the lesson is built on.** `PetriNets/Inhibitor.cs` adds inhibitor arcs: a transition that fires only while a place is empty. `flush(n)` then says *when every item has moved, finish* in n + 2 markings, where the ordinary net says *at some point, finish* in 2(n + 1). The extra markings are not complexity, they are wrong answers.

The cost arrives immediately. `self-inhibited` is one place, one transition, and an arc from the place back to the transition that fills it. Karp and Miller's tree, run on the underlying ordinary net, answers ω. The reachable set is **two markings** and the place never holds more than one. The acceleration assumes the sequence between a marking and the ancestor it covers can be repeated; here the token that appeared is what now blocks the transition that produced it. The tree is not slow, it is wrong — and it has to be, because the zero test makes two places into the counters of a two-counter machine and boundedness undecidable. `InhibitorNet` therefore has a reachable-set builder with a limit and no coverability counterpart at all: incomplete means "not within the limit", never "unbounded".

That is also the answer to why every other net in this repository is an ordinary place/transition net. It is not conservatism. It is the line past which the analyser's verdicts stop meaning anything.

## To verify

- Lesson 15 names unfoldings, partial order reduction and decision diagrams and implements none of them. The claim that an unfolding is exponentially smaller for the philosopher family is the published result, not a measurement from this repository; the Karp–Miller and Araki–Kasami papers are confirmed through Crossref but paywalled and unread.
- Nothing in lesson 13's statechart, process algebra and timed automaton sections was run. No UPPAAL model was built and no TINA state-class graph was computed; the Harel and Milner references are confirmed through Crossref but are behind paywalls and unread.
- The FMS literature reports far fewer states than the contest does for the same model, because the published counts are the *tangible* markings of a generalized stochastic net and `FMS-PT-*` is an ordinary P/T net. The specific numbers are quoted from memory in my notes and are not in any lesson until a source is read.
- The P/T net grammar is not among the RELAX NG files published at pnml.org, so the analyser's PNML has never been validated against a schema. `pnmlcoremodel.rng` is there and would check the structure; the P/T specifics fall through its `anyElement` rule.
- Hack 1972, the source of Commoner's theorem, is open access and unreadable to an automated fetch. Reading it in a browser would let lesson 6 quote the theorem rather than paraphrase a paraphrase.
- Murata 1989 remains paywalled and unread; every attribution to it in lessons 1 to 8 is marked in the page.
- Lesson 7, exercise 3: build the philosophers with a timeout and check that the net is deadlock-free and has an infinite run in which nobody eats.
- The claim that minimal siphon enumeration is NP-hard is stated in lesson 6 from general knowledge and not pinned to a paper.

## Open questions

- Lesson 13 hands TLC the state space and nothing else: the generated `.cfg` has an `INVARIANT` line and no `PROPERTY` line, so no temporal formula under fairness has been checked. `[]<>Enabled(t) => []<>t` is what lesson 7's starvation question asks, and TLC would answer it. Whether to generate fairness conditions per net, or to write one module by hand for the one net where starvation is the point, is undecided.
- The brute force over subsets of places caps the analyser at twenty places. Six philosophers taking one fork at a time have twenty-four, so the structural verdict cannot be computed for the largest net in lesson 7's own table. A constraint-solver formulation would fix it and would make the course depend on a solver.
- The coloured nets of lesson 8 bind one variable per transition. A transition joining two messages needs a tuple, and the unfolding would grow as a product. Lesson 12 sidestepped this — the contest ships every model already unfolded to P/T — so the question is still open, and lesson 15 is the last place it can be answered.
- Lesson 9 taught the stochastic formalism, which leaves the deterministic one open: a time Petri net in the sense of Merlin, where a transition carries an interval rather than a rate, has no Markov chain behind it and needs a state-class construction the analyser does not have. Whether lesson 13 builds one or hands the model to TINA, which does exactly this, is undecided.
