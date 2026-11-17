---
title: "18. Adversarial examples, poisoning and the defences"
description: "FGSM, PGD, Carlini–Wagner and universal perturbations against a fixed linear model, then detection by noise, feature squeezing, the certified radius and the poisoning defences of ix-adversarial, with eight predictions written before the first run, all eight held. PGD moves the features the gradient ignores, Carlini–Wagner returns the input untouched below c‖w‖ = 1, the detector gives all 4,000 inputs the same score, squeezing keeps the perturbation's mean, the certified radius is off by up to 4.4·10⁻⁴, and the influence function ignores the labels."
sidebar:
  order: 18
---

An adversarial example is an input changed slightly, on purpose, so that a model gets it wrong. [Goodfellow et al. (2015)](https://arxiv.org/abs/1412.6572) argued that such inputs follow from linearity itself: in high dimension, many small changes add up to a large one. Poisoning attacks the training data instead of the input. IX's pinned [`ix-adversarial`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial) crate has four evasion attacks, three defences, a certified radius and three tools against poisoning. This lesson measures them against a model simple enough that every number the tests check follows from a formula.

The eight predictions this lesson tests were [written in the journal](../journal/#2026-09-30--lesson-18-predicted-before-measuring) and committed before any of its code existed. [The results](../journal/#2026-09-30--lesson-18-measured) follow them. The experiments are in [`adversarial.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/src/adversarial.rs), one test per prediction, and [`l18_adversarial.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/examples/l18_adversarial.rs) prints what they measure. [`crosscheck.py`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/crosscheck/crosscheck.py) rebuilds the test set, the Carlini–Wagner path, the squeezing, the probit and both poisoning experiments with numpy and SciPy, and finds the same numbers.

## 1. A model that can be attacked on paper

Attacks are usually measured against trained networks, where the result depends on the training. This lesson fixes the model instead. Two classes y = ±1 live in 100 dimensions: x = y·μ + n, where every coordinate of μ is 0.2 and n is the course's approximate normal noise, the sum of twelve uniforms minus six. The classifier is the Bayes-optimal linear one for this problem, w = μ with no bias: it predicts the sign of z = w·x. A point's margin m = y·z is positive when the point is correctly classified, and its distance to the boundary is m/‖w‖₂. Since m = ‖μ‖² + y·w·n, it is distributed as 4 + N(0, 4), and the clean accuracy is Φ(2) ≈ 0.977. Each feature carries little signal, 0.2 against a noise of standard deviation 1. The model is accurate because it adds 100 of them.

```text
== the model under attack
2000 test points, 1000 per class, in 100 dimensions; w = mu = 0.2 everywhere, |w|_2 = 2.000, |w|_1 = 20.000
clean accuracy 0.9780   (Phi(2) = 0.9772)
```

The attacks below need the gradient of a loss with respect to the input. For the logistic loss log(1 + e^(−m)), it is −y·σ(−m)·w, a positive multiple of −y·w: the direction that lowers the margin fastest.

## 2. FGSM: every feature moved a little

`fgsm` adds ε·sign(g) to the input, where g is the gradient of the loss ([`evasion.rs` 5-10](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/evasion.rs#L5-L10)). Against a linear model, sign(g) = −y·sign(w), so every coordinate moves by ε against the class, and the margin falls by ε·Σ|wⱼ| = ε‖w‖₁ = 20ε. This is Goodfellow et al.'s linear explanation. The change on each feature is small next to its noise, and the 100 changes add up. The accuracy becomes Φ(2 − 10ε). P1 attacks the 2,000 test points at four values of ε:

```text
== P1, FGSM: every margin falls by eps |w|_1 = 20 eps
  eps   accuracy   Phi(2 - 10 eps)   changed class   exactly those with 0 < m < 20 eps   margins within 1e-12
  0.0   0.9780     0.9772               0            yes                                 yes
  0.1   0.8460     0.8413             264            yes                                 yes
  0.2   0.4780     0.5000            1000            yes                                 yes
  0.3   0.1470     0.1587            1662            yes                                 yes
```

Every margin fell by 20ε to within 10⁻¹². The points that changed class are exactly the correctly classified ones whose margin was below 20ε. The accuracies are within 0.022 of Φ(2 − 10ε), inside the predicted intervals. At ε = 0.2, a change of a fifth of the noise on each feature halves the accuracy. That ε is the smallest ℓ∞ change that reaches the boundary from the mean margin: m/‖w‖₁ = 4/20.

## 3. PGD and the sign of zero

`pgd` repeats FGSM's step: α·sign(g) from x, then a clip of the total change to [−ε, ε] ([`evasion.rs` 12-33](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/evasion.rs#L12-L33)), after [Madry et al. (2018)](https://arxiv.org/abs/1706.06083). IX starts from x itself, with no random start. A smaller difference matters more here. `pgd` takes the sign with [`f64::signum`](https://doc.rust-lang.org/std/primitive.f64.html#method.signum), which returns 1 for +0.0 and −1 for −0.0. `fgsm` maps 0 to 0, as NumPy's [`sign`](https://numpy.org/doc/stable/reference/generated/numpy.sign.html) does. A gradient component is exactly zero wherever the loss doesn't depend on the feature, and its sign then comes from the arithmetic. Here, 0.0 times −y·σ(−m) is a zero with the sign of −y. `adversarial_training_augment`, documented as "via FGSM", calls `signum` too ([`defense.rs` 7-20](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/defense.rs#L7-L20)). P2 gives both functions a gradient of zeros, then attacks a model that ignores half its features, with wⱼ = 0 for the last 50:

```text
== P2, PGD and f64::signum (eps 0.2, alpha 0.05, 10 steps), largest distance from the expected point
  gradient +0.0 everywhere: pgd from x +0.2 0.000, adversarial_training_augment from x +0.2 0.000, fgsm from x 0.000
  gradient -0.0 everywhere: pgd from x -0.2 0.000, adversarial_training_augment from x -0.2 0.000, fgsm from x 0.000
  model with w_j = 0 for the last 50 features, over the 2000 points (fewest, most):
    pgd:  features moved (100, 100), perturbation norm (2.0000, 2.0000), accuracy 0.4865
    fgsm: features moved (50, 50), perturbation norm (1.4142, 1.4142), accuracy 0.4865
  control, the full model: largest distance between pgd's point and fgsm's 0.000
```

With a zero gradient, `pgd` and `adversarial_training_augment` move every feature by the full ε, in a direction set by the sign of zero, while `fgsm` doesn't move. Against the half model, `pgd` moves all 100 features and `fgsm` only the 50 that matter. The accuracy is the same, 0.4865, because the model can't see the other 50. But PGD's perturbation is √2 times as long, 2.0 against 1.414, and anything that measures it, such as an ℓ₂ budget or a detector, sees 50 changes that do nothing. The control shows that nothing else differs: against the full model, whose gradient has no zero, `pgd` lands exactly on `fgsm`'s point.

## 4. Carlini–Wagner without its search over c

`cw_attack` minimizes ‖δ‖₂ + c·loss(x + δ) by gradient descent on δ and returns the iterate with the lowest objective ([`evasion.rs` 35-71](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/evasion.rs#L35-L71)). Its doc comment says the descent runs in tanh-space, but the code has no tanh. [Carlini and Wagner (2017)](https://doi.org/10.1109/SP.2017.49) use that change of variables to keep an image inside its box, minimize the squared norm, and search over c for the smallest perturbation that succeeds. IX leaves c to the caller and uses the plain norm.

With the hinge loss max(m, 0), the descent can be followed by hand. The gradient of ‖δ‖₂ is δ/‖δ‖, of length 1, and the loss's gradient is y·w while the point is on its side. So the path runs straight along −y·w. Its first step has length lr·c‖w‖. The next steps have length lr·(c‖w‖ − 1) while m > 0, and the path moves back by lr once past the boundary. If c‖w‖ < 1, every step after the first moves back toward x, and no δ at all has a lower objective than x itself (exercise 3). If c‖w‖ > 1, the path reaches the boundary, at distance m/‖w‖, and cycles around it. The point kept is the one of the cycle with the lowest objective. It is past the boundary with probability 1/2 at c‖w‖ = 2 and 1/3 at c‖w‖ = 1.5, depending on where the boundary falls between two steps. P3 runs 2,000 steps at lr = 0.01 on the correctly classified points:

```text
== P3, cw_attack with the hinge loss max(m, 0), lr 0.01, 2000 steps, on the correctly classified points
  c = 0.25 (c|w| = 0.5): 1956 points, 1956 returned unchanged, misclassified 0.0000 (predicted every result x), largest | |delta| - m/|w| | 5.8712
  c = 1.00 (c|w| = 2.0): 1956 points, 1 returned unchanged, misclassified 0.5072 (predicted [0.464, 0.536]), largest | |delta| - m/|w| | 0.0050
  c = 0.75 (c|w| = 1.5): 1956 points, 1 returned unchanged, misclassified 0.3522 (predicted [0.299, 0.367]), largest | |delta| - m/|w| | 0.0033
```

At c = 0.25, all 1,956 results are x itself. The attack finds nothing, and a caller who reads that as robustness has only picked c too small. At c = 1 and 0.75, 0.5072 and 0.3522 of the results are past the boundary. Every result is within 0.005 of the minimal perturbation, closer than the predicted 0.02, because the objective keeps the nearer of the points around the boundary. The one point returned unchanged at c = 1 and 0.75 is the nearest to the boundary: its first step already jumps past it by more than the distance saved. Success is decided point by point by where the boundary falls between two steps, not by the model. Carlini and Wagner's search over c, with a check that each result is misclassified, is what makes the attack reliable. IX's function does neither. The cross-check follows the same path as a scalar recurrence with numpy and finds the same counts.

## 5. Universal perturbations and JSMA

A universal perturbation, after [Moosavi-Dezfooli et al. (2017)](https://doi.org/10.1109/CVPR.2017.17), is one vector v that fools the model on most inputs. For each input that v doesn't fool yet, they add the smallest change that sends x + v to the boundary, found by DeepFool, then project v back into a ball of radius ε. For a linear model, DeepFool's step is exact: −m·y·w/‖w‖², of length m/‖w‖ ([Moosavi-Dezfooli et al. 2016](https://doi.org/10.1109/CVPR.2016.282)). IX's `universal_perturbation` adds grad·loss/‖grad‖ instead ([`evasion.rs` 107-144](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/evasion.rs#L107-L144)), a step along `gradient_fn` as long as the loss. The doc comment doesn't say whether `gradient_fn` is the loss's gradient or the direction that fools the model. P4 gives it one correctly classified point at a time, with loss = m, in both directions:

```text
== P4, universal_perturbation on one correctly classified point, one iteration, loss = m
  1956 points, largest relative error of the new margin against
    m(1 - |w|) = -m with the fooling direction -y w:   8.8e-14
    m(1 + |w|) = 3m with the loss's gradient +y w:     1.2e-14
    m'(1 - |w|/4) = m'/2 with w/4, m' = m/4:           9.7e-14
  length of the w/4 perturbation against a quarter of the full one: 0.0e0
```

With the fooling direction, the margin goes from m to −m. The step is twice DeepFool's, because the loss m is ‖w‖ = 2 times the distance m/‖w‖. With the loss's gradient, the margin triples, and the perturbation helps the model. Dividing w by 4 describes the same classifier, but the step becomes a quarter as long and stops halfway to the boundary. The step's length depends on the scale of the loss, which a minimal perturbation's shouldn't.

`jsma`, the saliency attack of [Papernot et al. (2016)](https://arxiv.org/abs/1511.07528), has a gap of the same kind: it takes a `_target` argument and never reads it ([`evasion.rs` 73-105](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/evasion.rs#L73-L105)). An exploratory check, not preregistered, confirms it returns the same point for both targets:

```text
== exploratory
  jsma returns the same point for targets 0 and 1: yes
```

## 6. Detection by noise

`detect_adversarial` adds Gaussian noise to the input `n_samples` times, measures the mean squared change of the output, and flags the input when that exceeds a threshold ([`defense.rs` 29-60](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/defense.rs#L29-L60)). Its comment gives the reasoning: "High variance suggests the input sits near a decision boundary — a hallmark of adversarial examples." Two details decide what it measures. The noise comes from a generator seeded with a fixed `seed`, so every input gets the same noise vectors. And for a linear output (z, −z), the change is (w·n, −w·n), which doesn't depend on x at all. P5 runs it on the 2,000 clean test points and their FGSM versions at ε = 0.2, with outputs (z, −z), then with probabilities (p, 1 − p):

```text
== P5, detect_adversarial, sigma 0.1, 50 samples, the 2000 clean points and their FGSM versions at eps 0.2
  outputs (z, -z): score of the first input 0.0353 (expectation 0.04); 4000 of 4000 inputs have it to within 1e-12
  flagged at threshold 0.015: 4000; at 0.09: 0
  control, outputs (p, 1 - p): score nearest the boundary 2.16e-3, farthest 2.25e-12; more than 10 times: yes
```

All 4,000 inputs have the same score to within 10⁻¹². It is 0.0353, one draw around its expectation σ²‖w‖² = 0.04. Whatever the threshold, the detector flags every input or none. With probabilities, the score does depend on the input: 2.16·10⁻³ nearest the boundary against 2.25·10⁻¹² farthest from it. How well it then separates clean inputs from attacked ones wasn't measured; the journal lists it as to verify. The function returns only a boolean, so the lesson recovers each score by bisecting the threshold, and a caller who wants to calibrate the threshold has to do the same.

## 7. Feature squeezing

`feature_squeezing` clamps each value to [0, 1] and rounds it to one of L + 1 levels, L = 2^bits − 1. It is documented as "eliminating small adversarial perturbations that fall below the quantization resolution" ([`defense.rs` 62-72](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/defense.rs#L62-L72)). Rounding doesn't eliminate a change, it concentrates it. A value moved by ε rounds differently when a threshold (k + ½)/L lies between the old and the new value. For uniform values that happens with probability Lε, and the rounded value then moves by a whole level, 1/L. The mean absolute change stays ε, and its root mean square grows to √(ε/L). P6 squeezes 100,000 uniform values, before and after a change of ±ε:

```text
== P6, feature_squeezing of 100000 uniform values moved by +-eps
  3 bits, eps 0.05: changed 0.3510, mean |change| 0.05014, root mean square 0.08463   (formula 0.350, 0.05000, 0.08452)
  5 bits, eps 0.01: changed 0.3094, mean |change| 0.00998, root mean square 0.01794   (formula 0.310, 0.01000, 0.01796)
  0 bits: [NaN, NaN, NaN, NaN]
```

At 3 bits, 35% of the changes of 0.05 survive, each as a jump of 1/7, and the mean change after squeezing is 0.0501, the same as before. [Xu et al. (2018)](https://doi.org/10.14722/ndss.2018.23198) don't use squeezing to clean inputs. They compare the model's outputs on an input and on its squeezed version, and flag the input when the two differ. At 0 bits, L = 0 and every output is 0/0.

## 8. The certified radius

The randomized smoothing of [Cohen et al. (2019)](https://arxiv.org/abs/1902.02918) classifies x by the class most likely under x + N(0, σ²I). If that class has probability at least p_A and any other at most p_B, the prediction can't change within an ℓ₂ radius σ/2·(Φ⁻¹(p_A) − Φ⁻¹(p_B)). `certified_radius` computes that bound from the two largest values of its input, which its doc comment calls logits, after clamping them to [10⁻¹⁰, 1 − 10⁻¹⁰] ([`robustness.rs` 111-144](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/robustness.rs#L111-L144)). Its `probit` is labelled "Beasley-Springer-Moro", but it uses the constants of formula 26.2.23 of [Abramowitz and Stegun](https://personal.math.ubc.ca/~cbm/aands/page_933.htm), whose error is below 4.5·10⁻⁴ ([`robustness.rs` 146-174](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/robustness.rs#L146-L174)). P7 compares it at σ = 1 with the exact radius. The course computes Φ⁻¹ with AS 241 of [Wichura (1988)](https://doi.org/10.2307/2347330), accurate to about 16 digits and tested against known quantiles:

```text
== P7, certified_radius at sigma 1 against the exact radius (AS 241)
  p_A = 0.501 to 0.999, p_B = 1 - p_A: largest error 4.44e-4, at p_A = 0.642
  p_A = 0.9: IX 1.281729, exact 1.281552
  logits (2, -1): 6.3609; logits (3, 1): 0.0000
```

The largest error is 4.44·10⁻⁴, at p_A = 0.642, just under the formula's bound. At p_A = 0.9, IX's radius is 1.8·10⁻⁴ larger than the exact one: small, but in the unsafe direction for a certificate. Logits are the larger trap. Logits (2, −1) are clamped to 1 − 10⁻¹⁰ and 10⁻¹⁰ and certify a radius of 6.36σ, while logits (3, 1) both clamp to 1 − 10⁻¹⁰ and certify 0. The function needs probabilities. Cohen et al. use a lower confidence bound on p_A, estimated from samples of the noise, which IX leaves to the caller.

## 9. Poisoning

Poisoning changes the training data rather than the input, and the crate has three tools against it ([`poisoning.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/poisoning.rs)):

- `detect_label_flips` flags a point whose label disagrees with the majority of its k nearest neighbours (lines 14-61).
- `spectral_signature_defense`, after [Tran et al. (2018)](https://arxiv.org/abs/1811.00636), projects each class on its top principal direction and flags the points strictly above the given percentile of the class's projections (lines 105-180).
- `influence_function` cites [Koh and Liang (2017)](https://arxiv.org/abs/1703.04730). Their influence of a training point on a test prediction goes through that point's loss gradient, and so through its label. IX's version ignores `_train_labels`: each score is (xᵢ·x_test)·(y_test − x̄·x_test)/(n·λ), where x̄ is the mean training row (lines 63-103).

P8 flips 100 of the 1,000 labels of two clusters around (−2, −2) and (2, 2). It then poisons a class of 100 points in 10 dimensions with 5 points shifted by 6 on one feature:

```text
== P8, poisoning
  1000 points in 2 dimensions, 100 labels flipped: influence_function unchanged bit for bit: yes
  detect_label_flips, k = 5: 99 flipped labels found, 11 other points flagged
  spectral_signature_defense, 90th percentile, 100 points per class in 10 dimensions: flagged per class [9, 9]
  with 5 points shifted by 6 added to class 0: flagged per class [10, 9], shifted points among them 5
```

The influence scores don't change when 10% of the labels do, so they can't point to the training points a flipped label hurts. The neighbour vote finds 99 of the 100 flipped labels. A flipped point is missed only when at least 3 of its 5 neighbours were flipped too, which has probability 0.009. The vote also flags 11 correct points, within the predicted 17. The spectral defence flags 9 points per class at the 90th percentile, not the 10 that "the top 10%" suggests, because it flags the scores strictly above the one at index ⌊0.9·n⌋. With the 5 shifted points in class 0, it flags 10 there, and all 5 are among them. The cross-check repeats the vote and the spectral defence with numpy, with its own eigenvectors, and finds the same counts.

## 10. A Lipschitz constant by sampling

`lipschitz_estimate` samples random points within a radius and returns the largest ratio ‖f(x') − f(x)‖/‖x' − x‖ ([`robustness.rs` 72-109](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/robustness.rs#L72-L109)). Sampling can only give a lower bound. A second exploratory check stretches the first of 100 coordinates by 10, a map whose Lipschitz constant is 10:

```text
== exploratory
  lipschitz_estimate of x -> (10 x_0, x_1, ..., x_99), constant 10, 200 samples, 20 seeds: lowest 2.617, median 3.021, highest 3.838
```

The estimates run from 2.6 to 3.8. A random unit direction u puts on average 1/100 of its squared length on the first coordinate, and the ratio is √(1 + 99u₀²), about 1.4 on average. The largest of 200 draws reaches about 3. For a linear map, the constant is the largest singular value. For a network, sampling finds a lower bound, and in 100 dimensions a loose one.

## 11. The predictions, scored

| | Prediction, written before the first run | Measured | Verdict |
|---|---|---|---|
| P1 | Every margin 20ε lower to within 10⁻¹²; exactly the points with 0 < m < 20ε change class; accuracy in [0.967, 0.988], [0.815, 0.867], [0.464, 0.536] and [0.133, 0.185] | 0.9780, 0.8460, 0.4780, 0.1470; margins and points as predicted | Confirmed |
| P2 | Zero gradient: `pgd` and `adversarial_training_augment` at x ± 0.2, `fgsm` at x; half model: 100 features against 50, norms 2 and 1.414, same accuracy; control: `pgd` equals `fgsm` | As predicted; accuracy 0.4865 for both | Confirmed |
| P3 | c = 0.25: every result x; c = 1: ‖δ‖ within 0.02 of m/‖w‖, misclassified in [0.464, 0.536]; c = 0.75: in [0.299, 0.367] | 1,956 of 1,956; within 0.005, 0.5072; 0.3522 | Confirmed |
| P4 | New margin −m with −y·w, 3m with +y·w, m'/2 and a quarter of the length with w/4, to within 10⁻¹² relative | Largest relative error 9.7·10⁻¹⁴ | Confirmed |
| P5 | Every score equal to within 10⁻¹², near 0.04; all flagged at 0.015, none at 0.09; with probabilities, largest more than 10 times the smallest | 4,000 of 4,000 at 0.0353; 4,000 and 0; 2.16·10⁻³ against 2.25·10⁻¹² | Confirmed |
| P6 | 3 bits, ε = 0.05: 0.350 ± 0.005 changed, mean 0.05 and root mean square 0.0845 within 2%; 5 bits, ε = 0.01: 0.310, 0.01, 0.0180; 0 bits: NaN | 0.3510, 0.05014, 0.08463; 0.3094, 0.00998, 0.01794; NaN | Confirmed |
| P7 | Largest error in [10⁻⁴, 4.5·10⁻⁴]; logits (2, −1) about 6.36; (3, 1) 0 | 4.44·10⁻⁴; 6.3609; 0 | Confirmed |
| P8 | Influence bit for bit the same; at least 95 of 100 flips found, at most 17 others; spectral 9 and 9, then 10 in class 0 with all 5 | The same; 99 and 11; 9 and 9, then 10 with all 5 | Confirmed |

All eight held on the first run, and the code compiled at the first try. No interval was changed afterwards. One result was tighter than predicted: Carlini–Wagner's results are within 0.005 of the minimal perturbation, not 0.02, because the objective keeps the nearer of the points around the boundary. Most predictions came from reading a function against its comment, and most found a gap between the two. The controls show that each check can fail: against the full model PGD equals FGSM, with probabilities the detector's score depends on the input, and the spectral defence does find the shifted points.

## What to use for our repositories

- **`fgsm`:** exact on a linear model, where every margin falls by ε‖w‖₁. A good first attack, and a number to report next to the clean accuracy.
- **`pgd` and `adversarial_training_augment`:** they move every feature the loss ignores by the full ε, in a direction set by the sign of zero, and no finite gradient value avoids it, since `signum` never returns 0. Reset those features after the call, or loop `fgsm` with a clip.
- **`cw_attack`:** search over c yourself, above 1/‖∇loss‖, and check that each result is misclassified. At c‖w‖ = 2, half of them weren't.
- **`universal_perturbation`:** pass the fooling direction, not the loss's gradient, and expect steps as long as the loss, not as long as the distance to the boundary.
- **`detect_adversarial`:** useless on a linear output. Since it returns only a boolean, calibrate its threshold on clean inputs by bisection.
- **`feature_squeezing`:** compare the model's outputs with and without it, as Xu et al. do, rather than trusting it to clean an input. Use at least 1 bit.
- **`certified_radius`:** pass a lower bound on p_A, not logits. Its probit can overstate the radius by up to 4.4·10⁻⁴σ.
- **Poisoning:** `detect_label_flips` works on separated clusters, with 99 of 100 flips found and 11 false alarms. `influence_function` doesn't read labels, so it can't find flipped ones. `spectral_signature_defense` flags n − ⌊p·n/100⌋ − 1 points per class.

## Exercises

1. Show that FGSM lowers every margin of a linear model by ε‖w‖₁, and that on this lesson's model the accuracy becomes Φ(2 − 10ε).
2. For a linear model, what are the smallest ℓ₂ and ℓ∞ perturbations that bring a point of margin m to the boundary? Evaluate them at m = 4 for this lesson's w.
3. Show that for the objective ‖δ‖₂ + c·max(m(x + δ), 0) of a linear model, no δ has a lower objective than δ = 0 when c‖w‖ ≤ 1.
4. For values uniform on [0, 1] rounded to L + 1 levels, derive the probability that a change of ±ε ≤ 1/(2L) changes the rounded value, and the root mean square of the change after rounding.
5. Why does `detect_adversarial` give every input the same score on outputs (z, −z)? What would change if each call drew fresh noise?

<details>
<summary>Solutions</summary>

1. The gradient is a positive multiple of −y·w, so x' = x − ε·y·sign(w) and m' = y·w·x' = m − ε·Σ|wⱼ| = m − ε‖w‖₁. Here m = ‖μ‖² + y·w·n is distributed as N(4, ‖w‖²) = N(4, 4), so P(m' > 0) = P(N(4, 4) > 20ε) = Φ((4 − 20ε)/2) = Φ(2 − 10ε).
2. The ℓ₂ perturbation is −m·y·w/‖w‖₂², of length m/‖w‖₂. The ℓ∞ one moves every coordinate by m/‖w‖₁ against the class. With ‖w‖₂ = 2, ‖w‖₁ = 20 and m = 4: 2 and 0.2. Since every wⱼ is equal here, both are the same vector: 0.2 against the class on every feature, a fifth of the noise, of ℓ₂ length 2 and ℓ∞ length 0.2.
3. By Cauchy–Schwarz, m(x + δ) ≥ m − ‖w‖‖δ‖. If ‖δ‖ < m/‖w‖, the objective is at least ‖δ‖ + c(m − ‖w‖‖δ‖) = cm + ‖δ‖(1 − c‖w‖) ≥ cm. Otherwise, it is at least ‖δ‖ ≥ m/‖w‖ ≥ cm. Either way it is at least cm, the objective at δ = 0.
4. The thresholds are at (k + ½)/L for k = 0, …, L − 1. A move of +ε crosses a threshold τ when x lies in (τ − ε, τ), with probability ε, and at most one when ε ≤ 1/(2L). The same holds for −ε, so the probability is Lε. Each crossing moves the rounded value by 1/L, so the mean square is Lε/L² = ε/L and the root mean square √(ε/L).
5. The change of the output is (w·n, −w·n) for noise n, whatever x is, and the fixed seed gives every input the same noises. The score is Σₖ 2(w·nₖ)²/(2·50), identical for all inputs. With fresh noise, the scores would vary around σ²‖w‖², as a scaled χ² with 50 degrees of freedom, but still wouldn't depend on x: noise, not information.

</details>

## Sources

- IX at pinned commit `490c395`: [`evasion.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/evasion.rs), [`defense.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/defense.rs), [`poisoning.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/poisoning.rs), [`robustness.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-adversarial/src/robustness.rs).
- I. J. Goodfellow, J. Shlens and C. Szegedy, ["Explaining and harnessing adversarial examples"](https://arxiv.org/abs/1412.6572), ICLR 2015.
- A. Madry, A. Makelov, L. Schmidt, D. Tsipras and A. Vladu, ["Towards deep learning models resistant to adversarial attacks"](https://arxiv.org/abs/1706.06083), ICLR 2018.
- N. Carlini and D. Wagner, ["Towards evaluating the robustness of neural networks"](https://doi.org/10.1109/SP.2017.49), IEEE Symposium on Security and Privacy, 2017.
- N. Papernot, P. McDaniel, S. Jha, M. Fredrikson, Z. B. Celik and A. Swami, ["The limitations of deep learning in adversarial settings"](https://arxiv.org/abs/1511.07528), IEEE European Symposium on Security and Privacy, 2016.
- S.-M. Moosavi-Dezfooli, A. Fawzi and P. Frossard, ["DeepFool: a simple and accurate method to fool deep neural networks"](https://doi.org/10.1109/CVPR.2016.282), CVPR 2016; with O. Fawzi, ["Universal adversarial perturbations"](https://doi.org/10.1109/CVPR.2017.17), CVPR 2017.
- W. Xu, D. Evans and Y. Qi, ["Feature squeezing: detecting adversarial examples in deep neural networks"](https://doi.org/10.14722/ndss.2018.23198), NDSS 2018.
- J. Cohen, E. Rosenfeld and J. Z. Kolter, ["Certified adversarial robustness via randomized smoothing"](https://arxiv.org/abs/1902.02918), ICML 2019.
- M. Abramowitz and I. A. Stegun, *Handbook of Mathematical Functions*, [formula 26.2.23](https://personal.math.ubc.ca/~cbm/aands/page_933.htm). M. J. Wichura, ["Algorithm AS 241: the percentage points of the normal distribution"](https://doi.org/10.2307/2347330), Applied Statistics 37, 1988.
- P. W. Koh and P. Liang, ["Understanding black-box predictions via influence functions"](https://arxiv.org/abs/1703.04730), ICML 2017.
- B. Tran, J. Li and A. Madry, ["Spectral signatures in backdoor attacks"](https://arxiv.org/abs/1811.00636), NeurIPS 2018.
- Rust: [`f64::signum`](https://doc.rust-lang.org/std/primitive.f64.html#method.signum). NumPy: [`sign`](https://numpy.org/doc/stable/reference/generated/numpy.sign.html).
