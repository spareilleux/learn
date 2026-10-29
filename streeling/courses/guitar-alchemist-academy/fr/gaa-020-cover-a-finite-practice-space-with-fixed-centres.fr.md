---
module_id: "gaa-020-cover-a-finite-practice-space-with-fixed-centres"
department: "guitar-alchemist-academy"
course: "Couvrir un espace fini d’exercices avec des centres fixés"
level: "advanced"
prerequisites: ["gaa-013-choose-a-voicing-diversity-key-for-the-task"]
estimated_duration: "50 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Couvrir un espace fini d’exercices avec des centres fixés

> Brouillon soumis à une revue technique et linguistique. Les entrées numériques et les résultats attendus sont des cas construits. Aucun nouvel essai de matériau, passage dans un moteur de scène, résultat apprenant ou résultat de production n’est fourni. Les décisions humaines et pédagogiques restent ouvertes.

## Opération du projet et interprétation

Une sélection [GA](https://github.com/GuitarAlchemist/ga) peut contenir des voicings distincts tout en laissant une région de l’espace déclaré loin des exercices retenus. Fixez les positions, la distance et le budget, puis minimisez la plus grande distance d’un candidat à son centre choisi le plus proche. L’énumération rend ce petit problème discret de centres exact ; ce n’est ni une garantie gloutonne ni une similarité musicale apprise. Au-delà du décompte de clés de diversité, on mesure ici le candidat le moins bien couvert. Un petit rayon ne prouve aucun transfert pour le guitariste.

Lisez le prérequis versionné et le passage précisément délimité de la source avant de calculer. Identifiez l’opération dont le projet a besoin, le sens de ses entrées et l’affirmation que le résultat pourrait étayer. Le dossier conserve la révision et le périmètre réellement consulté. Placez dans des colonnes distinctes une définition documentaire, une hypothèse construite et un résultat observé. Un assistant ne doit pas remplacer une observation absente par un récit plausible de ce que le logiciel ferait probablement.

Explicitez la représentation. Le JSON ci-dessous décrit une spécification mathématique finie ; ce n’est ni une syntaxe exécutable du projet ni une nouvelle fonction du moteur. Les noms de champs et l’ordre des identités font partie du cas pédagogique. Lisez la formule avec les valeurs : un nombre apparemment juste obtenu selon une autre interprétation ne répond pas à la tâche. Conservez les intermédiaires et le contrôle pour permettre à un relecteur de retrouver le premier désaccord. Les hypothèses sont volontairement étroites ; élargir leur domaine exige une justification supplémentaire.

## Modèle fixé et contrôle par changement d’entrée

```json
{
  "values": {
    "positions": {
      "A": 0,
      "B": 2,
      "C": 5,
      "D": 8
    },
    "centres_required": 2
  },
  "formula": "for each k-subset S of candidate IDs: radius(S)=max_x min_s abs(position[x]-position[s]); retain all minimum-radius subsets in lexicographic order",
  "expected": {
    "best_radius": 3,
    "optimal_centres": [
      [
        "A",
        "C"
      ],
      [
        "A",
        "D"
      ],
      [
        "B",
        "C"
      ],
      [
        "B",
        "D"
      ]
    ]
  },
  "negative_control": {
    "values": {
      "positions": {
        "A": 0,
        "B": 2,
        "C": 5,
        "D": 8
      },
      "centres_required": 1
    },
    "expected": {
      "best_radius": 5,
      "optimal_centres": [
        [
          "C"
        ]
      ]
    }
  }
}
```

### Exercice 1

Identifiez les entrées et l’opération à préserver.

<details><summary>Réponse 1</summary>

> **Réponse:** Les positions sont des caractéristiques scalaires construites ; les centres doivent être des candidats existants.

</details>

### Exercice 2

Trouvez le rayon optimal et tous les sous-ensembles de centres ex æquo.

<details><summary>Réponse 2</summary>

> **Réponse:** Le rayon optimal vaut `3`, atteint par `[[A,C],[A,D],[B,C],[B,D]]` ; conservez tous les ex æquo.

</details>

### Exercice 3

Expliquez le piège d’interprétation qu’un résumé pourrait cacher.

<details><summary>Réponse 3</summary>

> **Réponse:** Des clés de diversité différentes ne suffisent pas à établir une bonne couverture en distance.

</details>

### Exercice 4

Appliquez le contrôle modifié et comparez les résultats.

<details><summary>Réponse 4</summary>

> **Réponse:** Avec un seul centre, `[C]` est optimal et le rayon vaut `5`.

</details>

### Exercice 5

Précisez la limite et les preuves requises avant toute adoption.

<details><summary>Réponse 5</summary>

> **Réponse:** Validez le sens de la caractéristique et le transfert réel avant de revendiquer une couverture pédagogique utile.

</details>

## Tâche avec sources et référence manuelle directe

Placez les caractéristiques d’exercice près des identités GA conservées, puis énumérez tous les sous-ensembles de centres.

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

- [Prérequis versionné: gaa-013-choose-a-voicing-diversity-key-for-the-task](../../guitar-alchemist-academy/en/gaa-013-choose-a-voicing-diversity-key-for-the-task.md)
- [Artefact local conservé](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/practice-items.json)
- [Lecture primaire](https://docs.python.org/3/library/itertools.html#itertools.combinations)
- [Dossier du cas construit](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-c.json)
- [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)
