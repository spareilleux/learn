---
title: "11. Compter sans compter : filtres de Bloom, HyperLogLog, count-min, coucou"
description: "Quatre structures qui répondent à des questions d'appartenance, de cardinalité et de fréquence dans une mémoire fixée d'avance, mesurées dans ix-probabilistic d'IX contre sept prédictions écrites avant la première exécution : les sept ont tenu, et deux d'entre elles révèlent une borne documentée fausse et un filtre coucou qui perd un élément."
sidebar:
  order: 11
---

Un ensemble haché répond exactement à « ai-je déjà vu ceci ? », et il grandit avec chaque élément. Les quatre structures de la crate [`ix-probabilistic`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-probabilistic) épinglée d'IX répondent à cette question et à deux autres dans une mémoire fixée d'avance. Le prix est une erreur connue et bornée. Cette leçon mesure cette erreur face aux formules qui la promettent.

Les sept prédictions que teste cette leçon ont été [écrites dans le journal](../journal/#2026-09-29--leçon-11-prédite-avant-de-mesurer) et commitées avant qu'aucune ligne de son code n'existe. [Les résultats](../journal/#2026-09-29--leçon-11-mesurée) les suivent. Les expériences sont dans [`sketch.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/src/sketch.rs), avec un test par prédiction. [`l11_sketches.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/examples/l11_sketches.rs) affiche ce qu'elles mesurent. [`crosscheck.py`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/crosscheck/crosscheck.py) recalcule les formules en Python et rejoue avec numpy le HyperLogLog écrit à la main.

| Question | Structure | Type d'IX | Erreur admise |
|---|---|---|---|
| Cet élément est-il dans l'ensemble ? | Filtre de Bloom | `bloom::BloomFilter` | Des faux positifs, jamais de faux négatifs |
| Combien d'éléments distincts ? | HyperLogLog | `hyperloglog::HyperLogLog` | Une erreur relative d'environ 1,04/√m |
| Combien de fois cet élément est-il apparu ? | Count-min sketch | `count_min::CountMinSketch` | Uniquement des surcomptes, bornés avec une probabilité donnée |
| Cet élément est-il dans l'ensemble, avec suppressions ? | Filtre coucou | `cuckoo::CuckooFilter` | Des faux positifs, et des insertions qui peuvent échouer |

Les quatre hachent avec le [`DefaultHasher`](https://doc.rust-lang.org/std/collections/hash_map/struct.DefaultHasher.html) de Rust. Il est déterministe pour une version donnée de Rust, mais, comme le dit sa documentation, pas stable d'une version à l'autre. Les éléments sont les entiers 0, 1, 2, …, si bien que chaque expérience donne le même résultat à chaque exécution.

## 1. Un filtre de Bloom et ses faux positifs

Un [filtre de Bloom](https://doi.org/10.1145/362686.362692) est un tableau de m bits et k fonctions de hachage. Insérer un élément met à 1 les k bits que désignent ses hachages. Une requête répond « peut-être » quand les k bits sont à 1, et « non » dès que l'un ne l'est pas. Un élément inséré trouve toujours ses bits à 1 : il n'y a donc pas de faux négatifs. Un élément jamais inséré peut trouver ses k bits mis à 1 par d'autres : c'est un faux positif.

Pour n éléments et un taux visé p, les bits et hachages qui minimisent le taux valent m = −n ln p / (ln 2)² et k = (m/n) ln 2. Avec des hachages aléatoires, le taux après n insertions vaut alors (1 − e^(−kn/m))^k. [`BloomFilter::new`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-probabilistic/src/bloom.rs#L31) applique les deux premières formules en arrondissant vers le haut. Le dimensionnement calculé à la main dans `sketch.rs` trouve le même m. Le nombre de hachages d'IX est lu dans la forme serde du filtre, car le champ est privé :

```text
== Bloom filter: new(10000, 0.01)
  hand sizing: m = 95851 bits, k = 7 hashes
  10000 inserted, IX m = 95851, k = 7: 0 false negatives, 1041 false positives in 100000 queries, rate 0.01041; theory 0.01004; estimated_fp_rate 0.01001
  20000 inserted, IX m = 95851, k = 7: 0 false negatives, 15616 false positives in 100000 queries, rate 0.15616; theory 0.15745; estimated_fp_rate 0.15898
```

À la capacité, 1 041 des 100 000 entiers jamais insérés passent. L'intervalle prédit, trois écarts-types autour de 0,01004, était [0,00909 ; 0,01098]. Au double de la capacité, le taux vaut 15,6 %, là encore dans son intervalle prédit. Rien ne signale que le filtre a dépassé sa capacité : `insert` ne renvoie rien, et `len()` compte les insertions sans les comparer à quoi que ce soit.

[`estimated_fp_rate`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-probabilistic/src/bloom.rs#L82-L87) élève la part de bits à 1 à la puissance k. Il suit le taux mesuré sans savoir combien d'éléments sont entrés : c'est donc le contrôle à faire sur un filtre rempli par quelqu'un d'autre. Les bits sont stockés dans un `Vec<bool>` ([`bloom.rs` 22](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-probabilistic/src/bloom.rs#L22)), un octet par bit. Ce filtre occupe donc 95 851 octets, là où un tableau compact en prendrait 11 982, comme le reconnaît le `CONTRACTS.md` de la crate.

## 2. HyperLogLog : combien d'éléments distincts

[HyperLogLog](https://dmtcs.episciences.org/3545) garde m = 2^p petits registres. Le hachage de chaque élément choisit un registre avec ses p bits de poids faible. Dans les bits restants, la position du premier 1 est son **rang** : le rang r apparaît environ une fois sur 2^r hachages distincts. Chaque registre garde le plus grand rang qu'il a vu, et l'estimation est une moyenne harmonique corrigée de son biais, α m² / Σ 2^(−registre). Les doublons ne changent rien, car un même élément tombe toujours sur le même registre avec le même rang. Sous 2,5 m, quand beaucoup de registres sont encore à zéro, l'estimateur passe au comptage linéaire, m ln(m / zéros).

Flajolet, Fusy, Gandouet et Meunier donnent une erreur type de 1,04/√m. La version écrite à la main dans `sketch.rs` implémente le même estimateur, mais hache avec splitmix64 : elle ne partage rien avec le hachage d'IX. Sur 100 ensembles disjoints de 100 000 entiers, avec p = 10 :

```text
== HyperLogLog, p = 10 (1024 registers): 100 disjoint sets of 100000 integers
  predicted standard error 1.04 / sqrt(1024) = 0.0325
  IX, DefaultHasher: RMS relative error 0.0354, mean 0.0028, worst 0.1038
  hand, splitmix64 : RMS relative error 0.0340, mean 0.0076, worst 0.1016
```

Les deux erreurs sont dans l'intervalle prédit, [0,0256 ; 0,0394]. Un millier d'octets estime 100 000 éléments distincts à environ 3,5 % près la plupart du temps, et le pire des 100 ensembles s'écarte d'environ 10 %. numpy rejoue la version écrite à la main et affiche les trois mêmes nombres.

L'erreur type est un chiffre asymptotique. Le tableau suivant n'était pas prédit : la même comparaison à d'autres cardinalités, 100 ensembles chacune.

```text
== HyperLogLog across cardinalities, p = 10, 100 sets each (not preregistered)
  n =    500: IX mean  0.0001, RMS 0.0225; hand mean -0.0011, RMS 0.0235
  n =   2000: IX mean  0.0020, RMS 0.0304; hand mean  0.0034, RMS 0.0289
  n =   2560: IX mean  0.0244, RMS 0.0402; hand mean  0.0234, RMS 0.0421
  n =   3000: IX mean  0.0118, RMS 0.0280; hand mean  0.0148, RMS 0.0289
  n =   4000: IX mean  0.0055, RMS 0.0257; hand mean  0.0052, RMS 0.0334
  n =   6000: IX mean  0.0031, RMS 0.0271; hand mean  0.0010, RMS 0.0321
  n =  10000: IX mean  0.0050, RMS 0.0296; hand mean  0.0026, RMS 0.0341
  n = 100000: IX mean  0.0028, RMS 0.0354; hand mean  0.0076, RMS 0.0340
  HyperLogLog::standard(): memory_bytes 16384, error_rate 0.0081
```

À n = 2 560 = 2,5 m, les deux implémentations surestiment de 2,3 à 2,4 % en moyenne. Avec 100 ensembles, l'erreur type d'une moyenne vaut environ 0,0033 : l'écart représente donc environ sept erreurs types. C'est un biais, pas du bruit. C'est précisément là que [`count`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-probabilistic/src/hyperloglog.rs#L83-L89) quitte le comptage linéaire pour l'estimateur brut, biaisé vers le haut à cette taille. C'est pour cette raison que [HyperLogLog++](https://research.google/pubs/hyperloglog-in-practice-algorithmic-engineering-of-a-state-of-the-art-cardinality-estimation-algorithm/) corrige l'estimation brute avec des biais mesurés. Sous la bascule, le comptage linéaire est plus précis que 1,04/√m.

La dernière ligne montre le réglage par défaut : `standard()` utilise p = 14 et 16 384 octets. La première ligne du module promet « ~1.6KB memory », ce qu'aucune précision ne donne.

## 3. Count-min : combien de fois

Un [count-min sketch](https://doi.org/10.1016/j.jalgor.2003.12.001) est une table de d lignes de w compteurs. Ajouter un élément incrémente un compteur par ligne, choisi par le hachage de cette ligne. Son estimation est le plus petit de ses d compteurs. Chaque compteur que touche un élément contient son propre compte plus ceux des éléments qui le partagent : l'estimation ne sous-compte donc jamais. La borne de Cormode et Muthukrishnan explique pourquoi le minimum fonctionne. Avec w = ⌈e/ε⌉ et d = ⌈ln(1/δ)⌉, le surcompte dépasse εN avec une probabilité d'au plus δ, où N est le compte total. Exprimée avec la largeur, la borne vaut e·N/w avec une probabilité de 1 − e^(−d). D'après l'inégalité de Markov, une ligne dépasse e fois son surcompte attendu avec une probabilité d'au plus 1/e, et d lignes indépendantes le font toutes avec une probabilité de e^(−d).

Le commentaire de [`CountMinSketch::new`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-probabilistic/src/count_min.rs#L22-L23) oublie le e : « Error <= total_count / width with probability >= 1 - (1/e)^depth ». N/w est le surcompte *attendu* d'une ligne, et une ligne dépasse son espérance environ une fois sur deux. La prédiction était que plus de e^(−3) des éléments enfreindraient la borne documentée, et moins de e^(−3) la vraie borne :

```text
== count-min sketch: new(100, 3), 10000 integers added 10 times each
  N = 100000; underestimates 0; mean overcount 911.3; max overcount 1180
  share above N/width = 1000: 0.0992 (binomial model 0.1058; the doc allows 0.0498)
  share above e N/width = 2718: 0.0000
  with_error(0.01, 0.05): width 272, depth 3
```

Un élément sur dix dépasse de plus de 1 000, deux fois ce que le commentaire permet. Le modèle binomial derrière la prédiction traite la charge de chaque ligne comme une Binomiale(9 999, 1/100) et donne 0,1058. Aucun élément n'approche 2 718. [`with_error`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-probabilistic/src/count_min.rs#L35-L39) dimensionne correctement la table, avec une largeur ⌈e/0,01⌉ = 272 et une profondeur ⌈ln 20⌉ = 3. Seul le commentaire de `new` énonce la mauvaise borne.

## 4. Filtres coucou : l'appartenance avec suppression

Un filtre de Bloom ne peut pas oublier un élément, car ses bits sont partagés. Un [filtre coucou](https://doi.org/10.1145/2674005.2674994) stocke une courte **empreinte** de chaque élément (16 bits dans IX) dans l'une de deux cases de 4 emplacements. La première case vient du hachage de l'élément. La seconde est la première combinée par XOR avec un hachage de l'empreinte, si bien que chaque case se calcule à partir de l'autre et de la seule empreinte ([`alt_index`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-probabilistic/src/cuckoo.rs#L147-L151)). Quand les deux cases sont pleines, l'insertion déloge une empreinte vers son autre case, qui peut en déloger une autre, jusqu'à 500 fois. Supprimer retire une copie de l'empreinte.

```text
== cuckoo filter: new(4096), integers 0, 1, 2, ... until an insert fails
  4096 slots; first failure inserting 3730, load factor 0.9106
  earlier integers no longer found: 1 [2498]; the failed integer found: true
  false positives on 100000 integers never inserted: 14, rate 0.00014
  a second filter on the same sequence: same failure true, contains disagreements 0
```

- **Taux de remplissage :** le premier échec survient à 91 % des emplacements, au-dessus des 0,90 prédits mais sous les 95 % que Fan, Andersen, Kaminsky et Mitzenmacher rapportent pour des cases de 4.
- **Faux positifs :** 14 sur 100 000. Une requête compare son empreinte aux 8 emplacements de deux cases pleines à 91 %, ce qui donne environ 8 × 0,91 / 65 536 ≈ 1,1 sur 10 000.
- **L'insertion ratée :** [`insert`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-probabilistic/src/cuckoo.rs#L54-L75) a placé la nouvelle empreinte dès le premier déplacement, puis a transporté une autre empreinte de case en case pendant 500 déplacements. Quand il abandonne, il renvoie false et perd l'empreinte qu'il transporte encore.
  - **Le résultat :** 3 730, l'entier « non inséré », est trouvé. 2 498, inséré avec succès, ne l'est plus. C'est un **faux négatif**, la seule erreur qu'un filtre d'appartenance est censé ne pas commettre.
  - **Par rapport à l'article :** l'algorithme 1 de Fan et al. fait la même chose en cas d'échec, et l'article ne promet l'absence de faux négatifs que « as long as bucket overflow never occurs ». L'implémentation de référence des auteurs garde plutôt l'empreinte transportée dans un cache de victime d'une entrée ([`cuckoofilter.h`](https://github.com/efficient/cuckoofilter/blob/917583d6abef692dfa8e14453bd77d6e0b61eef3/src/cuckoofilter.h#L42-L48)).
  - **Par rapport à la documentation d'IX :** le commentaire d'`insert` dit seulement « Returns false if the filter is full », et ni lui ni `CONTRACTS.md` ne mentionnent la perte.
- **Déterminisme :** le `CONTRACTS.md` de la crate dit que les victimes sont tirées avec `rand::random()` et que les exécutions ne sont pas déterministes. Fan et al. tirent bien au hasard une case et une entrée. IX part toujours de la première case et choisit l'emplacement `fingerprint % len` ([`cuckoo.rs` 60](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-probabilistic/src/cuckoo.rs#L60)), et la crate ne dépend pas de `rand`. Deux filtres alimentés par les mêmes entiers échouent sur le même et s'accordent sur les 100 000 sondes.

```text
== cuckoo filter: the same integer inserted again and again
  insert(42) ten times: [true, true, true, true, true, true, true, true, false, false]; len 8
```

Un filtre coucou ne sait pas si un élément est déjà présent. Chaque insertion stocke une copie de plus de la même empreinte, et après 8 copies, la capacité de ses deux cases, l'insertion suivante échoue. Fan et al. le disent : les filtres coucou « are not suitable for applications that insert the same item more than 2b times ». Vérifiez `contains` avant d'insérer quand l'entrée peut se répéter, et ne supprimez jamais un élément qui n'a pas été inséré : un autre élément de même empreinte dans la même case perdrait sa copie.

## 5. Les prédictions, notées

| | Prédiction, écrite avant la première exécution | Mesure | Verdict |
|---|---|---|---|
| P1 | Bloom à la capacité : taux dans [0,00909 ; 0,01098] | 0,01041 | Confirmée |
| P2 | Bloom au double de la capacité : taux dans [0,1540 ; 0,1609] | 0,15616 | Confirmée |
| P3 | HyperLogLog, p = 10 : erreur quadratique moyenne dans [0,0256 ; 0,0394], moyenne à ±0,00975, pour IX et à la main | 0,0354 et 0,0028 ; 0,0340 et 0,0076 | Confirmée |
| P4 | Count-min : plus de 0,0498 des éléments au-dessus de N/w, dans [0,07 ; 0,20] ; moins de 0,0498 au-dessus de e·N/w | 0,0992 ; 0,0000 | Confirmée |
| P5 | Coucou : premier échec à un taux de remplissage d'au moins 0,90 | 0,9106 | Confirmée |
| P6 | Coucou : après le premier échec, un élément inséré plus tôt n'est plus trouvé | 2 498 | Confirmée |
| P7 | Coucou : deux filtres alimentés par la même séquence se comportent à l'identique | Même échec, 0 divergence | Confirmée |

Les sept prédictions ont tenu dès la première exécution. P1 à P3 vérifient que les structures respectent leur théorie. P4, P6 et P7 ont été écrites pour attraper un désaccord entre la documentation d'IX et son code, repéré d'abord à la lecture : les trois en ont trouvé un. Aucune des sept n'a été ajustée après l'exécution. Le seul changement fait ensuite est le nombre d'ensembles du tableau de la section 2, qui n'était pas une prédiction, et le journal le dit.

## Quels usages dans nos dépôts ?

- **Filtre de Bloom :** dimensionnez-le pour le plus grand ensemble qu'il contiendra, car rien ne prévient quand il est plein. Lisez `estimated_fp_rate()` plutôt que de vous fier à la capacité choisie par quelqu'un d'autre.
- **HyperLogLog :** fusionnez des sketches de même précision pour compter les éléments distincts sur plusieurs sources : `merge` prend le maximum registre par registre. Attendez-vous à un biais de quelques pour cent autour de 2,5 m, et publiez la barre d'erreur, car 1,04/√m est un écart-type, pas une limite.
- **Count-min sketch :** dimensionnez-le avec `with_error`, dont la borne est juste, et lisez le commentaire de `new` comme faux d'un facteur e. Les estimations sont des majorants : utiles pour repérer les éléments lourds, pas pour compter exactement les légers.
- **Filtre coucou :** traitez un `insert` raté comme un filtre auquel on ne peut plus se fier, et reconstruisez-le plus grand, puisqu'un échec retire silencieusement un autre élément (constat 26). Dimensionnez-le bien en dessous de 91 % de remplissage, et vérifiez `contains` avant d'insérer une entrée qui peut se répéter.

## Exercices

1. Un filtre de Bloom doit contenir 1 000 000 d'éléments avec un taux de faux positifs de 0,1 %. Combien de bits et de hachages `BloomFilter::new` choisit-il, et combien d'octets le filtre d'IX occupe-t-il alors ?
2. Pourquoi un HyperLogLog ignore-t-il les doublons, et pourquoi un count-min sketch ne le peut-il pas ?
3. Dans l'expérience count-min, le surcompte moyen vaut 911, sous N/w = 1 000, et pourtant un élément sur dix dépasse 1 000. Comment les deux peuvent-ils être vrais ?
4. Proposez une modification de `CuckooFilter::insert` pour qu'une insertion ratée ne perde rien, et dites ce que `contains` doit alors regarder en plus.

<details>
<summary>Solutions</summary>

1. m = ⌈−10⁶ ln 0,001 / (ln 2)²⌉ = 14 377 588 bits et k = ⌈(m/n) ln 2⌉ = ⌈9,97⌉ = 10 hachages. Dans un `Vec<bool>`, cela fait 14 377 588 octets, environ 14,4 Mo, là où des bits compacts prendraient environ 1,8 Mo.
2. HyperLogLog garde un maximum par registre : le même élément donne le même registre et le même rang, donc l'ajouter de nouveau ne peut pas relever le maximum. Un compteur count-min est une somme : ajouter de nouveau le même élément l'augmente, ce dont un comptage de fréquences a besoin.
3. Chaque estimation est le minimum de trois compteurs. Ce minimum est en général sous la moyenne de sa ligne, environ 1 000, ce qui tire le surcompte moyen vers 911. Mais un élément dépasse 1 000 dès que ses trois compteurs le dépassent, ce qui arrive environ 0,47³ ≈ 0,1 du temps avec ces charges.
4. Garder l'empreinte encore transportée quand les déplacements sont épuisés dans un emplacement « victime » d'une entrée, comme le fait l'implémentation de référence des auteurs, et ne renvoyer false que si cet emplacement est déjà pris. `contains` et `remove` doivent alors comparer aussi avec la victime, et la prochaine insertion réussie peut tenter de la replacer.

</details>

## Sources

- IX au commit épinglé `490c395` : [`bloom.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-probabilistic/src/bloom.rs), [`hyperloglog.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-probabilistic/src/hyperloglog.rs), [`count_min.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-probabilistic/src/count_min.rs), [`cuckoo.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-probabilistic/src/cuckoo.rs) et [`CONTRACTS.md`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-probabilistic/CONTRACTS.md).
- B. H. Bloom, [« Space/time trade-offs in hash coding with allowable errors »](https://doi.org/10.1145/362686.362692), *Communications of the ACM* 13, 1970.
- P. Flajolet, É. Fusy, O. Gandouet et F. Meunier, [« HyperLogLog: the analysis of a near-optimal cardinality estimation algorithm »](https://dmtcs.episciences.org/3545), *Analysis of Algorithms* (AofA 07), DMTCS Proceedings, 2007.
- S. Heule, M. Nunkesser et A. Hall, [« HyperLogLog in practice »](https://research.google/pubs/hyperloglog-in-practice-algorithmic-engineering-of-a-state-of-the-art-cardinality-estimation-algorithm/), EDBT 2013 : le biais de l'estimateur brut aux petites cardinalités.
- G. Cormode et S. Muthukrishnan, [« An improved data stream summary: the count-min sketch and its applications »](https://doi.org/10.1016/j.jalgor.2003.12.001), *Journal of Algorithms* 55, 2005.
- B. Fan, D. G. Andersen, M. Kaminsky et M. D. Mitzenmacher, [« Cuckoo filter: practically better than Bloom »](https://doi.org/10.1145/2674005.2674994), CoNEXT 2014 ([PDF](https://www.cs.cmu.edu/~dga/papers/cuckoo-conext2014.pdf)) : algorithmes 1 à 3, 95 % de remplissage avec des cases de 4, et la limite de 2b insertions répétées. Leur implémentation de référence, [efficient/cuckoofilter](https://github.com/efficient/cuckoofilter/blob/917583d6abef692dfa8e14453bd77d6e0b61eef3/src/cuckoofilter.h), à `917583d`.
