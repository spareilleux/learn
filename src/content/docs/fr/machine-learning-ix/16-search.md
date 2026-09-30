---
title: "16. Recherche : A*, recherche arborescente Monte-Carlo, recherche locale"
description: "A* et ses variantes pondérée, bidirectionnelle et Q*, la recherche arborescente Monte-Carlo et la recherche locale face à ix-search d'IX, avec huit prédictions écrites avant la première exécution, toutes tenues. A* pondéré tient sa borne et l'ascension rejoint Russell et Norvig sur les 8 reines ; l'A* d'IX demande une heuristique cohérente là où son contrat dit admissible, sa recherche bidirectionnelle suit les arcs directs depuis le but, son Q* ne distingue pas une impasse du bon chemin, et son MCTS joue l'adversaire comme un partenaire."
sidebar:
  order: 16
---

Chercher, pour un programme, c'est choisir parmi de nombreuses suites de coups : un itinéraire dans un graphe, un coup dans une partie, la configuration qui obtient le meilleur score. Le crate [`ix-search`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search) épinglé d'IX contient A\* et ses variantes pondérée, bidirectionnelle et Q\*, les parcours en largeur et en profondeur, minimax et alpha-bêta, la recherche arborescente Monte-Carlo et la recherche locale. [`ix-graph`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-graph) contient l'algorithme de Dijkstra. Cette leçon les fait tourner sur de petits graphes déroulés à la main, sur des labyrinthes aléatoires, sur un jeu à deux coups et sur les 8 reines, et vérifie ce que promet le [`CONTRACTS.md`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/CONTRACTS.md) d'IX.

