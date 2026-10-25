---
title: Examiner un item à partir du score des autres items
description: Examiner un item à partir du score des autres items — Sciences cognitives
sidebar:
  label: COG-020 · Examiner un item à partir du score des autres items
  order: 20
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/cognitive-science/fr/cog-020-screen-an-item-using-the-rest-score.fr.md
---

:::note[Streeling University]
**COG-020** · Examiner un item à partir du score des autres items · intermédiaire · 45 minutes

Généré par le département *Sciences cognitives* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/cognitive-science/fr/cog-020-screen-an-item-using-the-rest-score.fr.md) · [Mon journal](../../journal/)

Prérequis: [COG-008](../../cognitive-science/cog-008-choose-probes-that-distinguish-reasoning-models/)
:::

> Il s’agit d’un cas mathématique ou logique construit, appuyé par des passages de sources consultés. Revue technique humaine, relecture linguistique, tentatives apprenantes, exécution, adoption en production et publication restent indéterminées.

Un item Learn est réussi par environ la moitié d’un groupe construit. Cela ne prouve pas qu’il distingue la compétence visée. Un corrigé mal étiqueté ou une consigne ambiguë pourrait favoriser le groupe moins bien classé. Avant de réutiliser l’item dans une tâche d’explication assistée, comparez son résultat à la performance sur les autres items et examinez la consigne réelle.

Classez les réponses avec le score des autres items, en excluant l’item cible. L’inclure dans son propre classement crée une association partie-tout qui brouille la question. Notre petit diagnostic partage les scores distincts en deux moitiés égales. Il soustrait ensuite la proportion de réussite du groupe inférieur de celle du groupe supérieur. La facilité globale résume séparément toutes les réponses.

Le cas fixé donne un contraste négatif malgré une facilité moyenne. Le contrôle inverse les réponses à l’item et garde la proportion globale. Le contraste change de signe. Cette paire montre pourquoi le total des bonnes réponses ne remplace pas l’association avec le score restant. Gardez chaque ligne pour examiner si corrigé, adéquation du contenu ou formulation expliquent le motif.

Le texte primaire traite du score hors item, de la dépendance à l’échantillon et de l’hypothèse de dimensionnalité des indices classiques. Notre calcul par moitiés est un diagnostic fini déclaré, pas sa méthode psychométrique complète. Un résultat faible ou négatif invite à enquêter ; il n’autorise pas automatiquement à supprimer un item nécessaire sur le fond. Il manque encore apprenants réels, consentement approprié, réponses représentatives et revue de contenu. Un DSL adaptatif devrait garder cette incertitude plutôt que produire une étiquette universelle de qualité.

## Sources et périmètre du projet

L’utilitaire Learn sépare métadonnées, titre et corps, puis indexe les identités des modules anglais. Examinez cette représentation pour nommer l’artefact et sa révision. Elle n’implémente pas le modèle du cours et ne fournit aucune de ses entrées inventées.

[Prérequis: cog-008-choose-probes-that-distinguish-reasoning-models](../../cognitive-science/cog-008-choose-probes-that-distinguish-reasoning-models/)

