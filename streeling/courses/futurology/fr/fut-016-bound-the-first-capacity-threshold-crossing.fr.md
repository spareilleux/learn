---
module_id: "fut-016-bound-the-first-capacity-threshold-crossing"
department: "futurology"
course: "Encadrer le premier franchissement d’un seuil de capacité"
level: "advanced"
prerequisites: ["fut-010-project-weave-density-before-a-scene-expansion"]
estimated_duration: "50 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Encadrer le premier franchissement d’un seuil de capacité

> Brouillon soumis à une revue technique et linguistique. Les entrées numériques et les résultats attendus sont des cas construits. Aucun nouvel essai de matériau, passage dans un moteur de scène, résultat apprenant ou résultat de production n’est fourni. Les décisions humaines et pédagogiques restent ouvertes.

## Opération du projet et interprétation

Une scène de broderie proposée augmente son inventaire de croisements à chaque période. Une date unique cache l’incertitude de cette hypothèse. Évaluez les deux facteurs de croissance indiqués sur le même horizon discret, puis cherchez la première période atteignant la capacité. La trajectoire rapide donne le franchissement le plus précoce et la lente le plus tardif parce que la valeur croît avec le facteur à chaque période positive. Un franchissement absent reste absent ; ne dépassez pas l’horizon et ne présentez pas ces bornes comme un intervalle de confiance.

Lisez le prérequis versionné et le passage précisément délimité de la source avant de calculer. Identifiez l’opération dont le projet a besoin, le sens de ses entrées et l’affirmation que le résultat pourrait étayer. Le dossier conserve la révision et le périmètre réellement consulté. Placez dans des colonnes distinctes une définition documentaire, une hypothèse construite et un résultat observé. Un assistant ne doit pas remplacer une observation absente par un récit plausible de ce que le logiciel ferait probablement.

Explicitez la représentation. Le JSON ci-dessous décrit une spécification mathématique finie ; ce n’est ni une syntaxe exécutable du projet ni une nouvelle fonction du moteur. Les noms de champs et l’ordre des identités font partie du cas pédagogique. Lisez la formule avec les valeurs : un nombre apparemment juste obtenu selon une autre interprétation ne répond pas à la tâche. Conservez les intermédiaires et le contrôle pour permettre à un relecteur de retrouver le premier désaccord. Les hypothèses sont volontairement étroites ; élargir leur domaine exige une justification supplémentaire.

## Modèle fixé et contrôle par changement d’entrée

```json
{
  "values": {
    "initial": 8,
    "growth_bounds": [
      1.25,
      1.5
    ],
    "capacity": 18,
    "last_period": 4
  },
  "formula": "load[t]=initial*growth**t for integer t in [0,last_period]; crossing=min(t with load[t]>=capacity), or null; earliest=min(non-null crossings); latest=max(crossings) only if all cross",
  "expected": {
    "paths": [
      [
        8,
        10,
        12.5,
        15.625,
        19.53125
      ],
      [
        8,
        12,
        18,
        27,
        40.5
      ]
    ],
    "crossings": [
      4,
      2
    ],
    "earliest": 2,
    "latest": 4
  },
  "negative_control": {
    "values": {
      "initial": 8,
      "growth_bounds": [
        1.25,
        1.5
      ],
      "capacity": 50,
      "last_period": 4
    },
    "expected": {
      "paths": [
        [
          8,
          10,
          12.5,
          15.625,
          19.53125
        ],
        [
          8,
          12,
          18,
          27,
          40.5
        ]
      ],
      "crossings": [
        null,
        null
      ],
      "earliest": null,
      "latest": null
    }
  }
}
```

### Exercice 1

Identifiez les entrées et l’opération à préserver.

<details><summary>Réponse 1</summary>

> **Réponse:** Les facteurs ordonnés sont `1.25` et `1.5` ; l’horizon inclut la période `0`.

</details>

### Exercice 2

Trouvez les deux premières périodes de franchissement et la fenêtre correspondante.

<details><summary>Réponse 2</summary>

> **Réponse:** Les premiers franchissements sont `[4,2]`, donc la fenêtre est `[2,4]`. L’égalité avec la capacité compte.

</details>

### Exercice 3

Expliquez le piège d’interprétation qu’un résumé pourrait cacher.

<details><summary>Réponse 3</summary>

> **Réponse:** Les bornes de croissance sont des hypothèses, pas des fréquences observées ni un intervalle de confiance.

</details>

### Exercice 4

Appliquez le contrôle modifié et comparez les résultats.

<details><summary>Réponse 4</summary>

> **Réponse:** Avec la capacité `50`, les deux franchissements sont `null` ; aucune trajectoire ne l’atteint jusqu’à la période `4`.

</details>

### Exercice 5

Précisez la limite et les preuves requises avant toute adoption.

<details><summary>Réponse 5</summary>

> **Réponse:** Mesurez la charge et calibrez la croissance avant d’adopter une date ; l’inventaire n’est pas un temps de rendu.

</details>

## Tâche avec sources et référence manuelle directe

Tabulez les deux trajectoires d’inventaire Atlas et marquez leur premier franchissement dans l’horizon retenu.

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

- [Prérequis versionné: fut-010-project-weave-density-before-a-scene-expansion](../../futurology/en/fut-010-project-weave-density-before-a-scene-expansion.md)
- [Artefact local conservé](../../../../code/blender/scripts/atlas/kit.py)
- [Lecture primaire](https://docs.python.org/3/library/math.html)
- [Dossier du cas construit](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-c.json)
- [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)
