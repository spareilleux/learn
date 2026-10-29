---
module_id: "phi-017-retract-a-craft-default-when-a-defeater-arrives"
department: "philosophy"
course: "Retirer une conclusion par défaut quand un réfutateur arrive"
level: "advanced"
prerequisites: ["phi-008-separate-a-test-oracle-from-a-specification", "phi-009-state-who-may-authorize-an-agent-effect"]
estimated_duration: "50 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Retirer une conclusion par défaut quand un réfutateur arrive

> Brouillon soumis à une revue technique et linguistique. Les entrées numériques et les résultats attendus sont des cas construits. Aucun nouvel essai de matériau, passage dans un moteur de scène, résultat apprenant ou résultat de production n’est fourni. Les décisions humaines et pédagogiques restent ouvertes.

## Opération du projet et interprétation

Un transfert artisanal proposé considère provisoirement un objet identifié comme utilisable en l’absence de fait contraire connu. C’est une règle par défaut révisable, pas une implication stricte à partir de la catégorie objet. Précisez la règle par défaut normale et la règle stricte allant de fragile à non utilisable. Fermez d’abord les faits stricts, puis vérifiez si l’unique règle par défaut peut s’appliquer sans contradiction. Une information supplémentaire peut retirer la conclusion provisoire. Ce fragment traite une seule règle par défaut avec des faits cohérents ; il ne fournit ni validation matérielle ni autorisation d’effet.

Lisez le prérequis versionné et le passage précisément délimité de la source avant de calculer. Identifiez l’opération dont le projet a besoin, le sens de ses entrées et l’affirmation que le résultat pourrait étayer. Le dossier conserve la révision et le périmètre réellement consulté. Placez dans des colonnes distinctes une définition documentaire, une hypothèse construite et un résultat observé. Un assistant ne doit pas remplacer une observation absente par un récit plausible de ce que le logiciel ferait probablement.

Explicitez la représentation. Le JSON ci-dessous décrit une spécification mathématique finie ; ce n’est ni une syntaxe exécutable du projet ni une nouvelle fonction du moteur. Les noms de champs et l’ordre des identités font partie du cas pédagogique. Lisez la formule avec les valeurs : un nombre apparemment juste obtenu selon une autre interprétation ne répond pas à la tâche. Conservez les intermédiaires et le contrôle pour permettre à un relecteur de retrouver le premier désaccord. Les hypothèses sont volontairement étroites ; élargir leur domaine exige une justification supplémentaire.

## Modèle fixé et contrôle par changement d’entrée

```json
{
  "values": {
    "facts": [
      "asset"
    ],
    "strict_rule": [
      "fragile",
      "not_usable"
    ],
    "normal_default": {
      "prerequisite": "asset",
      "justification": "usable",
      "conclusion": "usable"
    }
  },
  "formula": "close facts under fragile=>not_usable; for this sole normal default, add usable iff asset present and not_usable absent; return sorted literals and default_fired",
  "expected": {
    "literals": [
      "asset",
      "usable"
    ],
    "default_fired": true
  },
  "negative_control": {
    "values": {
      "facts": [
        "asset",
        "fragile"
      ],
      "strict_rule": [
        "fragile",
        "not_usable"
      ],
      "normal_default": {
        "prerequisite": "asset",
        "justification": "usable",
        "conclusion": "usable"
      }
    },
    "expected": {
      "literals": [
        "asset",
        "fragile",
        "not_usable"
      ],
      "default_fired": false
    }
  }
}
```

### Exercice 1

Identifiez les entrées et l’opération à préserver.

<details><summary>Réponse 1</summary>

> **Réponse:** La règle par défaut possède une condition de cohérence ; l’absence de preuve contraire n’est pas une vérité observée.

</details>

### Exercice 2

Trouvez l’ensemble principal de littéraux et déterminez si la règle par défaut s’applique.

<details><summary>Réponse 2</summary>

> **Réponse:** L’ensemble principal est `[asset,usable]` et `default_fired` vaut `true`.

</details>

### Exercice 3

Expliquez le piège d’interprétation qu’un résumé pourrait cacher.

<details><summary>Réponse 3</summary>

> **Réponse:** Une implication stricte conserve sa conclusion après ajout de faits ; cette règle par défaut peut la retirer.

</details>

### Exercice 4

Appliquez le contrôle modifié et comparez les résultats.

<details><summary>Réponse 4</summary>

> **Réponse:** Le contrôle donne `[asset,fragile,not_usable]` et `default_fired` vaut `false` ; `usable` est absent.

</details>

### Exercice 5

Précisez la limite et les preuves requises avant toute adoption.

<details><summary>Réponse 5</summary>

> **Réponse:** Une inférence provisoire n’établit pas une propriété matérielle et n’autorise pas la publication.

</details>

## Tâche avec sources et référence manuelle directe

Conservez un relevé avant/après d’inférence par défaut ; marquez le réfutateur ultérieur et la conclusion retirée.

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

- [Prérequis versionné: phi-008-separate-a-test-oracle-from-a-specification](../../philosophy/en/phi-008-separate-a-test-oracle-from-a-specification.md)
- [Prérequis versionné: phi-009-state-who-may-authorize-an-agent-effect](../../philosophy/en/phi-009-state-who-may-authorize-an-agent-effect.md)
- [Artefact local conservé](../../../../code/streeling/evidence/representation-release-2026-10-22/phi002-schema-replay.json)
- [Lecture primaire](https://plato.stanford.edu/entries/logic-nonmonotonic/)
- [Dossier du cas construit](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-c.json)
- [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)
