---
module_id: "inf-013-value-an-evidence-probe-by-expected-information"
department: "information-theory"
course: "Évaluer une sonde de preuve par son information attendue"
level: "intermediate"
prerequisites: ["inf-001-entropy-of-governance", "cog-008-choose-probes-that-distinguish-reasoning-models"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Évaluer une sonde de preuve par son information attendue

> Ce cours s’appuie sur un cas construit et des sources consultées. Les effectifs, durées, étiquettes et signaux sont des données pédagogiques inventées. La revue technique humaine, la relecture linguistique, les tentatives réelles, l’exécution, l’adoption en production et la publication restent à décider.

Plusieurs explications conviennent à un handoff d’agent défaillant. Un collègue propose une nouvelle sonde parce qu’elle produit un rapport détaillé. Ce détail n’est utile que si le résultat distingue les explications pertinentes. Le prérequis cherche des réponses séparatrices ; ce cours calcule l’incertitude attendue après une partition déclarée des hypothèses. Il explicite les probabilités au lieu de tenir le rapport le plus long pour le plus informatif.

Le prior attribue des probabilités égales aux alternatives construites. Une sonde déterministe groupe les hypothèses selon le résultat prédit. Dans chaque groupe, renormalisez les probabilités initiales avant de calculer l’entropie. Pondérez ensuite les entropies par la probabilité de chaque résultat. Cette espérance est définie avant d’observer la sonde. Elle ne décrit aucun rapport mesuré et ne justifie pas de modifier le prior après une discussion non consignée.

La définition originale de [Shannon](https://people.math.harvard.edu/~ctm/home/text/others/shannon/entropy/entropy.pdf) fournit la mesure logarithmique. La base choisie donne des bits et les alternatives équiprobables permettent une vérification par décompte. La partition équilibrée laisse autant d’alternatives après chaque résultat. Le contrôle constant les conserve toutes. Cela explique pourquoi répéter un résumé sans observation discriminante peut ajouter des mots sans ajouter d’information dans le modèle.

Le dossier conservé refuse explicitement de compter une relecture comme un nouvel essai et rappelle que les résultats historiques ne calibrent pas un prior construit. Une étape composable pourrait porter hypothèses, vraisemblances et identité du résultat ; son aide à la revue reste une hypothèse de dogfooding. La référence directe est une partition et une table d’entropie manuscrites. Le gain d’information ne choisit pas seul l’action produit : coût de sonde et conséquences des erreurs restantes exigent un autre modèle décisionnel.

## Sources et périmètre du projet

Lisez le prérequis avant d’utiliser le modèle. Examinez l’artefact conservé du projet à la révision indiquée dans le dossier et repérez le champ ou la branche qui étaye l’observation. La source fournit une représentation ou un comportement déclaré ; elle ne transforme pas le cas inventé en résultat observé du projet. La lecture primaire apporte le concept nommé dans les limites annoncées.

[Prérequis: inf-001-entropy-of-governance](../../information-theory/en/inf-001-entropy-of-governance.md)

[Prérequis: cog-008-choose-probes-that-distinguish-reasoning-models](../../cognitive-science/en/cog-008-choose-probes-that-distinguish-reasoning-models.md)

[Artefact conservé du projet](../../../../code/streeling/evidence/pilot-value-2026-10-22/source-observations.json)

[Lecture primaire: Shannon 1948 corrected reprint, section 6](https://people.math.harvard.edu/~ctm/home/text/others/shannon/entropy/entropy.pdf)

## Modèle fixé et contrôle

```json
{
  "values": {
    "hypotheses": [
      "a",
      "b",
      "c",
      "d"
    ],
    "probabilities": [
      0.25,
      0.25,
      0.25,
      0.25
    ],
    "probe_outcomes": [
      "left",
      "left",
      "right",
      "right"
    ]
  },
  "formula": "H=-sum(p*log2(p)); expected posterior entropy=sum(P(outcome)*H(hypothesis|outcome)); information gain=prior entropy-expected posterior entropy.",
  "expected": {
    "prior_bits": 2,
    "expected_posterior_bits": 1,
    "information_gain_bits": 1,
    "outcome_probabilities": {
      "left": 0.5,
      "right": 0.5
    }
  },
  "negative_control": {
    "values": {
      "hypotheses": [
        "a",
        "b",
        "c",
        "d"
      ],
      "probabilities": [
        0.25,
        0.25,
        0.25,
        0.25
      ],
      "probe_outcomes": [
        "same",
        "same",
        "same",
        "same"
      ]
    },
    "expected": {
      "prior_bits": 2,
      "expected_posterior_bits": 2,
      "information_gain_bits": 0,
      "outcome_probabilities": {
        "same": 1
      }
    },
    "why": "An outcome shared by all hypotheses cannot reduce uncertainty."
  },
  "assumptions": [
    "Prior probabilities are authored and sum to unity.",
    "Each hypothesis deterministically predicts one error-free probe outcome."
  ],
  "limits": "Bits quantify this model uncertainty, not task utility, truth, time savings or observed experimental evidence."
}
```

### Exercice 1

Calculez l’entropie initiale des alternatives construites.

<details><summary>Réponse 1</summary>

Elle vaut `2` bits. Chaque alternative a une probabilité `0.25`, et l’entropie vaut `log2(4)`. C’est l’incertitude du modèle stipulé, sans mesure de défaillances réelles.

</details>

### Exercice 2

Calculez les probabilités des résultats et l’entropie conditionnelle attendue.

<details><summary>Réponse 2</summary>

Les résultats `left` et `right` ont chacun une probabilité `0.5`. Chacun laisse deux alternatives équiprobables d’entropie `1` bit ; l’entropie attendue vaut donc `1` bit.

</details>

### Exercice 3

Quel est le gain principal et quand cette espérance est-elle définie ?

<details><summary>Réponse 3</summary>

Il vaut `2-1=1` bit et précède l’observation. Un résultat réel sélectionnerait un groupe conditionnel précis ; il faut conserver sa probabilité et son identité au lieu de les remplacer par l’espérance.

</details>

### Exercice 4

Appliquez le contrôle constant et expliquez le résultat.

<details><summary>Réponse 4</summary>

Le seul résultat a une probabilité `1`, l’entropie reste `2` bits et le gain vaut `0`. La sonde ne distingue aucune hypothèse malgré l’émission d’un message.

</details>

### Exercice 5

La sonde la plus informative donne-t-elle nécessairement la meilleure décision ?

<details><summary>Réponse 5</summary>

Non. Coût, conséquences, erreurs de modèle et bruit peuvent compter. Ces quantités manquent ici. Gardez la partition manuelle et rejetez toute affirmation selon laquelle le gain construit prouve la réussite d’une enquête réelle.

</details>

## Travail avec consultation des sources

Commencez par un tableau sur papier avant d’ouvrir les réponses. Recopiez les entrées et leurs unités, appliquez l’opération déclarée et conservez les résultats intermédiaires. Ce calcul direct constitue la référence manuelle pour comparer une réponse assistée ou une notation composable proposée. Une réponse plus courte ne présente aucun avantage démontré si elle perd l’identité d’une entrée, une catégorie d’échec ou le contre-exemple.

Examinez ensuite le passage précis consigné dans le dossier. Ne citez que le petit champ ou la branche nécessaire à votre explication, avec sa révision. Après avoir enregistré votre première réponse, demandez à un assistant de contester une hypothèse. Conservez la consigne, sa réponse, les corrections retenues et les suggestions rejetées. La consultation des sources et la calculatrice sont autorisées ; signalez cette aide pour ne pas présenter le résultat comme un rappel sans assistance.

Appliquez l’entrée modifiée du contrôle négatif et énoncez un résultat observable qui réfuterait votre conclusion avant de recommander un changement. Un contrôle inattendu impose de vérifier le calcul et les hypothèses avant de modifier le fonctionnement du projet. Remettez ensemble la réponse initiale, la réponse corrigée, l’historique des aides et l’incertitude restante. Le dossier prépare cinq critères, un par exercice, dont les décisions restent indéterminées. Les corrigés et vérifications de l’auteur ne remplissent pas ces décisions. Une future comparaison en dogfooding exige des tentatives réelles sur la même tâche et une référence manuelle conservée ; ce cours ne demande aucune nouvelle implémentation d’agent ou de DSL.

[Dossier fixé de l’unité](../../../../code/streeling/evidence/batch50-2026-10-24/unit-b.json) · [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
