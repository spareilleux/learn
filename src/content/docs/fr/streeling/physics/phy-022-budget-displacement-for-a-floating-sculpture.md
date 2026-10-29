---
title: Dimensionner le volume déplacé par une sculpture flottante
description: Dimensionner le volume déplacé par une sculpture flottante — Physique
sidebar:
  label: PHY-022 · Dimensionner le volume déplacé par une sculpture flottante
  order: 22
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/physics/fr/phy-022-budget-displacement-for-a-floating-sculpture.fr.md
---

:::note[Streeling University]
**PHY-022** · Dimensionner le volume déplacé par une sculpture flottante · avancé · 45 minutes

Généré par le département *Physique* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/physics/fr/phy-022-budget-displacement-for-a-floating-sculpture.fr.md) · [Mon journal](../../journal/)

Prérequis: [PHY-014](../../physics/phy-014-preserve-mass-assumptions-when-scaling-a-craft-mesh/)
:::

> Brouillon pour révision technique et linguistique. Entrées numériques, étiquettes et résultats attendus sont des cas pédagogiques construits. Ils ne constituent ni nouveaux essais matériels physiques, ni exécutions natives de scène, ni observations d’apprentissage, ni résultats de production. Les décisions humaines et d’apprentissage restent indécises.

## Opération du projet et interprétation

Une sculpture métallique creuse est proposée pour un bassin de l’Observatory. Sa coque visible et son volume déplacé répondent à des questions différentes : la coque apporte la masse, tandis que l’enveloppe étanche exclut le fluide. Le prérequis sur le changement d’échelle des masses ne décide pas de l’existence d’un équilibre flottant. L’opération détermine ici le déplacement nécessaire pour équilibrer le poids, puis vérifie la capacité de l’enveloppe. Dimensions et masses sont des données inventées pour une fiche d’asset, sans mesure d’un objet fabriqué.

Dessinez toute l’enveloppe étanche avant de multiplier densité et volume. Le déplacement requis résulte de l’égalité entre le poids de l’objet et celui du fluide exclu. Une fraction requise inférieure à l’unité est compatible avec une immersion partielle ; ce n’est pas la fraction réellement immergée pendant une accélération. La force nette en immersion totale constitue un diagnostic distinct. Une valeur positive indique une force résultante ascendante dans ces hypothèses. Elle ne décrit pas la résultante à l’équilibre flottant.

Dans un transfert de l’artisanat vers la scène, conservez séparément masse de coque et volume d’enveloppe. Un maillage de surface ne suffit pas forcément à établir un intérieur étanche. Une barque en origami ou un corps sculpté creux peut changer fortement de déplacement sans changement proportionnel de masse matérielle. L’assistant doit identifier la région exclue, au lieu de déduire la flottabilité du nom d’un matériau ou d’un rendu aquatique convaincant.

Lisez le prérequis commité et le passage primaire délimité avant de calculer. Préparez un relevé séparant définition de source, prémisse construite, résultat dérivé et observation future. Une documentation ne soutient que l’affirmation située dans son périmètre lu. Paramètre de source, réponse mathématique et observation d’exécution ont des rôles de preuve différents ; un résumé assuré d’assistant ne peut les échanger. Le paquet conserve révision et périmètre de lecture pour permettre de contester une affirmation précise.

Travaillez d’abord réponses fermées. Dessinez la table ou le schéma requis et conservez les quantités intermédiaires, avec unités ou conventions d’identité. Cette dérivation manuscrite est la référence manuelle directe. Consultez seulement ensuite un assistant ou une aide à la traduction. Gardez la question, l’emplacement cité, la suggestion reçue et la modification acceptée ou rejetée. Comparez le résultat assisté à la première tentative conservée sur les mêmes entrées. Une réponse plus courte ne constitue pas un progrès si elle omet une condition ou invente un essai terminé.

## Modèle fixe et témoin à entrée modifiée

