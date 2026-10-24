---
module_id: "cog-011-measure-rubric-disagreement-before-adjudication"
department: "cognitive-science"
course: "Mesurer le désaccord de notation avant arbitrage"
title: "Mesurer le désaccord de notation avant arbitrage"
level: "intermediate"
prerequisites: ["cog-008-choose-probes-that-distinguish-reasoning-models"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Mesurer le désaccord de notation avant arbitrage

> **Portée du brouillon.** Modèles fixes construits à partir de sources inspectées. Les décisions humaines techniques, linguistiques et d’apprentissage restent en attente. Aucun résultat de flotte active, contrôleur de production, télémétrie utilisateur ou progrès d’apprentissage n’est revendiqué. Le journal distingue tests réellement exécutés, lectures et contrôles prévus.

## Sources à examiner

- [cog-008-choose-probes-that-distinguish-reasoning-models.md](../../cognitive-science/en/cog-008-choose-probes-that-distinguish-reasoning-models.md)
- [cs-008-compose-exact-source-review-verdicts.md](../../computer-science/en/cs-008-compose-exact-source-review-verdicts.md)

Deux évaluateurs attribuent le même score total à une explication de pratique GA. Sont-ils d'accord sur chaque réponse ? Un total peut cacher des désaccords opposés. Le prérequis conserve les profils de réponse plutôt que les seuls totaux. Ici, les observations sont des notations appariées fictives ; l'opération consiste à préserver leur désaccord avant qu'un arbitre choisisse un résultat final.

Le cours sur la revue de sources exactes distingue déjà les affirmations des différents types de reçus. Respectez cette frontière : les évaluateurs doivent examiner le même artefact et la même version du barème. Des sources ou des règles différentes donnent une autre comparaison. Les étiquettes binaires sont stipulées pour l'arithmétique, sans approbation humaine authentifiée. Des totaux égaux ne prouvent ni indépendance ni justesse.

Construisez un tableau apparié : réussite commune, réussite du premier évaluateur seul, de l'autre seul, échec commun. Chaque item appartient à une seule case. La diagonale donne l'accord ; les autres cases indiquent les cas à discuter. Gardez l'identité des items pour que l'arbitre retrouve les explications litigieuses. Un pourcentage sans ces identités ne suffit pas à guider une correction.

Les deux vecteurs ont autant de réussites, mais divergent sur des items précis. Une décision majoritaire ou consensuelle vient ensuite et ne doit pas remplacer les vecteurs originaux. Après discussion, conservez les notes initiales, le motif et l'étiquette finale. Sinon, le dossier pourrait faire croire que les évaluations indépendantes étaient d'accord dès le départ. Un consensus peut aussi être faux ; ce modèle ne fournit aucun oracle externe.

Le contrôle négatif recopie un vecteur dans l'autre. Il donne arithmétiquement un accord parfait tout en détruisant l'indépendance recherchée. Pour le travail avec les sources, choisissez dans le prérequis une tâche d'explication sans réponses et rédigez un barème binaire avec des exemples d'échec. La référence directe est un tableau rempli à la main. Demandez à un assistant d'identifier les désaccords, en distinguant son aide de toute future notation humaine. Rejetez un rapport qui transforme l'égalité des totaux en accord ou qualifie d'indépendantes des étiquettes copiées.

## Cas fixe et calculs attendus

```json
{
  "values": {
    "rater_A": [
      1,
      1,
      0,
      0,
      1,
      0
    ],
    "rater_B": [
      1,
      0,
      0,
      1,
      1,
      0
    ]
  },
  "formula": "agreement=count(A_i=B_i)/paired_count; disagreement=1-agreement",
  "expected": {
    "both_pass": 2,
    "A_only": 1,
    "B_only": 1,
    "both_fail": 2,
    "paired": 6,
    "agreement_fraction": "4/6",
    "disagreement_fraction": "2/6",
    "disputed_items": [
      2,
      4
    ],
    "unanimous_pass_fraction": "2/6"
  },
  "negative_control": "Replacing B with A creates perfect agreement but supplies no independent rating.",
  "assumptions": [
    "Binary fixed rubric, same six artifacts, independent fictional ratings, no missing ratings."
  ],
  "limits": "Raw agreement is neither validity nor chance-corrected reliability; no human raters were observed."
}
```

## Conserver une tentative d’apprenant avec ses sources

Travaillez à partir des entrées épinglées ci-dessus. Avant de demander de l’aide, écrivez votre prédiction pour le cas fixe et son contrôle négatif, avec l’unité de chaque quantité et la frontière exacte de comparaison. Un petit tableau sur papier constitue la référence manuelle directe. Gardez les valeurs intermédiaires, surtout celles qui contredisent votre première prédiction. Cette tâche d’explication utilise des sources existantes et des données fixes ; elle ne demande ni installation, ni service payant, ni nouveau programme.

Utilisez ensuite un assistant pour retrouver le passage pertinent et critiquer votre calcul. Conservez la consigne initiale, la réponse, l’emplacement cité et les modifications acceptées ou rejetées. Une citation est utile seulement si le contenu inspecté étaye l’affirmation précise. Une étape déclarée, un type de données et un commentaire n’apportent pas les mêmes preuves qu’un résultat exécuté. Expliquez cette frontière dans votre réponse finale plutôt que d’emprunter l’autorité d’une étiquette rassurante.

Remettez ensemble référence manuelle, résultat corrigé, résultat du contrôle, critère de réfutation et historique d’aide. Les critères préparés demandent si la portée est identifiée, le calcul correct, le contre-exemple conservé, l’explication étayée et la conclusion limitée à ses preuves. Ils restent indécidés sans réponse réelle d’un apprenant. Les corrigés ci-dessous sont préparés : ils ne prouvent aucun apprentissage. L’évaluateur doit garder un critère échoué et sa cause avant la correction, puis juger séparément la tentative révisée. Les preuves d’exécution et de publication, recueillies ultérieurement, exigent leurs propres relevés liés à la version.

### Exercice 1

Remplissez les effectifs appariés.

<details>
<summary>Réponse 1</summary>

Réussite commune `2`, A seul `1`, B seul `1`, échec commun `2` ; total `6`.

</details>

### Exercice 2

Calculez accord et désaccord.

<details>
<summary>Réponse 2</summary>

Accord `4/6` ; désaccord `2/6`.

</details>

### Exercice 3

Identifiez les items litigieux.

<details>
<summary>Réponse 3</summary>

Items `[2,4]` ; proportion de réussites unanimes `2/6`.

</details>

### Exercice 4

Interprétez le contrôle par copie.

<details>
<summary>Réponse 4</summary>

Accord numérique parfait, sans seconde évaluation indépendante.

</details>

### Exercice 5

Que doit conserver l’arbitrage ?

<details>
<summary>Réponse 5</summary>

Notes initiales, versions de l’artefact et du barème, preuves litigieuses, motif et décision finale.

</details>

[Dossier de preuves fixes](../../../../code/streeling/evidence/batch50-2026-10-23/unit-b.json) · [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)
