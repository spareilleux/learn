---
title: Croiser timbre et intervalle dans une épreuve d’oreille
description: Croiser timbre et intervalle dans une épreuve d’oreille — Guitar Alchemist Academy
sidebar:
  label: GAA-012 · Croiser timbre et intervalle dans une épreuve d’oreille
  order: 12
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-alchemist-academy/fr/gaa-012-cross-timbre-with-interval-in-an-ear-trial.fr.md
---

:::note[Streeling University]
**GAA-012** · Croiser timbre et intervalle dans une épreuve d’oreille · intermédiaire · 55 minutes

Généré par le département *Guitar Alchemist Academy* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-alchemist-academy/fr/gaa-012-cross-timbre-with-interval-in-an-ear-trial.fr.md) · [Mon journal](../../journal/)

Prérequis: [GAA-002](../../guitar-alchemist-academy/gaa-002-training-your-ear/)
:::

> Exemple construit et lecture de sources. Aucune nouvelle prestation, exécution audio ou de parseur, réponse de participant ni adoption en production n’est revendiquée. Les décisions techniques humaines, linguistiques et pédagogiques restent en attente.

Un guitariste peut sembler reconnaître un intervalle alors qu’il reconnaît le son qui lui est associé. Si chaque tierce majeure utilise un timbre et chaque quarte un autre, la réponse se devine sans comparer les hauteurs. GA devrait révéler ce défaut avant d’annoncer une compétence d’écoute. Nous construisons un petit plan croisé dont la couverture se vérifie sans produire d’audio ; validité musicale et apprentissage restent distincts.

## Lire les preuves conservées

Lire les règles d’indices du dossier : chaque tâche révèle ou cache volontairement certaines étiquettes. Le principe vaut aussi pour les indices sonores involontaires. NIST définit un plan factoriel complet par le croisement de chaque modalité avec toutes celles des autres facteurs. Nous utilisons cette propriété combinatoire, sans emprunter de résultat expérimental ni prétendre que l’ordre a été randomisé.

[Prérequis](../../guitar-alchemist-academy/gaa-002-training-your-ear/)

[Artefact de projet conservé](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/practice-outcomes-2026-10-22/practice-items.json)

[Dossier construit fixe](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/unit-a.json)

[Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/journal.md)

[Lecture primaire](https://www.itl.nist.gov/div898/handbook/pri/section3/pri333.htm)

### Exercice 1

Déclarer les intervalles `[M3,P4]` et les timbres `[nylon,steel]`. Leur produit cartésien comporte `4` cellules, ordonnées par intervalle puis timbre. Ce tableau n’affirme ni distinction perceptive des timbres synthétiques ni difficulté égale des intervalles. Il faudrait de vrais stimuli et auditeurs pour répondre à ces questions.

Énumérer les cellules dans l’ordre déclaré.

<details><summary>Réponse 1</summary>

Ce sont `[(M3,nylon),(M3,steel),(P4,nylon),(P4,steel)]`. Cet ordre rattache les vecteurs de comptes aux bonnes conditions.

</details>

### Exercice 2

Attribuer `2` essais à chaque cellule. Le vecteur `[2,2,2,2]` totalise `8`. Chaque intervalle apparaît avec chaque timbre : l’affectation ne permet plus au timbre de déterminer parfaitement la réponse. Cela élimine ce raccourci déterministe du tableau, sans garantir l’absence d’autres indices.

Quels sont le total et le nombre de cellules couvertes ?

<details><summary>Réponse 2</summary>

Il y a `8` essais et `4` cellules couvertes. Tous les comptes sont égaux et positifs : ce plan construit est complet et équilibré.

</details>

### Exercice 3

L’équilibre ne définit ni niveau, registre, direction, durée ni visibilité de la réponse. Chaque dimension peut devenir un indice. Préciser ce qui reste fixe ou varie et conserver l’identité réelle des stimuli. Un moteur qui ignorerait le timbre échouerait à un autre contrôle de fidélité, même avec un tableau prévu équilibré.

L’équilibre valide-t-il à lui seul une expérience d’écoute ?

<details><summary>Réponse 3</summary>

Non. Le tableau définit les affectations. Stimuli réels, contrôle des indices, lecture et réponses doivent encore être observés ; les comptes ne prouvent ni apprentissage ni équivalence perceptive.

</details>

### Exercice 4

Le contrôle négatif place `4` essais dans `(M3,nylon)` et `4` dans `(P4,steel)`, sans les autres cellules. Le vecteur est `[4,0,0,4]`. Il reste `8` essais et des marges équilibrées pour chaque facteur. Pourtant seulement `2` cellules sont couvertes : le timbre identifie parfaitement la réponse dans cette affectation.

Pourquoi des marges égales manquent-elles la confusion ?

<details><summary>Réponse 4</summary>

Elles ignorent les associations. Le contrôle ne couvre que `2` des `4` cellules ; intervalle et timbre restent parfaitement liés malgré les totaux marginaux égaux.

</details>

### Exercice 5

Un agent peut vérifier le tableau et conserver la graine d’un ordre randomisé si une expérience l’utilise réellement. Il ne doit pas inventer mélange, lecture réussie ou réponses. Avant d’interpréter un score, comparer stimulus joué et cellule prévue, conserver les aides et prévoir des exemples nouveaux si l’objectif est le transfert.

Qu’est-ce qui réfute un croisement complet des facteurs ?

<details><summary>Réponse 5</summary>

Une cellule requise sans essai réfute la complétude. Le contrôle en fournit le témoin ; une affirmation de production exige aussi la preuve des stimuli réellement lus.

</details>

## Tâche avec consultation des sources

Dessiner à la main les deux tableaux avec leurs marges. Inspecter les règles d’indices et proposer un autre indice involontaire à maîtriser pour cette tâche. Décrire un enregistrement de stimulus conservant intervalle, timbre et identité du fichier réel. Définir un réfutateur de couverture avant l’aide d’un agent ; laisser randomisation, écoute et résultats d’apprentissage non exécutés.

Conserver d’abord votre réponse avant de révéler les corrections préparées. Prendre le tableau ou calcul manuel comme référence pour toute calculatrice, consultation ou aide d’agent, et consigner cette aide. Garder réponse initiale et réponse corrigée séparément. Relier chaque exercice à un critère préparé du dossier ; aucune décision d’apprenant n’est encore prise. Noter un passage réellement lu et sa révision, puis distinguer ce qu’il établit de la prochaine étape proposée. Signaler toute entrée manquante comme non résolue. Une réponse mathématique juste soutient cet exemple ; revue humaine, exécution réelle et acceptation de l’apprenant demandent leurs propres observations conservées.
