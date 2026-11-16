---
title: Borner l’amplification de tension autour d’un plot artisanal
description: Borner l’amplification de tension autour d’un plot artisanal — Physique
sidebar:
  label: PHY-023 · Borner l’amplification de tension autour d’un plot artisanal
  order: 23
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/physics/fr/phy-023-bound-tension-amplification-around-a-craft-peg.fr.md
---

:::note[Streeling University]
**PHY-023** · Borner l’amplification de tension autour d’un plot artisanal · avancé · 45 minutes

Généré par le département *Physique* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/physics/fr/phy-023-bound-tension-amplification-around-a-craft-peg.fr.md) · [Mon journal](../../journal/)

Prérequis: [PHY-019](../../physics/phy-019-test-sliding-before-calling-a-sculpture-stable/)
:::

> Brouillon pour révision technique et linguistique. Entrées numériques, étiquettes et résultats attendus sont des cas pédagogiques construits. Ils ne constituent ni nouveaux essais matériels physiques, ni exécutions natives de scène, ni observations d’apprentissage, ni résultats de production. Les décisions humaines et d’apprentissage restent indécises.

## Opération du projet et interprétation

Une présentation de nœud fait passer un brin autour d’un plot avant le croisement mis en évidence. Un agent affirme que doubler les tours ne fait que doubler la tension supportée. L’opération dérive ici une capacité exponentielle à partir d’un angle de contact déclaré. Elle concerne une corde idéale souple sur un support circulaire rigide, à la limite du glissement. La scène artisanale sert de support à une annotation mécanique proposée ; son maillage ne prouve aucun frottement.

La relation limite de la source exige de préserver direction et frontière du système. Nommez la faible tension de maintien et la forte tension de charge avant leur rapport. Sous la limite, le frottement n’atteint pas nécessairement son maximum partout. Calculez donc une capacité puis comparez-la à la demande ; n’attribuez pas automatiquement le rapport limite à toute corde immobile. L’angle est l’angle total de contact, et non le changement de direction visible des extrémités après suppression des tours complets.

