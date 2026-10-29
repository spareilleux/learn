---
module_id: "sem-023-keep-points-and-displacements-distinct-under-translation"
department: "semiotics"
course: "Distinguer points et déplacements lors d’une translation"
level: "advanced"
prerequisites: ["sem-009-keep-units-in-a-composed-craft-instruction", "sem-006-preserve-orientation-across-scene-frames"]
estimated_duration: "50 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Distinguer points et déplacements lors d’une translation

> Brouillon soumis à une revue technique et linguistique. Les entrées numériques et les résultats attendus sont des cas construits. Aucun nouvel essai de matériau, passage dans un moteur de scène, résultat apprenant ou résultat de production n’est fourni. Les décisions humaines et pédagogiques restent ouvertes.

## Opération du projet et interprétation

Un DSL artisanal utilise les mêmes tableaux pour position et déplacement, puis les translate tous deux par l’origine du repère. Les unités ne détectent pas cette erreur : les deux sont des longueurs, mais seuls les points reçoivent l’origine. Avec une base identité, translatez les deux points puis soustrayez-les pour retrouver le déplacement inchangé. Conservez le rôle affine avec la valeur avant composition. Cela isole la translation sans rotation ni échelle et n’ajoute aucun adaptateur de scène. Un déplacement n’est pas une normale ; une différence correcte ne vérifie ni import ni mesure physique.

Lisez le prérequis versionné et le passage précisément délimité de la source avant de calculer. Identifiez l’opération dont le projet a besoin, le sens de ses entrées et l’affirmation que le résultat pourrait étayer. Le dossier conserve la révision et le périmètre réellement consulté. Placez dans des colonnes distinctes une définition documentaire, une hypothèse construite et un résultat observé. Un assistant ne doit pas remplacer une observation absente par un récit plausible de ce que le logiciel ferait probablement.

Explicitez la représentation. Le JSON ci-dessous décrit une spécification mathématique finie ; ce n’est ni une syntaxe exécutable du projet ni une nouvelle fonction du moteur. Les noms de champs et l’ordre des identités font partie du cas pédagogique. Lisez la formule avec les valeurs : un nombre apparemment juste obtenu selon une autre interprétation ne répond pas à la tâche. Conservez les intermédiaires et le contrôle pour permettre à un relecteur de retrouver le premier désaccord. Les hypothèses sont volontairement étroites ; élargir leur domaine exige une justification supplémentaire.

## Modèle fixé et contrôle par changement d’entrée

```json
{
  "values": {
    "p": [
      1,
      2,
      0
    ],
    "q": [
      4,
      6,
      0
    ],
    "translation": [
      10,
      -2,
      5
    ]
  },
  "formula": "point_world=p+translation componentwise; displacement=q-p; translated_difference=(q+translation)-(p+translation); never add translation to a displacement",
  "expected": {
    "p_world": [
      11,
      0,
      5
    ],
    "q_world": [
      14,
      4,
      5
    ],
    "displacement": [
      3,
      4,
      0
    ],
    "translated_difference": [
      3,
      4,
      0
    ]
  },
  "negative_control": {
    "values": {
      "p": [
        1,
        2,
        0
      ],
      "q": [
        4,
        6,
        0
      ],
      "translation": [
        -5,
        8,
        1
      ]
    },
    "expected": {
      "p_world": [
        -4,
        10,
        1
      ],
      "q_world": [
        -1,
        14,
        1
      ],
      "displacement": [
        3,
        4,
        0
      ],
      "translated_difference": [
        3,
        4,
        0
      ]
    }
  }
}
```

### Exercice 1

Identifiez les entrées et l’opération à préserver.

<details><summary>Réponse 1</summary>

> **Réponse:** Les deux opérandes ont des unités de longueur mais des rôles affines différents.

</details>

### Exercice 2

Calculez les deux points mondiaux et leur différence relative.

<details><summary>Réponse 2</summary>

> **Réponse:** Les points mondiaux sont `[11,0,5]` et `[14,4,5]` ; leur différence vaut `[3,4,0]`.

</details>

### Exercice 3

Expliquez le piège d’interprétation qu’un résumé pourrait cacher.

<details><summary>Réponse 3</summary>

> **Réponse:** Translater le déplacement lui attacherait incorrectement une origine.

</details>

### Exercice 4

Appliquez le contrôle modifié et comparez les résultats.

<details><summary>Réponse 4</summary>

