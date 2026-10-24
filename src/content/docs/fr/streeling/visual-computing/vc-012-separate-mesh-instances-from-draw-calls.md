---
title: Distinguer instances de maillage et appels de dessin
description: Distinguer instances de maillage et appels de dessin — Informatique visuelle
sidebar:
  label: VC-012 · Distinguer instances de maillage et appels de dessin
  order: 12
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/visual-computing/fr/vc-012-separate-mesh-instances-from-draw-calls.fr.md
---

:::note[Streeling University]
**VC-012** · Distinguer instances de maillage et appels de dessin · intermédiaire · 40 minutes

Généré par le département *Informatique visuelle* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/visual-computing/fr/vc-012-separate-mesh-instances-from-draw-calls.fr.md) · [Mon journal](../../journal/)

Prérequis: [VC-009](../../visual-computing/vc-009-budget-brutal-scene-expansion/)
:::

> Brouillon à soumettre à une relecture humaine. Les cas fixes ci-dessous sont des modèles mathématiques rédigés après lecture des sources ; ce ne sont pas de nouvelles mesures du projet. Les avis techniques, artisanaux, linguistiques et pédagogiques restent en attente. Aucun moteur de scène, échantillon physique, GPU, exécuteur de politique ni essai avec un apprenant n’a été utilisé pour cette leçon.

## Question du projet

Les anciennes descriptions CPU de BRUTAL comptent instances de blocs et boîtes. Un agent peut-il convertir directement l’un de ces nombres en appels de dessin pour un aperçu Godot ? Une instance de bloc est un nœud descriptif ; une boîte est une primitive décrite ; une soumission de dessin relève d’un chemin de rendu. Le projet doit distinguer ces quantités avant d’invoquer le regroupement comme argument de performance.

[Prérequis: vc-009-budget-brutal-scene-expansion](../../visual-computing/vc-009-budget-brutal-scene-expansion/)

## Lire le périmètre avant de calculer

Lisez le prérequis et le document du projet avant de calculer. Distinguez les affirmations tirées du code inspecté, les résultats consignés antérieurement et les conséquences des seules hypothèses ci-dessous. Un commentaire de code, un corrigé préparé et une observation exécutée n’ont pas la même valeur probante. Conservez la date d’origine ainsi que tout contrôle échoué ou non concluant dans votre résumé d’un ancien document. La référence manuelle est un petit calcul sur papier accompagné d’un tableau des emplacements dans les sources ; un agent peut aider à trouver une définition, mais son résumé doit être confronté à celle-ci. Ce cas fini ne nécessite aucun nouveau langage ni automatisme.

Godot présente MultiMesh comme un mécanisme d’instanciation et précise que l’indexation spatiale traite le groupe comme un seul objet. Nous construisons un modèle limité : une surface, un matériau par groupe, un nombre de passes déclaré, toutes les instances visibles, aucune ombre ni travail supplémentaire. Le calcul compare des soumissions distinctes et regroupées selon ces hypothèses. Il ne prédit pas le compteur réel d’un moteur. Modifier les groupes ou les passes change le modèle. La description acceptée et la requête plus grande refusée du dossier restent des résultats CPU ; dériver un budget ne les transforme pas en banc d’essai graphique.

## Cas fixe et hypothèses

```text
historical_v1: block_instances=5; boxes=53; triangles=636
historical_v2: block_instances=5; boxes=85; triangles=1020
authored_instances=60; groups=3; passes=2
separate_submissions=60*2=120
grouped_submissions=3*2=6
reduction=120-6=114
control_groups=60; control_submissions=60*2=120
```

## Exercices corrigés

### Exercice 1

Quelle ancienne quantité change entre versions de colonne ?

> **Réponse:** Les boîtes passent de `53` à `85` ; les instances de blocs restent à `5`. Aucun de ces compteurs ne donne des appels observés.

### Exercice 2

Calculez le budget des soumissions séparées.

> **Réponse:** Il vaut `120` selon le modèle de passes et de visibilité stipulé. C’est un calcul, pas une observation GPU.

### Exercice 3

Calculez les soumissions regroupées et la réduction modélisée.

> **Réponse:** On obtient `6` soumissions regroupées et `114` de moins que dans le cas séparé. Cela ne donne pas le gain de temps par image.

### Exercice 4

Utilisez un groupe incompatible par instance. Que se passe-t-il ?

> **Réponse:** Le contrôle redonne `120` soumissions, supprimant la réduction modélisée. Réutiliser un maillage ne garantit pas le regroupement.

### Exercice 5

L’échange peut-il annoncer une scène regroupée plus rapide ?

> **Réponse:** Non. Il peut annoncer le modèle conditionnel. Le chemin réel exige compteurs mesurés, charge et comportement de visibilité ; un tri spatial grossier peut modifier le travail.

## Tâche assistée par les sources

Lisez les anciens compteurs et la documentation MultiMesh. Dressez un tableau assisté distinguant nœuds, boîtes, instances de maillage et soumissions modélisées ; laissez inconnus les appels mesurés. Comparez-le à un regroupement manuel. Une charge compatible exigeant d’autres soumissions réfuterait l’applicabilité du modèle.

Réalisez la tâche en masquant les corrigés. Gardez vos réponses initiales, les étapes de calcul, les emplacements dans les sources, les incertitudes et toutes les aides reçues, y compris un indice, un terme traduit ou une suggestion d’agent. Comparez ensuite avec les réponses préparées et consignez les corrections sans effacer votre premier essai. Rédigez une courte note de décision présentant l’affirmation, ses hypothèses, le calcul, le contrôle négatif et l’observation susceptible de la réfuter. Un résultat juste dépourvu d’unité ou d’identité de source ne suffit pas à démontrer le transfert. Le dossier comporte cinq critères préparés pour l’apprenant ; leur décision reste null tant qu’il n’existe pas d’essai réel et de relecture autorisée. La réussite de ces calculs établirait seulement une compétence sur le cas déclaré. Elle ne prouverait ni adaptateur opérationnel, ni procédé matériel réussi, ni moteur de rendu plus rapide, ni progrès d’apprentissage dans le projet. Comparez votre note assistée à la référence manuelle : si l’aide masque une hypothèse ou supprime un refus, corrigez la note avant de proposer un changement de méthode.

## Sources et journal de validation

- [Document du projet](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/brutal-composition-2026-10-22/composition-calculations.json)
- [Source primaire](https://docs.godotengine.org/en/4.6/classes/class_multimesh.html)
- [Dossier de preuves fixes](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/unit-c.json)
- [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/journal.md)