Le témoin sans contact conserve les forces aux extrémités et le coefficient. La perte de capacité isole l’apport géométrique au lieu de changer simultanément matériau et géométrie. Pour une annotation future dans [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md) ou [Godot](https://docs.godotengine.org/en/4.5/), conservez le trajet de contact, l’auto-contact exclu et le sens de glissement possible. Une image d’enroulement plausible ne fournit pas de coefficient de frottement. Des fibres réelles, un œillet de broderie anguleux ou un nœud déformable peuvent contredire les hypothèses du plot rigide.

L’angle de contact se mesure en radians. Un tour complet contribue tout son angle ; la seule direction visible des extrémités ne remplace pas ce total.

Lisez le prérequis commité et le passage primaire délimité avant de calculer. Préparez un relevé séparant définition de source, prémisse construite, résultat dérivé et observation future. Une documentation ne soutient que l’affirmation située dans son périmètre lu. Paramètre de source, réponse mathématique et observation d’exécution ont des rôles de preuve différents ; un résumé assuré d’assistant ne peut les échanger. Le paquet conserve révision et périmètre de lecture pour permettre de contester une affirmation précise.

Travaillez d’abord réponses fermées. Dessinez la table ou le schéma requis et conservez les quantités intermédiaires, avec unités ou conventions d’identité. Cette dérivation manuscrite est la référence manuelle directe. Consultez seulement ensuite un assistant ou une aide à la traduction. Gardez la question, l’emplacement cité, la suggestion reçue et la modification acceptée ou rejetée. Comparez le résultat assisté à la première tentative conservée sur les mêmes entrées. Une réponse plus courte ne constitue pas un progrès si elle omet une condition ou invente un essai terminé.

## Modèle fixe et témoin à entrée modifiée

```json
{
  "values": {
    "hold_N": 2,
    "mu": 0.5,
    "wrap_rad": 2,
    "load_N": 4
  },
  "formula": "ratio=exp(mu*wrap); capacity=hold*ratio; reserve=capacity-load; feasible=reserve>=0",
  "expected": {
    "ratio": 2.718281828459045,
    "capacity_N": 5.43656365691809,
    "reserve_N": 1.43656365691809,
    "feasible": true
  },
  "negative_control": {
    "values": {
      "hold_N": 2,
      "mu": 0.5,
      "wrap_rad": 0,
      "load_N": 4
    },
    "expected": {
      "ratio": 1,
      "capacity_N": 2,
      "reserve_N": -2,
      "feasible": false
    }
  }
}
```

### Exercice 1

Calculez le rapport limite.

<details><summary>Réponse 1</summary>

Il vaut `2.718281828459045`, exponentielle du coefficient multiplié par l’angle de contact. C’est un rapport de capacité sans dimension.

</details>

### Exercice 2

Calculez la capacité à l’extrémité.

<details><summary>Réponse 2</summary>

Elle vaut `5.43656365691809 N`. C’est la forte tension supportable dans la condition limite déclarée, sans mesure d’une corde.

</details>

### Exercice 3

Comparez capacité et demande.

<details><summary>Réponse 3</summary>

La réserve vaut `1.43656365691809 N` ; la demande construite respecte cette borne statique idéale. Cela ne certifie pas un nœud.

</details>

### Exercice 4

Appliquez le témoin sans contact.

<details><summary>Réponse 4</summary>

La capacité devient `2 N`, la réserve `-2 N` et la faisabilité devient fausse. Le coefficient seul ne crée aucune amplification de contact.

</details>

### Exercice 5

Toute corde statique réalise-t-elle le rapport limite ?

<details><summary>Réponse 5</summary>

Non. L’égalité décrit le glissement imminent. En dessous, la réponse de frottement peut être moindre ; géométrie et matériau restent à examiner.

</details>

## Travail avec sources et référence manuelle directe

Annotez une présentation IX proposée avec extrémité de maintien, extrémité chargée et arc de contact. Dérivez la capacité à la main, puis examinez si une courbe Atlas permettrait d’identifier cet arc. Proposez une observation future sans en remplir le résultat.

Traitez le témoin comme un enregistrement distinct. Préservez le cas principal, écrivez une prédiction pour l’entrée modifiée et expliquez quelle prémisse change. En cas d’écart avec la première réponse, distinguez erreur de calcul, erreur d’interprétation et limite du modèle. Gardez tentative échouée et correction côte à côte. Le travail demande une note vérifiable avant de proposer un nœud DSL ou un flux d’agents ; une table manuelle peut déjà répondre au besoin.

Soumettez ensemble référence initiale, emplacements de sources, explication corrigée, résultat du témoin et critère de réfutation. Les critères préparés ci-dessous s’adressent à une révision future ; ils ne sont pas des apprentissages acceptés. Réponse réelle, historique d’aide, correction et décision restent vides jusqu’à conservation d’une tentative. Révision technique, révision linguistique, exécution, adoption en production et publication exigent chacune leurs preuves applicables. Un calcul fini réussi établirait seulement l’opération déclarée dans ses hypothèses.

## Critère de réfutation annoncé

Une explication conservant l’amplification lorsque le témoin retire tout angle de contact est réfutée par sa capacité.

## Critères d’apprentissage préparés

- Pour l’exercice 1: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 2: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 3: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 4: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 5: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.

## Sources et périmètre des affirmations

- [Prérequis commité: phy-019-test-sliding-before-calling-a-sculpture-stable](../../physics/phy-019-test-sliding-before-calling-a-sculpture-stable/)
- [Source de projet conservée](https://github.com/spareilleux/learn/blob/main/code/blender/scripts/atlas/kit.py)
- [Lecture primaire](https://www.ocw.mit.edu/courses/8-01sc-classical-mechanics-fall-2016/mit8_01scs22_chapter8.pdf)
- [Paquet construit](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/unit-c.json)
- [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/journal.md)
