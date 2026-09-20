---
title: 5. Invariants
description: Invariants de places et de transitions calculés par élimination de Farkas — un nombre pondéré de jetons qu'aucun tir ne peut changer, la preuve que le tampon borné ne peut pas déborder sans énumérer un seul marquage, et la liste honnête de ce qu'un invariant ne peut pas décider.
sidebar:
  order: 5
---

Code complet : [`code/petri-nets`](https://github.com/spareilleux/learn/tree/main/code/petri-nets). Cette leçon est imprimée par `dotnet run --project Examples -c Release -- l5`, comparée à [`expected/l5.txt`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/expected/l5.txt).

Les leçons 3 et 4 ont répondu à chaque question par énumération : construire le graphe d'accessibilité, regarder les douze marquages, rapporter. Cela marche jusqu'à ce que ça ne marche plus — le réseau de la leçon 3 sans son frein a une infinité de marquages, et un réseau à dix philosophes en a plus que vous ne voulez en garder en mémoire.

Cette leçon change la question. Au lieu de visiter les marquages et d'y vérifier une propriété un par un, elle regarde la matrice d'incidence et en tire un énoncé valable à *tout* marquage, accessible ou non, avant même qu'un marquage existe. La mission promettait que la leçon 5 prouverait le tampon borné à nouveau « sans regarder un seul marquage ». Voilà ce qu'est un invariant de places.

Vous en écrivez déjà. Un invariant de boucle est un énoncé qui survit à chaque itération ; un invariant d'un réseau de Petri est un énoncé qui survit à chaque tir. La différence, c'est que celui-ci, vous n'avez pas à le deviner : il sort d'une matrice.

## La ligne d'algèbre

La leçon 2 a donné l'équation d'état. Si un marquage *M* est atteint depuis *M0* en tirant chaque transition *x(t)* fois, alors

*M* = *M0* + *C x*

Prenez n'importe quel vecteur ligne *y* de la bonne longueur et multipliez les deux côtés par lui :

*y M* = *y M0* + *y C x*

Choisissez maintenant *y* tel que **y C = 0**. Le dernier terme disparaît quel que soit *x*, et il reste

*y M* = *y M0*

pour tout *M* que l'équation peut atteindre — ce qui inclut tout marquage accessible, puisque tout marquage accessible satisfait l'équation. Un tel *y* est un **invariant de places**, ou P-semi-flot quand on exige des poids positifs ou nuls. C'est un nombre pondéré de jetons qu'aucun tir ne peut changer.

Voilà toute la dérivation, et il vaut la peine de remarquer ce qu'elle n'a *pas* utilisé : aucun marquage, aucun ordre de tir, aucune sensibilisation. Les poids *y* ne dépendent que des arcs.

## Ce que le producteur et le consommateur conserve

L'analyseur les calcule à partir de *C* par **élimination de Farkas**, la méthode que décrit Murata (1989, section V-B) : partir d'une ligne par place, étiquetée par un vecteur unité ; éliminer une colonne de *C* à la fois en additionnant des paires de lignes de signes opposés dans cette colonne ; ce qui survit, ce sont les générateurs positifs ou nuls. Seuls ceux de support minimal sont conservés, de sorte que `free + full = 2` est rapporté plutôt que l'infinité de ses multiples et de ses sommes.

```
== What the producer and consumer never stops conserving ==
invariants of producer-consumer
  place invariants (3):
    ready + produced = 1
    free + full = 2
    waiting + taken = 1
  transition invariants (1):
    produce + deposit + take + consume
places: 6   rank of C: 3   dimension of the solutions of y C = 0: 3
```

Lisez les trois comme des phrases sur le système :

- `ready + produced = 1` — le producteur est dans exactement l'un de ses deux états. C'est un booléen, et l'invariant est la preuve qu'il en est un.
- `free + full = 2` — le tampon a deux emplacements, et chaque emplacement est libre ou occupé. Rien ne crée d'emplacement, rien n'en détruit.
- `waiting + taken = 1` — le consommateur, comme le producteur.

La dernière ligne du bloc est un contrôle de cohérence sur le nombre à attendre. Les solutions de *y C* = 0 forment un espace vectoriel de dimension (nombre de places) − rang(*C*) = 6 − 3 = 3, et ici les trois invariants minimaux en forment justement une base. Cette coïncidence n'est pas générale : un réseau peut avoir plus de semi-flots minimaux que la dimension de l'espace, parce que la minimalité porte sur les supports et non sur l'indépendance linéaire.

## La preuve

`free + full = 2` et rien d'autre donne la promesse de la leçon 1 :

```
== The proof that the buffer cannot overflow ==
invariant     free + full = 2
both counts are numbers of tokens, so free >= 0 and full >= 0
therefore     full <= 2 at every reachable marking, and at every marking at all
markings enumerated to get there: 0
checking it anyway on the graph of lesson 3: 12 markings, invariant holds in all: True
largest value of full among them: 2
```

Deux faits, une ligne d'arithmétique. `full` vaut au plus 2 parce que `free` ne peut pas être négatif et que les deux s'additionnent à 2. C'est une preuve sur un ensemble de marquages que personne n'a listés, et elle se lirait exactement pareil si le tampon avait une capacité d'un million.

Comparez avec ce qu'a fait la leçon 3 : douze marquages, chacun construit par tir, chacun comparé à ceux d'avant. Pour une capacité de *k*, cela fait 4·(*k*+1) marquages — la leçon 7 les met en tableau — et l'invariant tient toujours en une ligne.

Les deux dernières lignes du bloc sont le cours qui vérifie sa propre affirmation. Elles ne font pas partie de la preuve ; elles sont là parce qu'une preuve qui contredit le programme est une preuve qui a une erreur dedans.

## Chaque place, de trois façons

Le même raisonnement appliqué à chaque place donne une borne sans graphe : si un invariant *y* couvre *p*, alors *y(p)·M(p)* vaut au plus *y M0*, donc *M(p)* vaut au plus *y M0 / y(p)*. L'analyseur prend la plus petite borne de ce genre sur tous les invariants :

```
== The bound of every place, three ways ==
bounds of producer-consumer
place     invariants              coverability tree   reachability graph
ready     1                       1                   1
produced  1                       1                   1
free      2                       2                   2
full      2                       2                   2
waiting   1                       1                   1
taken     1                       1                   1
  markings enumerated: 0 for the invariants, 12 for the graph
```

Trois méthodes, les mêmes six nombres, et la colonne de gauche ne les a pas payés.

Retirez maintenant la place `free`, comme l'a fait la leçon 3, et reposez la question :

```
== The same table on the net with the brake removed ==
invariants of unbounded-producer
  place invariants (2):
    ready + produced = 1
    waiting + taken = 1
  transition invariants (1):
    produce + deposit + take + consume
bounds of unbounded-producer
place     invariants              coverability tree   reachability graph
ready     1                       1                   still growing at 500
produced  1                       1                   still growing at 500
full      not covered             unbounded           still growing at 500
waiting   1                       1                   still growing at 500
taken     1                       1                   still growing at 500
  markings enumerated: 0 for the invariants, 500 for the graph
```

L'invariant qui bornait le tampon a disparu, et la place qu'il bornait est celle qui grandit. C'est le même fait que la leçon 1 vous a dit en images — l'*absence* d'une place est ce qui rendait la file non bornée — énoncé cette fois comme l'absence d'une loi de conservation.

:::caution[Ce que « not covered » ne veut pas dire]
`not covered` dit que l'analyseur n'a trouvé aucun invariant de places donnant un poids à `full`. Cela ne dit **pas** que la place n'est pas bornée. Il existe des réseaux bornés dont aucun P-semi-flot ne sait exprimer la borne ; la bornitude structurelle est caractérisée par une autre condition (un vecteur positif *y* avec *y C* ≤ 0, et non *y C* = 0), et même celle-là parle de tout marquage initial plutôt que de celui-ci. Ici, c'est l'arbre de couverture de la leçon 3, qui est une procédure de décision, qui prouve que `full` n'est pas bornée. L'invariant a seulement échoué à prouver le contraire.
:::

## Ce qu'un invariant ne peut pas faire

Un invariant est une conséquence de l'équation d'état. Il hérite donc de la faiblesse à laquelle la leçon 2 a consacré une section : tout ce que l'équation accepte, les invariants l'acceptent aussi.

```
== An invariant cannot exclude what the state equation accepts ==
invariants of handshake
  place invariants (1):
    request + response = 0
  transition invariants (0):
spurious marking (0, 0, 1)  served:1  satisfies every place invariant: True
spurious marking (0, 0, 2)  served:2  satisfies every place invariant: True
```

Les deux marquages que le `handshake` ne peut pas atteindre satisfont parfaitement son invariant. Aucun ensemble d'invariants de places n'exclura jamais un marquage parasite, parce que les invariants de places sont strictement plus faibles que l'équation qui les a produits, et que l'équation est déjà strictement plus faible que l'accessibilité. Si la leçon 2 vous a laissé l'espoir que les invariants combleraient cet écart, non — c'est à la leçon 6 que l'écart commence à se combler, avec les siphons et les trappes.

La seconde limitation compte davantage en pratique : **les invariants prouvent la sûreté, jamais la vivacité.** Voici les quatre invariants du réseau qui s'interbloque de la leçon 4 :

```
== What invariants do not see: the deadlock of two locks ==
invariants of two-locks
  place invariants (4):
    a_idle + a_has_x = 1
    a_has_x + x = 1
    b_idle + b_has_y = 1
    b_has_y + y = 1
  transition invariants (2):
    a_take_x + a_take_y
    b_take_y + b_take_x
dead marking (0, 1, 0, 1, 0, 0)  a_has_x:1 b_has_y:1
every place invariant above holds there too: True
```

Les quatre sont vrais à l'interblocage. Ils le doivent — ils sont vrais partout, et l'interblocage est un marquage comme un autre. Un invariant peut vous dire « ce mauvais marquage est impossible » quand le marquage viole le compte ; il ne peut jamais vous dire « ce marquage accessible est mauvais », parce que la nocivité porte ici sur ce que le réseau *ne peut pas faire ensuite*, et qu'un compte conservé ne dit rien de l'avenir.

`a_has_x + x = 1` est la lecture utile de ce bloc : le verrou `x` est soit tenu par A, soit libre, jamais les deux, jamais ni l'un ni l'autre. *Cela*, cela vaut la peine d'être prouvé, et c'est exactement le genre d'énoncé auquel servent les invariants.

## Invariants de transitions

Transposez la question. Un **invariant de transitions**, ou T-semi-flot, est un vecteur d'entiers positifs ou nuls *x* avec **C x = 0** : un multiensemble de tirs dont l'effet net sur le marquage est nul.

```
== Transition invariants: the firings that cancel out ==
x = (1, 1, 1, 1)   produce + deposit + take + consume
firing it once from M0 gives (1, 0, 2, 0, 1, 0), back to (1, 0, 2, 0, 1, 0): True
```

Un aller-retour complet dans le système le laisse exactement comme il était. C'est la définition d'un cycle dans la chose modélisée — une requête servie, un message consommé, un verrou pris et relâché.

Le piège est celui que la leçon 2 a déjà enseigné à propos de l'équation d'état, dans l'autre sens : *C x* = 0 dit que l'arithmétique s'annule, pas qu'un ordre quelconque de ces tirs puisse réellement se dérouler.

```
two locks has two of them, and a marking from which neither can be fired at all:
  x = (1, 1, 0, 0)   a_take_x + a_take_y
  x = (0, 0, 1, 1)   b_take_y + b_take_x
  transitions enabled at the dead marking: (nothing)
```

Les deux T-invariants existent, tous deux décrivent un aller-retour parfaitement sensé — prendre les deux verrous, relâcher les deux verrous — et depuis l'interblocage aucun des deux ne peut démarrer.

Le cas intéressant est l'inverse :

```
the handshake has none at all, and that is a statement about its runs:
  transition invariants of handshake: 0
  transition invariants of handshake-started: 0
  a marking it can reach twice: False
  a marking the producer and consumer can reach twice: True
```

Le `handshake` n'a **aucun** invariant de transitions, et c'est un vrai énoncé sur son comportement : aucune séquence non vide de tirs ne peut ramener le réseau à un marquage où il est déjà passé, parce que chaque `receive` dépose un jeton dans `served` et que rien ne l'en retire. Un réseau sans T-invariant n'a aucun cycle du tout dans son graphe d'accessibilité. L'analyseur le vérifie directement sur le préfixe de 500 marquages de `handshake-started` : il n'a trouvé aucun marquage accessible deux fois, alors que le producteur et le consommateur en a en abondance.

Celui-là ne demande aucun théorème pour être cru. Si un réseau est réversible et peut tirer, alors une séquence non vide le ramène à *M0* ; le vecteur qui compte ces tirs est positif ou nul, non nul, et satisfait *C x* = 0. C'est donc un invariant de transitions. Retournez-le : **pas d'invariant de transitions, pas de retour**. C'est le seul fait voisin de la vivacité que cette leçon obtienne gratuitement, et la leçon 6 est d'où vient le reste.

## Points clés

- Un **invariant de places** est un vecteur *y* avec *y C* = 0. Alors *y M* = *y M0* à tout marquage que l'équation d'état peut atteindre, et donc à tout marquage accessible. C'est un invariant de boucle que vous n'avez pas à deviner.
- `free + full = 2` plus « les comptes de jetons ne sont pas négatifs » prouve que le tampon ne peut pas déborder, **avec zéro marquage énuméré**, et la preuve ne grandit pas avec la capacité.
- Les invariants de places donnent des **bornes** gratuitement : *M(p)* ≤ *y M0 / y(p)*. Une place qu'aucun invariant ne couvre est une place sans preuve, pas une place prouvée non bornée.
- Les invariants sont des **conséquences de l'équation d'état**, donc ils acceptent tout marquage parasite. Ils prouvent des propriétés de sûreté et jamais de vivacité : les quatre invariants de `two-locks` tiennent à son interblocage.
- Un **invariant de transitions** est un vecteur *x* avec *C x* = 0 : des tirs qui s'annulent. Il ne promet pas que la séquence puisse tirer. N'en avoir aucun, comme le `handshake`, prouve que le réseau ne peut jamais revenir à un marquage qu'il a quitté.
- Les deux sont calculés par **élimination de Farkas** sur *C*, dans [`Invariants.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Invariants.cs), sans rien construire.

## Exercices

1. Le réseau d'exclusion mutuelle a l'invariant `critical1 + critical2 + mutex = 1`. Écrivez, en une phrase et sans mentionner les réseaux de Petri, la propriété du programme C# que cela prouve. Puis dites quelle ligne du programme devrait changer pour que l'invariant devienne `= 2`, et ce qui casserait.
2. Le réseau lecteurs-rédacteurs de la leçon 7 a deux invariants de places. L'un d'eux est `reading + 3*writing + access = 3`. Que prouve-t-il sur le nombre de rédacteurs, et pourquoi le poids 3 apparaît-il ?
3. Un réseau modélise un workflow : il démarre avec un jeton dans `start` et devrait finir avec un jeton dans `end`. Quelqu'un affirme que « l'invariant `start + working + end = 1` prouve que le workflow se termine ». Dites précisément ce qu'il prouve et ce qu'il ne prouve pas.
4. Prenez le réseau `emit-loop` de la leçon 3 — une transition qui rend son jeton d'entrée et remplit deux places. Prédisez ses invariants de places avant de lancer l'analyseur, puis vérifiez.

<details>
<summary>Solutions</summary>

**1.** « À tout instant, au plus un fil d'exécution est dans la section critique, et le verrou est libre exactement quand aucun des deux n'y est. » La place `mutex` est l'objet verrou ; `= 1` est le fait qu'il n'y en a qu'un. Pour le rendre `= 2`, vous mettriez deux jetons dans `mutex` au départ, ce qui en code revient à remplacer `lock (gate)` par `new SemaphoreSlim(2)`. Ce qui casse, c'est ce que protège la section critique : deux fils seraient dedans à la fois, et c'est bien pour cela que le compte vaut 1. La leçon 7 construit exactement ce réseau et le mesure.

**2.** Il prouve que `writing` vaut au plus 1 : puisque `reading` et `access` ne peuvent pas être négatifs, 3·`writing` vaut au plus 3. Le poids 3 apparaît parce que `start_write` prend les trois permis d'`access` par un arc de poids 3 — l'invariant doit donner à un rédacteur le poids de ce qu'il consomme, ce qui est exactement ce qui fait de « un rédacteur exclut trois lecteurs » de l'arithmétique plutôt qu'une règle que quelqu'un a pensé à faire respecter.

**3.** Il prouve que le workflow est dans exactement l'un des trois états à tout instant, et donc qu'il ne tourne jamais deux fois à la fois et ne disparaît jamais en silence. Il ne prouve **rien** sur la terminaison : le marquage `working = 1` satisfait l'invariant pour toujours, et un réseau qui reste là est un workflow qui se bloque. La terminaison est une propriété de vivacité ; la leçon 10 la définit correctement dans le cadre de la *soundness*, et elle demande le graphe d'accessibilité ou un théorème structurel, pas un invariant.

**4.** Il n'y en a aucun dont le support contienne `log` ou `queue`, parce que `emit` ne fait que leur ajouter : tout *y* avec *y C* = 0 doit avoir *y(log)* = *y(queue)* = 0. Le seul invariant porte sur `ready` seule — `emit` prend un jeton dans `ready` et l'y remet aussitôt, donc la colonne de *C* y est nulle, et `ready = 1` est conservé. Deux des trois places n'ont aucune loi de conservation, et ce sont exactement les deux que l'arbre de couverture de la leçon 3 a marquées ω.

</details>

## Sources

- Tadao Murata, *Petri nets: Properties, analysis and applications*, **Proceedings of the IEEE** 77(4), avril 1989, pages 541–580, [doi:10.1109/5.24143](https://doi.org/10.1109/5.24143). La section V-B est la référence pour les invariants de places et de transitions et pour l'élimination de Farkas utilisée ici. La notice est confirmée via Crossref ; l'article est derrière le péage de l'IEEE et je ne l'ai pas lu, donc rien dans cette leçon ne repose sur lui seul — tout ce qui précède est soit dérivé dans le texte, soit imprimé par l'analyseur. *À vérifier.*
- Wolfgang Reisig, *Understanding Petri Nets*, Springer, 2013, [doi:10.1007/978-3-642-33278-4](https://doi.org/10.1007/978-3-642-33278-4), pour les invariants de places présentés comme la technique de preuve principale plutôt que comme une remarque en passant. *À vérifier* — notice vérifiée, livre non lu.
- L'implémentation que cette leçon imprime : [`Invariants.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Invariants.cs), avec les tests unitaires qui confrontent chaque invariant à chaque marquage accessible dans [`PetriNetTests.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/Tests/PetriNetTests.cs).
</content>
</invoke>
