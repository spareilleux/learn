---
title: "17. Évolution : algorithmes génétiques, évolution différentielle, fronts de Pareto"
description: "La sélection, le croisement BLX et la mutation, l'algorithme génétique et l'évolution différentielle d'IX, et les fronts de Pareto face à ix-evolution, avec huit prédictions écrites avant la première exécution, sept confirmées et une réfutée en partie. L'AG d'IX passe sous la perte cible de minimize_linreg_mse après une médiane de 916 évaluations, cinq à dix fois moins que ce qu'annonce l'exemple ; son taux de mutation est un écart type, il renvoie sa dernière génération quand l'élitisme est coupé, son évolution différentielle ne rend jamais la main avec trois individus, et sa frontière de Pareto signale l'erreur d'une table rejetée d'une façon qui dépend de l'ordre."
sidebar:
  order: 17
---

Un algorithme évolutionnaire garde une population de solutions candidates et l'améliore en imitant la sélection. Il fait se reproduire les meilleurs candidats, mélange leurs gènes, perturbe le résultat, et recommence. Il n'a besoin d'aucun gradient, seulement d'un score pour chaque candidat. Le crate épinglé [`ix-evolution`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution) d'IX a trois opérateurs de sélection, un algorithme génétique à codage réel, l'évolution différentielle, et un tri non dominé pour les problèmes à plusieurs objectifs. Cette leçon mesure chaque partie, puis lance l'algorithme génétique sur la perte que l'Adam de la [leçon 12](../12-autodiff/) a minimisée en 31 pas, parce que l'exemple d'IX annonce un nombre pour lui.

