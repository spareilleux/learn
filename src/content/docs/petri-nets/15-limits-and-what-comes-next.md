---
title: "15. Limits and what comes next: undecidability, unfoldings, partial order reduction, extensions"
description: Measure where this analyser stops and why, add the one extension that lifts a limit, and watch the coverability tree give a wrong answer instead of a slow one.
sidebar:
  order: 15
---

Fourteen lessons built an analyser and then checked it — against itself, against another tool's files, against a contest's published answers, against TLC. This one asks what it cannot do, and answers with numbers rather than with a shrug.

There are three kinds of limit here, and they are not the same kind of thing. One is this analyser's (brute force over subsets, a cap at twenty places). One is the machine's (lesson 12 measured it: 1.216 billion arcs). One belongs to the formalism, and no amount of engineering moves it.

## Run the experiment

```bash
dotnet run --project code/petri-nets/Examples -c Release -- l15
dotnet test code/petri-nets/Tests -c Release --filter InhibitorTests
```

The whole block below is in [`expected/l15.txt`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/expected/l15.txt), compared line by line by `check.sh`. The inhibitor extension is [`Inhibitor.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Inhibitor.cs) and the two nets it is demonstrated on are [`InhibitorNets.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/Examples/InhibitorNets.cs).

## How fast the state space grows

```
  family                     n   markings        arcs  arcs/marking
  philosophers               2          3           4           1.3
  philosophers               3          4           6           1.5
  philosophers               4          7          16           2.3
  philosophers               5         11          30           2.7
  philosophers               6         18          60           3.3
  philosophers               7         29         112           3.9
  philosophers-one-fork      2          6           8           1.3
  philosophers-one-fork      3         14          27           1.9
  philosophers-one-fork      4         34          88           2.6
  philosophers-one-fork      5         82         265           3.2
  philosophers-one-fork      6        198         768           3.9
  kanban                     1        160         616           3.9
  kanban                     2       4600       28120           6.1
  kanban                     3      58400      446400           7.6
```

Two things in that table matter more than the growth itself.

The first is the **last column**. Lesson 12 found that the memory wall is about arcs, not markings — `Dekker-PT-020` has 11.5 million markings and 1.216 billion arcs and dies at an 8 GiB heap, while `Peterson-PT-3` has 3.4 million markings and 13.6 million arcs and fits. Here the ratio climbs with every added component: 1.3 → 3.9 for philosophers, 3.9 → 7.6 for Kanban. Each new philosopher does not merely add its own states; it multiplies the ways every existing state can be left.

The second is the **difference between the two philosopher families**. Taking both forks atomically gives 29 markings at seven philosophers. Taking one fork at a time gives 198 at six. The formalism did not change and the machine did not change: what grew is the number of interleavings the model is obliged to distinguish, which is exactly what partial order reduction and unfoldings exist to collapse.

## What the structure costs by comparison

```
  net                       places  invariants  siphons   traps
  philosophers-3                 9           6        6       6
  philosophers-4                12           8        8       8
  philosophers-5                15          10       10      10
```

The invariants are Farkas elimination on a matrix: they keep answering while the state space multiplies. The siphons and traps are the brute force of lesson 7, enumerating subsets of places, and the analyser caps that at twenty. Six philosophers taking one fork at a time have twenty-four places, so the structural verdict cannot be computed for the largest net in lesson 7's own table — a limitation of this code, not of the theory. Finding a minimal siphon is NP-hard, which is an honest reason to be slow and no reason at all to be capped at twenty: a constraint-solver formulation would go much further, at the cost of making the course depend on a solver.

## The wall that engineering does not move

Three facts, none of them measurable here, all of them decided:

**Reachability is decidable.** Given a net and a marking, there is an algorithm that says whether the marking is reachable. That is not obvious and took twenty years to settle.

