---
title: "15. Limites et suite : indécidabilité, dépliages, réduction d'ordre partiel, extensions"
description: Mesurer où s'arrête cet analyseur et pourquoi, ajouter la seule extension qui lève une limite, et regarder l'arbre de couverture donner une réponse fausse plutôt qu'une réponse lente.
sidebar:
  order: 15
---

Quatorze leçons ont construit un analyseur puis l'ont vérifié — contre lui-même, contre les fichiers d'un autre outil, contre les réponses publiées d'un concours, contre TLC. Celle-ci demande ce qu'il ne sait pas faire, et répond avec des nombres plutôt qu'avec un haussement d'épaules.

Il y a ici trois sortes de limites, et ce ne sont pas la même chose. L'une est celle de cet analyseur (la force brute sur les sous-ensembles, un plafond à vingt places). L'une est celle de la machine (la leçon 12 l'a mesurée : 1,216 milliard d'arcs). L'une appartient au formalisme, et aucun travail d'ingénierie ne la déplace.

## Lancer l'expérience

```bash
dotnet run --project code/petri-nets/Examples -c Release -- l15
dotnet test code/petri-nets/Tests -c Release --filter InhibitorTests
```

Tout le bloc ci-dessous est dans [`expected/l15.txt`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/expected/l15.txt), comparé ligne à ligne par `check.sh`. L'extension par arcs inhibiteurs est [`Inhibitor.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Inhibitor.cs) et les deux réseaux sur lesquels elle est démontrée sont dans [`InhibitorNets.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/Examples/InhibitorNets.cs).

## À quelle vitesse croît l'espace d'états

```
  family                     n   markings        arcs  arcs/marking
  philosophers               2          3           4           1.3
  philosophers               3          4           6           1.5
  philosophers               4          7          16           2.3
  philosophers               5         11          30           2.7
  philosophers               6         18          60           3.3
  philosophers               7         29         112           3.9
  philosophers-one-fork      2          6           8           1.3
  philosophers-one-fork      3         14          27           1.9
  philosophers-one-fork      4         34          88           2.6
  philosophers-one-fork      5         82         265           3.2
  philosophers-one-fork      6        198         768           3.9
  kanban                     1        160         616           3.9
  kanban                     2       4600       28120           6.1
  kanban                     3      58400      446400           7.6
```

Deux choses dans ce tableau comptent plus que la croissance elle-même.

La première est la **dernière colonne**. La leçon 12 a trouvé que le mur mémoire porte sur les arcs et non sur les marquages — `Dekker-PT-020` a 11,5 millions de marquages et 1,216 milliard d'arcs et meurt sur un tas de 8 Gio, tandis que `Peterson-PT-3` a 3,4 millions de marquages et 13,6 millions d'arcs et passe. Ici le rapport grimpe à chaque composant ajouté : 1,3 → 3,9 pour les philosophes, 3,9 → 7,6 pour Kanban. Chaque nouveau philosophe n'ajoute pas seulement ses propres états ; il multiplie les façons de quitter chaque état existant.

La seconde est la **différence entre les deux familles de philosophes**. Prendre les deux fourchettes d'un coup donne 29 marquages à sept philosophes. Les prendre une par une en donne 198 à six. Le formalisme n'a pas changé et la machine non plus : ce qui a grandi, c'est le nombre d'entrelacements que le modèle est obligé de distinguer, et c'est exactement ce que la réduction d'ordre partiel et les dépliages existent pour effacer.

## Ce que coûte la structure, en comparaison

```
  net                       places  invariants  siphons   traps
  philosophers-3                 9           6        6       6
  philosophers-4                12           8        8       8
  philosophers-5                15          10       10      10
```

Les invariants sont une élimination de Farkas sur une matrice : ils continuent de répondre pendant que l'espace d'états se multiplie. Les siphons et les trappes sont la force brute de la leçon 7, qui énumère les sous-ensembles de places, et l'analyseur la plafonne à vingt. Six philosophes prenant une fourchette à la fois ont vingt-quatre places, donc le verdict structurel ne peut pas être calculé pour le plus gros réseau du tableau de la leçon 7 elle-même — une limite de ce code, pas de la théorie. Trouver un siphon minimal est NP-difficile, ce qui est une raison honnête d'être lent et n'est aucune raison d'être plafonné à vingt : une formulation pour solveur de contraintes irait beaucoup plus loin, au prix de rendre le cours dépendant d'un solveur.

