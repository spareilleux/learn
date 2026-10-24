---
title: Calculer les chemins critiques en précisant les ressources
description: Calculer les chemins critiques en précisant les ressources — Science des réseaux
sidebar:
  label: NET-010 · Calculer les chemins critiques en précisant les ressources
  order: 10
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/network-science/fr/net-010-compute-critical-paths-with-resource-assumptions.fr.md
---

:::note[Streeling University]
**NET-010** · Calculer les chemins critiques en précisant les ressources · intermédiaire · 45 minutes

Généré par le département *Science des réseaux* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/network-science/fr/net-010-compute-critical-paths-with-resource-assumptions.fr.md) · [Mon journal](../../journal/)

Prérequis: [NET-007](../../network-science/net-007-separate-dag-readiness-from-admission/)
:::

> **Portée du brouillon.** Modèles fixes construits à partir de sources inspectées. Les décisions humaines techniques, linguistiques et d’apprentissage restent en attente. Aucun résultat de flotte active, contrôleur de production, télémétrie utilisateur ou progrès d’apprentissage n’est revendiqué. Le journal distingue tests réellement exécutés, lectures et contrôles prévus.

## Sources à examiner

- [net-007-separate-dag-readiness-from-admission.md](../../network-science/net-007-separate-dag-readiness-from-admission/)
- [dag.rs](https://raw.githubusercontent.com/GuitarAlchemist/ix/456df065ee837e33b5bbe22a4df0616a4fcb76e5/crates/ix-pipeline/src/dag.rs)

Un coordinateur dessine les dépendances d'un pipeline de cours et annonce le plus long chemin comme délai promis. Ce n'est qu'une borne inférieure liée aux dépendances si les tâches se disputent aussi une ressource. Le prérequis introduit l'admission des tâches. Ce cours conserve le graphe et ajoute une ressource exclusive qui repousse la fin réalisable au-delà du plus long chemin.

La source IX épinglée fournit les prédécesseurs et l'ordre topologique. Elle n'ajoute ni nos durées ni nos réservations de ressources, qui appartiennent au cas pédagogique construit. Les tâches concurrentes peuvent représenter des activités nécessitant le même évaluateur réservé ou le même appareil pendant toute leur durée. Cette interprétation reste illustrative : aucune disponibilité, performance de service ou cadence humaine n'a été observée.

Calculez d'abord les fins au plus tôt avec des ressources illimitées. Un nœud commence après tous ses prédécesseurs ; leur plus grande date de fin détermine le début d'une jonction. Conservez les durées en ticks sans les convertir sans preuve en jours. Le calcul se reproduit à partir du graphe et des coûts, mais exclut les conflits de ressources par construction.

Ajoutez ensuite l'exclusivité. Les tâches concernées doivent se suivre même si le graphe les rend prêtes ensemble après leur prédécesseur commun. Les deux ordres occupent la ressource pendant la même durée totale dans ce petit cas. La jonction attend les deux. Un planning valide donne des intervalles permettant de vérifier dépendances et absence de chevauchement. Un ordre topologique seul ne donne ni dates de début ni allocation réalisable.

Le contrôle négatif supprime le conflit en gardant durées et arêtes. L'exécution parallèle atteint alors la borne liée aux dépendances. Pour le travail avec les sources, examinez la recherche des prédécesseurs IX et la distinction du prérequis entre largeur et travailleurs actifs. Dessinez les deux plannings à la main avant toute optimisation par un assistant. Rejetez une promesse qui superpose des réservations exclusives ou transforme un tick construit en durée mesurée. Conservez le planning rapide impossible comme contre-exemple.

## Cas fixe et calculs attendus

```json
{
  "values": {
    "durations_ticks": {
      "A": 2,
      "B": 4,
      "C": 3,
      "D": 1
    },
    "edges": [
      [
        "A",
        "B"
      ],
      [
        "A",
        "C"
      ],
      [
        "B",
        "D"
      ],
      [
        "C",
        "D"
      ]
    ],
    "shared_resource_jobs": [
      "B",
      "C"
    ],
    "resource_capacity": 1
  },
  "formula": "earliest_finish(v)=duration(v)+max(earliest_finish(predecessors)); add explicit non-overlap for shared exclusive resource",
  "expected": {
    "unlimited_earliest_finish": {
      "A": 2,
      "B": 6,
      "C": 5,
      "D": 7
    },
    "dependency_lower_bound": 7,
    "resource_schedule": {
      "A": [
        0,
        2
      ],
      "B": [
        2,
        6
      ],
      "C": [
        6,
        9
      ],
      "D": [
        9,
        10
      ]
    },
    "resource_makespan": 10,
    "alternative_resource_order_makespan": 10
  },
  "negative_control": "Removing the resource conflict permits B and C to overlap and finish in7ticks.",
  "assumptions": [
    "Exact nonpreemptive durations, no overhead, both B and C require the same exclusive resource for their whole duration, others unconstrained."
  ],
  "limits": "No optimal scheduler implementation, real worker utilization or IX timing was measured."
}
```

## Conserver une tentative d’apprenant avec ses sources

Travaillez à partir des entrées épinglées ci-dessus. Avant de demander de l’aide, écrivez votre prédiction pour le cas fixe et son contrôle négatif, avec l’unité de chaque quantité et la frontière exacte de comparaison. Un petit tableau sur papier constitue la référence manuelle directe. Gardez les valeurs intermédiaires, surtout celles qui contredisent votre première prédiction. Cette tâche d’explication utilise des sources existantes et des données fixes ; elle ne demande ni installation, ni service payant, ni nouveau programme.

Utilisez ensuite un assistant pour retrouver le passage pertinent et critiquer votre calcul. Conservez la consigne initiale, la réponse, l’emplacement cité et les modifications acceptées ou rejetées. Une citation est utile seulement si le contenu inspecté étaye l’affirmation précise. Une étape déclarée, un type de données et un commentaire n’apportent pas les mêmes preuves qu’un résultat exécuté. Expliquez cette frontière dans votre réponse finale plutôt que d’emprunter l’autorité d’une étiquette rassurante.

Remettez ensemble référence manuelle, résultat corrigé, résultat du contrôle, critère de réfutation et historique d’aide. Les critères préparés demandent si la portée est identifiée, le calcul correct, le contre-exemple conservé, l’explication étayée et la conclusion limitée à ses preuves. Ils restent indécidés sans réponse réelle d’un apprenant. Les corrigés ci-dessous sont préparés : ils ne prouvent aucun apprentissage. L’évaluateur doit garder un critère échoué et sa cause avant la correction, puis juger séparément la tentative révisée. Les preuves d’exécution et de publication, recueillies ultérieurement, exigent leurs propres relevés liés à la version.

### Exercice 1

Calculez les fins avec ressources illimitées.

<details>
<summary>Réponse 1</summary>

A `2`, B `6`, C `5`, D `7` ; durée du plus long chemin `7`.

</details>

### Exercice 2

Donnez un planning avec ressource exclusive.

<details>
<summary>Réponse 2</summary>

A `[0,2)`, B `[2,6)`, C `[6,9)`, D `[9,10)` ; fin `10`.

</details>

### Exercice 3

Inversez l’ordre d’usage de la ressource.

<details>
<summary>Réponse 3</summary>

C `[2,5)`, B `[5,9)`, D `[9,10)` finissent encore à `10`.

</details>

### Exercice 4

Évaluez le contrôle sans conflit.

<details>
<summary>Réponse 4</summary>

Superposez B et C après A ; D finit à `7`, la borne des dépendances.

</details>

### Exercice 5

Qu’est-ce qui réfute un planning ?

<details>
<summary>Réponse 5</summary>

Un prédécesseur inachevé ou des réservations exclusives superposées ; aucun délai réel n’en découle.

</details>

[Dossier de preuves fixes](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/unit-b.json) · [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/journal.md)
