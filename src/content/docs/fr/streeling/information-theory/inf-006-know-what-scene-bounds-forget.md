---
title: Comprendre ce que les bornes d'une scène oublient
description: Comprendre ce que les bornes d'une scène oublient — Théorie de l'information
sidebar:
  label: INF-006 · Comprendre ce que les bornes d'une scène oublient
  order: 6
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/information-theory/fr/inf-006-know-what-scene-bounds-forget.fr.md
---

:::note[Streeling University]
**INF-006** · Comprendre ce que les bornes d'une scène oublient · intermédiaire · 40 minutes

Généré par le département *Théorie de l'information* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/information-theory/fr/inf-006-know-what-scene-bounds-forget.fr.md) · [Mon journal](../../journal/)

Prérequis: [INF-004](../../information-theory/inf-004-information-loss-in-agent-handoffs/), [VC-009](../../visual-computing/vc-009-budget-brutal-scene-expansion/)
:::

> **Périmètre du brouillon.** Nouveaux appels CPU de validation et de calcul des bornes sur des brouillons BRUTAL conçus pour l'exercice, complétés par des calculs exacts de géométrie idéale et d'information selon une distribution a priori finie. Les revues technique, linguistique et pédagogique humaines, ainsi que la vérification du HTML du cours déployé, restent à faire. Aucun moteur de rendu, moteur de collision, adaptateur Blender/Godot ni GPU n'a été exécuté.

## La question du projet

Un agent reçoit deux boîtes de scène et une boîte englobante alignée sur les axes, puis affirme que la scène n'a pas changé. Le résumé peut suffire à cadrer un aperçu, mais il ne détermine pas toute la géométrie intérieure. Cette leçon rend la perte d'information concrète avant de choisir ce que les agents doivent échanger.

