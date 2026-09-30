---
title: "19. La forme des données : homologie persistante"
description: "Filtrations de Rips, diagrammes de persistance et les distances entre eux avec ix-topo d'IX, puis la graine et l'exagération précoce des deux t-SNE d'ix-manifold, avec huit prédictions écrites avant la première exécution : sept ont tenu et une a été réfutée en partie. La réduction est la réduction standard, mais la dimension du haut n'a pas de cofaces et signale 1 771 cavités dans un complexe contractile, les deux distances apparient les points par rang au lieu de chercher un appariement et violent le théorème de stabilité dans 24 nuages sur 50, et le t-SNE de Barnes–Hut ignore sa graine et, avec bhtsne 0.5.3 épinglé, rend une carte sans groupes."
sidebar:
  order: 19
---

L'homologie persistante décrit la forme d'un nuage de points par ce qui apparaît et disparaît quand on relie les points à une échelle croissante : composantes connexes, boucles, cavités. Chaque caractéristique reçoit une naissance et une mort, et un *diagramme de persistance* rassemble ces paires. [Carlsson (2009)](https://doi.org/10.1090/S0273-0979-09-01249-X) en défend l'usage comme outil d'analyse de données. Le crate épinglé [`ix-topo`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-topo) d'IX construit la filtration, calcule les diagrammes et les compare avec deux distances. Trois autres crates d'IX l'appellent, dont deux pour prendre l'empreinte des plongements de voicings de GA. La même leçon revient ensuite au t-SNE, que la [leçon 9](../09-other-reducers/) a rencontré dans `ix-unsupervised`, par la seconde implémentation d'IX, dans [`ix-manifold`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-manifold) : un `Tsne` exact et un `BarnesHutTsne` construit sur le crate [bhtsne](https://docs.rs/bhtsne/0.5.3/bhtsne/).

Les huit prédictions que teste cette leçon ont été [écrites dans le journal](../journal/#2026-09-30--leçon-19-prédite-avant-de-mesurer) et commitées avant que son code n'existe. [Les résultats](../journal/#2026-09-30--leçon-19-mesurée) les suivent. Les expériences sont dans [`topology.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/src/topology.rs), un test par prédiction, et [`l19_topology.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/examples/l19_topology.rs) affiche ce qu'elles mesurent. [`crosscheck.py`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/crosscheck/crosscheck.py) recalcule les diagrammes avec des ensembles Python, les distances exactes avec [`maximum_bipartite_matching`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.sparse.csgraph.maximum_bipartite_matching.html) et [`linear_sum_assignment`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.optimize.linear_sum_assignment.html) de SciPy, et les deux appariements d'IX une fois de plus, et trouve les mêmes nombres.

## 1. Un cercle à une échelle croissante

Le complexe de Vietoris–Rips à l'échelle r relie tout ensemble de points dont les distances deux à deux valent toutes au plus r : une arête pour deux points, un triangle pour trois, un tétraèdre pour quatre. Quand r croît, on ne fait qu'ajouter des simplexes, si bien que les complexes forment une *filtration*. `rips_complex(points, max_dim, max_radius)` la construit jusqu'à la dimension max_dim et donne à chaque simplexe son diamètre, la plus grande distance entre deux de ses sommets, comme valeur de filtration, la convention de [Ripser](https://doi.org/10.1007/s41468-021-00071-5) ([`simplex.rs` 216](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-topo/src/simplex.rs#L216)). Une composante naît en 0 et meurt quand une arête la fusionne avec une plus ancienne. Une boucle naît avec l'arête qui la ferme et meurt quand des triangles la remplissent. Une caractéristique qui ne meurt jamais dans la filtration est *essentielle*, de mort ∞.

Le cercle de la leçon compte 24 points aux angles 2πi/24 et aux rayons 1 + 0,1·(2u − 1), avec u uniforme tiré du générateur du cours :

```text
== the circle
24 points at radii 1 +- 0.1; diameter 2.1592, so every simplex is present at 2.5
```

À 2,5, le complexe est un simplexe plein sur 24 sommets, qui est contractile : une composante, aucune boucle, aucune cavité.

## 2. La réduction est la réduction standard

`compute_persistence` réduit la matrice de bord sur Z/2, colonne par colonne dans l'ordre de filtration, et apparie la ligne la plus basse de chaque colonne avec elle ([`persistence.rs` 70-163](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-topo/src/persistence.rs#L70-L163)) : l'algorithme d'[Edelsbrunner, Letscher et Zomorodian (2002)](https://doi.org/10.1007/s00454-002-2885-2) et de [Zomorodian et Carlsson (2005)](https://doi.org/10.1007/s00454-004-1146-y). Elle trouve chaque face en parcourant toute la liste des simplexes, ce qui coûte du temps, pas de la justesse, et écarte les paires dont la persistance est sous 10⁻¹⁵. La leçon écrit la même réduction avec une table de hachage des faces vers les colonnes. Elle vérifie aussi H₀ face à [Kruskal (1956)](https://doi.org/10.1090/S0002-9939-1956-0078686-7) : dans une filtration de Rips, une composante meurt à la longueur de l'arête qui la fusionne, si bien que les morts finies de H₀ sont les longueurs des arêtes d'un arbre couvrant minimal. P1 compare les trois :

```text
== P1, compute_persistence(rips_complex(points, 2, 2.5)) against a reduction written here
  H0: 23 finite pairs, 1 essential; equal to the reduction's: yes; deaths are Kruskal's tree, bit for bit: yes
  H1 pairs: 1, equal to the reduction's: yes
  persistence above 0.5: born 0.3153 (longest gap between neighbours 0.3153), dies 1.7007
  no other H1 pair
```

Chaque paire concorde, bit à bit. L'unique boucle du cercle naît quand l'anneau se ferme, au plus long des 24 écarts entre voisins, et meurt à 1,7007. Pour des points régulièrement espacés sur un cercle de rayon 1, elle mourrait près de √3 = 1,732, le côté du triangle équilatéral inscrit, là où le complexe cesse d'être un cercle ([Adamaszek et Adams 2017](https://arxiv.org/abs/1503.03669)). Toutes les autres paires de H₁ ont une persistance nulle et ont été écartées. La vérification croisée trouve la même boucle avec des ensembles Python et les mêmes morts de H₀ avec [`minimum_spanning_tree`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.sparse.csgraph.minimum_spanning_tree.html) de SciPy.

## 3. La dimension du haut n'a pas de cofaces

Une boucle ne peut être remplie que par des triangles, et une cavité que par des tétraèdres. `persistence_from_points(points, max_dim, max_radius)` construit `rips_complex(points, max_dim, max_radius)` et rend les diagrammes jusqu'à max_dim, que son commentaire de documentation décrit comme « maximum homology dimension (1 = loops, 2 = voids) » ([`pointcloud.rs` 30-44](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-topo/src/pointcloud.rs#L30-L44)). Mais un complexe construit jusqu'à la dimension max_dim n'a aucun simplexe de dimension max_dim + 1, donc rien ne peut tuer un cycle de la dimension du haut : chacun d'eux est signalé comme essentiel. `betti_at_radius` et `betti_curve` ([`pointcloud.rs` 46-89](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-topo/src/pointcloud.rs#L46-L89)) comptent le nombre de Betti du haut de la même façon, par `betti_numbers`, où la dimension du haut n'a aucun bord à soustraire ([`simplex.rs` 142-199](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-topo/src/simplex.rs#L142-L199)). P2 demande les diagrammes du cercle à 2,5, où la réponse est (1, 0, 0), et ceux des quatre coins du carré unité à 1,5, au-dessus de la diagonale √2 :

```text
== P2, the top dimension without cofaces, the circle at max_radius 2.5
  persistence_from_points(points, 1, ..): H1 253 pairs, 253 essential   (C(24, 2) - 24 + 1 = 253)
  persistence_from_points(points, 2, ..): H1 right: yes, 0 essential; H2 1771 pairs, 1771 essential   (C(23, 3) = 1771)
  H2 from the reduction written here, up to tetrahedra: 2 pairs, 0 essential
  the unit square's corners at radius 1.5: betti_at_radius [1, 3] with max_dim 1, [1, 0, 1] with max_dim 2; up to tetrahedra [1, 0, 0]
```

Avec max_dim = 1, le complexe est le graphe complet sur 24 sommets, et chacun de ses 253 cycles indépendants est signalé comme une boucle qui ne meurt jamais. Avec max_dim = 2, H₁ est juste, mais H₂ compte maintenant 1 771 cavités essentielles, une par 2-cycle indépendant du 2-squelette plein. Construite une dimension plus haut, la réduction de la leçon trouve 2 paires finies de H₂ et aucune essentielle. Le carré le montre à petite échelle : `betti_at_radius` signale 3 boucles avec max_dim = 1 et une cavité avec max_dim = 2, là où un tétraèdre plein n'en a aucune.

Le remède est de construire une dimension plus haut que le dernier diagramme qu'on lit. Trois appelants au commit épinglé passent max_dim = 1 et lisent β₁ : `topology` dans ix-voicings, qui rend les paires essentielles de H₁ comme β₁ ([`lib.rs` 879-899](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-voicings/src/lib.rs#L879-L899)) ; l'empreinte quotidienne d'ix-embedding-diagnostics ([`main.rs` 697](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-embedding-diagnostics/src/main.rs#L697)) ; et l'outil MCP `ix_topo`, par défaut ([`handlers.rs` 2151](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-agent/src/handlers.rs#L2151)). Les 14 empreintes conservées dans [`state/quality-snapshots/embeddings/`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2/state/quality-snapshots/embeddings), du 2026-04-12 au 2026-04-25, signalent toutes β₁ = 0, et elles ont raison : à leur rayon, les 100 points de chaque instrument sont reliés par 2 à 6 arêtes, une forêt sans cycle. Le constat n'en change aucune, mais il changerait la première empreinte dont le graphe ferme un cycle.

## 4. Deux distances entre diagrammes

On compare deux diagrammes en appariant leurs points, où tout point peut aussi être apparié à la diagonale, au coût de sa distance à elle, (mort − naissance)/2 en norme L∞. La distance bottleneck est le plus petit coût maximal atteignable ; la distance de p-Wasserstein est le plus petit (Σ coûtᵖ)^(1/p) atteignable. Deux points essentiels doivent être appariés entre eux, si bien que des diagrammes qui n'en ont pas le même nombre sont infiniment éloignés. [Cohen-Steiner, Edelsbrunner et Harer (2007)](https://doi.org/10.1007/s00454-006-1276-5) définissent la première ; [Kerber, Morozov et Nigmetov (2017)](https://doi.org/10.1145/3064175) calculent les deux exactement. La leçon les calcule par dichotomie sur les coûts candidats avec un couplage biparti par chemins augmentants, et avec l'algorithme hongrois de [Kuhn (1955)](https://doi.org/10.1002/nav.3800020109), et vérifie les deux face à toutes les affectations de petits problèmes.

Le commentaire de documentation de `bottleneck_distance` donne la définition : « the infimum over all matchings of the maximum cost of any matched pair ». Le code, dont le commentaire en ligne dit « Simple approximation », complète chaque diagramme avec les projections sur la diagonale des points de l'autre, trie les deux listes par persistance et les apparie rang par rang ([`persistence.rs` 165-213](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-topo/src/persistence.rs#L165-L213)). `wasserstein_distance` écarte les points essentiels, complète la liste la plus courte avec des projections des points de la plus longue, trie les deux par *naissance* et les apparie indice par indice ([`persistence.rs` 215-255](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-topo/src/persistence.rs#L215-L255)). Aucune ne cherche parmi les appariements. P3 construit des diagrammes où cela compte :

```text
== P3, hand-made diagrams: IX, exact
  bottleneck, {(0, 2), (10, 11)} and {(10, 12), (0, 1)}: 10.0000, 1.0000
  W1, {(0, 10), (1, 2)} and {(1, 10), (0, 2)}: 16.0000, 2.0000; W2: 11.3137, 1.4142
  {(0, inf)} and an empty diagram: IX's bottleneck 0.0000, IX's W2 0.0000; exact inf
```

Dans la première paire, (0, 2) et (10, 12) ont la même persistance, si bien que le classement par persistance les apparie, au coût 10, là où (0, 2) avec (0, 1) et (10, 11) avec (10, 12) coûtent 1 chacun. Dans la deuxième, le tri par naissance met (0, 2) face à (0, 10) et (1, 2) face à (1, 10), au coût 8 chacun, là où échanger les partenaires coûte 1 chacun. Et un diagramme avec une boucle essentielle est à distance 0 d'un diagramme vide, alors qu'aucun appariement n'existe.

## 5. Toujours au-dessus, et presque toujours strictement

Les deux appariements d'IX sont admissibles, donc aucune des deux distances ne peut tomber sous la distance exacte. P4 demande combien de fois elle est au-dessus, sur 1 000 paires de diagrammes de 5 points aléatoires, chacun né uniformément sur [0, 1] avec une persistance uniforme sur [0, 1] :

```text
== P4, 1000 pairs of random 5-point diagrams
  bottleneck: IX at least the exact distance in 1000, above it by more than 1e-9 in 999; median of IX / exact 2.29
  W1: IX at least the exact distance in 1000, above it by more than 1e-9 in 982; median of IX / exact 1.64
```

IX n'est jamais en dessous et presque toujours au-dessus : sa distance bottleneck est exacte pour une paire sur 1 000, et le rapport médian vaut 2,29. La distance bottleneck exacte vaut au plus la moitié de la plus grande persistance, ici 0,5, alors qu'IX apparie les projections sur la diagonale dans l'ordre des listes. La vérification croisée recalcule les deux appariements d'IX en Python et les distances exactes avec SciPy, et compte les mêmes 1 000, 999, 1 000 et 982.

## 6. Le théorème de stabilité, et ce qui le viole

Ce qui rend les diagrammes dignes d'être comparés, c'est la stabilité : déplacer chaque point d'un nuage d'au plus δ change le diamètre de chaque simplexe d'au plus 2δ, puis la distance bottleneck entre les diagrammes d'au plus 2δ ([Cohen-Steiner et al. 2007](https://doi.org/10.1007/s00454-006-1276-5) ; [Chazal et al. 2009](https://doi.org/10.1111/j.1467-8659.2009.01516.x)). Un petit changement des données ne peut pas faire un grand changement du diagramme. P5 tire 50 nuages de 24 points uniformes dans le carré unité, déplace chaque point d'exactement δ = 0,01 dans une direction aléatoire et compare les diagrammes de H₁, construits jusqu'aux triangles pour que H₁ ait ses cofaces :

```text
== P5, stability: 50 clouds of 24 points, each point moved by 0.01, H1 from persistence_from_points(.., 2, 1.5)
  H1 pairs in a diagram: fewest 0, most 7
  exact bottleneck at most 2 delta = 0.02: 50 of 50, largest 0.0195
  IX's bottleneck above 0.02: 24 of 50, largest 0.2526
```

Le théorème tient pour la distance exacte dans 50 nuages sur 50. La distance d'IX viole la borne dans 24 d'entre eux, la pire de plus de 12 fois. L'appariement rang par rang l'explique : quand deux boucles de persistances proches échangent leurs rangs, ou qu'une boucle plus courte que 2δ apparaît ou disparaît et décale les rangs suivants, il apparie des points qui n'ont rien à voir entre eux. Un appelant qui applique un seuil à la distance d'IX pour décider si deux plongements ont la même forme mesure l'ordre des persistances autant que la forme.

## 7. Le t-SNE de Barnes–Hut ignore sa graine

Le t-SNE ([van der Maaten et Hinton 2008](https://jmlr.org/papers/v9/vandermaaten08a.html)) transforme les distances en probabilités de voisinage P, la largeur de bande de chaque ligne choisie pour que son entropie soit le logarithme de la perplexité, puis déplace des points dans le plan jusqu'à ce que leurs similarités de Student Q correspondent à P. La version de Barnes–Hut ([van der Maaten 2014](https://jmlr.org/papers/v15/vandermaaten14a.html)) approche les forces avec un arbre. `BarnesHutTsne::with_seed` stocke une graine, et `fit_transform` la jette avec `let _ = self.seed;` : bhtsne 0.5.3 tire son plongement initial de `rand::thread_rng()` ([`lib.rs` 354-392](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-manifold/src/lib.rs#L354-L392) ; [bhtsne `tsne/mod.rs` 131-136](https://docs.rs/bhtsne/0.5.3/src/bhtsne/tsne/mod.rs.html#131-136)). Le commentaire au-dessus de cette ligne le dit et prévoit « Document this in the type docs », qui disent toujours « seed 0 ». Le `Tsne` exact amorce un générateur ChaCha8 ([`lib.rs` 131-134](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-manifold/src/lib.rs#L131-L134)). P6 ajuste 150 points en 10 dimensions, trois groupes de 50 autour de 0, 10·e₁ et 10·e₂ avec le bruit normal approché du cours, et note chaque plongement par le vote des 5 plus proches voisins de chaque point dans ce plongement :

```text
== P6, seeds: 150 points in three clusters in 10 dimensions
  BarnesHutTsne::with_seed(7) twice: largest coordinate difference above 1e-3: yes
  both Barnes-Hut embeddings: 5-nearest-neighbour vote right for at least 95% of the points: no; below 60%, where a random embedding gives about 1/3: yes
  Tsne::with_seed(7), 300 iterations, twice: the same embedding bit for bit: yes
```

La partie sur la graine a tenu : deux exécutions de Barnes–Hut avec la graine 7 diffèrent, et deux exécutions exactes sont identiques. L'autre partie a été réfutée. La prédiction disait que les deux cartes de Barnes–Hut sépareraient les groupes ; la première exécution a obtenu 0,267 et 0,347, près du tiers que donne une carte aléatoire. Le test épingle maintenant cette mesure, sous 0,6, et garde le 0,95 de la prédiction visible dans un commentaire.

La cause est dans la recherche de largeur de bande de bhtsne 0.5.3 ([`tsne/mod.rs` 194-270](https://docs.rs/bhtsne/0.5.3/src/bhtsne/tsne/mod.rs.html#194-270)). Elle part de β = 1, où le noyau est exp(−β·d²). Quand l'entropie est trop basse, β doit descendre, et faute de borne inférieure connue, le code lui donne la valeur d'une constante nommée `zero_point_five`, qui vaut 5,0. β monte au contraire, l'entropie baisse encore, et après 200 pas chaque ligne met presque tout son poids sur son plus proche voisin. La recherche ne marche que si β = 1 donne déjà une entropie trop haute, ce qui demande de petites distances. Ici les distances au carré à l'intérieur d'un groupe valent environ 20, et le bon β est bien sous 1. bhtsne 0.6.0 ajoute un test de non-régression dont le commentaire décrit exactement cela ([`src/test.rs` 845-853](https://docs.rs/crate/bhtsne/0.6.0/source/src/test.rs)) : « releases 0.5.3-0.5.4 moved beta upwards instead (a constant named `zero_point_five` was set to 5.0), making the search diverge and the conditional distribution degenerate ». L'espace de travail d'IX épingle `bhtsne = "=0.5.3"` ([`Cargo.toml` 108](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/Cargo.toml#L108)). Son propre test qui vérifie que Barnes–Hut sépare deux groupes tire un bruit d'écart type 0,1, où les distances au carré à l'intérieur d'un groupe valent environ 0,16, β = 1 est déjà trop petit, et la recherche va dans le bon sens ([`lib.rs` 548-582](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-manifold/src/lib.rs#L548-L582)). Une vérification exploratoire, mesurée après la première exécution, multiplie les mêmes points par 0,3 :

```text
== exploratory
  Barnes-Hut on the same points scaled by 0.3, twice: vote at least 95% in both runs: yes
```

Les mêmes données, rétrécies, sont parfaitement séparées. Le t-SNE est censé être invariant à cette échelle, puisque la recherche de largeur de bande l'absorbe ; celui-ci ne l'est pas. Le binaire `tsne-voicings` utilise Barnes–Hut par défaut, et le commentaire de documentation de son enum note qu'il n'est pas déterministe à graine fixée, mais il écrit `"seed": 42` dans sa sortie ([`tsne_voicings.rs` 53-92](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-voicings/src/bin/tsne_voicings.rs#L53-L92)). On n'a pas mesuré si les plongements de voicings de GA sont à une échelle où la recherche diverge ; le journal le liste à vérifier.

## 8. Une exagération précoce qui ne finit jamais

L'exagération précoce multiplie P par 12 au début, pour que les groupes se forment et s'écartent avant le placement fin. La documentation du module dit que `Tsne` le fait « for the first quarter of iters » ([`lib.rs` 36-38](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-manifold/src/lib.rs#L36-L38)). Le code l'arrête après `early_exaggeration_iters`, 250 par défaut, quel que soit `n_iter` ([`lib.rs` 79](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-manifold/src/lib.rs#L79), [139-143](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-manifold/src/lib.rs#L139-L143)). Avec 250 itérations ou moins, le plongement est ajusté à 12P du début à la fin. P7 note les plongements par KL(P‖Q), face à un P de perplexité 30 que la leçon calcule avec sa propre dichotomie :

```text
== P7, early exaggeration, the same points, seed 7, KL(P||Q) against P at perplexity 30
  200 iterations, default: the same as with_early_exaggeration(12.0, 200), bit for bit: yes
  KL after 200 iterations: default 1.452, exaggeration for the first 50 0.246
```

Avec 200 itérations, le défaut est l'exécution exagérée, bit à bit, et sa KL vaut 1,452, environ six fois celle du quart documenté, 0,246. Une deuxième vérification exploratoire lance les 1 000 itérations par défaut, avec l'exagération pendant les 250 premières :

```text
  the default 1000 iterations, exaggeration for the first 250: KL 0.241
```

50 itérations exagérées sur 200 arrivent à 0,005 près des 1 000 par défaut. Un appelant qui raccourcit `n_iter` pour gagner du temps, comme l'a fait la leçon, obtient une carte ajustée à la mauvaise cible, sauf s'il raccourcit aussi `early_exaggeration_iters`.

## 9. L'import de la skill, et les caractéristiques laissées de côté

La page de la skill `ix-topo` montre `use ix_topo::simplicial::{rips_complex, SimplexStream};` ([`SKILL.md` 28](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/.claude/skills/ix-topo/SKILL.md?plain=1#L28)). Le crate n'a pas de module `simplicial` ; ses modules sont `error`, `persistence`, `pointcloud` et `simplex` ([`lib.rs` 6-9](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-topo/src/lib.rs#L6-L9)). P8 garde cette ligne comme doctest `compile_fail`, qui échoue avec E0432, import non résolu, et la même ligne avec `simplex` comme doctest qui compile.

Une dernière vérification exploratoire coupe la filtration du cercle à 1,0, avant la mort de sa boucle, si bien que la boucle y est essentielle. `most_persistent_features` ne garde que les paires finies ([`pointcloud.rs` 91-111](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-topo/src/pointcloud.rs#L91-L111)) :

```text
  the circle at max_radius 1.0: essential H1 pairs 1; most_persistent_features ranks first a pair of dimension 0, persistence 0.3057
```

La caractéristique qu'elle classe première est le dernier écart à se fermer dans l'anneau, une composante qui vit 0,31. La boucle, la seule caractéristique qu'un lecteur de ce diagramme devrait voir, n'est pas du tout dans la liste, et la composante qui ne meurt jamais non plus.

## 10. Les prédictions, notées

| | Prédiction, écrite avant la première exécution | Mesuré | Verdict |
|---|---|---|---|
| P1 | H₀ et H₁ d'IX égaux à ceux d'une réduction écrite ici, bit à bit ; 23 morts finies de H₀ égales à l'arbre de Kruskal ; une paire de H₁ au-dessus de 0,5, née dans [0,25, 0,35], morte dans [1,5, 1,95] | Tout égal ; née à 0,3153, morte à 1,7007 | Confirmée |
| P2 | Cercle à 2,5 : 253 paires essentielles de H₁ avec max_dim = 1 ; H₁ juste et 1 771 paires essentielles de H₂ avec max_dim = 2 ; carré à 1,5 : [1, 3] et [1, 0, 1] | Comme prédit ; jusqu'aux tétraèdres, 2 paires finies de H₂ et [1, 0, 0] | Confirmée |
| P3 | Bottleneck 10 contre 1 ; W₁ 16 contre 2 ; W₂ 11,31 contre 1,414 ; un point essentiel contre aucun : 0 contre ∞ | 10, 1 ; 16, 2 ; 11,3137, 1,4142 ; 0, 0 et ∞ | Confirmée |
| P4 | IX au moins égal à la distance exacte pour 1 000 paires sur 1 000 pour les deux, au-dessus de plus de 10⁻⁹ pour au moins 900 | 1 000 et 999 pour le bottleneck, 1 000 et 982 pour W₁ | Confirmée |
| P5 | Bottleneck exact au plus 0,02 dans 50 nuages sur 50 ; celui d'IX au-dessus de 0,02 dans au moins 5 | 50 sur 50, le plus grand 0,0195 ; 24, le plus grand 0,2526 | Confirmée |
| P6 | Deux exécutions de Barnes–Hut avec la graine 7 diffèrent de plus de 10⁻³ ; deux exécutions exactes identiques ; les deux cartes de Barnes–Hut votent juste pour au moins 95 % | Différentes, identiques ; votes 0,267 et 0,347 | Réfutée en partie |
| P7 | 200 itérations : défaut égal à l'exagération pendant les 200, bit à bit ; sa KL plus haute qu'avec l'exagération pendant les 50 premières | Égal ; 1,452 contre 0,246 | Confirmée |
| P8 | L'import de la skill échoue avec E0432 ; la même ligne avec `simplex` compile | Comme prédit | Confirmée |

Sept ont tenu à la première exécution et une a été réfutée en partie. Aucun intervalle n'a été changé après coup. La partie réfutée venait d'un trou dans la lecture, pas dans le calcul : la prédiction a lu `ix-manifold` et s'est arrêtée à l'appel à bhtsne, dont elle a supposé la recherche de largeur de bande juste. Le test épingle ce que la première exécution a mesuré, et la vérification d'échelle qui l'explique est marquée exploratoire, puisqu'elle a été choisie après avoir vu le résultat. Les contrôles montrent que les autres vérifications peuvent échouer : la distance exacte respecte bien la borne de stabilité, la réduction de la leçon construite une dimension plus haut trouve bien le bon H₂, et le `Tsne` exact est reproductible.

## Quoi utiliser dans nos dépôts

- **`compute_persistence` et `rips_complex` :** justes, et bit à bit la réduction standard. La recherche des faces parcourt toute la liste, donc gardez les complexes petits, ou cherchez les faces dans une table comme le fait la leçon.
- **`persistence_from_points`, `betti_at_radius`, `betti_curve` :** construisez une dimension plus haut que le dernier diagramme ou nombre de Betti que vous lisez, et ignorez celui du haut. Pour β₁, passez max_dim = 2 et lisez l'indice 1.
- **`bottleneck_distance` et `wasserstein_distance` :** des bornes supérieures, pas les distances que nomment leurs commentaires de documentation, et sans la stabilité qui rend les diagrammes comparables. Pour un seuil ou un test de non-régression, utilisez un appariement exact : la dichotomie et l'algorithme hongrois de la leçon tiennent en quelques dizaines de lignes, et `linear_sum_assignment` de SciPy le fait en Python. Comptez les points essentiels à part ; les distances d'IX les ignorent.
- **`most_persistent_features` :** ajoutez vous-même les paires essentielles, en tête.
- **`BarnesHutTsne` :** non reproductible, quelle que soit la graine passée, et avec bhtsne 0.5.3 épinglé sa recherche de largeur de bande diverge sauf si les distances aux plus proches voisins sont petites. Mettez les données à une échelle où elle ne diverge pas, vérifiez la carte par un vote des voisins comme le fait la leçon, ou utilisez le `Tsne` exact sous quelques milliers de points.
- **`Tsne` :** avec moins de 1 000 itérations, réglez vous-même `early_exaggeration_iters` au quart de `n_iter`.
- **La skill `ix-topo` :** importez depuis `ix_topo::simplex`.

## Exercices

1. Montrez que les morts finies de H₀ d'une filtration de Rips sont les longueurs des arêtes d'un arbre couvrant minimal.
2. Pourquoi le graphe complet sur n sommets a-t-il C(n, 2) − n + 1 cycles indépendants, et le 2-squelette plein sur n sommets C(n − 1, 3) 2-cycles indépendants ?
3. Trouvez l'appariement bottleneck exact de la première paire de diagrammes de P3, et expliquez pourquoi le classement par persistance le manque.
4. Pourquoi la distance bottleneck d'IX peut-elle violer la borne de stabilité, alors qu'elle n'est jamais sous la distance exacte, qui la respecte ?
5. Dans la recherche de bhtsne 0.5.3, que devient β quand l'entropie en β = 1 est sous ln(perplexité) ? Pourquoi multiplier les données par 0,3 aide-t-il, et que devrait faire un changement d'échelle au t-SNE ?

<details>
<summary>Solutions</summary>

1. L'algorithme de Kruskal ajoute les arêtes par longueur croissante et garde une arête quand elle relie deux composantes. Dans la filtration de Rips, les arêtes entrent aussi par longueur croissante, et une arête qui relie deux composantes est exactement une arête qui tue une classe de H₀, à sa longueur, alors qu'une arête à l'intérieur d'une composante crée plutôt une boucle. Les arêtes qui tuent sont donc l'arbre de Kruskal, avec les mêmes longueurs, les 23 morts finies de P1.
2. Un graphe connexe à V sommets et E arêtes a E − V + 1 cycles indépendants, puisqu'un arbre couvrant a V − 1 arêtes et que chaque autre arête ferme un cycle : C(n, 2) − n + 1. Dans le 2-squelette plein, H₁ = 0, donc chaque 1-cycle est un bord et les bords des C(n, 3) triangles engendrent un espace de dimension C(n, 2) − n + 1. Les 2-cycles sont le noyau de cette application : C(n, 3) − C(n, 2) + n − 1 = C(n − 1, 3). Pour n = 24, 253 et 1 771.
3. Appariez (0, 2) avec (0, 1) au coût max(0, 1) = 1, et (10, 11) avec (10, 12) au coût 1 : le bottleneck vaut 1. Il ne peut pas être plus bas, parce que (0, 2) coûte 1 face à (0, 1), 10 face à (10, 12) et 1 face à la diagonale. Le classement par persistance apparie (0, 2) avec (10, 12), tous deux de persistance 2, au coût 10, parce que la persistance ne dit rien de l'endroit où se trouve un point.
4. La borne contraint la distance exacte, et celle d'IX n'en est qu'un majorant. Une perturbation de 0,01 peut échanger les rangs de deux boucles de persistances proches situées à des endroits différents, ou ajouter une boucle de persistance sous 0,02 qui décale tous les rangs suivants, et l'appariement rang par rang apparie alors des boucles éloignées. La distance exacte apparierait chaque boucle avec sa copie déplacée, ou une nouvelle boucle minuscule avec la diagonale.
5. β = 1 est enregistré comme borne supérieure, et comme aucune borne inférieure n'est connue, β passe à 5,0, puis est multiplié par 5 à chaque pas : il croît jusqu'à épuisement des 200 pas, et chaque ligne met presque tout son poids sur son plus proche voisin. Rétrécir les données d'un facteur 0,3 divise chaque distance au carré par environ 11, si bien qu'en β = 1 l'entropie est déjà au-dessus de la cible et que la recherche va dans le bon sens. Le t-SNE devrait être invariant à cette échelle, puisque les largeurs de bande l'absorbent ; le plongement ne devrait pas changer.

</details>

## Sources

- IX au commit épinglé `490c395` : [`persistence.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-topo/src/persistence.rs), [`pointcloud.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-topo/src/pointcloud.rs), [`simplex.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-topo/src/simplex.rs), [`ix-manifold/src/lib.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-manifold/src/lib.rs), [la skill `ix-topo`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/.claude/skills/ix-topo/SKILL.md).
- bhtsne [0.5.3](https://docs.rs/bhtsne/0.5.3/bhtsne/), la version qu'épingle IX, et [le test de non-régression de la 0.6.0](https://docs.rs/crate/bhtsne/0.6.0/source/src/test.rs).
- G. Carlsson, [« Topology and data »](https://doi.org/10.1090/S0273-0979-09-01249-X), Bulletin of the AMS 46, 2009.
- H. Edelsbrunner, D. Letscher et A. Zomorodian, [« Topological persistence and simplification »](https://doi.org/10.1007/s00454-002-2885-2), Discrete & Computational Geometry 28, 2002. A. Zomorodian et G. Carlsson, [« Computing persistent homology »](https://doi.org/10.1007/s00454-004-1146-y), Discrete & Computational Geometry 33, 2005.
- D. Cohen-Steiner, H. Edelsbrunner et J. Harer, [« Stability of persistence diagrams »](https://doi.org/10.1007/s00454-006-1276-5), Discrete & Computational Geometry 37, 2007. F. Chazal, D. Cohen-Steiner, L. J. Guibas, F. Mémoli et S. Y. Oudot, [« Gromov-Hausdorff stable signatures for shapes using persistence »](https://doi.org/10.1111/j.1467-8659.2009.01516.x), Computer Graphics Forum 28, 2009.
- M. Kerber, D. Morozov et A. Nigmetov, [« Geometry helps to compare persistence diagrams »](https://doi.org/10.1145/3064175), ACM Journal of Experimental Algorithmics 22, 2017.
- U. Bauer, [« Ripser: efficient computation of Vietoris–Rips persistence barcodes »](https://doi.org/10.1007/s41468-021-00071-5), Journal of Applied and Computational Topology 5, 2021.
- M. Adamaszek et H. Adams, [« The Vietoris–Rips complexes of a circle »](https://arxiv.org/abs/1503.03669), Pacific Journal of Mathematics 290, 2017.
- H. W. Kuhn, [« The Hungarian method for the assignment problem »](https://doi.org/10.1002/nav.3800020109), Naval Research Logistics Quarterly 2, 1955. J. B. Kruskal, [« On the shortest spanning subtree of a graph and the traveling salesman problem »](https://doi.org/10.1090/S0002-9939-1956-0078686-7), Proceedings of the AMS 7, 1956.
- L. van der Maaten et G. Hinton, [« Visualizing data using t-SNE »](https://jmlr.org/papers/v9/vandermaaten08a.html), JMLR 9, 2008. L. van der Maaten, [« Accelerating t-SNE using tree-based algorithms »](https://jmlr.org/papers/v15/vandermaaten14a.html), JMLR 15, 2014.
- SciPy : [`maximum_bipartite_matching`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.sparse.csgraph.maximum_bipartite_matching.html), [`linear_sum_assignment`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.optimize.linear_sum_assignment.html), [`minimum_spanning_tree`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.sparse.csgraph.minimum_spanning_tree.html).
