---
title: "14. Reinforcement learning: bandits and Q-learning"
description: "Bandits, Q-learning and SARSA against IX's ix-rl, with eight predictions written before the first run: seven held and one held in part. The learners behave as the textbooks say; IX's contracts get the tie-break wrong, its Agent trait reads the wrong row and never learns, and its Thompson sampling assumes rewards of variance 1."
sidebar:
  order: 14
---

Every lesson so far learned from a data set someone else collected. Reinforcement learning collects its own: an agent chooses an action, the world answers with a reward, and the next choice uses what the rewards taught. IX's pinned [`ix-rl`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl) crate has the two classic families. Multi-armed bandits (`EpsilonGreedy`, `UCB1`, `ThompsonSampling`) repeat one choice. Tabular Q-learning and SARSA act on a `GridWorld`, where each choice moves the agent to another state. This lesson reproduces two experiments of [Sutton and Barto](http://incompleteideas.net/book/the-book-2nd.html) with IX's learners, measures regret against the bound of Auer et al., and checks what IX's [`CONTRACTS.md`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/CONTRACTS.md) promises.

The eight predictions this lesson tests were [written in the journal](../journal/#2026-09-30--lesson-14-predicted-before-measuring) and committed before any of its code existed. [The results](../journal/#2026-09-30--lesson-14-measured) follow them. The experiments are in [`rl.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/src/rl.rs), one test per prediction. [`l14_reinforcement.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/examples/l14_reinforcement.rs) prints what they measure. [`crosscheck.py`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/crosscheck/crosscheck.py) recomputes the value iteration, the testbed's arms and the regret bound with [numpy](https://numpy.org/doc/stable/).

## 1. Bandits, by hand

A bandit has k arms. Arm a pays a random reward whose mean μₐ the learner doesn't know. Pulling the best arm every time would earn μ\* per step; each pull of arm a instead loses Δₐ = μ\* − μₐ. The regret after T pulls is the sum of the Δ of the arms pulled. This is the pseudo-regret: it counts the expected cost of each choice and leaves out the luck of the rewards.

A learner estimates each μₐ by the mean of the rewards arm a has paid. It doesn't need to keep them: after the n-th reward R,

Qₙ = Qₙ₋₁ + (R − Qₙ₋₁) / n

is the running mean. IX's three bandits all update this way ([`bandit.rs` 39-43](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/src/bandit.rs#L39-L43)). Where they differ is in how they choose.

## 2. ε-greedy and the 10-armed testbed

ε-greedy pulls the arm with the highest estimate, except with probability ε, when it pulls one uniformly at random. Sutton and Barto's testbed (section 2.3, Figure 2.2) has 2,000 random tasks. Each has 10 arms whose means are drawn from N(0, 1) and whose rewards are drawn from N(mean, 1), and each is played for 1,000 steps. `testbed` in `rl.rs` runs IX's `EpsilonGreedy` on it. The normal draws are sums of twelve uniforms minus six. Like N(0, 1), they have mean 0 and variance 1, and they need arithmetic only, so Windows, Linux and macOS draw the same numbers. [Lesson 12](../12-autodiff/) showed what a platform's `sin` and `cos` do to printed digits. Every ε sees the same tasks and the same noise (P6):

```text
== The 10-armed testbed: 2000 tasks, 1000 steps, sample averages
  epsilon   optimal arm, steps 1-100 / 401-500 / 901-1000      average reward, steps 1-100 / 401-500 / 901-1000
  0          33.5 %   35.9 %   35.9 %           0.967   1.038   1.042
  0.01       35.1 %   48.8 %   58.7 %           0.981   1.196   1.309
  0.1        42.1 %   74.7 %   80.0 %           1.016   1.346   1.372
  mean over the tasks of the best arm's mean: 1.538
```

Greedy (ε = 0) settles on the first arm that pays well and stays there: it has the best arm in about a third of the tasks, and that share barely moves after the first hundred steps (33.5 % to 35.9 %). ε = 0.1 finds the best arm 80 % of the time by step 1,000. ε = 0.01 is still climbing. These are the curves of Figure 2.2, and P6's intervals were set from it. The best arm's mean averages 1.538 over the tasks. The expected maximum of 10 draws from N(0, 1) is 1.539, and numpy, from the same random numbers, gets 1.538 too.

## 3. Ties, and a NaN

An argmax needs a rule for ties. [`CONTRACTS.md` 8 and 14](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/CONTRACTS.md#L8-L14) say that `EpsilonGreedy` and `QLearning` break them "by FIRST occurrence (lowest index)". Both choose with [`Iterator::max_by`](https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.max_by), whose documentation says the opposite: "If several elements are equally maximum, the last element is returned." `UCB1` does the same (P1):

```text
== Ties
  new EpsilonGreedy, 10 arms, epsilon 0:       arm 9
  new QLearning, 4 actions, epsilon 0:         action 3
  UCB1, 5 arms, after reward 1 from each:      arm 4
  UCB1, 3 arms, the same:                      arm 2
```

Before any reward every estimate is 0, so a greedy learner's first pull is the last arm, not the first. On the testbed this is harmless, since chance decides which arm is best. A caller who trusts the contract and puts a default arm at index 0, expecting it to win ties, gets the last one instead. The test has a control: with a unique maximum at index 0, the same call returns 0.

The same contract says, [line 24](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/CONTRACTS.md#L24), that "NaN rewards corrupt `q_values` silently". The greedy branch compares estimates with `partial_cmp(...).unwrap()`, and `partial_cmp` has no answer for NaN (P2):

```text
== A NaN reward on arm 0 of 3, then 100 selections
  epsilon 0: Panic("called `Option::unwrap()` on a `None` value")
  epsilon 1: Value
```

The corruption stays silent only while every pull explores. The first greedy choice panics.

## 4. UCB1, and how regret grows

ε-greedy explores at the same rate forever. On the arms 0.9, 0.8 and 0.7 of Bernoulli rewards (1 with probability p, else 0), an exploring pull costs (0 + 0.1 + 0.2)/3 = 0.1 on average, so ε = 0.1 pays 0.01 per step: its regret grows linearly with T. UCB1 ([Auer, Cesa-Bianchi and Fischer](https://doi.org/10.1023/A:1013689704352)) replaces chance with optimism. It pulls the arm with the highest

Qₐ + √(2 ln t / nₐ)

where t is the number of pulls so far and nₐ those of arm a ([`bandit.rs` 62-81](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/src/bandit.rs#L62-L81)). An arm pulled rarely has a large bonus and gets tried. Auer et al. prove that its expected regret stays below 8 Σ ln T / Δₐ + (1 + π²/3) Σ Δₐ, a bound that grows like ln T. `mean_regret` averages the pseudo-regret over 100 runs of 10⁴ steps and 20 runs of 10⁵ (P7):

```text
== Regret on Bernoulli arms 0.9, 0.8, 0.7 (pseudo-regret, mean over runs)
        T   runs   epsilon-greedy 0.1     UCB1   Thompson (IX)   Auer et al. bound
    10000    100                113.2    146.3            85.4              1106.5
   100000     20               1016.6    278.6           141.9              1382.8
  regret(1e5) / regret(1e4): epsilon-greedy 8.98, UCB1 1.90, Thompson 1.66
```

ε-greedy's 1,016.6 at 10⁵ is close to the 1,000 its exploration costs on average, the rest being greedy mistakes. Multiplying T by 10 multiplied its regret by 8.98, and UCB1's by 1.90, well under the bound. UCB1's ratio is above ln 10⁵ / ln 10⁴ = 1.25. My reading, not a measurement: at 10⁴ steps the best arm's own bonus is still large enough to hide part of the gaps. Two results were not predicted. At 10⁴ steps ε-greedy is ahead of UCB1, and only the longer horizon reverses the order. IX's Thompson sampling, the next section, has the lowest regret at both horizons.

## 5. Thompson sampling and the scale of the rewards

Thompson sampling ([Thompson, 1933](https://doi.org/10.2307/2332286); [Agrawal and Goyal](https://proceedings.mlr.press/v23/agrawal12.html)) draws a plausible mean for each arm from what it believes, then pulls the arm whose draw is highest. An arm it knows little about has a wide belief and sometimes draws high. IX's version draws each arm from a normal with the running mean and variance 1/n, and variance 1 until the second pull ([`bandit.rs` 112, 130-132](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/src/bandit.rs#L112-L132)). The normal comes from [`rand_distr`](https://docs.rs/rand_distr/0.5.1/rand_distr/struct.Normal.html). That is the belief about a mean after n rewards of variance 1 and no prior, with N(0, 1) before the first pull. [`CONTRACTS.md` 13](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/CONTRACTS.md#L13) calls it "a simplified update". What it doesn't say is that the variance of the rewards is fixed at 1, whatever they are. P8 pays the same arms either 0 or 1, or 0 or 100:

```text
== IX's Thompson sampling, arms paying 0 or 1 and 0 or 100: 100 runs of 10000 steps
  pay   1: one arm over 99 % of the pulls in 0 runs; most-pulled arm not the best in 0 runs
  pay 100: one arm over 99 % of the pulls in 100 runs; most-pulled arm not the best in 67 runs
```

Paying 0 or 1, the model is about right, and IX's Thompson sampling beat UCB1 in section 4. Paying 0 or 100, the first arm to pay gets a mean near 100p. The others still draw from normals of variance at most 1 around 0, so they are never pulled again. The run locks onto whichever arm paid first, which is the best one about 0.9 / (0.9 + 0.8 + 0.7) = 37.5 % of the time. It happened in 33 runs of 100. Dividing the rewards by their scale before `update` avoids it.

## 6. States: value iteration and Q-learning

With states, an action also moves the agent, and a good action now can lead somewhere bad later. The value of taking action a in state s and acting as well as possible afterwards obeys Bellman's equation:

Q\*(s, a) = r(s, a) + γ maxₐ′ Q\*(s′, a′)

where s′ is where a leads, r the reward, and γ < 1 discounts later rewards. IX's [`GridWorld`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/src/env.rs#L10-L77) is a 5 × 5 grid. It costs −1 per step and pays +10 on reaching the goal (4, 4) from the start (0, 0), and a move into a wall leaves the agent where it is. `value_iteration` in `rl.rs` solves the equation by hand. It applies the equation to every state and action, over and over, until nothing changes. The shortest path takes 8 steps, seven at −1 and then +10, so V\*(start) = 10γ⁷ − (1 − γ⁷)/(1 − γ).

Q-learning ([Watkins and Dayan](https://doi.org/10.1007/BF00992698)) doesn't know the rules. It learns the same values from its own moves, one at a time:

Q(s, a) ← Q(s, a) + α (r + γ maxₐ′ Q(s′, a′) − Q(s, a))

This is IX's `update_index` ([`q_learning.rs` 61-82](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/src/q_learning.rs#L61-L82)), and `train_gridworld` runs the episodes with ε-greedy moves (P4):

```text
== Q-learning on the 5 x 5 GridWorld: learning rate 0.1, gamma 0.99, epsilon 0.1, 2000 episodes
  V*(start) by value iteration: 2.527188; 10 g^7 - (1 - g^7)/(1 - g): 2.527188
  max_a Q(start) after training: 2.527188
  |max_a Q(start) - V*(start)| below 1e-3: true
  largest |Q - Q*| over the 96 state-actions outside the goal: 8.484
  mean reward per episode: episodes 1-100 -4.38, 1901-2000 2.13
  greedy walk, rows from state_index:        8 steps
  greedy walk through Agent::select_action:  no path within 100 steps
```

The start's value agrees with V\* to six decimals, and the greedy walk takes the 8 steps. numpy's value iteration gives the same 2.527188. The whole table is another matter: one entry is still 8.484 away from Q\*. Watkins and Dayan's convergence theorem needs every state and action tried infinitely often. An action the greedy policy avoids is updated only when exploration picks it, at most a quarter of ε, 2.5 % of the visits. The values along the path converge, and the rest of the table lags behind. The last line belongs to section 8.

## 7. SARSA, Q-learning and the cliff

Sutton and Barto's cliff (Example 6.6) is a 4 × 12 grid. The start and the goal sit at the two ends of the bottom row, with the cliff between them. Every move costs −1, and a step into the cliff costs −100 and sends the agent back to the start. SARSA differs from Q-learning in one term:

Q(s, a) ← Q(s, a) + α (r + γ Q(s′, a′) − Q(s, a))

where a′ is the action it will actually take next, exploratory ones included. Q-learning learns the values of the greedy policy. SARSA learns those of the ε-greedy policy it follows, and on that policy walking along the edge sometimes means falling. IX's `Sarsa` has `update_index` and `select_action_index`, but no training loop and no builder. `cliff_sarsa` writes the loop and sets the public fields. Both learners run with γ = 1, a step of 0.5 and ε = 0.1, for 50 runs of 500 episodes (P5):

```text
== The cliff: gamma 1, step 0.5, epsilon 0.1, 50 runs of 500 episodes
  greedy path, Q-learning: 13 steps: 50
  greedy path, SARSA:      no path: 12, 17 steps: 34, 19 steps: 3, 21 steps: 1
  mean online return, episodes 101-500: Q-learning -50.3, SARSA -27.5
  SARSA's walks with no path: stays in one cell, against a wall: 9; cycles through 2 cells: 3
```

Q-learning found the 13-step path along the edge in all 50 runs. While learning, it scores −50.3 per episode, because its exploring moves next to the cliff fall in. SARSA scores −27.5. Its greedy path takes 17 steps, the length of the path along the top row, in 34 runs, and more in 4. The figure of Sutton and Barto's Example 6.6 shows the same order. Two of P5's three parts held.

The third part didn't: it said SARSA's greedy path is longer than 13 steps in at least 40 runs. It was in 38. In the other 12, the greedy walk read from SARSA's final table never reaches the goal. In 9 it stays in one cell, walking into a wall, and in 3 it goes back and forth between two cells. The prediction assumed the final table describes a path. With a constant step of 0.5 it is a snapshot of estimates that keep moving. My explanation, not measured: one exploratory fall pulls a neighbour's estimate halfway to a target near −100, which can make walking into a wall look better for a while. Sutton and Barto's figure is about the online return, and that part held. P5 is marked refuted in part. Its test pins the measured 38 and 12, so that any change shows.

## 8. The Agent trait

[`traits.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/src/traits.rs#L16-L27) defines an `Agent<E>` trait that a generic training loop could call, and `QLearning` implements it for `GridWorld`. `select_action` computes the row as r × `q_table.ncols()` + c ([`q_learning.rs` 123](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/src/q_learning.rs#L123)). The Q-table's columns are the 4 actions, not the grid's columns. `update` is empty ([`q_learning.rs` 133-142](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/src/q_learning.rs#L133-L142)). `rows_read` finds the row each state reads by marking one row at a time (P3):

```text
== The Agent trait on GridWorld
  5 x 5: states reading another state's row: 20; rows read twice: [4, 8, 12, 16]; rows never read: [21, 22, 23, 24]
  4 x 4: states reading another state's row: 0; rows read twice: []; rows never read: []
  row read by state (r, c) of the 5 x 5 grid:
    r = 0:  0  1  2  3  4
    r = 1:  4  5  6  7  8
    r = 2:  8  9 10 11 12
    r = 3: 12 13 14 15 16
    r = 4: 16 17 18 19 20
  largest |change| of the table after 1000 transitions, Agent::update: 0, exactly
  the same transitions through update_index:                         0.546
```

On a grid 4 cells wide, the mistake is invisible. On the 5 × 5 grid, state (r, c) reads the row of the state r places before it in reading order, so every state below the first row reads another's. The table trained in section 6, read through the trait, doesn't reach the goal within 100 steps. A generic loop written against `Agent` would get an agent that reads the wrong states and never learns.

## 9. The predictions, scored

| | Prediction, written before the first run | Measured | Verdict |
|---|---|---|---|
| P1 | Ties go to the last index: arm 9 of 10, action 3 of 4, UCB1's arm 4 of 5 | 9, 3 and 4 | Confirmed |
| P2 | After a NaN reward, a greedy selection panics; with ε = 1, 100 selections don't | Panics at ε = 0, not at ε = 1 | Confirmed |
| P3 | Through `Agent`, 20 of 25 states read another row, rows 4, 8, 12, 16 twice, rows 21–24 never; 4 × 4 all right; `update` changes nothing | As predicted; change 0, exactly | Confirmed |
| P4 | Q-learning: max Q(start) within 10⁻³ of V\*(start) = 2.5272, greedy path of 8 steps | 2.527188; 8 steps | Confirmed |
| P5 | Cliff: Q-learning along the edge in ≥ 45 runs; SARSA longer than 13 steps in ≥ 40; SARSA's online return higher by ≥ 10 | 50; **38**; 22.8 | **Refuted in part** |
| P6 | Testbed, steps 901–1,000: optimal arm 25–45 % at ε = 0, 70–90 % at ε = 0.1, ε = 0.01 between; rewards in the same order | 35.9 %, 80.0 %, 58.7 %; 1.042 < 1.309 < 1.372 | Confirmed |
| P7 | ε-greedy's regret at 10⁵ in [990, 1,200], ratio 10⁵/10⁴ in [6, 10.5]; UCB1's ratio in [1.3, 3], below Auer et al.'s bound | 1,016.6 and 8.98; 1.90, below at both | Confirmed |
| P8 | Paying 0 or 100, Thompson gives one arm > 99 % of pulls in every run, not the best in 45–75; paying 0 or 1, the best arm most in ≥ 90 | 100 and 67; 100 | Confirmed |

Seven held on the first run. P5 held in two of its three parts, and no interval was changed afterwards. P1, P2 and P3 were written from reading IX's code and contracts, to catch a gap between what they say and what the code does, and each found one. P6 and P5 were set from Sutton and Barto's figures, and P4, P7 and P8 from arithmetic. Controls show that each check can fail: a unique maximum does win, an ordinary reward doesn't panic, `update_index` does change the table, an untrained table finds no path, and paying 0 or 1 doesn't lock.

## What to use for our repositories

- **IX's `EpsilonGreedy` and `UCB1`:** they do what the textbooks say. Ties go to the last index, whatever `CONTRACTS.md` says, so put the arm that should win ties last, or break ties before calling. Check rewards for NaN before `update`.
- **IX's `ThompsonSampling`:** only for rewards whose variance is near 1. Otherwise rescale them, or it may lock onto the first arm that pays.
- **Long horizons:** UCB1 or Thompson sampling. With a fixed ε, ε-greedy's regret keeps growing linearly.
- **IX's `QLearning`:** `select_action_index`, `update_index` and `train_gridworld` are right. Don't use its `Agent` implementation.
- **SARSA with IX:** write the loop yourself, judge it by its online return, and check that a greedy path read from its table reaches the goal before using it.

## Exercises

1. Show that the update Qₙ = Qₙ₋₁ + (Rₙ − Qₙ₋₁)/n, starting from any Q₀, gives the mean of R₁, …, Rₙ.
2. ε-greedy at ε = 0.1 on the arms 0.9, 0.8 and 0.7: what does exploration cost per step, and what regret do you expect after 10⁶ steps?
3. With rewards of 0 or 100, why is the first pull of IX's `ThompsonSampling` uniform over the arms, and why does that stay true after one failure? Why is 37.5 % only an approximation of the chance of locking onto the best arm?
4. What would `QLearning`'s `Agent::select_action` need in order to read the right row, and why can't it compute that from its arguments?

<details>
<summary>Solutions</summary>

1. The first update gives Q₁ = Q₀ + (R₁ − Q₀)/1 = R₁, whatever Q₀. Then, by induction, if Qₙ₋₁ = (R₁ + … + Rₙ₋₁)/(n − 1), Qₙ = Qₙ₋₁(1 − 1/n) + Rₙ/n = ((n − 1)Qₙ₋₁ + Rₙ)/n = (R₁ + … + Rₙ)/n.
2. An exploring pull picks each arm with probability 1/3, so it costs (0 + 0.1 + 0.2)/3 = 0.1 on average, and ε = 0.1 of the pulls explore: 0.01 per step. After 10⁶ steps, about 10,000, plus a few tens of greedy mistakes; P7 measured 1,016.6 after 10⁵.
3. Before any pull, every arm draws from N(0, 1), so each is equally likely to draw highest. After one failure an arm has n = 1 and its variance stays 1 (IX updates it only when n > 1) with mean 0, so it still draws from N(0, 1). The first arm to pay then locks, with a chance proportional to its p only while every pull is uniform. After a second failure on the same arm, its variance drops to 1/2 and it wins the draw less often. That takes two failures in a row before any success, which is rare but not impossible.
4. It needs the grid's width: the row of (r, c) is r × width + c. The trait passes only the state (r, c), and the Q-table knows the number of states and actions, not the grid's shape: 25 states could be 5 × 5 or 1 × 25. The agent would have to store the width when it is built for a grid, or the trait would have to receive the environment.

</details>

## Sources

- IX at pinned commit `490c395`: [`bandit.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/src/bandit.rs), [`q_learning.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/src/q_learning.rs), [`env.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/src/env.rs), [`traits.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/src/traits.rs) and [`CONTRACTS.md`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-rl/CONTRACTS.md).
- R. S. Sutton and A. G. Barto, [*Reinforcement Learning: An Introduction*](http://incompleteideas.net/book/the-book-2nd.html), 2nd edition, MIT Press, 2018: chapter 2 for bandits and the testbed, chapter 6 for Q-learning, SARSA and the cliff.
- P. Auer, N. Cesa-Bianchi and P. Fischer, ["Finite-time analysis of the multiarmed bandit problem"](https://doi.org/10.1023/A:1013689704352), Machine Learning 47, 2002: UCB1 and its bound.
- C. J. C. H. Watkins and P. Dayan, ["Q-learning"](https://doi.org/10.1007/BF00992698), Machine Learning 8, 1992.
- W. R. Thompson, ["On the likelihood that one unknown probability exceeds another in view of the evidence of two samples"](https://doi.org/10.2307/2332286), Biometrika 25, 1933.
- S. Agrawal and N. Goyal, ["Analysis of Thompson sampling for the multi-armed bandit problem"](https://proceedings.mlr.press/v23/agrawal12.html), COLT 2012.
- The Rust standard library, [`Iterator::max_by`](https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.max_by).
