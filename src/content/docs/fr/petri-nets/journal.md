---
title: Journal
description: Notes datées du cours sur les réseaux de Petri — la conception de l'analyseur, un PNML qui mentait sur son encodage, un arbre de couverture imprimé dans le mauvais ordre, les nombres de Lucas arrivés sans invitation, et ce que je n'ai pas pu vérifier.
sidebar:
  order: 99
---

## Avancement

- [x] Leçon 1 — Pourquoi les réseaux de Petri
- [x] Leçon 2 — La définition formelle et la matrice d'incidence
- [x] Leçon 3 — Le graphe d'accessibilité
- [x] Leçon 4 — Propriétés
- [x] Leçon 5 — Invariants
- [x] Leçon 6 — Classes structurelles
- [x] Leçon 7 — Modéliser la concurrence
- [x] Leçon 8 — Réseaux colorés
- [ ] Leçon 9 — Temps et probabilités
- [ ] Leçon 10 — Workflows
- [ ] Leçon 11 — Outils et interopérabilité
- [ ] Leçon 12 — Applications industrielles
- [ ] Leçon 13 — Face aux autres formalismes
- [ ] Leçon 14 — Sur nos propres systèmes
- [ ] Leçon 15 — Limites et suite

## QA

Ce cours enseigne un formalisme et tourne sur un analyseur que j'ai écrit, il n'y a donc aucun produit tiers contre lequel ouvrir des tickets. Ce que le tableau contient à la place, c'est ce que le recalcul a trouvé : deux défauts dans l'analyseur, et chaque affirmation qui s'est révélée fausse une fois le programme interrogé. Les numéros de ligne pointent sur les fichiers de [`code/petri-nets`](https://github.com/spareilleux/learn/tree/main/code/petri-nets).

