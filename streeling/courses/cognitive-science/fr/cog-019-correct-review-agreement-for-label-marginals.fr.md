---
module_id: "cog-019-correct-review-agreement-for-label-marginals"
department: "cognitive-science"
course: "Corriger l’accord de revue selon les marges des étiquettes"
title: "Corriger l’accord de revue selon les marges des étiquettes"
level: "intermediate"
prerequisites: ["cog-011-measure-rubric-disagreement-before-adjudication"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Corriger l’accord de revue selon les marges des étiquettes

> Il s’agit d’un cas mathématique ou logique construit, appuyé par des passages de sources consultés. Revue technique humaine, relecture linguistique, tentatives apprenantes, exécution, adoption en production et publication restent indéterminées.

Un coordinateur Streeling voit un accord brut élevé et veut déclarer la grille fiable. Lorsque les évaluateurs choisissent surtout la même étiquette, un modèle fondé sur leurs marges prévoit déjà une partie des accords. Le cours sur le désaccord conserve les cases appariées, mais s’arrête explicitement avant la correction du hasard. Ici, nous ajoutons ce calcul sans transformer un tableau construit en revue humaine.

Calculez l’accord observé sur la diagonale. Calculez ensuite, pour chaque évaluateur, les proportions d’acceptation et de refus. Multipliez les proportions correspondantes entre évaluateurs et additionnez-les pour obtenir l’accord attendu sous le modèle d’étiquettes indépendantes. Normalisez l’excès par la marge restante au-dessus de cette référence. Le dénominateur compte autant que le numérateur ; on ne soustrait pas simplement une constante à une précision brute.

Dans le cas fixé, les marges diffèrent. Une proportion d’acceptation commune changerait donc le modèle de comparaison. Gardez chaque marge liée à son évaluateur et les artefacts contestés pour l’arbitrage. Le contrôle remplace toutes les notes par une acceptation. L’accord brut devient parfait, mais le dénominateur de correction s’annule. Indiquez un résultat indéfini au lieu d’inventer un score corrigé parfait.

La documentation scikit-learn définit cette version empirique de kappa. Le petit tableau exact ne demande aucun paquet et la définition ne fixe aucun seuil de publication. Un accord élevé peut cacher un corrigé commun erroné ou des notes copiées. La tâche consiste à donner accords brut et corrigé, hypothèses et limite dégénérée. Une expression de revue composable doit garder cette limite visible, sans convertir un résultat indéfini en approbation.

## Sources et périmètre du projet

L’utilitaire Learn sépare métadonnées, titre et corps, puis indexe les identités des modules anglais. Examinez cette représentation pour nommer l’artefact et sa révision. Elle n’implémente pas le modèle du cours et ne fournit aucune de ses entrées inventées.

[Prérequis: cog-011-measure-rubric-disagreement-before-adjudication](../../cognitive-science/en/cog-011-measure-rubric-disagreement-before-adjudication.md)

[Artefact conservé du projet](../../../../scripts/streeling-lib.mjs)

[Lecture primaire](https://scikit-learn.org/stable/modules/generated/sklearn.metrics.cohen_kappa_score.html)

## Modèle fixé et contrôle négatif

```json
{
  "values": {
    "both_pass": 6,
    "A_only": 2,
    "B_only": 0,
    "both_fail": 2
  },
  "formula": "N=sum(cells); po=(both_pass+both_fail)/N; pA=(both_pass+A_only)/N; pB=(both_pass+B_only)/N; pe=pA*pB+(1-pA)*(1-pB); kappa=(po-pe)/(1-pe), null if pe=1.",
  "expected": {
    "N": 10,
    "observed_agreement": 0.8,
    "expected_agreement": 0.56,
    "kappa_fraction": "6/11"
  },
  "negative_control": {
    "values": {
      "both_pass": 10,
      "A_only": 0,
      "B_only": 0,
      "both_fail": 0
    },
    "expected": {
      "N": 10,
      "observed_agreement": 1,
      "expected_agreement": 1,
      "kappa_fraction": null
    },
    "why": "Unanimous use of one category makes the correction denominator zero."
  },
  "input_types": {
    "both_pass": "nonnegative integer",
    "A_only": "nonnegative integer",
    "B_only": "nonnegative integer",
    "both_fail": "nonnegative integer"
  },
  "assumptions": [
    "Same artifacts and binary rubric for both fictional raters; positive total.",
    "Chance model uses product of empirical per-rater marginals, not an actual random rater experiment."
  ],
  "limits": "Kappa is not validity, independence, fairness or a universal acceptance threshold. No human review occurred."
}
```

### Exercice 1

Calculez l’accord observé.

<details><summary>Réponse 1</summary>

La diagonale contient `8` items sur `10`, soit `0.8`. Cela décrit des étiquettes concordantes, pas la justesse des réponses ni l’origine indépendante des notes.

</details>

### Exercice 2

Calculez l’accord attendu avec les marges séparées.

<details><summary>Réponse 2</summary>

Les proportions d’acceptation valent `0.8` et `0.6` ; l’accord attendu vaut `0.56`. Fusionner les marges définirait un autre modèle de référence.

</details>

### Exercice 3

Calculez le score corrigé.

<details><summary>Réponse 3</summary>

Kappa vaut `6/11`. Gardez le tableau brut à côté : un scalaire corrigé n’identifie pas les artefacts contestés nécessaires à l’arbitrage.

</details>

### Exercice 4

Appliquez le contrôle où tout passe.

<details><summary>Réponse 4</summary>

Accords observé et attendu valent tous deux `1` ; le score corrigé vaut `null`. Le dénominateur s’annule, il ne faut pas fabriquer un kappa parfait.

</details>

### Exercice 5

Le score autorise-t-il la publication ?

<details><summary>Réponse 5</summary>

Non. Justesse, identité de l’artefact, indépendance et autorité de publication demandent leurs propres preuves. Une statistique ne remplace aucune revue technique ou linguistique manquante.

</details>

## Travail avec consultation des sources

Préparez une note d’accord pour des notes appariées fictives de grille Streeling.

**Référence manuelle directe:** Remplissez le tableau, gardez les deux marges et calculez la correction en fraction exacte.

**Critère de réfutation:** La synthèse fusionne des marges distinctes ou invente un score défini avec un dénominateur nul.

Enregistrez une première réponse avant d’ouvrir les corrigés. Repérez les types des entrées, le périmètre de comparaison et la quantité à préserver. Dessinez le plus petit tableau ou schéma qui permette de vérifier chaque résultat intermédiaire. Gardez un résultat inattendu : modifier les prémisses pour obtenir la conclusion souhaitée ferait disparaître le contre-exemple.

Lisez le prérequis et le passage primaire dans les limites indiquées. Notez la révision de la source, la définition réellement utilisée et les hypothèses reprises. L’artefact du projet fournit une représentation réelle à examiner ; le modèle fixé apporte des entrées inventées. Un nom de document ou une URL accessible n’établit pas un résultat de production. Précisez les observations nécessaires avant d’utiliser le calcul dans une décision opérationnelle.

Énoncez la référence manuelle directe et son critère de réfutation avant de proposer un DSL composable ou une abstraction d’agent. Demandez à un assistant de contester votre réponse manuelle après l’avoir enregistrée. Conservez la consigne, la réponse, le passage cité et la correction retenue ou rejetée. Une expression plus courte n’est utile que si elle préserve l’opération, le contrôle et la limite de refus. Comparez-la d’abord à un simple tableau.

Remettez ensemble réponse initiale, étapes intermédiaires, réponse corrigée et contrôle. Signalez la consultation des sources et l’usage d’une calculatrice comme des aides. Une future comparaison en dogfood doit porter sur la même version de la tâche et garder les échecs comme les réussites ; changer la question pourrait autrement passer pour un progrès. Les critères préparés ci-dessous restent indéterminés jusqu’à une tentative réelle. Un corrigé et une vérification d’auteur n’établissent ni apprentissage ni adoption.

## Critères préparés pour l’apprenant

- Exercice 1: Calculez l’accord observé. — Décision indéterminée.
- Exercice 2: Calculez l’accord attendu avec les marges séparées. — Décision indéterminée.
- Exercice 3: Calculez le score corrigé. — Décision indéterminée.
- Exercice 4: Appliquez le contrôle où tout passe. — Décision indéterminée.
- Exercice 5: Le score autorise-t-il la publication ? — Décision indéterminée.

[Dossier fixé](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-b.json) · [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25-b/journal.md)
