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
- [ ] Lesson 9 — Time and probability
- [ ] Lesson 10 — Workflows
- [ ] Lesson 11 — Tools and interoperability
- [ ] Lesson 12 — Industrial applications
- [ ] Lesson 13 — Against other formalisms
- [ ] Lesson 14 — On our own systems
- [ ] Lesson 15 — Limits and what comes next

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

## To verify

- Hack 1972, the source of Commoner's theorem, is open access and unreadable to an automated fetch. Reading it in a browser would let lesson 6 quote the theorem rather than paraphrase a paraphrase.
- Murata 1989 remains paywalled and unread; every attribution to it in lessons 1 to 8 is marked in the page.
- Lesson 7, exercise 3: build the philosophers with a timeout and check that the net is deadlock-free and has an infinite run in which nobody eats.
- The claim that minimal siphon enumeration is NP-hard is stated in lesson 6 from general knowledge and not pinned to a paper.

## Open questions

- The brute force over subsets of places caps the analyser at twenty places. Six philosophers taking one fork at a time have twenty-four, so the structural verdict cannot be computed for the largest net in lesson 7's own table. A constraint-solver formulation would fix it and would make the course depend on a solver.
- The coloured nets of lesson 8 bind one variable per transition. A transition joining two messages needs a tuple, and the unfolding would grow as a product. Whether to implement that in lesson 12, where a real protocol appears, or to hand that model to CPN Tools and say so, is undecided.
- Lesson 9 needs time, and time is where a net stops having one accepted semantics. Which of the timed formalisms — time Petri nets in the sense of Merlin, timed nets in the sense of Ramchandani, or the stochastic ones — this course teaches first is not settled.
