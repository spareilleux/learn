---
title: Dire ce qu’une vue artisanale ne peut pas distinguer
description: Dire ce qu’une vue artisanale ne peut pas distinguer — Philosophie
sidebar:
  label: PHI-010 · Dire ce qu’une vue artisanale ne peut pas distinguer
  order: 10
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/philosophy/fr/phi-010-state-what-a-craft-view-cannot-distinguish.fr.md
---

:::note[Streeling University]
**PHI-010** · Dire ce qu’une vue artisanale ne peut pas distinguer · intermédiaire · 45 minutes

Généré par le département *Philosophie* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/philosophy/fr/phi-010-state-what-a-craft-view-cannot-distinguish.fr.md) · [Mon journal](../../journal/)

Prérequis: [PHI-008](../../philosophy/phi-008-separate-a-test-oracle-from-a-specification/)
:::

> Brouillon soumis à une revue technique et linguistique. Chaque scène, nombre, température, durée et résultat introduit ci-dessous est un exemple construit. La lecture des sources et les calculs ne constituent ni un essai physique, ni un import [Godot](https://docs.godotengine.org/en/4.5/), ni un rendu [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), ni une exécution [ComfyUI](https://docs.comfy.org/), ni une observation d’apprentissage. Les décisions humaines et celles liées à l’exécution restent en attente.

## Question du projet

Une sculpture en origami ou en relief correspond à une référence de face ; un agent la déclare alors entièrement fidèle. Pourtant l’observation peut supprimer le caractère visé par l’exigence. Nous construisons deux candidats à vue simplifiée identique mais à profondeur différente. La leçon prolonge la distinction oracle-spécification en montrant précisément quelle différence la fonction d’observation ne transmet pas.

## Lire la limite conservée

Le pipeline demande des vues tournantes, mais ces arguments ne relient pas à eux seuls chaque vue à tous les éléments signifiants. Godot distingue perspective et orthographique. Notre projection idéale est une fonction mathématique pédagogique, pas une capture produite par un hôte.

Lisez le prérequis et l’artefact conservé avant d’interpréter le modèle. La source a sa propre révision et son propre objectif ; elle fournit la limite décrite ici, pas les nouvelles données pédagogiques. Dressez un tableau distinguant un champ inspecté, une hypothèse, une quantité calculée et un effet envisagé dans la scène. Le résumé d’un agent doit renvoyer au champ interprété. Un nom de fichier ne suffit pas à établir un résultat antérieur.

## Interpréter le modèle

Une observation transforme un objet candidat en résultat inspectable. Si plusieurs candidats donnent le même résultat, cet accord n’établit pas une propriété sur laquelle ils diffèrent. Ici, la fonction supprime volontairement la profondeur. Le témoin réfute l’inférence universelle entre accord de face et respect de la profondeur. Il ne rend pas les vues de face inutiles : elles peuvent renseigner les coordonnées conservées. Une observation supplémentaire doit viser la différence perdue. Accumuler des images sans relation déclarée avec l’exigence peut augmenter le volume des preuves sans combler la lacune logique.

La référence directe est un croquis légendé et un calcul manuel, réalisés sans ouvrir les réponses. Conservez les valeurs intermédiaires et les unités, puis appliquez l’entrée modifiée du témoin négatif. Un désaccord est instructif : cherchez s’il provient de la définition, du calcul, de la représentation ou de la tâche avant de modifier le modèle. Un accord sur le seul cas principal n’établit pas une règle universelle. Ces exemples finis rendent explicite une hypothèse qu’un aperçu fluide pourrait masquer.

```text
{"candidate_a":[0,0,0],"candidate_b":[0,0,1],"projection_axes":[0,1],"required_depth":0}
observe(p)=[p[0],p[1]]; requirement(p)=(p[2]==required_depth); indistinguishable=(observe(a)==observe(b))
```

## Exercices corrigés

### Exercice 1

Calculez les observations principales selon la projection déclarée.

<details><summary>Réponse 1</summary>

Les deux valent `[0,0]`. Les candidats sont indiscernables pour cette observation exacte malgré leurs profondeurs différentes.

</details>

### Exercice 2

Évaluez l’exigence de profondeur des deux candidats.

<details><summary>Réponse 2</summary>

Elle est vraie pour A et fausse pour B. Des observations égales n’impliquent donc pas le même respect de cette exigence.

</details>

### Exercice 3

Appliquez le témoin à position modifiée. Quelle différence devient observable ?

<details><summary>Réponse 3</summary>

Les observations deviennent `[0,0]` et `[1,0]`. Elles se distinguent, alors que B échoue toujours à l’exigence de profondeur.

</details>

### Exercice 4

Quelle observation idéale supplémentaire distinguerait les candidats principaux ?

<details><summary>Réponse 4</summary>

Une observation conservant la profondeur pourrait les distinguer. Elle donne un témoin pour cette paire, pas une preuve universelle d’identification de toute propriété sculpturale.

</details>

### Exercice 5

Quel énoncé de fidélité justifie l’observation initiale ?

<details><summary>Réponse 5</summary>

Déclarez seulement l’accord selon la vue de face et la convention choisies. Profondeur, surfaces cachées, matériau et procédé restent indécidés sans preuves distinctes.

</details>

## Tâche avec consultation des sources

Établissez la table d’observation avant les réponses, puis désignez un relief envisagé qu’une vue de face omettrait. Repérez les arguments de capture sans revendiquer de rendu. Un candidat à vue identique mais à propriété cachée incorrecte réfute une inférence universelle de fidélité.

Conservez séparément votre réponse initiale, les passages consultés, l’historique de l’aide reçue et les corrections ultérieures. Énoncez le résultat observable qui réfuterait votre recommandation avant de proposer une automatisation. Comparez la réponse assistée par les sources à votre référence manuelle, en précisant l’incertitude supplémentaire. Le dossier contient cinq critères préparés ; chaque décision reste nulle jusqu’à une véritable tentative suivie d’une revue. Les corrigés servent de vérification ; ils ne prouvent pas qu’un apprenant a effectué la tâche.

## Sources et journal de validation

- [Prérequis: phi-008-separate-a-test-oracle-from-a-specification](../../philosophy/phi-008-separate-a-test-oracle-from-a-specification/)
- [Artefact du projet conservé](https://github.com/spareilleux/learn/blob/main/code/blender/scripts/glb_pipeline.py)
- [Source primaire](https://docs.godotengine.org/en/4.5/classes/class_camera3d.html)
- [Dossier fixe des exemples](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/unit-c.json)
- [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/journal.md)
