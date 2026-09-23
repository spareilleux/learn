---
title: "9. Time and probability"
description: Rates turn the reachability graph into a continuous-time Markov chain — a queue modelled as a net and solved twice, once by the analyser and once by the textbook formula, then throughput, Little's law, and the immediate transitions of a GSPN whose vanishing states hold no time at all.
sidebar:
  order: 9
---

Full code: [`code/petri-nets`](https://github.com/spareilleux/learn/tree/main/code/petri-nets). This lesson is printed by `dotnet run --project Examples -c Release -- l9`, compared with [`expected/l9.txt`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/expected/l9.txt).

Eight lessons of this course have answered questions of the form *can this happen*. Can the buffer overflow, can the system deadlock, can the workflow finish. Those are the questions a test cannot answer, and they are worth the machinery.

They are also not the questions anyone asks first. The questions anyone asks first are *how often* and *how long*: what throughput does this hold, how many requests wait, what fraction are turned away. The nets of lessons 1 to 8 refuse all three, on purpose — a marking says where the tokens are, and the firing rule says which transitions *may* fire, never which one *will*, nor when.

This lesson adds the missing number and keeps everything else. The structure does not change, so every result of lessons 3 to 6 still holds; what changes is that each transition now carries a **rate**, and the reachability graph you already know becomes a **continuous-time Markov chain**.

## A rate is not a delay

Give each transition an exponential delay of rate λ: once enabled, it waits a random time with mean 1/λ before firing. The exponential is not an innocent choice, and it is worth being honest about why it is the one that works.

It is the only continuous distribution that is **memoryless**: a transition that has already waited three seconds is in exactly the state it was in at zero. That is what lets the future depend on the marking alone — and the marking alone is the whole reason the reachability graph is a finite object worth solving. Any other distribution would make the future depend on how long each enabled transition has already waited, which is an unbounded amount of extra state.

It is also frequently wrong. Service times in real systems are rarely exponential; a disk read is closer to constant, a retry with backoff is deliberately not memoryless. [Section "Where this stops"](#where-this-stops) says what to do then. The trade is the usual one: a distribution that is only roughly right, in exchange for an answer computed exactly rather than sampled.

## The queue, as a net

Two places and two transitions:

```
== A queue with one server and room for 5 ==
net queue-5
places      room jobs
transitions arrive serve
M0          (5, 0) = room:5
arc         room -> arrive
arc         arrive -> jobs
arc         jobs -> serve
arc         serve -> room
reachable markings: 6
```

`room` holds the free slots and `jobs` the waiting ones; an arrival takes a slot and makes a job, a service does the reverse. It is the buffer of [lesson 1](../01-why-petri-nets/) with the producer and consumer removed — and the place `room` is still the whole reason nothing overflows.

Six reachable markings, one per queue length from 0 to 5. Now the rates:

```
== The same structure, now with a rate on each transition ==
arrive: 3.0000 per unit of time
serve:  4.0000 per unit of time
load:   0.7500
```

With one arrival transition, one service transition, and exponential delays, this net **is** an M/M/1/K queue — the textbook model with Poisson arrivals, one exponential server and a waiting room of K. That matters for the next section, because M/M/1/K is one of the few models whose answer is known in closed form.

## Computed twice

The analyser builds the chain from the graph — the rate from state *i* to state *j* is the rate of the transition that joins them — and solves πQ = 0 with the probabilities summing to one. The formula computes the same distribution from ρ = λ/μ, without ever looking at the net:

```
== Stationary distribution, computed twice ==
jobs   from the net   from the formula
0      0.3041        0.3041
1      0.2281        0.2281
2      0.1711        0.1711
3      0.1283        0.1283
4      0.0962        0.0962
5      0.0722        0.0722
every state agrees within 1e-12: ok
```

Two independent routes, six agreeing numbers. That is the only reason to trust the analyser on a net whose answer is *not* known in closed form — which is every net you actually care about.

:::note[Why the check prints a verdict and not the difference]
The gap between the two columns is 5.6e-17 on my machine, and its exact digits depend on the order the machine happened to add the floating-point numbers in. Printing it would produce a line that differs between Windows, Linux and macOS and fail the comparison for a reason that has nothing to do with Petri nets. The check therefore prints a verdict against a threshold. The rule is general: compare numbers with a tolerance, and print only what you are willing to see reproduce exactly.
:::

## What the chain is worth asking

The distribution on its own is not the interesting part. These are:

```
== What the chain is worth asking ==
mean jobs in the system:   1.7009
accepted arrivals:         2.7835 per unit of time
completions:               2.7835 per unit of time
arrivals turned away:      0.0722 of the time
server busy:               0.6959 of the time
```

Read those four lines as an engineer, not as a mathematician:

- **arrivals offered 3.0 but only 2.7835 got in.** The missing 0.2165 is the 7.22 % of the time the waiting room is full. Capacity is not the same as throughput, and the net says by how much.
- **completions equal accepted arrivals**, to the last digit shown. Nothing is created or destroyed; if those two ever differed, the model would be wrong, not the system.
- **the server is busy 69.59 % of the time**, not 75 %. The naive answer ρ = 0.75 is the utilisation of a queue with *unbounded* room. Losing arrivals also loses work.

That last point is the kind of thing a load test tells you after a week of production and a model tells you before the first deploy.

## Little's law, for free

The mean time a job spends in the system is not something the chain computes directly. [Little's law](https://en.wikipedia.org/wiki/Little%27s_law) gives it: the mean number in the system equals the arrival rate times the mean time spent in it, for any stable system whatsoever — no assumption about distributions, service order or independence.

```
== Little's law, as an independent check ==
mean time in the system:   0.6111
arrivals times that time:  1.7009
mean jobs (above):         1.7009
in and out balance: ok
```

Used one way it is a measurement: 1.7009 / 2.7835 = 0.6111 units of time per job. Used the other way it is a **check on the model**, and that is how the lesson uses it — a law that holds for every stable system must hold here, so if it did not, the chain would be wrong.

You have both halves of that identity in production already: the queue depth on a dashboard and the request rate. The third number follows without instrumenting anything.

## The knife edge at load 1

Set the arrival rate equal to the service rate and the queue does not settle in the middle. It settles nowhere:

```
== Raising the load to 1 spreads the queue evenly ==
jobs   probability
0      0.1667
1      0.1667
2      0.1667
3      0.1667
4      0.1667
5      0.1667
```

Every length is equally likely. The queue is empty a sixth of the time and completely full a sixth of the time, and it drifts between the two without preference, because at ρ = 1 nothing pulls it back. A system sized "exactly at capacity" is not a system running at its limit — it is a system with no tendency at all, whose waiting room fills as readily as it empties.

That intuition is worth more than the number. It is also the reason the closed form needs a special case at ρ = 1: the geometric series that gives the other distributions has no sum there.

## A choice that takes no time

Real models have decisions that consume no time: a router picking a backend, a branch on a field, a retry limit that has been reached. Giving them a rate would be a lie — you would have to invent a duration for something instantaneous, and it would show up in the answer.

A **generalised stochastic Petri net** (GSPN) allows **immediate transitions**: they carry a weight instead of a rate, they fire the instant they are enabled, and when several compete the weights split the choice. One job, two servers, a 70/30 split:

```
== A choice that takes no time: immediate transitions ==
net two-servers
places      waiting at-fast at-slow
transitions to-fast to-slow done-fast done-slow
M0          (1, 0, 0) = waiting:1
reachable markings: 3, of which tangible: 2
the job waits (vanishing state): 0.0000 of the time
at the fast server: 0.5385
at the slow server: 0.4615
```

Three reachable markings, but only two of them **tangible**. The third — the job waiting to be routed — is **vanishing**: an immediate transition is enabled there, so the net leaves it at once and no time passes in it. Its probability is not small, it is exactly zero, and the solver removes it before solving the chain rather than letting it dilute the answer.

The two remaining numbers have an answer you can do in your head, which is why this example is here:

```
== The same two numbers by hand ==
at the fast server: 0.5385
at the slow server: 0.4615
```

Seven jobs in ten go to a server that takes half a unit of time, three in ten to one that takes a whole unit: 0.7 × 0.5 = 0.35 against 0.3 × 1 = 0.30, normalised to 0.5385 and 0.4615. The slow server holds 46 % of the jobs while receiving 30 % of them — the queue is where time is spent, not where traffic goes.

## What this costs

Nothing in this lesson enlarged the state space, and everything in it inherited the state space's problem. The chain has one equation per reachable marking, so the [state explosion of lesson 3](../03-the-reachability-graph/) is now also a linear algebra problem: a net with a million markings needs a million unknowns solved, and the dense elimination used here would need a million squared entries.

The practical consequences:

- **the analyser refuses an incomplete graph.** If the construction stopped at its limit, the missing states are not a rounding error — the probabilities would be normalised over the wrong set and every number would be quietly wrong.
- **it refuses a net with a dead marking.** A net that can stop has no stationary distribution; it has an absorbing state that eventually takes all the probability. [Lesson 4](../04-properties/) decides deadlock, and that decision comes first.
- **real tools use sparse solvers and iterative methods**, because the matrix of a Markov chain is nearly empty. The dense solver here is honest about its size: it is meant for the six states of a queue, not for six hundred thousand.

## Where this stops

Three limits, in increasing order of how often you will hit them.

**Deterministic delays break the method.** If a transition takes exactly 2 seconds rather than 2 on average, the future no longer depends on the marking alone, and there is no Markov chain to solve. **Timed Petri nets** with deterministic durations are a different and harder theory; the usual answers are a deterministic and stochastic net (DSPN, at most one deterministic transition enabled at a time), a phase-type approximation — several exponential stages in series, whose sum is much less variable than one exponential — or simulation.

**The steady state is not the story.** Everything above describes the system after it has run for a long time. Questions about the first hour, about the probability of overflowing within a day, about the distribution of a startup transient, are **transient** analysis: the same chain, integrated over time rather than solved at equilibrium.

**Means hide the tail.** This lesson computed a mean queue length and a mean waiting time. The number an SLO is written against is a percentile, and a mean says very little about a 99th percentile — two systems with the same mean can differ by an order of magnitude at the tail. The distribution over states is in hand, so tail questions about the *queue length* are answerable; tail questions about *waiting time* need the time-to-absorption machinery, or simulation.

## Key takeaways

- A rate adds *how often* and *how long* to a model that only said *whether*. The structure is untouched, so the invariants and the liveness results of the previous lessons still hold.
- The exponential is chosen because it is memoryless, and memorylessness is exactly what lets the marking be the whole state. It is a modelling assumption, not a fact about your system.
- Solve the same model twice by independent routes whenever one of them is available. The closed form of the M/M/1/K queue is worth more as a check on the analyser than as an answer.
- Little's law is free, needs no assumptions, and doubles as a test that the model balances.
- Throughput is not offered load, and utilisation is not ρ, as soon as the waiting room is finite.
- At load 1 a finite queue does not sit in the middle: every length is equally likely.
- Immediate transitions model decisions that take no time. Their states are vanishing, hold zero probability, and are eliminated before the chain is solved — giving them a fake rate would put a fake duration in the answer.
- The chain is as big as the reachability graph. Everything that made lesson 3 expensive makes this expensive too.

## Exercises

1. The queue above loses 7.22 % of its arrivals. Without running anything, say which cuts that loss more: doubling the waiting room from 5 to 10, or making the server 10 % faster. Then check with the analyser.
2. Add a second server to the queue, so two jobs can be in service at once. What changes in the net, and why does the analyser's answer stop matching `QueueFormula`?
3. The two-server example puts 46 % of the jobs at a server that receives 30 % of them. Choose the weights that split the jobs so that both servers hold them the same share of the time.
4. The lesson refuses to solve a net with a dead marking. Say what would come out if it solved it anyway, and why that answer would be useless rather than merely imprecise.

<details>
<summary>Solutions</summary>

**1.** Loss is p<sub>K</sub> = p₀ρ<sup>K</sup>, and at ρ = 0.75 each extra slot multiplies the loss by 0.75. Five extra slots multiply it by 0.75⁵ ≈ 0.237, so the loss falls from 7.22 % to roughly 1.8 % — far more than halved. Making the server 10 % faster takes ρ to 0.682, and 0.682⁵ against 0.75⁵ is about a 40 % cut, to roughly 4.3 %.

Room wins, and it wins because loss decays geometrically in the capacity but only polynomially in the rate. The general lesson is that when ρ is comfortably below 1, buffering is the cheap fix; when ρ approaches 1 the geometric decay flattens and buffering stops helping — at ρ = 1 the section above showed every length equally likely, so an extra slot buys almost nothing.

**2.** Add a place `servers` with two tokens, an arc from it into `serve` and one back out. The structure changes but the reachability graph does not grow: `servers` is bounded by a place invariant with `jobs in service`.

The formula stops applying because M/M/1/K assumes one server: with two, the service rate depends on how many jobs are present — it is 2μ when both servers are busy and μ when one is. That is an M/M/2/K queue, with a different closed form. The transition's rate in the net is a constant, so modelling two servers as "one transition, twice the rate" would be wrong at exactly the states where it matters: the ones with a single job.

This is the usual trap with rates. A rate belongs to a transition, not to a marking; if the speed depends on how many tokens are present, the tokens must be in the net.

**3.** Time at a server is share divided by rate, so equal time means w<sub>fast</sub>/2 = w<sub>slow</sub>/1, that is twice as much traffic to the fast server: weights 2 and 1, or any multiple. Then each holds exactly 0.5.

Note what this does *not* say. Splitting traffic in proportion to speed equalises the time spent at each server; it does not minimise anything in particular. Sending everything to the fast server would give a lower mean time here — routing policies are worth modelling precisely because the obvious split is rarely the best one.

**4.** The chain would converge on the dead marking: its probability would go to 1 and every other state to 0. That is not an imprecise answer, it is an answer to a different question — "where does this net end up" rather than "how does this net behave", and the second question has no answer here because the net does not keep running. The numbers would be perfectly well-formed and would describe a system that has stopped, which is why the analyser refuses rather than printing them. The same distinction bites elsewhere: a mean queue length computed over a period that includes an outage is not a smaller number, it is a number about a different system.

</details>

## Sources

- Marsan, Balbo, Conte, Donatelli, Franceschinis, *Modelling with Generalized Stochastic Petri Nets*, Wiley, 1995 — the standard reference for GSPN, vanishing states and their elimination. [Freely available from the authors' university](https://www.di.unito.it/~greatspn/GSPN-Wiley/).
- Murata, "Petri Nets: Properties, Analysis and Applications", *Proceedings of the IEEE* 77(4), 1989 — section on timed and stochastic extensions.
- Bolch, Greiner, de Meer, Trivedi, *Queueing Networks and Markov Chains*, 2nd edition, Wiley, 2006 — the M/M/1/K derivation and the numerical methods real tools use instead of the dense elimination here.
- [Little's law](https://en.wikipedia.org/wiki/Little%27s_law), and Little's own 2011 retrospective, *Little's Law as Viewed on Its 50th Anniversary*, *Operations Research* 59(3), on how little it assumes.
- [GreatSPN](https://www.di.unito.it/~greatspn/index.html) and [TimeNET](https://timenet.tu-ilmenau.de/) solve these models at a scale the analyser of this course does not attempt. Lesson 11 comes back to them.
- The implementation this lesson prints: [`Stochastic.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Stochastic.cs), with the chain, the elimination of the vanishing states and the closed form it is checked against.
