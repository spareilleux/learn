---
module_id: "gaa-021-align-a-practice-attempt-with-unit-edit-costs"
department: "guitar-alchemist-academy"
course: "Aligner une tentative musicale avec des coûts d’édition unitaires"
level: "advanced"
prerequisites: ["gaa-019-retrieve-overlapping-interval-motifs"]
estimated_duration: "50 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Aligner une tentative musicale avec des coûts d’édition unitaires

> Brouillon soumis à une revue technique et linguistique. Les entrées numériques et les résultats attendus sont des cas construits. Aucun nouvel essai de matériau, passage dans un moteur de scène, résultat apprenant ou résultat de production n’est fourni. Les décisions humaines et pédagogiques restent ouvertes.

## Opération du projet et interprétation

Un guitariste insère une note avant une phrase autrement correcte. Une comparaison position par position transforme cette insertion en plusieurs erreurs apparentes. Déclarez des coûts unitaires d’insertion, de suppression et de substitution, puis remplissez la table de Levenshtein finie. Elle fournit un score minimal d’alignement sans le confondre avec une recherche exacte de motif contigu. Le score n’inclut ni rythme, ni doigté, ni expression. Plusieurs alignements peuvent avoir le même coût ; sans règle de départage, conservez la distance sans inventer un diagnostic unique.

Lisez le prérequis versionné et le passage précisément délimité de la source avant de calculer. Identifiez l’opération dont le projet a besoin, le sens de ses entrées et l’affirmation que le résultat pourrait étayer. Le dossier conserve la révision et le périmètre réellement consulté. Placez dans des colonnes distinctes une définition documentaire, une hypothèse construite et un résultat observé. Un assistant ne doit pas remplacer une observation absente par un récit plausible de ce que le logiciel ferait probablement.

Explicitez la représentation. Le JSON ci-dessous décrit une spécification mathématique finie ; ce n’est ni une syntaxe exécutable du projet ni une nouvelle fonction du moteur. Les noms de champs et l’ordre des identités font partie du cas pédagogique. Lisez la formule avec les valeurs : un nombre apparemment juste obtenu selon une autre interprétation ne répond pas à la tâche. Conservez les intermédiaires et le contrôle pour permettre à un relecteur de retrouver le premier désaccord. Les hypothèses sont volontairement étroites ; élargir leur domaine exige une justification supplémentaire.

## Modèle fixé et contrôle par changement d’entrée

```json
{
  "values": {
    "target": [
      60,
      62,
      64
    ],
    "attempt": [
      60,
      61,
      62,
      64
    ]
  },
  "formula": "D[i,0]=i; D[0,j]=j; D[i,j]=min(D[i-1,j]+1,D[i,j-1]+1,D[i-1,j-1]+(target[i-1]!=attempt[j-1])); distance=D[len(target),len(attempt)]",
  "expected": {
    "table": [
      [
        0,
        1,
        2,
        3,
        4
      ],
      [
        1,
        0,
        1,
        2,
        3
      ],
      [
        2,
        1,
        1,
        1,
        2
      ],
      [
        3,
        2,
        2,
        2,
        1
      ]
    ],
    "distance": 1
  },
  "negative_control": {
    "values": {
      "target": [
        60,
        62,
        64
      ],
      "attempt": [
        64,
        62,
        60
      ]
    },
    "expected": {
      "table": [
        [
          0,
          1,
          2,
          3
        ],
        [
          1,
          1,
          2,
          2
        ],
        [
          2,
          2,
          1,
          2
        ],
        [
          3,
          2,
          2,
          2
        ]
      ],
      "distance": 2
    }
  }
}
```

### Exercice 1

Identifiez les entrées et l’opération à préserver.

<details><summary>Réponse 1</summary>

> **Réponse:** Les lignes indexent les préfixes cibles et les colonnes ceux de la tentative ; les préfixes vides fixent le bord.

</details>

### Exercice 2

Trouvez la distance principale et une modification de séquence attestant ce coût.

<details><summary>Réponse 2</summary>

> **Réponse:** La distance en bas à droite vaut `1` ; supprimer la note insérée `61` en fournit un témoin.

</details>

### Exercice 3

Expliquez le piège d’interprétation qu’un résumé pourrait cacher.

<details><summary>Réponse 3</summary>

> **Réponse:** Le score dépend des symboles ordonnés, pas seulement de l’appartenance à un ensemble de classes de hauteur.

</details>

### Exercice 4

Appliquez le contrôle modifié et comparez les résultats.

<details><summary>Réponse 4</summary>

> **Réponse:** Le contrôle inversé a une distance de `2` ; un ensemble de notes identique n’implique pas une phrase identique.

</details>

### Exercice 5

Précisez la limite et les preuves requises avant toute adoption.

<details><summary>Réponse 5</summary>

> **Réponse:** La table ne peut attribuer une erreur à la motricité, à l’écoute ou à l’attention sans observations.

</details>

## Tâche avec sources et référence manuelle directe

Remplissez à la main la table des préfixes avant de proposer un retour sur une note insérée.

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

- [Prérequis versionné: gaa-019-retrieve-overlapping-interval-motifs](../../guitar-alchemist-academy/en/gaa-019-retrieve-overlapping-interval-motifs.md)
- [Artefact local conservé](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/practice-items.json)
- [Lecture primaire](https://docs.python.org/3/library/math.html)
- [Dossier du cas construit](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-c.json)
- [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)
