---
title: Déclarer la priorité des modifications de matériau
description: Déclarer la priorité des modifications de matériau — Sémiotique
sidebar:
  label: SEM-014 · Déclarer la priorité des modifications de matériau
  order: 14
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/semiotics/fr/sem-014-declare-material-patch-precedence.fr.md
---

:::note[Streeling University]
**SEM-014** · Déclarer la priorité des modifications de matériau · intermédiaire · 45 minutes

Généré par le département *Sémiotique* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/semiotics/fr/sem-014-declare-material-patch-precedence.fr.md) · [Mon journal](../../journal/)

Prérequis: [SEM-011](../../semiotics/sem-011-version-a-dsl-meaning-before-renaming-its-syntax/)
:::

> Brouillon soumis à une revue technique et linguistique. Chaque scène, nombre, température, durée et résultat introduit ci-dessous est un exemple construit. La lecture des sources et les calculs ne constituent ni un essai physique, ni un import [Godot](https://docs.godotengine.org/en/4.5/), ni un rendu [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), ni une exécution [ComfyUI](https://docs.comfy.org/), ni une observation d’apprentissage. Les décisions humaines et celles liées à l’exécution restent en attente.

## Question du projet

Une scène de travail du métal combine finition de base, annotation artisanale et surbrillance de revue. Si deux descriptions fixent la rugosité, la composition doit désigner une priorité. Nous définissons une petite algèbre de modifications de champs et montrons où l’ordre compte. C’est une interprétation proposée pour un futur langage, pas une API existante de fusion des ressources Godot.

## Lire la limite conservée

L’utilitaire Atlas écrit couleur de base, caractère métallique et rugosité. L’introduction Godot documente séparément la priorité des ressources de maillage, de nœud et de remplacement, ainsi que la superposition. Ces faits motivent une priorité explicite sans implémenter notre algèbre de champs.

Lisez le prérequis et l’artefact conservé avant d’interpréter le modèle. La source a sa propre révision et son propre objectif ; elle fournit la limite décrite ici, pas les nouvelles données pédagogiques. Dressez un tableau distinguant un champ inspecté, une hypothèse, une quantité calculée et un effet envisagé dans la scène. Le résumé d’un agent doit renvoyer au champ interprété. Un nom de fichier ne suffit pas à établir un résultat antérieur.

## Interpréter le modèle

Une modification est une application partielle des noms de champs vers leurs valeurs. Elle ne remplace que les champs indiqués et conserve les autres. Par définition, la dernière valeur d’un champ conflictuel gagne. L’opération est associative pour ces applications finies, mais généralement non commutative. Le témoin aux champs disjoints donne une condition où permuter conserve le résultat. Remplacement de ressource et fusion de champs sont deux niveaux : la priorité documentée de l’hôte peut remplacer tout un matériau, alors que notre modèle fusionne des champs. Gardez cette différence avant de traduire une consigne artisanale en adaptateur de scène.

La référence directe est un croquis légendé et un calcul manuel, réalisés sans ouvrir les réponses. Conservez les valeurs intermédiaires et les unités, puis appliquez l’entrée modifiée du témoin négatif. Un désaccord est instructif : cherchez s’il provient de la définition, du calcul, de la représentation ou de la tâche avant de modifier le modèle. Un accord sur le seul cas principal n’établit pas une règle universelle. Ces exemples finis rendent explicite une hypothèse qu’un aperçu fluide pourrait masquer.

```text
{"base":{"roughness":0.8,"metallic":0},"patch_a":{"roughness":0.3},"patch_b":{"roughness":0.6,"metallic":1}}
merge(x,y)=right-biased field union; AB=merge(merge(base,a),b); BA=merge(merge(base,b),a)
```

## Exercices corrigés

### Exercice 1

Appliquez la modification artisanale puis celle de revue.

<details><summary>Réponse 1</summary>

La rugosité finale vaut `0.6` et le caractère métallique `1`. La rugosité de revue, plus tardive, gagne selon la règle déclarée.

</details>

### Exercice 2

Inversez l’ordre. Quelle valeur change ?

<details><summary>Réponse 2</summary>

La rugosité devient `0.3` ; le caractère métallique reste `1`. Les résultats sont tous deux définis, avec des priorités différentes.

</details>

### Exercice 3

Appliquez le témoin aux champs disjoints dans les deux ordres.

<details><summary>Réponse 3</summary>

Les deux donnent une rugosité de `0.3` et un caractère métallique de `1`. Sans clé commune, cette permutation conserve le résultat.

</details>

### Exercice 4

La documentation de remplacement Godot établit-elle cette fusion de champs ?

<details><summary>Réponse 4</summary>

Non. Le passage décrit la priorité des ressources de matériau et la superposition. Notre fusion partielle est une interprétation construite exigeant son propre contrat d’adaptateur.

</details>

### Exercice 5

Que doit conserver une description composable pour la revue ?

<details><summary>Réponse 5</summary>

Identité des modifications, champs affectés, ordre, ressource de base et correspondance avec l’hôte. L’apparence finale ne révèle pas quelle consigne a gagné un conflit.

</details>

## Tâche avec consultation des sources

Construisez manuellement les deux tables en conservant les champs inchangés. Repérez les affectations Atlas et la priorité distincte de Godot. Un champ conflictuel qui change après une permutation supposée anodine réfute une réorganisation inconditionnelle. N’implémentez pas cette algèbre dans cette unité.

Conservez séparément votre réponse initiale, les passages consultés, l’historique de l’aide reçue et les corrections ultérieures. Énoncez le résultat observable qui réfuterait votre recommandation avant de proposer une automatisation. Comparez la réponse assistée par les sources à votre référence manuelle, en précisant l’incertitude supplémentaire. Le dossier contient cinq critères préparés ; chaque décision reste nulle jusqu’à une véritable tentative suivie d’une revue. Les corrigés servent de vérification ; ils ne prouvent pas qu’un apprenant a effectué la tâche.

## Sources et journal de validation

- [Prérequis: sem-011-version-a-dsl-meaning-before-renaming-its-syntax](../../semiotics/sem-011-version-a-dsl-meaning-before-renaming-its-syntax/)
- [Artefact du projet conservé](https://github.com/spareilleux/learn/blob/main/code/blender/scripts/atlas/kit.py)
- [Source primaire](https://docs.godotengine.org/en/4.5/tutorials/3d/standard_material_3d.html)
- [Dossier fixe des exemples](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/unit-c.json)
- [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/journal.md)
