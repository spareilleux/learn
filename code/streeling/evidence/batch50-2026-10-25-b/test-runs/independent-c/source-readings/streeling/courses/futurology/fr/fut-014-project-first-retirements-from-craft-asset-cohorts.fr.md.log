---
module_id: "fut-014-project-first-retirements-from-craft-asset-cohorts"
department: "futurology"
course: "Projeter les premiers retraits par cohortes d’assets artisanaux"
level: "advanced"
prerequisites: ["fut-010-project-weave-density-before-a-scene-expansion", "psy-021-conservation-claims"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Projeter les premiers retraits par cohortes d’assets artisanaux

> Brouillon pour révision technique et linguistique. Entrées numériques, étiquettes et résultats attendus sont des cas pédagogiques construits. Ils ne constituent ni nouveaux essais matériels physiques, ni exécutions natives de scène, ni observations d’apprentissage, ni résultats de production. Les décisions humaines et d’apprentissage restent indécises.

## Opération du projet et interprétation

Une future bibliothèque artisanale prévoit de remplacer d’anciens assets de broderie et sculpture lorsque leur représentation devient inadaptée. Le compte total ne donne aucune date à ce travail. Deux bibliothèques de même taille peuvent avoir des dates d’introduction et hypothèses de durée différentes. Ce cours projette les premiers retraits par cohortes. Les masses fractionnaires sont des allocations de planification construites, sans défaillances observées ni probabilités estimées depuis l’adoption.

Pour chaque cohorte introduite, décalez l’allocation d’âge sur le calendrier et multipliez-la par sa masse. Additionnez les contributions arrivant dans la même période. Cette convolution finie préserve la masse totale si l’horizon couvre tous les retraits, mais son résultat nouveau est le profil temporel et son pic. L’identité comptable des stocks ne fournit pas le calendrier d’âge. Un pic peut survenir alors que les introductions diminuent déjà, car plusieurs cohortes anciennes arrivent ensemble.

Le témoin à vie plus courte garde les introductions et change seulement l’âge de retrait. Il déplace et augmente le pic sans changer la masse totale. Attention aux assets remplaçants : le modèle s’arrête au premier retrait de leurs prédécesseurs. Réintroduire les remplaçants créerait un modèle de renouvellement avec hypothèses et horizon supplémentaires. Une note de planification agentique devra donc lier registre d’introduction, règle d’âge et horizon, puis comparer la projection aux décisions réelles si elles sont enregistrées plus tard.

Lisez le prérequis commité et le passage primaire délimité avant de calculer. Préparez un relevé séparant définition de source, prémisse construite, résultat dérivé et observation future. Une documentation ne soutient que l’affirmation située dans son périmètre lu. Paramètre de source, réponse mathématique et observation d’exécution ont des rôles de preuve différents ; un résumé assuré d’assistant ne peut les échanger. Le paquet conserve révision et périmètre de lecture pour permettre de contester une affirmation précise.

Travaillez d’abord réponses fermées. Dessinez la table ou le schéma requis et conservez les quantités intermédiaires, avec unités ou conventions d’identité. Cette dérivation manuscrite est la référence manuelle directe. Consultez seulement ensuite un assistant ou une aide à la traduction. Gardez la question, l’emplacement cité, la suggestion reçue et la modification acceptée ou rejetée. Comparez le résultat assisté à la première tentative conservée sur les mêmes entrées. Une réponse plus courte ne constitue pas un progrès si elle omet une condition ou invente un essai terminé.

## Modèle fixe et témoin à entrée modifiée

```json
{
  "values": {
    "introduced_by_period": [
      2,
      3,
      1,
      0
    ],
    "retirement_age_mass": {
      "2": 0.5,
      "3": 0.5
    },
    "output_periods": 7
  },
  "formula": "first_retirements[t]=sum(introduced[c]*age_mass[t-c] for c in cohort periods, absent ages contribute zero); total=sum(first_retirements)",
  "expected": {
    "first_retirements": [
      0,
      0,
      1,
      2.5,
      2,
      0.5,
      0
    ],
    "total": 6,
    "peak_period": 3,
    "peak_mass": 2.5
  },
  "negative_control": {
    "values": {
      "introduced_by_period": [
        2,
        3,
        1,
        0
      ],
      "retirement_age_mass": {
        "1": 1
      },
      "output_periods": 7
    },
    "expected": {
      "first_retirements": [
        0,
        2,
        3,
        1,
        0,
        0,
        0
      ],
      "total": 6,
      "peak_period": 2,
      "peak_mass": 3
    }
  }
}
```

### Exercice 1

Trouvez la première période de retrait non nulle.

<details><summary>Réponse 1</summary>

C’est la période `2`, de masse `1`. Aucune cohorte n’atteint auparavant l’âge déclaré.

</details>

### Exercice 2

Dérivez le pic par contributions de cohortes.

<details><summary>Réponse 2</summary>

La période `3` combine `1` de la première cohorte et `1.5` de la suivante, soit `2.5`.

</details>

### Exercice 3

Écrivez tout le profil des premiers retraits.

<details><summary>Réponse 3</summary>

Il vaut `[0,0,1,2.5,2,0.5,0]`, total `6`. L’horizon inclut le dernier retrait alloué.

</details>

### Exercice 4

Appliquez le témoin à vie plus courte.

<details><summary>Réponse 4</summary>

Le profil devient `[0,2,3,1,0,0,0]`, avec pic `3` en période `2`. Même total ne signifie pas même besoin de capacité.

</details>

### Exercice 5

Les retraits répétés des remplaçants sont-ils inclus ?

<details><summary>Réponse 5</summary>

Non. Seuls les premiers retraits des cohortes initiales figurent. Un renouvellement exige des règles d’introduction et de vie des remplaçants.

</details>

## Travail avec sources et référence manuelle directe

Dessinez une table cohorte-calendrier pour une bibliothèque de broderie proposée et sommez les diagonales à la main. Comparez ce calendrier direct à une prévision fondée seulement sur le total ; conservez les deux règles comme hypothèses.

Traitez le témoin comme un enregistrement distinct. Préservez le cas principal, écrivez une prédiction pour l’entrée modifiée et expliquez quelle prémisse change. En cas d’écart avec la première réponse, distinguez erreur de calcul, erreur d’interprétation et limite du modèle. Gardez tentative échouée et correction côte à côte. Le travail demande une note vérifiable avant de proposer un nœud DSL ou un flux d’agents ; une table manuelle peut déjà répondre au besoin.

Soumettez ensemble référence initiale, emplacements de sources, explication corrigée, résultat du témoin et critère de réfutation. Les critères préparés ci-dessous s’adressent à une révision future ; ils ne sont pas des apprentissages acceptés. Réponse réelle, historique d’aide, correction et décision restent vides jusqu’à conservation d’une tentative. Révision technique, révision linguistique, exécution, adoption en production et publication exigent chacune leurs preuves applicables. Un calcul fini réussi établirait seulement l’opération déclarée dans ses hypothèses.

## Critère de réfutation annoncé

Une prévision annonçant le même pic dès que les introductions totales coïncident est réfutée par le témoin de durée de vie.

## Critères d’apprentissage préparés

- Pour l’exercice 1: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 2: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 3: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 4: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 5: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.

## Sources et périmètre des affirmations

- [Prérequis commité: fut-010-project-weave-density-before-a-scene-expansion](../../futurology/en/fut-010-project-weave-density-before-a-scene-expansion.md)
- [Prérequis commité: psy-021-conservation-claims](../../psychohistory/en/psy-021-conservation-claims.md)
- [Source de projet conservée](../../../../code/blender/scripts/atlas/kit.py)
- [Lecture primaire](https://docs.python.org/3/library/itertools.html#itertools.product)
- [Paquet construit](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-c.json)
- [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25-b/journal.md)
