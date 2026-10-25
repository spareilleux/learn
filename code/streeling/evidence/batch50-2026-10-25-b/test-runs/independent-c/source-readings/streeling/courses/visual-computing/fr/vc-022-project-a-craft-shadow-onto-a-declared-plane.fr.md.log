---
module_id: "vc-022-project-a-craft-shadow-onto-a-declared-plane"
department: "visual-computing"
course: "Projeter une ombre artisanale sur un plan déclaré"
level: "advanced"
prerequisites: ["sem-006-preserve-orientation-across-scene-frames"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Projeter une ombre artisanale sur un plan déclaré

> Brouillon pour révision technique et linguistique. Entrées numériques, étiquettes et résultats attendus sont des cas pédagogiques construits. Ils ne constituent ni nouveaux essais matériels physiques, ni exécutions natives de scène, ni observations d’apprentissage, ni résultats de production. Les décisions humaines et d’apprentissage restent indécises.

## Opération du projet et interprétation

Une arête de papier plié projette une ombre proposée sur un socle de l’Observatory. Déplacer cette ombre juste sous l’arête suppose une lumière verticale que la scène n’a peut-être pas. L’opération suit la direction déclarée de propagation jusqu’au plan récepteur. C’est une construction géométrique pour une annotation, sans nouveau moteur d’ombres ni observation d’une sculpture éclairée physiquement.

Résolvez l’équation de profondeur du récepteur pour obtenir le paramètre du rayon, puis reportez-le dans toutes les coordonnées. Distinguez propagation lumineuse et vecteur pointant vers la lumière. Inverser la convention peut placer l’intersection derrière le point. Le rayon avant refuse un paramètre négatif même si la droite infinie coupe le plan. Une direction parallèle exige une branche explicite : diviser par sa composante de profondeur est indéfini.

Le témoin conserve point source et récepteur, mais retire le mouvement en profondeur. Il isole une condition géométrique manquante. On ne le répare ni en bornant arbitrairement le paramètre ni en inventant un point lointain. Un futur transfert [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md) vers [Godot](https://docs.godotengine.org/en/4.5/) doit conserver repère, équation du récepteur et convention de propagation, puis tester séparément visibilité et occultation avec une capture fixe. La projection sur le plan infini peut tomber hors du socle réel, ou être cachée par un autre pli. La simple intersection ne représente aucun de ces problèmes.

Lisez le prérequis commité et le passage primaire délimité avant de calculer. Préparez un relevé séparant définition de source, prémisse construite, résultat dérivé et observation future. Une documentation ne soutient que l’affirmation située dans son périmètre lu. Paramètre de source, réponse mathématique et observation d’exécution ont des rôles de preuve différents ; un résumé assuré d’assistant ne peut les échanger. Le paquet conserve révision et périmètre de lecture pour permettre de contester une affirmation précise.

Travaillez d’abord réponses fermées. Dessinez la table ou le schéma requis et conservez les quantités intermédiaires, avec unités ou conventions d’identité. Cette dérivation manuscrite est la référence manuelle directe. Consultez seulement ensuite un assistant ou une aide à la traduction. Gardez la question, l’emplacement cité, la suggestion reçue et la modification acceptée ou rejetée. Comparez le résultat assisté à la première tentative conservée sur les mêmes entrées. Une réponse plus courte ne constitue pas un progrès si elle omet une condition ou invente un essai terminé.

## Modèle fixe et témoin à entrée modifiée

```json
{
  "values": {
    "point": [
      2,
      3,
      4
    ],
    "light_travel": [
      1,
      0,
      -2
    ],
    "plane_z": 0
  },
  "formula": "if d.z==0 return parallel; t=(plane_z-point.z)/d.z; if t<0 return behind; otherwise intersection=point+t*d",
  "expected": {
    "status": "hit",
    "t": 2,
    "intersection": [
      4,
      3,
      0
    ]
  },
  "negative_control": {
    "values": {
      "point": [
        2,
        3,
        4
      ],
      "light_travel": [
        1,
        0,
        0
      ],
      "plane_z": 0
    },
    "expected": {
      "status": "parallel",
      "t": null,
      "intersection": null
    }
  }
}
```

### Exercice 1

Dérivez le paramètre d’intersection.

<details><summary>Réponse 1</summary>

Il vaut `2`. Divisez le décalage signé du récepteur par la composante de profondeur signée ; le résultat positif permet la propagation avant.

</details>

### Exercice 2

Trouvez le point d’ombre candidat.

<details><summary>Réponse 2</summary>

Il vaut `[4,3,0]`. Le déplacement horizontal suit la direction fournie ; la coordonnée médiane reste fixe car sa composante est nulle.

</details>

### Exercice 3

Quelle convention accompagne les données ?

<details><summary>Réponse 3</summary>

Le vecteur décrit la propagation depuis le point vers le récepteur. Un vecteur vers la lumière signifie l’inverse et ne peut le remplacer silencieusement.

</details>

### Exercice 4

Appliquez le témoin parallèle.

<details><summary>Réponse 4</summary>

Le résultat est `parallel`, avec paramètre et intersection `null`. Aucun impact fini ne doit être fabriqué avec un grand dénominateur.

</details>

### Exercice 5

Le point candidat prouve-t-il une ombre visible ?

<details><summary>Réponse 5</summary>

Non. La surface peut être bornée ou occultée et le transport lumineux manque. Une capture moteur fixe reste une observation distincte proposée.

</details>

## Travail avec sources et référence manuelle directe

Dessinez arête pliée, socle et flèche lumineuse dans un repère commun. Dérivez le point à la main, puis rédigez les contrôles de surface bornée et d’occultation nécessaires à un futur essai.

Traitez le témoin comme un enregistrement distinct. Préservez le cas principal, écrivez une prédiction pour l’entrée modifiée et expliquez quelle prémisse change. En cas d’écart avec la première réponse, distinguez erreur de calcul, erreur d’interprétation et limite du modèle. Gardez tentative échouée et correction côte à côte. Le travail demande une note vérifiable avant de proposer un nœud DSL ou un flux d’agents ; une table manuelle peut déjà répondre au besoin.

Soumettez ensemble référence initiale, emplacements de sources, explication corrigée, résultat du témoin et critère de réfutation. Les critères préparés ci-dessous s’adressent à une révision future ; ils ne sont pas des apprentissages acceptés. Réponse réelle, historique d’aide, correction et décision restent vides jusqu’à conservation d’une tentative. Révision technique, révision linguistique, exécution, adoption en production et publication exigent chacune leurs preuves applicables. Un calcul fini réussi établirait seulement l’opération déclarée dans ses hypothèses.

## Critère de réfutation annoncé

Tout point d’ombre fini annoncé pour le témoin parallèle hors plan contredit l’équation déclarée du rayon.

## Critères d’apprentissage préparés

- Pour l’exercice 1: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 2: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 3: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 4: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 5: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.

## Sources et périmètre des affirmations

- [Prérequis commité: sem-006-preserve-orientation-across-scene-frames](../../semiotics/en/sem-006-preserve-orientation-across-scene-frames.md)
- [Source de projet conservée](../../../../code/blender/scripts/atlas/kit.py)
- [Lecture primaire](https://pbr-book.org/4ed/Shapes/Basic_Shape_Interface)
- [Paquet construit](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-c.json)
- [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25-b/journal.md)