| Attendu | Ce qui se passe | Où | Mesure | État |
|---|---|---|---|---|
| La déclaration PNML annonce l'encodage que le fichier a | `XmlWriter.Create(StringBuilder, settings)` écrit `encoding="utf-16"` quoi que dise `XmlWriterSettings.Encoding`, parce que l'encodage vient du `TextWriter` ; les octets étaient en UTF-8 | [`Pnml.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Pnml.cs) | Les huit fichiers du lot 1 annonçaient un encodage qu'ils n'avaient pas | Corrigé par une sous-classe de `StringWriter` de trois lignes qui redéfinit `Encoding` (2026-09-15) |
| L'arbre de couverture s'imprime comme un arbre | Le premier afficheur parcourait les nœuds dans l'ordre de création et les indentait par profondeur, si bien que des enfants apparaissaient sous des frères sans rapport | [`Report.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Report.cs), `Tree` | L'arbre à 17 nœuds d'`unbounded-producer` n'avait aucun sens ; une leçon a failli être écrite autour | Corrigé : l'afficheur parcourt l'arbre en profondeur depuis la racine (2026-09-15) |
| Le marquage le plus éloigné du producteur/consommateur est à 6 tirs de *M0* | Il est à 8 | Brouillon de la leçon 3 | `PathTo(11)` renvoie huit noms de transitions | Corrigé avant publication (2026-09-15) |
| `handshake` a 8 marquages accessibles | Il en a 1, et celui-là est mort | Brouillon de la leçon 2 | `ReachabilityGraph.Build` renvoie un unique état | Corrigé avant publication (2026-09-15) |
| Une **trappe** sans jeton est ce qui rend un marquage parasite | C'est un **siphon**. Une trappe marquée reste marquée ; un siphon vide reste vide | Brouillon de la leçon 2 | Les deux définitions sont duales et le brouillon les avait inversées | Corrigé avant publication (2026-09-15) |
| `handshake` a l'invariant de transitions (1, 1) | Il n'en a **aucun** : `receive` dépose dans `served` un jeton que rien ne retire, donc aucun multiensemble de tirs ne s'annule | [`Invariants.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Invariants.cs) | `Invariants.Transitions(handshake).Count` vaut 0, et pour `handshake-started` aussi | Corrigé avant publication ; la leçon 5 fait maintenant de ce zéro son propre résultat (2026-09-17) |
| `mutual-exclusion` est hors de la classe à choix asymétrique | Il est **dedans** : `idle1•` et `idle2•` sont chacun inclus dans `mutex•` | [`Structure.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Structure.cs) | Un test unitaire affirmant le contraire a échoué ; ce sont les philosophes qui tombent hors de la classe | Test corrigé sur la réponse mesurée (2026-09-17) |
| `{x, y}` est encore un siphon minimal une fois que les deux fils prennent `x` d'abord | Il n'est plus minimal : `{y}` seule devient un siphon, et `x` se trouve dans `{a_has_x, b_has_x, x}` | Leçon 6, exercice 1 | `two-locks-ordered` a 4 siphons minimaux, tous avec une trappe marquée | Corrigé avant publication, et la prédiction fausse est publiée avec la bonne réponse (2026-09-17) |
| Le siphon sans trappe dans un verrou jamais relâché est `{critical1, critical2, mutex}` | Il y en a deux, `{idle1}` et `{critical2, mutex}` ; `{critical1}` se révèle être une trappe | Leçon 7, exercice 2 | `Report.Siphons(mutual-exclusion-leaky)` | Corrigé avant publication (2026-09-17) |

## Expériences

Un avertissement avant le tableau : contrairement au [GA Lab](../../ga-lab/journal/), ce cours ne commite pas ses hypothèses dans un fichier avant de mesurer. Les prédictions ci-dessous ont été écrites dans mes notes pendant la construction de chaque réseau puis confrontées au programme ; c'est une discipline plus faible, et là où une prédiction était fausse, c'est l'analyseur qui l'a attrapée, pas un relecteur.

| Question | Hypothèse, écrite avant de mesurer | Résultat | Verdict |
|---|---|---|---|
| Les invariants de places donnent-ils les mêmes bornes que le graphe d'accessibilité ? | Ils donnent les six mêmes nombres sur le producteur et le consommateur | Identiques, place par place, et un test unitaire échoue désormais s'ils divergent : 0 marquage énuméré d'un côté, 12 de l'autre | Confirmée (2026-09-17) |
| La place qui grandit est-elle sans invariant ? | Retirer `free` retire l'invariant qui bornait `full` | `unbounded-producer` a 2 invariants de places au lieu de 3, et `full` n'est couverte par aucun | Confirmée, avec la réserve qu'énonce la leçon : ne pas être couverte est une preuve manquante, pas une preuve de non-bornitude (2026-09-17) |
| Les invariants de places peuvent-ils exclure un marquage parasite ? | Non — ce sont des conséquences de l'équation d'état | Les deux marquages parasites de `handshake`, (0, 0, 1) et (0, 0, 2), satisfont tous les invariants de places | Confirmée (2026-09-17) |
| La condition de Commoner s'accorde-t-elle avec le graphe d'accessibilité ? | Sur tous les réseaux à choix libre du cours | Accord sur les quatre — `producer-consumer` vivant, `start-once` et `handshake` non, `connection` vivant — et un test unitaire l'affirme | Confirmée, sur quatre réseaux seulement ; le théorème lui-même est pris de sources secondaires (2026-09-17) |
| Les circuits d'un graphe marqué sont-ils les mêmes ensembles que ses invariants de places ? | Oui, avec les mêmes constantes | Les trois circuits de `producer-consumer` sont `{ready, produced}` 1, `{free, full}` 2, `{waiting, taken}` 1 — les trois invariants de la leçon 5 | Confirmée (2026-09-17) |
| Combien d'invariants de transitions le handshake a-t-il ? | (1, 1) : `receive` puis `reply` rend le jeton | **Zéro**, et le préfixe de 500 marquages de `handshake-started` ne contient aucun marquage accessible deux fois | Réfutée, et c'est devenu le meilleur résultat : un réseau sans T-invariant ne peut jamais revenir à un marquage qu'il a quitté (2026-09-17) |
| Combien coûte le fait de prendre les fourchettes une à la fois ? | Un interblocage, et plus de marquages | Exactement **un** marquage mort à chaque taille de 2 à 6 philosophes, et 6, 14, 34, 82, 198 marquages contre 3, 4, 7, 11, 18 pour la version atomique | Confirmée, et la constante 1 a été une surprise (2026-09-17) |
| Qu'est-ce qu'inverser un philosophe fait à la structure ? | Retire l'interblocage | Retire un **siphon** : trois philosophes ont 7 siphons minimaux, dont un — `{eating1, fork1, eating2, fork2, eating3, fork3}` — sans trappe marquée ; inversé, 6 siphons et aucun sans trappe marquée | Confirmée, et c'est l'énoncé structurel de « ordonnez vos verrous » (2026-09-17) |
| Une transition vivante est-elle à l'abri de la famine ? | Non | `start_write` est L4 dans les lecteurs-rédacteurs, et le graphe contient un cycle à deux marquages, `start_read` puis `stop_read`, qui ne la tire jamais | Confirmée : la vivacité est « toujours possible », jamais « finit par arriver » (2026-09-17) |
| La couleur réduit-elle l'espace d'états ? | Non — elle ne replie que le modèle | 4 places et 4 transitions à toute limite de tentatives ; le dépliage et le nombre de marquages accessibles croissent tous deux linéairement, 8, 10, 14, 24, 44 marquages pour les limites 2, 3, 5, 10, 20 | Confirmée, et c'est le point principal de la leçon 8 (2026-09-17) |

## 2026-09-15 — Leçons 1 à 4, et l'analyseur qui les fait tourner

**Pourquoi écrire un analyseur.** Il existe des outils mûrs — TINA, LoLA, CPN Tools, GreatSPN, TAPAAL — et la leçon 11 les utilisera. J'en ai quand même écrit un petit, pour trois raisons. Un cours dont les sorties sont comparées par la CI a besoin d'un programme dont je contrôle la sortie jusqu'à l'ordre. Un lecteur qui a la règle de tir sous les yeux en C# la comprend plus vite qu'un lecteur qui a une capture d'écran d'une interface graphique. Et l'analyseur est la seule façon honnête d'écrire ces leçons : les douze marquages, les dix-sept nœuds de l'arbre et les deux solutions parasites sont tous imprimés par lui, pas retenus par moi.

Cela fait environ 1 400 lignes dans dix fichiers de [`code/petri-nets/PetriNets`](https://github.com/spareilleux/learn/tree/main/code/petri-nets/PetriNets) : le réseau et la règle de tir, PNML en lecture et en écriture, le graphe d'accessibilité, l'arbre de couverture de Karp–Miller, les invariants de places et de transitions par élimination de Farkas, l'équation d'état, et un afficheur. Le SDK .NET de cette machine est le 10.0.112, sur .NET 10.0.12 ; `global.json` épingle la bande 10.0.1xx avec `rollForward: latestFeature`, de sorte que la préversion 11.0.100 également installée n'est pas retenue.

**Le déterminisme est la contrainte qui a façonné le code.** Tout ce qu'une leçon cite doit sortir à l'identique sous Windows, Linux et macOS, et les collections à base de hachage ne le promettent pas. Le graphe d'accessibilité est donc construit en largeur et numérote ses états dans l'ordre de découverte ; les tirs sont triés par état source puis par transition avant d'être renvoyés ; les invariants sont normalisés par leur plus grand commun diviseur puis triés ; l'écriture PNML émet des fins de ligne LF et une indentation fixe. `check.sh` compare quatre sorties de leçon et huit fichiers PNML, donc un changement qui réordonne quoi que ce soit échoue tout de suite au lieu de rendre une leçon fausse en silence.

**Surprises :**

- **Le tampon sans frein est à une place près.** Retirer `free` et ses deux arcs du producteur/consommateur transforme un réseau à douze marquages en un réseau dont l'ensemble d'accessibilité est infini. Rien dans l'image ne prévient ; c'est l'*absence* d'une place qui le fait. Je lis désormais « quelle place arrête cette transition » comme la première question à poser à un réseau.
- **Les nombres de Lucas.** Le graphe d'accessibilité de *n* philosophes a 3, 4, 7, 11, 18, 29, 47, 76, 123 marquages pour *n* = 2 … 10. J'attendais quelque chose comme 2ⁿ et j'ai obtenu une suite où chaque terme est la somme des deux précédents. Cela s'explique dès qu'on voit qu'un marquage est un choix de philosophes qui mangent, deux d'entre eux jamais voisins — les ensembles indépendants d'un cycle, comptés par les nombres de Lucas. Un rappel agréable que l'espace d'états a une structure, ce qu'exploitent précisément les techniques de réduction de la leçon 15.
- **L'arbre de couverture est plus gros que le graphe qu'il remplace.** Pour le producteur/consommateur borné : 56 nœuds d'arbre pour 12 marquages. Un arbre ne partage rien, donc chaque marquage est répété une fois par chemin qui y mène. L'arbre ne devient rentable que lorsque le graphe n'existe pas du tout.
- **Les solutions parasites sont plus difficiles à construire qu'à décrire.** Je voulais un marquage satisfaisant *M* = *M0* + *C x* sans être accessible, et mes quatre premières tentatives ont échoué pour la même raison : dans ces réseaux, tout cycle portait un jeton, donc l'équation d'état et la règle de tir étaient d'accord. Celui qui marche est le réseau `handshake`, où `receive` et `reply` se repassent un seul jeton et où personne n'envoie jamais la première requête — l'équation laisse `receive` emprunter le jeton que `reply` ne produirait qu'ensuite. Plutôt que de faire confiance à la construction, l'analyseur énumère maintenant tous les marquages jusqu'à un budget de jetons et signale ceux que l'équation accepte et que le graphe ne contient pas ; il trouve `(0, 0, 1)` et `(0, 0, 2)`. Un test vérifie aussi l'inverse pour le producteur/consommateur, qui n'en a aucun.

**Deux bugs de mon fait, tous deux d'affichage plutôt que de mathématiques :**

- **Du PNML qui mentait sur son encodage.** `XmlWriter.Create(StringBuilder, settings)` écrit `encoding="utf-16"` dans la déclaration quoi que dise `XmlWriterSettings.Encoding`, parce que l'encodage est pris sur le `TextWriter`. Les fichiers étaient écrits en UTF-8, donc chacun d'eux annonçait un encodage qu'il n'avait pas — sans conséquence pour mon propre lecteur, piège pour tout outil qui croit la déclaration. Corrigé par une sous-classe de `StringWriter` de trois lignes qui redéfinit `Encoding`.
- **Un arbre de couverture imprimé dans le mauvais ordre.** La première version imprimait les nœuds dans l'ordre de création et les indentait par profondeur, ce qui ressemble à un arbre sans en être un : les enfants d'un nœud créé plus tard apparaissaient sous un frère sans rapport. La sortie n'avait aucun sens et j'ai failli écrire une leçon autour. L'afficheur parcourt maintenant l'arbre en profondeur depuis la racine.

**Ce que je n'ai pas pu vérifier, et que j'ai marqué comme tel :**

- L'article de synthèse de Murata est derrière le péage de l'IEEE, et IEEE Xplore a refusé la requête. La notice bibliographique est confirmée via Crossref — *Proceedings of the IEEE* 77(4), avril 1989, pages 541–580, [doi:10.1109/5.24143](https://doi.org/10.1109/5.24143) — et les définitions que je lui attribue sont les définitions standard, mais je n'ai pas lu l'article lui-même. Là où il faudrait m'y fier pour une affirmation que je ne peux pas vérifier autrement — que l'équation d'état est nécessaire *et suffisante* pour les réseaux acycliques — la leçon 2 dit *à vérifier* au lieu d'affirmer.
- Le rapport technique de Yale de Lipton, 1976, pour la borne inférieure EXPSPACE de la couverture, est cité d'après des sources secondaires. La borne supérieure correspondante de Rackoff est confirmée : *Theoretical Computer Science* 6(2), 1978, pages 223–231.
- Tout ce qui concerne la complexité de l'accessibilité est rattaché à des articles dont j'ai vérifié les notices chez Crossref : décidabilité par Mayr (STOC 1981) et Kosaraju (STOC 1982), borne supérieure ackermannienne par Leroux et Schmitz (LICS 2019), et borne inférieure correspondante par Czerwiński et Orlikowski et, indépendamment, Leroux, tous deux à FOCS 2021. Je voulais l'état *actuel* de cette question plutôt que le « décidable, complexité ouverte » des manuels plus anciens, et 2021 l'a close.
- ISO/IEC 15909 a trois parties, et je les ai vérifiées toutes les trois sur iso.org : la partie 1 (2019, concepts), la partie 2 (2011, le format d'échange que ce cours écrit, confirmée pour la dernière fois en 2024) et la partie 3 (2021, extensions). La norme elle-même coûte 227 CHF et je ne l'ai pas lue ; le PNML qu'écrit l'analyseur suit la grammaire publique de [pnml.org](https://www.pnml.org/) et fait l'aller-retour par son propre lecteur, ce qui est tout ce que ce cours prétend.

**Reste à faire :**

- Le workflow CI `.github/workflows/petri-nets-examples.yml` est écrit mais **non commité** : le jeton disponible ici n'a pas la portée `workflow`. Rien dans les leçons ne revendique une CI verte tant qu'elle n'a pas tourné.
- Le dogfooding de la leçon 14 — un pipeline `Channel<T>` de Guitar Alchemist, une topologie RabbitMQ, une mise à jour progressive Kubernetes, un pipeline d'agents — n'a pas commencé. Le lot 1 ne modélise que des systèmes de manuel, et le dit.

## 2026-09-15 — Traductions

Les versions française et espagnole de la mission, des leçons 1 à 4 et de ce journal ont été produites à partir du commit anglais, les blocs de code étant recopiés par script et seules la prose, les commentaires du code et les libellés Mermaid étant traduits. Les noms des places et des transitions à l'intérieur des réseaux font partie de la sortie du programme : ils restent en anglais dans les trois langues, parce que les traduire ferait diverger les listings de `expected/`.

## 2026-09-17 — Leçons 5 à 8, et les quatre choses que l'analyseur m'a dites fausses

La question de la CI du lot 1 est réglée : `.github/workflows/petri-nets-examples.yml` a été commité et il est vert sur Ubuntu, Windows et macOS depuis le 2026-09-16, au commit `53ceefc`. Il lance maintenant huit leçons au lieu de quatre.

**Ce que l'analyseur a gagné.** 672 lignes dans trois nouveaux fichiers, plus des ajouts à quatre fichiers existants :

- [`Structure.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Structure.cs) — les classes (machine à états, graphe marqué, choix libre, choix libre étendu, choix asymétrique, ordinaire, pur, fortement connexe), les circuits élémentaires, les siphons et les trappes par force brute sur les sous-ensembles de places, et la plus grande trappe contenue dans un ensemble par le point fixe habituel.
- [`Coloured.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Coloured.cs) — les ensembles de couleurs, les gardes, les expressions d'arc, une règle de tir sur les marquages colorés, et `Unfold()` vers un réseau P/T ordinaire.
- Dans [`Invariants.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Invariants.cs), la borne que chaque place tire des seuls invariants, et le rang de *C* par élimination entière exacte.
- Dans [`ReachabilityGraph.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/ReachabilityGraph.cs), `CycleAvoiding(t)` : un cycle accessible depuis *M0* qui ne tire jamais *t*. Deux douzaines de lignes, et c'est ce qui transforme « cette transition est vivante » en « et voici l'exécution dans laquelle cela n'arrive jamais ».

Sept réseaux se sont ajoutés à ceux qu'exporte le lot 1 — `connection`, `handshake-started`, `readers-writers`, `counting-semaphore`, les philosophes prenant une fourchette à la fois avec et sans ordre imposé, et le dépliage du réseau de réessai coloré — et un huitième, le verrou jamais relâché, n'existe que pour être cassé dans l'exercice de la leçon 7 et n'est pas exporté. Tout réseau exporté est régénéré et comparé par `check.sh`. Les tests unitaires sont passés de 30 à 52.

**Le résultat que je n'attendais pas, et que j'ai gardé.** La leçon 5 devait se terminer sur « un invariant de transitions existe mais ne peut pas tirer », avec le `handshake` comme exemple. Le `handshake` n'a aucun invariant de transitions. `receive` met un jeton dans `served` et rien ne l'en retire jamais, donc aucun multiensemble non vide de tirs ne s'annule ; et dès que c'est vrai, le réseau ne peut jamais revenir à un marquage qu'il a quitté. La leçon dit cela désormais, ce qui est un meilleur fait, et `two-locks` porte le point initial — il a deux T-invariants et un marquage depuis lequel aucun des deux ne peut démarrer.

**Trois autres prédictions que le programme a refusées**, toutes dans le tableau QA ci-dessus : `mutual-exclusion` *est* un réseau à choix asymétrique (un test unitaire affirmant le contraire a échoué), `{x, y}` cesse d'être un siphon minimal une fois que les deux fils prennent `x` d'abord, et le verrou jamais relâché a deux siphons sans trappe plutôt que celui que j'avais nommé. La leçon 6 publie la prédiction fausse à côté de la bonne réponse, parce que la forme de l'erreur — supposer qu'un ensemble reste minimal quand la structure autour de lui change — est plus utile que la réponse.

**Surprises à garder :**

- **Les philosophes s'interbloquent exactement une fois.** De deux à six philosophes, une fourchette à la fois : 1 marquage mort à chaque fois, sur 6, 14, 34, 82, 198. Je m'attendais à ce que le nombre grandisse avec l'anneau. Ce n'est pas le cas, parce que la seule façon de perdre est que *tout le monde* tienne une fourchette, et il n'y a qu'un tel marquage.
- **La famine fait deux marquages de large.** Le réseau lecteurs-rédacteurs est vivant, et l'exécution dans laquelle le rédacteur n'entre jamais est `start_read`, `stop_read`, répétés. La trouver a demandé un parcours en profondeur du graphe avec une transition supprimée, et la voir imprimée a rendu concrète la différence entre vivacité et équité comme les définitions ne l'avaient jamais fait.
- **La couleur n'achète rien à l'analyse.** Le réseau de réessai garde quatre places et quatre transitions que la limite de tentatives soit 2 ou 20 ; le dépliage passe de 8 places à 44 et les marquages accessibles de 8 à 44. Je savais que la théorie disait cela ; regarder les colonnes de gauche rester plates pendant que celles de droite grimpent, c'est ce qui le fait atterrir.
- **La condition de Commoner gagne son salaire sur `handshake-started`.** Le graphe d'accessibilité de ce réseau est infini — l'analyseur abandonne à 500 marquages — et l'arbre de couverture ne peut que rapporter qu'il n'est pas borné et qu'aucune transition n'est morte. La condition siphon-et-trappe répond *vivant* quand même, dans le temps qu'il faut pour énumérer les sous-ensembles de trois places. C'est le premier endroit de ce cours où la méthode structurelle fait quelque chose que l'énumération ne peut pas faire du tout.

**Ce que je n'ai pas pu vérifier, et que j'ai marqué comme tel :**

- **Hack 1972** est l'endroit où le théorème de vivacité de Commoner pour les réseaux à choix libre est énoncé. La notice est confirmée sur DSpace@MIT — *Analysis of production schemata by Petri nets*, MIT-LCS-TR-094, février 1972, [handle 1721.1/149406](https://dspace.mit.edu/handle/1721.1/149406) — et le PDF est en accès libre, mais le téléchargement est derrière un contrôle anti-robot qui a refusé toutes mes requêtes, donc **je ne l'ai pas lu**. La formulation du théorème dans la leçon 6 vient de sources secondaires. Ce que la leçon affirme sur ses propres preuves est plus étroit et vérifié : la condition et le graphe d'accessibilité sont d'accord sur les quatre réseaux à choix libre de ce cours, et un test unitaire échoue s'ils cessent de l'être.
- **Commoner, Holt, Even et Pnueli 1971** pour les théorèmes sur les graphes marqués : notice confirmée via Crossref (*JCSS* 5(5), pages 511–523, [doi:10.1016/S0022-0000(71)80013-2](https://doi.org/10.1016/S0022-0000(71)80013-2)), article derrière le péage d'Elsevier, non lu.
- **Desel et Esparza 1995**, *Free Choice Petri Nets* : notice confirmée chez Cambridge Core, [doi:10.1017/CBO9780511526558](https://doi.org/10.1017/CBO9780511526558), non lu.
- **Jensen et Kristensen 2009** pour les réseaux colorés : notice confirmée via Crossref, [doi:10.1007/b95112](https://doi.org/10.1007/b95112), non lu. ISO/IEC 15909-1:2019, où la sous-classe des réseaux symétriques est définie, coûte toujours 227 CHF et n'est toujours pas lue.
- **Dijkstra 1971** pour les philosophes et l'ordonnancement des ressources : notice confirmée via Crossref, [doi:10.1007/BF00289519](https://doi.org/10.1007/BF00289519), non lu.
- L'exercice 3 de la leçon 7 — les philosophes avec un délai d'expiration — est argumenté, pas construit. Il est marqué *à vérifier* dans la leçon elle-même.

**Une chose qui est honnêtement plus faible qu'il n'y paraît.** Toute affirmation « aucun marquage énuméré » des leçons 5 et 6 est vraie de la *méthode*, et le même programme construit ensuite le graphe d'accessibilité quand même pour vérifier la méthode. C'est le bon sens pour un cours, et cela veut dire qu'aucune de ces leçons ne démontre la méthode sur un réseau où l'énumération échouerait réellement — sauf `handshake-started`, qui est le seul réseau ici dont le graphe n'existe pas.

## 2026-09-21 — Premier oracle exécutable de cycle de vie C#

La leçon 14 relie maintenant le modèle formel aux formes de panne mesurées dans les leçons 6 et 9 du C# avancé. J’ai ajouté un pipeline fini à une place avec des places explicites `succeeded`, `failed` et `cancelled`. Son graphe complet compte huit marquages et trois marquages morts ; chacun est une terminaison voulue, donc aucun marquage mort n’est non terminal. Cinq tests ciblés préservent cette classification et l’invariant de capacité `free + queued = 1`, et la fixture PNML est régénérée avec le reste du cours.

La correction importante était sémantique : `DeadStates` signifie qu’aucune transition n’est activée ; la fin réussie d’un workflow fini est donc morte elle aussi. « Sans interblocage » est le mauvais oracle pour un pipeline qui se termine. Le contrat exécutable devient un graphe complet dont chaque marquage mort porte exactement un jeton terminal nommé. La page indique aussi honnêtement que les exemples Channel en forme de GA reproduisent des mécanismes et ne sont pas des tests de régression des binaires actuels. RabbitMQ, Redis et Kubernetes restent des expériences ultérieures.

## À vérifier

- Hack 1972, la source du théorème de Commoner, est en accès libre et illisible par une requête automatisée. Le lire dans un navigateur permettrait à la leçon 6 de citer le théorème plutôt que de paraphraser une paraphrase.
- Murata 1989 reste payant et non lu ; chaque attribution qui lui est faite dans les leçons 1 à 8 est signalée dans la page.
- Leçon 7, exercice 3 : construire les philosophes avec un délai d'expiration et vérifier que le réseau est sans interblocage et possède une exécution infinie dans laquelle personne ne mange.
- L'affirmation que l'énumération des siphons minimaux est NP-difficile est énoncée dans la leçon 6 d'après des connaissances générales et n'est rattachée à aucun article.

## Questions ouvertes

- La force brute sur les sous-ensembles de places plafonne l'analyseur à vingt places. Six philosophes prenant une fourchette à la fois en ont vingt-quatre, donc le verdict structurel ne peut pas être calculé pour le plus gros réseau du tableau de la leçon 7 elle-même. Une formulation pour solveur de contraintes réglerait cela et rendrait le cours dépendant d'un solveur.
- Les réseaux colorés de la leçon 8 lient une variable par transition. Une transition qui joint deux messages a besoin d'un tuple, et le dépliage croîtrait comme un produit. Reste indécidé s'il faut l'implémenter à la leçon 12, où apparaît un vrai protocole, ou confier ce modèle à CPN Tools et le dire.
- La leçon 9 a besoin du temps, et le temps est l'endroit où un réseau cesse d'avoir une sémantique unique acceptée. Lequel des formalismes temporisés — les réseaux de Petri temporels au sens de Merlin, les réseaux temporisés au sens de Ramchandani, ou les stochastiques — ce cours enseigne en premier n'est pas tranché.
