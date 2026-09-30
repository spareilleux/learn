---
title: "16. Search: A*, Monte-Carlo tree search, local search"
description: "A* and its weighted, bidirectional and Q* variants, Monte-Carlo tree search and local search against IX's ix-search, with eight predictions written before the first run, all held. Weighted A* keeps its bound and hill climbing matches Russell and Norvig on the 8 queens; IX's A* needs a consistent heuristic where its contract says admissible, its bidirectional search follows forward edges from the goal, its Q* can't tell a dead end from the right way, and its MCTS plays the opponent as a partner."
sidebar:
  order: 16
---

Search is how a program chooses among many sequences of moves: a route through a graph, a move in a game, the configuration that scores best. IX's pinned [`ix-search`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search) crate has A\* and its weighted, bidirectional and Q\* variants, breadth-first and depth-first search, minimax and alpha-beta, Monte-Carlo tree search and local search. [`ix-graph`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-graph) has Dijkstra's algorithm. This lesson runs them on small graphs traced by hand, on random mazes, on a two-move game and on the 8 queens, and checks what IX's [`CONTRACTS.md`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/CONTRACTS.md) promises.

The eight predictions this lesson tests were [written in the journal](../journal/#2026-09-30--lesson-16-predicted-before-measuring) and committed before any of its code existed. [The results](../journal/#2026-09-30--lesson-16-measured) follow them. The experiments are in [`search.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/src/search.rs), one test per prediction. [`l16_search.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/examples/l16_search.rs) prints what they measure. [`crosscheck.py`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/crosscheck/crosscheck.py) rebuilds the same mazes and boards from the course's `Rng`. It solves the mazes with SciPy's [`csgraph.shortest_path`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.sparse.csgraph.shortest_path.html) and replays hill climbing on the boards in plain Python.

## 1. A\* and the heuristic it trusts

[Hart, Nilsson and Raphael (1968)](https://doi.org/10.1109/TSSC.1968.300136)'s A\* expands, among the nodes it has reached, the one with the smallest f(n) = g(n) + h(n). Here g(n) is the cost of the best path found so far from the start, and h(n) estimates the cost left to the goal. A heuristic is *admissible* when it never overestimates, h(n) ≤ h\*(n). It is *consistent* when it never drops by more than the cost of an edge, h(n) ≤ c(n, n′) + h(n′). With h = 0, A\* is Dijkstra's algorithm: IX's `uniform_cost_search` is exactly `astar` with h = 0.

IX's `astar` keeps a closed set and never reopens a closed state ([`astar.rs` 137-148](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/astar.rs#L137-L148)). Its doc comment draws the consequence: optimality then "requires a **consistent** (monotone) heuristic, not merely an admissible one" ([`astar.rs` 71-74](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/astar.rs#L71-L74)). [`CONTRACTS.md` 9](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/CONTRACTS.md#L9) says admissible. P1 settles it on four nodes. The optimum is 5, by S, A, C, G. The heuristic h(A) = 4, 0 elsewhere, is admissible: from A the cheapest way costs 1 + 3 = 4. It is not consistent: h(A) = 4 is more than c(A, C) + h(C) = 1.

```text
== A*, S→A 1, S→C 3, A→C 1, C→G 3
  h(A) = 4, 0 elsewhere  cost 6, path S C G, 3 expansions
  h = 0                  cost 5, path S A C G, 3 expansions
  h = h*                 cost 5, path S A C G, 3 expansions
  ix-graph Dijkstra       5
```

S is expanded first. A enters the frontier with f = 1 + 4 = 5, and C with f = 3 + 0 = 3. C comes out first and is closed with g = 3. When A comes out, its path to C costs 2, but C is closed and the cheaper path is skipped, so the search ends at 6. With h = 0 or h = h\*, both consistent, A\* finds 5, and so does ix-graph's [`Graph::dijkstra`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-graph/src/graph.rs#L91-L125). That Dijkstra has no closed set: it pushes a node again whenever its distance drops, and skips the stale entries. The doc comment is right and the contract is wrong. The fix is a consistent heuristic, or reopening a closed state when a cheaper path to it turns up.

## 2. Weighted A\* on mazes

[Pohl (1970)](https://doi.org/10.1016/0004-3702(70)90007-X)'s weighted A\* orders the frontier by g + w·h with w > 1. It trusts the heuristic more, expands fewer nodes, and in exchange the path it finds can cost up to w times the optimum. [`CONTRACTS.md` 10](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/CONTRACTS.md#L10) promises that bound. Without reopening, it needs a consistent heuristic. [Chen and Sturtevant (2021)](https://doi.org/10.1609/aaai.v35i5.16485) show that consistency is necessary for a bounded best-first search that never reopens. The Manhattan distance on a grid with moves of cost 1 is consistent, so P2 expects the bound to hold. The test uses 100 mazes of 30 × 30, each cell a wall with probability 0.25, going from one corner to the other:

```text
== 100 mazes of 30 x 30, walls with probability 0.25, Manhattan h
  far corner reachable:                84
  astar None exactly when unreachable: true
  astar cost = Dijkstra's everywhere:  true
  total optimal cost:                  5046
  A*:          mean expansions 383.7
  w = 1.5      mean expansions 145.3, over the bound 0, worst cost / optimum 1.1724
  w = 2        mean expansions 140.3, over the bound 0, worst cost / optimum 1.1724
  w = 5        mean expansions 132.6, over the bound 0, worst cost / optimum 1.4138
```

In 16 mazes the walls cut the far corner off. `astar` returns `None` for exactly those 16, as [`CONTRACTS.md` 8](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/CONTRACTS.md#L8) says. In the other 84, it finds Dijkstra's cost. The cross-check finds the same 84 mazes and the same total of 5,046 moves with SciPy. No weighted path breaks its bound. The worst costs 17% more than the optimum at w = 1.5 and 2, and 41% at w = 5. Most of the saving comes from the first step above 1: w = 1.5 already expands 2.6 times fewer nodes than A\*. P2 made no claim about w = 5 against w = 2. [Wilt and Ruml (2012)](https://www.cs.unh.edu/~ruml/papers/wted-astar-socs-12.pdf) show domains where a larger weight expands more nodes. On these mazes it expands a few fewer.

On an open grid, many nodes share the same f. [`CONTRACTS.md` 29](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/CONTRACTS.md#L29) warns that those ties go in [`BinaryHeap`](https://doc.rust-lang.org/std/collections/struct.BinaryHeap.html)'s internal order. The costs above don't depend on it, but the expansion counts do.

## 3. Bidirectional A\*

A bidirectional search runs one search forward from the start and one backward from the goal, and stops once their frontiers can no longer improve the best meeting point. The backward search must follow edges in reverse, from each node to its predecessors. The doc comment of `bidirectional_astar` says so: it "Requires a `reverse_successors` function (predecessors from goal side)". But its signature takes no such function, and the backward search calls `successors()` ([`astar.rs` 255-264 and 357](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/astar.rs#L255-L357)). That is right only when every edge can be walked back at the same cost. P3 tries a directed cycle and an undirected path:

```text
== bidirectional_astar, h = 0
  directed cycle S→A→G→S: bidirectional cost 1, path S G; astar cost 2, path S A G
  path 0-1-2-3-4: bidirectional path [0, 1, 2, 3, 4], cost 4
    bidirectional actions (0, 1) (1, 2) (3, 2) (4, 3)
    astar actions         (0, 1) (1, 2) (2, 3) (3, 4)
```

On the cycle, the backward search leaves G along G→S, which is a forward edge, and reaches S at cost 1. The two searches meet at S, and the result is a path S, G of cost 1 through an edge that doesn't exist. The true answer is 2. On the undirected path the cost and the states are right, but the actions after the meeting point are the backward search's: (3, 2) where the path goes from 2 to 3. [`CONTRACTS.md` 11](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/CONTRACTS.md#L11) says that in the paths `astar` and `weighted_astar` return, `actions[i]` goes from `path[i]` to `path[i+1]`. `bidirectional_astar` returns the same `SearchResult` and documents no other meaning, but it appends the backward search's actions as they are ([`astar.rs` 396-402](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/astar.rs#L396-L402)). One more detail, read from the code and not measured here: each node the two searches push gets f = g + h(parent), the heuristic of the node it came from, not its own ([`astar.rs` 334 and 366](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/astar.rs#L334-L366)). With h = 0 that changes nothing.

## 4. Q\*: a heuristic for all the children at once

When a state has many successors, A\* spends its time generating them and calling h on each. [Agostinelli et al.](https://arxiv.org/abs/2102.04518)'s Q\* uses a network that takes a state and returns, in one call, the cost-to-go of every transition from it. Q\* can then push the children without generating them. IX's module header claims that Q\* reduces "node expansions by orders of magnitude compared to A\*" ([`qstar.rs` 1-4](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/qstar.rs#L1-L4)). But its `QFunction` maps a state to one number. `qstar_search` calls it once per expanded node and gives every child max(h(parent) − c, 0) ([`qstar.rs` 164-191](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/qstar.rs#L164-L191)). For a child reached at cost c ≤ h(parent), that makes its f the parent's own g + h, whatever the child is. P4 builds a start with one good branch and 100 dead ends, whose h of 100 says exactly that:

```text
== S→A→G and 100 dead ends S→D→X: (cost, expansions, heuristic calls)
  astar           2, 2, 103
  qstar_search    2, 102, 103
  qstar_two_head  2, 2, 103
```

A\* reads h = 100 on each dead end, pushes it at f = 101 and never expands it. Q\* pushes A and the 100 dead ends at the same f = 1, below the goal's f = 2, and must expand them all before it reaches the goal. `qstar_two_head` calls h on each successor, as A\* does, and expands 2. It doesn't even save heuristic calls here. A\* calls h once per child it pushes, Q\* once per node it expands, and Q\* expands 102 nodes to reach the goal. Without a function that scores the children of a state in one call, IX's single-head Q\* is a less-informed A\*. One more mismatch, also read and not measured: the doc comment of `qstar_bounded` describes a focal search with OPEN and FOCAL lists, and the function calls `qstar_weighted` ([`qstar.rs` 292-303](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/qstar.rs#L292-L303)).

## 5. Monte-Carlo tree search

Monte-Carlo tree search builds a game tree one path at a time. Each iteration descends from the root by UCB1, the bandit rule of [lesson 14](../14-reinforcement-learning/), which [Kocsis and Szepesvári (2006)](https://doi.org/10.1007/11871842_29) applied to trees as UCT. It adds one untried child, finishes the game with random moves, and adds the result to every node on the path. In a two-player game, each node must be scored for the player who chooses it. Otherwise the opponent's choices maximize the wrong player's result. [Browne et al. (2012)](https://doi.org/10.1109/TCIAIG.2012.2186810)'s survey backs up each reward from the viewpoint of the player who moved into the node. IX adds the same reward to every node ([`mcts.rs` 93-99](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/mcts.rs#L93-L99)), and `MctsState::reward` is 1 for "win" without saying whose ([`mcts.rs` 16-17](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/mcts.rs#L16-L17)). P5 offers the root player a sure draw B, or a gamble A where the opponent then picks the root player's win or loss:

```text
== A (the opponent picks win or loss) or B (a draw), 2000 iterations, exploration 1.41, 20 seeds
  ix mcts_search chooses A:  20 of 20
  negamax MCTS chooses B:    20 of 20
  ix minimax:                B, value 0
```

In IX's tree the opponent's node picks the child with the higher reward, which is the root player's win. So A looks worth almost 1, and IX gambles for every seed. IX's own [`minimax`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/adversarial.rs#L32-L88) takes the draw. So does `negamax_mcts` in `search.rs`, which is IX's loop with one change: each node's total is the reward r when the root player moved into it, and 1 − r when the opponent did. IX's `mcts_search` fits one-player problems, puzzles and planning, where every choice is the searcher's. IX's own test plays a two-player Nim and only checks that the move is legal.

When two children have the same visit count, [`CONTRACTS.md` 14](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/CONTRACTS.md#L14) says that the first encountered wins. [`max_by_key`](https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.max_by_key) returns the last maximum ([`mcts.rs` 102-107](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/mcts.rs#L102-L107)), as `max_by` did in lesson 14's bandits. P6 gives the root three moves to a draw and three iterations, so that each child is visited once. A log in `apply` records the order of expansion:

```text
== 3 moves to a draw, 3 iterations, 20 seeds
  mcts_search returns the last expanded child 20 times, the first 0 times
```

## 6. Local search

Local search doesn't build paths. It moves from a state to a better neighbour, and cares only about where it ends. IX's `hill_climbing` moves to the best neighbour as long as it improves. `random_restart_hill_climbing` repeats it from fresh starts, `beam_search` keeps the k best neighbours of the whole beam at each step, and `tabu_search` forbids recently visited states and keeps the best one seen. [`CONTRACTS.md` 16](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/CONTRACTS.md#L16) says that `local::hill_climb` returns the best state seen. The crate has no `hill_climb`, and the one search that can end below its best is `beam_search`. It replaces the beam by the best neighbours even when they are worse, and returns the best of the last beam ([`local.rs` 97-124](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/local.rs#L97-L124)). P7 starts every search at the top of f(x) = −(x − 10)²:

```text
== local search on -(x - 10)^2 from x = 10
  beam_search, beam 1,   1 steps: x = 11, value -1
  beam_search, beam 1,   2 steps: x = 10, value 0
  beam_search, beam 1, 101 steps: x = 11, value -1
  hill_climbing: x = 10, value 0; tabu_search: x = 10, value 0
  random_restart_hill_climbing from 3, 0 restarts: x = 3, value -inf, 1 generator calls
  random_restart_hill_climbing from 3, 5 restarts: x = 10, value 0, 6 generator calls
```

A beam of 1 leaves the optimum at the first step and comes back at the second, so an odd number of steps returns a worse state than the start. Hill climbing and tabu search keep the optimum. `random_restart_hill_climbing` generates one state before its loop and scores it −∞ ([`local.rs` 72-95](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/local.rs#L72-L95)). With 0 restarts, it returns that state with a value of −∞. With 5, it calls the generator 6 times and throws the first state away.

The 8 queens are the classic test of hill climbing. The board has one queen per column, a neighbour moves one queen within its column (56 neighbours), and h counts the pairs of queens that attack each other. [Russell and Norvig](https://aima.cs.berkeley.edu/) (section 4.1.1) report that steepest ascent from a random board "gets stuck 86% of the time, solving only 14% of problem instances", "taking just 4 steps on average when it succeeds and 3 when it gets stuck". IX's `hill_climbing` is that algorithm, except that ties go to the last best neighbour instead of a random one (P8):

```text
== 8 queens, IX's hill_climbing
  1000 random boards: solved 144 (14.4%), mean steps 4.08 when solved, 3.10 when stuck
  random_restart_hill_climbing, 20 restarts: solved 94 of 100 runs
```

IX lands on the textbook's numbers. With a success rate p = 0.144 per start, 20 independent starts succeed at least once with probability 1 − 0.856²⁰ = 0.955, and 94 runs of 100 did. The cross-check replays the same boards in Python, with the same tie-breaking. It finds the same 144 solved boards, the same mean steps and the same 94 runs.

## 7. The predictions, scored

| | Prediction, written before the first run | Measured | Verdict |
|---|---|---|---|
| P1 | h(A) = 4 (admissible, not consistent): `astar` returns 6 by S, C, G after 3 expansions; h = 0, h = h\* and Dijkstra give 5 | As predicted | Confirmed |
| P2 | 100 mazes: `astar` is `None` exactly where Dijkstra finds no path, otherwise the same cost; w = 1.5, 2, 5 stay within w times the optimum; w = 2 expands less than 0.7 times A\* | 84 reachable, all equal; 0 over the bound; 140.3 against 383.7 | Confirmed |
| P3 | Directed cycle: cost 1 and path [S, G], where A\* gives 2; path 0–4: actions (0, 1), (1, 2), (3, 2), (4, 3) | As predicted | Confirmed |
| P4 | 100 dead ends: A\* expands 2, `qstar_search` 102, `qstar_two_head` 2, all at cost 2, and Q\* makes 103 heuristic calls like A\* | As predicted | Confirmed |
| P5 | `mcts_search` takes the gamble for 20 of 20 seeds; `minimax` and a negamax MCTS take the draw | 20 of 20; B with value 0; 20 of 20 | Confirmed |
| P6 | A tie goes to the last expanded child in 20 of 20 seeds, the first in none | 20 and 0 | Confirmed |
| P7 | `beam_search` from the optimum: 11 after 1 step, 10 after 2, 11 after 101; hill climbing and tabu stay at 10; 0 restarts give −∞, 5 restarts call the generator 6 times | As predicted | Confirmed |
| P8 | 8 queens: 10–18% solved, 3–5 steps when solved, 2–4 when stuck; 20 restarts solve 85–100 of 100 | 14.4%, 4.08, 3.10; 94 | Confirmed |

All eight held on the first run, and the code compiled at the first try. No interval was changed afterwards. P1, P3, P4, P6 and P7 came from reading IX's code against its contracts and doc comments, and tracing it by hand. P2 and P8 came from published results, and IX matched them. P5 came from the textbook rule for two-player trees. Controls show that each check can fail. A consistent heuristic does find 5. `astar` does find the true cost on the cycle. A\* and the two-head Q\* do skip the dead ends. Minimax and the negamax MCTS do take the draw. Hill climbing and tabu search do keep the optimum.

## What to use for our repositories

- **IX's `astar`:** give it a consistent heuristic. The Manhattan distance on a grid and the straight-line distance on a map are consistent. A heuristic that is admissible but not consistent can return a longer path.
- **IX's `weighted_astar`:** w = 1.5 already expanded 2.6 times fewer nodes on these mazes, with every cost within its bound.
- **IX's `bidirectional_astar`:** only on graphs where every edge can be walked back at the same cost. Read `path`, not `actions`, after the meeting point.
- **IX's `qstar_search`:** not as a faster A\*. With a heuristic that sees one state at a time, use `astar`.
- **IX's `mcts_search`:** one-player problems only. For a two-player game, use `minimax` or `alpha_beta`, or an MCTS that scores each node for its player.
- **IX's `beam_search`:** keep the best state seen yourself. Call `random_restart_hill_climbing` with at least one restart.
- **IX's `hill_climbing`:** it behaves as the textbook says. Add restarts: with 20 of them, 94 of 100 runs solved the 8 queens.

## Exercises

1. Show that a consistent heuristic with h(goal) = 0 is admissible. Check that P1's heuristic is admissible but not consistent.
2. With a consistent heuristic, show that f never decreases along a path. Deduce that when A\* closes a node, its g is already optimal, so no reopening is needed.
3. In IX's `qstar_search`, show that a child reached at cost c ≤ h(parent) gets f = g(parent) + h(parent). Why can't Q\* keep P4's dead ends out of the way?
4. Hill climbing solves a random board with probability p = 0.144. How many independent starts give at least a 95% chance of one success?

<details>
<summary>Solutions</summary>

1. Take an optimal path n = n₀, n₁, …, n_k = goal. Consistency gives h(n₀) ≤ c(n₀, n₁) + h(n₁) ≤ c(n₀, n₁) + c(n₁, n₂) + h(n₂) ≤ … ≤ the path's cost + h(goal) = h\*(n). For P1: h\*(A) = 1 + 3 = 4, so h(A) = 4 is admissible, and the other values are 0. On the edge A→C, h(A) = 4 is more than c(A, C) + h(C) = 1 + 0, so it is not consistent.
2. For an edge n → n′, f(n′) = g(n) + c(n, n′) + h(n′) ≥ g(n) + h(n) = f(n), by consistency, so f never decreases along a path. Now suppose that every node closed so far had its optimal g, and that A\* is about to close n with g(n) larger than its optimum g\*(n). On an optimal path to n, take the first node m that isn't closed. Its predecessor on that path is closed with its optimal g, so m was pushed with g(m) = g\*(m). If m were n, n would already have its optimal g, so m comes before n on the path. Since f doesn't decrease along the optimal path, f(m) = g\*(m) + h(m) ≤ g\*(n) + h(n) < g(n) + h(n) = f(n). A\* would have taken m first, a contradiction.
3. The child gets g(parent) + c + max(h(parent) − c, 0), which is g(parent) + h(parent) when c ≤ h(parent). In P4, A and every D_i have f = g(S) + h(S) = 0 + 1 = 1. Their own values, 1 and 100, are only read when they are expanded, after they have been chosen. The goal, reached from A, gets f = 2, so the 101 nodes at f = 1 all come first.
4. The chance that n starts all fail is (1 − p)ⁿ, so n must satisfy 0.856ⁿ ≤ 0.05, that is n ≥ ln 0.05 / ln 0.856 = −2.996 / −0.1555 = 19.3. Twenty starts give 1 − 0.856²⁰ = 0.955, and the measurement solved 94 of 100 runs.

</details>

## Sources

- IX at pinned commit `490c395`: [`astar.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/astar.rs), [`qstar.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/qstar.rs), [`mcts.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/mcts.rs), [`local.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/local.rs), [`adversarial.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/adversarial.rs), [`CONTRACTS.md`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/CONTRACTS.md), and ix-graph's [`graph.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-graph/src/graph.rs).
- P. E. Hart, N. J. Nilsson and B. Raphael, ["A formal basis for the heuristic determination of minimum cost paths"](https://doi.org/10.1109/TSSC.1968.300136), IEEE Transactions on Systems Science and Cybernetics 4, 1968.
- I. Pohl, ["Heuristic search viewed as path finding in a graph"](https://doi.org/10.1016/0004-3702(70)90007-X), Artificial Intelligence 1, 1970.
- J. Chen and N. R. Sturtevant, ["Necessary and sufficient conditions for avoiding reopenings in best first suboptimal search with general bounding functions"](https://doi.org/10.1609/aaai.v35i5.16485), AAAI 35, 2021.
- C. Wilt and W. Ruml, ["When does weighted A\* fail?"](https://www.cs.unh.edu/~ruml/papers/wted-astar-socs-12.pdf), SoCS 2012.
- F. Agostinelli et al., ["A\* search without expansions: learning heuristic functions with deep Q-networks"](https://arxiv.org/abs/2102.04518), arXiv:2102.04518.
- L. Kocsis and C. Szepesvári, ["Bandit based Monte-Carlo planning"](https://doi.org/10.1007/11871842_29), ECML 2006.
- C. B. Browne et al., ["A survey of Monte Carlo tree search methods"](https://doi.org/10.1109/TCIAIG.2012.2186810), IEEE Transactions on Computational Intelligence and AI in Games 4, 2012.
- S. Russell and P. Norvig, [*Artificial Intelligence: A Modern Approach*](https://aima.cs.berkeley.edu/), section 4.1.1, local search on the 8 queens.
- SciPy: [`sparse.csgraph.shortest_path`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.sparse.csgraph.shortest_path.html). Rust: [`Iterator::max_by_key`](https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.max_by_key), [`BinaryHeap`](https://doc.rust-lang.org/std/collections/struct.BinaryHeap.html).
