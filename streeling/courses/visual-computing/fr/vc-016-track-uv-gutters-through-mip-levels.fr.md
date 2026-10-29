---
module_id: vc-016-track-uv-gutters-through-mip-levels
department: visual-computing
course: "Suivre les espaces UV dans les niveaux de mipmap"
level: intermediate
prerequisites: ["vc-010-preserve-packed-texture-channel-contracts"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Suivre les espaces UV dans les niveaux de mipmap

> Brouillon soumis à une revue technique et linguistique. Chaque scène, nombre, température, durée et résultat introduit ci-dessous est un exemple construit. La lecture des sources et les calculs ne constituent ni un essai physique, ni un import [Godot](https://docs.godotengine.org/en/4.5/), ni un rendu [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), ni une exécution [ComfyUI](https://docs.comfy.org/), ni une observation d’apprentissage. Les décisions humaines et celles liées à l’exécution restent en attente.

## Question du projet

Un atlas de tissage ou de broderie peut respecter les canaux tout en mélangeant des régions voisines à distance. Nous suivons la largeur déclarée d’un espace entre îlots lorsque la texture diminue dans une chaîne idéale de mipmaps. La leçon ajoute une séparation spatiale au contrat des canaux. Elle indique où une marge choisie cesse de tenir, sans prédire tout filtrage ni prouver l’apparition d’une couture rendue.

## Lire la limite conservée

L’utilitaire de matériaux Atlas affecte des propriétés visuelles, mais les lignes inspectées ne garantissent aucun espace UV. La page Godot décrit les mipmaps ; son avertissement sur une limite non implémentée concerne cette version documentée et ne décrit pas le fork de l’utilisateur.

Lisez le prérequis et l’artefact conservé avant d’interpréter le modèle. La source a sa propre révision et son propre objectif ; elle fournit la limite décrite ici, pas les nouvelles données pédagogiques. Dressez un tableau distinguant un champ inspecté, une hypothèse, une quantité calculée et un effet envisagé dans la scène. Le résumé d’un agent doit renvoyer au champ interprété. Un nom de fichier ne suffit pas à établir un résultat antérieur.

## Interpréter le modèle

Chaque niveau idéal divise les deux axes de l’image par le même facteur. L’espace de l’image de base est donc divisé par une puissance de ce facteur. Précisez s’il s’agit de l’espace total entre îlots ou de la marge de chaque côté : les confondre change la distance disponible. Une marge numérique restante dépend encore de l’empreinte de filtrage, de la répétition et du contenu des mipmaps. Décodage correct des canaux et isolation des îlots sont des exigences distinctes à composer. Une normale, une rugosité ou une hauteur peut être décodée correctement tout en provenant de la mauvaise région voisine.

La référence directe est un croquis légendé et un calcul manuel, réalisés sans ouvrir les réponses. Conservez les valeurs intermédiaires et les unités, puis appliquez l’entrée modifiée du témoin négatif. Un désaccord est instructif : cherchez s’il provient de la définition, du calcul, de la représentation ou de la tâche avant de modifier le modèle. Un accord sur le seul cas principal n’établit pas une règle universelle. Ces exemples finis rendent explicite une hypothèse qu’un aperçu fluide pourrait masquer.

```text
{"gutter_px":16,"mip_level":3,"required_gutter_px":2}
effective_gutter_px=gutter_px/(2**mip_level); meets_declared_margin=effective_gutter_px>=required_gutter_px
```

## Exercices corrigés

### Exercice 1

Calculez l’espace effectif du cas principal.

<details><summary>Réponse 1</summary>

Il vaut `2 px`, exactement l’exigence de `2 px`. L’égalité satisfait cette comparaison construite sans offrir de réserve supplémentaire.

</details>

### Exercice 2

Appliquez le témoin au niveau plus grossier.

<details><summary>Réponse 2</summary>

L’espace devient `1 px`, sous l’exigence. Un même atlas satisfait donc le niveau déclaré et échoue au suivant.

</details>

### Exercice 3

Respecter la marge prouve-t-il l’absence de bavure visible ?

<details><summary>Réponse 3</summary>

Non. Filtres, compression, dérivées UV, répétition et contenu sont absents du modèle. Il borne une distance idéale, pas tout le processus d’échantillonnage.

</details>

### Exercice 4

Pourquoi distinguer espace total et marge propre à chaque îlot ?

<details><summary>Réponse 4</summary>

Les définitions allouent des séparations différentes. Un nombre sans définition spatiale peut diviser ou multiplier la protection supposée.

</details>

### Exercice 5

Un décodage correct de texture compacte répare-t-il un contrat spatial défaillant ?

<details><summary>Réponse 5</summary>

Non. Comprendre les canaux n’empêche pas d’échantillonner l’îlot voisin. Conservez les rôles des canaux et l’exigence de séparation dans l’atlas.

</details>

## Tâche avec consultation des sources

Dessinez deux îlots et légendez leur espace total aux niveaux initial et modifié. Calculez les largeurs manuellement. Repérez la portée limitée de l’utilitaire, puis décrivez les preuves supplémentaires d’un futur import. Un niveau plus grossier sous la marge réfute une garantie valable à tous les niveaux.

Conservez séparément votre réponse initiale, les passages consultés, l’historique de l’aide reçue et les corrections ultérieures. Énoncez le résultat observable qui réfuterait votre recommandation avant de proposer une automatisation. Comparez la réponse assistée par les sources à votre référence manuelle, en précisant l’incertitude supplémentaire. Le dossier contient cinq critères préparés ; chaque décision reste nulle jusqu’à une véritable tentative suivie d’une revue. Les corrigés servent de vérification ; ils ne prouvent pas qu’un apprenant a effectué la tâche.

## Sources et journal de validation

- [Prérequis: vc-010-preserve-packed-texture-channel-contracts](../../visual-computing/en/vc-010-preserve-packed-texture-channel-contracts.md)
- [Artefact du projet conservé](../../../../code/blender/scripts/atlas/kit.py)
- [Source primaire](https://docs.godotengine.org/en/4.5/tutorials/assets_pipeline/importing_images.html)
- [Dossier fixe des exemples](../../../../code/streeling/evidence/batch50-2026-10-24/unit-c.json)
- [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
