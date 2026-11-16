---
title: Distinguer identité stable d’un cours et titre affiché
description: Distinguer identité stable d’un cours et titre affiché — Sémiotique
sidebar:
  label: SEM-010 · Distinguer identité stable d’un cours et titre affiché
  order: 10
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/semiotics/fr/sem-010-distinguish-stable-course-identity-from-display-names.fr.md
---

:::note[Streeling University]
**SEM-010** · Distinguer identité stable d’un cours et titre affiché · intermédiaire · 40 minutes

Généré par le département *Sémiotique* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/semiotics/fr/sem-010-distinguish-stable-course-identity-from-display-names.fr.md) · [Mon journal](../../journal/)

Prérequis: [SEM-004](../../semiotics/sem-004-face-identity-under-reindexing/), [DV-008](../../data-visualization/dv-008-streeling-evidence-stage-map/)
:::

> Brouillon à soumettre à une relecture humaine. Les cas fixes ci-dessous sont des modèles mathématiques rédigés après lecture des sources ; ce ne sont pas de nouvelles mesures du projet. Les avis techniques, artisanaux, linguistiques et pédagogiques restent en attente. Aucun moteur de scène, échantillon physique, GPU, exécuteur de politique ni essai avec un apprenant n’a été utilisé pour cette leçon.

## Question du projet

Learn traduit le titre d’un cours puis en révise la formulation. Cela doit-il créer un nouveau cours, une nouvelle langue ou une nouvelle version du contenu ? Le lecteur figé extrait métadonnées et titre, tandis que la clé de module retire les suffixes linguistiques des fichiers. Il faut interpréter ces signes sans compter les traductions comme de nouveaux cours. L’identité de source et le libellé humain répondent à des questions différentes.

[Prérequis: sem-004-face-identity-under-reindexing](../../semiotics/sem-004-face-identity-under-reindexing/); [Prérequis: dv-008-streeling-evidence-stage-map](../../data-visualization/dv-008-streeling-evidence-stage-map/)

## Lire le périmètre avant de calculer

Lisez le prérequis et le document du projet avant de calculer. Distinguez les affirmations tirées du code inspecté, les résultats consignés antérieurement et les conséquences des seules hypothèses ci-dessous. Un commentaire de code, un corrigé préparé et une observation exécutée n’ont pas la même valeur probante. Conservez la date d’origine ainsi que tout contrôle échoué ou non concluant dans votre résumé d’un ancien document. La référence manuelle est un petit calcul sur papier accompagné d’un tableau des emplacements dans les sources ; un agent peut aider à trouver une définition, mais son résumé doit être confronté à celle-ci. Ce cas fini ne nécessite aucun nouveau langage ni automatisme.

Utilisez un tableau construit avec identité stable, langue, titre et révision. Comptez les identités distinctes pour l’inventaire, les couples identité-langue pour la couverture et les révisions pour le suivi des versions. Deux titres peuvent être identiques tout en désignant des cours différents ; deux titres différents peuvent traduire un même cours. Inversement, réutiliser une identité ne prouve pas que le contenu soit inchangé. Le helper fournit une convention d’indexation, pas une garantie globale d’unicité chez tous les producteurs. Il faut encore détecter les doublons et lier la relecture à la source exacte.

## Cas fixe et hypothèses

```text
rows=[
 {"id":"course-a","locale":"en","title":"Clearance","revision":"r1"},
 {"id":"course-a","locale":"fr","title":"Jeu","revision":"r1"},
 {"id":"course-a","locale":"es","title":"Holgura","revision":"r1"},
 {"id":"course-b","locale":"en","title":"Clearance","revision":"r1"}
]
rows_count=4; distinct_ids=2; distinct_id_locale_pairs=4
rename_course_a_en_title="Panel Clearance"
renamed_distinct_ids=2
control_duplicate={"id":"course-a","locale":"en","revision":"r2"}
```

## Exercices corrigés

### Exercice 1

Comptez les identités et les lignes de couverture linguistique.

> **Réponse:** On compte `2` identités et `4` couples identité-langue. Le nombre de lignes n’est pas le nombre de cours distincts.

### Exercice 2

Renommez le premier titre affiché. Quel effectif d’inventaire change ?

> **Réponse:** Aucun ne change : les identités restent `2` et les couples `4`. Un titre modifié change toutefois les octets relus et peut exiger un nouveau contrôle.

### Exercice 3

Des titres identiques permettent-ils de fusionner les identités ?

> **Réponse:** Non. Le mot affiché commun ne prouve pas une identité commune. Gardez les deux clés et examinez séparément les doublons éventuels.

### Exercice 4

Ajoutez le doublon de contrôle. La couverture augmente-t-elle ?

> **Réponse:** Les lignes passent à `5`, mais les couples distincts restent `4`. Le couple répété porte des révisions divergentes : il faut les réconcilier, pas créditer une autre traduction.

### Exercice 5

Une identité stable transfère-t-elle une approbation aux octets modifiés ?

> **Réponse:** Non. L’identité assure la correspondance ; la relecture porte sur un contenu exact. Gardez empreintes et avis applicables séparément des titres.

## Tâche assistée par les sources

Inspectez parseModule et moduleKey dans le helper Learn figé. Suivez manuellement un cours existant et ses traductions à travers nom de fichier, métadonnées et titre. Comparez le comptage assisté au tableau des clés distinctes. Compter un titre renommé ou une langue en doublon comme nouveau cours réfute la règle proposée.

Réalisez la tâche en masquant les corrigés. Gardez vos réponses initiales, les étapes de calcul, les emplacements dans les sources, les incertitudes et toutes les aides reçues, y compris un indice, un terme traduit ou une suggestion d’agent. Comparez ensuite avec les réponses préparées et consignez les corrections sans effacer votre premier essai. Rédigez une courte note de décision présentant l’affirmation, ses hypothèses, le calcul, le contrôle négatif et l’observation susceptible de la réfuter. Un résultat juste dépourvu d’unité ou d’identité de source ne suffit pas à démontrer le transfert. Le dossier comporte cinq critères préparés pour l’apprenant ; leur décision reste null tant qu’il n’existe pas d’essai réel et de relecture autorisée. La réussite de ces calculs établirait seulement une compétence sur le cas déclaré. Elle ne prouverait ni adaptateur opérationnel, ni procédé matériel réussi, ni moteur de rendu plus rapide, ni progrès d’apprentissage dans le projet. Comparez votre note assistée à la référence manuelle : si l’aide masque une hypothèse ou supprime un refus, corrigez la note avant de proposer un changement de méthode.

## Sources et journal de validation

- [Document du projet](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)
- [Source primaire](https://github.com/spareilleux/learn/blob/8f13637ae4596b614c2ba493b596b6a08e1cf43a/scripts/streeling-lib.mjs)
- [Dossier de preuves fixes](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/unit-c.json)
- [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/journal.md)