[Artefact conservé du projet](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Lecture primaire](https://www.cs.cas.cz/comps/PsychometricsBook/chapters/chapter5/chap5_item_analysis.html)

## Modèle fixé et contrôle négatif

```json
{
  "values": {
    "rest_scores": [
      0,
      1,
      2,
      3,
      4,
      5,
      6,
      7
    ],
    "item_correct": [
      1,
      1,
      1,
      0,
      1,
      0,
      0,
      0
    ]
  },
  "formula": "Sort records by distinct rest_score ascending; lower group is first half, upper group is last half. p=all correct/N; D=upper correct/upper size-lower correct/lower size. Rank excludes target item.",
  "expected": {
    "lower_correct": 3,
    "upper_correct": 1,
    "group_size": 4,
    "overall_fraction": 0.5,
    "discrimination": -0.5
  },
  "negative_control": {
    "values": {
      "rest_scores": [
        0,
        1,
        2,
        3,
        4,
        5,
        6,
        7
      ],
      "item_correct": [
        0,
        0,
        0,
        1,
        0,
        1,
        1,
        1
      ]
    },
    "expected": {
      "lower_correct": 1,
      "upper_correct": 3,
      "group_size": 4,
      "overall_fraction": 0.5,
      "discrimination": 0.5
    },
    "why": "Reversing the item responses keeps ease unchanged but reverses the association with rest score."
  },
  "input_types": {
    "rest_scores": "even-length list of distinct integer scores excluding the item",
    "item_correct": "same-length binary integer list"
  },
  "assumptions": [
    "Fixed item and rest-score rubric; complete fictional records.",
    "Equal halves are an authored diagnostic convention, not a mandated psychometric standard."
  ],
  "limits": "A small descriptive contrast is neither causal learning evidence nor proof of item validity, dimensionality or population discrimination."
}
```

### Exercice 1

Calculez la facilité globale.

<details><summary>Réponse 1</summary>

Il y a `4` bonnes réponses sur `8`, soit `0.5`. Cette quantité ignore quel groupe de score restant a réussi.

</details>

### Exercice 2

Calculez le contraste signé.

<details><summary>Réponse 2</summary>

Le groupe inférieur donne `3` réponses correctes et le supérieur `1`, chacun sur `4`. Le contraste vaut `-0.5`, un signal à examiner selon ce diagnostic déclaré.

</details>

### Exercice 3

Appliquez le contrôle inversant les réponses.

<details><summary>Réponse 3</summary>

Sa proportion globale reste `0.5`, mais le contraste devient `0.5`. Des totaux égaux ne donnent donc pas des profils de discrimination égaux.

</details>

### Exercice 4

Pourquoi exclure la cible du classement ?

<details><summary>Réponse 4</summary>

Pour éviter que sa réponse définisse en partie ses propres groupes de comparaison. Cela ne prouve ni l’unidimensionnalité valide du reste ni l’absence d’incertitude d’échantillonnage.

</details>

### Exercice 5

L’agent doit-il supprimer automatiquement l’item ?

<details><summary>Réponse 5</summary>

Non. Gardez consigne, corrigé et identités des lignes ; examinez adéquation, ambiguïté et composition du groupe. Un contraste négatif descriptif n’en identifie pas la cause.

</details>

## Travail avec consultation des sources

Préparez une note d’examen d’item pour un questionnaire d’explication Learn proposé.

**Référence manuelle directe:** Classez selon les scores restants et remplissez à la main les proportions de réussite des groupes.

**Critère de réfutation:** Une synthèse de qualité traite comme équivalents ces cas de même facilité et de contrastes opposés.

Enregistrez une première réponse avant d’ouvrir les corrigés. Repérez les types des entrées, le périmètre de comparaison et la quantité à préserver. Dessinez le plus petit tableau ou schéma qui permette de vérifier chaque résultat intermédiaire. Gardez un résultat inattendu : modifier les prémisses pour obtenir la conclusion souhaitée ferait disparaître le contre-exemple.

Lisez le prérequis et le passage primaire dans les limites indiquées. Notez la révision de la source, la définition réellement utilisée et les hypothèses reprises. L’artefact du projet fournit une représentation réelle à examiner ; le modèle fixé apporte des entrées inventées. Un nom de document ou une URL accessible n’établit pas un résultat de production. Précisez les observations nécessaires avant d’utiliser le calcul dans une décision opérationnelle.

Énoncez la référence manuelle directe et son critère de réfutation avant de proposer un DSL composable ou une abstraction d’agent. Demandez à un assistant de contester votre réponse manuelle après l’avoir enregistrée. Conservez la consigne, la réponse, le passage cité et la correction retenue ou rejetée. Une expression plus courte n’est utile que si elle préserve l’opération, le contrôle et la limite de refus. Comparez-la d’abord à un simple tableau.

Remettez ensemble réponse initiale, étapes intermédiaires, réponse corrigée et contrôle. Signalez la consultation des sources et l’usage d’une calculatrice comme des aides. Une future comparaison en dogfood doit porter sur la même version de la tâche et garder les échecs comme les réussites ; changer la question pourrait autrement passer pour un progrès. Les critères préparés ci-dessous restent indéterminés jusqu’à une tentative réelle. Un corrigé et une vérification d’auteur n’établissent ni apprentissage ni adoption.

## Critères préparés pour l’apprenant

- Exercice 1: Calculez la facilité globale. — Décision indéterminée.
- Exercice 2: Calculez le contraste signé. — Décision indéterminée.
- Exercice 3: Appliquez le contrôle inversant les réponses. — Décision indéterminée.
- Exercice 4: Pourquoi exclure la cible du classement ? — Décision indéterminée.
- Exercice 5: L’agent doit-il supprimer automatiquement l’item ? — Décision indéterminée.

[Dossier fixé](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/unit-b.json) · [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/journal.md)