```json
{
  "values": {
    "mass_kg": 0.6,
    "fluid_density_kg_m3": 1000,
    "sealed_volume_m3": 0.001,
    "g_m_s2": 10
  },
  "formula": "weight=m*g; maximum_buoyancy=rho*g*V; required_displacement=m/rho; required_fraction=required_displacement/V; feasible=required_fraction<=1; full_submersion_net=maximum_buoyancy-weight",
  "expected": {
    "weight_N": 6,
    "maximum_buoyancy_N": 10,
    "required_displacement_m3": 0.0006,
    "required_fraction": 0.6,
    "feasible": true,
    "full_submersion_net_N": 4
  },
  "negative_control": {
    "values": {
      "mass_kg": 1.2,
      "fluid_density_kg_m3": 1000,
      "sealed_volume_m3": 0.001,
      "g_m_s2": 10
    },
    "expected": {
      "weight_N": 12,
      "maximum_buoyancy_N": 10,
      "required_displacement_m3": 0.0012,
      "required_fraction": 1.2,
      "feasible": false,
      "full_submersion_net_N": -2
    }
  }
}
```

### Exercice 1

Calculez le poids et la poussée maximale.

<details><summary>Réponse 1</summary>

Ils valent `6 N` et `10 N`. La seconde utilise toute l’enveloppe étanche, et non le seul volume du métal.

</details>

### Exercice 2

Trouvez le déplacement et la fraction requise.

<details><summary>Réponse 2</summary>

Ils valent `0.0006 m^3` et `0.6`. C’est un déplacement d’équilibre possible, sans mesure issue d’une image.

</details>

### Exercice 3

Interprétez la résultante en immersion totale.

<details><summary>Réponse 3</summary>

Elle vaut `4 N` vers le haut. À l’équilibre flottant proposé, la résultante s’annulerait dans les hypothèses statiques déclarées.

</details>

### Exercice 4

Appliquez le témoin plus lourd.

<details><summary>Réponse 4</summary>

La fraction requise vaut `1.2` et la résultante en immersion totale `-2 N`. L’immersion partielle ne peut équilibrer ce poids.

</details>

### Exercice 5

La faisabilité établit-elle une orientation stable ?

<details><summary>Réponse 5</summary>

Non. Le calcul ne contient ni couple de rappel ni modèle d’entrée d’eau. Stabilité et étanchéité exigent des preuves distinctes pour cet usage.

</details>

## Travail avec sources et référence manuelle directe

Préparez une annotation distinguant enveloppe et coque pour une sculpture Atlas creuse proposée. Prenez pour référence directe un bilan des forces manuscrit ; identifiez le volume qu’une inspection future du maillage devrait établir. Laissez les mesures physiques et de scène vides.

Traitez le témoin comme un enregistrement distinct. Préservez le cas principal, écrivez une prédiction pour l’entrée modifiée et expliquez quelle prémisse change. En cas d’écart avec la première réponse, distinguez erreur de calcul, erreur d’interprétation et limite du modèle. Gardez tentative échouée et correction côte à côte. Le travail demande une note vérifiable avant de proposer un nœud DSL ou un flux d’agents ; une table manuelle peut déjà répondre au besoin.

Soumettez ensemble référence initiale, emplacements de sources, explication corrigée, résultat du témoin et critère de réfutation. Les critères préparés ci-dessous s’adressent à une révision future ; ils ne sont pas des apprentissages acceptés. Réponse réelle, historique d’aide, correction et décision restent vides jusqu’à conservation d’une tentative. Révision technique, révision linguistique, exécution, adoption en production et publication exigent chacune leurs preuves applicables. Un calcul fini réussi établirait seulement l’opération déclarée dans ses hypothèses.

## Critère de réfutation annoncé

Toute affirmation selon laquelle le témoin plus lourd flotte partiellement avec ce volume étanche inchangé est réfutée par sa fraction requise.

## Critères d’apprentissage préparés

- Pour l’exercice 1: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 2: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 3: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 4: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 5: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.

## Sources et périmètre des affirmations

- [Prérequis commité: phy-014-preserve-mass-assumptions-when-scaling-a-craft-mesh](../../physics/phy-014-preserve-mass-assumptions-when-scaling-a-craft-mesh/)
- [Source de projet conservée](https://github.com/spareilleux/learn/blob/main/code/blender/scripts/atlas/kit.py)
- [Lecture primaire](https://openstax.org/books/university-physics-volume-1/pages/14-4-archimedes-principle-and-buoyancy)
- [Paquet construit](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/unit-c.json)
- [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/journal.md)
