---
title: "8. Optimisation : descente, momentum, Adam, et recherches sans gradient"
description: "Trois règles de mise à jour le long de la vallée de Rosenbrock, écrites à la main et suivies pas à pas par ix_optimize ; ce que coûte en évaluations un gradient que personne n'a écrit ; pourquoi minimize renvoie une réponse finie pour une exécution partie en NaN ; et le recuit simulé et l'essaim particulaire sur la même fonction."
sidebar:
  order: 8
---

La leçon 2 ajustait une droite par descente de gradient et découvrait qu'un pas trop grand diverge. La leçon 7 découvrait que la taille du pas n'est pas toujours le nombre que vous avez passé. Cette leçon regarde la règle de mise à jour elle-même, sur une fonction choisie pour rendre les différences visibles.

La **fonction de Rosenbrock**, `(1 - x)² + 100(y - x²)²`, a son minimum en `(1, 1)` où elle vaut 0. Autour de ce minimum court une vallée longue, courbe, presque plate, aux parois raides. La descente simple rebondit entre les parois et rampe sur le fond ; c'est la façon classique de voir ce qu'achètent le momentum et les pas par coordonnée.

| | ML.NET | Tribuo | PyTorch | IX |
|---|---|---|---|---|
| Descente simple | `OnlineGradientDescent` | [`SGD`](https://tribuo.org/learn/4.3/javadoc/org/tribuo/math/optimisers/SGD.html) | `optim.SGD` | `ix_optimize::gradient::SGD` |
| Momentum | — | `SGD.getLinearDecaySGD` avec momentum | `optim.SGD(momentum=…)` | `ix_optimize::gradient::Momentum` |
| Adam | — | [`Adam`](https://tribuo.org/learn/4.3/javadoc/org/tribuo/math/optimisers/Adam.html) | `optim.Adam` | `ix_optimize::gradient::Adam` |
| Sans gradient | — | — | — | `annealing::SimulatedAnnealing`, `pso::ParticleSwarm` |

Le programme est [`examples/l08_optimization.rs`](https://github.com/spareilleux/learn/blob/37b8830/code/machine-learning-ix/examples/l08_optimization.rs), au départ de `(-1.2, 1.0)`, le point qu'emploie l'article de Rosenbrock.

## Trois règles

La **descente simple** soustrait le gradient : `p ← p - α g`. Elle a un problème dans une vallée — le gradient pointe en travers de la vallée bien plus fortement que le long d'elle, donc l'essentiel du pas est gaspillé en allers-retours.

Le **momentum** tient une vitesse courante, `v ← βv + αg`, et soustrait celle-ci. Les pas qui continuent de pointer dans le même sens s'accumulent ; ceux qui alternent s'annulent. Dans une vallée, c'est exactement le bon réflexe.

**Adam** tient deux moyennes courantes : la moyenne du gradient et celle de son carré. Il divise l'une par la racine de l'autre, ce qui donne à chaque coordonnée son propre pas — grand là où le gradient a été petit et régulier, petit là où il a été grand et bruité. Les deux moyennes partent de zéro, si bien que les premiers pas seraient trop petits ; diviser par `1 - βᵗ` corrige cela ([`src/optimize.rs`, lignes 101-125](https://github.com/spareilleux/learn/blob/37b8830/code/machine-learning-ix/src/optimize.rs#L101-L125)) :

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

La descente simple épuise ses 5000 pas sans atteindre le minimum. Le momentum, au même taux d'apprentissage, arrive en 4129. Adam arrive en 2822 avec un taux cinquante fois plus grand, ce qui est la raison pratique pour laquelle il est le choix par défaut à peu près partout : il est bien moins sensible au nombre que vous choisissez.

La version à la main et `ix_optimize` s'accordent exactement — mêmes nombres de pas, mêmes points finaux, et même premier pas depuis le même gradient :

```text
== the first Adam step from the same gradient
  gradient [-215.6000, -88.0000]
  hand [-1.15000000, 1.05000000]
  ix   [-1.15000000, 1.05000000]
```

Ce premier pas mérite d'être lu. Le gradient vaut `[-215.6, -88]`, follement différent selon les deux coordonnées, et Adam les déplace toutes deux d'exactement 0,05 — le taux d'apprentissage. Au premier pas, la correction de biais rend `mean_hat` égal au gradient et `square_hat` égal à son carré, si bien que le rapport est le *signe* du gradient et rien d'autre. Adam commence par ignorer complètement la taille du gradient.

## Un gradient que personne n'a écrit

`ObjectiveFunction::gradient` a une implémentation par défaut : si vous n'en fournissez pas, il est mesuré par différences centrées ([`traits.rs`, lignes 10-13](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-optimize/src/traits.rs#L10-L13)) :

```rust
fn gradient(&self, x: &Array1<f64>) -> Array1<f64> {
    ix_math::calculus::numerical_gradient(&|p: &Array1<f64>| self.evaluate(p), x, 1e-7)
}
```

`ClosureObjective`, l'enveloppe de confort, ne le redéfinit jamais. Envelopper une closure coûte donc deux évaluations supplémentaires de l'objectif par coordonnée et par pas — et achète un gradient exact à environ huit chiffres :

```text
== the gradient at the start, written and measured
  written  [-215.600000000, -88.000000000]
  measured [-215.600000093, -87.999999998]
  largest gap 9.30e-8, and two extra evaluations of f per coordinate per step
  Adam on ClosureObjective: best f 1.061e-16 against 1.061e-16 with the written gradient
```

Les deux exécutions atterrissent sur la même valeur à tous les chiffres imprimés. C'est la conclusion honnête ici : pour un objectif lisse en deux dimensions, le gradient mesuré suffit, et le coût est en évaluations, pas en précision. L'exercice les compte — 1001 contre 201 pour 200 pas — et le rapport croît avec le nombre de paramètres, ce qui est la raison pour laquelle personne n'entraîne un réseau de neurones ainsi.

## Une réponse finie pour une exécution qui a divergé

`minimize` retient le meilleur point traversé et renvoie celui-là, pas celui où elle a fini ([`gradient.rs`, lignes 124-165](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-optimize/src/gradient.rs#L124-L165)). D'ordinaire c'est une gentillesse. Quand l'exécution diverge, c'est un piège :

```text
== a step size that diverges
  ix SGD lr 0.01: best f 24.200000 after 5000 steps, converged false
  the same run by hand ends at f NaN — the best point hides the divergence
```

24,200000 vaut `f(-1.2, 1.0)` — le point de départ. À un taux d'apprentissage de 0,01, le tout premier pas dépasse, chacun des suivants dépasse davantage, les valeurs filent vers l'infini puis vers NaN, et comme aucune valeur n'a jamais été plus petite que la première, `best_params` est encore le point que l'appelant a fourni. Le résultat ressemble à une réponse ordinaire : une valeur finie, un point fini, 5000 itérations.

Le seul champ qui proteste est `converged: false` — et la descente simple renvoie `converged: false` pour une exécution qui s'est terminée tout à fait honorablement à 0,003761, elle aussi. Donc `converged` ne sépare pas les deux cas, et `best_value` non plus. Un appelant qui veut savoir si une optimisation a fonctionné doit comparer l'objectif au point renvoyé à l'objectif au départ, et refuser un résultat qui n'a pas progressé.

## Deux recherches qui ne demandent jamais de gradient

Certains objectifs n'ont pas de gradient — une configuration discrète, une simulation, un score de boîte noire. IX livre deux des réponses classiques.

Le **recuit simulé** propose un voisin aléatoire et l'accepte toujours s'il est meilleur ; s'il est pire, il l'accepte quand même avec probabilité `exp(-Δ/T)`, où la température `T` décroît avec le temps. Chaud, il vagabonde librement et s'échappe des minima locaux ; froid, il ne descend plus que la pente.

L'**essaim particulaire** fait voler une population de points, chacun attiré vers le meilleur point qu'il a personnellement vu et vers le meilleur point que quiconque a vu.

```text
== without a gradient
  simulated annealing, seed 42: best [0.9934, 0.9881] f 0.000193 after 3216 iterations
  particle swarm, 40 particles, seed 42: best [1.0000, 1.0000] f 0.000000
```

Le recuit s'arrête à l'itération 3216, quand le programme exponentiel fait passer la température sous `min_temp`, et obtient quatre chiffres de la réponse. L'essaim, avec 40 particules sur 200 itérations — 8000 évaluations — atterrit sur le minimum. Les deux s'en tirent honorablement sur un problème où le gradient écrit demandait 2822 pas ; les deux seraient un mauvais choix *parce que* le gradient existe.

## Retour à la droite

Les trois mêmes règles sur la perte de la leçon 2, centrée-réduite, là où la réponse est connue :

```text
== the build-time line, standardized: closed form slope 0.667448, intercept 0
  SGD        106 steps: slope 0.667448, intercept -0.000000, loss 0.554513
  Momentum   366 steps: slope 0.667448, intercept -0.000000, loss 0.554513
  Adam       384 steps: slope 0.667448, intercept -0.000000, loss 0.554513
```

Tous trois atteignent la forme close à six décimales, et la descente simple y arrive la première. Sur une cuvette ronde avec un taux d'apprentissage bien choisi, le momentum n'a rien à accumuler et Adam rien à remettre à l'échelle ; tous deux ne font qu'ajouter leur propre dynamique par-dessus un problème qui n'en avait pas besoin. La vallée de Rosenbrock et cette cuvette sont les deux bouts de la même histoire, et savoir à quel bout vous êtes est une propriété du problème, pas de l'optimiseur.

## À retenir

- La descente simple rebondit entre les parois de la vallée de Rosenbrock. Le momentum accumule les pas qui vont dans le même sens, et Adam donne à chaque coordonnée son propre pas, ce qui l'a mené au minimum en 2822 pas.
- Les versions à la main et `ix_optimize` s'accordent pas à pas. Le premier pas d'Adam déplace chaque coordonnée du taux d'apprentissage, quelle que soit la taille du gradient.
- Sans gradient écrit, IX en mesure un par différences centrées : juste à environ huit chiffres, au prix de deux évaluations supplémentaires par coordonnée et par pas.
- `minimize` renvoie le meilleur point par lequel il est passé : une exécution qui a divergé jusqu'à NaN renvoie donc son point de départ comme une réponse finie ; compare l'objectif au résultat avec l'objectif au départ.
- Le recuit simulé et l'essaim de particules n'ont pas besoin de gradient, mais sont un mauvais choix quand il en existe un, et sur un bol rond la descente simple finit la première : c'est le problème qui décide quelle règle gagne.

## Exercices

1. Quel est le plus grand taux d'apprentissage de descente simple qui atteigne encore la vallée en 5000 pas ?
2. Combien d'évaluations de l'objectif coûte un gradient manquant sur 200 pas d'Adam ?
3. Comment le coefficient de momentum change-t-il le nombre de pas ?

<details>
<summary>Solutions</summary>

Elles sont dans [`examples/l08_exercises.rs`](https://github.com/spareilleux/learn/blob/37b8830/code/machine-learning-ix/examples/l08_exercises.rs).

**1.** 0,002 — et le bord est net :

```text
== plain descent on Rosenbrock, 5000 steps, by learning rate
  rate 0.0001 : ends at f 2.305718
  rate 0.0005 : ends at f 0.042952
  rate 0.001  : ends at f 0.003761
  rate 0.002  : ends at f 0.000055
  rate 0.005  : ends at f 0.788039
  rate 0.01   : ends at f NaN
```

En dessous de 0,002 l'exécution est stable et lente ; à 0,002 elle est stable et bien plus rapide ; à 0,005 elle est instable mais encore bornée ; à 0,01 elle est perdue. La fenêtre utilisable couvre un facteur d'environ cinq, et rien d'autre que l'essai ne dit où elle se trouve. Adam à 0,05 était confortablement au milieu d'une fenêtre bien plus large.

**2.** Cinq fois plus :

```text
== evaluations of f for 200 Adam steps
  written gradient true : 201 evaluations, best f 2.588e0
  written gradient false: 1001 evaluations, best f 2.588e0
```

201, c'est une par pas plus la première. 1001, c'est cela plus `2 × 2 coordonnées × 200 pas`. Avec `d` paramètres le facteur est `1 + 2d`, donc un modèle à mille paramètres paierait deux mille fois plus — et atteindrait le même point, comme le montre la colonne `best f`.

**3.** Plus de momentum aide, jusqu'à ce que ça n'aide plus :

```text
== momentum coefficient against steps to reach f < 1e-10
  0    : 20000 steps, last [0.9999, 0.9997] f 1.938e-8
  0.5  : 20000 steps, last [1.0000, 1.0000] f 2.130e-15
  0.9  :  4129 steps, last [1.0000, 1.0000] f 1.244e-16
  0.95 :  1790 steps, last [1.0000, 1.0000] f 1.242e-16
  0.99 :  4014 steps, last [1.0000, 1.0000] f 4.696e-18
```

Avec `β = 0` c'est la descente simple, et 20 000 pas ne suffisent pas à déclencher le test sur la norme du gradient. 0,95 est le meilleur des cinq, à 1790 pas. À 0,99 la vitesse emporte si loin au-delà du virage que l'exécution prend plus du double de temps — et atterrit sur le point le plus précis des cinq, ayant spiralé vers l'intérieur. Les valeurs par défaut usuelles, 0,9 et 0,99, encadrent l'optimum ici, ce qui donne une image juste de l'intérêt qu'il y a à régler ce paramètre.

</details>

## Sources

- Rosenbrock, *[An automatic method for finding the greatest or least value of a function](https://academic.oup.com/comjnl/article/3/3/175/345501)*, 1960
- Kingma et Ba, *[Adam: A Method for Stochastic Optimization](https://arxiv.org/abs/1412.6980)*, 2015
- Goodfellow, Bengio, Courville, *[Deep Learning](https://www.deeplearningbook.org/)*, chapitre 8
- Kirkpatrick, Gelatt et Vecchi, *[Optimization by Simulated Annealing](https://www.science.org/doi/10.1126/science.220.4598.671)*, 1983
- [PyTorch : `torch.optim`](https://docs.pytorch.org/docs/stable/optim.html)
- IX en `490c395` : [`ix-optimize/src/gradient.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-optimize/src/gradient.rs), [`ix-optimize/src/traits.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-optimize/src/traits.rs), [`ix-optimize/src/annealing.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-optimize/src/annealing.rs), [`ix-optimize/src/pso.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-optimize/src/pso.rs), [`ix-math/src/calculus.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-math/src/calculus.rs)
