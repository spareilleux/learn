---
title: 6. Structural classes
description: State machines, marked graphs and free-choice nets — three shapes of net that come with theorems, the circuits and siphons and traps those theorems are stated in, a liveness decided on a net whose reachability graph is infinite, and the honest reason most real models fall outside all three classes.
sidebar:
  order: 6
---

Full code: [`code/petri-nets`](https://github.com/spareilleux/learn/tree/main/code/petri-nets). This lesson is printed by `dotnet run --project Examples -c Release -- l6`, compared with [`expected/l6.txt`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/expected/l6.txt).

Lesson 5 proved things from the incidence matrix. This lesson proves things from the *shape* of the net — from which places feed which transitions, before any weights, any tokens, any firing.

The reason to care is blunt: for three particular shapes, somebody has already done the hard work. If your net is one of them, a property that costs a reachability graph in general costs an inspection of the arcs. If your net is not one of them, you should know that too, because it tells you which theorem you are not allowed to use.

Two pieces of notation, used everywhere below and in [`Structure.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Structure.cs):

- **•t** is the set of places transition *t* takes from, and **t•** the set it puts into;
- **•p** is the set of transitions that fill place *p*, and **p•** the set that empty it.

## The three shapes

| class | condition | what it forbids |
|---|---|---|
| **state machine** | every transition has exactly one input and one output place | any transition that synchronises or forks |
| **marked graph** | every place has exactly one input and one output transition | any place two transitions compete for |
| **free-choice net** | if two places share an output transition, each of them has exactly that one output | a choice whose outcome depends on somebody else's tokens |

A state machine is the thing you were drawing before you met Petri nets: one token walking around a graph of states. It can branch, it cannot fork — nothing in it ever produces two tokens.

A marked graph is the dual: it can fork and synchronise, and it has no choice at all. Every place has one producer and one consumer, so no two transitions ever compete.

A free-choice net allows both, as long as choice and synchronisation never touch the same place. When `p` feeds `t1` and `t2`, the decision between them is free — nothing else in the net can make one of them impossible while leaving the other enabled.

Here is where the nets of this course fall, with the classes decided on the arcs alone:

```
== Where the nets of this course sit ==
net                 state machine  marked graph  free choice  ext. free choice  asym. choice  strongly conn.
producer-consumer   no             yes           yes          yes               yes           yes
unbounded-producer  no             yes           yes          yes               yes           no
connection          yes            no            yes          yes               yes           yes
start-once          yes            no            yes          yes               yes           no
handshake           no             no            yes          yes               yes           no
mutual-exclusion    no             no            no           no                yes           yes
two-locks           no             no            no           no                yes           yes
readers-writers     no             no            no           no                no            yes
philosophers-3      no             no            no           no                no            yes
```

The last two columns are the weaker relatives. **Extended free choice** asks that two places sharing an output transition share *all* of them; **asymmetric choice** (also called a simple net) asks only that one of the two sets of output transitions contains the other. Each class contains the one before it, and the table shows the ladder working: the lock is asymmetric-choice, the philosophers are not even that.

Read the bottom four rows before the top five. Everything in this course that models a shared resource is outside the free-choice class, and that is not an accident — the last section of this lesson says why.

## Marked graphs: count the tokens on each circuit

The producer and consumer is a marked graph: `free` is filled only by `take` and emptied only by `deposit`, and every other place is the same.

```
== A marked graph: the producer and consumer ==
structure of producer-consumer
  ordinary (every arc weight 1):  yes
  pure (no self-loop):            yes
  strongly connected:             yes
  state machine:                  no
  marked graph:                   yes
  free choice:                    yes
  extended free choice:           yes
  asymmetric choice:              yes
circuits of producer-consumer: 3 circuits
  {ready, produced}  tokens at M0: 1
  {free, full}  tokens at M0: 2
  {waiting, taken}  tokens at M0: 1
marked graph theorem  live: True   safe: False   markings enumerated: 0
reachability graph    live: True   safe: False   markings enumerated: 12
```

Stop at those three circuits and compare them with lesson 5:

```
ready + produced = 1
free + full = 2
waiting + taken = 1
```

They are the same three sets with the same three numbers. In a marked graph the tokens on a circuit can never change — every transition on the circuit takes one token from the place before it and puts one into the place after it — so **each circuit is a place invariant**, and the number of tokens on it is the constant. The analyser's unit tests check that correspondence on this net. Lesson 5's algebra and this lesson's geometry are, here, two descriptions of one fact.

Two theorems then fall out, both from Commoner, Holt, Even and Pnueli's *Marked directed graphs* ([JCSS 5(5), 1971](https://doi.org/10.1016/S0022-0000(71)80013-2)):

- a marked graph is **live** exactly when every directed circuit carries at least one token;
- a live marked graph is **safe** exactly when every place lies on a circuit carrying exactly one token.

Both are easy to believe from the invariant: a circuit with no token is a set of conditions none of which can ever become true, and the circuit through a place caps how many tokens that place can hold. The analyser applies them and then checks the answers against the reachability graph — `live: True  safe: False` both ways, twelve markings on one side and none on the other. `free` and `full` are on a circuit with two tokens, which is exactly why the net is 2-bounded and not safe.

This is the first time in the course that a liveness question has been answered without enumeration.

## State machines: one token, and can you get back

```
== A state machine that is live, and one that is not ==
net connection
places      disconnected connecting connected
transitions open established failed close
M0          (1, 0, 0) = disconnected:1
arc         disconnected -> open
arc         open -> connecting
arc         connecting -> established
arc         established -> connected
arc         connecting -> failed
arc         failed -> disconnected
arc         connected -> close
arc         close -> disconnected
structure of connection
  ordinary (every arc weight 1):  yes
  pure (no self-loop):            yes
  strongly connected:             yes
  state machine:                  yes
  marked graph:                   no
  free choice:                    yes
  extended free choice:           yes
  asymmetric choice:              yes
state machine theorem  strongly connected: True   tokens at M0: 1
                       live: True   safe: True
reachability graph     live: True   safe: True   markings enumerated: 3
```

`connection` is `disconnected → connecting → connected → disconnected`, with a `failed` branch back from `connecting`. It is the state machine you would have drawn anyway, and for that shape the rule is short: a state machine is live when it is strongly connected and holds at least one token, and safe when it holds at most one. The total number of tokens never changes, because every transition takes one and gives one.

`start-once` is the counterexample lesson 4 already used, and now the reason is structural rather than behavioural:

```
net start-once
places      stopped running serving
transitions start accept finish
M0          (1, 0, 0) = stopped:1
arc         stopped -> start
arc         start -> running
arc         running -> accept
arc         accept -> serving
arc         serving -> finish
arc         finish -> running
structure of start-once
  ...
  strongly connected:             no
  state machine:                  yes
state machine theorem  strongly connected: False   tokens at M0: 1
                       live: False   safe: True
reachability graph     live: False   safe: True   markings enumerated: 3
```

Nothing leads back to `stopped`. One glance at the arcs settles it, and lesson 4 needed the whole graph to say the same thing.

## Siphons and traps

For the free-choice class the theorem is stated in two ideas that are worth having even when your net is in no class at all.

A **siphon** is a set *S* of places with **•S ⊆ S•**: every transition that puts a token into *S* also takes one out of it.

A **trap** is a set *S* with **S• ⊆ •S**: every transition that takes a token out of *S* also puts one back in.

Each has a one-line proof attached, for ordinary nets — nets where every arc has weight 1:

- **A siphon that is empty stays empty.** Suppose *S* holds nothing and some *t* fires putting a token into *S*. Then *t* ∈ •S ⊆ S•, so *t* also takes a token from some place of *S* — which holds none, so *t* was not enabled. Contradiction.
- **A trap that holds a token keeps holding one.** Suppose *S* holds a token and *t* fires. If *t* takes nothing from *S*, the count cannot drop. If it does, then *t* ∈ S• ⊆ •S, so *t* also puts a token into some place of *S*, and *S* is marked again straight away.

A siphon is a way for a system to die; a trap is a way for it to stay alive. That is why these are the two notions liveness theorems are written in, and it is worth being precise about which is which: it is the **trap** that has to be marked, never the siphon.

Now the consequence that needs no class at all, and whose proof fits in three lines:

:::note[Every dead marking empties a siphon]
Let *M* be a dead marking of an ordinary net and let *D* be the set of places holding nothing at *M*. Take any *t* that puts a token into *D*. Since *M* is dead, *t* is not enabled, so one of its input places holds nothing — that place is in *D*, so *t* takes from *D*. Hence •D ⊆ D•: *D* is a siphon.

Turn it round and you get a sufficient condition for **deadlock-freedom** in any ordinary net: if every siphon contains a trap that is marked at *M0*, there is no dead marking. A dead marking would give an empty siphon *D*; *D* contains a marked trap; that trap still holds a token, and it is inside *D*, which holds none.
:::

The analyser verifies the first half on the deadlocking net of lesson 4:

```
== Every dead marking empties a siphon ==
dead marking (0, 1, 0, 1, 0, 0)  a_has_x:1 b_has_y:1
  places holding nothing: {a_idle, b_idle, x, y}
  that set is a siphon: True
  largest trap inside it: {}
```

And the structural cause is one of its five minimal siphons:

```
siphons of two-locks: 5 minimal siphons
  siphon {a_idle, a_has_x}
    largest trap inside it: {a_idle, a_has_x}  marked at M0: yes
  siphon {b_idle, b_has_y}
    largest trap inside it: {b_idle, b_has_y}  marked at M0: yes
  siphon {a_has_x, x}
    largest trap inside it: {a_has_x, x}  marked at M0: yes
  siphon {b_has_y, y}
    largest trap inside it: {b_has_y, y}  marked at M0: yes
  siphon {x, y}
    largest trap inside it: {}  marked at M0: no
  every siphon contains a marked trap: no
  minimal traps: {a_idle, a_has_x} {b_idle, b_has_y} {a_has_x, x} {b_has_y, y}
```

`{x, y}`, the two locks together, is a siphon containing no trap at all. Both locks can be taken and neither has to come back, and once that set is empty it is empty for ever. The deadlock of lesson 4 was a picture; this is its cause, found without firing anything.

## Commoner's theorem, and what it buys

For free-choice nets the sufficient condition becomes an exact characterisation. The result is stated in Michel Hack's 1972 master's thesis and attributed there to Frederic Commoner:

> A free-choice net is live if and only if every siphon contains a marked trap.

The analyser applies it to the free-choice nets of the course and puts the reachability graph's verdict next to it:

```
== Free choice, siphons and traps ==
siphons of producer-consumer: 3 minimal siphons
  siphon {ready, produced}
    largest trap inside it: {ready, produced}  marked at M0: yes
  siphon {free, full}
    largest trap inside it: {free, full}  marked at M0: yes
  siphon {waiting, taken}
    largest trap inside it: {waiting, taken}  marked at M0: yes
  every siphon contains a marked trap: yes
  minimal traps: {ready, produced} {free, full} {waiting, taken}
free choice: True   every siphon contains a marked trap: True
Commoner therefore says live: True
the reachability graph says live: True

siphons of start-once: 1 minimal siphon
  siphon {stopped}
    largest trap inside it: {}  marked at M0: no
  every siphon contains a marked trap: no
  minimal traps: {running, serving}
free choice: True   every siphon contains a marked trap: False
Commoner therefore says live: False
the reachability graph says live: False

siphons of handshake: 1 minimal siphon
  siphon {request, response}
    largest trap inside it: {request, response}  marked at M0: no
  every siphon contains a marked trap: no
  minimal traps: {served} {request, response}
free choice: True   every siphon contains a marked trap: False
Commoner therefore says live: False
the reachability graph says live: False
```

`start-once` is worth a second look, because it is the case where the wording matters. The siphon `{stopped}` **is** marked at *M0* — the service starts out stopped. What it does not contain is a *trap*: once `start` has fired, nothing ever puts a token back into `stopped`, so the siphon empties and stays empty, and `start` is dead for the rest of time. A siphon being marked now means nothing. A marked trap inside it is the promise.

The handshake is the other shape of failure: there the siphon `{request, response}` is also a trap, and it holds nothing from the start. A net that begins with an empty trap has already lost.

Now the payoff. Put one token in `request` and the same structure becomes live — and the net becomes unbounded, because `served` counts the completed exchanges for ever:

```
== A liveness decided where no reachability graph exists ==
net handshake-started
places      request response served
transitions receive reply
M0          (1, 0, 0) = request:1
siphons of handshake-started: 1 minimal siphon
  siphon {request, response}
    largest trap inside it: {request, response}  marked at M0: yes
  every siphon contains a marked trap: yes
  minimal traps: {served} {request, response}
free choice: True
every siphon contains a marked trap: True
Commoner: live
the graph cannot say so: bounded: False, dead transitions: none
reachability graph stopped after 500 markings, complete: False
```

The reachability graph gave up at 500 markings and would have gone on for ever. The coverability tree of lesson 3 can say the net is unbounded and that no transition is dead, and that is all it can say — ω threw away the counts liveness needs. The structure answered the question anyway. That is what these classes are for.

## Where the classes stop

Every net in this course that models a shared resource is outside the free-choice class, and the analyser says exactly where:

```
== Where the classes stop: the place two transitions fight over ==
mutual-exclusion   free choice: False, extended: False, asymmetric: True
  mutex feeds enter1 and enter2, which do not read the same places
two-locks          free choice: False, extended: False, asymmetric: True
  x feeds a_take_x and b_take_x, which do not read the same places
  y feeds a_take_y and b_take_y, which do not read the same places
philosophers-3     free choice: False, extended: False, asymmetric: False
  fork1 feeds take1 and take3, which do not read the same places
  fork2 feeds take1 and take2, which do not read the same places
  fork3 feeds take2 and take3, which do not read the same places
```

The pattern is the same every time. `mutex` offers a choice between `enter1` and `enter2`, but the choice is not free: whether `enter1` can take the token depends on `idle1`, which has nothing to do with `mutex`. That is precisely what free choice forbids, and it is precisely what a lock *is*. The philosophers fall out of the asymmetric-choice class too, because in a ring each fork is contended by two neighbours whose other inputs are unrelated in both directions.

So the honest summary of this lesson is a warning as much as a tool: the theorems are sharp and the class that carries the sharpest of them excludes mutual exclusion, lock ordering and the dining philosophers — three of the four things a concurrent program actually does. What survives outside the class is the one-way implication proved above (a marked trap in every siphon means no deadlock), which holds for any ordinary net and is what lesson 7 leans on.

:::caution[The cost of finding a siphon]
[`Structure.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Structure.cs) finds minimal siphons by trying every subset of places. That is exact, it is fine on nets of twenty places, and it is exponential. Deciding whether a net has a siphon with a given property is NP-hard in general, and real tools use constraint solvers rather than enumeration. The three philosophers of lesson 7 have 4 096 subsets; six philosophers would have 16 million.
:::

## Key takeaways

- A **state machine** has one input and one output place per transition. It is live when strongly connected with at least one token, safe when it has at most one.
- A **marked graph** has one input and one output transition per place. Its circuits are its place invariants; it is live when every circuit carries a token, and a live one is safe when every place lies on a circuit carrying exactly one.
- A **free-choice net** never mixes choice with synchronisation. Commoner's theorem makes liveness exactly "every siphon contains a marked trap".
- A **siphon** that empties stays empty; a **trap** that is marked stays marked. Both proofs are one line, for ordinary nets.
- **Every dead marking empties a siphon**, in any ordinary net. So a marked trap inside every siphon proves deadlock-freedom, whatever class the net is in.
- The classes were all decided **from the arcs**, with no marking enumerated; `handshake-started` is declared live although its reachability graph is infinite.
- Mutual exclusion, lock ordering and the philosophers are **outside** the free-choice class. Sharing a resource is exactly what breaks it.

## Exercises

1. `two-locks-ordered` — both threads taking `x` before `y` — was shown deadlock-free in lesson 4 by enumeration. Predict what its minimal siphons look like and whether each contains a marked trap, then check with the analyser.
2. The producer and consumer is both a marked graph and a free-choice net. Is that a coincidence? Prove or disprove: every marked graph is a free-choice net.
3. Take `connection` and delete the transition `failed`. Which of the two hypotheses of the state machine theorem breaks, and what happens to the net?
4. The `handshake` net has `{served}` among its minimal traps. Explain why a place with no outgoing arc is always a trap, and why that fact is useless.

<details>
<summary>Solutions</summary>

**1.** The analyser prints this, and it is worth checking your prediction against the first line, because mine was wrong:

```
== Exercise 1: the same net with both threads taking x first ==
siphons of two-locks-ordered: 4 minimal siphons
  siphon {y}
    largest trap inside it: {y}  marked at M0: yes
  siphon {a_idle, a_has_x}
    largest trap inside it: {a_idle, a_has_x}  marked at M0: yes
  siphon {b_idle, b_has_x}
    largest trap inside it: {b_idle, b_has_x}  marked at M0: yes
  siphon {a_has_x, b_has_x, x}
    largest trap inside it: {a_has_x, b_has_x, x}  marked at M0: yes
  every siphon contains a marked trap: yes
  minimal traps: {y} {a_idle, a_has_x} {b_idle, b_has_x} {a_has_x, b_has_x, x}
free choice: False
deadlock-free by the graph: True
```

I expected `{x, y}` to still appear, with a marked trap added to it. It does not appear at all. In the ordered net, `y` on its own is a siphon — it is filled and emptied by the same two transitions — and it is also a trap holding a token, so `{x, y}` is no longer *minimal*. The set that carries `x` is `{a_has_x, b_has_x, x}`: the lock is either free or held by one of the two threads, and every way of taking it puts it somewhere in that set. Both are traps, both are marked, every siphon contains a marked trap, and by the implication proved above that is a proof of deadlock-freedom needing no reachability graph. Lesson 4 got the same answer with one. Note the last two lines: the net is *not* free-choice, so this is the one-way implication only — the condition holding proves deadlock-freedom, and would not have proved liveness.

**2.** Not a coincidence: **every marked graph is a free-choice net**, and the proof is immediate. Free choice can only be violated when two places share an output transition while one of them has another output too. In a marked graph every place has exactly one output transition, so if `p1` and `p2` share one, both have exactly that one — which is the free-choice condition satisfied. The converse fails: `connection` is free-choice and not a marked graph, since `disconnected` has two input transitions.

**3.** Strong connectivity breaks: without `failed`, the only way out of `connecting` is `established`, and there is still a path back, so in fact the net stays strongly connected — `connecting → established → connected → close → disconnected → open → connecting`. Delete `close` instead and you cut the only return from `connected`, the net stops being strongly connected, and it degenerates into `start-once`: a connection that opens and can never be reopened. The exercise is really about noticing which arc is the return path.

**4.** A place `p` with `p•` empty satisfies `p• ⊆ •p` for the trivial reason that the empty set is a subset of anything, so `{p}` is a trap. It is useless because it is marked only if it already holds a token, and being marked forever is not interesting for a place nothing reads: it is a counter, not a condition. The traps that matter in Commoner's theorem are the ones *inside a siphon*, and a sink place is in no siphon — `•{p}` is non-empty while `{p}•` is empty, so `{p}` cannot satisfy the siphon condition.

</details>

## Sources

- Frederic Commoner, Anatol W. Holt, Shimon Even and Amir Pnueli, *Marked directed graphs*, **Journal of Computer and System Sciences** 5(5), October 1971, pages 511–523, [doi:10.1016/S0022-0000(71)80013-2](https://doi.org/10.1016/S0022-0000(71)80013-2). The liveness and safeness theorems for marked graphs. Record confirmed through Crossref; the article is behind the Elsevier paywall and I have not read it. *To verify.*
- Michel Hack, *Analysis of production schemata by Petri nets*, MS thesis, MIT, February 1972, published as Project MAC technical report MAC-TR-94 / MIT-LCS-TR-094, [handle 1721.1/149406](https://dspace.mit.edu/handle/1721.1/149406). This is where Commoner's liveness theorem for free-choice nets is stated. The record and the open-access PDF are confirmed on DSpace@MIT, but the download is behind a bot check that refused my fetches, so **I have not read the thesis** and the wording above is taken from secondary sources. *To verify.* What this lesson does assert on its own evidence is narrower and checked: on the four free-choice nets here, the condition and the reachability graph agree, and the unit tests fail if they ever stop agreeing.
- Jörg Desel and Javier Esparza, *Free Choice Petri Nets*, Cambridge Tracts in Theoretical Computer Science 40, Cambridge University Press, 1995, [doi:10.1017/CBO9780511526558](https://doi.org/10.1017/CBO9780511526558). The monograph on the class. Record confirmed at Cambridge Core; not read. *To verify.*
- Tadao Murata, *Petri nets: Properties, analysis and applications*, **Proceedings of the IEEE** 77(4), April 1989, pages 541–580, [doi:10.1109/5.24143](https://doi.org/10.1109/5.24143), sections II-B and IV for the classes and for siphons and traps. Paywalled and not read. *To verify.*
- The implementation: [`Structure.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Structure.cs).
