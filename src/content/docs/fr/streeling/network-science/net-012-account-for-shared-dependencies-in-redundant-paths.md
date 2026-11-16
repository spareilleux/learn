---
title: Tenir compte des dépendances communes dans des chemins redondants
description: Tenir compte des dépendances communes dans des chemins redondants — Science des réseaux
sidebar:
  label: NET-012 · Tenir compte des dépendances communes dans des chemins redondants
  order: 12
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/network-science/fr/net-012-account-for-shared-dependencies-in-redundant-paths.fr.md
---

:::note[Streeling University]
**NET-012** · Tenir compte des dépendances communes dans des chemins redondants · intermédiaire · 45 minutes

Généré par le département *Science des réseaux* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/network-science/fr/net-012-account-for-shared-dependencies-in-redundant-paths.fr.md) · [Mon journal](../../journal/)

Prérequis: [NET-003](../../network-science/net-003-worker-lane-coverage-and-fragility/)
:::

> Ce cours s’appuie sur un cas construit et des sources consultées. Les effectifs, durées, étiquettes et signaux sont des données pédagogiques inventées. La revue technique humaine, la relecture linguistique, les tentatives réelles, l’exécution, l’adoption en production et la publication restent à décider.

Un coordinateur voit deux chemins pour obtenir une revue et affirme que chacun peut secourir l’autre. Les deux peuvent dépendre du même service de dépôt ou fournisseur d’identifiants. Le prérequis compte les choix déclarés après une coupure. Ce cours pose une question probabiliste lorsque les chemins partagent un prérequis. Deux chemins dans un graphe ne constituent pas à eux seuls deux possibilités indépendantes.

Conditionnez d’abord sur la disponibilité de la dépendance commune. Dans cette condition, les succès des branches sont supposés indépendants ; la probabilité de leurs échecs simultanés est donc le produit. Soustrayez-la de l’unité pour l’union conditionnelle, puis multipliez par la réussite du prérequis commun. Ce facteur reste à l’extérieur de l’union. Le copier comme s’il était indépendant changerait le modèle.

Le raccourci tentant calcule la réussite marginale de chaque chemin, puis suppose ces événements indépendants. Ils dépendent pourtant du prérequis partagé, ce qui surestime la réussite. Le contrôle affaiblit ce prérequis en gardant les comportements conditionnels. L’écart obtenu illustre le coût caché de la dépendance commune. Les probabilités sont inventées et ne mesurent aucun fournisseur ni l’exposition d’un utilisateur.

