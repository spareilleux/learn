---
module_id: dv-015-map-missing-stitches-without-inventing-holes
department: data-visualization
course: "Cartographier les points manquants sans inventer de trous"
level: intermediate
prerequisites: ["dv-010-show-pitch-errors-and-missing-estimates"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Cartographier les points manquants sans inventer de trous

> Brouillon soumis à une revue technique et linguistique. Chaque scène, nombre, température, durée et résultat introduit ci-dessous est un exemple construit. La lecture des sources et les calculs ne constituent ni un essai physique, ni un import [Godot](https://docs.godotengine.org/en/4.5/), ni un rendu [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), ni une exécution [ComfyUI](https://docs.comfy.org/), ni une observation d’apprentissage. Les décisions humaines et celles liées à l’exécution restent en attente.

## Question du projet

Une carte d’inspection de broderie laisse une case vide faute d’observation. Un auteur de scène y voit un trou et retire la géométrie. Nous distinguons l’absence observée d’un point d’un emplacement non observé, en conservant l’adresse spatiale et le dénominateur. La distinction du prérequis passe d’une trace temporelle à une surface artisanale envisagée, sans confondre une image et une inspection physique.

## Lire la limite conservée

Le jeu de croisements conservé associe à chacun un identifiant et des coordonnées de grille. Ces champs fournissent une adresse explicite. Ses booléens décrivent l’ordre du tissage, pas la présence de points ; notre table distincte ne doit pas remplacer leur sens.

Lisez le prérequis et l’artefact conservé avant d’interpréter le modèle. La source a sa propre révision et son propre objectif ; elle fournit la limite décrite ici, pas les nouvelles données pédagogiques. Dressez un tableau distinguant un champ inspecté, une hypothèse, une quantité calculée et un effet envisagé dans la scène. Le résumé d’un agent doit renvoyer au champ interprété. Un nom de fichier ne suffit pas à établir un résultat antérieur.

## Interpréter le modèle

Utilisez une table parcourue ligne par ligne avec trois états. Vrai signifie point observé, faux signifie absence observée et nul signifie emplacement non observé. Marquez explicitement les emplacements non observés avec une légende textuelle ; le fond ne doit pas suggérer un vide physique. Présentez absence observée et couverture. Le masque d’observation fait partie des données, pas d’une décoration jetable. Un groupe de sites absents ne prouve pas non plus une déchirure continue : la matière entre les sites n’a été ni modélisée ni échantillonnée.

La référence directe est un croquis légendé et un calcul manuel, réalisés sans ouvrir les réponses. Conservez les valeurs intermédiaires et les unités, puis appliquez l’entrée modifiée du témoin négatif. Un désaccord est instructif : cherchez s’il provient de la définition, du calcul, de la représentation ou de la tâche avant de modifier le modèle. Un accord sur le seul cas principal n’établit pas une règle universelle. Ces exemples finis rendent explicite une hypothèse qu’un aperçu fluide pourrait masquer.

```text
{"grid_width":3,"grid_height":2,"observed_stitch":[true,false,null,true,false,true]}
observed=count(v is not null); present=count(v is true); absent=count(v is false); missing=total-observed; observed_absence_fraction=absent/observed
```

## Exercices corrigés

### Exercice 1

Comptez les sites présents, absents et non observés.

<details><summary>Réponse 1</summary>

On compte `3` présents, `2` absences observées et `1` site manquant. Il y a `5` observations pour `6` sites de grille.

</details>

### Exercice 2

Calculez la fraction d’absences observées. Quelle population décrit-elle ?

<details><summary>Réponse 2</summary>

Elle vaut `0.4` sur les `5` sites observés. Elle décrit ce sous-ensemble, sans justifier une estimation pour tout un textile réel.

</details>

### Exercice 3

Appliquez le témoin qui remplace la valeur manquante par faux.

<details><summary>Réponse 3</summary>

Les observations passent à `6`, les absences à `3`, les valeurs manquantes à `0` et la fraction à `0.5`. Le remplacement invente une observation.

</details>

### Exercice 4

Comment la légende distingue-t-elle les deux sortes de vide ?

<details><summary>Réponse 4</summary>

Prévoyez des états textuels et des marques distincts pour absence observée et site non observé. Un fond transparent ne distingue pas mesure manquante et trou réel.

</details>

### Exercice 5

La grille certifie-t-elle une déchirure physique continue ?

<details><summary>Réponse 5</summary>

Non. Les états de sites espacés ne définissent ni la matière intermédiaire ni sa connexité. Il faut d’autres données avant de retirer une surface continue.

</details>

## Tâche avec consultation des sources

Dessinez la grille, légendez son masque et reproduisez manuellement les dénominateurs. Repérez les adresses du jeu et expliquez pourquoi son booléen d’ordre n’indique pas une présence. Une vue transformant le site non observé en absence confirmée réfute la conservation de cette limite.

Conservez séparément votre réponse initiale, les passages consultés, l’historique de l’aide reçue et les corrections ultérieures. Énoncez le résultat observable qui réfuterait votre recommandation avant de proposer une automatisation. Comparez la réponse assistée par les sources à votre référence manuelle, en précisant l’incertitude supplémentaire. Le dossier contient cinq critères préparés ; chaque décision reste nulle jusqu’à une véritable tentative suivie d’une revue. Les corrigés servent de vérification ; ils ne prouvent pas qu’un apprenant a effectué la tâche.

## Sources et journal de validation

- [Prérequis: dv-010-show-pitch-errors-and-missing-estimates](../../data-visualization/en/dv-010-show-pitch-errors-and-missing-estimates.md)
- [Artefact du projet conservé](../../../../code/streeling/evidence/weave-scene-2026-10-22/crossings.json)
- [Source primaire](https://docs.godotengine.org/en/4.5/classes/class_camera3d.html)
- [Dossier fixe des exemples](../../../../code/streeling/evidence/batch50-2026-10-24/unit-c.json)
- [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
