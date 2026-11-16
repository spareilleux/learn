---
module_id: phi-011-cross-mesh-and-lighting-before-attributing-a-render-change
department: philosophy
course: "Croiser maillage et éclairage avant d’attribuer un changement de rendu"
level: intermediate
prerequisites: ["phi-007-test-a-learning-gain-against-counterfactuals"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Croiser maillage et éclairage avant d’attribuer un changement de rendu

> Brouillon soumis à une revue technique et linguistique. Chaque scène, nombre, température, durée et résultat introduit ci-dessous est un exemple construit. La lecture des sources et les calculs ne constituent ni un essai physique, ni un import [Godot](https://docs.godotengine.org/en/4.5/), ni un rendu [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), ni une exécution [ComfyUI](https://docs.comfy.org/), ni une observation d’apprentissage. Les décisions humaines et celles liées à l’exécution restent en attente.

## Question du projet

Une équipe remplace le maillage d’une sculpture et modifie son éclairage dans la même comparaison. Le nouveau résidu est plus mauvais et le maillage est accusé. Nous séparons les changements dans une table complète construite. La leçon prolonge les contrefactuels par un plan croisé explicite, puis utilise un témoin avec interaction pour montrer les limites d’un effet unique du maillage.

## Lire la limite conservée

Le pipeline expose des réglages de capture avec ceux de géométrie. Ces arguments ne fournissent aucune comparaison causale contrôlée. Le guide factoriel NIST explique le croisement des niveaux et les interactions ; notre table est inventée, sans reprendre une expérience de la source.

Lisez le prérequis et l’artefact conservé avant d’interpréter le modèle. La source a sa propre révision et son propre objectif ; elle fournit la limite décrite ici, pas les nouvelles données pédagogiques. Dressez un tableau distinguant un champ inspecté, une hypothèse, une quantité calculée et un effet envisagé dans la scène. Le résumé d’un agent doit renvoyer au champ interprété. Un nom de fichier ne suffit pas à établir un résultat antérieur.

## Interpréter le modèle

Comparez ancien et nouveau maillages sous un éclairage identique avant toute moyenne. Comparez ensuite ces écarts entre éclairages. S’ils diffèrent, l’effet dépend de l’éclairage dans la table construite. Une diagonale change les deux facteurs et ne peut en isoler aucun. Le croisement complet explicite les comparaisons manquantes, mais n’établit pas automatiquement la causalité réelle. Un futur essai exige caméras, réglages, entrées et ordre d’exécution maîtrisés, ainsi qu’une répétition ou une méthode d’incertitude justifiée lorsque nécessaire. Les calculs présents sont déterministes et ne contiennent aucun bruit de rendu échantillonné.

La référence directe est un croquis légendé et un calcul manuel, réalisés sans ouvrir les réponses. Conservez les valeurs intermédiaires et les unités, puis appliquez l’entrée modifiée du témoin négatif. Un désaccord est instructif : cherchez s’il provient de la définition, du calcul, de la représentation ou de la tâche avant de modifier le modèle. Un accord sur le seul cas principal n’établit pas une règle universelle. Ces exemples finis rendent explicite une hypothèse qu’un aperçu fluide pourrait masquer.

```text
{"old_flat":6,"old_lit":10,"new_flat":4,"new_lit":8}
mesh_flat=new_flat-old_flat; mesh_lit=new_lit-old_lit; average_mesh=(mesh_flat+mesh_lit)/2; interaction=mesh_lit-mesh_flat; diagonal=new_lit-old_flat
```

## Exercices corrigés

### Exercice 1

Comparez nouveau et ancien maillages sous chaque éclairage identique.

<details><summary>Réponse 1</summary>

Les deux écarts valent `-2` unités de résidu. Dans cette table construite, le nouveau maillage améliore le critère à chaque niveau d’éclairage.

</details>

### Exercice 2

Que donne la diagonale et pourquoi son attribution est-elle erronée ?

<details><summary>Réponse 2</summary>

Le changement diagonal vaut `2` unités. Il mélange maillage et éclairage ; il ne peut attribuer cette augmentation au seul maillage.

</details>

### Exercice 3

Calculez l’écart moyen de maillage et l’interaction.

<details><summary>Réponse 3</summary>

L’écart moyen vaut `-2` unités et l’interaction `0`. L’égalité des écarts de maillage entre ces éclairages appartient à cette table, pas à une loi universelle du rendu.

</details>

### Exercice 4

Appliquez le témoin avec interaction. Quel énoncé simple échoue ?

<details><summary>Réponse 4</summary>

Les écarts valent `-2` et `2`, leur moyenne `0`, l’interaction `4` et la diagonale `6`. Une amélioration indépendante de l’éclairage est réfutée.

</details>

### Exercice 5

La table prouve-t-elle qu’un nettoyage réel a amélioré un rendu ?

<details><summary>Réponse 5</summary>

Non. Les valeurs sont inventées. Elles enseignent les comparaisons à conserver dans un vrai plan ; observations exécutées et conditions contrôlées restent absentes.

</details>

## Tâche avec consultation des sources

Dessinez la table croisée et calculez manuellement tous les contrastes à éclairage constant. Annotez les réglages du pipeline à fixer dans un futur essai. Un éclairage apparié où le nouveau maillage dégrade le résidu, comme dans le témoin, réfute un bénéfice inconditionnel.

Conservez séparément votre réponse initiale, les passages consultés, l’historique de l’aide reçue et les corrections ultérieures. Énoncez le résultat observable qui réfuterait votre recommandation avant de proposer une automatisation. Comparez la réponse assistée par les sources à votre référence manuelle, en précisant l’incertitude supplémentaire. Le dossier contient cinq critères préparés ; chaque décision reste nulle jusqu’à une véritable tentative suivie d’une revue. Les corrigés servent de vérification ; ils ne prouvent pas qu’un apprenant a effectué la tâche.

## Sources et journal de validation

- [Prérequis: phi-007-test-a-learning-gain-against-counterfactuals](../../philosophy/en/phi-007-test-a-learning-gain-against-counterfactuals.md)
- [Artefact du projet conservé](../../../../code/blender/scripts/glb_pipeline.py)
- [Source primaire](https://www.itl.nist.gov/div898/handbook/pri/section3/pri3331.htm)
- [Dossier fixe des exemples](../../../../code/streeling/evidence/batch50-2026-10-24/unit-c.json)
- [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
