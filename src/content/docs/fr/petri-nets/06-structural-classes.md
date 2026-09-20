---
title: 6. Classes structurelles
description: Machines à états, graphes marqués et réseaux à choix libre — trois formes de réseau qui viennent avec des théorèmes, les circuits, les siphons et les trappes dans lesquels ces théorèmes sont énoncés, une vivacité décidée sur un réseau dont le graphe d'accessibilité est infini, et la raison honnête pour laquelle la plupart des modèles réels tombent hors des trois classes.
sidebar:
  order: 6
---

Code complet : [`code/petri-nets`](https://github.com/spareilleux/learn/tree/main/code/petri-nets). Cette leçon est imprimée par `dotnet run --project Examples -c Release -- l6`, comparée à [`expected/l6.txt`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/expected/l6.txt).

La leçon 5 prouvait des choses à partir de la matrice d'incidence. Cette leçon prouve des choses à partir de la *forme* du réseau — à partir de quelles places alimentent quelles transitions, avant tout poids, tout jeton, tout tir.

La raison de s'y intéresser est brutale : pour trois formes particulières, quelqu'un a déjà fait le travail difficile. Si votre réseau en est une, une propriété qui coûte un graphe d'accessibilité en général coûte une inspection des arcs. Si votre réseau n'en est pas une, il faut le savoir aussi, parce que cela vous dit quel théorème vous n'avez pas le droit d'utiliser.

Deux notations, employées partout ci-dessous et dans [`Structure.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Structure.cs) :

- **•t** est l'ensemble des places où la transition *t* prend, et **t•** l'ensemble où elle dépose ;
- **•p** est l'ensemble des transitions qui remplissent la place *p*, et **p•** l'ensemble de celles qui la vident.

## Les trois formes

| classe | condition | ce qu'elle interdit |
|---|---|---|
| **machine à états** | toute transition a exactement une place d'entrée et une place de sortie | toute transition qui synchronise ou qui fourche |
| **graphe marqué** | toute place a exactement une transition d'entrée et une transition de sortie | toute place que deux transitions se disputent |
| **réseau à choix libre** | si deux places partagent une transition de sortie, chacune d'elles a exactement cette sortie-là | un choix dont l'issue dépend des jetons de quelqu'un d'autre |

Une machine à états est ce que vous dessiniez avant de rencontrer les réseaux de Petri : un jeton qui se promène dans un graphe d'états. Elle peut brancher, elle ne peut pas fourcher — rien en elle ne produit jamais deux jetons.

Un graphe marqué est le dual : il peut fourcher et synchroniser, et il n'a aucun choix. Toute place a un producteur et un consommateur, donc deux transitions ne se disputent jamais rien.

Un réseau à choix libre permet les deux, tant que choix et synchronisation ne touchent jamais la même place. Quand `p` alimente `t1` et `t2`, la décision entre les deux est libre — rien d'autre dans le réseau ne peut rendre l'une impossible en laissant l'autre sensibilisée.

Voici où tombent les réseaux de ce cours, les classes étant décidées sur les seuls arcs :

```
== Where the nets of this course sit ==
net                 state machine  marked graph  free choice  ext. free choice  asym. choice  strongly conn.
producer-consumer   no             yes           yes          yes               yes           yes
unbounded-producer  no             yes           yes          yes               yes           no
connection          yes            no            yes          yes               yes           yes
start-once          yes            no            yes          yes               yes           no
handshake           no             no            yes          yes               yes           no
mutual-exclusion    no             no            no           no                yes           yes
two-locks           no             no            no           no                yes           yes
readers-writers     no             no            no           no                no            yes
philosophers-3      no             no            no           no                no            yes
```

Les deux dernières colonnes sont les parentes plus faibles. Le **choix libre étendu** demande que deux places partageant une transition de sortie les partagent *toutes* ; le **choix asymétrique** (aussi appelé réseau simple) demande seulement que l'un des deux ensembles de transitions de sortie contienne l'autre. Chaque classe contient la précédente, et le tableau montre l'échelle à l'œuvre : le verrou est à choix asymétrique, les philosophes ne le sont même pas.

Lisez les quatre dernières lignes avant les cinq premières. Tout ce qui, dans ce cours, modélise une ressource partagée est hors de la classe à choix libre, et ce n'est pas un accident — la dernière section de cette leçon dit pourquoi.

## Graphes marqués : comptez les jetons sur chaque circuit

Le producteur et le consommateur est un graphe marqué : `free` n'est remplie que par `take` et vidée que par `deposit`, et il en va de même de toutes les autres places.

```
== A marked graph: the producer and consumer ==
structure of producer-consumer
  ordinary (every arc weight 1):  yes
  pure (no self-loop):            yes
  strongly connected:             yes
  state machine:                  no
  marked graph:                   yes
  free choice:                    yes
  extended free choice:           yes
  asymmetric choice:              yes
circuits of producer-consumer: 3 circuits
  {ready, produced}  tokens at M0: 1
  {free, full}  tokens at M0: 2
  {waiting, taken}  tokens at M0: 1
marked graph theorem  live: True   safe: False   markings enumerated: 0
reachability graph    live: True   safe: False   markings enumerated: 12
```

Arrêtez-vous sur ces trois circuits et comparez-les à la leçon 5 :

```
ready + produced = 1
free + full = 2
waiting + taken = 1
```

Ce sont les mêmes trois ensembles avec les mêmes trois nombres. Dans un graphe marqué, les jetons sur un circuit ne peuvent jamais changer — toute transition du circuit prend un jeton à la place qui la précède et en met un dans celle qui la suit — donc **chaque circuit est un invariant de places**, et le nombre de jetons dessus est la constante. Les tests unitaires de l'analyseur vérifient cette correspondance sur ce réseau. L'algèbre de la leçon 5 et la géométrie de celle-ci sont, ici, deux descriptions d'un seul fait.

Deux théorèmes en découlent, tous deux tirés du *Marked directed graphs* de Commoner, Holt, Even et Pnueli ([JCSS 5(5), 1971](https://doi.org/10.1016/S0022-0000(71)80013-2)) :

- un graphe marqué est **vivant** exactement quand tout circuit orienté porte au moins un jeton ;
- un graphe marqué vivant est **sûr** exactement quand toute place se trouve sur un circuit portant exactement un jeton.

Les deux se croient facilement à partir de l'invariant : un circuit sans jeton est un ensemble de conditions dont aucune ne pourra jamais devenir vraie, et le circuit qui passe par une place plafonne le nombre de jetons que cette place peut tenir. L'analyseur les applique puis confronte les réponses au graphe d'accessibilité — `live: True  safe: False` des deux côtés, douze marquages d'un côté et aucun de l'autre. `free` et `full` sont sur un circuit à deux jetons, ce qui est exactement pourquoi le réseau est 2-borné et n'est pas sûr.

C'est la première fois dans ce cours qu'une question de vivacité est tranchée sans énumération.

## Machines à états : un jeton, et peut-on revenir

```
== A state machine that is live, and one that is not ==
net connection
places      disconnected connecting connected
transitions open established failed close
M0          (1, 0, 0) = disconnected:1
arc         disconnected -> open
arc         open -> connecting
arc         connecting -> established
arc         established -> connected
arc         connecting -> failed
arc         failed -> disconnected
arc         connected -> close
arc         close -> disconnected
structure of connection
  ordinary (every arc weight 1):  yes
  pure (no self-loop):            yes
  strongly connected:             yes
  state machine:                  yes
  marked graph:                   no
  free choice:                    yes
  extended free choice:           yes
  asymmetric choice:              yes
state machine theorem  strongly connected: True   tokens at M0: 1
                       live: True   safe: True
reachability graph     live: True   safe: True   markings enumerated: 3
```

`connection`, c'est `disconnected → connecting → connected → disconnected`, avec une branche `failed` qui revient de `connecting`. C'est la machine à états que vous auriez dessinée de toute façon, et pour cette forme la règle est courte : une machine à états est vivante quand elle est fortement connexe et porte au moins un jeton, et sûre quand elle en porte au plus un. Le nombre total de jetons ne change jamais, parce que chaque transition en prend un et en donne un.

`start-once` est le contre-exemple que la leçon 4 utilisait déjà, et la raison est maintenant structurelle plutôt que comportementale :

```
net start-once
places      stopped running serving
transitions start accept finish
M0          (1, 0, 0) = stopped:1
arc         stopped -> start
arc         start -> running
arc         running -> accept
arc         accept -> serving
arc         serving -> finish
arc         finish -> running
structure of start-once
  ...
  strongly connected:             no
  state machine:                  yes
state machine theorem  strongly connected: False   tokens at M0: 1
                       live: False   safe: True
reachability graph     live: False   safe: True   markings enumerated: 3
```

Rien ne ramène à `stopped`. Un coup d'œil aux arcs suffit, là où la leçon 4 avait besoin de tout le graphe pour dire la même chose.

## Siphons et trappes

Pour la classe à choix libre, le théorème s'énonce en deux idées qui valent la peine d'être connues même quand votre réseau n'est dans aucune classe.

Un **siphon** est un ensemble *S* de places avec **•S ⊆ S•** : toute transition qui met un jeton dans *S* en retire aussi un.

Une **trappe** est un ensemble *S* avec **S• ⊆ •S** : toute transition qui retire un jeton de *S* en remet aussi un.

Chacune a une preuve en une ligne, pour les réseaux ordinaires — ceux où tout arc a le poids 1 :

- **Un siphon vide reste vide.** Supposons que *S* ne tienne rien et qu'un certain *t* tire en mettant un jeton dans *S*. Alors *t* ∈ •S ⊆ S•, donc *t* prend aussi un jeton dans une place de *S* — qui n'en tient aucun, donc *t* n'était pas sensibilisée. Contradiction.
- **Une trappe qui tient un jeton continue d'en tenir un.** Supposons que *S* tienne un jeton et que *t* tire. Si *t* ne prend rien dans *S*, le compte ne peut pas baisser. Si elle y prend, alors *t* ∈ S• ⊆ •S, donc *t* met aussi un jeton dans une place de *S*, et *S* est marquée à nouveau aussitôt.

Un siphon est une façon pour un système de mourir ; une trappe est une façon pour lui de rester vivant. C'est pourquoi ce sont les deux notions dans lesquelles les théorèmes de vivacité s'écrivent, et il vaut la peine d'être précis sur laquelle est laquelle : c'est la **trappe** qui doit être marquée, jamais le siphon.

Voici maintenant la conséquence qui ne demande aucune classe, et dont la preuve tient en trois lignes :

:::note[Tout marquage mort vide un siphon]
Soit *M* un marquage mort d'un réseau ordinaire et soit *D* l'ensemble des places ne tenant rien à *M*. Prenez une *t* quelconque qui met un jeton dans *D*. Comme *M* est mort, *t* n'est pas sensibilisée, donc l'une de ses places d'entrée ne tient rien — cette place est dans *D*, donc *t* prend dans *D*. Donc •D ⊆ D• : *D* est un siphon.

Retournez-le et vous obtenez une condition suffisante d'**absence d'interblocage** dans n'importe quel réseau ordinaire : si tout siphon contient une trappe marquée à *M0*, il n'y a pas de marquage mort. Un marquage mort donnerait un siphon vide *D* ; *D* contient une trappe marquée ; cette trappe tient encore un jeton, et elle est à l'intérieur de *D*, qui n'en tient aucun.
:::

L'analyseur vérifie la première moitié sur le réseau qui s'interbloque de la leçon 4 :

```
== Every dead marking empties a siphon ==
dead marking (0, 1, 0, 1, 0, 0)  a_has_x:1 b_has_y:1
  places holding nothing: {a_idle, b_idle, x, y}
  that set is a siphon: True
  largest trap inside it: {}
```

Et la cause structurelle est l'un de ses cinq siphons minimaux :

```
siphons of two-locks: 5 minimal siphons
  siphon {a_idle, a_has_x}
    largest trap inside it: {a_idle, a_has_x}  marked at M0: yes
  siphon {b_idle, b_has_y}
    largest trap inside it: {b_idle, b_has_y}  marked at M0: yes
  siphon {a_has_x, x}
    largest trap inside it: {a_has_x, x}  marked at M0: yes
  siphon {b_has_y, y}
    largest trap inside it: {b_has_y, y}  marked at M0: yes
  siphon {x, y}
    largest trap inside it: {}  marked at M0: no
  every siphon contains a marked trap: no
  minimal traps: {a_idle, a_has_x} {b_idle, b_has_y} {a_has_x, x} {b_has_y, y}
```

`{x, y}`, les deux verrous ensemble, est un siphon ne contenant aucune trappe. Les deux verrous peuvent être pris et aucun n'est obligé de revenir, et une fois cet ensemble vide il l'est pour toujours. L'interblocage de la leçon 4 était une image ; voici sa cause, trouvée sans rien tirer.

## Le théorème de Commoner, et ce qu'il achète

Pour les réseaux à choix libre, la condition suffisante devient une caractérisation exacte. Le résultat est énoncé dans le mémoire de maîtrise de Michel Hack, en 1972, et y est attribué à Frederic Commoner :

> Un réseau à choix libre est vivant si et seulement si tout siphon contient une trappe marquée.

L'analyseur l'applique aux réseaux à choix libre du cours et met le verdict du graphe d'accessibilité à côté :

```
== Free choice, siphons and traps ==
siphons of producer-consumer: 3 minimal siphons
  siphon {ready, produced}
    largest trap inside it: {ready, produced}  marked at M0: yes
  siphon {free, full}
    largest trap inside it: {free, full}  marked at M0: yes
  siphon {waiting, taken}
    largest trap inside it: {waiting, taken}  marked at M0: yes
  every siphon contains a marked trap: yes
  minimal traps: {ready, produced} {free, full} {waiting, taken}
free choice: True   every siphon contains a marked trap: True
Commoner therefore says live: True
the reachability graph says live: True

siphons of start-once: 1 minimal siphon
  siphon {stopped}
    largest trap inside it: {}  marked at M0: no
  every siphon contains a marked trap: no
  minimal traps: {running, serving}
free choice: True   every siphon contains a marked trap: False
Commoner therefore says live: False
the reachability graph says live: False

siphons of handshake: 1 minimal siphon
  siphon {request, response}
    largest trap inside it: {request, response}  marked at M0: no
  every siphon contains a marked trap: no
  minimal traps: {served} {request, response}
free choice: True   every siphon contains a marked trap: False
Commoner therefore says live: False
the reachability graph says live: False
```

`start-once` mérite un second regard, parce que c'est le cas où la formulation compte. Le siphon `{stopped}` **est** marqué à *M0* — le service commence à l'arrêt. Ce qu'il ne contient pas, c'est une *trappe* : une fois que `start` a tiré, rien ne remet jamais de jeton dans `stopped`, donc le siphon se vide et le reste, et `start` est morte pour le reste du temps. Qu'un siphon soit marqué maintenant ne signifie rien. Une trappe marquée à l'intérieur, voilà la promesse.

Le `handshake` est l'autre forme d'échec : là, le siphon `{request, response}` est aussi une trappe, et il ne tient rien dès le départ. Un réseau qui commence avec une trappe vide a déjà perdu.

Maintenant le bénéfice. Mettez un jeton dans `request` et la même structure devient vivante — et le réseau devient non borné, parce que `served` compte les échanges terminés pour toujours :

```
== A liveness decided where no reachability graph exists ==
net handshake-started
places      request response served
transitions receive reply
M0          (1, 0, 0) = request:1
siphons of handshake-started: 1 minimal siphon
  siphon {request, response}
    largest trap inside it: {request, response}  marked at M0: yes
  every siphon contains a marked trap: yes
  minimal traps: {served} {request, response}
free choice: True
every siphon contains a marked trap: True
Commoner: live
the graph cannot say so: bounded: False, dead transitions: none
reachability graph stopped after 500 markings, complete: False
```

Le graphe d'accessibilité a abandonné à 500 marquages et aurait continué indéfiniment. L'arbre de couverture de la leçon 3 peut dire que le réseau n'est pas borné et qu'aucune transition n'est morte, et c'est tout ce qu'il peut dire — ω a jeté les comptes dont la vivacité a besoin. La structure a répondu quand même. C'est à cela que servent ces classes.

## Où les classes s'arrêtent

Tout réseau de ce cours qui modélise une ressource partagée est hors de la classe à choix libre, et l'analyseur dit exactement où :

```
== Where the classes stop: the place two transitions fight over ==
mutual-exclusion   free choice: False, extended: False, asymmetric: True
  mutex feeds enter1 and enter2, which do not read the same places
two-locks          free choice: False, extended: False, asymmetric: True
  x feeds a_take_x and b_take_x, which do not read the same places
  y feeds a_take_y and b_take_y, which do not read the same places
philosophers-3     free choice: False, extended: False, asymmetric: False
  fork1 feeds take1 and take3, which do not read the same places
  fork2 feeds take1 and take2, which do not read the same places
  fork3 feeds take2 and take3, which do not read the same places
```

Le motif est le même à chaque fois. `mutex` offre un choix entre `enter1` et `enter2`, mais le choix n'est pas libre : que `enter1` puisse prendre le jeton dépend de `idle1`, qui n'a rien à voir avec `mutex`. C'est précisément ce que le choix libre interdit, et c'est précisément ce qu'*est* un verrou. Les philosophes tombent aussi hors de la classe à choix asymétrique, parce que dans un anneau chaque fourchette est disputée par deux voisins dont les autres entrées sont sans rapport dans les deux sens.

Le résumé honnête de cette leçon est donc autant un avertissement qu'un outil : les théorèmes sont tranchants, et la classe qui porte le plus tranchant d'entre eux exclut l'exclusion mutuelle, l'ordonnancement des verrous et le dîner des philosophes — trois des quatre choses qu'un programme concurrent fait réellement. Ce qui survit hors de la classe, c'est l'implication à sens unique prouvée plus haut (une trappe marquée dans tout siphon signifie pas d'interblocage), qui vaut pour tout réseau ordinaire et sur laquelle s'appuie la leçon 7.

:::caution[Le coût de la recherche d'un siphon]
[`Structure.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Structure.cs) trouve les siphons minimaux en essayant tous les sous-ensembles de places. C'est exact, c'est très bien sur des réseaux de vingt places, et c'est exponentiel. Décider si un réseau a un siphon ayant une propriété donnée est NP-difficile en général, et les vrais outils emploient des solveurs de contraintes plutôt que l'énumération. Les trois philosophes de la leçon 7 ont 4 096 sous-ensembles ; six philosophes en auraient 16 millions.
:::

## Points clés

- Une **machine à états** a une place d'entrée et une place de sortie par transition. Elle est vivante quand elle est fortement connexe avec au moins un jeton, sûre quand elle en a au plus un.
- Un **graphe marqué** a une transition d'entrée et une transition de sortie par place. Ses circuits sont ses invariants de places ; il est vivant quand tout circuit porte un jeton, et un graphe marqué vivant est sûr quand toute place est sur un circuit portant exactement un jeton.
- Un **réseau à choix libre** ne mêle jamais choix et synchronisation. Le théorème de Commoner fait de la vivacité exactement « tout siphon contient une trappe marquée ».
- Un **siphon** qui se vide reste vide ; une **trappe** qui est marquée reste marquée. Les deux preuves tiennent en une ligne, pour les réseaux ordinaires.
- **Tout marquage mort vide un siphon**, dans n'importe quel réseau ordinaire. Donc une trappe marquée dans chaque siphon prouve l'absence d'interblocage, quelle que soit la classe du réseau.
- Les classes ont toutes été décidées **sur les arcs**, sans énumérer un marquage ; `handshake-started` est déclaré vivant alors que son graphe d'accessibilité est infini.
- L'exclusion mutuelle, l'ordonnancement des verrous et les philosophes sont **hors** de la classe à choix libre. Partager une ressource est exactement ce qui la casse.

## Exercices

1. `two-locks-ordered` — les deux fils prenant `x` avant `y` — a été montré sans interblocage à la leçon 4 par énumération. Prédisez à quoi ressemblent ses siphons minimaux et si chacun contient une trappe marquée, puis vérifiez avec l'analyseur.
2. Le producteur et le consommateur est à la fois un graphe marqué et un réseau à choix libre. Est-ce une coïncidence ? Prouvez ou réfutez : tout graphe marqué est un réseau à choix libre.
3. Prenez `connection` et supprimez la transition `failed`. Laquelle des deux hypothèses du théorème des machines à états casse, et qu'arrive-t-il au réseau ?
4. Le réseau `handshake` a `{served}` parmi ses trappes minimales. Expliquez pourquoi une place sans arc sortant est toujours une trappe, et pourquoi ce fait est inutile.

<details>
<summary>Solutions</summary>

**1.** L'analyseur imprime ceci, et il vaut la peine de confronter votre prédiction à la première ligne, parce que la mienne était fausse :

```
== Exercise 1: the same net with both threads taking x first ==
siphons of two-locks-ordered: 4 minimal siphons
  siphon {y}
    largest trap inside it: {y}  marked at M0: yes
  siphon {a_idle, a_has_x}
    largest trap inside it: {a_idle, a_has_x}  marked at M0: yes
  siphon {b_idle, b_has_x}
    largest trap inside it: {b_idle, b_has_x}  marked at M0: yes
  siphon {a_has_x, b_has_x, x}
    largest trap inside it: {a_has_x, b_has_x, x}  marked at M0: yes
  every siphon contains a marked trap: yes
  minimal traps: {y} {a_idle, a_has_x} {b_idle, b_has_x} {a_has_x, b_has_x, x}
free choice: False
deadlock-free by the graph: True
```

Je m'attendais à ce que `{x, y}` apparaisse encore, avec une trappe marquée ajoutée. Il n'apparaît pas du tout. Dans le réseau ordonné, `y` toute seule est un siphon — elle est remplie et vidée par les deux mêmes transitions — et c'est aussi une trappe tenant un jeton, donc `{x, y}` n'est plus *minimal*. L'ensemble qui porte `x` est `{a_has_x, b_has_x, x}` : le verrou est soit libre, soit tenu par l'un des deux fils, et toute façon de le prendre le met quelque part dans cet ensemble. Les deux sont des trappes, les deux sont marquées, tout siphon contient une trappe marquée, et par l'implication prouvée plus haut c'est une preuve d'absence d'interblocage qui ne demande aucun graphe d'accessibilité. La leçon 4 avait la même réponse, avec un graphe. Notez les deux dernières lignes : le réseau n'est *pas* à choix libre, donc c'est l'implication à sens unique seulement — la condition qui tient prouve l'absence d'interblocage, et n'aurait pas prouvé la vivacité.

**2.** Pas une coïncidence : **tout graphe marqué est un réseau à choix libre**, et la preuve est immédiate. Le choix libre ne peut être violé que quand deux places partagent une transition de sortie alors que l'une d'elles en a une autre. Dans un graphe marqué, toute place a exactement une transition de sortie, donc si `p1` et `p2` en partagent une, les deux ont exactement celle-là — ce qui est la condition de choix libre satisfaite. La réciproque est fausse : `connection` est à choix libre et n'est pas un graphe marqué, puisque `disconnected` a deux transitions d'entrée.

**3.** C'est la forte connexité qui casse : sans `failed`, la seule sortie de `connecting` est `established`, et il y a toujours un chemin de retour, donc en fait le réseau reste fortement connexe — `connecting → established → connected → close → disconnected → open → connecting`. Supprimez plutôt `close` et vous coupez le seul retour depuis `connected`, le réseau cesse d'être fortement connexe, et il dégénère en `start-once` : une connexion qui s'ouvre et ne peut jamais être rouverte. L'exercice porte en réalité sur le fait de repérer quel arc est le chemin de retour.

**4.** Une place `p` dont `p•` est vide satisfait `p• ⊆ •p` pour la raison triviale que l'ensemble vide est inclus dans n'importe quoi, donc `{p}` est une trappe. C'est inutile parce qu'elle n'est marquée que si elle tient déjà un jeton, et être marquée pour toujours n'a rien d'intéressant pour une place que rien ne lit : c'est un compteur, pas une condition. Les trappes qui comptent dans le théorème de Commoner sont celles qui sont *à l'intérieur d'un siphon*, et une place puits n'est dans aucun siphon — `•{p}` est non vide alors que `{p}•` est vide, donc `{p}` ne peut pas satisfaire la condition de siphon.

</details>

## Sources

- Frederic Commoner, Anatol W. Holt, Shimon Even et Amir Pnueli, *Marked directed graphs*, **Journal of Computer and System Sciences** 5(5), octobre 1971, pages 511–523, [doi:10.1016/S0022-0000(71)80013-2](https://doi.org/10.1016/S0022-0000(71)80013-2). Les théorèmes de vivacité et de sûreté pour les graphes marqués. Notice confirmée via Crossref ; l'article est derrière le péage d'Elsevier et je ne l'ai pas lu. *À vérifier.*
- Michel Hack, *Analysis of production schemata by Petri nets*, mémoire de maîtrise, MIT, février 1972, publié comme rapport technique Project MAC MAC-TR-94 / MIT-LCS-TR-094, [handle 1721.1/149406](https://dspace.mit.edu/handle/1721.1/149406). C'est là que le théorème de vivacité de Commoner pour les réseaux à choix libre est énoncé. La notice et le PDF en accès libre sont confirmés sur DSpace@MIT, mais le téléchargement est derrière un contrôle anti-robot qui a refusé mes requêtes, donc **je n'ai pas lu le mémoire** et la formulation ci-dessus vient de sources secondaires. *À vérifier.* Ce que cette leçon affirme sur ses propres preuves est plus étroit et vérifié : sur les quatre réseaux à choix libre présents ici, la condition et le graphe d'accessibilité sont d'accord, et les tests unitaires échouent s'ils cessent de l'être.
- Jörg Desel et Javier Esparza, *Free Choice Petri Nets*, Cambridge Tracts in Theoretical Computer Science 40, Cambridge University Press, 1995, [doi:10.1017/CBO9780511526558](https://doi.org/10.1017/CBO9780511526558). La monographie sur la classe. Notice confirmée chez Cambridge Core ; non lue. *À vérifier.*
- Tadao Murata, *Petri nets: Properties, analysis and applications*, **Proceedings of the IEEE** 77(4), avril 1989, pages 541–580, [doi:10.1109/5.24143](https://doi.org/10.1109/5.24143), sections II-B et IV pour les classes et pour les siphons et les trappes. Payant et non lu. *À vérifier.*
- L'implémentation : [`Structure.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Structure.cs).
</content>
</invoke>
