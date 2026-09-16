---
title: "6. Ensembles : bagging, forêts aléatoires et gradient boosting"
description: "Cinquante arbres peu profonds qui votent plutôt qu'un seul arbre profond — échantillons bootstrap et score out-of-bag à la main, une forêt aléatoire qui tire ses variables à chaque division contre l'unique tirage par arbre d'ix_ensemble, l'égalité qui revient au plus grand indice de classe, et un gradient boosting sur souches reproduit jusqu'au dernier chiffre."
sidebar:
  order: 6
---

L'arbre de décision de la leçon 3 atteignait 0,895 sur les jobs de test. L'approfondir colle mieux aux lignes d'entraînement et moins bien à celles de test. Les **ensembles** prennent l'autre route : entraîner beaucoup de modèles faibles et les combiner. Deux recettes dominent, et elles sont en désaccord sur presque tout.

Le **bagging** entraîne chaque modèle sur un tirage aléatoire différent des lignes et moyenne leurs votes. Les modèles sont indépendants, donc leurs erreurs s'annulent en partie ; l'ensemble est plus stable qu'aucun de ses membres. Le **boosting** entraîne les modèles l'un après l'autre, chacun corrigeant ce que les précédents ont manqué. Les modèles sont entièrement dépendants, et l'ensemble est plus tranchant mais plus facile à surajuster.

