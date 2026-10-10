---
title: "9. Cinq autres réducteurs : MDS, ACP à noyau, NMF, LDA et t-SNE"
description: "Reconstruire un carré à partir de ses distances à la main et avec IX, trouver l'axe qui distingue deux anneaux, factoriser des durées CI, projeter les jobs étiquetés et vérifier ce que fait réellement transform dans le t-SNE d'IX."
sidebar:
  order: 9
---

La leçon 5 utilisait l'[ACP](../05-dimensionality-reduction/) pour conserver les directions de forte variance. C'est une question parmi d'autres, pas une définition universelle d'une bonne projection. Voici cinq autres questions, chacune traitée par un réducteur de la version épinglée d'[`ix-unsupervised`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised). L'expérience exécutable se trouve dans [`l09_reducers.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/examples/l09_reducers.rs) ; [`crosscheck.py`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/crosscheck/crosscheck.py) vérifie les mêmes propriétés indépendamment avec numpy et scikit-learn 1.8.0. Le [journal](../journal/#2026-09-24--cinq-réducteurs-trois-entrées) distingue mesures et incertitudes.

| Question | Méthode | Entrée | Sens de la sortie |
|---|---|---|---|
| Peut-on préserver des distances sans même disposer des caractéristiques ? | MDS classique | Matrice des distances deux à deux | Coordonnées reproduisant les distances euclidiennes, si possible |
| Une similarité non linéaire révèle-t-elle une structure invisible pour un axe droit ? | ACP à noyau | Caractéristiques et noyau choisi | Axes de variance dans l'espace du noyau |
| Peut-on décomposer des mesures positives en parties additives ? | NMF | Matrice de caractéristiques non négatives | Deux facteurs non négatifs dont le produit approche l'entrée |
| Quelles directions séparent des classes **connues** ? | Analyse discriminante linéaire (LDA) | Caractéristiques **et** étiquettes | Au plus `classes - 1` axes discriminants |
| Quels points sont voisins dans une visualisation ? | t-SNE | Matrice des caractéristiques | Disposition ajustée ; distances et tailles des groupes ne sont pas des mesures étalonnées |

Ici, **LDA** signifie *analyse discriminante linéaire*, et non l'autre méthode appelée *latent Dirichlet allocation*. Aucune de ces projections ne remplace une évaluation sur des données tenues à l'écart.

## 1. MDS : partir des distances, pas des caractéristiques

La [MDS classique](https://scikit-learn.org/stable/modules/manifold.html#multidimensional-scaling) part d'une matrice `D` de taille `n × n`, et non des caractéristiques d'origine. On élève chaque distance au carré, on retranche les moyennes de sa ligne et de sa colonne, puis on ajoute la moyenne générale :

```text
Bᵢⱼ = -½ (D²ᵢⱼ - row_meanᵢ - column_meanⱼ + grand_mean)
```

C'est l'identité `B = -½ J D² J`, avec `J = I - 11ᵀ/n`. Si les distances proviennent de points euclidiens, `B` est leur matrice de Gram centrée. Ses principaux vecteurs propres, multipliés par la racine carrée de leurs valeurs propres, donnent des coordonnées. La version à la main réutilise l'algorithme de Jacobi de la leçon 5 ; [`classical_mds`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/mds.rs) emploie le solveur symétrique d'`ix-math`. Sur un carré de côté un, les deux versions retrouvent les six distances non nulles à `1e-10` près :

```text
== classical MDS: square from distances alone
  hand and IX recover all six distances: true
```

On compare les *distances*, pas les coordonnées : une rotation ou une réflexion change les coordonnées sans changer la réponse. Une matrice de distances non euclidiennes peut produire des valeurs propres négatives ; les ramener à zéro donne une approximation, pas la preuve d'un plongement exact. IX implémente ici la MDS **classique**, et non une minimisation itérative du *stress*.

## 2. ACP à noyau : choisir une similarité non linéaire

L'[ACP à noyau](https://scikit-learn.org/stable/modules/decomposition.html#kernel-pca) remplace la matrice de covariance de l'ACP par une matrice de noyau centrée, `Kᵢⱼ = k(xᵢ, xⱼ)`. Le type [`Kernel`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/kernel_pca.rs) d'IX est une énumération : noyaux linéaire, polynomial et gaussien RBF. La valeur RBF est `exp(-γ ||xᵢ-xⱼ||²)` ; `γ` détermine ce qu'on considère comme proche.

Huit points occupent deux anneaux concentriques. La moyenne de chaque anneau vaut `(0, 0)` : le premier axe **linéaire** ne peut donc distinguer leurs moyennes. Nous pensions, à titre exploratoire, que le **premier axe RBF** le ferait ; c'était faux aussi. Avec `γ = 0.5`, le contraste radial apparaît sur **l'axe 4** :

```text
== kernel PCA: concentric rings
  mean gap on linear axis: 0.0000
  mean gap on RBF axis 1: 0.0000
  mean gap on RBF axis 4: 0.5798
  linear axis separates ring means: false
  fourth RBF axis separates ring means: true
```

Ne garder que les deux premières composantes ferait perdre la propriété recherchée. Ce n'est pas un défaut d'IX : maximiser la variance dans l'espace du noyau ne revient toujours pas à séparer les anneaux. Le signe d'un axe est arbitraire ; l'expérience prend la valeur absolue de l'écart entre les moyennes.

## 3. NMF : des parties additives exigent des données positives

La [factorisation en matrices non négatives](https://scikit-learn.org/stable/modules/decomposition.html#nmf) cherche `V ≈ W H`, tous les éléments de `V`, `W` et `H` restant non négatifs. La [`NonNegativeMatrixFactorization`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/nmf.rs) d'IX utilise des mises à jour multiplicatives. Les 186 jobs CI du cours ont chacun cinq durées positives en secondes : c'est une entrée admissible. Au rang deux, avec 300 itérations et la graine 42, l'erreur quadratique moyenne de reconstruction vaut `0.505` secondes carrées par cellule :

```text
== NMF: CI timings, 186 jobs x 5 features
  rank 2 reconstruction MSE: 0.505
  standardized input rejected: true
```

Standardiser ces mêmes colonnes soustrait leur moyenne et crée des valeurs négatives : IX refuse cette matrice. Pour NMF, utilisons les durées brutes. N'appelons toutefois pas les deux facteurs des « profils de charge » sur la seule foi de l'erreur : il faut comparer plusieurs graines, inspecter `H` et mesurer la reconstruction sur des données tenues à l'écart. Contrairement à l'ACP, NMF n'est pas une projection orthogonale et ses facteurs ne sont pas uniques.

## 4. LDA : les étiquettes déterminent la question

L'[analyse discriminante linéaire](https://scikit-learn.org/stable/modules/lda_qda.html#dimensionality-reduction-using-linear-discriminant-analysis) oppose la dispersion entre classes à la dispersion au sein de chacune. Nous connaissons le système d'exploitation du runner de chaque job CI : Ubuntu, Windows ou macOS. La [`LinearDiscriminantAnalysis`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/lda.rs) d'IX ajuste deux axes sur les durées standardisées :

```text
== LDA: runner OS labels
  three OS classes allow at most two axes: true
  projection finite: true
```

Trois classes autorisent au plus `3 - 1 = 2` axes discriminants, même si l'entrée a cinq colonnes. L'exemple ajuste et projette les **mêmes** 186 lignes pour montrer l'API : il ne mesure aucune exactitude en test. Pour savoir si les durées prédisent l'OS, il faut d'abord séparer entraînement et test, ajuster le standardiseur et LDA sur l'entraînement seulement, transformer le test, puis entraîner et évaluer un classifieur. Sinon, les étiquettes du test influencent la projection.

## 5. t-SNE : un dessin des voisinages, pas un standardiseur réutilisable

[t-SNE](https://scikit-learn.org/stable/modules/manifold.html#t-sne) convertit les distances en probabilités de voisinage, dans l'entrée puis dans une disposition de dimension réduite, et déplace les points affichés pour rapprocher les deux. La *perplexité* règle une échelle de voisinage, pas le nombre de groupes. Le graphique peut susciter de bonnes questions, mais ses distances globales et la taille apparente des groupes ne sont pas étalonnées.

Le [`TSNE`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/tsne.rs) d'IX accepte une graine. Nous ajustons douze jobs standardisés, avec une perplexité de 3 et 300 itérations. L'en-tête du module promet une « approximation Barnes-Hut », mais cette version parcourt chaque paire dans `compute_q`, puis dans le gradient : prévoyons un travail quadratique, pas le passage à l'échelle de Barnes-Hut. Surtout, `transform` ignore son argument et rend la disposition déjà ajustée :

```text
== t-SNE: first 12 standardized jobs
  12 x 2 finite embedding: true
  transform ignores its input: true
```

Passer un treizième job à `transform` ne le place **pas** sur la carte. Réajuster avec ce point change le problème et peut déplacer tous les autres. Si nous devons projeter de futurs jobs, commençons plutôt par une ACP ou une ACP à noyau ajustée ; le t-SNE d'IX n'est pas un transformateur de production.

## Quels usages dans nos dépôts ?

- **Géométrie des voicings IX/GA :** partir de l'ACP et d'une métrique de recherche musicale adaptée ; employer ACP à noyau ou t-SNE pour explorer, jamais pour prouver que les îlots visuels sont des classes musicales.
- **Historique Gaia ou CI :** la MDS classique est pertinente si l'objet est une distance mesurée entre runs ou traces, et non un vecteur de caractéristiques. Vérifier le caractère euclidien avant de promettre une carte exacte.
- **Durées CI :** NMF pourrait dévoiler des motifs additifs, sous réserve de stabilité et de vérification hors échantillon. LDA pose une autre question, supervisée, à partir des étiquettes de runner.

## Exercices

1. Pourquoi comparer les six distances du carré plutôt que quatre couples de coordonnées ? Que conclure si l'erreur maximale sur les distances vaut `0.2` ?
2. Pourquoi la première composante RBF ne sépare-t-elle pas les anneaux alors que la quatrième y parvient ? Que perd-on en ne gardant que deux composantes ?
3. Pourquoi NMF refuse-t-elle les jobs CI standardisés ? Que faut-il ajuster uniquement sur les lignes d'entraînement avant d'estimer si les coordonnées LDA prédisent l'OS ?
4. Le t-SNE d'IX peut-il placer un nouveau job avec `transform` ? Quelle ligne de son source épinglé tranche la question ?

<details>
<summary>Solutions</summary>

1. Le signe et l'orientation des vecteurs propres ne sont pas déterminés ; les distances deux à deux le sont. Une erreur de `0.2` signifie que cette carte à deux dimensions ne reproduit **pas** exactement la géométrie demandée.
2. Les premiers axes maximisent la variance dans l'espace du noyau, pas la séparation des anneaux ; le contraste radial est quatrième ici. Deux composantes le perdent. Changer `γ` ou les données peut changer l'ordre : il faut examiner les axes ajustés.
3. Le centrage crée des valeurs négatives, interdites par NMF. Pour une estimation supervisée, séparer les lignes avant d'ajuster le standardiseur et LDA, puis mesurer sur le test intact.
4. Non. Dans l'[implémentation de `DimensionReducer`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/tsne.rs#L249-L253), `fn transform(&self, _x: &Array2<f64>)` rend `self.embedding.clone()` ; `_x` n'est jamais lu.

</details>

## Sources

- IX au commit épinglé `490c395` : [MDS](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/mds.rs), [ACP à noyau](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/kernel_pca.rs), [NMF](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/nmf.rs), [LDA](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/lda.rs), [t-SNE](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/tsne.rs).
- [Guide scikit-learn sur les variétés](https://scikit-learn.org/stable/modules/manifold.html), [guide sur les décompositions](https://scikit-learn.org/stable/modules/decomposition.html) et [guide LDA](https://scikit-learn.org/stable/modules/lda_qda.html).