**It is Ackermann-complete.** Not exponential — *Ackermannian*, a function that outgrows every primitive recursive one. [Leroux (2021)](https://arxiv.org/abs/2104.12695) proved the lower bound is not primitive recursive; [Czerwiński and Orlikowski (2021)](https://arxiv.org/abs/2104.13866) pinned it to Ackermann-complete. No implementation removes that, and the instances in lesson 12 that answered in seconds answered because they were small, not because the problem is easy.

**Boundedness is decidable, and that is why lesson 3 works.** [Karp and Miller (1969)](https://doi.org/10.1016/S0022-0000(69)80011-5) gave the coverability tree, which terminates on every net by replacing a place that grew with ω. `CoverabilityTree.Build` is that algorithm, and lesson 12 measured what its lack of merging costs: on `kanban-1`, a net with **160 reachable markings**, it ran out of memory.

**Some questions are undecidable outright.** Whether two nets have the same reachability set is one; [Araki and Kasami (1976)](https://doi.org/10.1016/0304-3975(76)90067-0) collect several. That is worth holding next to lesson 13: TLC will answer any invariant you can write about a finite state space, and the question *are these two models the same* has no algorithm in either formalism.

## The extension that lifts the limit, and what it costs

A Petri net cannot test a place for zero. A transition fires when its input places hold *enough*; there is no arc that means *and this place is empty*. That is why `handshake` cannot detect that it is stuck, and why lesson 10's soundness had to be defined by a short-circuit rather than by "the work places are empty".

Add one arc type and the limit is gone:

```csharp
public sealed record InhibitorArc(string Place, string Transition);
```

`InhibitorNet.IsEnabled` is the ordinary rule plus one line: every inhibiting place must hold nothing.

Here is what it buys. `flush(n)` moves `n` tokens from `a` to `b` one at a time, and `finish` is inhibited by `a`:

```
  flush(n)       with the zero test     without it
  flush-1                         3              4
  flush-2                         4              6
  flush-4                         6             10
  flush-8                        10             18
```

With the inhibitor arc, `finish` fires exactly once, after the last `move`: *n* + 2 markings. Drop it and `finish` may fire at any point, which is 2(*n* + 1) markings and a model that no longer says what it was written to say. The extra markings are not complexity — they are wrong answers.

And here is what it costs. `self-inhibited` is the smallest net that can be built with one: one place, one transition, and an arc from the place to the transition that produced it.

```
  self-inhibited: one place, one transition, one inhibitor arc.
    as an ordinary net, the coverability tree says bounded = False, p <= omega
    with the inhibitor arc, the reachable set is 2 markings, p <= 1, complete = True
```

**The coverability tree is not slow here. It is wrong.** Karp and Miller's acceleration rests on an argument that an inhibitor arc breaks: if a marking strictly covers one of its ancestors, the firing sequence in between can be repeated for ever, so the places that grew can grow without bound. With an inhibitor arc, the token that appeared is exactly what now blocks the transition that produced it. The sequence cannot be repeated, and ω is a lie.

That is not a defect to fix. The zero test turns two places into the counters of a two-counter machine, so an inhibitor net simulates a Turing machine, and boundedness, reachability and liveness all become undecidable. `InhibitorNet` therefore ships with a reachable-set builder that takes a limit and **no coverability counterpart at all**: when its search is incomplete the answer is "not within the limit", never "unbounded". Everything else in this repository is an ordinary net on purpose.

## What would actually help, and is not here

Three techniques attack the table at the top of this lesson, and none of them is implemented.

**Unfoldings.** Instead of enumerating markings, build a partial order of events — a net that records what happened, with concurrency left unordered rather than interleaved. [McMillan (1993)](https://doi.org/10.1007/3-540-56496-9_14) showed how to stop: a *cut-off* event is one whose result is already represented, and the finite complete prefix that remains can be exponentially smaller than the reachability graph for concurrent systems. [Esparza, Römer and Vogler (1996)](https://doi.org/10.1007/3-540-61042-1_40) fixed the adequate order that makes the prefix minimal. The two philosopher families above are precisely the shape this attacks: the difference between 29 and 198 is interleaving, and an unfolding does not pay for it.

**Partial order reduction.** Keep enumerating markings, but at each one fire only a subset of the enabled transitions — chosen so that every property of interest is preserved. Valmari's stubborn sets and the ample-set constructions are the usual formulations. Cheaper to bolt onto an existing explorer than an unfolding, and much harder to get right: the subset condition is where the soundness lives, and a wrong one silently loses states, which is the same failure mode as a state constraint in lesson 13.

**Decision diagrams.** Lesson 12 measured this one from the outside. `tedd` answers `Dekker-PT-020` in 2.3 s and 1209 MB where this analyser dies after 158.3 s at 8 GiB, because a decision diagram stores a *set* of markings symbolically and never stores an arc at all. The 1.216 billion arcs that killed the explicit search simply do not exist in that representation.

*To verify.* None of the three was implemented or measured here. The claim that an unfolding is exponentially smaller for the philosopher family is the published result, not an observation from this repository, and the honest version is: the interleaving is visible in the table, and the technique that removes it was not run.

## Where the course itself stops

- **No temporal logic.** Lesson 13 handed TLC the state space and no `PROPERTY` line; `[]<>Enabled(t) => []<>t` under fairness is what lesson 7's starvation question really asks, and neither this analyser nor any module here answers it.
- **No deterministic time.** Lesson 9 added stochastic rates and got a Markov chain. A Merlin interval `[a, b]` needs a state-class construction that is not here; [TINA](https://projects.laas.fr/tina/) does it.
- **No coloured tuples.** Lesson 8's coloured nets bind one variable per transition. A transition joining two messages needs a tuple and the unfolding grows as a product; the contest models of lesson 12 sidestepped it by shipping everything already unfolded.
- **No continuous or hybrid nets**, where a marking is a real number and firing is a rate. That is a different formalism with a different theory, and nothing above transfers to it.
- **The siphon cap.** Twenty places, for the reason given above.

## Key takeaways

- The cost of enumeration is in the arcs, and the arcs per marking climb with every component added: 1.3 → 3.9 across six philosophers, 3.9 → 7.6 across three Kanban cards.
- Taking one fork at a time instead of two costs 198 markings where atomic pickup costs 29. That difference is interleaving, and it is what unfoldings and partial order reduction exist to remove.
- Structural analysis keeps answering while the state space multiplies, because invariants are a matrix computation. The analyser's twenty-place cap on siphons is its own limit, not the theory's.
- Reachability is decidable and Ackermann-complete. No implementation moves that, and the equality of two reachability sets is undecidable outright.
- One inhibitor arc buys the test for zero — and makes the formalism Turing complete, at which point the coverability tree stops being an approximation and starts being wrong: it answers ω for a net whose place never holds two tokens.
- Every net in this repository is an ordinary place/transition net for that reason, and the one exception is in the course to be measured once and put away.

## Exercises

1. Run `l15` and extend the Kanban row to four cards. Before running it, predict the arcs per marking from the three rows already there. How close is the prediction, and which direction does it err in?
2. `flush(n)` has *n* + 2 markings with the zero test and 2(*n* + 1) without. Write the sentence the inhibitor arc makes the net say, and the sentence the ordinary net says instead. Which of the two is a specification you could hand to a programmer?
3. Build an inhibitor net with two places `x` and `y` and transitions that decrement `x` while incrementing `y`, plus one transition enabled only when `x` is empty. You have built half of a two-counter machine. What would you need to add to build the other half, and why does that make boundedness undecidable?
4. `CoverabilityTree.Build(InhibitorNets.SelfInhibited().Net)` answers ω. Find the step of the Karp–Miller construction that is unsound here, and state the assumption it makes, in one sentence.

<details>
<summary>Solutions</summary>

1. The three ratios are 3.9, 6.1 and 7.6, so the increments are +2.2 and +1.5 and a straight extrapolation gives about **8.9**. Measured, four cards give **454 475 markings, 3 979 850 arcs, ratio 8.8** — the extrapolation overshoots, and it will keep overshooting. The ratio is the average out-degree of a marking, bounded by the number of transitions, and `Nets.Kanban` has sixteen of them at any number of cards; the curve has to flatten. Where the cost keeps compounding is the markings: 160 → 4 600 → 58 400 → 454 475, a factor of about eight per card with no ceiling in sight.

2. With the arc: *when every item has been moved, finish.* Without it: *at some point, finish, and separately the items get moved.* The first is a specification — it names the condition. The second is a description of two things that happen, and a programmer handed it would be right to ask "before or after?" and get no answer from the model. That is the exact gap lesson 10 had to close with a short-circuit instead of a zero test.

3. You need a second counter and the ability to branch on either being zero: a two-counter machine is two counters, increment, decrement, and a conditional jump on zero for each. `x` and `y` are the counters, the arcs are the increments and decrements, and the inhibitor arc is the jump. Minsky's result is that two counters suffice to simulate a Turing machine; so "does this net ever put more than *k* tokens in a place" becomes "does this machine ever reach this configuration", which is the halting problem. There is no algorithm, so no coverability tree can exist — not a slow one, none.

4. The unsound step is the ω-acceleration: when a new marking *M′* strictly covers an ancestor *M* on its own path, every place where *M′ > M* is set to ω. The assumption is that **the firing sequence leading from *M* to *M′* can be fired again from *M′***, so those places can be pumped arbitrarily high. In `self-inhibited` the sequence is the single transition `grow`, and firing it puts a token in `p` — which is precisely what inhibits `grow`. The sequence cannot be repeated once, let alone arbitrarily often.

</details>

## Sources

- Jérôme Leroux, *The Reachability Problem for Petri Nets is Not Primitive Recursive*, [arXiv:2104.12695](https://arxiv.org/abs/2104.12695), 2021. The lower bound.
- Wojciech Czerwiński and Łukasz Orlikowski, *Reachability in Vector Addition Systems is Ackermann-complete*, [arXiv:2104.13866](https://arxiv.org/abs/2104.13866), 2021. The matching upper bound, and the reason this lesson says Ackermann rather than "very hard".
- Richard Karp and Raymond Miller, *Parallel program schemata*, **Journal of Computer and System Sciences** 3(2), 1969, [doi:10.1016/S0022-0000(69)80011-5](https://doi.org/10.1016/S0022-0000(69)80011-5). The coverability tree `CoverabilityTree.cs` implements. The record is confirmed through Crossref; the paper is behind a paywall and I have not read it, and everything this course says about the construction is either derived in lesson 3 or measured. *To verify.*
- Toshiro Araki and Tadao Kasami, *Some decision problems related to the reachability problem for Petri nets*, **Theoretical Computer Science** 2(1), 1976, [doi:10.1016/0304-3975(76)90067-0](https://doi.org/10.1016/0304-3975(76)90067-0). Same caveat. *To verify.*
- Kenneth McMillan, *Using unfoldings to avoid the state explosion problem in the verification of asynchronous circuits*, **CAV '92**, LNCS 663, [doi:10.1007/3-540-56496-9_14](https://doi.org/10.1007/3-540-56496-9_14), and Javier Esparza, Stefan Römer and Walter Vogler, *An improvement of McMillan's unfolding algorithm*, **TACAS '96**, LNCS 1055, [doi:10.1007/3-540-61042-1_40](https://doi.org/10.1007/3-540-61042-1_40). Neither algorithm is implemented here. *To verify.*
- Tadao Murata, *Petri nets: Properties, analysis and applications*, **Proceedings of the IEEE** 77(4), 1989, [doi:10.1109/5.24143](https://doi.org/10.1109/5.24143). Section IV-A is the presentation of the coverability tree this course followed, and section VI lists the extensions.
- [TINA](https://projects.laas.fr/tina/), named for the state-class construction this analyser does not have.
- Lesson 12's contest numbers, for `tedd`: [Model Checking Contest](https://mcc.lip6.fr/) results.
