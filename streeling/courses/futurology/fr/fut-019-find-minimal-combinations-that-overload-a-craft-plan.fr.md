---
module_id: "fut-019-find-minimal-combinations-that-overload-a-craft-plan"
department: "futurology"
course: "Trouver les combinaisons minimales qui surchargent un plan artisanal"
level: "advanced"
prerequisites: ["fut-008-stress-test-a-release-plan-against-review-backlogs", "phi-013-explain-an-infeasible-craft-plan-with-a-minimal-core"]
estimated_duration: "50 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Trouver les combinaisons minimales qui surchargent un plan artisanal

> Brouillon soumis à une revue technique et linguistique. Les entrées numériques et les résultats attendus sont des cas construits. Aucun nouvel essai de matériau, passage dans un moteur de scène, résultat apprenant ou résultat de production n’est fourni. Les décisions humaines et pédagogiques restent ouvertes.

## Opération du projet et interprétation

Inversez la question de planification : au lieu de choisir un scénario favorable, cherchez quelles combinaisons de surcroîts déclarés font dépasser la capacité. Énumérez les sous-ensembles et retenez une surcharge uniquement si aucun sous-ensemble propre ne surcharge. Minimal signifie minimal pour l’inclusion, pas le moins probable, le moins coûteux ni le plus faible en magnitude. Un surcroît peut représenter un détail ou une reprise supplémentaire, mais son effet reste une hypothèse. Le résultat prépare des combinaisons à éprouver, pas une prévision ni le diagnostic d’un incident réel.

Lisez le prérequis versionné et le passage précisément délimité de la source avant de calculer. Identifiez l’opération dont le projet a besoin, le sens de ses entrées et l’affirmation que le résultat pourrait étayer. Le dossier conserve la révision et le périmètre réellement consulté. Placez dans des colonnes distinctes une définition documentaire, une hypothèse construite et un résultat observé. Un assistant ne doit pas remplacer une observation absente par un récit plausible de ce que le logiciel ferait probablement.

Explicitez la représentation. Le JSON ci-dessous décrit une spécification mathématique finie ; ce n’est ni une syntaxe exécutable du projet ni une nouvelle fonction du moteur. Les noms de champs et l’ordre des identités font partie du cas pédagogique. Lisez la formule avec les valeurs : un nombre apparemment juste obtenu selon une autre interprétation ne répond pas à la tâche. Conservez les intermédiaires et le contrôle pour permettre à un relecteur de retrouver le premier désaccord. Les hypothèses sont volontairement étroites ; élargir leur domaine exige une justification supplémentaire.

## Modèle fixé et contrôle par changement d’entrée

```json
{
  "values": {
    "base_load": 5,
    "capacity": 10,
    "increments": {
      "A": 3,
      "B": 3,
      "C": 1
    }
  },
  "formula": "load(S)=base_load+sum(increments[x] for x in S); overload iff load(S)>capacity; return inclusion-minimal overloading subsets in lexicographic order",
  "expected": {
    "minimal_overloads": [
      [
        "A",
        "B"
      ]
    ],
    "loads": [
      11
    ]
  },
  "negative_control": {
    "values": {
      "base_load": 5,
      "capacity": 8,
      "increments": {
        "A": 3,
        "B": 3,
        "C": 1
      }
    },
    "expected": {
      "minimal_overloads": [
        [
          "A",
          "B"
        ],
        [
          "A",
          "C"
        ],
        [
          "B",
          "C"
        ]
      ],
      "loads": [
        11,
        9,
        9
      ]
    }
  }
}
```

### Exercice 1

Identifiez les entrées et l’opération à préserver.

<details><summary>Réponse 1</summary>

> **Réponse:** Les surcroîts s’ajoutent à la même référence ; ce sont des contributions construites non négatives.

</details>

### Exercice 2

Identifiez toutes les surcharges minimales principales et leur charge.

<details><summary>Réponse 2</summary>

> **Réponse:** Seul `[A,B]` est une surcharge minimale du cas principal, avec une charge de `11`.

</details>

### Exercice 3

Expliquez le piège d’interprétation qu’un résumé pourrait cacher.

<details><summary>Réponse 3</summary>

> **Réponse:** Le surensemble `[A,B,C]` surcharge mais n’est pas minimal puisqu’il contient un sous-ensemble déjà surchargé.

</details>

### Exercice 4

Appliquez le contrôle modifié et comparez les résultats.

<details><summary>Réponse 4</summary>

> **Réponse:** Avec la capacité `8`, les combinaisons minimales sont `[[A,B],[A,C],[B,C]]`, de charges `[11,9,9]`.

</details>

### Exercice 5

Précisez la limite et les preuves requises avant toute adoption.

<details><summary>Réponse 5</summary>

> **Réponse:** L’énumération ne fournit ni classement probabiliste ni contribution causale réelle.

</details>

## Tâche avec sources et référence manuelle directe

Dessinez le treillis des surcroîts Atlas proposés et justifiez la minimalité de chaque surcharge retenue.

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

- [Prérequis versionné: fut-008-stress-test-a-release-plan-against-review-backlogs](../../futurology/en/fut-008-stress-test-a-release-plan-against-review-backlogs.md)
- [Prérequis versionné: phi-013-explain-an-infeasible-craft-plan-with-a-minimal-core](../../philosophy/en/phi-013-explain-an-infeasible-craft-plan-with-a-minimal-core.md)
- [Artefact local conservé](../../../../code/blender/scripts/atlas/kit.py)
- [Lecture primaire](https://docs.python.org/3/library/itertools.html#itertools.combinations)
- [Dossier du cas construit](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-c.json)
- [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)
