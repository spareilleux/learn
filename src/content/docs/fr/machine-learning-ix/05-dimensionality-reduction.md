---
title: "5. Composantes principales, et ce que signifie un ratio de variance"
description: "Cinq durées d'intégration continue ramenées à deux, en diagonalisant leur matrice de covariance — les rotations de Jacobi à la main contre l'itération de puissance d'IX, le ratio de variance expliquée qu'IX normalise sur les composantes retenues plutôt que sur les données, et un nuage dont l'axe principal échappe à l'itération de puissance parce que son vecteur de départ lui est orthogonal."
sidebar:
  order: 5
---

Les leçons 3 et 4 travaillaient toutes deux sur les mêmes cinq nombres : les secondes qu'un job d'intégration continue passe à attendre, à s'installer, à cloner, à nettoyer et à finir. Cinq nombres, c'est déjà trop pour dessiner, et deux d'entre eux — `checkout_s` et `post_checkout_s` — portent presque la même information. La **réduction de dimension** demande moins de nombres qui perdent le moins possible.

La réponse la plus ancienne est l'**analyse en composantes principales** : trouver la direction le long de laquelle les données varient le plus, puis la direction de plus grande variation restante perpendiculaire à la première, et ainsi de suite. Gardez les deux premières et vous pouvez dessiner les données ; gardez-les toutes et vous n'avez fait que les pivoter.

