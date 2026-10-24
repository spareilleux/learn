---
title: Interpréter l'ordre des couches par rapport à la normale de référence
description: Interpréter l'ordre des couches par rapport à la normale de référence — Sémiotique
sidebar:
  label: SEM-008 · Interpréter l'ordre des couches par rapport à la normale de référence
  order: 8
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/semiotics/fr/sem-008-interpret-layer-order-relative-to-the-reference-normal.fr.md
---

:::note[Streeling University]
**SEM-008** · Interpréter l'ordre des couches par rapport à la normale de référence · intermédiaire · 40 minutes

Généré par le département *Sémiotique* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/semiotics/fr/sem-008-interpret-layer-order-relative-to-the-reference-normal.fr.md) · [Mon journal](../../journal/)

Prérequis: [SEM-004](../../semiotics/sem-004-face-identity-under-reindexing/), [SEM-006](../../semiotics/sem-006-preserve-orientation-across-scene-frames/)
:::

> **Portée du brouillon.** Tables de signes pédagogiques et lecture des sources FOLD/IX à une révision précise. Aucun nouvel adaptateur, transformation de scène ou test natif n'ont été exécutés. Les revues humaines technique, artisanale, linguistique et pédagogique restent à effectuer ; la vérification du HTML du cours déployé est distincte.

## La question du projet

Un agent peut-il traduire « au-dessus » en signe d'ordre des couches sans conserver la normale de référence ? [SEM-004](../../semiotics/sem-004-face-identity-under-reindexing/) préserve l'identité des faces lors des changements d'indices ; [SEM-006](../../semiotics/sem-006-preserve-orientation-across-scene-frames/) suit l'orientation à travers les repères. Ce cours déduit une autre règle : le sens du signe dépend de la face qui fournit la normale de référence.

