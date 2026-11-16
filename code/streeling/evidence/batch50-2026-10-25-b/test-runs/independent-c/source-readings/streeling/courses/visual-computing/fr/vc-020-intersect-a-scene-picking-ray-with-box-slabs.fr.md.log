---
module_id: "vc-020-intersect-a-scene-picking-ray-with-box-slabs"
department: "visual-computing"
course: "Intersecter un rayon de sélection avec les tranches d’une boîte"
level: "advanced"
prerequisites: ["vc-008-save-and-query-a-weave-scene"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Intersecter un rayon de sélection avec les tranches d’une boîte

> Brouillon pour révision technique et linguistique. Entrées numériques, étiquettes et résultats attendus sont des cas pédagogiques construits. Ils ne constituent ni nouveaux essais matériels physiques, ni exécutions natives de scène, ni observations d’apprentissage, ni résultats de production. Les décisions humaines et d’apprentissage restent indécises.

## Opération du projet et interprétation

La scène tissée distingue déjà l’identité du croisement touché de l’étiquette du brin. Avant d’examiner une broderie ou sculpture détaillée, un futur sélecteur peut éliminer les candidats dont le rayon n’atteint pas la boîte englobante. Cette intersection constitue un filtrage large : elle peut exclure un candidat, sans certifier un impact sur sa surface. Ce cours calcule à la main l’intervalle admissible du paramètre en conservant cette asymétrie de preuve.

Considérez la boîte comme l’intersection de tranches selon les coordonnées. Chaque coordonnée non parallèle fournit un intervalle de paramètres où le rayon se trouve entre minimum et maximum. Intersectez ces intervalles avec le segment avant. Une coordonnée parallèle exige une autre branche : son origine est déjà dans toute la tranche, ou elle n’y entre jamais. Remplacer une division par zéro par un nombre immense masquerait la distinction. Le témoin place l’origine hors d’une tranche parallèle sans changer la coordonnée parcourue.

Le paramètre ne représente une distance que si la normalisation et les unités du vecteur le permettent. Un futur transfert de scène doit conserver les repères, la limite avant et le prédicat détaillé exécuté après l’impact sur boîte. Les boîtes de groupes BRUTAL peuvent désigner une sculpture à examiner ; elles n’identifient pas la marque ciselée sélectionnée. Distinguez boîte manquée, maillage non testé et impact détaillé confirmé.

Lisez le prérequis commité et le passage primaire délimité avant de calculer. Préparez un relevé séparant définition de source, prémisse construite, résultat dérivé et observation future. Une documentation ne soutient que l’affirmation située dans son périmètre lu. Paramètre de source, réponse mathématique et observation d’exécution ont des rôles de preuve différents ; un résumé assuré d’assistant ne peut les échanger. Le paquet conserve révision et périmètre de lecture pour permettre de contester une affirmation précise.

Travaillez d’abord réponses fermées. Dessinez la table ou le schéma requis et conservez les quantités intermédiaires, avec unités ou conventions d’identité. Cette dérivation manuscrite est la référence manuelle directe. Consultez seulement ensuite un assistant ou une aide à la traduction. Gardez la question, l’emplacement cité, la suggestion reçue et la modification acceptée ou rejetée. Comparez le résultat assisté à la première tentative conservée sur les mêmes entrées. Une réponse plus courte ne constitue pas un progrès si elle omet une condition ou invente un essai terminé.

## Modèle fixe et témoin à entrée modifiée

```json
{
  "values": {
    "minimum": [
      0,
      0,
      0
    ],
    "maximum": [
      2,
      2,
      2
    ],
    "origin": [
      -2,
      1,
      1
    ],
    "direction": [
      1,
      0,
      0
    ],
    "t_max": 10
  },
  "formula": "start=[0,t_max]; for each nonzero direction intersect with sorted((minimum-origin)/direction,(maximum-origin)/direction); zero direction outside slab rejects; hit iff resulting interval nonempty",
  "expected": {
    "hit": true,
    "t_enter": 2,
    "t_exit": 4
  },
  "negative_control": {
    "values": {
      "minimum": [
        0,
        0,
        0
      ],
      "maximum": [
        2,
        2,
        2
      ],
      "origin": [
        -2,
        3,
        1
      ],
      "direction": [
        1,
        0,
        0
      ],
      "t_max": 10
    },
    "expected": {
      "hit": false,
      "t_enter": null,
      "t_exit": null
    }
  }
}
```

### Exercice 1

Trouvez l’intervalle sur l’axe parcouru.

<details><summary>Réponse 1</summary>

Il vaut `[2,4]`. Triez les paramètres des limites avant intersection pour traiter aussi un sens négatif.

</details>

### Exercice 2

Traitez les coordonnées parallèles.

<details><summary>Réponse 2</summary>

Les origines sont dans leurs tranches fermées, sans restriction supplémentaire. Aucune division par une direction nulle n’est nécessaire.

</details>

### Exercice 3

Appliquez la limite avant.

<details><summary>Réponse 3</summary>

L’intervalle reste `[2,4]` dans `[0,10]` ; le modèle annonce un impact sur boîte. La sortie appartient à la boîte fermée.

</details>

### Exercice 4

Évaluez le témoin à origine déplacée.

<details><summary>Réponse 4</summary>

Il manque la boîte : l’origine parallèle est hors tranche. Entrée et sortie valent `null` ; l’autre intervalle ne suffit pas.

</details>

### Exercice 5

L’impact sur boîte établit-il une sélection de croisement ?

<details><summary>Réponse 5</summary>

Non. La requête de surface et la correspondance d’identité restent distinctes ; la boîte contient aussi du vide.

</details>

## Travail avec sources et référence manuelle directe

Dessinez rayon et tranches pour un sélecteur de sculpture proposé avant de demander un résumé de l’essai. Produisez une table manuelle d’intervalles et précisez la requête d’identité détaillée après admission.

Traitez le témoin comme un enregistrement distinct. Préservez le cas principal, écrivez une prédiction pour l’entrée modifiée et expliquez quelle prémisse change. En cas d’écart avec la première réponse, distinguez erreur de calcul, erreur d’interprétation et limite du modèle. Gardez tentative échouée et correction côte à côte. Le travail demande une note vérifiable avant de proposer un nœud DSL ou un flux d’agents ; une table manuelle peut déjà répondre au besoin.

Soumettez ensemble référence initiale, emplacements de sources, explication corrigée, résultat du témoin et critère de réfutation. Les critères préparés ci-dessous s’adressent à une révision future ; ils ne sont pas des apprentissages acceptés. Réponse réelle, historique d’aide, correction et décision restent vides jusqu’à conservation d’une tentative. Révision technique, révision linguistique, exécution, adoption en production et publication exigent chacune leurs preuves applicables. Un calcul fini réussi établirait seulement l’opération déclarée dans ses hypothèses.

## Critère de réfutation annoncé

Toute explication admettant le témoin sur le seul recouvrement de l’axe parcouru est réfutée par la tranche parallèle.

## Critères d’apprentissage préparés

- Pour l’exercice 1: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 2: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 3: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 4: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 5: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.

## Sources et périmètre des affirmations

- [Prérequis commité: vc-008-save-and-query-a-weave-scene](../../visual-computing/en/vc-008-save-and-query-a-weave-scene.md)
- [Source de projet conservée](../../../../code/streeling/weave-godot/trial.gd)
- [Lecture primaire](https://pbr-book.org/4ed/Shapes/Basic_Shape_Interface)
- [Paquet construit](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-c.json)
- [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25-b/journal.md)
