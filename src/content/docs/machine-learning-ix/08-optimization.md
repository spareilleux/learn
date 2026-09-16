---
title: "8. Optimization: descent, momentum, Adam, and searches without a gradient"
description: "Three update rules down Rosenbrock's valley, written by hand and matched step for step by ix_optimize; what a gradient nobody wrote costs in evaluations; why minimize returns a finite answer for a run that diverged to NaN; and simulated annealing and particle swarm on the same function."
sidebar:
  order: 8
---

Lesson 2 fitted a line by gradient descent and found that too large a step diverges. Lesson 7 found that the size of the step is not always the number you passed. This lesson looks at the update rule itself, on a function chosen to make the differences visible.

**Rosenbrock's function**, `(1 - x)² + 100(y - x²)²`, has its minimum at `(1, 1)` where it is 0. Around that minimum runs a long, curved, almost flat valley with steep walls. Plain descent bounces between the walls and crawls along the floor; it is the standard way to see what momentum and per-coordinate step sizes buy.

| | ML.NET | Tribuo | PyTorch | IX |
|---|---|---|---|---|
| Plain descent | `OnlineGradientDescent` | [`SGD`](https://tribuo.org/learn/4.3/javadoc/org/tribuo/math/optimisers/SGD.html) | `optim.SGD` | `ix_optimize::gradient::SGD` |
| Momentum | — | `SGD.getLinearDecaySGD` with momentum | `optim.SGD(momentum=…)` | `ix_optimize::gradient::Momentum` |
| Adam | — | [`Adam`](https://tribuo.org/learn/4.3/javadoc/org/tribuo/math/optimisers/Adam.html) | `optim.Adam` | `ix_optimize::gradient::Adam` |
| Without a gradient | — | — | — | `annealing::SimulatedAnnealing`, `pso::ParticleSwarm` |

The program is [`examples/l08_optimization.rs`](https://github.com/spareilleux/learn/blob/37b8830/code/machine-learning-ix/examples/l08_optimization.rs), starting from `(-1.2, 1.0)`, the point Rosenbrock's paper uses.

## Three rules

**Plain descent** subtracts the gradient: `p ← p - α g`. It has one problem on a valley — the gradient points across the valley far more strongly than along it, so most of the step is wasted going back and forth.

**Momentum** keeps a running velocity, `v ← βv + αg`, and subtracts that. Steps that keep pointing the same way accumulate; steps that alternate cancel. On a valley that is exactly the right instinct.

**Adam** keeps two running averages: the mean of the gradient and the mean of its square. It divides one by the square root of the other, which gives every coordinate its own step size — large where the gradient has been small and steady, small where it has been large and noisy. Both averages start at zero, so early steps would be too small; dividing by `1 - βᵗ` corrects that ([`src/optimize.rs`, lines 101-125](https://github.com/spareilleux/learn/blob/37b8830/code/machine-learning-ix/src/optimize.rs#L101-L125)):

```rust
let mean_hat = &mean / (1.0 - self.beta1.powf(t));
let square_hat = &square / (1.0 - self.beta2.powf(t));
let next = params - &(self.learning_rate * &mean_hat / &(square_hat.mapv(f64::sqrt) + self.epsilon));
```

```text
== by hand, 5000 steps at most
  SGD        5000 steps: last [0.9387, 0.8810] f 0.003761, best f 0.003761
  Momentum   4129 steps: last [1.0000, 1.0000] f 0.000000, best f 0.000000
  Adam       2822 steps: last [1.0000, 1.0000] f 0.000000, best f 0.000000

== ix_optimize::gradient::minimize, the same 5000 steps
  SGD        5000 steps: best [0.9387, 0.8810] f 0.003761, converged false
  Momentum   4129 steps: best [1.0000, 1.0000] f 0.000000, converged true
  Adam       2822 steps: best [1.0000, 1.0000] f 0.000000, converged true
```

Plain descent runs out of its 5000 steps still short of the minimum. Momentum, at the same learning rate, arrives in 4129. Adam arrives in 2822 with a learning rate fifty times larger, which is the practical reason it is the default almost everywhere: it is far less sensitive to the number you choose.

The hand version and `ix_optimize` agree exactly — same step counts, same final points, and the same first step from the same gradient:

```text
== the first Adam step from the same gradient
  gradient [-215.6000, -88.0000]
  hand [-1.15000000, 1.05000000]
  ix   [-1.15000000, 1.05000000]
```

That first step is worth reading. The gradient is `[-215.6, -88]`, wildly different in the two coordinates, and Adam moves both by exactly 0.05 — the learning rate. On the first step the bias correction makes `mean_hat` equal to the gradient and `square_hat` equal to the gradient squared, so the ratio is the *sign* of the gradient and nothing else. Adam begins by ignoring the size of the gradient entirely.

## A gradient nobody wrote

`ObjectiveFunction::gradient` has a default: if you do not supply one, it is measured with central differences ([`traits.rs`, lines 10-13](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-optimize/src/traits.rs#L10-L13)):

```rust
fn gradient(&self, x: &Array1<f64>) -> Array1<f64> {
    ix_math::calculus::numerical_gradient(&|p: &Array1<f64>| self.evaluate(p), x, 1e-7)
}
```

`ClosureObjective`, the convenience wrapper, never overrides it. So wrapping a closure costs two extra evaluations of the objective per coordinate per step — and buys a gradient that is accurate to about eight digits:

```text
== the gradient at the start, written and measured
  written  [-215.600000000, -88.000000000]
  measured [-215.600000093, -87.999999998]
  largest gap 9.30e-8, and two extra evaluations of f per coordinate per step
  Adam on ClosureObjective: best f 1.061e-16 against 1.061e-16 with the written gradient
```

The two runs land on the same value to every digit printed. That is the honest conclusion here: for a smooth two-dimensional objective, the measured gradient is good enough, and the cost is evaluations, not accuracy. The exercise counts them — 1001 against 201 for 200 steps — and the ratio grows with the number of parameters, which is why nobody trains a neural network this way.

## A finite answer for a run that diverged

`minimize` tracks the best point it has passed through and returns that, not where it ended ([`gradient.rs`, lines 124-165](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-optimize/src/gradient.rs#L124-L165)). Usually that is a kindness. When the run diverges it is a trap:

```text
== a step size that diverges
  ix SGD lr 0.01: best f 24.200000 after 5000 steps, converged false
  the same run by hand ends at f NaN — the best point hides the divergence
```

24.200000 is `f(-1.2, 1.0)` — the starting point. At a learning rate of 0.01 the very first step overshoots, every later one overshoots further, the values run to infinity and then to NaN, and since no value was ever smaller than the first, `best_params` is still the point the caller passed in. The result looks like an ordinary answer: a finite value, a finite point, 5000 iterations.

The only field that objects is `converged: false` — and plain descent returns `converged: false` for a run that ended perfectly respectably at 0.003761 too. So `converged` does not separate the two, and `best_value` does not either. A caller who wants to know whether an optimization worked has to check the objective at the returned point against the objective at the start, and refuse a result that did not improve.

## Two searches that never ask for a gradient

Some objectives have no gradient — a discrete configuration, a simulation, a score from a black box. IX ships two of the classical answers.

**Simulated annealing** proposes a random neighbour and always accepts it if it is better; if it is worse it accepts it anyway with probability `exp(-Δ/T)`, where the temperature `T` falls over time. Hot, it wanders freely and escapes local minima; cold, it only goes downhill.

**Particle swarm** flies a population of points, each pulled towards the best point it has personally seen and towards the best point anyone has seen.

```text
== without a gradient
  simulated annealing, seed 42: best [0.9934, 0.9881] f 0.000193 after 3216 iterations
  particle swarm, 40 particles, seed 42: best [1.0000, 1.0000] f 0.000000
```

Annealing stops at iteration 3216, when the exponential schedule takes the temperature below `min_temp`, and gets four digits of the answer. The swarm, with 40 particles over 200 iterations — 8000 evaluations — lands on the minimum. Both do respectably on a problem where the written gradient needed 2822 steps; both would be a poor choice *because* the gradient exists.

## Back to the line

The same three rules on the loss of lesson 2, standardized, where the answer is known:

```text
== the build-time line, standardized: closed form slope 0.667448, intercept 0
  SGD        106 steps: slope 0.667448, intercept -0.000000, loss 0.554513
  Momentum   366 steps: slope 0.667448, intercept -0.000000, loss 0.554513
  Adam       384 steps: slope 0.667448, intercept -0.000000, loss 0.554513
```

All three reach the closed form to six decimals, and plain descent gets there first. On a round bowl with a well-chosen learning rate there is nothing for momentum to accumulate and nothing for Adam to rescale; both only add their own dynamics on top of a problem that did not need them. Rosenbrock's valley and this bowl are the two ends of the same story, and which end you are on is a property of the problem, not of the optimizer.

## Exercises

1. What is the largest plain-descent learning rate that still reaches the valley in 5000 steps?
2. How many evaluations of the objective does a missing gradient cost over 200 Adam steps?
3. How does the momentum coefficient change the number of steps?

<details>
<summary>Solutions</summary>

They are in [`examples/l08_exercises.rs`](https://github.com/spareilleux/learn/blob/37b8830/code/machine-learning-ix/examples/l08_exercises.rs).

**1.** 0.002 — and the edge is sharp:

```text
== plain descent on Rosenbrock, 5000 steps, by learning rate
  rate 0.0001 : ends at f 2.305718
  rate 0.0005 : ends at f 0.042952
  rate 0.001  : ends at f 0.003761
  rate 0.002  : ends at f 0.000055
  rate 0.005  : ends at f 0.788039
  rate 0.01   : ends at f NaN
```

Below 0.002 the run is stable and slow; at 0.002 it is stable and much faster; at 0.005 it is unstable but still bounded; at 0.01 it is gone. The usable window spans a factor of about five, and nothing but trying tells you where it is. Adam at 0.05 sat comfortably in the middle of a much wider one.

**2.** Five times as many:

```text
== evaluations of f for 200 Adam steps
  written gradient true : 201 evaluations, best f 2.588e0
  written gradient false: 1001 evaluations, best f 2.588e0
```

201 is one per step plus the first. 1001 is that plus `2 × 2 coordinates × 200 steps`. With `d` parameters the factor is `1 + 2d`, so a model with a thousand parameters would pay two thousand times over — and reach the same point, as the `best f` column shows.

**3.** More momentum helps until it does not:

```text
== momentum coefficient against steps to reach f < 1e-10
  0    : 20000 steps, last [0.9999, 0.9997] f 1.938e-8
  0.5  : 20000 steps, last [1.0000, 1.0000] f 2.130e-15
  0.9  :  4129 steps, last [1.0000, 1.0000] f 1.244e-16
  0.95 :  1790 steps, last [1.0000, 1.0000] f 1.242e-16
  0.99 :  4014 steps, last [1.0000, 1.0000] f 4.696e-18
```

With `β = 0` this is plain descent, and 20 000 steps are not enough to trip the gradient-norm test. 0.95 is the best of these at 1790 steps. At 0.99 the velocity carries so far past the turn that the run takes more than twice as long — and lands on the most accurate point of the five, having spiralled in. The usual defaults, 0.9 and 0.99, sit on either side of the optimum here, which is a fair picture of how much this parameter is worth tuning.

</details>

## Sources

- Rosenbrock, *[An automatic method for finding the greatest or least value of a function](https://academic.oup.com/comjnl/article/3/3/175/345501)*, 1960
- Kingma and Ba, *[Adam: A Method for Stochastic Optimization](https://arxiv.org/abs/1412.6980)*, 2015
- Goodfellow, Bengio, Courville, *[Deep Learning](https://www.deeplearningbook.org/)*, chapter 8
- Kirkpatrick, Gelatt and Vecchi, *[Optimization by Simulated Annealing](https://www.science.org/doi/10.1126/science.220.4598.671)*, 1983
- [PyTorch: `torch.optim`](https://docs.pytorch.org/docs/stable/optim.html)
- IX at `490c395`: [`ix-optimize/src/gradient.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-optimize/src/gradient.rs), [`ix-optimize/src/traits.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-optimize/src/traits.rs), [`ix-optimize/src/annealing.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-optimize/src/annealing.rs), [`ix-optimize/src/pso.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-optimize/src/pso.rs), [`ix-math/src/calculus.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-math/src/calculus.rs)