> **Réponse:** Les points du contrôle sont `[-4,10,1]` et `[-1,14,1]` ; la différence reste `[3,4,0]`.

</details>

### Exercice 5

Précisez la limite et les preuves requises avant toute adoption.

<details><summary>Réponse 5</summary>

> **Réponse:** Rotation, échelle, normales et import réel nécessitent d’autres transformations déclarées et d’autres preuves.

</details>

## Tâche avec sources et référence manuelle directe

Annotez les positions Atlas et leurs différences avec leurs rôles affines avant de changer seulement l’origine proposée.

En masquant les réponses, dessinez un tableau ou un schéma propre à l’opération, puis calculez le résultat principal à la main. Cette première tentative conservée constitue la référence manuelle directe. Indiquez les entrées, les intermédiaires, la règle de chaque étape et la raison de tout refus ou résultat indéterminé. Énoncez le critère de réfutation avant de demander à un assistant de simplifier le travail. Un tableau ordinaire peut suffire au projet ; un DSL composable ou un nœud agentique doit apporter un bénéfice supplémentaire démontré.

Consultez ensuite l’artefact local et le passage primaire liés. Notez l’emplacement, la révision, la définition utilisée et ce qu’elle ne permet pas d’établir. Demandez à un assistant de contester une hypothèse et conservez la question et sa réponse. Déclarez comme aide tout usage de calculatrice, de traduction ou de recherche documentaire. Comparez le résultat aidé à la référence initiale avec les mêmes entrées. Rejetez une explication plus courte si elle supprime une identité, une condition ou la distinction entre exemple construit et observation du projet.

Traitez le contrôle négatif comme un enregistrement séparé. Prédisez son résultat avant de lire la correction, puis comparez les champs modifiés et les invariants. En cas de désaccord, distinguez erreur de calcul, erreur de sens et limite des hypothèses. Conservez l’échec, son diagnostic, sa correction et sa reprise ; n’effacez pas la première tentative. Remettez ces traces avec l’explication documentée et les incertitudes restantes. Cette petite boucle d’amélioration pourra servir au dogfooding, mais aucune amélioration réelle d’apprentissage ou d’exécution n’a été mesurée ici.

Le dossier prépare un critère par exercice sans remplir les décisions pédagogiques. La réponse réelle, l’historique d’aide, la correction personnelle et la décision restent vides tant qu’aucune tentative n’existe. Revue technique, revue linguistique, exécution dans le moteur, validation matérielle, adoption et publication nécessitent des preuves distinctes. Le calcul fini n’établit que la relation annoncée sous ses hypothèses. Avant de l’utiliser dans une scène ou un outil de pratique, précisez l’observation supplémentaire et son seuil de rejet ; un corrigé préparé ne vaut pas acceptation.

## Critère prospectif de réfutation

Une réponse proposée est rejetée si l’application de l’opération affichée à une entrée conservée contredit le résultat attendu, ou si son explication présente ce cas construit comme une observation déjà réalisée dans le projet.

## Critères préparés pour l’apprenant

- Conserver la réponse correcte et le raisonnement intermédiaire de l’exercice 1, ainsi que la portée de l’affirmation. La décision pédagogique reste ouverte.
- Conserver la réponse correcte et le raisonnement intermédiaire de l’exercice 2, ainsi que la portée de l’affirmation. La décision pédagogique reste ouverte.
- Conserver la réponse correcte et le raisonnement intermédiaire de l’exercice 3, ainsi que la portée de l’affirmation. La décision pédagogique reste ouverte.
- Conserver la réponse correcte et le raisonnement intermédiaire de l’exercice 4, ainsi que la portée de l’affirmation. La décision pédagogique reste ouverte.
- Conserver la réponse correcte et le raisonnement intermédiaire de l’exercice 5, ainsi que la portée de l’affirmation. La décision pédagogique reste ouverte.

## Sources et portée des affirmations

- [Prérequis versionné: sem-009-keep-units-in-a-composed-craft-instruction](../../semiotics/en/sem-009-keep-units-in-a-composed-craft-instruction.md)
- [Prérequis versionné: sem-006-preserve-orientation-across-scene-frames](../../semiotics/en/sem-006-preserve-orientation-across-scene-frames.md)
- [Artefact local conservé](../../../../code/blender/scripts/atlas/kit.py)
- [Lecture primaire](https://docs.godotengine.org/en/stable/classes/class_transform3d.html)
- [Dossier du cas construit](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-c.json)
- [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)
