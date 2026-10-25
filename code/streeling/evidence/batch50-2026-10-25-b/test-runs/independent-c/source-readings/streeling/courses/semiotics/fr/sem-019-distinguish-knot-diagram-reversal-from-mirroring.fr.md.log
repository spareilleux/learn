---
module_id: "sem-019-distinguish-knot-diagram-reversal-from-mirroring"
department: "semiotics"
course: "Distinguer inversion du parcours et miroir d’un diagramme de nœud"
level: "advanced"
prerequisites: ["sem-005-bind-scene-hits-to-crossing-identity"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Distinguer inversion du parcours et miroir d’un diagramme de nœud

> Brouillon pour révision technique et linguistique. Entrées numériques, étiquettes et résultats attendus sont des cas pédagogiques construits. Ils ne constituent ni nouveaux essais matériels physiques, ni exécutions natives de scène, ni observations d’apprentissage, ni résultats de production. Les décisions humaines et d’apprentissage restent indécises.

## Opération du projet et interprétation

Un ornement de nœud en miroir et le même ornement parcouru à l’envers peuvent conserver chaque identifiant de croisement tout en changeant des aspects différents du sens. Le cours sur la liaison des croisements ne décide pas du changement d’une annotation signée. Nous déclarons ici une convention d’écran orienté et calculons le signe depuis le déterminant des tangentes du brin dessus et du brin dessous. Cette table est construite ; elle ne reconstruit aucun nœud physique et ne prouve pas une courbe fermée plongée.

La somme des signes donne le writhe du diagramme. Inverser le parcours de toute la composante inverse les deux tangentes à chaque croisement ; le signe reste donc fixe. Réfléchir une coordonnée d’écran inverse l’orientation du plan et tous les signes. Gardez l’ordre dessus/dessous dans les deux opérations. Échanger ces rôles par erreur ajouterait une inversion et masquerait l’effet du miroir.

Les notes de Calegari distinguent writhe de diagramme et invariant d’isotopie ambiante : ajouter une boucle de Reidemeister le change. Le cours soutient donc une annotation bornée sur ce diagramme et ses transformations déclarées, sans test universel d’identité des nœuds. Un futur ornement [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md) ou [Godot](https://docs.godotengine.org/en/4.5/) devra conserver référents des croisements, orientation d’écran et historique avec le nombre. L’assistant ne peut conclure ni mêmes nœuds à partir de writhes égaux, ni types physiques différents à partir d’un changement de writhe.

Lisez le prérequis commité et le passage primaire délimité avant de calculer. Préparez un relevé séparant définition de source, prémisse construite, résultat dérivé et observation future. Une documentation ne soutient que l’affirmation située dans son périmètre lu. Paramètre de source, réponse mathématique et observation d’exécution ont des rôles de preuve différents ; un résumé assuré d’assistant ne peut les échanger. Le paquet conserve révision et périmètre de lecture pour permettre de contester une affirmation précise.

Travaillez d’abord réponses fermées. Dessinez la table ou le schéma requis et conservez les quantités intermédiaires, avec unités ou conventions d’identité. Cette dérivation manuscrite est la référence manuelle directe. Consultez seulement ensuite un assistant ou une aide à la traduction. Gardez la question, l’emplacement cité, la suggestion reçue et la modification acceptée ou rejetée. Comparez le résultat assisté à la première tentative conservée sur les mêmes entrées. Une réponse plus courte ne constitue pas un progrès si elle omet une condition ou invente un essai terminé.

## Modèle fixe et témoin à entrée modifiée

```json
{
  "values": {
    "over_tangents": [
      [
        1,
        0
      ],
      [
        0,
        1
      ],
      [
        1,
        1
      ]
    ],
    "under_tangents": [
      [
        0,
        1
      ],
      [
        1,
        0
      ],
      [
        -1,
        1
      ]
    ],
    "operation": "reverse"
  },
  "formula": "crossing_sign=sign(det(over,under)) in a declared oriented screen frame; writhe=sum(signs); reverse negates both tangents at every crossing; mirror negates x components; recompute signs and writhe",
  "expected": {
    "original_signs": [
      1,
      -1,
      1
    ],
    "original_writhe": 1,
    "transformed_signs": [
      1,
      -1,
      1
    ],
    "transformed_writhe": 1
  },
  "negative_control": {
    "values": {
      "over_tangents": [
        [
          1,
          0
        ],
        [
          0,
          1
        ],
        [
          1,
          1
        ]
      ],
      "under_tangents": [
        [
          0,
          1
        ],
        [
          1,
          0
        ],
        [
          -1,
          1
        ]
      ],
      "operation": "mirror"
    },
    "expected": {
      "original_signs": [
        1,
        -1,
        1
      ],
      "original_writhe": 1,
      "transformed_signs": [
        -1,
        1,
        -1
      ],
      "transformed_writhe": -1
    }
  }
}
```

### Exercice 1

Calculez déterminants et signes initiaux.

<details><summary>Réponse 1</summary>

Les déterminants valent `[1,-1,2]`, donc les signes `[1,-1,1]`. La norme ne pondère pas la somme signée.

</details>

### Exercice 2

Calculez le writhe du diagramme.

<details><summary>Réponse 2</summary>

Il vaut `1`. Comptez chaque croisement déclaré une seule fois, pas chaque rencontre au cours du parcours.

</details>

### Exercice 3

Inversez les deux tangentes.

<details><summary>Réponse 3</summary>

Les signes restent `[1,-1,1]` et le writhe `1`. La bilinéarité conserve le déterminant lorsque ses deux arguments changent de signe.

</details>

### Exercice 4

Appliquez le témoin miroir.

<details><summary>Réponse 4</summary>

Les signes deviennent `[-1,1,-1]` et le writhe `-1`. L’orientation plane change sans modifier les référents dessus/dessous.

</details>

### Exercice 5

Le writhe certifie-t-il le type de nœud ?

<details><summary>Réponse 5</summary>

Non. Une boucle de Reidemeister-I change le writhe du diagramme en préservant le type ambiant. Une somme égale oublie aussi l’agencement.

</details>

## Travail avec sources et référence manuelle directe

Dessinez les paires de tangentes orientées et conservez les étiquettes lors de l’inversion et du miroir. Préparez une légende d’ornement précisant la transformation de diagramme testée par le nombre signé.

Traitez le témoin comme un enregistrement distinct. Préservez le cas principal, écrivez une prédiction pour l’entrée modifiée et expliquez quelle prémisse change. En cas d’écart avec la première réponse, distinguez erreur de calcul, erreur d’interprétation et limite du modèle. Gardez tentative échouée et correction côte à côte. Le travail demande une note vérifiable avant de proposer un nœud DSL ou un flux d’agents ; une table manuelle peut déjà répondre au besoin.

Soumettez ensemble référence initiale, emplacements de sources, explication corrigée, résultat du témoin et critère de réfutation. Les critères préparés ci-dessous s’adressent à une révision future ; ils ne sont pas des apprentissages acceptés. Réponse réelle, historique d’aide, correction et décision restent vides jusqu’à conservation d’une tentative. Révision technique, révision linguistique, exécution, adoption en production et publication exigent chacune leurs preuves applicables. Un calcul fini réussi établirait seulement l’opération déclarée dans ses hypothèses.

## Critère de réfutation annoncé

Une annotation affirmant que l’inversion du parcours inverse tous les signes est réfutée par les déterminants inchangés.

## Critères d’apprentissage préparés

- Pour l’exercice 1: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 2: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 3: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 4: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 5: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.

## Sources et périmètre des affirmations

- [Prérequis commité: sem-005-bind-scene-hits-to-crossing-identity](../../semiotics/en/sem-005-bind-scene-hits-to-crossing-identity.md)
- [Source de projet conservée](../../../../code/streeling/weave-godot/trial.gd)
- [Lecture primaire](https://math.uchicago.edu/~dannyc/notes/knot_theory.pdf)
- [Paquet construit](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-c.json)
- [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25-b/journal.md)
