---
module_id: "dv-024-recover-layer-values-from-stacked-endpoints"
department: "data-visualization"
course: "Retrouver les valeurs des couches à partir des extrémités empilées"
level: "advanced"
prerequisites: ["dv-006-position-length-area-comparisons"]
estimated_duration: "50 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Retrouver les valeurs des couches à partir des extrémités empilées

> Brouillon soumis à une revue technique et linguistique. Les entrées numériques et les résultats attendus sont des cas construits. Aucun nouvel essai de matériau, passage dans un moteur de scène, résultat apprenant ou résultat de production n’est fourni. Les décisions humaines et pédagogiques restent ouvertes.

## Opération du projet et interprétation

Un tableau de bord empile le temps de préparation et de correction d’objets [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md). L’extrémité supérieure représente l’effort total, alors que le segment supérieur représente seulement la correction. Retrouvez chaque couche en soustrayant les extrémités cumulées voisines avant de comparer les objets. Des totaux égaux peuvent cacher des corrections différentes ; des corrections égales peuvent aboutir à des extrémités différentes si la préparation varie. Cette opération inverse dépasse le choix d’une échelle commune et ne suppose aucun traitement réel.

Lisez le prérequis versionné et le passage précisément délimité de la source avant de calculer. Identifiez l’opération dont le projet a besoin, le sens de ses entrées et l’affirmation que le résultat pourrait étayer. Le dossier conserve la révision et le périmètre réellement consulté. Placez dans des colonnes distinctes une définition documentaire, une hypothèse construite et un résultat observé. Un assistant ne doit pas remplacer une observation absente par un récit plausible de ce que le logiciel ferait probablement.

Explicitez la représentation. Le JSON ci-dessous décrit une spécification mathématique finie ; ce n’est ni une syntaxe exécutable du projet ni une nouvelle fonction du moteur. Les noms de champs et l’ordre des identités font partie du cas pédagogique. Lisez la formule avec les valeurs : un nombre apparemment juste obtenu selon une autre interprétation ne répond pas à la tâche. Conservez les intermédiaires et le contrôle pour permettre à un relecteur de retrouver le premier désaccord. Les hypothèses sont volontairement étroites ; élargir leur domaine exige une justification supplémentaire.

## Modèle fixé et contrôle par changement d’entrée

```json
{
  "values": {
    "endpoints": [
      [
        0,
        2,
        8
      ],
      [
        0,
        5,
        8
      ]
    ]
  },
  "formula": "layers[j]=endpoints[j+1]-endpoints[j]; compare final endpoints separately from last-layer differences",
  "expected": {
    "layers": [
      [
        2,
        6
      ],
      [
        5,
        3
      ]
    ],
    "equal_totals": true,
    "equal_last_layers": false
  },
  "negative_control": {
    "values": {
      "endpoints": [
        [
          0,
          2,
          8
        ],
        [
          0,
          5,
          11
        ]
      ]
    },
    "expected": {
      "layers": [
        [
          2,
          6
        ],
        [
          5,
          6
        ]
      ],
      "equal_totals": false,
      "equal_last_layers": true
    }
  }
}
```

### Exercice 1

Identifiez les entrées et l’opération à préserver.

<details><summary>Réponse 1</summary>

> **Réponse:** Les tableaux contiennent des extrémités cumulées avec leur origine, pas des valeurs de couche indépendantes.

</details>

### Exercice 2

Retrouvez les valeurs des couches et distinguez égalité des totaux et des couches de correction.

<details><summary>Réponse 2</summary>

> **Réponse:** Les différences voisines donnent `[[2,6],[5,3]]` ; les totaux coïncident mais les corrections diffèrent.

</details>

### Exercice 3

Expliquez le piège d’interprétation qu’un résumé pourrait cacher.

<details><summary>Réponse 3</summary>

> **Réponse:** Comparer les extrémités supérieures compare les totaux, pas l’effort de correction.

</details>

### Exercice 4

Appliquez le contrôle modifié et comparez les résultats.

<details><summary>Réponse 4</summary>

> **Réponse:** Le contrôle donne `[[2,6],[5,6]]` ; les dernières couches coïncident alors que les totaux diffèrent.

</details>

### Exercice 5

Précisez la limite et les preuves requises avant toute adoption.

<details><summary>Réponse 5</summary>

> **Réponse:** Il faut des étapes identifiées, une unité commune et des temps réellement observés avant de conclure à une amélioration.

</details>

## Tâche avec sources et référence manuelle directe

Dessinez les extrémités cumulées d’un suivi de traitement Atlas, retrouvez les étapes puis distinguez égalité des totaux et des dernières couches.

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

- [Prérequis versionné: dv-006-position-length-area-comparisons](../../data-visualization/en/dv-006-position-length-area-comparisons.md)
- [Artefact local conservé](../../../../code/blender/scripts/atlas/kit.py)
- [Lecture primaire](https://d3js.org/d3-shape/stack)
- [Dossier du cas construit](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-c.json)
- [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)