La [spécification FOLD à la révision fixée](https://github.com/edemaine/fold/blob/824f9fa6f944248787b0b2077ef622761489201e/doc/spec.md#L346-L377), présentée comme un brouillon préliminaire de version 1.2, définit `[f,g,s]` par rapport à la normale de la seconde face. Pour `s=+1`, la face `f` est du côté indiqué par la normale de la face `g`. Pour `s=-1`, elle est du côté opposé. Ce n'est pas un indicateur de hauteur absolue dans le monde.

## 1. Convertir vers une direction globale déclarée

Pour un exemple pédagogique de couches planes, posons `d` à +1 lorsque `f` est au-dessus de `g` par rapport à un axe global vertical choisi, et à -1 sinon. Notons `sigma_f` et `sigma_g` les signes des normales des faces par rapport à ce même axe. Les deux doivent être connus et non nuls dans cet exemple simplifié. Le signe relatif est `s=d*sigma_g`, donc `d=s*sigma_g`.

### Exercice 1 : identifier la face de référence

Pour `[2,5,+1]`, déterminez l'ordre global lorsque la normale de la face 5 pointe vers le haut puis vers le bas. Quelle face fournit la normale ?

> **Réponse:** La face 5 fournit la normale de référence. Avec `sigma_g=+1`, l'ordre global est `d=+1` ; avec `sigma_g=-1`, il est `d=-1`. La même relation positive peut signifier des ordres globaux opposés. Les positions des arguments et la direction de référence sont des informations nécessaires.

## 2. Permuter les arguments n'inverse pas toujours le signe

Écrivez la relation permutée sous la forme `[g,f,t]`. Son ordre global est `-d`, désormais mesuré par rapport à la normale de l'autre face. Ainsi, `t=-d*sigma_f=-s*sigma_f*sigma_g`. Des normales de même direction exigent le signe opposé ; des normales de directions opposées exigent le même signe. Cela concorde avec la règle de permutation des triplets de la spécification.

### Exercice 2 : permuter une relation concrète

Utilisez `[2,5,+1]`, `sigma_g=-1` et `sigma_f=+1`. Trouvez `d` et le signe après permutation. Précisez ensuite ce qui se passe si les deux normales ont plutôt des signes égaux.

> **Réponse:** L'ordre global est `d=-1` ; le signe après permutation est `t=+1`, donnant `[5,2,+1]`. Les normales opposées expliquent le signe inchangé. Avec des normales de même signe, le signe après permutation serait plutôt `t=-1`. Inverser aveuglément le signe à chaque permutation d'arguments est incorrect.

## 3. Retourner l'objet entier

Lors d'un retournement de l'objet entier par rapport au même axe global vertical, l'ordre global et les deux signes de normales s'inversent. Par conséquent, `s'=(-d)*(-sigma_g)=s` : le signe relatif stocké reste inchangé. Cette opération diffère du remplacement de l'étiquette d'un argument ou d'un changement de définition du « haut ».

Les [commandes d'IX à la révision fixée](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/crates/ix-origami/src/controls.rs#L82-L107) implémentent un déplacement plan séparément du retournement. Le retournement prend l'opposé des coordonnées y pliées tout en conservant les triplets bruts d'ordre des faces ; ses commentaires expliquent l'inversion conjointe de l'orientation et du haut. C'est une preuve issue du code, et non une nouvelle exécution ou une correspondance universelle avec l'axe vertical d'une scène hôte.

### Exercice 3 : rejeter une inversion systématique du signe

Partez de `d=+1`, `sigma_g=+1` et `s=+1`. Retournez le modèle entier. Si un adaptateur inverse aussi le signe stocké, quel ordre global impliquerait-il ?

> **Réponse:** Les nouvelles valeurs correctes sont `d'=-1`, `sigma_g'=-1` et `s'=+1` inchangé. Stocker incorrectement `s'=-1` impliquerait `d'=s'*sigma_g'=+1`, contredisant le retournement visé. La géométrie et ses normales de référence doivent être interprétées ensemble.

## 4. Distinguer des changements de bits égaux d'actions égales

Pour un croisement de tissage, un indicateur de rôle `warp_over` demande si le brin actuellement appelé chaîne est plus haut selon la direction de scène choisie. Recolorer ne change ni le rôle ni l'ordre. Renommer chaîne et trame complémente l'indicateur tout en laissant l'ancien brin physique de chaîne à la même hauteur. Retourner l'objet entier en conservant les noms des rôles complémente aussi l'indicateur, mais inverse la relation de hauteur globale de cet ancien brin.

Le [relevé pédagogique des relations](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/weave-material-2026-10-22/layer-relations.json) conserve 8 combinaisons de signes et des fiches distinctes de croisements pour `w2-f0` et `w3-f0`. Ce sont des exemples sémantiques finis, et non des modifications réelles de la scène enregistrée. Un indicateur de rôle et un triplet FOLD relatif à la normale répondent à des questions différentes.

### Exercice 4 : distinguer trois modifications

Un croisement a initialement la chaîne au-dessus de la trame. Comparez une recoloration, une permutation des noms de rôles et un retournement de l'objet entier. Un booléen complémenté permet-il d'identifier l'opération effectuée ?

> **Réponse:** La recoloration laisse l'indicateur et l'ordre physique inchangés. Une permutation des noms de rôles complémente l'indicateur mais préserve la hauteur de l'ancienne chaîne physique. Le retournement de l'objet entier avec conservation des noms complémente l'indicateur et inverse cette relation de hauteur. Un booléen complémenté seul ne permet pas d'identifier l'opération ; conservez les identités des brins, l'affectation des rôles, le repère et la provenance de la transformation.

## 5. Préserver l'ordre inconnu et la portée du code

Dans la spécification à la révision fixée, `s=0` signifie un ordre inconnu ; une paire omise est elle aussi inconnue. Aucun des deux ne signifie une hauteur égale ou une absence d'intersection confirmée. Le [module de couches d'IX à la révision fixée](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/crates/ix-origami/src/layers.rs#L1-L16) vérifie les relations de couches fournies ; il ne calcule pas un ordre complet. Une vérification acceptée ne peut donc pas compléter chaque relation absente.

### Exercice 5 : préparer une transmission avec accès aux sources

Lisez la spécification et les commandes et le module d'IX. Un agent émet « la face 2 est au-dessus de la face 5 » à partir d'une relation omise, puis propose un nouveau DSL. Quelle est la correction utile minimale et quelles preuves manquent encore ?

> **Réponse:** Gardez l'ordre inconnu. Pour une relation connue, conservez la révision du code, l'identité des faces, les rôles ordonnés des arguments, la définition du signe, les informations pertinentes de normales et de repères et toute transformation. Un relevé typé accompagné d'un validateur fondé sur une table peut suffire ; un nouveau DSL exige un avantage démontré. Les vérifications sélectionnées ne déduisent pas l'ordre manquant et n'établissent pas la réalisabilité physique. Aucun adaptateur ou nouvelle vérification native n'ont été livrés ici.