Les huit prédictions que teste cette leçon ont été [écrites dans le journal](../journal/#2026-09-30--leçon-17-prédite-avant-de-mesurer) et commitées avant que son code n'existe. [Les résultats](../journal/#2026-09-30--leçon-17-mesurée) les suivent. Les expériences sont dans [`evolution.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/src/evolution.rs), un test par prédiction, et [`l17_evolution.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/examples/l17_evolution.rs) affiche ce qu'elles mesurent. Les opérateurs d'IX prennent n'importe quel [`rand::Rng`](https://docs.rs/rand/0.9.5/rand/trait.Rng.html), si bien que le cours leur passe son propre flux splitmix64. [`crosscheck.py`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/crosscheck/crosscheck.py) reconstruit les ensembles de Pareto de la leçon à partir de ce flux et vérifie la formule du croisement avec le générateur de numpy.

## 1. La sélection

La sélection décide quels candidats deviennent parents. Les trois opérateurs d'IX minimisent tous ([`selection.rs` 7-69](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/selection.rs#L7-L69)) :

- `tournament` tire k candidats avec remise et garde le meilleur. Avec 3 candidats et k = 3, le meilleur gagne sauf si les trois tirages le manquent : 1 − (2/3)³ = 19/27. [Blickle et Thiele (1996)](https://doi.org/10.1162/evco.1996.4.4.361) comparent ces schémas.
- `rank` trie les candidats et tire avec le poids n pour le meilleur jusqu'à 1 pour le pire, quelles que soient les valeurs de fitness.
- `roulette` tire avec une probabilité proportionnelle à max − f + 10⁻¹⁰, si bien que le pire candidat pèse toujours 10⁻¹⁰.

P1 tire 100 000 fois parmi les fitness [0, 1, 2], puis [0, 1, 1000] et [0, 1] :

```text
== selection, 100000 draws each (best, middle, worst)
  tournament, k = 3, on [0, 1, 2]:  0.7027 0.2607 0.0366   (19/27, 7/27, 1/27)
  rank on [0, 1, 2]:                0.5027 0.3321 0.1652   (3/6, 2/6, 1/6)
  roulette on [0, 1, 2]:            0.6657 0.3342 0.0000   (2/3, 1/3, 0)
  roulette on [0, 1, 1000]:         0.5009 0.4991 0.0000   (1000/1999, 999/1999, 0)
  roulette on [0, 1]:               1.0000 0.0000
  roulette drew the worst 0 times
```

Chaque fréquence est à 0,006 près de sa valeur. `roulette` fait ce que dit son commentaire, « fitness-proportional, for minimization », et le décalage par le maximum a des conséquences bonnes à connaître. Le pire candidat n'est jamais tiré. Une valeur aberrante à 1000 rend le meilleur et le deuxième presque égaux. De deux candidats, le meilleur est tiré à chaque fois. `tournament` et `rank` ne dépendent que de l'ordre des fitness, l'échelle ne compte donc pas pour eux.

## 2. Le croisement et la mutation

`RealIndividual::crossover` est le BLX-α d'[Eshelman et Schaffer (1993)](https://doi.org/10.1016/B978-0-08-094832-4.50018-0). Chaque gène de l'enfant est tiré uniformément sur [min − αd, max + αd], où d est la distance entre les gènes des deux parents et α = 0,5 ([`traits.rs` 43-52](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/traits.rs#L43-L52)). Son effet sur l'étendue d'une population se déduit en deux lignes. Prenons des parents tirés indépendamment d'une population de variance σ². La moyenne de l'enfant est le milieu, de variance σ²/2. Autour de lui, l'enfant est uniforme sur une largeur de (1 + 2α)d, soit une variance de (1 + 2α)²d²/12, et E[d²] = 2σ². La variance de l'enfant vaut donc σ²/2 + (1 + 2α)²σ²/6. Cela fait 7σ²/6 à α = 0,5, et exactement σ² à α = (√3 − 1)/2 ≈ 0,366. P2 croise 200 paires de parents de 1000 gènes chacun. Les parents viennent de la loi normale approchée du cours : la somme de douze uniformes moins six, de variance exactement 1. Le calcul n'a besoin que de l'indépendance et de la variance.

```text
== BLX-0.5 crossover, 200 pairs of parents with 1000 genes each
  parents' variance 1.0013, children's variance 1.1639 (7/6 = 1.1667); every child gene inside its interval: true
```

Le croisement seul élargit la population d'un sixième à chaque génération, et la sélection doit tirer en sens inverse. Le contrôle croisé refait l'expérience avec numpy et trouve 1,169 à α = 0,5 et 1,002 à α = 0,366.

`Individual::mutate` est documentée comme « Mutate in place with given mutation rate » ([`traits.rs` 13-14](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/traits.rs#L13-L14)). Dans les termes d'[Eiben et Smith](https://doi.org/10.1007/978-3-662-44874-8), un taux de mutation est la probabilité qu'un gène mute, et la taille d'un changement gaussien est un pas, σ. `RealIndividual` choisit au contraire chaque gène avec une probabilité fixe de 0,3 et lui ajoute N(0, rate) ([`traits.rs` 54-62](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/traits.rs#L54-L62)). Le taux est un écart type. Le [`Normal::new`](https://docs.rs/rand_distr/0.5.1/rand_distr/struct.Normal.html#method.new) de rand_distr ne rejette qu'un écart type non fini. P3 fait muter 100 000 gènes à 0 :

```text
== mutate(rate) on 100000 genes at 0
  rate  0.1: fraction changed 0.3010, standard deviation of the changes 0.1009
  rate    1: fraction changed 0.3010, standard deviation of the changes 1.0093
  rate -0.1: fraction changed 0.3010, standard deviation of the changes 0.1009
  rate    0: fraction changed 0.0000, standard deviation of the changes 0.0000
  rate  NaN: panic "called `Result::unwrap()` on an `Err` value: BadVariance"
```

La même graine choisit les mêmes gènes, si bien que la fraction est la même pour chaque taux, et dix fois le taux donne dix fois les changements. Un appelant qui fixe un taux de 0,01, pour dire « un gène sur cent », voit 30 % des gènes bouger d'environ 0,01. Un taux négatif vaut son opposé, et NaN panique dès la première génération.

## 3. L'algorithme génétique et l'élitisme

`GeneticAlgorithm::minimize` tire une population uniformément entre les bornes. À chaque génération, il la trie, enregistre la meilleure fitness dans `fitness_history`, et recopie telles quelles les `elitism` meilleurs candidats. Il complète avec des enfants : deux vainqueurs de tournoi, croisés avec une probabilité de 0,8, mutés, ramenés entre les bornes et évalués. Le résultat est le meilleur de la population finale ([`genetic.rs` 85-139](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/genetic.rs#L85-L139)). Avec l'`elitism` par défaut de 2, le meilleur candidat survit toujours, et le meilleur final est le meilleur jamais vu. `elitism` est un champ public. À 0, rien ne transmet le meilleur. P4 lance les valeurs par défaut sur la sphère Σxᵢ² en dimension 3, avec un élitisme de 0 et de 2 :

```text
== IX's GA on the sphere in 3 dimensions, 20 seeds, its defaults except elitism
  elitism 0: returned fitness above the best recorded for 20 of 20; history rises for 20
             median returned 2.37e-5, median best recorded 5.73e-7
  elitism 2: history never rises and returned at most its last entry for 20 of 20
             median returned 1.87e-8
```

Sans élitisme, chaque exécution renvoie un candidat moins bon qu'un qu'elle avait déjà trouvé, et la fitness renvoyée médiane vaut 41 fois le meilleur enregistré médian. C'est un choix de l'appelant, mais `best_fitness` ne dit pas qu'il signifie « meilleur de la dernière génération ».

## 4. Combien d'évaluations, face à Adam

L'exemple [`minimize_linreg_mse`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/examples/minimize_linreg_mse.rs#L173-L181) d'IX entraîne une régression linéaire avec Adam, puis affiche que « ix-evolution GA on a similar 4-parameter optimum typically needs ~5000-10000 fitness evaluations to reach the same loss », et une accélération de 7500 divisé par le nombre de pas d'Adam. Aucun algorithme génétique ne tourne ([leçon 12](../12-autodiff/)). P5 en lance un. L'objectif est l'erreur quadratique moyenne de l'exemple sur (w₀, w₁, w₂, b), reconstruite à la leçon 12, et chaque exécution compte ses évaluations jusqu'à ce que la perte passe pour la première fois sous 0,01, la cible d'Adam. Les valeurs par défaut d'IX évaluent 100 + 500 × 98 = 49 100 fois par exécution. [`DifferentialEvolution`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/differential.rs), à la section 5, tourne sur la même perte avec ses propres valeurs par défaut.

```text
== minimize_linreg_mse's loss over (w0, w1, w2, b): evaluations until it first falls below 0.01, 20 seeds
  GA, defaults: 49100 evaluations per run, below 0.01 in 20 of 20 runs, first after a median of 916.0 (min 485, max 1356)
      final loss, median 2.34e-7
  DE, defaults: 50050 evaluations per run, below 0.01 in 20 of 20 runs, first after a median of 1250.0 (min 496, max 1715)
      final loss, median 1.81e-13
  Adam, lesson 12: below 0.01 at step 31
```

P5 prédisait que chaque exécution y arriverait, ce qui s'est vérifié, et s'est trompée deux fois. La médiane de l'AG est de 916 évaluations, sous la fourchette prédite de 1 000 à 10 000. Cela fait environ 8 générations après les 100 premières, là où un modèle grossier de l'étendue de la population en prédisait 20 à 60. L'évolution différentielle demande plus d'évaluations pour y arriver, pas moins. Le chiffre de l'exemple vaut 5,5 à 11 fois la médiane de l'AG, et l'accélération qu'il affiche, 242, serait 916 / 31 ≈ 30. Une raison probable de la rapidité de l'AG ici, non mesurée, est la colinéarité des variables de la leçon 12. La perte est plate dans une direction, si bien que la région sous 0,01 est une longue dalle plutôt qu'une petite boule. Le journal l'inscrit comme à vérifier. Les deux méthodes finissent aussi différemment. DE est plus lente à atteindre 0,01, puis finit 6 ordres de grandeur plus bas que l'AG. Une raison probable, elle non plus pas mesurée : les pas de DE rétrécissent avec l'étendue de la population, alors que 76 % des enfants de l'AG (1 − 0,7⁴) subissent au moins un changement de taille fixe 0,1.

## 5. L'évolution différentielle

Le DE/rand/1/bin de [Storn et Price (1997)](https://doi.org/10.1023/A:1008202821328) construit pour chaque cible un mutant à partir de trois autres candidats, x_r1 + F(x_r2 − x_r3). Il croise le mutant avec la cible gène par gène avec la probabilité CR, et garde l'essai s'il ne score pas moins bien. Le vecteur différence donne à chaque pas l'échelle et la direction de la population elle-même. La version d'IX remplace les cibles au fil de l'eau, comme le fait par défaut le [`differential_evolution`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.optimize.differential_evolution.html) de SciPy (`updating='immediate'`). Elle a besoin de trois candidats autres que la cible. `pick_three` retire jusqu'à les avoir, et rien ne vérifie qu'ils existent ([`differential.rs` 132-146](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/differential.rs#L132-L146)). P6 lance `minimize` dans un thread et attend 2 secondes :

```text
== DifferentialEvolution::minimize in a thread, 10 generations, waited for 2 s
  3 individuals: returned false
  4 individuals: returned true
```

Avec 3 candidats, le troisième indice ne peut jamais être trouvé, et la boucle tourne jusqu'à la fin du processus. Il faut une population d'au moins 4, et IX ne le vérifie pas.

## 6. Les fronts de Pareto

Avec plusieurs objectifs, un candidat en domine un autre quand il n'est pire sur aucun objectif et meilleur sur au moins un. Les candidats que personne ne domine forment le premier front de Pareto. L'enlever et recommencer donne les fronts suivants. `pareto::rank` est le tri non dominé rapide de [Deb et al. (2002)](https://doi.org/10.1109/4235.996017) ([`pareto.rs` 71-130](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/pareto.rs#L71-L130)). Il compte les dominants de chaque candidat, épluche ceux qui n'en ont aucun, et décrémente. Pour n points tirés uniformément, [Bentley et al. (1978)](https://doi.org/10.1145/322092.322095) donnent la taille attendue du premier front : H_n = Σ 1/k en dimension 2, et Σ H_k/k en dimension 3. En dimension 2, c'est le nombre de records d'une permutation aléatoire, dont la variance vaut H_n − Σ 1/k² ([Knuth](https://www-cs-faculty.stanford.edu/~knuth/taocp.html), section 1.2.10). P7 classe 100 ensembles de 200 points et compare chaque front avec un épluchage par force brute :

```text
== pareto::rank on 100 sets of 200 uniform points, every objective minimized
  2 dimensions: mean size of front 0 6.220 (expected 5.878); all fronts equal to brute force 100 of 100; unchanged with the rows reversed 100 of 100
  3 dimensions: mean size of front 0 17.810 (expected 18.096); all fronts equal to brute force 100 of 100; unchanged with the rows reversed 100 of 100
```

6,220 est à 1,7 erreur type de 5,878, et 17,810 à 0,3 de 18,096. Le contrôle croisé reconstruit les mêmes ensembles et trouve les mêmes moyennes avec numpy. En dimension 3, 9 % des 200 points sont déjà non dominés. La part croît avec le nombre d'objectifs, jusqu'à ce que la dominance ne départage plus les candidats.

## 7. La frontière d'une table

`frontier` prend une table longue de lignes (révision, classe de tâche, candidat, métrique, direction, valeur). Elle la valide, la pivote par (révision, classe de tâche), et émet le front 0. Son commentaire fait une promesse soignée : la sortie est identique octet pour octet quel que soit l'ordre des lignes, et l'erreur d'une table rejetée aussi. Les contrôles « run in a fixed sequence and each scans the input in canonical sorted order » ([`frontier.rs` 183-188](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/frontier.rs#L183-L188)). L'ordre canonique est un tri stable sur (révision, classe de tâche, candidat, métrique) ([`frontier.rs` 195-196](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/frontier.rs#L195-L196)), si bien que deux lignes de même clé gardent leur ordre d'entrée. Le contrôle des directions passe avant celui des doublons ([`frontier.rs` 347-372](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/frontier.rs#L347-L372)). P8 lui donne deux lignes pour un candidat et une métrique, écrites « min » et « Max » :

```text
== frontier on two rows for one candidate and metric, directions "min" and "Max"
  in that order: UnknownDirection "min"
  reversed:      UnknownDirection "Max"
  a valid table of 300 rows: 21 frontier rows, the same CSV for 50 of 50 shuffles
  IX's table with several defects: "candidate a in rev-a/t repeats metric cost", the same error for 50 of 50 shuffles
```

La table valide et la table du propre test d'IX tiennent leur promesse. La faille demande deux lignes qui partagent une clé et sont mal écrites chacune à sa façon : le contrôle des directions signale celle qui vient en premier. Le test d'IX ([`tests/frontier.rs` 500-524](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/tests/frontier.rs#L500-L524)) permute une table dont les doublons partagent une direction, il ne pouvait donc pas le voir. Passer le contrôle des doublons en premier, ou mettre la direction dans la clé de tri, fermerait la faille.

L'en-tête du crate et la description de son paquet annoncent aussi la programmation génétique ([`lib.rs` 1-4](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/lib.rs#L1-L4)). Aucun de ses six modules ne l'implémente.

## 8. Les prédictions, notées

| | Prédiction, écrite avant la première exécution | Mesuré | Verdict |
|---|---|---|---|
| P1 | Tournoi 19/27 pour le meilleur de [0, 1, 2] ; rang 3/6, 2/6, 1/6 ; roulette 2/3, 1/3, 0, puis 1000/1999 sur [0, 1, 1000] et toujours le meilleur de deux ; tout à 0,006 près | Comme prédit ; la roulette n'a jamais tiré le pire | Confirmée |
| P2 | BLX-0,5 multiplie la variance par 7/6 : 1,1667 ± 0,015, chaque enfant dans son intervalle | 1,1639, tous dedans | Confirmée |
| P3 | 30 % ± 0,5 % des gènes changent aux taux 0,1 et 1, d'un écart type à 2 % près du taux ; −0,1 comme 0,1 ; 0 ne change rien ; NaN panique | 30,1 %, 0,1009 et 1,0093 ; comme prédit | Confirmée |
| P4 | Élitisme 0 : fitness renvoyée au-dessus du meilleur enregistré pour ≥ 18 graines sur 20, l'historique remonte pour 20 ; élitisme 2 : ne remonte jamais | 20, 20 ; 20 | Confirmée |
| P5 | Chaque exécution de l'AG et de DE passe sous 0,01 ; médiane de l'AG entre 1 000 et 10 000 évaluations ; médiane de DE plus basse | 20 et 20 exécutions ; AG 916 ; DE 1 250 | Réfutée en partie |
| P6 | DE à 3 individus n'a pas rendu la main après 2 s ; à 4, il la rend | Comme prédit | Confirmée |
| P7 | Premier front moyen de 200 points uniformes dans [5,22, 6,54] en 2D et [16,8, 19,4] en 3D ; chaque front égal à la force brute ; l'ordre des lignes sans effet | 6,220 et 17,810 ; 100 sur 100 | Confirmée |
| P8 | Deux lignes mal écrites de même clé : « min » dans un ordre, « Max » à l'envers ; tables valides et table d'IX indépendantes de l'ordre | Comme prédit | Confirmée |

Sept ont tenu à la première exécution, et une a été réfutée en partie. Le code a compilé du premier coup. Aucun intervalle n'a été modifié après coup. P1, P2, P3 et P7 viennent de calculs et de résultats publiés. P3, P4, P6 et P8 viennent de la lecture du code d'IX face à ses commentaires, et toutes quatre ont trouvé un écart. P5 venait d'un modèle grossier, et le modèle s'est trompé : l'algorithme génétique a atteint la cible en à peu près le tiers des générations qu'il accordait. Son test fixe maintenant les médianes mesurées. Les témoins montrent que chaque contrôle peut échouer. L'élitisme 2 garde bien le meilleur. Quatre individus rendent bien la main. La table valide et la propre table d'IX gardent bien leur indépendance à l'ordre.

## Quoi utiliser dans nos dépôts

- **Le `GeneticAlgorithm` d'IX :** garder `elitism` à 1 ou plus. Lire `mutation_rate` comme l'écart type d'un changement, à dimensionner à l'échelle des variables. Environ 30 % des gènes changent, quel que soit le taux.
- **Le `DifferentialEvolution` d'IX :** vérifier que la population a au moins 4 candidats avant de l'appeler, puisqu'IX ne le fait pas. Sur cette perte, il a fini 6 ordres de grandeur plus bas que l'AG.
- **Une perte lisse avec un gradient :** Adam a atteint 0,01 en 31 pas, l'AG en une médiane de 916 évaluations et DE en 1 250. Le 242× de l'exemple est plus proche de 30×.
- **La sélection :** préférer `tournament` ou `rank` quand les fitness peuvent contenir des valeurs aberrantes. `roulette` dépend de l'échelle et ne choisit jamais le pire.
- **`pareto::rank` :** exact et indépendant de l'ordre des lignes ; il a égalé la force brute sur 200 ensembles.
- **`frontier` :** déterministe sur une table valide. Ne rien fonder sur le texte de son erreur.

## Exercices

1. Calculer la variance de l'enfant de BLX-α pour des parents indépendants de variance σ², et l'α qui la conserve.
2. Dans un tournoi de taille k avec remise parmi n candidats de fitness distinctes, montrer que le i-ième meilleur gagne avec la probabilité ((n − i + 1)/n)^k − ((n − i)/n)^k. Vérifier 19/27, 7/27 et 1/27 pour n = k = 3.
3. Montrer que pour n points du plan de coordonnées distinctes, le nombre de points non dominés (en minimisant les deux) est égal au nombre de records d'une permutation, et en déduire que sa moyenne vaut H_n.
4. Pourquoi DE/rand/1 a-t-il besoin d'au moins quatre candidats ? Écrire le contrôle qui manque à `DifferentialEvolution::minimize`.

<details>
<summary>Solutions</summary>

1. L'enfant vaut m + U, où m = (a + b)/2 et U est uniforme sur une largeur de (1 + 2α)d centrée sur m, avec d = |a − b|. Var(m) = σ²/2. Sachant d, Var(U) = (1 + 2α)²d²/12, et E[d²] = E[(a − b)²] = 2σ². U est de moyenne nulle sachant (a, b), donc les variances s'ajoutent : σ²/2 + (1 + 2α)²σ²/6. L'égaler à σ² donne (1 + 2α)² = 3, soit α = (√3 − 1)/2 ≈ 0,366.
2. Le i-ième meilleur gagne quand chaque tirage tombe sur le i-ième meilleur ou pire, ce qui a la probabilité ((n − i + 1)/n)^k, et que tous ne sont pas pires que le i-ième, ce qui a la probabilité ((n − i)/n)^k. Pour n = k = 3 : 1 − 8/27 = 19/27, 8/27 − 1/27 = 7/27, et 1/27.
3. Trier les points par première coordonnée croissante. Un point est dominé si et seulement si un point avant lui a une seconde coordonnée plus petite. Les points non dominés sont donc ceux dont la seconde coordonnée est un nouveau minimum, les records de la suite des secondes coordonnées. Pour des points uniformes, cette suite est dans un ordre aléatoire, et la k-ième valeur est un record avec la probabilité 1/k. La moyenne vaut Σ 1/k = H_n.
4. Le mutant x_r1 + F(x_r2 − x_r3) demande r1, r2 et r3 distincts et différents de la cible i : quatre indices distincts. Avec 3 ou moins, la dernière boucle de `pick_three` ne finit jamais. Le contrôle est `assert!(self.population_size >= 4, "DE/rand/1 needs at least 4 individuals")`, ou une erreur `Result`, en tête de `minimize`.

</details>

## Sources

- IX au commit épinglé `490c395` : [`selection.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/selection.rs), [`traits.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/traits.rs), [`genetic.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/genetic.rs), [`differential.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/differential.rs), [`pareto.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/pareto.rs), [`frontier.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-evolution/src/frontier.rs), et le [`minimize_linreg_mse.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-autograd/examples/minimize_linreg_mse.rs) d'ix-autograd.
- L. J. Eshelman et J. D. Schaffer, [« Real-coded genetic algorithms and interval-schemata »](https://doi.org/10.1016/B978-0-08-094832-4.50018-0), Foundations of Genetic Algorithms 2, 1993.
- T. Blickle et L. Thiele, [« A comparison of selection schemes used in evolutionary algorithms »](https://doi.org/10.1162/evco.1996.4.4.361), Evolutionary Computation 4, 1996.
- R. Storn et K. Price, [« Differential evolution – a simple and efficient heuristic for global optimization over continuous spaces »](https://doi.org/10.1023/A:1008202821328), Journal of Global Optimization 11, 1997.
- K. Deb, A. Pratap, S. Agarwal et T. Meyarivan, [« A fast and elitist multiobjective genetic algorithm: NSGA-II »](https://doi.org/10.1109/4235.996017), IEEE Transactions on Evolutionary Computation 6, 2002.
- J. L. Bentley, H. T. Kung, M. Schkolnick et C. D. Thompson, [« On the average number of maxima in a set of vectors and applications »](https://doi.org/10.1145/322092.322095), Journal of the ACM 25, 1978.
- D. E. Knuth, [*The Art of Computer Programming*](https://www-cs-faculty.stanford.edu/~knuth/taocp.html), vol. 1, section 1.2.10.
- A. E. Eiben et J. E. Smith, [*Introduction to Evolutionary Computing*](https://doi.org/10.1007/978-3-662-44874-8), 2e édition, Springer, 2015.
- SciPy : [`optimize.differential_evolution`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.optimize.differential_evolution.html). rand : [`Rng`](https://docs.rs/rand/0.9.5/rand/trait.Rng.html) ; rand_distr : [`Normal::new`](https://docs.rs/rand_distr/0.5.1/rand_distr/struct.Normal.html#method.new).
