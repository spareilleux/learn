---
title: "13. Against other formalisms: TLA+, statecharts, process algebras, timed automata"
description: Hand all 25 nets of this course to TLC and compare three numbers per net, then ask what statecharts, process algebras and timed automata say that a Petri net does not.
sidebar:
  order: 13
---

Lesson 11 handed the analyser files written by another tool. Lesson 12 handed it answers computed by other people. This lesson asks the question underneath both: **is a Petri net the right language at all?**

Four rivals cover most of what is used for concurrency: [TLA+](https://lamport.azurewebsites.net/tla/tla.html), statecharts, process algebras, and timed automata. Only one of them has a checker that will read a whole net corpus without a licence dialogue, so only one of them is *measured* here. The rest are compared honestly, and marked as not run.

## Run the experiment

```bash
dotnet run --project code/petri-nets/Examples -c Release -- l13
```

```bash
# The cross-check. tla2tools.jar is not vendored: download it first.
dotnet run --project code/petri-nets/Examples -c Release -- tla out/tla
java -cp tla2tools.jar tlc2.TLC -workers 1 -cleanup out/tla/mutual_exclusion.tla
```

The generator is [`Tla.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/Examples/Tla.cs), the firing rule it instantiates is [`tla/PetriNet.tla`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/tla/PetriNet.tla), and the whole block below is in [`expected/l13.txt`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/expected/l13.txt), compared line by line by `check.sh`.

## The same net, written twice

A TLA+ specification is a formula. Its variables take values; a behaviour is a sequence of assignments. A Petri net is a graph; its places hold tokens, and a marking is a function from places to naturals. Those two sentences meet exactly once: **make the single variable a function from places to naturals, and a TLA+ state *is* a marking.**

So the firing rule is written once, by hand, and never generated:

```tla
Enabled(t) == \A p \in Places : marking[p] >= Pre[t][p]

Fire(t) ==
    /\ Enabled(t)
    /\ marking' = [p \in Places |-> marking[p] - Pre[t][p] + Post[t][p]]

Init == marking = M0
Next == \E t \in Transitions : Fire(t)
Spec == Init /\ [][Next]_marking
```

What is generated is only the net. `Nets.MutualExclusion()` becomes:

```tla
---------------------- MODULE mutual_exclusion ----------------------
EXTENDS Naturals

Places == {"idle1", "critical1", "idle2", "critical2", "mutex"}
Transitions == {"enter1", "leave1", "enter2", "leave2"}

PreArcs == {
    [p |-> "idle1", t |-> "enter1", w |-> 1],
    [p |-> "mutex", t |-> "enter1", w |-> 1],
    [p |-> "critical1", t |-> "leave1", w |-> 1],
    [p |-> "idle2", t |-> "enter2", w |-> 1],
    [p |-> "mutex", t |-> "enter2", w |-> 1],
    [p |-> "critical2", t |-> "leave2", w |-> 1]
}

PostArcs == {
    [p |-> "critical1", t |-> "enter1", w |-> 1],
    [p |-> "idle1", t |-> "leave1", w |-> 1],
    [p |-> "mutex", t |-> "leave1", w |-> 1],
    [p |-> "critical2", t |-> "enter2", w |-> 1],
    [p |-> "idle2", t |-> "leave2", w |-> 1],
    [p |-> "mutex", t |-> "leave2", w |-> 1]
}

M0 == [p \in Places |-> IF p \in {"idle1", "idle2", "mutex"} THEN 1 ELSE 0]
\* Every place is bounded by 1 (Invariants.PlaceBounds), so the constraint truncates nothing.
Cap == 1

VARIABLE marking
INSTANCE PetriNet
=============================================================================
```

Keeping the semantics in a hand-written module and the data in a generated one is the difference between a translation you can read and a translation you have to trust. The generator is a hundred lines and writes no logic.

## What the model checker has to be told

One line of that module is not in the net at all: `Cap == 1`.

TLA+ has no notion of boundedness. A specification is a set of behaviours, not a graph, and `marking[p]` ranges over all of `Nat`. Handed an unbounded net, TLC enumerates until it exhausts memory, and never says *unbounded* — it says nothing, for as long as you let it. The generated `.cfg` therefore carries a state constraint:

```
SPECIFICATION Spec
CONSTRAINT Bounded
INVARIANT TypeOK
CHECK_DEADLOCK FALSE
```

and `Bounded == \A p \in Places : marking[p] =< Cap`.

Where does `Cap` come from? From [`Invariants.PlaceBounds`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Invariants.cs) — the place invariants of lesson 5. **The structure theory supplies the number the model checker cannot derive.** For 21 of the 25 nets the invariants prove a bound, and the constraint truncates nothing:

```
  21 of 25 nets carry a cap the place invariants produced.
  The other 4 have no invariant covering every place, so the generated module caps them at 3:
    unbounded-producer
    handshake
    emit-loop
    handshake-started
```

A cap picked by hand instead would be a quiet hazard. Set `queue-5`'s cap to 2 — its initial marking holds five tokens in `room` — and TLC discards the initial state before exploring anything:

```
Model checking completed. No error has been found.
1 states generated, 0 distinct states found, 0 states left on queue.
```

Nothing was checked and the verdict says success. There is no line in that output to distinguish it from a complete run, which is why the number comes from the invariants and why the lesson prints which nets got a cap it could not prove.

## Three numbers for one state space

TLC finishes with a line like `5 states generated, 3 distinct states found` and a depth. Three numbers. Before running it on anything, three guesses:

- **distinct states** = the analyser's reachable markings;
- **states generated** = the analyser's arcs, plus one for the initial state;
- **depth** = the analyser's longest shortest path, plus one, because TLC counts states on the path and the analyser counts steps.

Twenty-five modules, twenty-five TLC runs:

| net | markings | distinct | arcs + 1 | generated | depth + 1 | TLC |
|---|---|---|---|---|---|---|
| producer-consumer | 12 | 12 | 21 | 21 | 9 | 9 |
| handshake | 1 | 1 | 1 | 1 | 1 | 1 |
| mutual-exclusion | 3 | 3 | 5 | 5 | 2 | 2 |
| two-locks | 4 | 4 | 7 | 7 | 3 | 3 |
| two-locks-ordered | 3 | 3 | 5 | 5 | 2 | 2 |
| start-once | 3 | 3 | 4 | 4 | 3 | 3 |
| connection | 3 | 3 | 5 | 5 | 3 | 3 |
| readers-writers | 5 | 5 | 9 | 9 | 4 | 4 |
| counting-semaphore | 7 | 7 | 19 | 19 | 3 | 3 |
| philosophers-one-fork-3 | 14 | 14 | 28 | 28 | 4 | 4 |
| philosophers-ordered-3 | 12 | 12 | 23 | 23 | 4 | 4 |
| lane-lock-guarded | 7 | 7 | 15 | 15 | 4 | 4 |
| lane-lock-unguarded | 10 | 10 | 19 | 19 | 5 | 5 |
| pipeline-lifecycle | 8 | 8 | 9 | 9 | 5 | 5 |
| queue-5 | 6 | 6 | 11 | 11 | 6 | 6 |
| two-servers | 3 | 3 | 5 | 5 | 2 | 2 |
| order-sound | 6 | 6 | 8 | 8 | 5 | 5 |
| order-and-xor | 10 | 10 | 14 | 14 | 6 | 6 |
| order-xor-and | 5 | 5 | 5 | 5 | 3 | 3 |
| order-rework | 4 | 4 | 5 | 5 | 4 | 4 |
| retry | 8 | 8 | 10 | 10 | 7 | 7 |
| kanban-1 | 160 | 160 | 617 | 617 | 15 | 15 |

**Twenty-two nets, sixty-six numbers, no disagreement.** The three nets left out — `unbounded-producer`, `emit-loop`, `handshake-started` — have no finite reachability graph, so TLC explores the truncation the cap defines and the analyser explores nothing; they agree on that too, which is not the same as agreeing.

The three columns are worth staring at. *Distinct states* and *markings* agree because a TLA+ state and a marking were made the same object on purpose. *Generated* and *arcs* agree for a different reason, and one net nearly broke it.

## The step that should have vanished

In `order-sound`, two different transitions lead from one marking to the same marking: `ship` and `cancel` both take the order out of the same state into the same next one. It is the only such pair in all 25 nets.

A Petri net's reachability graph is **labelled**: those are two arcs, because two different things happened. TLA+'s next-state relation is not labelled: `Next` is a disjunction, and its successors are a set of states. So `order-sound` should have shown `arcs + 1 = 8` against `generated = 7`.

It shows 8 against 8. TLC counts one state generated **per disjunct it evaluates**, not per successor it keeps — the collision is counted twice and then deduplicated into `distinct`. The prediction was right by accident, and the accident is the whole difference between the two formalisms in one row: if you ask *what can happen next*, TLA+ answers with states; if you ask *what can happen*, a Petri net answers with transitions. The second question is the one lesson 7 needed to talk about starvation.

## A final marking is not a deadlock

The first run of this lesson was wrong, and wrong in a way worth keeping.

With the configuration above minus its last line, TLC stopped after **three** of `retry`'s eight markings, and after six of `pipeline-lifecycle`'s eight. It was not a bug in the translation. TLC calls a state with no successor a **deadlock** and halts there, because a TLA+ specification describes a system that goes on for ever; stuttering is allowed, stopping is not.

A Petri net has no such assumption. The final marking of a workflow net is the point of the net — lesson 10 spends its length defining soundness as *reaching* one. A dead marking is something this course computes and reports, in `ReachabilityGraph.DeadStates`, not something that aborts the run.

`CHECK_DEADLOCK FALSE` is therefore not a convenience flag. It is where the two formalisms disagree about what a system *is*: a reactive process, or a procedure with an end.

## What a place invariant proves, and what it does not

Four nets have no place invariant covering every place, and the lesson's first draft said so like this: *the four nets the invariants do not bound are the four with no finite reachability graph.*

That is false, and the test caught it. `handshake` has no such invariant and has **exactly one reachable marking**, because it is dead on arrival — its `receive` drops a token into `served` that nothing takes back, so no multiset of places is conserved and no invariant exists, yet nothing can grow because nothing can fire.

A place invariant is a **sufficient** condition for boundedness and never a necessary one. Three of the four capped nets really are unbounded. The fourth is bounded for a reason invariants cannot see.

## What a net says that a specification does not

```
  mutual-exclusion            3 place invariants,  3 minimal siphons,  3 minimal traps
  philosophers-one-fork-3     6 place invariants,  7 minimal siphons,  6 minimal traps
  readers-writers             2 place invariants,  2 minimal siphons,  2 minimal traps
```

None of these nine numbers needs a reachable state.

Take the property that `mutual-exclusion` exists to have: two threads are never in their critical sections at once. In TLA+ you write it as an invariant and TLC checks it:

```tla
AtMostOneInCritical == marking["critical1"] + marking["critical2"] =< 1
```

```
Model checking completed. No error has been found.
5 states generated, 3 distinct states found, 0 states left on queue.
```

TLC verified it by visiting all three states. The analyser never visits a state: `critical1 + critical2 + mutex = 1` is a place invariant, computed from the incidence matrix by Farkas elimination, and the property follows from it for **every** reachable marking, including the ones nobody enumerated. On three states the difference is invisible. On `Dekker-PT-020` — 11.5 million markings and 1.216 billion arcs, lesson 12 — one method still answers and the other runs out of memory at an 8 GiB heap after 158 seconds.

This is the honest summary of the comparison: a model checker decides more properties, and a net decides fewer properties without looking.

:::note[This block is not produced by check.sh]
The TLC numbers above come from a manual run on 2026-09-22: `tla2tools.jar` 2.19 from the [TLA+ releases](https://github.com/tlaplus/tlaplus) (MIT), OpenJDK 25, one worker. The jar is not vendored, so `check.sh` runs `l13` without it and the lesson's own block stops at the analyser's three columns. Twenty-five modules took 20.1 s wall clock, most of it twenty-five JVM starts; the analyser's own pass over the same 25 nets, siphons and traps included, takes 1.8 s.
:::

## Statecharts

[Statecharts](https://doi.org/10.1016/0167-6423(87)90035-9) add three things to a state machine: **hierarchy** (a state contains a machine), **orthogonality** (a state contains several machines running at once), and **broadcast** (an event fires every transition waiting for it).

Orthogonality is the one that maps cleanly. An AND-state with two regions is a product of two state machines, and a product of two state machines is what two places marked in parallel already are; the state count multiplies in both. `lane-lock-guarded` and `lane-lock-unguarded` are that shape.

Hierarchy does not map. A Petri net has no containment: to leave a composite state you draw one transition per inner state, and the drawing grows where the statechart stayed small. Broadcast does not map either — a Petri net transition consumes what it consumes, and nothing else reacts. A model with a "stop everything" event is a statechart; expressed as a net it becomes an arc from every place.

What a net keeps that a statechart gives up: **tokens are a resource count**. A statechart state is in or out. `counting-semaphore` holds two tokens in one place and needs no second region for it; the same thing in a statechart is either two orthogonal regions or an integer variable outside the formalism, and neither one leaves you with an invariant.

## Process algebras

In [CCS](https://doi.org/10.1007/3-540-10235-3) or [CSP](https://www.cs.cmu.edu/~crary/819-f09/Hoare78.pdf), composition is the primitive. You write two processes, put them in parallel, restrict the channels they share, and the behaviour is *derived* by the operational rules. There is no graph until you expand one.

A Petri net is the opposite. The structure is the primitive: places, transitions, arcs, drawn once. Composition is not an operator — you fuse places, by hand, and `Nets.Philosophers(n)` is a loop that builds arcs.

That trade shows up in everything this course does. Structural analysis needs the structure to exist before you run anything: siphons, traps, invariants and the free-choice classification of lesson 6 are all read off the arcs. In a process algebra those objects have no home — the arcs are a consequence, not a datum. Conversely, a process algebra composes: `P | Q` is a term, and you may reason about `P` alone and reuse the result. Fusing places gives no such theorem, which is exactly why lesson 12's Kanban net had to be rebuilt in full rather than assembled from four copies of one cell.

Equality differs too. Two markings are equal when they are the same function. Two processes are equal when they are **bisimilar**, which is a relation between behaviours and not between structures. Two nets with the same reachability graph up to labelling are bisimilar and are still two different nets — with different invariants, different siphons, and different verdicts from lesson 6.

## Timed automata

A [timed automaton](https://doi.org/10.1016/0304-3975(94)90010-8) has real-valued clocks, guards that compare them to constants, and resets on transitions. Its state space is not a graph of states but a graph of **zones**: sets of clock valuations, kept finite by a region construction. [UPPAAL](https://uppaal.org/) is the tool.

Lesson 9 of this course added time to a net, and added the *other* kind: a stochastic rate on each transition, which yields a continuous-time Markov chain and answers "how often" rather than "by when". The deterministic kind — a Merlin interval `[a, b]` on a transition — has no Markov chain behind it and needs a state-class construction the analyser does not have. [TINA](https://projects.laas.fr/tina/) does exactly that construction for time Petri nets.

*To verify.* Nothing in this section was run. No UPPAAL model was built, no TINA state-class graph was computed, and no number in this lesson comes from either. The claim that a time Petri net needs state classes rather than a Markov chain is the journal's open question from lesson 9, still open here.

## Where this one stops

- **Only the state space was compared.** TLC can check temporal properties under fairness — `[]<>Enabled(t) => []<>t` is what lesson 7's starvation question really asks — and none of the 25 modules declares one. The generated `.cfg` has an `INVARIANT` line and no `PROPERTY` line.
- **No PlusCal.** The modules are raw TLA+ because the net is already a transition relation; a PlusCal translation would add an algorithm nobody wrote.
- **The translation is one-way.** Nothing here reads a TLA+ module back into a net, and the hard direction is the one not done: a specification whose variables are not a marking has no net.
- **Three of the four unbounded nets are truncated, not analysed.** TLC's answer for them is a statement about the cap.

## Key takeaways

- A TLA+ state and a Petri net marking are the same object when the single variable is a function from places to naturals; everything else in the comparison follows from that choice.
- Across 22 nets with a finite state space, TLC's *distinct states*, *states generated* and *depth* equal the analyser's markings, arcs + 1 and longest-shortest-path + 1. Sixty-six numbers, no disagreement.
- TLA+ has no notion of boundedness. The cap that makes TLC terminate comes from the place invariants — structure theory feeding a model checker, not the other way round.
- TLC halts on a state with no successor and calls it a deadlock. A workflow net's final marking is that state, so the check has to be turned off; the two formalisms disagree about whether systems end.
- A place invariant proves boundedness and never disproves it: `handshake` has no invariant and one marking.
- A model checker decides more properties. A net decides fewer properties without enumerating anything, which is the only kind of answer that survives 1.2 billion arcs.

## Exercises

1. Generate `out/tla/queue_5.tla` and change `Cap` from 5 to 2 by hand. Run TLC. How many distinct states does it find, and what does that number mean about the constraint?
2. `philosophers-one-fork-3` has a deadlock. Restore `CHECK_DEADLOCK TRUE` in its `.cfg`, run TLC, and read the counterexample trace it prints. Compare it with `ReachabilityGraph.PathTo` on the dead state. Which one is easier to act on?
3. Add `AtMostOneInCritical` to `two_locks.tla` as an invariant and run TLC. Then find the place invariant that makes the same claim without enumeration, using `l5`. Which one survives replacing the two locks with ten?
4. `order-sound` is the only net whose graph has two steps between the same pair of markings. Build a net where three transitions lead from the initial marking to the same successor, and predict TLC's *states generated* before running it.

<details>
<summary>Solutions</summary>

1. **Zero.** `queue-5` starts with all five tokens in `room`, so the initial marking itself violates a cap of 2 and TLC discards it before exploring anything:

   ```
   Model checking completed. No error has been found.
   1 states generated, 0 distinct states found, 0 states left on queue.
   ```

   It checked nothing and reported success. A cap of 4 does the same. That is the answer to the exercise and the reason the cap in this lesson comes from the invariants rather than from a number somebody picked: a state constraint is not an analysis, and TLC's verdict reads identically whether it explored the whole state space or none of it. The analyser's corresponding flag, `ReachabilityGraph.IsComplete`, is false rather than absent.

2. TLC prints the shortest behaviour reaching the dead state: each step with the whole marking, in order. `PathTo` returns the transition names and nothing else. TLC's trace is easier to read; `PathTo`'s list is easier to feed back into the model, and lesson 3 uses it for exactly that. Neither tells you *why*: the reason is structural, and it is the siphon `{fork1, fork2, fork3}` emptying, which only lesson 7's `Structure.MinimalSiphons` names.

3. TLC visits four states and reports no error. `l5` prints `held1 + free1 = 1` and `held2 + free2 = 1` for `two-locks`, from which no thread holds two locks — and the invariants are computed from a 4 × 4 matrix. At ten locks the invariant computation grows like the matrix and the state space grows like 2¹⁰: the enumeration is still tractable at ten, and stops being so somewhere in the twenties, which is where lesson 12's wall starts.

4. The new net has 1 initial marking and 3 arcs out of it, so the analyser reports 3 steps; TLC reports **4 states generated, 2 distinct states found**, because it counts one generated state per disjunct evaluated and then keeps one. The gap between *generated* and *arcs + 1* stays zero, and the gap between *generated* and *distinct* is where the collisions went.

</details>

## Sources

- Leslie Lamport, *Specifying Systems*, Addison-Wesley 2002, available from the [TLA+ home page](https://lamport.azurewebsites.net/tla/book.html). The `[][Next]_v` form and the meaning of a state constraint are chapters 2 and 14.
- [The TLA+ tools](https://github.com/tlaplus/tlaplus) (MIT). `tla2tools.jar` 2.19 is what produced every TLC number above; it is not vendored here.
- David Harel, *Statecharts: A visual formalism for complex systems*, **Science of Computer Programming** 8(3), 1987, pages 231–274, [doi:10.1016/0167-6423(87)90035-9](https://doi.org/10.1016/0167-6423(87)90035-9). The record is confirmed through Crossref; the paper is behind a paywall and I have not read it, so nothing above rests on it alone — hierarchy, orthogonality and broadcast are the three features every later description agrees on. *To verify.*
- Robin Milner, *A Calculus of Communicating Systems*, **LNCS 92**, Springer 1980, [doi:10.1007/3-540-10235-3](https://doi.org/10.1007/3-540-10235-3). Same caveat. *To verify.*
- C. A. R. Hoare, *Communicating Sequential Processes*, **Communications of the ACM** 21(8), 1978, [author's copy](https://www.cs.cmu.edu/~crary/819-f09/Hoare78.pdf). This one is readable in full and is the source for the claim that composition is the primitive.
- Rajeev Alur and David Dill, *A theory of timed automata*, **Theoretical Computer Science** 126(2), 1994, [doi:10.1016/0304-3975(94)90010-8](https://doi.org/10.1016/0304-3975(94)90010-8), [author's copy](https://www.cis.upenn.edu/~alur/TCS94.pdf). Clocks, guards, resets and the region construction.
- [UPPAAL](https://uppaal.org/) and [TINA](https://projects.laas.fr/tina/), the two tools named in the timed section. Neither was run.
- Tadao Murata, *Petri nets: Properties, analysis and applications*, **Proceedings of the IEEE** 77(4), 1989, [doi:10.1109/5.24143](https://doi.org/10.1109/5.24143), for the firing rule the TLA+ module states.