| | ML.NET | Tribuo | scikit-learn | IX |
|---|---|---|---|---|
| Forêt aléatoire | [`FastForest`](https://learn.microsoft.com/dotnet/api/microsoft.ml.trainers.fasttree.fastforestbinarytrainer) | [`RandomForestTrainer`](https://tribuo.org/learn/4.3/javadoc/org/tribuo/common/tree/RandomForestTrainer.html) | [`RandomForestClassifier`](https://scikit-learn.org/stable/modules/generated/sklearn.ensemble.RandomForestClassifier.html) | `ix_ensemble::random_forest::RandomForest` |
| Boosting | [`FastTree`](https://learn.microsoft.com/dotnet/api/microsoft.ml.trainers.fasttree.fasttreebinarytrainer), [`LightGbm`](https://learn.microsoft.com/dotnet/api/microsoft.ml.lightgbmextensions) | [`AdaBoostTrainer`](https://tribuo.org/learn/4.3/javadoc/org/tribuo/classification/ensemble/AdaBoostTrainer.html) | [`GradientBoostingClassifier`](https://scikit-learn.org/stable/modules/generated/sklearn.ensemble.GradientBoostingClassifier.html) | `ix_ensemble::gradient_boosting::GradientBoostedClassifier` |
| Score out-of-bag | — | — | `oob_score=True` | — |
| Variables par division | configurable | configurable | `max_features`, retirées à chaque division | `max_features`, tirées une fois par arbre |

Le programme est [`examples/l06_ensembles.rs`](https://github.com/spareilleux/learn/blob/37b8830/code/machine-learning-ix/examples/l06_ensembles.rs), sur la découpe de la leçon 3 : un job sur cinq pour le test, les 148 autres pour l'entraînement.

## Le bootstrap

Un **échantillon bootstrap** de `n` lignes, ce sont `n` lignes tirées *avec remise*. Certaines arrivent deux fois, d'autres jamais :

```text
== one tree, depth 4: test accuracy 0.8947
a bootstrap of 148 rows drew 100 distinct rows and left 48 out (0.324 of them); 1/e = 0.368
```

Une ligne donnée échappe à un tirage avec probabilité `1 - 1/n`, et aux `n` tirages avec probabilité `(1 - 1/n)ⁿ`, qui tend vers `1/e ≈ 0,368` quand `n` grandit. Environ un tiers des lignes n'atteint jamais un arbre donné — et ces lignes sont un jeu de test gratuit pour lui. Moyenné sur la forêt, c'est le **score out-of-bag** : chaque ligne jugée seulement par les arbres qui ne l'ont jamais vue, sans rien mettre de côté.

IX tire ses échantillons de `rand::rngs::StdRng`, que Python ne peut pas rejouer. La version à la main emploie plutôt un générateur xorshift 64 bits — trois décalages et trois XOR ([`src/ensemble.rs`, lignes 9-31](https://github.com/spareilleux/learn/blob/37b8830/code/machine-learning-ix/src/ensemble.rs#L9-L31)) — pour que la vérification croisée reproduise chaque tirage et retombe sur les mêmes 48 lignes :

```rust
pub fn next_u64(&mut self) -> u64 {
    let mut x = self.0;
    x ^= x << 13;
    x ^= x >> 7;
    x ^= x << 17;
    self.0 = x;
    x
}
```

## Le bagging, puis une forêt

Le bagging seul donne cinquante arbres qui se ressemblent encore beaucoup : la division la plus forte — `checkout_s`, qui sépare Windows du reste — est la première division de presque chacun d'eux. La **forêt aléatoire** de Breiman ajoute une seconde source de désaccord : à chaque nœud, seule une poignée aléatoire de variables peut servir à diviser, si bien que les variables plus faibles ont leur tour.

```text
== fifty trees of depth 4, by hand
  bagging, 5 of 5 features: test accuracy 0.8947, out-of-bag accuracy 0.9662
  forest, 3 of 5          : test accuracy 0.9211, out-of-bag accuracy 0.9459
```

Le bagging a égalé l'arbre unique ; restreindre les variables à trois sur cinq a gagné un job de test. IX, avec son défaut de `ceil(√5) = 3` variables et un autre générateur, retombe sur le même score :

```text
== ix_ensemble::random_forest::RandomForest::new(50, 4), seed 42
  trees 50, max_features default None -> ceil(sqrt(5)) = 3
  test accuracy 0.9211
```

## Une fois par arbre, ou une fois par division

Les deux forêts sont d'accord ici, mais ce n'est pas le même algorithme. Le commentaire de documentation de `RandomForest` promet « random feature subsets (sqrt(n_features) features per split) » ; le code tire le sous-ensemble une seule fois, avant la croissance de l'arbre, et construit tout l'arbre à partir de ces colonnes uniquement ([`random_forest.rs`, lignes 68-84](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-ensemble/src/random_forest.rs#L68-L84)) :

```rust
// Sous-ensemble aléatoire de variables
let mut all_features: Vec<usize> = (0..p).collect();
for i in 0..max_features {
    let j = rng.random_range(i..p);
    all_features.swap(i, j);
}
let feature_indices: Vec<usize> = all_features[..max_features].to_vec();
// … l'arbre est ensuite ajusté sur sub_x, qui n'a que ces colonnes
```

Avec trois variables sur cinq l'écart est petit. Poussez `max_features` à 1 et il ne l'est plus :

```text
== with a single feature
  hand, one feature drawn at every split: 0.9474
  ix, one feature drawn once per tree:    0.7632
```

Tirer une variable *par division* construit encore un vrai arbre : la racine peut diviser sur `checkout_s`, ses enfants sur `queue_s`, leurs enfants sur autre chose, et l'arbre combine les cinq variables le long d'un chemin. Tirer une variable *par arbre* donne cinquante modèles unidimensionnels, chacun capable de seuiller une seule durée, et le vote de cinquante souches déguisées vaut 0,763. La version à la main, au même réglage nominal, bat la forêt par défaut.

Le nombre à retenir n'est pas 0,7632 mais ceci : `max_features` ne veut pas dire la même chose dans `ix-ensemble` que dans scikit-learn, Tribuo ou l'article de Breiman, et le commentaire de documentation décrit l'autre sens.

## Le vote, et ce qui arrive en cas d'égalité

`predict` prend la classe de plus grande probabilité moyenne, via `max_by` ([`random_forest.rs`, ligne 97](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-ensemble/src/random_forest.rs#L97)). `Iterator::max_by` renvoie le **dernier** maximum, donc une égalité exacte revient au plus grand indice de classe. Deux souches en désaccord en fabriquent une :

```text
== a tie between two classes
  two stumps, seed 6: probabilities [0.500, 0.500] -> ix predicts class 1
```

scikit-learn, la forêt à la main et `np.argmax` prennent tous le plus petit indice. C'est le comportement que la leçon 3 avait trouvé dans `KNN::predict`, et il vient de la même ligne de Rust : dans IX, une égalité se tranche par l'ordre des classes, et les classes sont ordonnées par ce que l'appelant a mis dans le vecteur d'étiquettes.

Ajouter des arbres ne change pas le score de test ici — les trois jobs manqués le sont pour toutes les tailles de forêt — mais cela stabilise l'estimation out-of-bag :

```text
== by number of trees (hand forest, 3 of 5)
    1 trees: test 0.9211, out-of-bag 0.9375
    2 trees: test 0.9211, out-of-bag 0.9438
    5 trees: test 0.9211, out-of-bag 0.9323
   10 trees: test 0.9211, out-of-bag 0.9388
   25 trees: test 0.9211, out-of-bag 0.9527
   50 trees: test 0.9211, out-of-bag 0.9459
  100 trees: test 0.9211, out-of-bag 0.9527
```

Plus d'arbres ne nuit jamais à un ensemble baggé — c'est sa principale vertu pratique — mais ils cessent d'aider, et ici ils avaient cessé avant que le premier ait fini.

## Boosting : ajuster ce qui reste

Le gradient boosting part d'une constante et ajoute une petite correction à la fois. Pour une classification à `K` classes, il tient `K` scores courants par ligne. Les scores de départ sont les log-priors lissés ; à chaque tour, pour chaque classe, il ajuste une **souche** — un arbre de profondeur 1 — sur le *résidu* `1{y = c} - p(c)`, la quantité dont le modèle sous-estime actuellement cette classe, et ajoute une copie rétrécie de la souche au score.

Le résidu est le gradient négatif de la log-perte multiclasse par rapport au score, d'où le nom : chaque tour est un pas de descente de gradient, pris dans l'espace des fonctions plutôt que des paramètres.

Trouver la souche, c'est trouver la division qui sépare le mieux les résidus, c'est-à-dire celle qui minimise l'erreur quadratique autour des deux moyennes de feuilles. Comme la somme totale des carrés ne dépend pas de l'endroit où tombe la division, la minimiser revient à *maximiser* `n_L·mean_L² + n_R·mean_R²`, ce qui se balaie en une passe par variable ([`src/ensemble.rs`, lignes 255-265](https://github.com/spareilleux/learn/blob/37b8830/code/machine-learning-ix/src/ensemble.rs#L255-L265)) :

```rust
let left_mean = left_sum / left_n as f64;
let right_mean = (total - left_sum) / right_n as f64;
let score = left_n as f64 * left_mean * left_mean + right_n as f64 * right_mean * right_mean;
```

La version à la main suit `ix_ensemble` pas à pas, y compris la valeur de feuille — la simple moyenne des résidus, là où la recette originale de Friedman et scikit-learn emploient un pas de Newton. Les deux implémentations s'accordent alors exactement :

```text
== gradient boosting on stumps, learning rate 0.3
   1 rounds: hand 0.6842, ix 0.6842, rows where they differ 0
   5 rounds: hand 0.9474, ix 0.9474, rows where they differ 0
  10 rounds: hand 0.9474, ix 0.9474, rows where they differ 0
  25 rounds: hand 0.9211, ix 0.9211, rows where they differ 0
  50 rounds: hand 0.9211, ix 0.9211, rows where they differ 0
```

Pas une ligne sur 38 ne diffère, quel que soit le nombre de tours, et la version numpy de la vérification croisée reproduit les mêmes exactitudes. Le boosting est le seul algorithme de ce cours où IX, la version à la main et une troisième implémentation s'accordent jusqu'au dernier chiffre — ce qui mérite d'être dit clairement, car les leçons jusqu'ici ont surtout trouvé l'inverse.

Cinq tours battent cinquante. L'ensemble culmine à 0,9474 et retombe à 0,9211 : sans jeu de validation ni arrêt anticipé, `n_estimators` est le paramètre qui décide si le boosting aide, et rien dans l'API ne le mesure pour vous. Le bagging a le caractère inverse — ses arbres supplémentaires sont inoffensifs — ce qui est la raison pratique de tendre d'abord vers une forêt.

Le premier tour se lit tout seul :

```text
start, the smoothed log priors: [-0.4529, -1.7592, -1.6500]
  round 1, class ubuntu : split checkout_s <= 1.5, leaves 0.3074 and -0.4358
  round 1, class windows: split checkout_s <= 4.0, leaves -0.1722 and 0.8278
  round 1, class macos  : split queue_s <= 5.5, leaves -0.1671 and 0.7008
  probabilities of the first test job after one round: [0.6682, 0.1567, 0.1751]
```

`exp(-0.4529) = 0,636` : 95 des 148 jobs d'entraînement tournaient sur Ubuntu, lissés en ajoutant un à chaque effectif. Le modèle commence par deviner les taux de base. Puis chaque classe reçoit la question qui réduit le plus son propre résidu — pour Windows, « le clonage a-t-il pris plus de 4 secondes ? », pour macOS, « le job a-t-il attendu plus de 5,5 secondes dans la file ? » — et les trois réponses, passées au softmax, placent déjà le premier job de test sur Ubuntu avec une probabilité de 0,67.

## Exercices

1. Le score out-of-bag suit-il le score de test quand les arbres s'approfondissent ?
2. Où les deux forêts se contredisent-elles sur le jeu de test, et quelles lignes la forêt manque-t-elle encore ?
3. Quels systèmes d'exploitation la forêt confond-elle ?

<details>
<summary>Solutions</summary>

Elles sont dans [`examples/l06_exercises.rs`](https://github.com/spareilleux/learn/blob/37b8830/code/machine-learning-ix/examples/l06_exercises.rs).

**1.** Il en suit la *forme* mais pas le niveau :

```text
== depth against the two scores (hand forest, 50 trees, 3 of 5 features)
  depth 1: out-of-bag 0.7838, test 0.9211
  depth 2: out-of-bag 0.9730, test 0.9211
  depth 3: out-of-bag 0.9730, test 0.9211
  depth 4: out-of-bag 0.9459, test 0.9211
  depth 5: out-of-bag 0.9662, test 0.9211
  depth 6: out-of-bag 0.9595, test 0.9211
  depth 7: out-of-bag 0.9595, test 0.9211
  depth 8: out-of-bag 0.9595, test 0.9211
```

La profondeur 1 est clairement trop faible, et les deux scores le disent. Ensuite le score out-of-bag erre entre 0,946 et 0,973 pendant que le score de test ne bouge pas du tout. Avec 148 lignes d'entraînement, une estimation out-of-bag repose sur environ 54 d'entre elles par arbre, et des écarts de 0,02 sont du bruit. C'est une alarme utile pour « ce modèle est gravement faux », pas un moyen de choisir entre deux profondeurs raisonnables.

**2.** Elles ne se contredisent jamais, et toutes deux se trompent sur les trois mêmes jobs :

```text
== the two forests on the 38 test jobs
  hand 0.9211, ix 0.9211, rows where they disagree: []
  the rows the hand forest still gets wrong:
    test job 12, workflow Deploy to GitHub Pages         truly ubuntu  predicted macos
    test job 27, workflow Rust course examples           truly ubuntu  predicted macos
    test job 29, workflow GHA 05: caches and artifacts   truly ubuntu  predicted windows
```

Tous trois sont des jobs Ubuntu qui se sont comportés comme autre chose — une file lente ou un clonage lent sur un runner d'ordinaire rapide. Rien dans cinq durées ne distingue un job Ubuntu lent d'un job macOS normal, donc aucune quantité d'arbres ne les récupérera ; le plafond ici, ce sont les données, pas le modèle.

**3.** Chaque erreur est un job Ubuntu appelé autrement :

```text
== confusion of the hand forest, rows true, columns predicted
  order ["ubuntu", "windows", "macos"]
  ubuntu  [23, 1, 2]
  windows [0, 9, 0]
  macos   [0, 0, 3]
```

Windows et macOS sont reconnus parfaitement. C'est ce que fait un jeu d'entraînement déséquilibré : avec 121 jobs Ubuntu contre 34 et 31, la classe majoritaire absorbe l'incertitude, et les erreurs tombent toutes sur elle.

</details>

## Sources

- Breiman, *[Random Forests](https://link.springer.com/article/10.1023/A:1010933404324)*, 2001, pour le bagging, le tirage de variables à chaque division et l'estimation out-of-bag
- Friedman, *[Greedy Function Approximation: A Gradient Boosting Machine](https://projecteuclid.org/euclid.aos/1013203451)*, 2001
- James, Witten, Hastie, Tibshirani, Taylor, *[An Introduction to Statistical Learning](https://www.statlearning.com/)*, chapitre 8
- [scikit-learn : méthodes d'ensemble](https://scikit-learn.org/stable/modules/ensemble.html)
- IX en `490c395` : [`ix-ensemble/src/random_forest.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-ensemble/src/random_forest.rs), [`ix-ensemble/src/gradient_boosting.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-ensemble/src/gradient_boosting.rs)
