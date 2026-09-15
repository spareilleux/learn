---
title: "3. Classification : régression logistique, k plus proches voisins, arbres de décision"
description: Quel OS a exécuté un job CI, d'après les durées de ses étapes — régression logistique par descente de gradient, k plus proches voisins avec et sans mise à l'échelle, un arbre de décision CART avec l'impureté de Gini, et une validation croisée stratifiée, chacun écrit à la main et comparé avec ix-supervised et scikit-learn, y compris une égalité qu'IX départage dans l'autre sens.
sidebar:
  order: 3
---

La régression prédit un nombre ; la **classification** prédit une classe. Cette leçon prédit l'OS d'un job CI, Ubuntu, Windows ou macOS, à partir de cinq durées en secondes : `queue_s` (l'attente d'un runner), `setup_s` (l'étape *Set up job*), `checkout_s` et `post_checkout_s` (le checkout et son nettoyage), et `complete_s` (l'étape *Complete job*). La leçon 1 a donné la référence : toujours Ubuntu, 65 % d'exactitude, F1 macro de 0.263.

Trois classifieurs, trois idées de ce qu'« apprendre » veut dire : une somme pondérée passée dans une courbe, les exemples les plus proches, et une liste de questions.

| | ML.NET | Tribuo | scikit-learn | IX |
|---|---|---|---|---|
| Régression logistique | [`LbfgsLogisticRegression`](https://learn.microsoft.com/dotnet/api/microsoft.ml.standardtrainerscatalog.lbfgslogisticregression) | [`LogisticRegressionTrainer`](https://tribuo.org/learn/4.3/javadoc/org/tribuo/classification/sgd/linear/LogisticRegressionTrainer.html) | [`LogisticRegression`](https://scikit-learn.org/stable/modules/generated/sklearn.linear_model.LogisticRegression.html) | `ix_supervised::logistic_regression` |
| k plus proches voisins | — | [`KNNTrainer`](https://tribuo.org/learn/4.3/javadoc/org/tribuo/common/nearest/KNNTrainer.html) | [`KNeighborsClassifier`](https://scikit-learn.org/stable/modules/generated/sklearn.neighbors.KNeighborsClassifier.html) | `ix_supervised::knn::KNN` |
| Arbre de décision | arbres boostés : [`FastTree`](https://learn.microsoft.com/dotnet/api/microsoft.ml.trainers.fasttree.fasttreebinarytrainer) | [`CARTClassificationTrainer`](https://tribuo.org/learn/4.3/javadoc/org/tribuo/classification/dtree/CARTClassificationTrainer.html) | [`DecisionTreeClassifier`](https://scikit-learn.org/stable/modules/tree.html) | `ix_supervised::decision_tree::DecisionTree` |
| Validation croisée | [`CrossValidate`](https://learn.microsoft.com/dotnet/api/microsoft.ml.multiclassclassificationcatalog.crossvalidate) | [`CrossValidation`](https://tribuo.org/learn/4.3/javadoc/org/tribuo/evaluation/CrossValidation.html) | [`cross_val_score`](https://scikit-learn.org/stable/modules/generated/sklearn.model_selection.cross_val_score.html) | `ix_supervised::validation::cross_val_score` |

Dans IX, les trois implémentent le trait [`Classifier`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-supervised/src/traits.rs#L11-L16) : `fit(&x, &y)`, `predict(&x)` et `predict_proba(&x)`, avec les étiquettes en `Array1<usize>`. Le programme est [`examples/l03_classification.rs`](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/examples/l03_classification.rs). Un job sur cinq est un job de test, les autres servent à l'entraînement : une règle que la vérification croisée en Python peut répéter, ce que le découpage aléatoire d'IX ne lui permet pas.

```text
== split: train 148 [95, 25, 28], test 38 [26, 9, 3] (ubuntu, windows, macos)
```

## Régression logistique

Une droite donne n'importe quel nombre ; une classe demande une probabilité entre 0 et 1. La régression logistique calcule la même somme pondérée que la leçon 2, `z = w·x + b`, puis la comprime avec la **sigmoïde** `σ(z) = 1 / (1 + e⁻ᶻ)` : `z = 0` donne 0.5, un grand `z` positif donne presque 1. Elle répond à une question par oui ou non ; ici, *ce job tourne-t-il sous Windows ?*, à partir de `checkout_s` et `post_checkout_s`.

La perte n'est plus l'erreur quadratique mais la **perte logistique** (*log loss*), qui punit sans limite une mauvaise réponse donnée avec assurance. Avec `pᵢ = σ(w·xᵢ + b)` et `yᵢ` égal à 0 ou 1 :

```text
L(w, b) = -1/n Σ [ yᵢ·ln(pᵢ) + (1 - yᵢ)·ln(1 - pᵢ) ]
∂L/∂w = 1/n Σ (pᵢ - yᵢ)·xᵢ        ∂L/∂b = 1/n Σ (pᵢ - yᵢ)
```

Le gradient a la même forme que celui de la leçon 2 : prédiction moins vérité, fois l'entrée. Il n'y a pas de forme close ; [`src/classify.rs`, lignes 9-31](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/src/classify.rs#L9-L31) fait un nombre fixe de pas de gradient en partant de zéro :

```rust
for _ in 0..iterations {
    let mut dw = Array1::<f64>::zeros(p);
    let mut db = 0.0;
    for i in 0..n {
        let error = sigmoid(x.row(i).dot(&w) + b) - y[i] as f64;
        dw.scaled_add(error / n as f64, &x.row(i));
        db += error / n as f64;
    }
    w.scaled_add(-learning_rate, &dw);
    b -= learning_rate * db;
}
```

[`LogisticRegression::fit`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-supervised/src/logistic_regression.rs#L44-L68) fait la même chose avec des produits matriciels, et `predict` répond 1 quand la probabilité est d'au moins 0.5 :

```text
== logistic regression, windows or not, features ["checkout_s", "post_checkout_s"]
lr 0.01, 1000 iterations: hand w [0.2924, 0.4670] b -1.9327 | ix w [0.2924, 0.4670] b -1.9327 | same to 1e-9: true
  test: accuracy 1.000, windows precision 1.000, recall 1.000
  P(windows | checkout 1 s, post 0.5 s) = 0.197  P(windows | checkout 3 s, post 1.5 s) = 0.412  P(windows | checkout 6 s, post 3 s) = 0.773
lr 0.1, 20000 iterations: hand w [2.4770, 1.8829] b -12.3652 | ix w [2.4770, 1.8829] b -12.3652 | same to 1e-9: true
  test: accuracy 0.974, windows precision 0.900, recall 1.000
  P(windows | checkout 1 s, post 0.5 s) = 0.000  P(windows | checkout 3 s, post 1.5 s) = 0.108  P(windows | checkout 6 s, post 3 s) = 1.000
```

Mêmes nombres à la main et dans IX, mais quel modèle est *la* régression logistique de ces données ? Dans les lignes d'entraînement, les jobs Windows sont exactement les jobs dont le checkout dure plus de 4 secondes (l'arbre de décision plus bas trouve cette règle). Sur des données séparables, la perte logistique n'a pas de minimum : elle continue de baisser à mesure que les poids grandissent, et les probabilités tendent vers 0 et 1. IX n'a ni test d'arrêt ni pénalité, si bien que la réponse est celle que donne le nombre d'itérations. Les deux exécutions sont d'accord sur presque tous les jobs de test, mais pas sur leur degré de certitude : un job avec un checkout de 3 secondes est Windows à 41 % pour l'une, à 11 % pour l'autre.

D'autres bibliothèques ajoutent une pénalité sur la taille des poids, la **régularisation**, qui donne à la perte un minimum unique. La valeur par défaut de scikit-learn, `C=1`, trouve `w [2.0809, 0.9997] b -9.8885` dans la vérification croisée, et un `C=1e6` presque sans pénalité trouve `[6.5664, 2.9888] b -30.3265` ; les deux ont une exactitude de test de 0.974. `LbfgsLogisticRegression` de ML.NET a aussi des pénalités par défaut : `l1Regularization = 1` et `l2Regularization = 1`.

## k plus proches voisins

Le classifieur le plus simple n'apprend rien : pour classer un job, on trouve les `k` jobs d'entraînement dont les durées sont les plus proches, et on prend la classe de la majorité d'entre eux. « Le plus proche » se mesure avec la distance euclidienne, `√Σ (aⱼ - bⱼ)²` sur les cinq caractéristiques ([`src/classify.rs`, lignes 41-68](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/src/classify.rs#L41-L68)) :

```rust
let mut near: Vec<(f64, usize)> = x_train
    .rows()
    .into_iter()
    .map(|t| distance(row, t))
    .zip(y_train.iter().copied())
    .collect();
// Un tri stable garde les distances égales dans l'ordre d'entraînement
near.sort_by(|a, b| a.0.total_cmp(&b.0));
let mut votes = vec![0; classes];
for &(_, class) in &near[..k] {
    votes[class] += 1;
}
let best = *votes.iter().max().unwrap();
votes.iter().position(|&v| v == best).unwrap()
```

Les distances additionnent des secondes d'attente et des secondes de checkout, si bien que les caractéristiques les plus dispersées décident. Le programme exécute `k = 4` et `k = 5` sur les durées brutes, puis sur les durées standardisées avec les lignes d'entraînement, comme dans la leçon 1 :

```text
== k nearest neighbours, features ["queue_s", "setup_s", "checkout_s", "post_checkout_s", "complete_s"]
raw          k = 4: accuracy hand 0.921, ix 0.921, test rows where they differ: []
raw          k = 5: accuracy hand 0.921, ix 0.921, test rows where they differ: []
standardized k = 4: accuracy hand 0.974, ix 0.947, test rows where they differ: [27]
  test row 27 (jobs.csv row 135, from 0): votes [2, 0, 2] -> hand ubuntu, ix macos, true ubuntu
standardized k = 5: accuracy hand 0.974, ix 0.974, test rows where they differ: []
```

La standardisation fait passer l'exactitude de 92 % à 97 %. Avec `k = 4`, un job de test a deux voisins Ubuntu et deux voisins macOS : une égalité. La version à la main donne l'égalité à la première classe, Ubuntu, et scikit-learn aussi (exactitude de 0.974 dans la vérification croisée). [`KNN::predict`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-supervised/src/knn.rs#L34-L55) la donne à macOS :

```rust
votes.iter().enumerate().max_by_key(|(_, &v)| v).unwrap().0
```

[`Iterator::max_by_key`](https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.max_by_key) renvoie le **dernier** de plusieurs maximums égaux, si bien qu'IX départage chaque égalité en faveur du plus grand indice de classe. Aucune des deux règles n'est plus correcte, mais le résultat dépend alors de l'ordre des classes, et diffère de celui de scikit-learn. Un `k` impair évite les égalités entre deux classes, pas entre trois : `k = 5` peut voter 2, 2, 1.

ML.NET n'a pas d'entraîneur de k plus proches voisins dans sa [liste d'entraîneurs](https://learn.microsoft.com/dotnet/machine-learning/resources/tasks).

## Arbres de décision

Un arbre de décision pose une question sur une caractéristique à chaque nœud, `checkout_s <= 4?`, et envoie le job à gauche ou à droite jusqu'à atteindre une feuille, qui porte une classe. Sa croissance est gloutonne : à chaque nœud, on essaie chaque caractéristique et chaque seuil à mi-chemin entre deux valeurs consécutives, et on garde la question qui rend les deux groupes les plus purs.

La pureté se mesure par l'**impureté de Gini**, la probabilité que deux jobs tirés au hasard dans le groupe (avec remise) soient de classes différentes. Avec `pₖ` la part de la classe `k` :

```text
Gini = 1 - Σ pₖ²                 [10, 0, 0] → 0        [5, 5, 0] → 0.5
gain = Gini(parent) - (nₗ·Gini(left) + nᵣ·Gini(right)) / n
```

La version à la main est [`src/classify.rs`, lignes 105-160](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/src/classify.rs#L105-L160) ; celle d'IX est [`best_split`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-supervised/src/decision_tree.rs#L177-L240), appelée par `build_tree` jusqu'à la profondeur limite, moins de `min_samples_split` lignes (2 par défaut), ou un nœud pur ([ligne 268](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-supervised/src/decision_tree.rs#L268)). Les deux gardent la première division au plus grand gain, et les deux envoient `<=` à gauche. Le programme affiche l'arbre fait à la main, puis les nœuds enregistrés par IX :

```text
== decision tree, max depth 3
checkout_s <= 4
  queue_s <= 5.5
    queue_s <= 4.5
      -> ubuntu [89, 0, 0]
    queue_s > 4.5
      -> ubuntu [5, 0, 3]
  queue_s > 5.5
    checkout_s <= 1.5
      -> macos [1, 0, 4]
    checkout_s > 1.5
      -> macos [0, 0, 21]
checkout_s > 4
  -> windows [0, 25, 0]
ix nodes, pre-order: [{"Split":{"feature":2,"threshold":4.0}},{"Split":{"feature":0,"threshold":5.5}},{"Split":{"feature":0,"threshold":4.5}},{"Leaf":{"class":0,"class_counts":[89.0,0.0,0.0]}},{"Leaf":{"class":0,"class_counts":[5.0,0.0,3.0]}},{"Split":{"feature":2,"threshold":1.5}},{"Leaf":{"class":2,"class_counts":[1.0,0.0,4.0]}},{"Leaf":{"class":2,"class_counts":[0.0,0.0,21.0]}},{"Leaf":{"class":1,"class_counts":[0.0,25.0,0.0]}}]
test accuracy hand 0.921, ix 0.921, same predictions: true
confusion matrix (rows = true, columns = predicted):
[[23, 1, 2],
 [0, 9, 0],
 [0, 0, 3]]
ubuntu   precision 1.000 recall 0.885 f1 0.939
windows  precision 0.900 recall 1.000 f1 0.947
macos    precision 0.600 recall 1.000 f1 0.750
```

Le même arbre trois fois : à la main, dans IX, et dans l'`export_text` de scikit-learn dans la vérification croisée. Il se lit comme une règle que tu aurais pu écrire : un checkout de plus de 4 secondes, c'est Windows ; sinon, plus de 5.5 secondes dans la file, c'est macOS. L'arbre trouve chaque job de test Windows et macOS, et prend 3 des 26 jobs Ubuntu pour autre chose : selon ses propres règles, l'un avait un checkout de plus de 4 secondes, et deux ont attendu plus de 5.5 secondes dans la file.

Un arbre est le seul des trois modèles qui s'explique lui-même. Sa faiblesse est le revers de la médaille : assez profond, il pose des questions jusqu'à ce que chaque job d'entraînement soit dans une feuille pure, y compris les accidents de cet échantillon.

## Validation croisée

38 jobs de test donnent un score bruité : un job vaut 2.6 points d'exactitude. La **validation croisée à k plis** (*k-fold*) utilise chaque ligne une fois pour le test : on découpe les lignes en `k` plis, on entraîne sur `k - 1`, on teste sur le dernier, et on répète pour chaque pli. [`cross_val_score`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-supervised/src/validation.rs#L300-L329) prend une closure qui construit un nouveau modèle pour chaque pli, et utilise `StratifiedKFold` (exercice 2 de la leçon 1), si bien que chaque pli garde la part de chaque OS :

```rust
cross_val_score(x, &jobs.os, || DecisionTree::new(3), 5, 42)
```

```text
== cross_val_score, 5 stratified folds, seed 42
knn k=5, raw           folds [0.923, 0.919, 0.973, 1.000, 1.000] mean 0.963
decision tree depth 3  folds [0.923, 0.919, 0.973, 1.000, 0.944] mean 0.952
decision tree depth 10 folds [0.923, 0.892, 0.973, 1.000, 0.917] mean 0.941
```

L'arbre plus profond a un score plus bas : il apprend sur les plis d'entraînement des règles qui ne tiennent pas sur le pli de test, c'est le **surapprentissage**. Les plis varient de 0.89 à 1.00, plus que les modèles ne diffèrent entre eux : sur 186 jobs, une différence d'un point entre deux modèles ne veut pas dire grand-chose.

`cross_val_score` prend un modèle, pas un pipeline : un scaler ajusté dans chaque pli, comme l'exige la leçon 1, ne peut pas lui être passé. L'exercice 2 montre ce que cela coûte.

## À retenir

- La régression logistique est une droite passée dans une sigmoïde, entraînée par descente de gradient sur la perte logistique. Celle d'IX n'a ni régularisation ni test d'arrêt : sur des données presque séparables, ses poids et ses probabilités dépendent du nombre d'itérations.
- Les k plus proches voisins demandent des caractéristiques à la même échelle. IX départage les égalités de vote en faveur du plus grand indice de classe, scikit-learn en faveur du plus petit.
- Un arbre de décision choisit, à chaque nœud, le seuil qui fait le plus baisser l'impureté de Gini. IX, la version à la main et scikit-learn font pousser le même arbre sur ces données.
- La validation croisée donne un score par pli : regarde leur dispersion avant de comparer deux modèles.

## Exercices

Les solutions sont dans [`examples/l03_exercises.rs`](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/examples/l03_exercises.rs), et leur sortie dans `expected/l03_exercises.txt`.

1. Entraîne la régression logistique d'IX pour répondre *macOS ou non* à partir de `queue_s` et `checkout_s`, standardisées avec les lignes d'entraînement (taux d'apprentissage 0.1, 5 000 itérations). Le modèle prédit macOS quand la probabilité est d'au moins 0.5 : calcule plutôt la précision, le rappel et le F1 pour macOS avec des seuils de 0.3, 0.5, 0.7 et 0.9, ainsi que l'`auc_score` d'IX.

<details>
<summary>Solution</summary>

[Lignes 18-47](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/examples/l03_exercises.rs#L18-L47) :

```rust
let p_mac = model.predict_proba(&x_test).column(1).to_owned();
for threshold in [0.3, 0.5, 0.7, 0.9] {
    let predicted: Array1<usize> = p_mac.mapv(|p| usize::from(p >= threshold));
    let (p, r, f) = precision_recall_f1(&confusion(&y_test, &predicted, 2), 1);
    // …
}
println!("AUC {:.3}", auc_score(&y_test, &p_mac));
```

```text
== exercise 1
weights [4.1125, -0.6938] bias -2.8674
threshold 0.3: macos precision 0.600, recall 1.000, f1 0.750, predicted macos 5
threshold 0.5: macos precision 0.600, recall 1.000, f1 0.750, predicted macos 5
threshold 0.7: macos precision 0.750, recall 1.000, f1 0.857, predicted macos 4
threshold 0.9: macos precision 0.750, recall 1.000, f1 0.857, predicted macos 4
AUC 1.000
```

Un seuil plus élevé échange du rappel contre de la précision ; ici, il retire une mauvaise réponse macOS sans en perdre une bonne. L'**AUC**, l'aire sous la courbe ROC ([`metrics.rs`, lignes 480-483](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-supervised/src/metrics.rs#L480-L483)), est la probabilité qu'un job macOS pris au hasard obtienne un score plus élevé qu'un autre job pris au hasard, sur tous les seuils à la fois. 1.000 dit que les trois jobs de test macOS ont un score supérieur à celui de tous les autres jobs : un seuil entre eux et le quatrième job, quelque part au-dessus de 0.9, serait parfait. L'AUC juge le classement ; le seuil est un choix à part, fait selon ce que coûte une fausse alerte par rapport à un oubli. Avec seulement 3 jobs de test macOS, aucun de ces nombres n'est précis.

</details>

2. Choisis `k` pour les k plus proches voisins : exécute `cross_val_score` avec 5 plis pour `k` de 1 à 15, sur les cinq caractéristiques standardisées avec les statistiques de **toutes** les lignes, et affiche le meilleur `k`.

<details>
<summary>Solution</summary>

[Lignes 49-66](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/examples/l03_exercises.rs#L49-L66) :

```rust
let z = Scaler::fit(&jobs.features).transform(&jobs.features);
let mut best = (0.0, 0);
for k in 1..=15 {
    let scores = cross_val_score(&z, &jobs.os, || KNN::new(k), 5, 42);
    let mean = scores.iter().sum::<f64>() / 5.0;
    println!("k {k:2}: mean accuracy {mean:.3}");
    if mean > best.0 {
        best = (mean, k);
    }
}
```

```text
== exercise 2
k  1: mean accuracy 0.974
k  2: mean accuracy 0.957
k  3: mean accuracy 0.968
k  4: mean accuracy 0.974
k  5: mean accuracy 0.963
k  6: mean accuracy 0.963
k  7: mean accuracy 0.963
k  8: mean accuracy 0.968
k  9: mean accuracy 0.963
k 10: mean accuracy 0.968
k 11: mean accuracy 0.963
k 12: mean accuracy 0.963
k 13: mean accuracy 0.963
k 14: mean accuracy 0.963
k 15: mean accuracy 0.958
best k 4 (0.974); accuracy of always ubuntu: 0.651
```

`k = 1` et `k = 4` affichent tous deux 0.974 ; `k = 4` gagne sur une décimale plus loin. De `k = 1` à `k = 15`, les moyennes restent dans un intervalle de 1.7 point, environ trois jobs sur 186 : ces données ne désignent pas de `k`. Chaque choix bat la référence d'au moins 30 points.

Le scaler a vu le pli de test de chaque découpage, c'est la fuite de données de la leçon 1. Avec 186 lignes venant de la même CI, les moyennes et les écarts-types de quatre cinquièmes des lignes sont proches de ceux de toutes les lignes, si bien que l'effet est faible ici, mais un score choisi de cette façon est légèrement optimiste. Bien faire les choses, c'est écrire la boucle sur les plis à la main, avec `StratifiedKFold::split` et un scaler ajusté sur chaque pli d'entraînement.

</details>

## Sources

- James, Witten, Hastie, Tibshirani, Taylor, *[An Introduction to Statistical Learning](https://www.statlearning.com/)*, chapitres 4 (régression logistique, k plus proches voisins), 5 (validation croisée) et 8 (arbres)
- [scikit-learn : plus proches voisins](https://scikit-learn.org/stable/modules/neighbors.html), [arbres de décision](https://scikit-learn.org/stable/modules/tree.html) et [validation croisée](https://scikit-learn.org/stable/modules/cross_validation.html)
- IX à `490c395` : [`logistic_regression.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-supervised/src/logistic_regression.rs), [`knn.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-supervised/src/knn.rs), [`decision_tree.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-supervised/src/decision_tree.rs), [`validation.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-supervised/src/validation.rs)