Les huit prédictions que teste cette leçon ont été [écrites dans le journal](../journal/#2026-09-30--leçon-16-prédite-avant-de-mesurer) et commitées avant que son code n'existe. [Les résultats](../journal/#2026-09-30--leçon-16-mesurée) les suivent. Les expériences sont dans [`search.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/src/search.rs), un test par prédiction. [`l16_search.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/examples/l16_search.rs) affiche ce qu'elles mesurent. [`crosscheck.py`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/crosscheck/crosscheck.py) reconstruit les mêmes labyrinthes et les mêmes échiquiers à partir du `Rng` du cours. Il résout les labyrinthes avec [`csgraph.shortest_path`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.sparse.csgraph.shortest_path.html) de SciPy et rejoue l'ascension sur les échiquiers en Python pur.

## 1. A\* et l'heuristique en laquelle il a confiance

L'A\* de [Hart, Nilsson et Raphael (1968)](https://doi.org/10.1109/TSSC.1968.300136) développe, parmi les nœuds qu'il a atteints, celui dont f(n) = g(n) + h(n) est le plus petit. Ici g(n) est le coût du meilleur chemin trouvé jusqu'ici depuis le départ, et h(n) estime le coût restant jusqu'au but. Une heuristique est *admissible* quand elle ne surestime jamais, h(n) ≤ h\*(n). Elle est *cohérente* quand elle ne baisse jamais de plus que le coût d'un arc, h(n) ≤ c(n, n′) + h(n′). Avec h = 0, A\* est l'algorithme de Dijkstra : le `uniform_cost_search` d'IX est exactement `astar` avec h = 0.

Le `astar` d'IX garde un ensemble fermé et ne rouvre jamais un état fermé ([`astar.rs` 137-148](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/astar.rs#L137-L148)). Son commentaire en tire la conséquence : l'optimalité « requires a **consistent** (monotone) heuristic, not merely an admissible one » ([`astar.rs` 71-74](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/astar.rs#L71-L74)). [`CONTRACTS.md` 9](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/CONTRACTS.md#L9) dit admissible. P1 tranche sur quatre nœuds. L'optimum vaut 5, par S, A, C, G. L'heuristique h(A) = 4, 0 ailleurs, est admissible : depuis A, le chemin le moins cher coûte 1 + 3 = 4. Elle n'est pas cohérente : h(A) = 4 dépasse c(A, C) + h(C) = 1.

```text
== A*, S→A 1, S→C 3, A→C 1, C→G 3
  h(A) = 4, 0 elsewhere  cost 6, path S C G, 3 expansions
  h = 0                  cost 5, path S A C G, 3 expansions
  h = h*                 cost 5, path S A C G, 3 expansions
  ix-graph Dijkstra       5
```

S est développé en premier. A entre dans la frontière avec f = 1 + 4 = 5, et C avec f = 3 + 0 = 3. C sort d'abord et se ferme avec g = 3. Quand A sort, son chemin vers C coûte 2, mais C est fermé et le chemin moins cher est sauté : la recherche finit à 6. Avec h = 0 ou h = h\*, toutes deux cohérentes, A\* trouve 5, et le [`Graph::dijkstra`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-graph/src/graph.rs#L91-L125) d'ix-graph aussi. Ce Dijkstra n'a pas d'ensemble fermé : il réempile un nœud chaque fois que sa distance baisse, et saute les entrées périmées. Le commentaire a raison et le contrat a tort. Le remède est une heuristique cohérente, ou rouvrir un état fermé quand un chemin moins cher vers lui apparaît.

## 2. A\* pondéré sur des labyrinthes

L'A\* pondéré de [Pohl (1970)](https://doi.org/10.1016/0004-3702(70)90007-X) ordonne la frontière par g + w·h avec w > 1. Il fait davantage confiance à l'heuristique, développe moins de nœuds, et en échange le chemin trouvé peut coûter jusqu'à w fois l'optimum. [`CONTRACTS.md` 10](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/CONTRACTS.md#L10) promet cette borne. Sans réouverture, il lui faut une heuristique cohérente. [Chen et Sturtevant (2021)](https://doi.org/10.1609/aaai.v35i5.16485) montrent que la cohérence est nécessaire à une recherche best-first bornée qui ne rouvre jamais. La distance de Manhattan sur une grille aux déplacements de coût 1 est cohérente, donc P2 s'attend à ce que la borne tienne. Le test prend 100 labyrinthes de 30 × 30, chaque case étant un mur avec une probabilité de 0,25, d'un coin à l'autre :

```text
== 100 mazes of 30 x 30, walls with probability 0.25, Manhattan h
  far corner reachable:                84
  astar None exactly when unreachable: true
  astar cost = Dijkstra's everywhere:  true
  total optimal cost:                  5046
  A*:          mean expansions 383.7
  w = 1.5      mean expansions 145.3, over the bound 0, worst cost / optimum 1.1724
  w = 2        mean expansions 140.3, over the bound 0, worst cost / optimum 1.1724
  w = 5        mean expansions 132.6, over the bound 0, worst cost / optimum 1.4138
```

Dans 16 labyrinthes, les murs coupent l'accès au coin opposé. `astar` renvoie `None` pour exactement ces 16, comme le dit [`CONTRACTS.md` 8](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/CONTRACTS.md#L8). Dans les 84 autres, il trouve le coût de Dijkstra. Le contrôle croisé trouve les mêmes 84 labyrinthes et le même total de 5 046 déplacements avec SciPy. Aucun chemin pondéré ne dépasse sa borne. Le pire coûte 17 % de plus que l'optimum à w = 1,5 et 2, et 41 % à w = 5. L'essentiel du gain vient du premier pas au-dessus de 1 : w = 1,5 développe déjà 2,6 fois moins de nœuds qu'A\*. P2 ne disait rien de w = 5 face à w = 2. [Wilt et Ruml (2012)](https://www.cs.unh.edu/~ruml/papers/wted-astar-socs-12.pdf) montrent des domaines où un poids plus grand développe plus de nœuds. Sur ces labyrinthes, il en développe un peu moins.

Sur une grille ouverte, beaucoup de nœuds ont le même f. [`CONTRACTS.md` 29](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/CONTRACTS.md#L29) prévient que ces égalités suivent l'ordre interne de [`BinaryHeap`](https://doc.rust-lang.org/std/collections/struct.BinaryHeap.html). Les coûts ci-dessus n'en dépendent pas, mais les nombres d'expansions, si.

## 3. A\* bidirectionnel

Une recherche bidirectionnelle mène une recherche vers l'avant depuis le départ et une vers l'arrière depuis le but, et s'arrête quand leurs frontières ne peuvent plus améliorer le meilleur point de rencontre. La recherche arrière doit suivre les arcs à l'envers, de chaque nœud vers ses prédécesseurs. Le commentaire de `bidirectional_astar` le dit : elle « Requires a `reverse_successors` function (predecessors from goal side) ». Mais sa signature ne prend aucune fonction de ce genre, et la recherche arrière appelle `successors()` ([`astar.rs` 255-264 et 357](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/astar.rs#L255-L357)). C'est juste seulement quand chaque arc peut être parcouru à l'envers au même coût. P3 essaie un cycle orienté et un chemin non orienté :

```text
== bidirectional_astar, h = 0
  directed cycle S→A→G→S: bidirectional cost 1, path S G; astar cost 2, path S A G
  path 0-1-2-3-4: bidirectional path [0, 1, 2, 3, 4], cost 4
    bidirectional actions (0, 1) (1, 2) (3, 2) (4, 3)
    astar actions         (0, 1) (1, 2) (2, 3) (3, 4)
```

Sur le cycle, la recherche arrière quitte G par G→S, qui est un arc direct, et atteint S au coût 1. Les deux recherches se rejoignent en S, et le résultat est un chemin S, G de coût 1 par un arc qui n'existe pas. La vraie réponse est 2. Sur le chemin non orienté, le coût et les états sont justes, mais les actions après le point de rencontre sont celles de la recherche arrière : (3, 2) là où le chemin va de 2 à 3. [`CONTRACTS.md` 11](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/CONTRACTS.md#L11) dit que dans les chemins que renvoient `astar` et `weighted_astar`, `actions[i]` va de `path[i]` à `path[i+1]`. `bidirectional_astar` renvoie le même `SearchResult` et ne documente aucun autre sens, mais il ajoute les actions de la recherche arrière telles quelles ([`astar.rs` 396-402](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/astar.rs#L396-L402)). Un détail de plus, lu dans le code et non mesuré ici : chaque nœud que les deux recherches empilent reçoit f = g + h(parent), l'heuristique du nœud d'où il vient, pas la sienne ([`astar.rs` 334 et 366](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/astar.rs#L334-L366)). Avec h = 0, cela ne change rien.

## 4. Q\* : une heuristique pour tous les enfants à la fois

Quand un état a beaucoup de successeurs, A\* passe son temps à les générer et à appeler h sur chacun. Le Q\* d'[Agostinelli et al.](https://arxiv.org/abs/2102.04518) utilise un réseau qui prend un état et renvoie, en un seul appel, le coût restant de chaque transition qui en part. Q\* peut alors empiler les enfants sans les générer. L'en-tête du module d'IX affirme que Q\* réduit « node expansions by orders of magnitude compared to A\* » ([`qstar.rs` 1-4](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/qstar.rs#L1-L4)). Mais sa `QFunction` associe un seul nombre à un état. `qstar_search` l'appelle une fois par nœud développé et donne à chaque enfant max(h(parent) − c, 0) ([`qstar.rs` 164-191](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/qstar.rs#L164-L191)). Pour un enfant atteint au coût c ≤ h(parent), son f devient le g + h du parent, quel que soit l'enfant. P4 construit un départ avec une bonne branche et 100 impasses, dont le h de 100 dit exactement cela :

```text
== S→A→G and 100 dead ends S→D→X: (cost, expansions, heuristic calls)
  astar           2, 2, 103
  qstar_search    2, 102, 103
  qstar_two_head  2, 2, 103
```

A\* lit h = 100 sur chaque impasse, l'empile à f = 101 et ne la développe jamais. Q\* empile A et les 100 impasses au même f = 1, sous le f = 2 du but, et doit toutes les développer avant d'atteindre le but. `qstar_two_head` appelle h sur chaque successeur, comme A\*, et développe 2 nœuds. Q\* n'économise même pas d'appels à l'heuristique ici. A\* appelle h une fois par enfant empilé, Q\* une fois par nœud développé, et Q\* développe 102 nœuds pour atteindre le but. Sans fonction qui note les enfants d'un état en un seul appel, le Q\* à une tête d'IX est un A\* moins informé. Un autre écart, lu lui aussi et non mesuré : le commentaire de `qstar_bounded` décrit une recherche focale avec des listes OPEN et FOCAL, et la fonction appelle `qstar_weighted` ([`qstar.rs` 292-303](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/qstar.rs#L292-L303)).

## 5. Recherche arborescente Monte-Carlo

La recherche arborescente Monte-Carlo construit un arbre de jeu un chemin à la fois. Chaque itération descend depuis la racine avec UCB1, la règle de bandit de la [leçon 14](../14-reinforcement-learning/), que [Kocsis et Szepesvári (2006)](https://doi.org/10.1007/11871842_29) ont appliquée aux arbres sous le nom d'UCT. Elle ajoute un enfant non essayé, termine la partie avec des coups au hasard, et ajoute le résultat à chaque nœud du chemin. Dans un jeu à deux joueurs, chaque nœud doit être noté pour le joueur qui le choisit. Sinon, les choix de l'adversaire maximisent le résultat du mauvais joueur. La revue de [Browne et al. (2012)](https://doi.org/10.1109/TCIAIG.2012.2186810) remonte chaque récompense du point de vue du joueur qui est entré dans le nœud. IX ajoute la même récompense à chaque nœud ([`mcts.rs` 93-99](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/mcts.rs#L93-L99)), et `MctsState::reward` vaut 1 pour « win » sans dire de qui ([`mcts.rs` 16-17](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/mcts.rs#L16-L17)). P5 offre au joueur racine un nul assuré B, ou un pari A où l'adversaire choisit ensuite la victoire ou la défaite du joueur racine :

```text
== A (the opponent picks win or loss) or B (a draw), 2000 iterations, exploration 1.41, 20 seeds
  ix mcts_search chooses A:  20 of 20
  negamax MCTS chooses B:    20 of 20
  ix minimax:                B, value 0
```

Dans l'arbre d'IX, le nœud de l'adversaire choisit l'enfant à la plus forte récompense, qui est la victoire du joueur racine. A semble donc valoir presque 1, et IX parie pour chaque graine. Le [`minimax`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/adversarial.rs#L32-L88) d'IX lui-même prend le nul. `negamax_mcts` de `search.rs` aussi : c'est la boucle d'IX avec un seul changement, le total de chaque nœud valant la récompense r quand le joueur racine y est entré, et 1 − r quand c'est l'adversaire. Le `mcts_search` d'IX convient aux problèmes à un joueur, casse-têtes et planification, où chaque choix revient à celui qui cherche. Le test d'IX lui-même joue un Nim à deux joueurs et vérifie seulement que le coup est légal.

Quand deux enfants ont le même nombre de visites, [`CONTRACTS.md` 14](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/CONTRACTS.md#L14) dit que le premier rencontré l'emporte. [`max_by_key`](https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.max_by_key) renvoie le dernier maximum ([`mcts.rs` 102-107](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/mcts.rs#L102-L107)), comme `max_by` dans les bandits de la leçon 14. P6 donne à la racine trois coups vers un nul et trois itérations, pour que chaque enfant soit visité une fois. Un journal dans `apply` enregistre l'ordre de développement :

```text
== 3 moves to a draw, 3 iterations, 20 seeds
  mcts_search returns the last expanded child 20 times, the first 0 times
```

## 6. Recherche locale

La recherche locale ne construit pas de chemin. Elle passe d'un état à un voisin meilleur, et seul compte l'endroit où elle s'arrête. Le `hill_climbing` d'IX passe au meilleur voisin tant qu'il améliore. `random_restart_hill_climbing` le répète depuis de nouveaux départs, `beam_search` garde à chaque pas les k meilleurs voisins de tout le faisceau, et `tabu_search` interdit les états récemment visités et garde le meilleur vu. [`CONTRACTS.md` 16](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/CONTRACTS.md#L16) dit que `local::hill_climb` renvoie le meilleur état vu. Le crate n'a pas de `hill_climb`, et la seule recherche qui peut finir sous son meilleur est `beam_search`. Elle remplace le faisceau par les meilleurs voisins même quand ils sont moins bons, et renvoie le meilleur du dernier faisceau ([`local.rs` 97-124](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/local.rs#L97-L124)). P7 lance chaque recherche au sommet de f(x) = −(x − 10)² :

```text
== local search on -(x - 10)^2 from x = 10
  beam_search, beam 1,   1 steps: x = 11, value -1
  beam_search, beam 1,   2 steps: x = 10, value 0
  beam_search, beam 1, 101 steps: x = 11, value -1
  hill_climbing: x = 10, value 0; tabu_search: x = 10, value 0
  random_restart_hill_climbing from 3, 0 restarts: x = 3, value -inf, 1 generator calls
  random_restart_hill_climbing from 3, 5 restarts: x = 10, value 0, 6 generator calls
```

Un faisceau de 1 quitte l'optimum au premier pas et y revient au deuxième, si bien qu'un nombre impair de pas renvoie un état moins bon que le départ. L'ascension et la recherche tabou gardent l'optimum. `random_restart_hill_climbing` génère un état avant sa boucle et le note −∞ ([`local.rs` 72-95](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/local.rs#L72-L95)). Avec 0 redémarrage, elle renvoie cet état avec la valeur −∞. Avec 5, elle appelle le générateur 6 fois et jette le premier état.

Les 8 reines sont le test classique de l'ascension. L'échiquier a une reine par colonne, un voisin déplace une reine dans sa colonne (56 voisins), et h compte les paires de reines qui s'attaquent. [Russell et Norvig](https://aima.cs.berkeley.edu/) (section 4.1.1) rapportent que l'ascension la plus raide depuis un échiquier aléatoire « gets stuck 86% of the time, solving only 14% of problem instances », « taking just 4 steps on average when it succeeds and 3 when it gets stuck ». Le `hill_climbing` d'IX est cet algorithme, sauf que les égalités vont au dernier meilleur voisin au lieu d'un voisin tiré au hasard (P8) :

```text
== 8 queens, IX's hill_climbing
  1000 random boards: solved 144 (14.4%), mean steps 4.08 when solved, 3.10 when stuck
  random_restart_hill_climbing, 20 restarts: solved 94 of 100 runs
```

IX retombe sur les nombres du manuel. Avec un taux de réussite p = 0,144 par départ, 20 départs indépendants réussissent au moins une fois avec une probabilité de 1 − 0,856²⁰ = 0,955, et 94 exécutions sur 100 ont réussi. Le contrôle croisé rejoue les mêmes échiquiers en Python, avec le même départage. Il trouve les mêmes 144 échiquiers résolus, les mêmes nombres moyens de pas et les mêmes 94 exécutions.

## 7. Les prédictions, notées

| | Prédiction, écrite avant la première exécution | Mesuré | Verdict |
|---|---|---|---|
| P1 | h(A) = 4 (admissible, pas cohérente) : `astar` renvoie 6 par S, C, G après 3 expansions ; h = 0, h = h\* et Dijkstra donnent 5 | Comme prédit | Confirmée |
| P2 | 100 labyrinthes : `astar` vaut `None` exactement là où Dijkstra ne trouve pas de chemin, sinon le même coût ; w = 1,5, 2, 5 restent sous w fois l'optimum ; w = 2 développe moins de 0,7 fois A\* | 84 accessibles, tous égaux ; 0 au-dessus de la borne ; 140,3 contre 383,7 | Confirmée |
| P3 | Cycle orienté : coût 1 et chemin [S, G], là où A\* donne 2 ; chemin 0–4 : actions (0, 1), (1, 2), (3, 2), (4, 3) | Comme prédit | Confirmée |
| P4 | 100 impasses : A\* développe 2 nœuds, `qstar_search` 102, `qstar_two_head` 2, tous au coût 2, et Q\* fait 103 appels à l'heuristique comme A\* | Comme prédit | Confirmée |
| P5 | `mcts_search` prend le pari pour 20 graines sur 20 ; `minimax` et un MCTS negamax prennent le nul | 20 sur 20 ; B avec la valeur 0 ; 20 sur 20 | Confirmée |
| P6 | Une égalité va au dernier enfant développé pour 20 graines sur 20, au premier pour aucune | 20 et 0 | Confirmée |
| P7 | `beam_search` depuis l'optimum : 11 après 1 pas, 10 après 2, 11 après 101 ; l'ascension et le tabou restent à 10 ; 0 redémarrage donne −∞, 5 redémarrages appellent le générateur 6 fois | Comme prédit | Confirmée |
| P8 | 8 reines : 10 à 18 % résolus, 3 à 5 pas en cas de réussite, 2 à 4 en cas de blocage ; 20 redémarrages résolvent 85 à 100 exécutions sur 100 | 14,4 %, 4,08, 3,10 ; 94 | Confirmée |

Les huit ont tenu à la première exécution, et le code a compilé du premier coup. Aucun intervalle n'a été modifié après coup. P1, P3, P4, P6 et P7 viennent de la lecture du code d'IX face à ses contrats et à ses commentaires, déroulé à la main. P2 et P8 viennent de résultats publiés, et IX les a rejoints. P5 vient de la règle du manuel pour les arbres à deux joueurs. Les témoins montrent que chaque vérification peut échouer. Une heuristique cohérente trouve bien 5. `astar` trouve bien le vrai coût sur le cycle. A\* et le Q\* à deux têtes sautent bien les impasses. Minimax et le MCTS negamax prennent bien le nul. L'ascension et la recherche tabou gardent bien l'optimum.

## Quoi utiliser dans nos dépôts

- **Le `astar` d'IX :** donnez-lui une heuristique cohérente. La distance de Manhattan sur une grille et la distance à vol d'oiseau sur une carte le sont. Une heuristique admissible mais pas cohérente peut renvoyer un chemin plus long.
- **Le `weighted_astar` d'IX :** w = 1,5 a déjà développé 2,6 fois moins de nœuds sur ces labyrinthes, chaque coût restant sous sa borne.
- **Le `bidirectional_astar` d'IX :** seulement sur des graphes où chaque arc se parcourt à l'envers au même coût. Lisez `path`, pas `actions`, après le point de rencontre.
- **Le `qstar_search` d'IX :** pas comme un A\* plus rapide. Avec une heuristique qui ne voit qu'un état à la fois, utilisez `astar`.
- **Le `mcts_search` d'IX :** problèmes à un joueur seulement. Pour un jeu à deux joueurs, utilisez `minimax` ou `alpha_beta`, ou un MCTS qui note chaque nœud pour son joueur.
- **Le `beam_search` d'IX :** gardez vous-même le meilleur état vu. Appelez `random_restart_hill_climbing` avec au moins un redémarrage.
- **Le `hill_climbing` d'IX :** il se comporte comme le dit le manuel. Ajoutez des redémarrages : avec 20, 94 exécutions sur 100 ont résolu les 8 reines.

## Exercices

1. Montrez qu'une heuristique cohérente avec h(but) = 0 est admissible. Vérifiez que l'heuristique de P1 est admissible mais pas cohérente.
2. Avec une heuristique cohérente, montrez que f ne décroît jamais le long d'un chemin. Déduisez-en que lorsque A\* ferme un nœud, son g est déjà optimal, si bien qu'aucune réouverture n'est nécessaire.
3. Dans le `qstar_search` d'IX, montrez qu'un enfant atteint au coût c ≤ h(parent) reçoit f = g(parent) + h(parent). Pourquoi Q\* ne peut-il pas écarter les impasses de P4 ?
4. L'ascension résout un échiquier aléatoire avec une probabilité p = 0,144. Combien de départs indépendants donnent au moins 95 % de chances d'une réussite ?

<details>
<summary>Solutions</summary>

1. Prenez un chemin optimal n = n₀, n₁, …, n_k = but. La cohérence donne h(n₀) ≤ c(n₀, n₁) + h(n₁) ≤ c(n₀, n₁) + c(n₁, n₂) + h(n₂) ≤ … ≤ le coût du chemin + h(but) = h\*(n). Pour P1 : h\*(A) = 1 + 3 = 4, donc h(A) = 4 est admissible, et les autres valeurs valent 0. Sur l'arc A→C, h(A) = 4 dépasse c(A, C) + h(C) = 1 + 0 : elle n'est pas cohérente.
2. Pour un arc n → n′, f(n′) = g(n) + c(n, n′) + h(n′) ≥ g(n) + h(n) = f(n), par cohérence, donc f ne décroît jamais le long d'un chemin. Supposez maintenant que chaque nœud fermé jusqu'ici avait son g optimal, et qu'A\* s'apprête à fermer n avec un g(n) supérieur à son optimum g\*(n). Sur un chemin optimal vers n, prenez le premier nœud m qui n'est pas fermé. Son prédécesseur sur ce chemin est fermé avec son g optimal, donc m a été empilé avec g(m) = g\*(m). Si m était n, n aurait déjà son g optimal, donc m vient avant n sur le chemin. Comme f ne décroît pas le long du chemin optimal, f(m) = g\*(m) + h(m) ≤ g\*(n) + h(n) < g(n) + h(n) = f(n). A\* aurait pris m d'abord : contradiction.
3. L'enfant reçoit g(parent) + c + max(h(parent) − c, 0), soit g(parent) + h(parent) quand c ≤ h(parent). Dans P4, A et chaque D_i ont f = g(S) + h(S) = 0 + 1 = 1. Leurs propres valeurs, 1 et 100, ne sont lues que lorsqu'ils sont développés, après avoir été choisis. Le but, atteint depuis A, reçoit f = 2, donc les 101 nœuds à f = 1 passent tous avant.
4. La probabilité que les n départs échouent tous vaut (1 − p)ⁿ, donc n doit vérifier 0,856ⁿ ≤ 0,05, c'est-à-dire n ≥ ln 0,05 / ln 0,856 = −2,996 / −0,1555 = 19,3. Vingt départs donnent 1 − 0,856²⁰ = 0,955, et la mesure a résolu 94 exécutions sur 100.

</details>

## Sources

- IX au commit épinglé `490c395` : [`astar.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/astar.rs), [`qstar.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/qstar.rs), [`mcts.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/mcts.rs), [`local.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/local.rs), [`adversarial.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/src/adversarial.rs), [`CONTRACTS.md`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-search/CONTRACTS.md), et le [`graph.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-graph/src/graph.rs) d'ix-graph.
- P. E. Hart, N. J. Nilsson et B. Raphael, [« A formal basis for the heuristic determination of minimum cost paths »](https://doi.org/10.1109/TSSC.1968.300136), IEEE Transactions on Systems Science and Cybernetics 4, 1968.
- I. Pohl, [« Heuristic search viewed as path finding in a graph »](https://doi.org/10.1016/0004-3702(70)90007-X), Artificial Intelligence 1, 1970.
- J. Chen et N. R. Sturtevant, [« Necessary and sufficient conditions for avoiding reopenings in best first suboptimal search with general bounding functions »](https://doi.org/10.1609/aaai.v35i5.16485), AAAI 35, 2021.
- C. Wilt et W. Ruml, [« When does weighted A\* fail? »](https://www.cs.unh.edu/~ruml/papers/wted-astar-socs-12.pdf), SoCS 2012.
- F. Agostinelli et al., [« A\* search without expansions: learning heuristic functions with deep Q-networks »](https://arxiv.org/abs/2102.04518), arXiv:2102.04518.
- L. Kocsis et C. Szepesvári, [« Bandit based Monte-Carlo planning »](https://doi.org/10.1007/11871842_29), ECML 2006.
- C. B. Browne et al., [« A survey of Monte Carlo tree search methods »](https://doi.org/10.1109/TCIAIG.2012.2186810), IEEE Transactions on Computational Intelligence and AI in Games 4, 2012.
- S. Russell et P. Norvig, [*Artificial Intelligence: A Modern Approach*](https://aima.cs.berkeley.edu/), section 4.1.1, recherche locale sur les 8 reines.
- SciPy : [`sparse.csgraph.shortest_path`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.sparse.csgraph.shortest_path.html). Rust : [`Iterator::max_by_key`](https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.max_by_key), [`BinaryHeap`](https://doc.rust-lang.org/std/collections/struct.BinaryHeap.html).
