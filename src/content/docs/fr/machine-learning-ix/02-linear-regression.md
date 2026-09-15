---
title: 2. Régression linéaire et descente de gradient
description: Une droite à travers les temps de build de ce site, par les moindres carrés en forme close et par descente de gradient — à la main, avec l'équation normale d'IX et avec ses optimiseurs SGD, Momentum et Adam — pourquoi la descente diverge sur les caractéristiques brutes, ce que change la standardisation, et une valeur aberrante qui décide de la pente.
sidebar:
  order: 2
---

La leçon 1 prédisait chaque build avec une constante. Cette leçon laisse la prédiction dépendre d'une caractéristique, le nombre de pages, selon le plus vieux modèle qui soit : une droite, `seconds = w · pages + b`. Trouver `w` et `b`, c'est la **régression linéaire**. On peut la résoudre exactement, avec une formule, ou pas à pas, par **descente de gradient** ; la seconde méthode est celle qui entraîne presque tous les autres modèles d'apprentissage automatique, alors elle vaut la peine d'être vue sur un problème dont on connaît la réponse exacte.

| | ML.NET | Tribuo | scikit-learn | IX |
|---|---|---|---|---|
| Moindres carrés exacts | [`Ols`](https://learn.microsoft.com/dotnet/api/microsoft.ml.mklcomponentscatalog.ols) | [`LARSTrainer`](https://tribuo.org/learn/4.3/javadoc/org/tribuo/regression/slm/LARSTrainer.html), régression par moindres angles | [`LinearRegression`](https://scikit-learn.org/stable/modules/generated/sklearn.linear_model.LinearRegression.html) | `ix_supervised::linear_regression::LinearRegression` |
| Par descente de gradient | [`OnlineGradientDescent`](https://learn.microsoft.com/dotnet/api/microsoft.ml.standardtrainerscatalog.onlinegradientdescent) | [`LinearSGDTrainer`](https://tribuo.org/learn/4.3/javadoc/org/tribuo/regression/sgd/linear/LinearSGDTrainer.html) | [`SGDRegressor`](https://scikit-learn.org/stable/modules/sgd.html) | une perte et `ix_optimize::gradient::minimize` |
| Optimiseurs | — | [`AdaGrad`](https://tribuo.org/learn/4.3/javadoc/org/tribuo/math/optimisers/AdaGrad.html), [`Adam`](https://tribuo.org/learn/4.3/javadoc/org/tribuo/math/optimisers/Adam.html)… | une planification du `learning_rate` | `SGD`, `Momentum`, `Adam` |

Le programme de cette leçon est [`examples/l02_linear_regression.rs`](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/examples/l02_linear_regression.rs). Il entraîne sur les 52 builds les plus anciens et teste sur les 13 plus récents, le découpage chronologique de la leçon 1.

## Moindres carrés

Quelle droite ? Celle qui a la plus petite erreur quadratique moyenne sur les lignes d'entraînement :

```text
L(w, b) = 1/n Σ (w·xᵢ + b - yᵢ)²
```

Au minimum, les deux dérivées partielles de `L` sont nulles. Résoudre les deux équations donne la forme close, avec `x̄` et `ȳ` les moyennes :

```text
w = Σ (xᵢ - x̄)(yᵢ - ȳ) / Σ (xᵢ - x̄)²        b = ȳ - w·x̄
```

`w` est la covariance des pages et des secondes divisée par la variance des pages ([`src/linear.rs`, lignes 5-13](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/src/linear.rs#L5-L13)) :

```rust
pub fn fit_closed_form(x: &Array1<f64>, y: &Array1<f64>) -> (f64, f64) {
    let n = x.len() as f64;
    let (mx, my) = (x.sum() / n, y.sum() / n);
    let cov: f64 = x.iter().zip(y).map(|(a, b)| (a - mx) * (b - my)).sum();
    let var: f64 = x.iter().map(|a| (a - mx).powi(2)).sum();
    let w = cov / var;
    (w, my - w * mx)
}
```

Avec plusieurs caractéristiques, le même raisonnement donne l'**équation normale**. On ajoute à **X** une colonne de uns pour `b` ; les paramètres sont `θ = (XᵀX)⁻¹ Xᵀy`. C'est ce que calcule [`LinearRegression::fit`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-supervised/src/linear_regression.rs#L57-L79), avec une inversion de matrice :

```rust
let ones = Array2::ones((n, 1));
let x_aug = ndarray::concatenate(Axis(1), &[x.view(), ones.view()]).unwrap();
let xtx = x_aug.t().dot(&x_aug);
let xty = x_aug.t().dot(y);
let xtx_inv = ix_math::linalg::inverse(&xtx).expect("X^T X is singular");
let w = xtx_inv.dot(&xty);
```

```text
== least squares on the 52 training builds
hand: seconds = 0.041707 * pages + 9.708880
ix:   seconds = 0.041707 * pages + 9.708880
same to 1e-9: true
```

Environ 10 secondes de coût fixe, plus 0.04 seconde par page, soit 24 pages par seconde. scikit-learn trouve la même droite dans la vérification croisée. Inverser `XᵀX` convient pour quelques caractéristiques ; cela échoue quand deux caractéristiques sont des copies exactes l'une de l'autre, où `XᵀX` n'a pas d'inverse et `fit` panique avec ce message (*à vérifier* sur des données), et cela perd en précision quand elles le sont presque. Des bibliothèques comme scikit-learn résolvent le problème des moindres carrés sans former l'inverse.

## Sur les builds de test

```text
== 13 test builds
line:     rmse 7.952, mae 4.574, r2 -0.180
baseline: rmse 10.344, mae 7.308, r2 -0.996
  93a0ea8 274 pages: actual 23 s, predicted 21.1 s, error +1.9
  a7a6f72 274 pages: actual 21 s, predicted 21.1 s, error -0.1
  fd52d46 277 pages: actual 24 s, predicted 21.3 s, error +2.7
  bd17932 271 pages: actual 24 s, predicted 21.0 s, error +3.0
  3147e64 277 pages: actual 23 s, predicted 21.3 s, error +1.7
  e5254f6 280 pages: actual 25 s, predicted 21.4 s, error +3.6
  b96934a 283 pages: actual 18 s, predicted 21.5 s, error -3.5
  35c2e3e 283 pages: actual 20 s, predicted 21.5 s, error -1.5
  85a8c04 283 pages: actual 19 s, predicted 21.5 s, error -2.5
  b0803c9 283 pages: actual 29 s, predicted 21.5 s, error +7.5
  bcfc3fc 283 pages: actual 26 s, predicted 21.5 s, error +4.5
  849fb18 286 pages: actual 21 s, predicted 21.6 s, error -0.6
  95a3830 289 pages: actual 48 s, predicted 21.8 s, error +26.2
without the 48 s build: rmse 3.336, mae 2.769, r2 -0.234
```

La droite bat la référence : son erreur typique passe de 10 à 8 secondes, et à 3 sans le dernier build. Son R² reste négatif, et empire sans ce build. Les builds de test ont tous entre 271 et 289 pages, si bien que la droite prédit 21 à 22 secondes pour chacun d'eux ; ce qui varie de 18 à 29 secondes est quelque chose que le nombre de pages ne mesure pas. Le R² compare le modèle avec la moyenne du jeu de test, et sur un intervalle aussi étroit, la droite n'a rien à expliquer. Les métriques répondent à une question précise : ici, « le nombre de pages explique-t-il les différences entre ces 13 builds ? », et la réponse est non.

Le build de 48 secondes correspond à une seule exécution CI ; je n'en ai pas cherché la cause (*à vérifier*).

## Descente de gradient

La forme close existe parce que la perte est une simple quadratique. Pour la plupart des modèles, il n'y a pas de formule, et on trouve les paramètres en descendant la pente. Le **gradient** de `L` pointe vers le haut ; chaque pas déplace un peu les paramètres dans la direction opposée, multiplié par le **taux d'apprentissage** `α` :

```text
∂L/∂w = 2/n Σ (w·xᵢ + b - yᵢ)·xᵢ        ∂L/∂b = 2/n Σ (w·xᵢ + b - yᵢ)
w ← w - α · ∂L/∂w                        b ← b - α · ∂L/∂b
```

[`src/linear.rs`, lignes 15-32](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/src/linear.rs#L15-L32) :

```rust
let (mut dw, mut db) = (0.0, 0.0);
for (xi, yi) in x.iter().zip(y) {
    let error = w * xi + b - yi;
    dw += 2.0 * error * xi / n;
    db += 2.0 * error / n;
}
(w - learning_rate * dw, b - learning_rate * db)
```

En partant de `w = 0` et `b = 0`, sur les nombres de pages tels quels, en affichant la perte après 1, 10, 1 000 et 100 000 pas :

```text
== gradient descent by hand, raw pages
learning rate 3e-5: step 1 loss 4.957e2 step 10 loss 3.373e4 step 1000 loss 4.538e207 step 100000 loss NaN
  -> w NaN, b NaN
learning rate 1e-5: step 1 loss 3.354e1 step 10 loss 1.565e1 step 1000 loss 1.561e1 step 100000 loss 1.235e1
  -> w 0.080177, b 1.813045
```

Avec `α = 3e-5`, la perte grandit à chaque pas jusqu'au dépassement de capacité. Avec `α = 1e-5`, après 100 000 pas, la droite est encore loin de `w = 0.0417, b = 9.71`. Les deux problèmes ont une seule cause : la perte est une vallée très raide dans une direction et presque plate dans l'autre.

La courbure de `L` est sa matrice des dérivées secondes, `2 · [[mean(x²), mean(x)], [mean(x), 1]]`. Avec les pages d'entraînement de la leçon 1 (moyenne 184.0, écart-type 62.5), ses valeurs propres valent environ 75 500 dans la direction raide et 0.21 dans la direction plate. Un pas dépasse le fond, et la descente diverge, quand `α` est plus grand que 2 divisé par la plus forte courbure, environ 2.6e-5 : 3e-5 est au-dessus. En dessous, la direction plate se réduit d'un facteur `1 - α · 0.21` par pas : avec `α = 1e-5`, 100 000 pas n'enlèvent qu'un cinquième de la distance.

**Standardiser** la caractéristique rend la vallée ronde. Avec `z = (pages - μ) / σ`, `mean(z) = 0` et `mean(z²) = 1`, la courbure vaut `2` dans toutes les directions, et `α = 0.1` réduit l'erreur d'un facteur 0.8 par pas dans les deux. La droite trouvée sur `z` se reconvertit en pages : `w = ws / σ` et `b = bs - ws · μ / σ`.

```text
== gradient descent by hand, standardized pages, learning rate 0.1
100 steps: ws 2.605694, bs 17.384615 -> w 0.041707, b 9.708880
```

100 pas atteignent la forme close à six décimales près. `bs` est la moyenne des secondes d'entraînement, comme il se doit quand la caractéristique a une moyenne de 0.

## Les optimiseurs d'IX

`ix-optimize` sépare les trois parties d'une descente : une fonction à minimiser, un optimiseur qui transforme un gradient en pas, et une boucle. La fonction implémente [`ObjectiveFunction`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-optimize/src/traits.rs#L5-L17) : `evaluate` est obligatoire ; `gradient` a une implémentation par défaut qui l'estime numériquement, à partir de `(f(x + ε) - f(x - ε)) / 2ε` avec `ε = 1e-7` pour chaque paramètre ([`calculus.rs`, lignes 7-21](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-math/src/calculus.rs#L7-L21)). Le `Mse` de la leçon donne le gradient exact ([lignes 16-36](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/examples/l02_linear_regression.rs#L16-L36)) ; `ClosureObjective` enveloppe une closure et garde l'implémentation par défaut.

Les trois optimiseurs, avec `g` le gradient ([`gradient.rs`, lignes 19-116](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-optimize/src/gradient.rs#L19-L116)) :

| Optimiseur | Pas | Idée |
|---|---|---|
| `SGD(α)` | `θ ← θ - α·g` | la descente ci-dessus |
| `Momentum(α, β)` | `v ← β·v - α·g`, `θ ← θ + v` | une bille qui garde une partie de sa vitesse : plus rapide le long d'une longue vallée plate |
| `Adam(α)` | `m ← β₁·m + (1-β₁)·g`, `s ← β₂·s + (1-β₂)·g²`, `θ ← θ - α·m̂ / (√ŝ + ε)` | le pas de chaque paramètre divisé par la taille de ses gradients récents |

`m̂` et `ŝ` sont `m` et `s` corrigés du départ à zéro, et IX utilise `β₁ = 0.9`, `β₂ = 0.999`. Malgré son nom, `SGD` n'est pas stochastique ici : `minimize` lui passe le gradient sur toutes les lignes à chaque pas. La descente de gradient stochastique, comme `OnlineGradientDescent` de ML.NET, utilise une ligne ou un petit lot par pas.

[`minimize`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-optimize/src/gradient.rs#L124-L168) s'arrête quand la norme du gradient passe sous la tolérance, et renvoie les meilleurs paramètres qu'il a vus :

```text
== ix_optimize::gradient::minimize, from [0, 0]
SGD(0.1), exact gradient       iterations    79, converged true , loss 5.908583, w 0.041707, b 9.708880
SGD(0.1), numerical gradient   iterations    79, converged true , loss 5.908583, w 0.041707, b 9.708880
Adam(0.1), exact gradient      iterations   868, converged true , loss 5.908583, w 0.041707, b 9.708880
closed-form loss on the training builds: 5.908583
```

Le gradient numérique ne change rien ici : la perte est une quadratique, pour laquelle une différence centrée est exacte aux arrondis près. `SGD` s'arrête après 79 itérations, la boucle à la main après 100, parce qu'ils s'arrêtent sur des tests différents : la norme du gradient sous 1e-6, et un pas qui bouge de moins de 1e-9. Adam en demande 868 : ses pas sont divisés par la taille récente des gradients, si bien qu'ils ne rétrécissent pas en proportion du gradient près du minimum, et le gradient met plus longtemps à passer sous la tolérance. Adam est conçu pour les problèmes où les gradients des différents paramètres ont des tailles très différentes ; après standardisation, celui-ci n'en a pas.

## À retenir

- Les moindres carrés ont une forme close, `w = cov(x, y) / var(x)`, et l'équation normale pour plusieurs caractéristiques. IX la calcule avec une inversion de matrice, et coïncide avec la version à la main et scikit-learn à 1e-9 près.
- La descente de gradient diverge quand le taux d'apprentissage dépasse 2 divisé par la plus forte courbure, et se traîne le long des directions plates. Des caractéristiques à des échelles différentes provoquent les deux à la fois ; la standardisation règle le problème.
- Une droite peut battre la référence et avoir quand même un R² négatif : vérifie avec quoi une métrique compare le modèle.
- Dans IX, un modèle à entraîner est une `ObjectiveFunction` ; `minimize` exécute la boucle avec `SGD` (sur le lot complet), `Momentum` ou `Adam`, et sans méthode `gradient` en utilise un numérique.

## Exercices

Les solutions sont dans [`examples/l02_exercises.rs`](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/examples/l02_exercises.rs), et leur sortie dans `expected/l02_exercises.txt`.

1. Ajuste la droite sur les 65 builds. Puis ajuste-la 65 fois, en retirant chaque fois un build, et affiche les trois builds dont le retrait change le plus la pente.

<details>
<summary>Solution</summary>

[Lignes 17-34](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/examples/l02_exercises.rs#L17-L34) :

```rust
let (w, b) = fit_closed_form(&pages, seconds);
let mut changes: Vec<(f64, usize)> = (0..pages.len())
    .map(|i| {
        let keep: Vec<usize> = (0..pages.len()).filter(|&j| j != i).collect();
        let (wi, _) = fit_closed_form(&pick(&pages, &keep), &pick(seconds, &keep));
        ((wi - w).abs(), i)
    })
    .collect();
changes.sort_by(|a, c| c.0.total_cmp(&a.0));
```

```text
== exercise 1
all 65 builds: seconds = 0.053333 * pages + 8.0049
without 95a3830 (289 pages, 48 s): slope changes by 0.007328
without b0803c9 (283 pages, 29 s): slope changes by 0.001631
without b96934a (283 pages, 18 s): slope changes by 0.001408
```

Un build sur 65 déplace la pente de 14 %, quatre fois plus que n'importe quel autre. Il a le plus de pages et la plus grande erreur : les moindres carrés élèvent les erreurs au carré, si bien qu'un point loin de la droite et loin de la moyenne tire le plus fort sur la droite. C'est l'**influence** ; la statistique la mesure avec la distance de Cook, et les pertes robustes, comme la perte de Huber du `SGDRegressor` de scikit-learn, la réduisent.

</details>

2. Sur les 65 builds, standardisés, compare `SGD` et `Momentum(0.9)` d'IX en partant de `[0, 0]`, avec des taux d'apprentissage de 0.01 et 0.1. Lequel demande le moins d'itérations, et pourquoi la réponse change-t-elle avec le taux d'apprentissage ?

<details>
<summary>Solution</summary>

[Lignes 36-65](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/examples/l02_exercises.rs#L36-L65) :

```rust
for learning_rate in [0.01, 0.1] {
    let plain = minimize(
        &objective,
        &mut SGD::new(learning_rate),
        array![0.0, 0.0],
        &criteria,
    );
    let momentum = minimize(
        &objective,
        &mut Momentum::new(learning_rate, 0.9),
        array![0.0, 0.0],
        &criteria,
    );
    // …
}
```

```text
== exercise 2
learning rate 0.01: SGD 866 iterations (loss 16.315161), Momentum(0.9) 270 iterations (loss 16.315161)
learning rate 0.1: SGD 80 iterations (loss 16.315161), Momentum(0.9) 284 iterations (loss 16.315161)
```

Momentum gagne avec 0.01 et perd avec 0.1. Standardisée sur ses propres lignes, la perte a une courbure de 2 dans toutes les directions, si bien que la descente simple réduit l'erreur d'un facteur `1 - 2α` par pas : 0.98 avec `α = 0.01`, 0.8 avec `α = 0.1`. Avec le momentum, l'erreur suit `eₜ₊₁ = (1 + β - 2α)·eₜ - β·eₜ₋₁` ; pour les deux taux d'apprentissage, cette récurrence oscille, et son amplitude se réduit de `√β ≈ 0.95` par pas. 0.95 bat 0.98, et perd face à 0.8. Le momentum aide quand la descente simple est lente, dans les longues vallées plates ; sur une cuvette ronde avec un bon taux d'apprentissage, il n'ajoute que du dépassement.

</details>

## Sources

- James, Witten, Hastie, Tibshirani, Taylor, *[An Introduction to Statistical Learning](https://www.statlearning.com/)*, chapitre 3
- Goodfellow, Bengio, Courville, *[Deep Learning](https://www.deeplearningbook.org/)*, chapitre 4 (courbure et taux d'apprentissage) et chapitre 8 (momentum, Adam)
- [scikit-learn : modèles linéaires](https://scikit-learn.org/stable/modules/linear_model.html) et [descente de gradient stochastique](https://scikit-learn.org/stable/modules/sgd.html)
- IX à `490c395` : [`ix-supervised/src/linear_regression.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-supervised/src/linear_regression.rs), [`ix-optimize/src/gradient.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-optimize/src/gradient.rs), [`ix-optimize/src/traits.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-optimize/src/traits.rs)
