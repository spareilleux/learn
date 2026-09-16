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
- [ ] Leçon 5 — Invariants
- [ ] Leçon 6 — Classes structurelles
- [ ] Leçon 7 — Modéliser la concurrence
- [ ] Leçon 8 — Réseaux colorés
- [ ] Leçon 9 — Temps et probabilités
- [ ] Leçon 10 — Workflows
- [ ] Leçon 11 — Outils et interopérabilité
- [ ] Leçon 12 — Applications industrielles
- [ ] Leçon 13 — Face aux autres formalismes
- [ ] Leçon 14 — Sur nos propres systèmes
- [ ] Leçon 15 — Limites et suite

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
