---
title: "17. Evolution: genetic algorithms, differential evolution, Pareto fronts"
description: "Selection, BLX crossover and mutation, IX's genetic algorithm and differential evolution, and Pareto fronts against ix-evolution, with eight predictions written before the first run, seven held and one refuted in part. IX's GA gets below the target loss of minimize_linreg_mse after a median of 916 evaluations, five to ten times fewer than the example claims; its mutation rate is a standard deviation, it returns its last generation when elitism is off, its differential evolution never returns with three individuals, and its Pareto frontier reports a rejected table's error in an order-dependent way."
sidebar:
  order: 17
---

An evolutionary algorithm keeps a population of candidate solutions and improves it by imitating selection. It breeds from the better candidates, mixes their genes, perturbs the result, and repeats. It needs no gradient, only a score for each candidate. IX's pinned [`ix-evolution`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution) crate has three selection operators, a real-coded genetic algorithm, differential evolution, and a non-dominated sort for problems with several objectives. This lesson measures each part, then runs the genetic algorithm on the loss that [lesson 12](../12-autodiff/)'s Adam minimized in 31 steps, because IX's example claims a number for it.

The eight predictions this lesson tests were [written in the journal](../journal/#2026-09-30--lesson-17-predicted-before-measuring) and committed before any of its code existed. [The results](../journal/#2026-09-30--lesson-17-measured) follow them. The experiments are in [`evolution.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/src/evolution.rs), one test per prediction, and [`l17_evolution.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/examples/l17_evolution.rs) prints what they measure. IX's operators take any [`rand::Rng`](https://docs.rs/rand/0.9.5/rand/trait.Rng.html), so the course hands them its own splitmix64 stream. [`crosscheck.py`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/crosscheck/crosscheck.py) rebuilds the lesson's Pareto sets from that stream and checks the crossover formula with numpy's own generator.

## 1. Selection

Selection decides which candidates become parents. IX's three operators all minimize ([`selection.rs` 7-69](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/selection.rs#L7-L69)):

- `tournament` draws k candidates with replacement and keeps the best. With 3 candidates and k = 3, the best wins unless all three draws miss it: 1 − (2/3)³ = 19/27. [Blickle and Thiele (1996)](https://doi.org/10.1162/evco.1996.4.4.361) compare these schemes.
- `rank` sorts the candidates and draws with weight n for the best down to 1 for the worst, whatever the fitness values are.
- `roulette` draws with a probability proportional to max − f + 10⁻¹⁰, so the worst candidate always weighs 10⁻¹⁰.

P1 draws 100,000 times from fitness [0, 1, 2], then [0, 1, 1000] and [0, 1]:

```text
== selection, 100000 draws each (best, middle, worst)
  tournament, k = 3, on [0, 1, 2]:  0.7027 0.2607 0.0366   (19/27, 7/27, 1/27)
  rank on [0, 1, 2]:                0.5027 0.3321 0.1652   (3/6, 2/6, 1/6)
  roulette on [0, 1, 2]:            0.6657 0.3342 0.0000   (2/3, 1/3, 0)
  roulette on [0, 1, 1000]:         0.5009 0.4991 0.0000   (1000/1999, 999/1999, 0)
  roulette on [0, 1]:               1.0000 0.0000
  roulette drew the worst 0 times
```

Every frequency is within 0.006 of its value. `roulette` does what its comment says, "fitness-proportional, for minimization", and the shift by the maximum has consequences worth knowing. The worst candidate is never drawn. One outlier at 1000 makes the best and the second best almost equal. Of two candidates, the better one is drawn every time. `tournament` and `rank` depend only on the order of the fitness values, so the scale doesn't matter to them.

## 2. Crossover and mutation

`RealIndividual::crossover` is BLX-α, from [Eshelman and Schaffer (1993)](https://doi.org/10.1016/B978-0-08-094832-4.50018-0). Each child gene is drawn uniformly on [min − αd, max + αd], where d is the distance between the two parents' genes and α = 0.5 ([`traits.rs` 43-52](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/traits.rs#L43-L52)). Its effect on the spread of a population follows from two lines. Take parents drawn independently from a population of variance σ². The child's mean is the midpoint, whose variance is σ²/2. Around it, the child is uniform on a width of (1 + 2α)d, a variance of (1 + 2α)²d²/12, and E[d²] = 2σ². The child's variance is therefore σ²/2 + (1 + 2α)²σ²/6. That is 7σ²/6 at α = 0.5, and exactly σ² at α = (√3 − 1)/2 ≈ 0.366. P2 crosses 200 pairs of parents with 1000 genes each. The parents come from the course's approximate normal: the sum of twelve uniforms minus six, of variance exactly 1. The derivation needs only independence and the variance.

```text
== BLX-0.5 crossover, 200 pairs of parents with 1000 genes each
  parents' variance 1.0013, children's variance 1.1639 (7/6 = 1.1667); every child gene inside its interval: true
```

Crossover alone widens the population by a sixth each generation, so selection has to pull against it. The cross-check repeats the experiment with numpy and finds 1.169 at α = 0.5 and 1.002 at α = 0.366.

`Individual::mutate` is documented as "Mutate in place with given mutation rate" ([`traits.rs` 13-14](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/traits.rs#L13-L14)). In [Eiben and Smith](https://doi.org/10.1007/978-3-662-44874-8)'s terms, a mutation rate is the probability that a gene mutates, and the size of a Gaussian change is a step size, σ. `RealIndividual` instead picks each gene with a fixed probability of 0.3 and adds N(0, rate) to it ([`traits.rs` 54-62](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/traits.rs#L54-L62)). The rate is a standard deviation. rand_distr's [`Normal::new`](https://docs.rs/rand_distr/0.5.1/rand_distr/struct.Normal.html#method.new) rejects only a standard deviation that isn't finite. P3 mutates 100,000 genes at 0:

```text
== mutate(rate) on 100000 genes at 0
  rate  0.1: fraction changed 0.3010, standard deviation of the changes 0.1009
  rate    1: fraction changed 0.3010, standard deviation of the changes 1.0093
  rate -0.1: fraction changed 0.3010, standard deviation of the changes 0.1009
  rate    0: fraction changed 0.0000, standard deviation of the changes 0.0000
  rate  NaN: panic "called `Result::unwrap()` on an `Err` value: BadVariance"
```

The same seed picks the same genes, so the fraction is the same for every rate, and ten times the rate gives ten times the changes. A caller who sets a rate of 0.01, meaning "one gene in a hundred", gets 30% of the genes moved by about 0.01. A negative rate is its opposite, and NaN panics in the first generation.

## 3. The genetic algorithm and elitism

`GeneticAlgorithm::minimize` draws a population uniformly within the bounds. Each generation sorts it, records the best fitness in `fitness_history`, and copies the `elitism` best candidates unchanged. It fills the rest with children: two tournament winners, crossed with probability 0.8, mutated, clamped to the bounds and evaluated. The result is the best of the final population ([`genetic.rs` 85-139](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/genetic.rs#L85-L139)). With the default `elitism` of 2, the best candidate always survives, so the final best is the best ever seen. `elitism` is a public field. At 0, nothing carries the best forward. P4 runs the defaults on the sphere Σxᵢ² in 3 dimensions, with elitism 0 and 2:

```text
== IX's GA on the sphere in 3 dimensions, 20 seeds, its defaults except elitism
  elitism 0: returned fitness above the best recorded for 20 of 20; history rises for 20
             median returned 2.37e-5, median best recorded 5.73e-7
  elitism 2: history never rises and returned at most its last entry for 20 of 20
             median returned 1.87e-8
```

Without elitism, every run returns a candidate worse than one it had already found, and the median returned fitness is 41 times the median best recorded. It is a choice the caller makes, but `best_fitness` doesn't say that it means "best of the last generation".

## 4. How many evaluations, against Adam

IX's [`minimize_linreg_mse`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/examples/minimize_linreg_mse.rs#L173-L181) example trains a linear regression with Adam, then prints that the "ix-evolution GA on a similar 4-parameter optimum typically needs ~5000-10000 fitness evaluations to reach the same loss", and a speedup of 7500 divided by Adam's step count. No genetic algorithm runs ([lesson 12](../12-autodiff/)). P5 runs one. The objective is the example's mean squared error over (w₀, w₁, w₂, b), rebuilt in lesson 12, and each run counts its evaluations until the loss first falls below 0.01, Adam's target. IX's defaults evaluate 100 + 500 × 98 = 49,100 times per run. [`DifferentialEvolution`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/differential.rs), in section 5, runs on the same loss with its own defaults.

```text
== minimize_linreg_mse's loss over (w0, w1, w2, b): evaluations until it first falls below 0.01, 20 seeds
  GA, defaults: 49100 evaluations per run, below 0.01 in 20 of 20 runs, first after a median of 916.0 (min 485, max 1356)
      final loss, median 2.34e-7
  DE, defaults: 50050 evaluations per run, below 0.01 in 20 of 20 runs, first after a median of 1250.0 (min 496, max 1715)
      final loss, median 1.81e-13
  Adam, lesson 12: below 0.01 at step 31
```

P5 predicted that every run would get there, which held, and it was wrong twice. The GA's median is 916 evaluations, below the predicted range of 1,000 to 10,000. That is about 8 generations after the first 100, where a rough model of the population's spread predicted 20 to 60. Differential evolution needs more evaluations to get there, not fewer. The example's figure is 5.5 to 11 times the GA's median, and the speedup it prints, 242, would be 916 / 31 ≈ 30. A probable reason the GA is fast here, not measured, is lesson 12's collinear features. The loss is flat along one direction, so the region below 0.01 is a long slab rather than a small ball. The journal lists that as to verify. The two methods also finish differently. DE is slower to 0.01, then ends 6 orders of magnitude lower than the GA. A likely reason, also not measured: DE's steps shrink with the population's spread, while 76% of the GA's children (1 − 0.7⁴) get at least one change of fixed size 0.1.

## 5. Differential evolution

[Storn and Price (1997)](https://doi.org/10.1023/A:1008202821328)'s DE/rand/1/bin builds a mutant for each target from three other candidates, x_r1 + F(x_r2 − x_r3). It crosses the mutant with the target gene by gene with probability CR, and keeps the trial if it scores no worse. The difference vector gives each step the scale and direction of the population itself. IX's version replaces the targets as it goes, as SciPy's [`differential_evolution`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.optimize.differential_evolution.html) does by default (`updating='immediate'`). It needs three candidates other than the target. `pick_three` redraws until it has them, and nothing checks that they exist ([`differential.rs` 132-146](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/differential.rs#L132-L146)). P6 runs `minimize` in a thread and waits 2 seconds:

```text
== DifferentialEvolution::minimize in a thread, 10 generations, waited for 2 s
  3 individuals: returned false
  4 individuals: returned true
```

With 3 candidates, the third index can never be found, and the loop spins until the process exits. A population of 4 or more is needed, and IX doesn't check for it.

## 6. Pareto fronts

With several objectives, one candidate dominates another when it is no worse on every objective and better on at least one. The candidates no other dominates form the first Pareto front. Removing it and repeating gives the next fronts. `pareto::rank` is the fast non-dominated sort of [Deb et al. (2002)](https://doi.org/10.1109/4235.996017) ([`pareto.rs` 71-130](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/pareto.rs#L71-L130)). It counts each candidate's dominators, peels those with none, and decrements. For n points drawn uniformly, [Bentley et al. (1978)](https://doi.org/10.1145/322092.322095) give the expected size of the first front: H_n = Σ 1/k in 2 dimensions, and Σ H_k/k in 3. In 2 dimensions it is the number of records of a random permutation, whose variance is H_n − Σ 1/k² ([Knuth](https://www-cs-faculty.stanford.edu/~knuth/taocp.html), section 1.2.10). P7 ranks 100 sets of 200 points and compares every front with a brute-force peeling:

```text
== pareto::rank on 100 sets of 200 uniform points, every objective minimized
  2 dimensions: mean size of front 0 6.220 (expected 5.878); all fronts equal to brute force 100 of 100; unchanged with the rows reversed 100 of 100
  3 dimensions: mean size of front 0 17.810 (expected 18.096); all fronts equal to brute force 100 of 100; unchanged with the rows reversed 100 of 100
```

6.220 is 1.7 standard errors from 5.878, and 17.810 is within 0.3 of 18.096. The cross-check rebuilds the same sets and finds the same means with numpy. In 3 dimensions, 9% of the 200 points are already undominated. The share grows with the number of objectives, until dominance no longer tells candidates apart.

## 7. The frontier of a table

`frontier` takes a long table of (revision, task class, candidate, metric, direction, value) rows. It validates it, pivots it per (revision, task class), and emits front 0. Its comment makes a careful promise: the output is byte-identical whatever the row order, and so is the error of a rejected table. The checks "run in a fixed sequence and each scans the input in canonical sorted order" ([`frontier.rs` 183-188](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/frontier.rs#L183-L188)). The canonical order is a stable sort on (revision, task class, candidate, metric) ([`frontier.rs` 195-196](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/frontier.rs#L195-L196)), so two rows with the same key keep their input order. The direction check runs before the duplicate check ([`frontier.rs` 347-372](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/frontier.rs#L347-L372)). P8 gives it two rows for one candidate and metric, spelled "min" and "Max":

```text
== frontier on two rows for one candidate and metric, directions "min" and "Max"
  in that order: UnknownDirection "min"
  reversed:      UnknownDirection "Max"
  a valid table of 300 rows: 21 frontier rows, the same CSV for 50 of 50 shuffles
  IX's table with several defects: "candidate a in rev-a/t repeats metric cost", the same error for 50 of 50 shuffles
```

The valid table and IX's own test table keep their promise. The gap needs two rows that share a key and are both misspelled differently: the direction check reports whichever comes first. IX's test ([`tests/frontier.rs` 500-524](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/tests/frontier.rs#L500-L524)) permutes a table whose duplicates share one direction, so it couldn't see this. Running the duplicate check first, or including the direction in the sort key, would close it.

The crate's header and its package description also announce genetic programming ([`lib.rs` 1-4](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/lib.rs#L1-L4)). None of its six modules implements it.

## 8. The predictions, scored

| | Prediction, written before the first run | Measured | Verdict |
|---|---|---|---|
| P1 | Tournament 19/27 for the best of [0, 1, 2]; rank 3/6, 2/6, 1/6; roulette 2/3, 1/3, 0, then 1000/1999 on [0, 1, 1000] and always the better of two; all within 0.006 | As predicted; roulette never drew the worst | Confirmed |
| P2 | BLX-0.5 multiplies the variance by 7/6: 1.1667 ± 0.015, every child inside its interval | 1.1639, all inside | Confirmed |
| P3 | 30% ± 0.5% of the genes change at rates 0.1 and 1, by a standard deviation within 2% of the rate; −0.1 as 0.1; 0 changes nothing; NaN panics | 30.1%, 0.1009 and 1.0093; as predicted | Confirmed |
| P4 | Elitism 0: returned fitness above the best recorded for ≥ 18 of 20 seeds, history rises for 20; elitism 2: never rises | 20, 20; 20 | Confirmed |
| P5 | Every GA and DE run gets below 0.01; GA median 1,000–10,000 evaluations; DE's median lower | 20 and 20 runs; GA 916; DE 1,250 | Refuted in part |
| P6 | DE with 3 individuals hasn't returned after 2 s; with 4 it returns | As predicted | Confirmed |
| P7 | Mean first front of 200 uniform points in [5.22, 6.54] in 2-D and [16.8, 19.4] in 3-D; every front equal to brute force; row order irrelevant | 6.220 and 17.810; 100 of 100 | Confirmed |
| P8 | Two misspelled rows with one key: "min" in one order, "Max" reversed; valid tables and IX's table order-independent | As predicted | Confirmed |

Seven held on the first run, and one was refuted in part. The code compiled at the first try. No interval was changed afterwards. P1, P2, P3 and P7 came from derivations and published results. P3, P4, P6 and P8 came from reading IX's code against its comments, and all four found a gap. P5 came from a rough model, and the model was wrong: the genetic algorithm reached the target in about a third of the generations it allowed. Its test now pins the measured medians. The controls show that each check can fail. Elitism 2 does keep the best. Four individuals do return. The valid table and IX's own table do keep their order-independence.

## What to use for our repositories

- **IX's `GeneticAlgorithm`:** keep `elitism` at 1 or more. Read `mutation_rate` as the standard deviation of a change, sized to your variables' scale. About 30% of the genes change whatever the rate.
- **IX's `DifferentialEvolution`:** check that the population has at least 4 candidates before calling it, since IX doesn't. On this loss it ended 6 orders of magnitude lower than the GA.
- **A smooth loss with a gradient:** Adam reached 0.01 in 31 steps, the GA in a median of 916 evaluations and DE in 1,250. The example's 242× is closer to 30×.
- **Selection:** prefer `tournament` or `rank` when fitness values can include outliers. `roulette` depends on the scale and never picks the worst.
- **`pareto::rank`:** exact and independent of row order; it matched brute force on 200 sets.
- **`frontier`:** deterministic on a valid table. Don't key anything on the text of its error.

## Exercises

1. Derive the child variance of BLX-α for independent parents of variance σ², and the α that preserves it.
2. In a tournament of size k with replacement among n candidates of distinct fitness, show that the i-th best wins with probability ((n − i + 1)/n)^k − ((n − i)/n)^k. Check 19/27, 7/27 and 1/27 for n = k = 3.
3. Show that for n points in the plane with distinct coordinates, the number of non-dominated points (minimizing both) equals the number of records in a permutation, and deduce that its mean is H_n.
4. Why does DE/rand/1 need at least four candidates? Write the check that `DifferentialEvolution::minimize` is missing.

<details>
<summary>Solutions</summary>

1. The child is m + U, where m = (a + b)/2 and U is uniform on a width of (1 + 2α)d centred on m, with d = |a − b|. Var(m) = σ²/2. Given d, Var(U) = (1 + 2α)²d²/12, and E[d²] = E[(a − b)²] = 2σ². U has mean 0 given (a, b), so the variances add: σ²/2 + (1 + 2α)²σ²/6. Setting it to σ² gives (1 + 2α)² = 3, that is α = (√3 − 1)/2 ≈ 0.366.
2. The i-th best wins when every draw is among the i-th best or worse, which has probability ((n − i + 1)/n)^k, and not all of them are worse than the i-th, which has probability ((n − i)/n)^k. For n = k = 3: 1 − 8/27 = 19/27, 8/27 − 1/27 = 7/27, and 1/27.
3. Sort the points by their first coordinate, increasing. A point is dominated if and only if some point before it has a smaller second coordinate. So the non-dominated points are those whose second coordinate is a new minimum, the records of the sequence of second coordinates. For uniform points, that sequence is in random order, and the k-th value is a record with probability 1/k. The mean is Σ 1/k = H_n.
4. The mutant x_r1 + F(x_r2 − x_r3) needs r1, r2 and r3 distinct and different from the target i: four distinct indices. With 3 or fewer, `pick_three`'s last loop never ends. The check is `assert!(self.population_size >= 4, "DE/rand/1 needs at least 4 individuals")`, or a `Result` error, at the top of `minimize`.

</details>

## Sources

- IX at pinned commit `490c395`: [`selection.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/selection.rs), [`traits.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/traits.rs), [`genetic.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/genetic.rs), [`differential.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/differential.rs), [`pareto.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/pareto.rs), [`frontier.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/frontier.rs), and ix-autograd's [`minimize_linreg_mse.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/examples/minimize_linreg_mse.rs).
- L. J. Eshelman and J. D. Schaffer, ["Real-coded genetic algorithms and interval-schemata"](https://doi.org/10.1016/B978-0-08-094832-4.50018-0), Foundations of Genetic Algorithms 2, 1993.
- T. Blickle and L. Thiele, ["A comparison of selection schemes used in evolutionary algorithms"](https://doi.org/10.1162/evco.1996.4.4.361), Evolutionary Computation 4, 1996.
- R. Storn and K. Price, ["Differential evolution – a simple and efficient heuristic for global optimization over continuous spaces"](https://doi.org/10.1023/A:1008202821328), Journal of Global Optimization 11, 1997.
- K. Deb, A. Pratap, S. Agarwal and T. Meyarivan, ["A fast and elitist multiobjective genetic algorithm: NSGA-II"](https://doi.org/10.1109/4235.996017), IEEE Transactions on Evolutionary Computation 6, 2002.
- J. L. Bentley, H. T. Kung, M. Schkolnick and C. D. Thompson, ["On the average number of maxima in a set of vectors and applications"](https://doi.org/10.1145/322092.322095), Journal of the ACM 25, 1978.
- D. E. Knuth, [*The Art of Computer Programming*](https://www-cs-faculty.stanford.edu/~knuth/taocp.html), vol. 1, section 1.2.10.
- A. E. Eiben and J. E. Smith, [*Introduction to Evolutionary Computing*](https://doi.org/10.1007/978-3-662-44874-8), 2nd edition, Springer, 2015.
- SciPy: [`optimize.differential_evolution`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.optimize.differential_evolution.html). rand: [`Rng`](https://docs.rs/rand/0.9.5/rand/trait.Rng.html); rand_distr: [`Normal::new`](https://docs.rs/rand_distr/0.5.1/rand_distr/struct.Normal.html#method.new).
