---
title: L'apprentissage automatique, appliqué dans IX — Mission
description: Apprendre l'apprentissage automatique en partant de l'algèbre — découpage et évaluation, régression linéaire et descente de gradient, classification, partitionnement — en écrivant chaque algorithme à la main en Rust, puis en lisant et en exécutant le même algorithme dans les crates IX, sur l'historique CI de ce site.
sidebar:
  label: Mission
  order: 0
---

:::note[Comment ce cours est testé]
Chaque résultat de ce cours est affiché par un programme de [`code/machine-learning-ix`](https://github.com/spareilleux/learn/tree/main/code/machine-learning-ix) : un projet Cargo qui dépend des crates IX au commit [`490c395`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2). [`.github/workflows/ml-ix-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/ml-ix-examples.yml) exécute `cargo fmt`, `clippy`, les tests unitaires et chaque exemple sous Linux, Windows et macOS, et compare chaque sortie avec le fichier de `expected/`. Sous Linux seulement, le même workflow recalcule les résultats qui ne dépendent pas d'IX avec [numpy](https://numpy.org/doc/stable/) 2.4.2 et [scikit-learn](https://scikit-learn.org/stable/) 1.8.0, et les compare aussi. Les sorties des leçons ont été capturées avec Rust 1.94 sous Windows en septembre 2026, et sont identiques sur les trois systèmes.
:::

## Pourquoi j'apprends ça

[IX](https://github.com/GuitarAlchemist/ix) est un workspace Rust d'algorithmes d'apprentissage automatique et de mathématiques que Claude Code peut appeler comme outils : k-means, arbres de décision, descente de gradient, et environ quatre-vingts autres crates. Quand un outil répond « 3 clusters, silhouette 0.50 », je veux savoir ce qui a été calculé, si c'est juste, et à quoi ressemblerait une meilleure réponse.

Ma façon d'apprendre un algorithme, c'est de l'écrire. Chaque leçon écrit un algorithme en quelques dizaines de lignes, l'exécute, ainsi que la version d'IX, sur les mêmes données, et compare les deux jusqu'au dernier chiffre affiché. Quand elles diffèrent, l'une des deux a tort, et c'est en cherchant laquelle que j'apprends le plus : cette série a trouvé neuf endroits où la réponse d'IX, ou sa documentation, diffère du manuel ou de scikit-learn, listés dans le [journal](journal/).

## À qui s'adresse ce cours

Tu écris du C# ou du Java. L'algèbre du lycée ne te fait pas peur : une droite `y = w·x + b`, une somme `Σ`, une racine carrée, une dérivée. Tu n'as besoin de rien savoir de l'apprentissage automatique. Tu n'as pas non plus besoin de bien connaître Rust : le code utilise des boucles, des closures et les matrices de [ndarray](https://docs.rs/ndarray/0.17/ndarray/), et le [cours Rust](../rust-for-csharp-java/) couvre le reste.

Si tu as utilisé [ML.NET](https://learn.microsoft.com/dotnet/machine-learning/), [Tribuo](https://tribuo.org/) ou [Deeplearning4j](https://deeplearning4j.konduit.ai/), chaque leçon relie ce que tu connais à ce que fait IX.

## IX, ML.NET et Tribuo en un tableau

| | ML.NET | Tribuo | IX |
|---|---|---|---|
| Langage | C#, F# | Java | Rust |
| Un jeu de données | `IDataView`, colonnes typées | `Dataset<T>` d'`Example<T>` | deux matrices `ndarray` : `Array2<f64>` pour les caractéristiques, `Array1` pour les étiquettes |
| Un modèle | `IEstimator.Fit` renvoie un `ITransformer` | `Trainer.train` renvoie un `Model` | une struct avec `fit` et `predict` (traits `Regressor`, `Classifier`, `Clusterer`) |
| Prétraitement | `NormalizeMeanVariance`, ajusté comme un modèle | `TransformationMap` | `StandardScaler::fit`, puis `transform` |
| Depuis un assistant IA | — | — | outils MCP comme `ix_kmeans` et `ix_ml_pipeline` |

Sources : [tâches et entraîneurs ML.NET](https://learn.microsoft.com/dotnet/machine-learning/resources/tasks), [partitionnement dans Tribuo](https://tribuo.org/learn/4.3/javadoc/org/tribuo/clustering/package-summary.html), [README d'IX](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/README.md).

## Les données

Aucun jeu de données téléchargé : les deux fichiers viennent de ce dépôt, et [`data/extract.py`](https://github.com/spareilleux/learn/blob/15cde435d825d3c392307e7c6f9ee2e085d0e2bc/code/machine-learning-ix/data/extract.py) les reconstruit à partir de l'historique CI que le [cours DuckDB](../duckdb/) a exporté le 2026-09-14 (`runs.json` et `jobs.json`) et à partir de Git :

- [`builds.csv`](https://github.com/spareilleux/learn/blob/15cde435d825d3c392307e7c6f9ee2e085d0e2bc/code/machine-learning-ix/data/builds.csv), pour la régression : les 65 builds réussis de ce site, dans l'ordre des commits, avec le nombre de pages Markdown à ce commit (18 à 289) et les secondes de l'étape qui les construit (10 à 48). Le temps de build augmente-t-il avec le nombre de pages ?
- [`jobs.csv`](https://github.com/spareilleux/learn/blob/15cde435d825d3c392307e7c6f9ee2e085d0e2bc/code/machine-learning-ix/data/jobs.csv), pour la classification et le partitionnement : 186 jobs CI, chacun avec cinq durées en secondes entières (attente dans la file, préparation du job, checkout du dépôt, nettoyage du checkout, fin du job) et l'OS du runner : 121 Ubuntu, 34 Windows, 31 macOS. Les durées permettent-elles de dire quel OS a exécuté un job ?

## IX, épinglé

Le cours utilise cinq crates IX : `ix-math` (statistiques, mise à l'échelle, découpage), `ix-supervised` (régression, classification, métriques, validation croisée), `ix-optimize` (descente de gradient), `ix-unsupervised` (k-means, DBSCAN, mélanges gaussiens) et `ix-voicings` (le score de silhouette et le partitionnement des *voicings* de guitare). [`Cargo.toml`](https://github.com/spareilleux/learn/blob/15cde435d825d3c392307e7c6f9ee2e085d0e2bc/code/machine-learning-ix/Cargo.toml) les prend depuis Git, épinglées à un commit, comme le décrit la [référence Cargo](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html) :

```toml
ix-supervised = { git = "https://github.com/GuitarAlchemist/ix", rev = "490c39533627d296bf9f8f050e6fafc14d7a20c2" }
```

Chaque lien vers du code IX dans les leçons pointe vers ce commit, si bien que les numéros de ligne restent justes quand IX change.

## À la fin de ce cours, je saurai

- découper des données pour l'entraînement et le test, choisir une référence, et évaluer un modèle avec la métrique qui convient à la question ;
- ajuster une droite de deux façons, par la forme close et par descente de gradient, et dire pourquoi la descente diverge ;
- entraîner et comparer une régression logistique, les k plus proches voisins et un arbre de décision, avec validation croisée ;
- regrouper des données sans étiquettes avec k-means, DBSCAN et un mélange gaussien, et juger les groupes ;
- lire un algorithme dans IX, le vérifier face à une version écrite à la main et à scikit-learn, et décrire précisément une différence.

## Plan

| # | Leçon | Si tu connais ML.NET |
|---|---|---|
| 1 | [Données, caractéristiques et évaluation](01-data-and-evaluation/) | `IDataView`, `TrainTestSplit`, `RegressionMetrics` |
| 2 | [Régression linéaire et descente de gradient](02-linear-regression/) | `Ols`, `OnlineGradientDescent` |
| 3 | [Classification : régression logistique, k plus proches voisins, arbres de décision](03-classification/) | `LbfgsLogisticRegression`, `FastTree`, `CrossValidate` |
| 4 | [Partitionnement : k-means, DBSCAN, mélanges gaussiens](04-clustering/) | `KMeansTrainer` |
| — | [Journal](journal/) | |

## Ressources

- [IX au commit `490c395`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2), et son dossier de tutoriels [`docs/`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2/docs)
- [Guide de l'utilisateur de scikit-learn](https://scikit-learn.org/stable/), la référence qu'utilise la vérification croisée, et sa page sur les [pièges courants](https://scikit-learn.org/stable/common_pitfalls.html)
- [Documentation ML.NET](https://learn.microsoft.com/dotnet/machine-learning/) et [documentation Tribuo](https://tribuo.org/)
- *[An Introduction to Statistical Learning](https://www.statlearning.com/)*, de James, Witten, Hastie, Tibshirani et Taylor : gratuit en ligne, le livre derrière la plupart des formules de ce cours
- [ndarray](https://docs.rs/ndarray/0.17/ndarray/), la crate de matrices que partagent IX et ce cours
