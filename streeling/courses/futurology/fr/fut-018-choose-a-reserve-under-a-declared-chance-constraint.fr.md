---
module_id: "fut-018-choose-a-reserve-under-a-declared-chance-constraint"
department: "futurology"
course: "Choisir une réserve sous une contrainte probabiliste déclarée"
level: "advanced"
prerequisites: ["fut-012-budget-the-worst-tail-mass-of-a-renderer-scenario"]
estimated_duration: "50 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Choisir une réserve sous une contrainte probabiliste déclarée

> Brouillon soumis à une revue technique et linguistique. Les entrées numériques et les résultats attendus sont des cas construits. Aucun nouvel essai de matériau, passage dans un moteur de scène, résultat apprenant ou résultat de production n’est fourni. Les décisions humaines et pédagogiques restent ouvertes.

## Opération du projet et interprétation

Une file de captures artisanales proposée a besoin d’une réserve face à une demande incertaine. Au lieu de minimiser la moyenne ou la perte moyenne de la pire queue, imposez une limite à la probabilité de dépasser la capacité disponible. Énumérez les réserves candidates et sommez la masse des scénarios strictement supérieurs à cette capacité. L’égalité est servie. La plus petite réserve admissible dépend de la distribution fournie ; ses probabilités sont des hypothèses pédagogiques, pas une fiabilité mesurée ni une garantie d’absence de surcharge.

Lisez le prérequis versionné et le passage précisément délimité de la source avant de calculer. Identifiez l’opération dont le projet a besoin, le sens de ses entrées et l’affirmation que le résultat pourrait étayer. Le dossier conserve la révision et le périmètre réellement consulté. Placez dans des colonnes distinctes une définition documentaire, une hypothèse construite et un résultat observé. Un assistant ne doit pas remplacer une observation absente par un récit plausible de ce que le logiciel ferait probablement.

Explicitez la représentation. Le JSON ci-dessous décrit une spécification mathématique finie ; ce n’est ni une syntaxe exécutable du projet ni une nouvelle fonction du moteur. Les noms de champs et l’ordre des identités font partie du cas pédagogique. Lisez la formule avec les valeurs : un nombre apparemment juste obtenu selon une autre interprétation ne répond pas à la tâche. Conservez les intermédiaires et le contrôle pour permettre à un relecteur de retrouver le premier désaccord. Les hypothèses sont volontairement étroites ; élargir leur domaine exige une justification supplémentaire.

## Modèle fixé et contrôle par changement d’entrée

```json
{
  "values": {
    "demands": [
      8,
      10,
      14
    ],
    "probabilities": [
      0.5,
      0.3,
      0.2
    ],
    "base_capacity": 10,
    "reserves": [
      0,
      2,
      4
    ],
    "maximum_exceedance": 0.1
  },
  "formula": "p_exceed(r)=sum(probability[i] for demand[i]>base_capacity+r); passing=[r where p_exceed(r)<=maximum_exceedance]; choose minimum passing r or null",
  "expected": {
    "exceedance": [
      0.2,
      0.2,
      0
    ],
    "passing_reserves": [
      4
    ],
    "chosen_reserve": 4
  },
  "negative_control": {
    "values": {
      "demands": [
        8,
        10,
        14
      ],
      "probabilities": [
        0.5,
        0.3,
        0.2
      ],
      "base_capacity": 10,
      "reserves": [
        0,
        2,
        4
      ],
      "maximum_exceedance": 0.2
    },
    "expected": {
      "exceedance": [
        0.2,
        0.2,
        0
      ],
      "passing_reserves": [
        0,
        2,
        4
      ],
      "chosen_reserve": 0
    }
  }
}
```

### Exercice 1

Identifiez les entrées et l’opération à préserver.

<details><summary>Réponse 1</summary>

> **Réponse:** Utilisez un dépassement strict et des probabilités de scénario normalisées.

</details>

### Exercice 2

Calculez les probabilités de dépassement et identifiez la réserve admissible.

<details><summary>Réponse 2</summary>

> **Réponse:** Les probabilités de dépassement sont `[0.2,0.2,0]` ; seule la réserve `4` respecte la limite principale.

</details>

### Exercice 3

Expliquez le piège d’interprétation qu’un résumé pourrait cacher.

<details><summary>Réponse 3</summary>

> **Réponse:** La contrainte ne borne pas la gravité d’une surcharge lorsqu’elle survient.

</details>

### Exercice 4

Appliquez le contrôle modifié et comparez les résultats.

<details><summary>Réponse 4</summary>

> **Réponse:** Avec la limite `0.2`, tous les candidats passent et la plus petite réserve vaut `0`.

</details>

### Exercice 5

Précisez la limite et les preuves requises avant toute adoption.

<details><summary>Réponse 5</summary>

> **Réponse:** Calibrez les masses des scénarios et les coûts de réserve avant une décision de production.

</details>

## Tâche avec sources et référence manuelle directe

Énumérez les réserves d’une charge de capture Atlas et conservez les dépassements stricts pour chacune.

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

- [Prérequis versionné: fut-012-budget-the-worst-tail-mass-of-a-renderer-scenario](../../futurology/en/fut-012-budget-the-worst-tail-mass-of-a-renderer-scenario.md)
- [Artefact local conservé](../../../../code/blender/scripts/atlas/kit.py)
- [Lecture primaire](https://docs.python.org/3/library/math.html)
- [Dossier du cas construit](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-c.json)
- [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)
