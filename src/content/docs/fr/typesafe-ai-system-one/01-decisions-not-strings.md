---
title: "1. Des décisions, pas des chaînes"
description: Le modèle mental System One, les trois primitives typées, pourquoi la confiance n'est pas une autorité et où les sorties fermées de Jev sont utiles sans prouver la justesse sémantique.
sidebar:
  order: 1
---

[TypeSafe AI](https://docs.typesafe.ai/introduction) présente Jev comme un modèle de jugements rapides et ciblés dans du logiciel. Une requête contient un `state` et une ou plusieurs questions. Chaque question est évaluée indépendamment sur le même état, et la réponse revient sous l'identifiant choisi par l'appelant.

C'est volontairement moins général que du texte généré. Le gain n'est pas une justesse magique, mais une interface réduite que le code peut valider et composer.

## Trois primitives

| Primitive | Quand l'utiliser | Valeur renvoyée |
|---|---|---|
| [`Choice`](https://docs.typesafe.ai/primitives/choice) | un membre d'un ensemble fermé doit l'emporter | option choisie, probabilités de toutes les options, confiance |
| [`Score`](https://docs.typesafe.ai/primitives/score) | la réponse se place sur une échelle ordonnée | score pondéré, légende, probabilités, confiance |
| [`Noul`](https://docs.typesafe.ai/primitives/noul) | la réponse utile est un degré de oui ou non | un nombre de 0 à 1 |

`Noul` est le nom de la primitive binaire de TypeSafe. Contrairement à Choice et Score, elle n'a pas de champ `confidence` distinct.

Le laboratoire pose les trois questions en un appel :

```json
{
  "next_step": {
    "type": "choice",
    "instructions": "Quelle prochaine étape du cycle de vie les preuves fournies permettent-elles?",
    "criteria": {
      "design_review": "Réviser le design; l'autorité d'implémentation est absente ou les preuves sont incomplètes.",
      "bounded_implementation": "Implémenter un seul tracer borné uniquement lorsque le design et les preuves d'autorité sont explicites.",
      "reject": "La proposition contredit une contrainte absolue ou ne peut pas échouer de manière fermée."
    }
  },
  "delivery_risk": {
    "type": "score",
    "instructions": "À quel point l'effet proposé serait-il difficile à annuler?",
    "criteria": ["Faible et réversible", "Modéré ou compensable", "Élevé ou difficile à annuler"]
  },
  "authority_present": {
    "type": "noul",
    "instructions": "L'état contient-il une autorité d'implémentation explicite et bornée?"
  }
}
```

Il ne demande pas « Gaia doit-il implémenter ceci sans danger? », question trop large qui mélangerait plusieurs décisions.

## Questions atomiques, composition dans le code

La décision finale reste du code :

```python
if not authority_artifact_verified:
    return "human_review:no_explicit_authority"
if authority_present < 0.9:
    return "human_review:model_did_not_observe_authority"
if next_step_confidence < 0.75:
    return "human_review:uncertain_next_step"
if delivery_risk > 1.0:
    return "human_review:risk_above_bound"
```

`authority_artifact_verified` vient du code local de confiance, jamais de Jev. La réponse Noul peut rendre la route plus prudente, mais elle ne peut pas transformer l'absence d'un artefact d'autorité en permission.

Les seuils sont des hypothèses, pas des constantes universelles. La [documentation sur la confiance](https://docs.typesafe.ai/confidence) recommande de commencer prudemment et d'ajuster sur les données du domaine. Une action destructive exige une politique différente d'une recommandation en lecture seule.

## La sûreté des types n'est pas la vérité sémantique

L'API peut limiter `next_step.choice` aux options de la requête. Notre validateur peut donc refuser `"merge_now"`. Une réponse valide ne peut pas glisser une nouvelle commande en inventant une chaîne.

Mais deux affirmations restent distinctes :

1. **Forme :** la réponse appartient à l'espace déclaré.
2. **Sens :** la réponse choisie est juste pour cet état.

La première se vérifie mécaniquement à chaque appel. La seconde demande un corpus étiqueté, une analyse des erreurs, de la calibration et une politique adaptée aux conséquences. L'affirmation « can't hallucinate » de l'annonce concerne l'interface fermée; ce cours ne l'interprète pas comme l'impossibilité d'un mauvais jugement.

## Discipline de version et de probabilités

La page actuelle liste `jev-1.13.0` et les alias `jev-latest` et `jev-preview`. Un alias peut bouger. Si des seuils ont été évalués sur un modèle, épinglez sa version et journalisez le champ `model` concret de chaque réponse.

Utilisez la distribution complète lorsque l'alternative secondaire importe. `confidence` résume la forme de la distribution; elle ne dit ni quelle seconde option mérite une escalade, ni si une marge convient à votre domaine.

## À retenir

- Choice, Score et Noul sont des primitives de jugement fermées, pas de la génération libre.
- Posez des questions atomiques et composez les réponses dans le code.
- Une forme valide empêche les options inventées; elle ne prouve pas la justesse.
- La confiance guide une politique; elle n'est ni autorité ni acceptation.
- Épinglez le modèle quand les seuils comptent et mesurez chaque montée de version.

## Exercices

1. Il faut choisir quel dépôt possède un bogue : Gaia, GA, IX, TARS ou Demerzel. Quelle primitive convient, et quelle option faut-il ajouter si la liste peut être incomplète?

<details>
<summary>Solution</summary>

Choice, car la réponse est un élément d'un ensemble fermé sans ordre. Ajoutez `unknown` ou `none_of_the_above`; sinon le modèle doit affecter sa probabilité à une option même si aucune ne convient.

</details>

2. Une réponse choisit `bounded_implementation` avec une confiance de 0,98, mais l'état ne contient aucune autorisation. Peut-on dispatcher?

<details>
<summary>Solution</summary>

Non. La confiance décrit la distribution du modèle, pas l'autorité. Le code doit vérifier l'artefact d'autorité réel. Même la réponse Noul reste consultative et ne remplace aucune preuve cryptographique ou de dépôt.

</details>

## Sources

- TypeSafe AI : [introduction](https://docs.typesafe.ai/introduction), [primitives](https://docs.typesafe.ai/primitives), [confiance](https://docs.typesafe.ai/confidence), [modèles](https://docs.typesafe.ai/models)
- TypeSafe AI : [Introducing System One Models & Jev](https://typesafe.ai/blog/introducing-system-one-models-and-jev)
