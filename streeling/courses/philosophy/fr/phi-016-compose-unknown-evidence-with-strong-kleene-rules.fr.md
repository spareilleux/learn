---
module_id: "phi-016-compose-unknown-evidence-with-strong-kleene-rules"
department: "philosophy"
course: "Composer une preuve inconnue selon les règles fortes de Kleene"
level: "advanced"
prerequisites: ["phi-001-how-to-argue-well", "sem-003-status-signs-and-evidence"]
estimated_duration: "50 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Composer une preuve inconnue selon les règles fortes de Kleene

> Brouillon soumis à une revue technique et linguistique. Les entrées numériques et les résultats attendus sont des cas construits. Aucun nouvel essai de matériau, passage dans un moteur de scène, résultat apprenant ou résultat de production n’est fourni. Les décisions humaines et pédagogiques restent ouvertes.

## Opération du projet et interprétation

Un résumé de preuve [Demerzel](https://github.com/GuitarAlchemist/Demerzel) contient une proposition indéterminée. Transformer l’inconnu en faux fait inventer une preuve positive à sa négation ; le transformer en vrai invente aussi une preuve. Déclarez une interprétation forte de Kleene avec faux, inconnu et vrai dans cet ordre. La conjonction prend le minimum, la disjonction le maximum et la négation conserve l’inconnu. C’est une interprétation proposée pour raisonner, pas un contrôle déployé. L’inconnu désigne ici un statut indisponible, pas des preuves contradictoires ni une probabilité intermédiaire.

Lisez le prérequis versionné et le passage précisément délimité de la source avant de calculer. Identifiez l’opération dont le projet a besoin, le sens de ses entrées et l’affirmation que le résultat pourrait étayer. Le dossier conserve la révision et le périmètre réellement consulté. Placez dans des colonnes distinctes une définition documentaire, une hypothèse construite et un résultat observé. Un assistant ne doit pas remplacer une observation absente par un récit plausible de ce que le logiciel ferait probablement.

Explicitez la représentation. Le JSON ci-dessous décrit une spécification mathématique finie ; ce n’est ni une syntaxe exécutable du projet ni une nouvelle fonction du moteur. Les noms de champs et l’ordre des identités font partie du cas pédagogique. Lisez la formule avec les valeurs : un nombre apparemment juste obtenu selon une autre interprétation ne répond pas à la tâche. Conservez les intermédiaires et le contrôle pour permettre à un relecteur de retrouver le premier désaccord. Les hypothèses sont volontairement étroites ; élargir leur domaine exige une justification supplémentaire.

## Modèle fixé et contrôle par changement d’entrée

```json
{
  "values": {
    "p": "U",
    "q": "F",
    "order": [
      "F",
      "U",
      "T"
    ]
  },
  "formula": "AND=min and OR=max under F<U<T; NOT swaps F and T and preserves U; excluded_middle=OR(p,NOT(p))",
  "expected": {
    "and": "F",
    "or": "U",
    "not_p": "U",
    "excluded_middle": "U"
  },
  "negative_control": {
    "values": {
      "p": "U",
      "q": "T",
      "order": [
        "F",
        "U",
        "T"
      ]
    },
    "expected": {
      "and": "U",
      "or": "T",
      "not_p": "U",
      "excluded_middle": "U"
    }
  }
}
```

### Exercice 1

Identifiez les entrées et l’opération à préserver.

<details><summary>Réponse 1</summary>

> **Réponse:** `U` désigne un statut indéterminé, pas faux ni un score de confiance.

</details>

### Exercice 2

Évaluez la conjonction, la disjonction et la négation principales.

<details><summary>Réponse 2</summary>

> **Réponse:** La conjonction vaut `F`, la disjonction `U` et la négation `U`.

</details>

### Exercice 3

Expliquez le piège d’interprétation qu’un résumé pourrait cacher.

<details><summary>Réponse 3</summary>

> **Réponse:** Le tiers exclu vaut `U` ; importer la table classique changerait l’interprétation déclarée.

</details>

### Exercice 4

Appliquez le contrôle modifié et comparez les résultats.

<details><summary>Réponse 4</summary>

> **Réponse:** La conjonction du contrôle vaut `U` et la disjonction `T` ; la négation reste `U`.

</details>

### Exercice 5

Précisez la limite et les preuves requises avant toute adoption.

<details><summary>Réponse 5</summary>

> **Réponse:** Une politique réelle exige sa règle d’action et ses preuves liées ; cette table n’autorise rien.

</details>

## Tâche avec sources et référence manuelle directe

Préparez un relevé de valeurs de vérité près de la reprise du schéma Demerzel, sans en faire une exécution de politique.

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

- [Prérequis versionné: phi-001-how-to-argue-well](../../philosophy/en/phi-001-how-to-argue-well.md)
- [Prérequis versionné: sem-003-status-signs-and-evidence](../../semiotics/en/sem-003-status-signs-and-evidence.md)
- [Artefact local conservé](../../../../code/streeling/evidence/representation-release-2026-10-22/phi002-schema-replay.json)
- [Lecture primaire](https://plato.stanford.edu/entries/logic-manyvalued/)
- [Dossier du cas construit](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-c.json)
- [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)
