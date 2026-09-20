---
title: 5. Invariants
description: Place and transition invariants computed by Farkas elimination — a weighted count of tokens that no firing can change, the proof that the bounded buffer cannot overflow without enumerating a single marking, and an honest list of what an invariant cannot decide.
sidebar:
  order: 5
---

Full code: [`code/petri-nets`](https://github.com/spareilleux/learn/tree/main/code/petri-nets). This lesson is printed by `dotnet run --project Examples -c Release -- l5`, compared with [`expected/l5.txt`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/expected/l5.txt).

Lessons 3 and 4 answered every question by enumeration: build the reachability graph, look at all twelve markings, report. That works until it does not — the net of lesson 3 without its brake has infinitely many markings, and a net with ten philosophers has more than you want to hold in memory.

This lesson changes the question. Instead of visiting the markings and checking a property at each one, it looks at the incidence matrix and derives a statement that holds at *every* marking, reachable or not, before any marking exists. The mission promised that lesson 5 would prove the bounded buffer again "without looking at a single marking". That is what a place invariant is.

You already write these. A loop invariant is a statement that survives every iteration; an invariant of a Petri net is a statement that survives every firing. The difference is that you do not have to guess this one: it comes out of a matrix.

## The one line of algebra

Lesson 2 gave the state equation. If a marking *M* is reached from *M0* by firing each transition *x(t)* times, then

*M* = *M0* + *C x*

Take any row vector *y* of the right length and multiply both sides by it:

*y M* = *y M0* + *y C x*

Now choose *y* so that **y C = 0**. The last term vanishes whatever *x* was, and you are left with

*y M* = *y M0*

for every *M* the equation can reach — which includes every reachable marking, since every reachable marking satisfies the equation. Such a *y* is a **place invariant**, or P-semiflow when the weights are required to be non-negative. It is a weighted count of tokens that no firing can change.

That is the whole derivation, and it is worth noticing what it did *not* use: no marking, no firing order, no enabledness. The weights *y* depend on the arcs alone.

## What the producer and consumer conserves

The analyser computes them from *C* by **Farkas elimination**, the method Murata (1989, section V-B) describes: start with one row per place, tagged by a unit vector; remove one column of *C* at a time by adding together pairs of rows with opposite signs in that column; what survives are the non-negative generators. Only the ones of minimal support are kept, so that `free + full = 2` is reported rather than the infinitely many multiples and sums of it.

```
== What the producer and consumer never stops conserving ==
invariants of producer-consumer
  place invariants (3):
    ready + produced = 1
    free + full = 2
    waiting + taken = 1
  transition invariants (1):
    produce + deposit + take + consume
places: 6   rank of C: 3   dimension of the solutions of y C = 0: 3
```

Read the three of them as sentences about the system:

- `ready + produced = 1` — the producer is in exactly one of its two states. It is a boolean, and the invariant is the proof that it is one.
- `free + full = 2` — the buffer has two slots, and every slot is either free or full. Nothing creates a slot, nothing destroys one.
- `waiting + taken = 1` — the consumer, same as the producer.

The last line of the block is a sanity check on how many to expect. The solutions of *y C* = 0 form a vector space of dimension (number of places) − rank(*C*) = 6 − 3 = 3, and here the three minimal invariants happen to be a basis of it. That coincidence is not general: a net can have more minimal semiflows than the dimension of the space, because minimality is about supports and not about linear independence.

## The proof

`free + full = 2` and nothing else gives the promise of lesson 1:

```
== The proof that the buffer cannot overflow ==
invariant     free + full = 2
both counts are numbers of tokens, so free >= 0 and full >= 0
therefore     full <= 2 at every reachable marking, and at every marking at all
markings enumerated to get there: 0
checking it anyway on the graph of lesson 3: 12 markings, invariant holds in all: True
largest value of full among them: 2
```

Two facts, one line of arithmetic. `full` is at most 2 because `free` cannot be negative and the two of them add up to 2. This is a proof about a set of markings nobody listed, and it would read exactly the same if the buffer had a capacity of a million.

Compare with what lesson 3 did: twelve markings, each one built by firing, each one compared with the ones before it. For a capacity of *k*, that is 4·(*k*+1) markings — lesson 7 tabulates them — and the invariant is still one line.

The last two lines of the block are the course checking its own claim. They are not part of the proof; they are there because a proof that disagrees with the program is a proof with a mistake in it.

## Every place, three ways

The same reasoning applied to each place gives a bound without a graph: if an invariant *y* covers *p*, then *y(p)·M(p)* is at most *y M0*, so *M(p)* is at most *y M0 / y(p)*. The analyser takes the smallest such bound over all the invariants:

```
== The bound of every place, three ways ==
bounds of producer-consumer
place     invariants              coverability tree   reachability graph
ready     1                       1                   1
produced  1                       1                   1
free      2                       2                   2
full      2                       2                   2
waiting   1                       1                   1
taken     1                       1                   1
  markings enumerated: 0 for the invariants, 12 for the graph
```

Three methods, same six numbers, and the left column paid nothing for them.

Now remove the place `free`, as lesson 3 did, and ask again:

```
== The same table on the net with the brake removed ==
invariants of unbounded-producer
  place invariants (2):
    ready + produced = 1
    waiting + taken = 1
  transition invariants (1):
    produce + deposit + take + consume
bounds of unbounded-producer
place     invariants              coverability tree   reachability graph
ready     1                       1                   still growing at 500
produced  1                       1                   still growing at 500
full      not covered             unbounded           still growing at 500
waiting   1                       1                   still growing at 500
taken     1                       1                   still growing at 500
  markings enumerated: 0 for the invariants, 500 for the graph
```

The invariant that bounded the buffer is gone, and the place it bounded is the one that grows. That is the same fact lesson 1 told you in pictures — the *absence* of a place is what made the queue unbounded — now stated as the absence of a conservation law.

:::caution[What "not covered" does not mean]
`not covered` says the analyser found no place invariant giving `full` a weight. It does **not** say the place is unbounded. There are bounded nets whose bound no P-semiflow can express; structural boundedness is characterised by a different condition (a positive vector *y* with *y C* ≤ 0, not *y C* = 0), and even that is about every initial marking rather than this one. Here the coverability tree of lesson 3, which is a decision procedure, is what proves `full` unbounded. The invariant only failed to prove the opposite.
:::

## What an invariant cannot do

An invariant is a consequence of the state equation. So it inherits the weakness lesson 2 spent a section on: everything the equation accepts, the invariants accept too.

```
== An invariant cannot exclude what the state equation accepts ==
invariants of handshake
  place invariants (1):
    request + response = 0
  transition invariants (0):
spurious marking (0, 0, 1)  served:1  satisfies every place invariant: True
spurious marking (0, 0, 2)  served:2  satisfies every place invariant: True
```

The two markings the handshake cannot reach satisfy its invariant perfectly. No set of place invariants will ever exclude a spurious marking, because place invariants are strictly weaker than the equation that produced them, and the equation is already strictly weaker than reachability. If lesson 2 left you hoping that invariants would close that gap, they do not — lesson 6 is where the gap starts to close, with siphons and traps.

The second limitation matters more in practice: **invariants prove safety, never liveness.** Here are the four invariants of the deadlocking net of lesson 4:

```
== What invariants do not see: the deadlock of two locks ==
invariants of two-locks
  place invariants (4):
    a_idle + a_has_x = 1
    a_has_x + x = 1
    b_idle + b_has_y = 1
    b_has_y + y = 1
  transition invariants (2):
    a_take_x + a_take_y
    b_take_y + b_take_x
dead marking (0, 1, 0, 1, 0, 0)  a_has_x:1 b_has_y:1
every place invariant above holds there too: True
```

All four are true at the deadlock. They have to be — they are true everywhere, and the deadlock is a marking like any other. An invariant can tell you "this bad marking is impossible" when the marking violates the count; it can never tell you "this reachable marking is bad", because badness here is about what the net *cannot do next*, and a conserved count says nothing about the future.

`a_has_x + x = 1` is the useful reading of that block: the lock `x` is either held by A or free, never both, never neither. That *is* worth proving, and it is exactly the kind of statement invariants are for.

## Transition invariants

Transpose the question. A **transition invariant**, or T-semiflow, is a non-negative integer vector *x* with **C x = 0**: a multiset of firings whose net effect on the marking is nothing.

```
== Transition invariants: the firings that cancel out ==
x = (1, 1, 1, 1)   produce + deposit + take + consume
firing it once from M0 gives (1, 0, 2, 0, 1, 0), back to (1, 0, 2, 0, 1, 0): True
```

One round trip through the system leaves it exactly as it was. That is the definition of a cycle in the thing being modelled — a request served, a message consumed, a lock taken and released.

The catch is the one lesson 2 already taught about the state equation, in the other direction: *C x* = 0 says the arithmetic cancels, not that any order of those firings can actually run.

```
two locks has two of them, and a marking from which neither can be fired at all:
  x = (1, 1, 0, 0)   a_take_x + a_take_y
  x = (0, 0, 1, 1)   b_take_y + b_take_x
  transitions enabled at the dead marking: (nothing)
```

Both T-invariants exist, both describe a perfectly sensible round trip — take both locks, release both locks — and from the deadlock neither of them can start.

The interesting case is the opposite one:

```
the handshake has none at all, and that is a statement about its runs:
  transition invariants of handshake: 0
  transition invariants of handshake-started: 0
  a marking it can reach twice: False
  a marking the producer and consumer can reach twice: True
```

The handshake has **no** transition invariant, and that is a real statement about its behaviour: no non-empty sequence of firings can bring the net back to a marking it has already been in, because every `receive` drops a token in `served` and nothing takes it out. A net with no T-invariant has no cycle in its reachability graph at all. The analyser checks that directly on the 500-marking prefix of `handshake-started`: it found no marking reachable twice, while the producer and consumer has plenty.

That one needs no theorem to believe. If a net is reversible and can fire at all, then some non-empty sequence brings it back to *M0*; the vector counting those firings is non-negative, non-zero, and satisfies *C x* = 0. So it is a transition invariant. Turn it round: **no transition invariant, no return**. It is the only liveness-adjacent fact this lesson gets for free, and lesson 6 is where the rest of it comes from.

## Key takeaways

- A **place invariant** is a vector *y* with *y C* = 0. Then *y M* = *y M0* at every marking the state equation can reach, and so at every reachable marking. It is a loop invariant you do not have to guess.
- `free + full = 2` plus "token counts are not negative" proves the buffer cannot overflow, **with zero markings enumerated**, and the proof does not grow with the capacity.
- Place invariants give **bounds** for free: *M(p)* ≤ *y M0 / y(p)*. A place no invariant covers is a place with no proof, not a place proved unbounded.
- Invariants are **consequences of the state equation**, so they accept every spurious marking. They prove safety properties and never liveness ones: all four invariants of `two-locks` hold at its deadlock.
- A **transition invariant** is a vector *x* with *C x* = 0: firings that cancel out. It does not promise the sequence can fire. Having none at all, as the handshake does, proves the net can never return to a marking it has left.
- Both are computed by **Farkas elimination** on *C*, in [`Invariants.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Invariants.cs), without building anything.

## Exercises

1. The mutual exclusion net has the invariant `critical1 + critical2 + mutex = 1`. Write, in one sentence and without mentioning Petri nets, the property of the C# program this proves. Then say which line of the program would have to change for the invariant to become `= 2`, and what would break.
2. The readers and writers net of lesson 7 has two place invariants. One of them is `reading + 3*writing + access = 3`. What does it prove about the number of writers, and why does the weight 3 appear?
3. A net models a workflow: it starts with one token in `start` and should end with one token in `end`. Someone claims "the invariant `start + working + end = 1` proves the workflow terminates". Say precisely what it does prove and what it does not.
4. Take the `emit-loop` net of lesson 3 — one transition that gives its input token back and fills two places. Predict its place invariants before running the analyser, then check.

<details>
<summary>Solutions</summary>

**1.** "At most one thread is inside the critical section at any time, and the lock is free exactly when neither is." The `mutex` place is the lock object; `= 1` is the fact that there is one of it. To make it `= 2` you would put two tokens in `mutex` at the start, which in code is replacing `lock (gate)` by `new SemaphoreSlim(2)`. What breaks is whatever the critical section protects: two threads would be inside at once, which is the point of the count being 1. Lesson 7 builds exactly that net and measures it.

**2.** It proves `writing` is at most 1: since `reading` and `access` cannot be negative, 3·`writing` is at most 3. The weight 3 appears because `start_write` takes all three permits from `access` through an arc of weight 3 — the invariant has to give a writer the weight of what it consumes, which is exactly what makes "one writer excludes three readers" arithmetic rather than a rule someone remembered to enforce.

**3.** It proves that the workflow is in exactly one of the three states at any time, and therefore that it never runs twice at once and never silently disappears. It proves **nothing** about termination: the marking `working = 1` satisfies the invariant for ever, and a net that sits there is a workflow that hangs. Termination is a liveness property; lesson 10 defines it properly as part of soundness, and it needs the reachability graph or a structural theorem, not an invariant.

**4.** There are none whose support contains `log` or `queue`, because `emit` only ever adds to them: any *y* with *y C* = 0 must have *y(log)* = *y(queue)* = 0. The one invariant is over `ready` alone — `emit` takes a token from `ready` and puts it straight back, so the column of *C* is zero there, and `ready = 1` is conserved. Two of the three places have no conservation law, and those are exactly the two the coverability tree of lesson 3 marked ω.

</details>

## Sources

- Tadao Murata, *Petri nets: Properties, analysis and applications*, **Proceedings of the IEEE** 77(4), April 1989, pages 541–580, [doi:10.1109/5.24143](https://doi.org/10.1109/5.24143). Section V-B is the reference for place and transition invariants and for the Farkas elimination used here. The record is confirmed through Crossref; the paper is behind the IEEE paywall and I have not read it, so nothing in this lesson rests on it alone — everything above is either derived in the text or printed by the analyser. *To verify.*
- Wolfgang Reisig, *Understanding Petri Nets*, Springer, 2013, [doi:10.1007/978-3-642-33278-4](https://doi.org/10.1007/978-3-642-33278-4), for place invariants presented as the primary proof technique rather than as an afterthought. *To verify* — record checked, book not read.
- The implementation this lesson prints: [`Invariants.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Invariants.cs), with the unit tests that check every invariant against every reachable marking in [`PetriNetTests.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/Tests/PetriNetTests.cs).
