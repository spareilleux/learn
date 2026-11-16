---
module_id: sem-012-preserve-the-order-of-stitch-frame-actions
department: semiotics
course: "Conserver l’ordre des actions d’un repère de broderie"
level: intermediate
prerequisites: ["sem-006-preserve-orientation-across-scene-frames"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Conserver l’ordre des actions d’un repère de broderie

> Brouillon soumis à une revue technique et linguistique. Chaque scène, nombre, température, durée et résultat introduit ci-dessous est un exemple construit. La lecture des sources et les calculs ne constituent ni un essai physique, ni un import [Godot](https://docs.godotengine.org/en/4.5/), ni un rendu [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), ni une exécution [ComfyUI](https://docs.comfy.org/), ni une observation d’apprentissage. Les décisions humaines et celles liées à l’exécution restent en attente.

## Question du projet

Une consigne demande de décaler puis de tourner un motif de broderie. Un autre auteur inverse les verbes parce que les listes contiennent les mêmes actions. L’ancrage arrive ailleurs. L’ordre fait ici partie du sens : deux compositions aux mêmes ingrédients peuvent placer différemment la scène. La leçon prolonge l’orientation des repères en passant du nom d’une direction à une séquence d’actions interprétée.

## Lire la limite conservée

L’utilitaire d’objets Atlas accepte un parent et une position ; un motif pourrait donc être placé dans un autre repère. Il ne définit pas nos consignes. La documentation Godot motive une distinction entre opérations locales et relatives au parent, sans déduire le repère des seuls verbes.

Lisez le prérequis et l’artefact conservé avant d’interpréter le modèle. La source a sa propre révision et son propre objectif ; elle fournit la limite décrite ici, pas les nouvelles données pédagogiques. Dressez un tableau distinguant un champ inspecté, une hypothèse, une quantité calculée et un effet envisagé dans la scène. Le résumé d’un agent doit renvoyer au champ interprété. Un nom de fichier ne suffit pas à établir un résultat antérieur.

## Interpréter le modèle

Utilisez un repère plan fixe et un quart de tour exact. Dans la formule, la composition applique d’abord l’action la plus à droite. Décaler avant de tourner fait tourner le décalage avec le point. Tourner avant de décaler ajoute un déplacement qui reste aligné sur le repère fixe. La différence est sémantique, pas due aux arrondis. Le témoin à translation nulle montre pourquoi un exemple concordant ne prouve pas l’indépendance de l’ordre. Un DSL envisagé doit conserver ordre et repère dans son interprétation avant d’en simplifier la syntaxe ou d’optimiser les actions.

La référence directe est un croquis légendé et un calcul manuel, réalisés sans ouvrir les réponses. Conservez les valeurs intermédiaires et les unités, puis appliquez l’entrée modifiée du témoin négatif. Un désaccord est instructif : cherchez s’il provient de la définition, du calcul, de la représentation ou de la tâche avant de modifier le modèle. Un accord sur le seul cas principal n’établit pas une règle universelle. Ces exemples finis rendent explicite une hypothèse qu’un aperçu fluide pourrait masquer.

```text
{"point_mm":[1,0],"translation_mm":[1,0],"rotation_deg":90}
R(x,y)=(-y,x); T(p)=p+t; rotate_after_translate=R(T(p)); translate_after_rotate=T(R(p))
```

## Exercices corrigés

### Exercice 1

Décalez d’abord le point, puis tournez-le.

<details><summary>Réponse 1</summary>

Le résultat est `(0,2) mm`. Le décalage appartient au vecteur tourné autour de l’origine fixe.

</details>

### Exercice 2

Tournez d’abord, puis décalez. L’ancrage reste-t-il identique ?

<details><summary>Réponse 2</summary>

Le résultat est `(1,1) mm`, différent du premier ordre. Les mêmes noms d’actions ne définissent donc pas la même position sans leur ordre.

</details>

### Exercice 3

Appliquez la translation nulle aux deux compositions.

<details><summary>Réponse 3</summary>

Les deux donnent `(0,1) mm`. Cet accord particulier ne justifie pas de permuter la translation non nulle du cas principal.

</details>

### Exercice 4

Que doit conserver une traduction en description de scène ?

<details><summary>Réponse 4</summary>

Conservez ordre, unités du point et du décalage, origine de rotation, repère du décalage et convention de composition. Les verbes seuls laissent le sens incomplet.

</details>

### Exercice 5

Un compilateur peut-il réordonner ces actions parce qu’un aperçu concordait ?

<details><summary>Réponse 5</summary>

Pas avec les entrées principales déclarées. L’optimisation exige une condition prouvant l’égalité des résultats interprétés, pas un aperçu particulier sans décalage.

</details>

## Tâche avec consultation des sources

Dessinez les deux trajets depuis le même départ et écrivez manuellement leurs coordonnées intermédiaires. Repérez la limite de placement Atlas sans modifier le code. Les ancrages différents réfutent une permutation inconditionnelle ; proposez un test d’équivalence sémantique avant un compilateur.

Conservez séparément votre réponse initiale, les passages consultés, l’historique de l’aide reçue et les corrections ultérieures. Énoncez le résultat observable qui réfuterait votre recommandation avant de proposer une automatisation. Comparez la réponse assistée par les sources à votre référence manuelle, en précisant l’incertitude supplémentaire. Le dossier contient cinq critères préparés ; chaque décision reste nulle jusqu’à une véritable tentative suivie d’une revue. Les corrigés servent de vérification ; ils ne prouvent pas qu’un apprenant a effectué la tâche.

## Sources et journal de validation

- [Prérequis: sem-006-preserve-orientation-across-scene-frames](../../semiotics/en/sem-006-preserve-orientation-across-scene-frames.md)
- [Artefact du projet conservé](../../../../code/blender/scripts/atlas/kit.py)
- [Source primaire](https://docs.godotengine.org/en/4.5/tutorials/3d/using_transforms.html)
- [Dossier fixe des exemples](../../../../code/streeling/evidence/batch50-2026-10-24/unit-c.json)
- [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
