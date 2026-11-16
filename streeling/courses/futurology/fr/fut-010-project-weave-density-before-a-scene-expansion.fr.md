---
module_id: fut-010-project-weave-density-before-a-scene-expansion
department: futurology
course: "Projeter la densité du tissage avant d’agrandir une scène"
level: intermediate
prerequisites: ["fut-007-test-a-weave-generator-outside-its-preview"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Projeter la densité du tissage avant d’agrandir une scène

> Brouillon soumis à une revue technique et linguistique. Chaque scène, nombre, température, durée et résultat introduit ci-dessous est un exemple construit. La lecture des sources et les calculs ne constituent ni un essai physique, ni un import [Godot](https://docs.godotengine.org/en/4.5/), ni un rendu [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), ni une exécution [ComfyUI](https://docs.comfy.org/), ni une observation d’apprentissage. Les décisions humaines et celles liées à l’exécution restent en attente.

## Question du projet

Une future scène double la densité de fils et ne prévoit que le double d’annotations de croisements. Le plan confond un nombre de fils avec un nombre de paires. Nous dérivons des scénarios de charge à partir d’une construction explicite avant de parler de capacité. La leçon prolonge le passage de l’aperçu à la cible en distinguant les ressources liées au produit des directions de celles liées à leur somme.

## Lire la limite conservée

Le jeu conservé contient coordonnées de grille et identifiants de croisements pour une zone finie. Ses lignes historiques ne sont pas des mesures de performance. Elles motivent un inventaire par paires ; multiplicateurs de densité et charge future restent des hypothèses construites.

Lisez le prérequis et l’artefact conservé avant d’interpréter le modèle. La source a sa propre révision et son propre objectif ; elle fournit la limite décrite ici, pas les nouvelles données pédagogiques. Dressez un tableau distinguant un champ inspecté, une hypothèse, une quantité calculée et un effet envisagé dans la scène. Le résumé d’un agent doit renvoyer au champ interprété. Un nom de fichier ne suffit pas à établir un résultat antérieur.

## Interpréter le modèle

Dans ce tissage rectangulaire complet, chaque fil de chaîne rencontre chaque fil de trame. Les croisements forment un produit, les fils une somme. Agrandir les deux directions les modifie donc différemment. Le calcul décrit un inventaire, pas un coût de rendu ou de requête. L’hôte peut regrouper des représentations, ignorer des croisements cachés ou leur associer des données différentes ; une capacité future exige un coût unitaire réellement mesuré et son domaine de validité. Le témoin ne modifie qu’une direction, afin de maintenir la croissance quadratique dans ses hypothèses. Un scénario est un calcul conditionnel, pas une prévision de demande.

La référence directe est un croquis légendé et un calcul manuel, réalisés sans ouvrir les réponses. Conservez les valeurs intermédiaires et les unités, puis appliquez l’entrée modifiée du témoin négatif. Un désaccord est instructif : cherchez s’il provient de la définition, du calcul, de la représentation ou de la tâche avant de modifier le modèle. Un accord sur le seul cas principal n’établit pas une règle universelle. Ces exemples finis rendent explicite une hypothèse qu’un aperçu fluide pourrait masquer.

```text
{"warp_count":6,"weft_count":4,"warp_multiplier":2,"weft_multiplier":2}
base_crossings=warp_count*weft_count; future_crossings=(warp_count*warp_multiplier)*(weft_count*weft_multiplier); crossing_ratio=warp_multiplier*weft_multiplier; strand_ratio=(warp_count*warp_multiplier+weft_count*weft_multiplier)/(warp_count+weft_count)
```

## Exercices corrigés

### Exercice 1

Comptez les croisements et fils initiaux.

<details><summary>Réponse 1</summary>

Il y a `24` croisements et `10` fils. Un croisement est une paire d’identités directionnelles, pas un fil supplémentaire.

</details>

### Exercice 2

Modifiez les deux directions et calculez les rapports.

<details><summary>Réponse 2</summary>

Il y a `96` croisements et `20` fils. Les croisements sont multipliés par `4` et les fils par `2`.

</details>

### Exercice 3

Appliquez le témoin à une seule direction.

<details><summary>Réponse 3</summary>

Il y a `48` croisements et `16` fils. Les rapports valent `2` et `1.6` ; l’énoncé de croissance à deux directions ne se transpose pas tel quel.

</details>

### Exercice 4

Le rapport de croisements peut-il devenir un rapport de durée de rendu ?

<details><summary>Réponse 4</summary>

Non. Les effectifs ne précisent ni regroupement, ni élimination, ni géométrie, ni matériaux, ni requêtes, ni coûts fixes. Il faut un modèle de coût et des observations réelles.

</details>

### Exercice 5

Qu’est-ce qui réfuterait ce modèle de grille complète ?

<details><summary>Réponse 5</summary>

Une construction où certaines paires ne se rencontrent pas, se rencontrent plusieurs fois ou sont exclues viole les hypothèses de comptage. Révisez le modèle avant le budget.

</details>

## Tâche avec consultation des sources

Dressez manuellement un inventaire distinguant fils, croisements et annotations envisagées. Repérez les identités du jeu et marquez les entrées de scénario comme hypothèses. Énoncez l’observation qui rejetterait la grille complète avant de recommander une scène ou un budget d’automatisation plus grands.

Conservez séparément votre réponse initiale, les passages consultés, l’historique de l’aide reçue et les corrections ultérieures. Énoncez le résultat observable qui réfuterait votre recommandation avant de proposer une automatisation. Comparez la réponse assistée par les sources à votre référence manuelle, en précisant l’incertitude supplémentaire. Le dossier contient cinq critères préparés ; chaque décision reste nulle jusqu’à une véritable tentative suivie d’une revue. Les corrigés servent de vérification ; ils ne prouvent pas qu’un apprenant a effectué la tâche.

## Sources et journal de validation

- [Prérequis: fut-007-test-a-weave-generator-outside-its-preview](../../futurology/en/fut-007-test-a-weave-generator-outside-its-preview.md)
- [Artefact du projet conservé](../../../../code/streeling/evidence/weave-scene-2026-10-22/crossings.json)
- [Source primaire](https://docs.godotengine.org/en/4.5/tutorials/3d/using_transforms.html)
- [Dossier fixe des exemples](../../../../code/streeling/evidence/batch50-2026-10-24/unit-c.json)
- [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