| | ML.NET | Tribuo | scikit-learn | IX |
|---|---|---|---|---|
| ACP | [`ProjectToPrincipalComponents`](https://learn.microsoft.com/dotnet/api/microsoft.ml.pcacatalog.projecttoprincipalcomponents) | [`PCA`](https://tribuo.org/learn/4.3/javadoc/org/tribuo/util/infotheory/example/package-summary.html) via `TransformationMap` | [`PCA`](https://scikit-learn.org/stable/modules/generated/sklearn.decomposition.PCA.html) | `ix_unsupervised::pca::PCA` |
| Comment les axes sont trouvés | SVD randomisée | SVD | SVD, `svd_flip` pour les signes | itération de puissance avec déflation |
| Variance expliquée | `Eigenvalues` | — | `explained_variance_ratio_` | `explained_variance_ratio()` |
| Les autres dans le crate | — | — | `KernelPCA`, `NMF`, `TSNE`, `MDS`, `LDA` | `kernel_pca`, `nmf`, `tsne`, `mds`, `lda` |

Le programme de cette leçon est [`examples/l05_reduction.rs`](https://github.com/spareilleux/learn/blob/37b8830/code/machine-learning-ix/examples/l05_reduction.rs). Il travaille sur les 186 jobs, standardisés comme en leçon 4, pour qu'une seconde d'attente compte autant qu'une seconde de clonage.

## La variance le long d'une direction

Prenez un vecteur unitaire **u**. Projetez chaque ligne centrée dessus : les projections ont une variance. Écrite avec la **matrice de covariance** **C** — celle dont l'entrée `i, j` est la covariance de la variable `i` avec la variable `j` — cette variance vaut exactement `uᵀ C u`.

Donc « la direction de plus grande variance » est « le vecteur unitaire qui maximise `uᵀ C u` », et l'algèbre linéaire y répond en une ligne : c'est le **vecteur propre** de **C** associé à la plus grande **valeur propre**, et cette valeur propre *est* la variance le long de cet axe. La deuxième direction est le vecteur propre suivant, la troisième le suivant, et comme **C** est symétrique ils sont tous perpendiculaires entre eux.

Des colonnes standardisées rendent **C** facile à lire : chaque entrée diagonale vaut 1, et toutes les autres sont des corrélations.

```text
== covariance matrix of the standardized features
  [1.005, -0.083, 0.048, 0.030, 0.516]
  [-0.083, 1.005, -0.201, -0.276, 0.095]
  [0.048, -0.201, 1.005, 0.794, 0.084]
  [0.030, -0.276, 0.794, 1.005, 0.040]
  [0.516, 0.095, 0.084, 0.040, 1.005]
trace (total variance): 5.027
```

La diagonale vaut 1,005 plutôt que 1 parce que le centrage-réduction divise par `n` et la covariance par `n - 1`. Deux paires ressortent : `checkout_s` avec `post_checkout_s` à 0,794 — nettoyer un clone prend autant de temps que le clone en méritait — et `queue_s` avec `complete_s` à 0,516. Cinq variables, mais moins de cinq choses indépendantes en jeu.

## Deux façons de diagonaliser

IX trouve un vecteur propre à la fois par **itération de puissance** : multiplier un vecteur de départ par **C** encore et encore, et il se tourne vers le vecteur propre de plus grande valeur propre. Puis IX **déflate** — soustrait ce couple propre de la matrice — et recommence ([`pca.rs`, lignes 103-151](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/pca.rs#L103-L151)) :

```rust
let mut v = Array1::from_elem(n, 1.0 / (n as f64).sqrt());
// …
let v_new = matrix.dot(&v);
let new_eigenvalue = v.dot(&v_new);
```

Cette leçon emploie l'autre méthode classique, celle de **Jacobi** : choisir à répétition la plus grande entrée hors diagonale et l'annuler par une rotation. Chaque rotation est un changement de base qui conserve les valeurs propres ; quand il ne reste plus rien hors de la diagonale, la diagonale porte toutes les valeurs propres et les rotations accumulées tous les vecteurs propres ([`src/reduce.rs`, lignes 34-93](https://github.com/spareilleux/learn/blob/37b8830/code/machine-learning-ix/src/reduce.rs#L34-L93)) :

```rust
// L'angle qui annule m[p][q] : cot(2θ) = (m[p][p] - m[q][q]) / (2 m[p][q])
let theta = 0.5 * (2.0 * m[[p, q]]).atan2(m[[p, p]] - m[[q, q]]);
let (c, s) = (theta.cos(), theta.sin());
```

Un vecteur propre n'a pas de signe naturel : **u** et **-u** décrivent le même axe. scikit-learn tranche en rendant positive l'entrée de plus grande valeur absolue de chaque composante, et la version à la main copie cette règle pour que les deux se comparent entrée par entrée.

```text
== all five components, by hand (Jacobi)
  component 1: variance 1.9441, ratio 0.3867, cumulative 0.3867, [0.161, -0.331, 0.645, 0.654, 0.140]
  component 2: variance 1.5060, ratio 0.2996, cumulative 0.6863, [0.679, 0.142, -0.102, -0.144, 0.699]
  component 3: variance 0.9183, ratio 0.1827, cumulative 0.8690, [-0.251, 0.891, 0.291, 0.194, 0.146]
  component 4: variance 0.4517, ratio 0.0899, cumulative 0.9588, [-0.671, -0.269, -0.063, -0.057, 0.686]
  component 5: variance 0.2070, ratio 0.0412, cumulative 1.0000, [0.005, 0.069, -0.696, 0.714, 0.027]
sum of the five ratios: 1.0000
```

La première composante est `0.645 · checkout_s + 0.654 · post_checkout_s` avec de petites contributions du reste : l'axe du clonage, exactement la paire corrélée à 0,794. La deuxième est `0.679 · queue_s + 0.699 · complete_s` : l'axe de l'attente. Deux axes sur cinq expliquent 69 % de tout ce que font les cinq durées.

Les cinq valeurs propres somment à 5,027, la trace de la matrice de covariance. Ce n'est pas un hasard : pivoter les données ne peut ni créer ni détruire de la variance, seulement la répartir entre les axes.

## IX trouve les mêmes axes

```text
== ix_unsupervised::pca::PCA, five components
  ix   variance [1.9441, 1.5060, 0.9183, 0.4517, 0.2070]
  hand variance [1.9441, 1.5060, 0.9183, 0.4517, 0.2070]
  largest difference: 1.28e-10
  component 1: ix [0.161, -0.331, 0.645, 0.654, 0.140] same direction as the hand version
  component 2: ix [0.679, 0.142, -0.102, -0.144, 0.699] same direction as the hand version
  component 3: ix [-0.251, 0.891, 0.291, 0.194, 0.146] same direction as the hand version
  component 4: ix [0.671, 0.269, 0.063, 0.057, -0.686] opposite direction to the hand version
  component 5: ix [0.005, 0.069, -0.696, 0.714, 0.027] same direction as the hand version
```

Les variances concordent à dix décimales, et scikit-learn imprime les mêmes cinq. La composante 4 pointe dans l'autre sens, ce qui ne change rien au sous-espace ni à la reconstruction — l'itération de puissance n'a tout simplement pas de convention de signe, et le sens du vecteur de départ décide du sens de la réponse. Du code qui compare deux exécutions d'une ACP doit comparer des axes, pas des vecteurs.

Les scores concordent également, puisque le signe de la composante 4 n'entre pas dans les deux premières :

```text
== first three jobs in two dimensions
  job 0 on ubuntu  hand [-1.2345, 1.7418] ix [-1.2345, 1.7418]
  job 1 on ubuntu  hand [-1.9498, -0.1172] ix [-1.9498, -0.1172]
  job 2 on ubuntu  hand [-0.5102, -0.6465] ix [-0.5102, -0.6465]
```

## Le ratio qui vaut toujours 1

Demandez deux composantes au lieu de cinq et les deux bibliothèques cessent d'être d'accord :

```text
== keeping two of the five components
  hand ratio [0.3867, 0.2996] sum 0.6863
  ix   ratio [0.5635, 0.4365] sum 1.0000
```

`explained_variance_ratio` divise chaque valeur propre retenue par la somme des valeurs propres **retenues** ([`pca.rs`, lignes 46-57](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/pca.rs#L46-L57)) :

```rust
self.explained_variance.as_ref().map(|ev| {
    let total = ev.sum();
    if total > 0.0 { ev / total } else { ev.clone() }
})
```

`ev` ne contient jamais que les `n_components` valeurs propres que le modèle a gardées : les ratios somment donc à 1 quoi que vous demandiez, et le commentaire de documentation — « proportion of total variance per component » — n'est vrai que si vous gardez toutes les composantes. Le nombre qu'un lecteur veut, c'est 0,3867 : la part de la variance *des données*. IX rapporte 0,5635, la part de ce qu'il a décidé de garder, qui ne peut pas servir à décider combien garder. L'exercice ci-dessous en montre la conséquence : la question habituelle « combien de composantes pour 90 % ? » répond toujours « une ».

Les variances brutes trancheraient, mais `explained_variance` est un champ privé ; `save_state()` est le seul moyen de les lire depuis un modèle ajusté.

:::note[Confirmé indépendamment]
`PCA(n_components=2)` de scikit-learn sur la même matrice rapporte `[0.3867, 0.2996]`, de somme 0,6863 — la version à la main, pas celle d'IX. Voir la section `== lesson 5` de [`crosscheck/crosscheck.py`](https://github.com/spareilleux/learn/blob/37b8830/code/machine-learning-ix/crosscheck/crosscheck.py).
:::

## Ce qui est perdu

Garder `k` composantes puis revenir en arrière donne la meilleure approximation de rang `k` des données. L'erreur qu'elle laisse est exactement la variance jetée :

```text
== mean squared reconstruction error, and the variance kept
  k 1: error 0.6133, variance kept 0.3867
  k 2: error 0.3137, variance kept 0.6863
  k 3: error 0.1310, variance kept 0.8690
  k 4: error 0.0412, variance kept 0.9588
  k 5: error 0.0000, variance kept 1.0000
```

Les deux colonnes somment à 1,0000 sur chaque ligne, et pas par chance : des variables standardisées ont un carré moyen de 1 par case, donc l'erreur laissée par `k` composantes est exactement la part de variance que portaient les autres. Cette identité est la raison pour laquelle le ratio compte — c'est le seul nombre qui dit ce que coûte une réduction, ce qui est aussi pourquoi un ratio qui affiche toujours 1,0000 ne dit rien.

## Un nuage que l'itération de puissance ne peut pas voir

L'itération de puissance part du même vecteur à chaque fois — `(1, 1, …, 1)/√n`, toutes coordonnées égales ([`pca.rs`, ligne 107](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/pca.rs#L107)). Multiplier par **C** tourne ce vecteur vers le vecteur propre dominant — sauf s'il est déjà lui-même un vecteur propre, auquel cas il ne bouge jamais.

Six points forment un tel nuage. Ils s'étirent le long de `(1, -1)`, avec un peu de dispersion selon `(1, 1)` :

```text
== a cloud stretched along (1, -1)
  covariance [2.4, -1.6, -1.6, 2.4]
  hand eigenvalues [4.0000, 0.8000] first eigenvector [0.7071, -0.7071]
  ix PCA(1): variance [0.8000] component [0.7071, 0.7071]
  ix PCA(2): variance [0.8000, 0.0000] components [0.7071, 0.7071] [0.7071, 0.7071]
  ix PCA(1) scores [0.0000, 0.0000, 0.0000, 0.0000, 1.4142, -1.4142]
```

L'axe principal porte une variance de 4,0 le long de `(1, -1)`. `PCA::new(1)` renvoie l'autre : variance 0,8 le long de `(1, 1)`, l'axe *mineur*. Le vecteur de départ est ce vecteur propre mineur, donc `C·v = 0,8·v`, le quotient de Rayleigh cesse de changer dès le deuxième passage, et la boucle sort satisfaite.

`PCA::new(2)` fait pire. La déflation retire l'axe 0,8, laissant une matrice dont la seule direction est `(1, -1)` ; l'itération de puissance repart de `(1, 1)/√2`, que cette matrice envoie sur zéro, le garde-fou `norm < 1e-15` se déclenche, et le vecteur de départ est renvoyé inchangé. Le modèle finit avec deux fois la même composante et une variance de 0, décrivant un nuage bidimensionnel avec un seul axe répété.

Les scores montrent le coût : quatre des six points se projettent exactement sur 0, donc la réduction censée garder la direction la plus informative a aplati les données selon celle-ci.

C'est un cas sur le fil du rasoir — il faut que les deux variables aient exactement la même variance — et sur les jobs d'intégration continue IX et Jacobi concordent à dix décimales. Mais c'est la forme de la défaillance, pas sa rareté, qui compte : l'itération de puissance depuis un départ fixe n'offre aucune garantie, et rien dans la sortie de `PCA` ne dit dans quel cas vous êtes. La SVD de scikit-learn n'a pas de vecteur de départ, et renvoie une variance de 4,0 le long de `(0.7071, -0.7071)`.

## Quoi en faire

- Pour décider combien de composantes garder, calculez le ratio vous-même depuis `save_state().explained_variance`, en divisant par la somme sur *toutes* les composantes — ce qui veut dire ajuster une fois `PCA::new(n_features)`.
- Avant de faire confiance à une première composante, ajustez avec toutes les composantes et vérifiez que les variances sortent en ordre décroissant. L'itération de puissance suivie de déflation ne peut pas le garantir, et l'outil `ix_ml_pipeline` active l'ACP avec `normalize`.
- Comparer deux exécutions d'une ACP, c'est comparer des sous-espaces ou des valeurs absolues, jamais des vecteurs signés.

## À retenir

- L'ACP garde les vecteurs propres de la matrice de covariance aux plus grandes valeurs propres ; chaque valeur propre est la variance le long de son axe, et ensemble elles donnent la variance totale.
- Sur les jobs de CI, les rotations de Jacobi à la main et l'itération de puissance d'IX trouvent les mêmes variances à dix décimales près. Un vecteur propre n'a pas de signe naturel : compare des axes, jamais des vecteurs signés.
- Avec des caractéristiques standardisées, l'erreur laissée en gardant `k` composantes est exactement la part de la variance que portaient les autres : cette part est le coût d'une réduction.
- `explained_variance_ratio()` d'IX divise par les seules composantes gardées, donc la somme vaut toujours 1 ; calcule toi-même le ratio sur toutes les composantes.
- L'itération de puissance depuis un vecteur de départ fixe manque l'axe principal quand ce vecteur est lui-même un autre vecteur propre, et rien dans la sortie ne le dit.

## Exercices

1. Combien de composantes faut-il pour garder 90 % de la variance, et que dit `explained_variance_ratio()` pour chaque nombre ?
2. **Blanchissez** les scores à deux composantes — divisez chaque colonne par son propre écart-type — et montrez que le résultat a une matrice de covariance identité.
3. Reconstruisez le job 0 à partir de 1, 2, 3, 4 puis 5 composantes et regardez-le converger vers la vraie ligne.

<details>
<summary>Solutions</summary>

Elles sont dans [`examples/l05_exercises.rs`](https://github.com/spareilleux/learn/blob/37b8830/code/machine-learning-ix/examples/l05_exercises.rs).

**1.** Il en faut quatre. IX répond à la question par 1,0000 quoi que vous demandiez, donc la question ne peut pas lui être posée :

```text
== components needed for a share of the variance
  k 1: really kept 0.3867, ix reports 1.0000
  k 2: really kept 0.6863, ix reports 1.0000
  k 3: really kept 0.8690, ix reports 1.0000
  k 4: really kept 0.9588, ix reports 1.0000
  k 5: really kept 1.0000, ix reports 1.0000
  4 components pass 0.90; IX reports 1.0000 for every k
```

**2.** Les scores sont déjà décorrélés — c'est ce qu'achète la perpendicularité — donc leur matrice de covariance est diagonale et porte les deux valeurs propres. Diviser chaque colonne par la racine de sa valeur propre met les deux variances à 1 :

```text
== whitening the two-component scores
  covariance of the raw scores
    [1.944062, 0.000000]
    [0.000000, 1.505963]
  covariance of the whitened scores
    [1.000000, 0.000000]
    [0.000000, 1.000000]
```

Le blanchiment est ce que veut une méthode fondée sur les distances avant de commencer : après lui, la distance euclidienne dans l'espace des scores est la distance de Mahalanobis dans l'espace d'origine.

**3.** Une composante place le job 0 près du milieu de tout ; la cinquième le restitue exactement :

```text
== job 0 rebuilt, one component at a time
  true      [-0.091, 1.785, -0.596, -0.796, 1.968]
  k 1       [-0.198, 0.409, -0.797, -0.808, -0.173]
  k 2       [0.984, 0.655, -0.975, -1.059, 1.043]
  k 3       [0.589, 2.056, -0.517, -0.754, 1.273]
  k 4       [-0.091, 1.783, -0.581, -0.811, 1.968]
  k 5       [-0.091, 1.785, -0.596, -0.796, 1.968]
```

Le job 0 est inhabituel — 1,785 écart-type d'installation et 1,968 d'achèvement — donc la première composante, qui parle de clonage, se trompe à son sujet ; c'est la troisième, l'axe de l'installation, qui le retrouve.

## Sources

- James, Witten, Hastie, Tibshirani, Taylor, *[An Introduction to Statistical Learning](https://www.statlearning.com/)*, chapitre 12
- Golub et Van Loan, *Matrix Computations*, chapitre 8, pour la méthode de Jacobi et la convergence de l'itération de puissance
- [scikit-learn : décomposition en composantes](https://scikit-learn.org/stable/modules/decomposition.html) et [`svd_flip`](https://scikit-learn.org/stable/modules/generated/sklearn.utils.extmath.svd_flip.html)
- IX en `490c395` : [`ix-unsupervised/src/pca.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/pca.rs), et les autres réducteurs du même crate — [`tsne.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/tsne.rs), [`mds.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/mds.rs), [`kernel_pca.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/kernel_pca.rs), [`nmf.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/nmf.rs), [`lda.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/lda.rs)

</details>
