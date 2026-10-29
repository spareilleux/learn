---
module_id: "phi-015-diagnose-a-failed-prediction-with-an-auxiliary-premise"
department: "philosophy"
course: "Diagnostiquer une prédiction échouée avec une prémisse auxiliaire"
level: "advanced"
prerequisites: ["phi-008-separate-a-test-oracle-from-a-specification"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Diagnostiquer une prédiction échouée avec une prémisse auxiliaire

> Brouillon pour révision technique et linguistique. Entrées numériques, étiquettes et résultats attendus sont des cas pédagogiques construits. Ils ne constituent ni nouveaux essais matériels physiques, ni exécutions natives de scène, ni observations d’apprentissage, ni résultats de production. Les décisions humaines et d’apprentissage restent indécises.

## Opération du projet et interprétation

Un test proposé d’origami vers la scène prévoit une arête visible si la géométrie est préservée et le dispositif de capture adéquat. La capture échoue hypothétiquement. Un agent accuse aussitôt la géométrie alors que caméra ou éclairage peuvent avoir manqué. Ce cours énumère les explications compatibles avant et après vérification indépendante de l’auxiliaire. Il ne rapporte aucune nouvelle capture et ne réduit pas tous les échecs scientifiques à une logique booléenne.

Définissez précisément le modèle fini. La réussite est ici exactement la conjonction de l’hypothèse géométrique et de l’auxiliaire de dispositif. C’est plus fort que dire que leur conjonction implique seulement la réussite ; l’équivalence est une prémisse pédagogique construite. L’échec exclut le monde où les deux sont vrais, laissant les mondes où l’un ou les deux sont faux. Il n’entraîne donc pas seul la fausseté de l’hypothèse principale. Distinguez compatibilité logique, plausibilité et probabilité : la table ne fournit aucun poids préalable.

Le témoin vérifie indépendamment l’auxiliaire en conservant l’échec. Seul subsiste alors le monde à hypothèse fausse et auxiliaire vrai. Réutiliser l’image ratée pour prétendre vérifier le dispositif n’apporterait pas la preuve indépendante posée par le témoin. Un transfert artisanal futur doit donc nommer contrôle auxiliaire, source et résultat contradictoire possible. L’assistant doit préserver les alternatives non résolues au lieu de transformer l’échec global en diagnostic injustifié du maillage.

Lisez le prérequis commité et le passage primaire délimité avant de calculer. Préparez un relevé séparant définition de source, prémisse construite, résultat dérivé et observation future. Une documentation ne soutient que l’affirmation située dans son périmètre lu. Paramètre de source, réponse mathématique et observation d’exécution ont des rôles de preuve différents ; un résumé assuré d’assistant ne peut les échanger. Le paquet conserve révision et périmètre de lecture pour permettre de contester une affirmation précise.

Travaillez d’abord réponses fermées. Dessinez la table ou le schéma requis et conservez les quantités intermédiaires, avec unités ou conventions d’identité. Cette dérivation manuscrite est la référence manuelle directe. Consultez seulement ensuite un assistant ou une aide à la traduction. Gardez la question, l’emplacement cité, la suggestion reçue et la modification acceptée ou rejetée. Comparez le résultat assisté à la première tentative conservée sur les mêmes entrées. Une réponse plus courte ne constitue pas un progrès si elle omet une condition ou invente un essai terminé.

## Modèle fixe et témoin à entrée modifiée

```json
{
  "values": {
    "observed_prediction": false,
    "auxiliary_verified": null
  },
  "formula": "enumerate Boolean worlds [H,A] lexicographically; retain worlds with (H and A)==observed_prediction and, when auxiliary_verified is not null, A==auxiliary_verified; H_false_entailed=all(not H for retained worlds) with nonempty retained set",
  "expected": {
    "worlds": [
      [
        false,
        false
      ],
      [
        false,
        true
      ],
      [
        true,
        false
      ]
    ],
    "count": 3,
    "H_false_entailed": false
  },
  "negative_control": {
    "values": {
      "observed_prediction": false,
      "auxiliary_verified": true
    },
    "expected": {
      "worlds": [
        [
          false,
          true
        ]
      ],
      "count": 1,
      "H_false_entailed": true
    }
  }
}
```

### Exercice 1

Quel monde l’échec élimine-t-il ?

<details><summary>Réponse 1</summary>

Il élimine `[true,true]`. Dans l’équivalence déclarée, ce monde produirait nécessairement une réussite.

</details>

### Exercice 2

Énumérez les mondes restants.

<details><summary>Réponse 2</summary>

Ils sont `[[false,false],[false,true],[true,false]]`, au total `3`. N’en choisissez pas silencieusement un sans preuve supplémentaire.

</details>

### Exercice 3

L’hypothèse principale est-elle déjà réfutée dans le modèle ?

<details><summary>Réponse 3</summary>

Non. Le monde `[true,false]` subsiste. L’auxiliaire peut être faux et l’hypothèse principale vraie.

</details>

### Exercice 4

Appliquez la vérification auxiliaire indépendante.

<details><summary>Réponse 4</summary>

Seul `[[false,true]]` reste, soit `1` monde ; l’hypothèse principale y est fausse. L’indépendance est posée, sans observation ici.

</details>

### Exercice 5

La compatibilité classe-t-elle les explications par probabilité ?

<details><summary>Réponse 5</summary>

Non. Le modèle n’a ni vraisemblances ni probabilités préalables. Compter des mondes logiques ne les rend pas équiprobables en réalité.

</details>

## Travail avec sources et référence manuelle directe

Rédigez une table papier de diagnostic pour une capture de pli proposée. Nommez contrôle géométrique manuel et contrôle indépendant du dispositif en les gardant non exécutés. Faites préciser quelle explication chacun exclurait.

Traitez le témoin comme un enregistrement distinct. Préservez le cas principal, écrivez une prédiction pour l’entrée modifiée et expliquez quelle prémisse change. En cas d’écart avec la première réponse, distinguez erreur de calcul, erreur d’interprétation et limite du modèle. Gardez tentative échouée et correction côte à côte. Le travail demande une note vérifiable avant de proposer un nœud DSL ou un flux d’agents ; une table manuelle peut déjà répondre au besoin.

Soumettez ensemble référence initiale, emplacements de sources, explication corrigée, résultat du témoin et critère de réfutation. Les critères préparés ci-dessous s’adressent à une révision future ; ils ne sont pas des apprentissages acceptés. Réponse réelle, historique d’aide, correction et décision restent vides jusqu’à conservation d’une tentative. Révision technique, révision linguistique, exécution, adoption en production et publication exigent chacune leurs preuves applicables. Un calcul fini réussi établirait seulement l’opération déclarée dans ses hypothèses.

## Critère de réfutation annoncé

Un diagnostic concluant à l’hypothèse fausse sur le seul échec est réfuté par le monde restant à hypothèse vraie et auxiliaire faux.

## Critères d’apprentissage préparés

- Pour l’exercice 1: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 2: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 3: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 4: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 5: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.

## Sources et périmètre des affirmations

- [Prérequis commité: phi-008-separate-a-test-oracle-from-a-specification](../../philosophy/en/phi-008-separate-a-test-oracle-from-a-specification.md)
- [Source de projet conservée](../../../../code/blender/scripts/atlas/kit.py)
- [Lecture primaire](https://plato.stanford.edu/entries/scientific-method/)
- [Paquet construit](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-c.json)
- [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25-b/journal.md)
