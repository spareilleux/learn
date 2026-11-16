---
module_id: "sem-018-interpret-a-multi-shaft-weaving-draft"
department: "semiotics"
course: "Interpréter un bref de tissage à plusieurs cadres"
level: "advanced"
prerequisites: ["vc-007-weave-seams-as-scene-contracts"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Interpréter un bref de tissage à plusieurs cadres

> Brouillon pour révision technique et linguistique. Entrées numériques, étiquettes et résultats attendus sont des cas pédagogiques construits. Ils ne constituent ni nouveaux essais matériels physiques, ni exécutions natives de scène, ni observations d’apprentissage, ni résultats de production. Les décisions humaines et d’apprentissage restent indécises.

## Opération du projet et interprétation

La scène artisanale IX possède une règle de croisements alternés, mais un panneau plus général doit interpréter enfilage et séquence de levées de cadres. Une formule de parité alternée ne représente pas toutes les duites de cet exemple. Nous déclarons une convention pédagogique à foule montante : un cadre levé place ses fils de chaîne au-dessus de la trame pour cette duite. L’opération compose les deux relevés en une mise en carte, sans simuler un métier.

Lisez une ligne en suivant l’identité dans l’enfilage, puis vérifiez si le cadre appartient à l’ensemble levé. Plusieurs fils peuvent partager un cadre ; une levée modifie donc plusieurs croisements. Distinguez étiquette de cadre et indice de fil : affectation de commande d’un côté, adresse spatiale de l’autre. La ligne booléenne indique quel brin est dessus selon notre convention. Elle ne fixe ni épaisseur, ni efforts de contact, ni textile réalisable.

Le témoin à ligne absente dépasse une comparaison d’apparence. Remplacer une donnée manquante par un ensemble vide inventerait une instruction tout baissé et un panneau complet. Renvoyez plutôt une ligne incomplète en conservant les lignes connues. Un futur DSL artisanal composable devra préserver cette distinction ; ce cours demande seulement une table d’interprétation manuelle. Un agent ne doit pas promouvoir un bref incomplet en scène [Godot](https://docs.godotengine.org/en/4.5/) admise parce que les lignes connues semblent cohérentes.

Lisez le prérequis commité et le passage primaire délimité avant de calculer. Préparez un relevé séparant définition de source, prémisse construite, résultat dérivé et observation future. Une documentation ne soutient que l’affirmation située dans son périmètre lu. Paramètre de source, réponse mathématique et observation d’exécution ont des rôles de preuve différents ; un résumé assuré d’assistant ne peut les échanger. Le paquet conserve révision et périmètre de lecture pour permettre de contester une affirmation précise.

Travaillez d’abord réponses fermées. Dessinez la table ou le schéma requis et conservez les quantités intermédiaires, avec unités ou conventions d’identité. Cette dérivation manuscrite est la référence manuelle directe. Consultez seulement ensuite un assistant ou une aide à la traduction. Gardez la question, l’emplacement cité, la suggestion reçue et la modification acceptée ou rejetée. Comparez le résultat assisté à la première tentative conservée sur les mêmes entrées. Une réponse plus courte ne constitue pas un progrès si elle omet une condition ou invente un essai terminé.

## Modèle fixe et témoin à entrée modifiée

```json
{
  "values": {
    "threading": [
      0,
      1,
      2,
      0
    ],
    "lift_plan": [
      [
        0,
        2
      ],
      [
        1
      ],
      [
        0,
        1
      ]
    ]
  },
  "formula": "drawdown[pick][warp]=threading[warp] in lift_plan[pick]; a missing lift-plan row yields null and status incomplete rather than false cells",
  "expected": {
    "status": "complete",
    "drawdown": [
      [
        true,
        false,
        true,
        true
      ],
      [
        false,
        true,
        false,
        false
      ],
      [
        true,
        true,
        false,
        true
      ]
    ]
  },
  "negative_control": {
    "values": {
      "threading": [
        0,
        1,
        2,
        0
      ],
      "lift_plan": [
        [
          0,
          2
        ],
        [
          1
        ],
        null
      ]
    },
    "expected": {
      "status": "incomplete",
      "drawdown": [
        [
          true,
          false,
          true,
          true
        ],
        [
          false,
          true,
          false,
          false
        ],
        null
      ]
    }
  }
}
```

### Exercice 1

Interprétez la première duite.

<details><summary>Réponse 1</summary>

La ligne vaut `[true,false,true,true]` : l’affectation répétée lève les deux fils concernés. Indices spatiaux et cadres diffèrent.

</details>

### Exercice 2

Interprétez la deuxième duite.

<details><summary>Réponse 2</summary>

La ligne vaut `[false,true,false,false]`. Le cadre levé agit sur ses fils affectés, quelle que soit leur position dans le tableau.

</details>

### Exercice 3

Interprétez la dernière duite connue.

<details><summary>Réponse 3</summary>

La ligne vaut `[true,true,false,true]`. Un seul bit de parité alternée ne permet pas de reconstruire ce motif.

</details>

### Exercice 4

Appliquez le témoin à levée absente.

<details><summary>Réponse 4</summary>

La dernière ligne devient `null` et l’état `incomplete`. Les lignes connues restent disponibles ; l’absence n’est pas un ensemble vide.

</details>

### Exercice 5

Une mise en carte complète prouve-t-elle un tissage physique ?

<details><summary>Réponse 5</summary>

Non. Elle établit cette interprétation finie selon la convention déclarée. Mécanique des fils, fabrication et lecture humaine restent non testées.

</details>

## Travail avec sources et référence manuelle directe

Dessinez cadres et duites à la main, puis dérivez les croisements avant de les montrer à un assistant. Comparez le plan général à la scène alternée commitée et rédigez la frontière sémantique manquante d’une extension proposée.

Traitez le témoin comme un enregistrement distinct. Préservez le cas principal, écrivez une prédiction pour l’entrée modifiée et expliquez quelle prémisse change. En cas d’écart avec la première réponse, distinguez erreur de calcul, erreur d’interprétation et limite du modèle. Gardez tentative échouée et correction côte à côte. Le travail demande une note vérifiable avant de proposer un nœud DSL ou un flux d’agents ; une table manuelle peut déjà répondre au besoin.

Soumettez ensemble référence initiale, emplacements de sources, explication corrigée, résultat du témoin et critère de réfutation. Les critères préparés ci-dessous s’adressent à une révision future ; ils ne sont pas des apprentissages acceptés. Réponse réelle, historique d’aide, correction et décision restent vides jusqu’à conservation d’une tentative. Révision technique, révision linguistique, exécution, adoption en production et publication exigent chacune leurs preuves applicables. Un calcul fini réussi établirait seulement l’opération déclarée dans ses hypothèses.

## Critère de réfutation annoncé

Tout interpréteur produisant une dernière ligne tout baissé certaine pour le témoin absent a inventé une instruction.

## Critères d’apprentissage préparés

- Pour l’exercice 1: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 2: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 3: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 4: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 5: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.

## Sources et périmètre des affirmations

- [Prérequis commité: vc-007-weave-seams-as-scene-contracts](../../visual-computing/en/vc-007-weave-seams-as-scene-contracts.md)
- [Source de projet conservée](../../../../code/streeling/weave-godot/trial.gd)
- [Lecture primaire](https://docs.python.org/3/library/itertools.html#itertools.product)
- [Paquet construit](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-c.json)
- [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25-b/journal.md)