## Le mur que l'ingénierie ne déplace pas

Trois faits, aucun mesurable ici, tous décidés :

**L'accessibilité est décidable.** Étant donné un réseau et un marquage, il existe un algorithme qui dit si le marquage est accessible. Ce n'est pas évident et il a fallu vingt ans pour le régler.

**Elle est Ackermann-complète.** Pas exponentielle — *ackermannienne*, une fonction qui dépasse toute fonction primitive récursive. [Leroux (2021)](https://arxiv.org/abs/2104.12695) a prouvé que la borne inférieure n'est pas primitive récursive ; [Czerwiński et Orlikowski (2021)](https://arxiv.org/abs/2104.13866) l'ont fixée à Ackermann-complète. Aucune implémentation n'enlève cela, et les instances de la leçon 12 qui ont répondu en quelques secondes l'ont fait parce qu'elles étaient petites, pas parce que le problème est facile.

**La bornitude est décidable, et c'est pourquoi la leçon 3 fonctionne.** [Karp et Miller (1969)](https://doi.org/10.1016/S0022-0000(69)80011-5) ont donné l'arbre de couverture, qui termine sur tout réseau en remplaçant par ω une place qui a grandi. `CoverabilityTree.Build` est cet algorithme, et la leçon 12 a mesuré ce que coûte son absence de fusion : sur `kanban-1`, un réseau à **160 marquages accessibles**, il a épuisé la mémoire.

**Certaines questions sont carrément indécidables.** Savoir si deux réseaux ont le même ensemble d'accessibilité en est une ; [Araki et Kasami (1976)](https://doi.org/10.1016/0304-3975(76)90067-0) en rassemblent plusieurs. Cela vaut d'être tenu à côté de la leçon 13 : TLC répondra à tout invariant qu'on sait écrire sur un espace d'états fini, et la question *ces deux modèles sont-ils le même* n'a d'algorithme dans aucun des deux formalismes.

## L'extension qui lève la limite, et ce qu'elle coûte

Un réseau de Petri ne sait pas tester une place à zéro. Une transition se franchit quand ses places d'entrée en portent *assez* ; il n'y a pas d'arc qui veuille dire *et cette place est vide*. C'est pourquoi `handshake` ne peut pas détecter qu'il est bloqué, et pourquoi la solidité de la leçon 10 a dû être définie par un court-circuit plutôt que par « les places de travail sont vides ».

Ajoutez un type d'arc et la limite disparaît :

```csharp
public sealed record InhibitorArc(string Place, string Transition);
```

`InhibitorNet.IsEnabled` est la règle ordinaire plus une ligne : chaque place inhibitrice doit ne rien porter.

Voici ce que cela achète. `flush(n)` déplace *n* jetons de `a` vers `b` un par un, et `finish` est inhibé par `a` :

```
  flush(n)       with the zero test     without it
  flush-1                         3              4
  flush-2                         4              6
  flush-4                         6             10
  flush-8                        10             18
```

Avec l'arc inhibiteur, `finish` se franchit exactement une fois, après le dernier `move` : *n* + 2 marquages. Enlevez-le et `finish` peut se franchir à tout moment, ce qui fait 2(*n* + 1) marquages et un modèle qui ne dit plus ce pour quoi il a été écrit. Les marquages en plus ne sont pas de la complexité — ce sont des réponses fausses.

Et voici ce que cela coûte. `self-inhibited` est le plus petit réseau qu'on puisse bâtir avec un tel arc : une place, une transition, et un arc de la place vers la transition qui l'a produite.

```
  self-inhibited: one place, one transition, one inhibitor arc.
    as an ordinary net, the coverability tree says bounded = False, p <= omega
    with the inhibitor arc, the reachable set is 2 markings, p <= 1, complete = True
```

**L'arbre de couverture n'est pas lent ici. Il est faux.** L'accélération de Karp et Miller repose sur un argument qu'un arc inhibiteur casse : si un marquage couvre strictement l'un de ses ancêtres, la séquence de franchissements entre les deux peut être répétée indéfiniment, donc les places qui ont grandi peuvent grandir sans borne. Avec un arc inhibiteur, le jeton qui est apparu est exactement ce qui bloque maintenant la transition qui l'a produit. La séquence ne peut pas être répétée, et ω est un mensonge.

Ce n'est pas un défaut à corriger. Le test à zéro transforme deux places en compteurs d'une machine à deux compteurs, donc un réseau à arcs inhibiteurs simule une machine de Turing, et la bornitude, l'accessibilité et la vivacité deviennent toutes indécidables. `InhibitorNet` est donc livré avec un constructeur d'ensemble accessible qui prend une limite et **aucune contrepartie de couverture** : quand sa recherche est incomplète, la réponse est « pas dans la limite », jamais « non borné ». Tout le reste de ce dépôt est un réseau ordinaire exprès.

## Ce qui aiderait vraiment, et qui n'est pas là

Trois techniques attaquent le tableau du haut de cette leçon, et aucune n'est implémentée.

**Les dépliages.** Au lieu d'énumérer des marquages, on construit un ordre partiel d'événements — un réseau qui enregistre ce qui s'est passé, en laissant la concurrence non ordonnée plutôt qu'entrelacée. [McMillan (1993)](https://doi.org/10.1007/3-540-56496-9_14) a montré comment s'arrêter : un événement de *coupure* est un événement dont le résultat est déjà représenté, et le préfixe fini complet qui reste peut être exponentiellement plus petit que le graphe d'accessibilité pour les systèmes concurrents. [Esparza, Römer et Vogler (1996)](https://doi.org/10.1007/3-540-61042-1_40) ont corrigé l'ordre adéquat qui rend ce préfixe minimal. Les deux familles de philosophes ci-dessus sont précisément la forme que cela attaque : la différence entre 29 et 198 est de l'entrelacement, et un dépliage ne le paie pas.

**La réduction d'ordre partiel.** On continue d'énumérer des marquages, mais à chacun on ne franchit qu'un sous-ensemble des transitions franchissables — choisi de sorte que toute propriété d'intérêt soit préservée. Les ensembles obstinés de Valmari et les constructions d'ensembles amples en sont les formulations usuelles. Moins cher à greffer sur un explorateur existant qu'un dépliage, et bien plus difficile à faire juste : la condition sur le sous-ensemble est là où vit la correction, et une mauvaise perd des états en silence, ce qui est le même mode de panne qu'une contrainte d'état à la leçon 13.

**Les diagrammes de décision.** La leçon 12 a mesuré celui-là de l'extérieur. `tedd` répond à `Dekker-PT-020` en 2,3 s et 1209 Mo là où cet analyseur meurt après 158,3 s sur 8 Gio, parce qu'un diagramme de décision stocke un *ensemble* de marquages symboliquement et ne stocke jamais d'arc du tout. Les 1,216 milliard d'arcs qui ont tué la recherche explicite n'existent tout simplement pas dans cette représentation.

*À vérifier.* Aucune des trois n'a été implémentée ni mesurée ici. L'affirmation qu'un dépliage est exponentiellement plus petit pour la famille des philosophes est le résultat publié, pas une observation de ce dépôt, et la version honnête est : l'entrelacement est visible dans le tableau, et la technique qui l'enlève n'a pas été exécutée.

## Où le cours lui-même s'arrête

- **Pas de logique temporelle.** La leçon 13 a confié à TLC l'espace d'états et aucune ligne `PROPERTY` ; `[]<>Enabled(t) => []<>t` sous équité est ce que demande vraiment la question de famine de la leçon 7, et ni cet analyseur ni aucun module d'ici n'y répond.
- **Pas de temps déterministe.** La leçon 9 a ajouté des taux stochastiques et obtenu une chaîne de Markov. Un intervalle de Merlin `[a, b]` demande une construction par classes d'états qui n'est pas là ; [TINA](https://projects.laas.fr/tina/) la fait.
- **Pas de tuples colorés.** Les réseaux colorés de la leçon 8 lient une variable par transition. Une transition qui joint deux messages a besoin d'un tuple et le dépliage croît comme un produit ; les modèles du concours de la leçon 12 ont contourné cela en livrant tout déjà déplié.
- **Pas de réseaux continus ni hybrides**, où un marquage est un réel et le franchissement un débit. C'est un autre formalisme avec une autre théorie, et rien de ce qui précède ne s'y transfère.
- **Le plafond des siphons.** Vingt places, pour la raison donnée plus haut.

## À retenir

- Le coût de l'énumération est dans les arcs, et les arcs par marquage grimpent à chaque composant ajouté : 1,3 → 3,9 sur six philosophes, 3,9 → 7,6 sur trois cartes Kanban.
- Prendre une fourchette à la fois au lieu de deux coûte 198 marquages là où la prise atomique en coûte 29. Cette différence est de l'entrelacement, et c'est ce que les dépliages et la réduction d'ordre partiel existent pour enlever.
- L'analyse structurelle continue de répondre pendant que l'espace d'états se multiplie, parce que les invariants sont un calcul matriciel. Le plafond de vingt places sur les siphons est celui de l'analyseur, pas celui de la théorie.
- L'accessibilité est décidable et Ackermann-complète. Aucune implémentation ne déplace cela, et l'égalité de deux ensembles d'accessibilité est carrément indécidable.
- Un arc inhibiteur achète le test à zéro — et rend le formalisme Turing-complet, moment où l'arbre de couverture cesse d'être une approximation et devient faux : il répond ω pour un réseau dont la place ne porte jamais deux jetons.
- Chaque réseau de ce dépôt est un réseau place/transition ordinaire pour cette raison, et la seule exception est dans le cours pour être mesurée une fois puis rangée.

## Exercices

1. Lancez `l15` et prolongez la ligne Kanban à quatre cartes. Avant de le lancer, prédisez les arcs par marquage à partir des trois lignes déjà là. La prédiction est-elle proche, et dans quel sens se trompe-t-elle ?
2. `flush(n)` a *n* + 2 marquages avec le test à zéro et 2(*n* + 1) sans. Écrivez la phrase que l'arc inhibiteur fait dire au réseau, et celle que le réseau ordinaire dit à la place. Laquelle des deux est une spécification qu'on pourrait donner à un programmeur ?
3. Construisez un réseau à arcs inhibiteurs avec deux places `x` et `y` et des transitions qui décrémentent `x` en incrémentant `y`, plus une transition franchissable seulement quand `x` est vide. Vous avez bâti la moitié d'une machine à deux compteurs. Que faudrait-il ajouter pour l'autre moitié, et pourquoi cela rend-il la bornitude indécidable ?
4. `CoverabilityTree.Build(InhibitorNets.SelfInhibited().Net)` répond ω. Trouvez l'étape de la construction de Karp et Miller qui n'est pas valide ici, et énoncez l'hypothèse qu'elle fait, en une phrase.

<details>
<summary>Corrigés</summary>

1. Les trois rapports sont 3,9, 6,1 et 7,6, donc les incréments sont +2,2 et +1,5 et une extrapolation linéaire donne environ **8,9**. Mesuré, quatre cartes donnent **454 475 marquages, 3 979 850 arcs, rapport 8,8** — l'extrapolation dépasse, et elle continuera de dépasser. Le rapport est le degré sortant moyen d'un marquage, borné par le nombre de transitions, et `Nets.Kanban` en a seize quel que soit le nombre de cartes ; la courbe doit s'aplatir. Là où le coût continue de composer, c'est sur les marquages : 160 → 4 600 → 58 400 → 454 475, un facteur d'environ huit par carte sans plafond en vue.

2. Avec l'arc : *quand chaque article a été déplacé, terminer.* Sans : *à un moment, terminer, et par ailleurs les articles se déplacent.* La première est une spécification — elle nomme la condition. La seconde est la description de deux choses qui arrivent, et un programmeur à qui on la donne aurait raison de demander « avant ou après ? » et n'obtiendrait aucune réponse du modèle. C'est exactement l'écart que la leçon 10 a dû combler avec un court-circuit faute de test à zéro.

3. Il faut un second compteur et la capacité de brancher sur la nullité de l'un ou de l'autre : une machine à deux compteurs, ce sont deux compteurs, l'incrément, le décrément, et un saut conditionnel sur zéro pour chacun. `x` et `y` sont les compteurs, les arcs sont les incréments et décréments, et l'arc inhibiteur est le saut. Le résultat de Minsky est que deux compteurs suffisent à simuler une machine de Turing ; donc « ce réseau met-il jamais plus de *k* jetons dans une place » devient « cette machine atteint-elle jamais cette configuration », c'est-à-dire le problème de l'arrêt. Il n'y a pas d'algorithme, donc aucun arbre de couverture ne peut exister — pas un lent, aucun.

4. L'étape non valide est l'accélération par ω : quand un nouveau marquage *M′* couvre strictement un ancêtre *M* sur son propre chemin, chaque place où *M′ > M* est mise à ω. L'hypothèse est que **la séquence de franchissements menant de *M* à *M′* peut être refranchie depuis *M′***, donc que ces places peuvent être pompées arbitrairement haut. Dans `self-inhibited` la séquence est l'unique transition `grow`, et la franchir met un jeton dans `p` — ce qui est précisément ce qui inhibe `grow`. La séquence ne peut pas être répétée une fois, et encore moins arbitrairement souvent.

</details>

## Sources

- Jérôme Leroux, *The Reachability Problem for Petri Nets is Not Primitive Recursive*, [arXiv:2104.12695](https://arxiv.org/abs/2104.12695), 2021. La borne inférieure.
- Wojciech Czerwiński et Łukasz Orlikowski, *Reachability in Vector Addition Systems is Ackermann-complete*, [arXiv:2104.13866](https://arxiv.org/abs/2104.13866), 2021. La borne supérieure correspondante, et la raison pour laquelle cette leçon dit Ackermann plutôt que « très dur ».
- Richard Karp et Raymond Miller, *Parallel program schemata*, **Journal of Computer and System Sciences** 3(2), 1969, [doi:10.1016/S0022-0000(69)80011-5](https://doi.org/10.1016/S0022-0000(69)80011-5). L'arbre de couverture qu'implémente `CoverabilityTree.cs`. La notice est confirmée par Crossref ; l'article est derrière un péage et je ne l'ai pas lu, et tout ce que ce cours dit de la construction est soit dérivé en leçon 3, soit mesuré. *À vérifier.*
- Toshiro Araki et Tadao Kasami, *Some decision problems related to the reachability problem for Petri nets*, **Theoretical Computer Science** 2(1), 1976, [doi:10.1016/0304-3975(76)90067-0](https://doi.org/10.1016/0304-3975(76)90067-0). Même réserve. *À vérifier.*
- Kenneth McMillan, *Using unfoldings to avoid the state explosion problem in the verification of asynchronous circuits*, **CAV '92**, LNCS 663, [doi:10.1007/3-540-56496-9_14](https://doi.org/10.1007/3-540-56496-9_14), et Javier Esparza, Stefan Römer et Walter Vogler, *An improvement of McMillan's unfolding algorithm*, **TACAS '96**, LNCS 1055, [doi:10.1007/3-540-61042-1_40](https://doi.org/10.1007/3-540-61042-1_40). Aucun des deux algorithmes n'est implémenté ici. *À vérifier.*
- Tadao Murata, *Petri nets: Properties, analysis and applications*, **Proceedings of the IEEE** 77(4), 1989, [doi:10.1109/5.24143](https://doi.org/10.1109/5.24143). La section IV-A est la présentation de l'arbre de couverture que ce cours a suivie, et la section VI liste les extensions.
- [TINA](https://projects.laas.fr/tina/), nommé pour la construction par classes d'états que cet analyseur n'a pas.
- Les chiffres du concours de la leçon 12, pour `tedd` : résultats du [Model Checking Contest](https://mcc.lip6.fr/).