Le [modèle Scene de BRUTAL à la révision inspectée](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Lego/Model.fs#L236-L257) transforme les huit coins de chaque boîte locale et en extrait les minima et maxima composante par composante. Ses boîtes reposent sur le sol : X/Z s'étendent d'une demi-dimension de chaque côté, et Y va de zéro à la hauteur. [VC-009](../../visual-computing/vc-009-budget-brutal-scene-expansion/) explique le budget de boîtes, qui est distinct. Ici, l'égalité du budget et des bornes dissimulera délibérément une différence géométrique.

## 1. Trouver tous les extrema transformés

Pour le lacet enfant de 45 degrés sous une échelle parent de `(2,1,1)` construit pour l'exercice, une boîte unitaire reposant sur le sol a pour minimum global `(-sqrt2,0,-1/sqrt2)` et pour maximum `(sqrt2,1,1/sqrt2)`. Les [cas natifs réellement exécutés](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/scene-frames-2026-10-22/native-cases.json) conservent les bornes en float32. Un calcul exact indépendant et une formule fondée sur les valeurs absolues des composantes de la base concordent dans la tolérance déclarée de `1e-5`.

Transformer seulement les deux extrémités locales opposées `(-0.5,0,-0.5)` et `(0.5,1,0.5)` donnerait au contraire Z égal à zéro en calcul exact, et manquerait les extrema des autres coins. Une application affine ne conserve pas nécessairement l'identité du coin qui maximise une coordonnée. La [comparaison des bornes](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/scene-frames-2026-10-22/bounds-comparison.json) conserve ce raccourci qui échoue. Ces affirmations concernent les boîtes soumises à des transformations affines, pas une perspective générale ni une déformation non linéaire.

### Exercice pratique 1 : rejeter le raccourci des deux coins

Quel intervalle Z doit couvrir la boîte transformée complète, et quel intervalle annonce le raccourci des extrémités opposées ? Pourquoi ce dernier n'est-il pas une borne conservative ?

> **Réponse:** L'intervalle Z exact complet va de `-1/sqrt2` à `1/sqrt2` ; le raccourci ne donne que zéro. Il exclut des coins réellement transformés et ne peut donc pas envelopper cette boîte de façon sûre. Transformer les huit coins, ou utiliser une formule équivalente valide pour une boîte affine, traite ce cas ; vérifier deux extrémités ne suffit pas.

## 2. Construire deux scènes ayant un résumé commun

Utilisons l'orientation identité et le mètre dans cet exemple pédagogique à deux scènes :

| Scène | Dimensions des boîtes | Translations X | Translation Y/Z |
| --- | --- | --- | --- |
| A | `(1,2,2)` pour chaque boîte | -0.5 et 0.5 | 0 pour les deux axes |
| B | `(0.2,2,2)` pour chaque boîte | -0.9 et 0.9 | 0 pour les deux axes |

Le véritable validateur public accepte les deux brouillons pédagogiques, et les propriétés natives de Scene renvoient un nombre de boîtes de 2 et les mêmes bornes : minimum `(-1,0,-1)`, maximum `(1,2,1)`. La scène A remplit cette boîte de deux moitiés jointives. La scène B laisse un vide intérieur entre de minces plaques latérales. Le [relevé du contre-exemple](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/scene-frames-2026-10-22/summary-counterexample.json) distingue les observations natives de la géométrie idéale exacte fondée sur les décimaux. Il n'affirme pas que les dimensions représentées en float32 ont des volumes rationnels exacts.

### Exercice pratique 2 : retrouver ce que le résumé omet

Calculez le volume idéal de l'union de chaque scène et le volume de leur boîte englobante commune. L'égalité du nombre de boîtes et des bornes établit-elle l'égalité de la géométrie ou une collision de hachage de scène ?

> **Réponse:** La scène A a pour volume `2*1*2*2=8` ; B a pour volume `2*0.2*2*2=1.6`, soit `8/5`. Le volume de leur boîte englobante commune est `2*2*2=8`. Le même résumé par le nombre et les bornes ne détermine donc pas l'intérieur. Aucune égalité ni collision de hachage des scènes complètes n'a été affirmée ou mesurée.

## 3. Une borne peut éliminer un candidat sans prouver un contact

Utilisons des boîtes fermées pour ces tests d'appartenance conçus pour l'exercice. Le centre `(0,1,0)` appartient à l'union A, sur la frontière commune des deux moitiés, et se trouve hors de B, bien que les deux boîtes englobantes globales l'incluent. Le témoin extérieur `(1.2,1,0)` se trouve hors des deux. Il s'agit de tests pédagogiques d'appartenance de points à ces unions de boîtes, pas de l'exécution d'un test de collision en production.

Lorsque deux bornes globales sont disjointes dans le même repère et les mêmes unités déclarés, les géométries qu'elles enveloppent ne peuvent pas se chevaucher. La réciproque est fausse : des bornes qui se chevauchent peuvent envelopper des géométries séparées. Les conventions de frontière comptent aussi pour un contact exact. Un candidat issu de la phase large justifie une vérification plus précise ; ce n'est ni une collision confirmée ni une garantie de jeu pour la fabrication.

### Exercice pratique 3 : interpréter un résultat positif de phase large

Un agent utilise seulement la borne globale de B pour affirmer qu'il y a de la matière au centre. Donnez le contre-exemple et une conclusion utile que la même borne peut encore soutenir.

> **Réponse:** Les plaques latérales de B laissent le centre `(0,1,0)` vide, alors que sa borne globale inclut ce point. La borne peut rejeter `(1.2,1,0)` comme extérieur à toute la géométrie enveloppée. Un test positif portant uniquement sur la borne globale ne peut établir ni une présence de matière, ni un contact entre surfaces, ni un jeu physique.

## 4. Quantifier la perte selon une distribution a priori déclarée

Pour un exemple de théorie de l'information volontairement restreint, supposons que A et B soient les seules possibilités, chacune de probabilité 0.5. L'entropie initiale du choix de scène vaut 1 bit. Le message contient seulement le nombre 2 et les bornes communes. Les deux possibilités produisent ce message : l'entropie conditionnelle du choix de scène reste donc de 1 bit, et l'information mutuelle sur le choix vaut 0 bits.

Ajoutons le résultat déclaré d'appartenance du centre. Il est vrai pour A et faux pour B ; selon cette distribution a priori à deux possibilités, il identifie donc la scène : l'entropie conditionnelle devient 0 et l'information mutuelle devient 1 bit. Cela ne signifie pas qu'un bit identifie toute scène, ni que les bornes sont inutiles pour une autre tâche. Les possibilités et leur distribution a priori définissent le calcul.

### Exercice pratique 4 : énoncer précisément l'affirmation informationnelle

Calculez l'entropie initiale, l'entropie conditionnelle après le résumé commun et l'information mutuelle. Comment ces valeurs évoluent-elles après le test du centre, et quelle hypothèse empêche de généraliser ce résultat à toutes les scènes ?

> **Réponse:** On a initialement 1 bit, puis 1 bit d'entropie conditionnelle et 0 bits d'information mutuelle après le résumé commun. Ajouter le résultat au centre donne 0 bits conditionnels et 1 bit d'information mutuelle. Ces valeurs reposent sur exactement deux possibilités équiprobables aux réponses déterministes indiquées. Elles ne constituent ni une entropie générale des scènes, ni un taux de compression mesuré, ni un codage universel sur un bit.

## 5. Choisir un message pour la décision réelle

Pour le cadrage d'une caméra, la borne commune peut suffire. Pour la présence de matière, le destinataire a besoin de la géométrie appropriée ou d'un résultat de requête justifié. Pour l'ombrage ou l'interprétation des côtés, [PHY-008](../../physics/phy-008-keep-surface-normals-perpendicular/) et [SEM-006](../../semiotics/sem-006-preserve-orientation-across-scene-frames/) recensent d'autres distinctions manquantes. Un résumé doit déclarer la question à laquelle il peut répondre et conserver le contexte de source, de repère et d'unités.

La principale objection à l'envoi systématique de toute la géométrie est son coût de transfert et d'inspection. Une alternative plus simple est un résumé limité à la tâche, accompagné d'un moyen de demander davantage de preuves. Notre test du centre suffit au choix pédagogique ; ce n'est pas un protocole général de requête implémenté. [INF-004](../../information-theory/inf-004-information-loss-in-agent-handoffs/) explique pourquoi une transmission économique doit tout de même préserver les distinctions nécessaires au destinataire.

### Exercice pratique 5 : concevoir une transmission suffisante

Le destinataire a d'abord besoin d'un cadrage de caméra, puis demande s'il y a de la matière au centre. Que doit conserver ou ajouter l'agent à chaque étape ? Énoncez un critère qui conduirait à rejeter le résumé proposé pour une nouvelle tâche.

> **Réponse:** Conservez la borne avec son repère, ses unités et son contexte source pour le cadrage. Ajoutez le résultat d'appartenance du centre, dont le périmètre est explicite, et sa justification géométrique pour la question suivante, ou fournissez la géométrie pertinente pour un véritable test précis. Rejetez le résumé comme insuffisant lorsque deux scènes admissibles produisent le même message mais exigent des réponses différentes à la tâche du destinataire. Aucun nouvel adaptateur, service de requête en production ni résultat d'exécution dans un hôte n'a été implémenté ici.
