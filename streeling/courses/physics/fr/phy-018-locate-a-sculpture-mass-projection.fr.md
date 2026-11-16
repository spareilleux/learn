---
module_id: phy-018-locate-a-sculpture-mass-projection
department: physics
course: "Situer la projection des masses d’une sculpture"
level: intermediate
prerequisites: ["phy-013-check-torque-when-moving-a-scene-pivot"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Situer la projection des masses d’une sculpture

> Brouillon soumis à une revue technique et linguistique. Chaque scène, nombre, température, durée et résultat introduit ci-dessous est un exemple construit. La lecture des sources et les calculs ne constituent ni un essai physique, ni un import [Godot](https://docs.godotengine.org/en/4.5/), ni un rendu [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), ni une exécution [ComfyUI](https://docs.comfy.org/), ni une observation d’apprentissage. Les décisions humaines et celles liées à l’exécution restent en attente.

## Question du projet

Une sculpture métallique asymétrique peut paraître équilibrée parce que l’origine de son maillage est centrée. Cette origine relève de la modélisation. Nous situons la projection d’un modèle de masses déclaré par rapport à un intervalle d’appui, afin qu’une future annotation Godot distingue centrage visuel et prémisse mécanique statique. La leçon prolonge le raisonnement sur les pivots en pondérant les positions, au lieu d’attribuer la même masse à chaque composant ou sommet.

## Lire la limite conservée

L’utilitaire d’objets Atlas accepte une position et un parent facultatif. Ce sont des propriétés spatiales, pas des masses mesurées. L’utilitaire de matériau inspecté ne fournit pas non plus de densité. Nous introduisons donc des masses ponctuelles pédagogiques explicites.

Lisez le prérequis et l’artefact conservé avant d’interpréter le modèle. La source a sa propre révision et son propre objectif ; elle fournit la limite décrite ici, pas les nouvelles données pédagogiques. Dressez un tableau distinguant un champ inspecté, une hypothèse, une quantité calculée et un effet envisagé dans la scène. Le résumé d’un agent doit renvoyer au champ interprété. Un nom de fichier ne suffit pas à établir un résultat antérieur.

## Interpréter le modèle

OpenStax définit le centre de masse à partir des positions pondérées par les masses. Notre coupe ignore l’autre coordonnée horizontale et suppose une gravité verticale. Sous les hypothèses de contact indiquées, la projection doit être à l’intérieur de l’appui pour obtenir une marge statique positive. L’égalité marque une limite, pas une réserve. Ni centre géométrique ni origine d’objet ne remplacent ce calcul. Modifier quelques sommets peut changer leur moyenne sans déplacer de matériau ; déplacer un composant lourd change au contraire le modèle, même si une boîte englobante décorative reste centrée.

La référence directe est un croquis légendé et un calcul manuel, réalisés sans ouvrir les réponses. Conservez les valeurs intermédiaires et les unités, puis appliquez l’entrée modifiée du témoin négatif. Un désaccord est instructif : cherchez s’il provient de la définition, du calcul, de la représentation ou de la tâche avant de modifier le modèle. Un accord sur le seul cas principal n’établit pas une règle universelle. Ces exemples finis rendent explicite une hypothèse qu’un aperçu fluide pourrait masquer.

```text
{"masses_kg":[2,1],"x_m":[0,0.3],"support_m":[-0.12,0.12]}
x_cm=sum(m_i*x_i)/sum(m_i); margin=min(x_cm-support_min,support_max-x_cm)
```

## Exercices corrigés

### Exercice 1

Trouvez la masse totale et le centre projeté du cas principal.

<details><summary>Réponse 1</summary>

La masse totale vaut `3 kg` et le centre projeté `0.1 m`. Le composant à l’origine participe au dénominateur malgré sa position pondérée nulle.

</details>

### Exercice 2

Calculez la marge jusqu’au bord d’appui le plus proche. Que signifie son signe ?

<details><summary>Réponse 2</summary>

La marge vaut `0.02 m`. Elle est positive car la projection est strictement intérieure à l’intervalle déclaré ; ce n’est pas un coefficient de sécurité mesuré.

</details>

### Exercice 3

Déplacez seulement le composant décoratif selon le témoin.

<details><summary>Réponse 3</summary>

La projection devient `0.2 m` et la marge `-0.08 m`. Elle sort de l’appui malgré une masse totale et un intervalle d’appui inchangés.

</details>

### Exercice 4

La moyenne des sommets du maillage fournit-elle la même quantité justifiée ?

<details><summary>Réponse 4</summary>

Non. La densité des sommets dépend de la tessellation, pas de la masse. Il faut des masses de composants ou un modèle densité-volume ; l’origine ne fournit ni l’un ni l’autre.

</details>

### Exercice 5

Quelles conclusions restent impossibles malgré une marge positive ?

<details><summary>Réponse 5</summary>

Réponse dynamique, glissement, résistance des assemblages, déformation et stabilité réelle restent non vérifiés. Le résultat porte uniquement sur la coupe statique déclarée.

</details>

## Tâche avec consultation des sources

Dessinez les composants et l’appui, puis calculez manuellement la projection pondérée. Repérez où Atlas stocke les positions et où les masses requises sont absentes. Une projection extérieure réfute une marge positive dans ce modèle ; elle ne constitue pas l’observation d’une chute réelle.

Conservez séparément votre réponse initiale, les passages consultés, l’historique de l’aide reçue et les corrections ultérieures. Énoncez le résultat observable qui réfuterait votre recommandation avant de proposer une automatisation. Comparez la réponse assistée par les sources à votre référence manuelle, en précisant l’incertitude supplémentaire. Le dossier contient cinq critères préparés ; chaque décision reste nulle jusqu’à une véritable tentative suivie d’une revue. Les corrigés servent de vérification ; ils ne prouvent pas qu’un apprenant a effectué la tâche.

## Sources et journal de validation

- [Prérequis: phy-013-check-torque-when-moving-a-scene-pivot](../../physics/en/phy-013-check-torque-when-moving-a-scene-pivot.md)
- [Artefact du projet conservé](../../../../code/blender/scripts/atlas/kit.py)
- [Source primaire](https://openstax.org/books/university-physics-volume-1/pages/9-6-center-of-mass)
- [Dossier fixe des exemples](../../../../code/streeling/evidence/batch50-2026-10-24/unit-c.json)
- [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