L’utilitaire [F#](https://learn.microsoft.com/dotnet/fsharp/) conservé compose des résultats parallèles et des échecs. Son existence fournit une frontière à lire, sans mesure ni théorème d’indépendance. La provenance [W3C](https://www.w3.org/TR/2013/REC-prov-dm-20130430/) distingue les activités des entités utilisées, ce qui aide à tracer la dépendance. Avant de proposer un workflow redondant, dessinez l’arbre des conditions et cherchez les prérequis communs. Nombre de chemins, déclaration parallèle et fiabilité observée restent des preuves distinctes.

## Sources et périmètre du projet

Lisez le prérequis avant d’utiliser le modèle. Examinez l’artefact conservé du projet à la révision indiquée dans le dossier et repérez le champ ou la branche qui étaye l’observation. La source fournit une représentation ou un comportement déclaré ; elle ne transforme pas le cas inventé en résultat observé du projet. La lecture primaire apporte le concept nommé dans les limites annoncées.

[Prérequis: net-003-worker-lane-coverage-and-fragility](../../network-science/net-003-worker-lane-coverage-and-fragility/)

[Artefact conservé du projet](https://github.com/spareilleux/learn/blob/main/code/streeling/functional-composition/vendor/GaAsync.fs)

[Lecture primaire: W3C Recommendation 2013-04-30](https://www.w3.org/TR/2013/REC-prov-dm-20130430/)

[Lecture primaire: Microsoft F# documentation, read 2026-10-24](https://learn.microsoft.com/dotnet/fsharp/)

## Modèle fixé et contrôle

```json
{
  "values": {
    "shared_success": 0.95,
    "branch_a_success_given_shared": 0.8,
    "branch_b_success_given_shared": 0.9
  },
  "formula": "success=shared_success*(1-(1-a)*(1-b)); marginal_a=shared_success*a; marginal_b=shared_success*b; naive_independent=1-(1-marginal_a)*(1-marginal_b).",
  "expected": {
    "conditional_branch_union": 0.98,
    "success": 0.931,
    "marginal_a": 0.76,
    "marginal_b": 0.855,
    "naive_independent": 0.9652
  },
  "negative_control": {
    "values": {
      "shared_success": 0.5,
      "branch_a_success_given_shared": 0.8,
      "branch_b_success_given_shared": 0.9
    },
    "expected": {
      "conditional_branch_union": 0.98,
      "success": 0.49,
      "marginal_a": 0.4,
      "marginal_b": 0.45,
      "naive_independent": 0.67
    },
    "why": "A weaker shared dependency worsens both paths together; independent marginal multiplication overstates the union."
  },
  "assumptions": [
    "Branch successes independent conditional on the shared dependency succeeding.",
    "Both paths fail if the shared dependency fails.",
    "Authored probabilities refer to the same window and operation."
  ],
  "limits": "No live provider availability measured; correlation outside this conditional model may differ."
}
```

### Exercice 1

Calculez la probabilité conditionnelle qu’au moins une branche réussisse.

<details><summary>Réponse 1</summary>

Elle vaut `1-(1-0.8)*(1-0.9)=0.98`. L’indépendance ne s’applique qu’après conditionnement sur la réussite du prérequis commun. Sinon, les chemins partagent une cause d’échec.

</details>

### Exercice 2

Calculez la réussite totale du cas principal.

<details><summary>Réponse 2</summary>

Elle vaut `0.95*0.98=0.931`. Le prérequis commun doit réussir en plus de l’union des branches. Le résultat ne peut dépasser sa probabilité de réussite sous ces hypothèses.

</details>

### Exercice 3

Calculez le raccourci trompeur utilisant les marges indépendantes.

<details><summary>Réponse 3</summary>

Les marges valent `0.76` et `0.855` ; le raccourci donne `0.9652`. Il surestime `0.931` en ignorant l’échec commun. Des marges justes ne rendent pas les événements indépendants.

</details>

### Exercice 4

Appliquez le contrôle avec prérequis moins fiable.

<details><summary>Réponse 4</summary>

L’union conditionnelle reste `0.98`, la réussite réelle du modèle devient `0.49` et le raccourci `0.67`. Améliorer les seules branches ne supprime pas la limite commune.

</details>

### Exercice 5

Qu’est-ce qui justifierait une affirmation réelle de redondance ?

<details><summary>Réponse 5</summary>

Gardez opération, fenêtre, résultats mesurés des branches et du prérequis, services communs et hypothèses justifiées. L’utilitaire et les probabilités inventées montrent la question à poser, sans établir de disponibilité réelle ni autoriser un nouveau mécanisme de repli.

</details>

## Travail avec consultation des sources

Commencez par un tableau sur papier avant d’ouvrir les réponses. Recopiez les entrées et leurs unités, appliquez l’opération déclarée et conservez les résultats intermédiaires. Ce calcul direct constitue la référence manuelle pour comparer une réponse assistée ou une notation composable proposée. Une réponse plus courte ne présente aucun avantage démontré si elle perd l’identité d’une entrée, une catégorie d’échec ou le contre-exemple.

Examinez ensuite le passage précis consigné dans le dossier. Ne citez que le petit champ ou la branche nécessaire à votre explication, avec sa révision. Après avoir enregistré votre première réponse, demandez à un assistant de contester une hypothèse. Conservez la consigne, sa réponse, les corrections retenues et les suggestions rejetées. La consultation des sources et la calculatrice sont autorisées ; signalez cette aide pour ne pas présenter le résultat comme un rappel sans assistance.

Appliquez l’entrée modifiée du contrôle négatif et énoncez un résultat observable qui réfuterait votre conclusion avant de recommander un changement. Un contrôle inattendu impose de vérifier le calcul et les hypothèses avant de modifier le fonctionnement du projet. Remettez ensemble la réponse initiale, la réponse corrigée, l’historique des aides et l’incertitude restante. Le dossier prépare cinq critères, un par exercice, dont les décisions restent indéterminées. Les corrigés et vérifications de l’auteur ne remplissent pas ces décisions. Une future comparaison en dogfooding exige des tentatives réelles sur la même tâche et une référence manuelle conservée ; ce cours ne demande aucune nouvelle implémentation d’agent ou de DSL.

[Dossier fixé de l’unité](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/unit-b.json) · [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/journal.md)
