---
title: Conserver l’ordre des événements dans une passation
description: Conserver l’ordre des événements dans une passation — Théorie de l'information
sidebar:
  label: INF-012 · Conserver l’ordre des événements dans une passation
  order: 12
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/information-theory/fr/inf-012-retain-event-order-in-a-handoff-summary.fr.md
---

:::note[Streeling University]
**INF-012** · Conserver l’ordre des événements dans une passation · intermédiaire · 45 minutes

Généré par le département *Théorie de l'information* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/information-theory/fr/inf-012-retain-event-order-in-a-handoff-summary.fr.md) · [Mon journal](../../journal/)

Prérequis: [INF-004](../../information-theory/inf-004-information-loss-in-agent-handoffs/)
:::

> **Portée du brouillon.** Modèles fixes construits à partir de sources inspectées. Les décisions humaines techniques, linguistiques et d’apprentissage restent en attente. Aucun résultat de flotte active, contrôleur de production, télémétrie utilisateur ou progrès d’apprentissage n’est revendiqué. Le journal distingue tests réellement exécutés, lectures et contrôles prévus.

## Sources à examiner

- [inf-004-information-loss-in-agent-handoffs.md](../../information-theory/inf-004-information-loss-in-agent-handoffs/)
- [antigravity-bridge.ps1](https://raw.githubusercontent.com/GuitarAlchemist/ga/dc2e74cbd992a298f67efb928b5b3754615e1924/Scripts/antigravity-bridge.ps1)

Une passation indique qu'une leçon a été modifiée et approuvée. Dans quel ordre, et quelle version l'approbation couvrait-elle ? Les mêmes effectifs d'événements peuvent mener à des décisions d'intégration opposées. Le prérequis montre une collision entre états. Ce cours définit un calcul dépendant de l'ordre pour rendre cette collision vérifiable, sans se fier au ton du résumé.

Le pont GA épinglé écrit un contexte léger et une note fournie par l'appelant. Son horodatage situe cette note sans reconstruire toutes les modifications et approbations antérieures. Lisez sa branche d'écriture avant de proposer un résumé enrichi. Nos historiques sont des données construites pour un flux de source unique. Ils ne prétendent pas que le pont impose un cycle d'approbation ou fournisse un journal distribué.

L'état contient la version courante et son éventuelle approbation exacte. Une modification change la version et invalide l'approbation précédente. Une approbation nomme sa cible. Appliquez les événements dans l'ordre causal fourni et gardez les états intermédiaires. Dans un historique, l'approbation précède une modification ultérieure. Dans l'autre, la nouvelle version reçoit son approbation après la modification. Compter les types d'événements efface cette différence.

Un champ d'horloge ne suffit pas si les sources ne sont pas synchronisées ou si l'observation est incomplète. Ce cours suppose une suite causale complète et ne résout donc pas l'ordre distribué. En pratique, une version parente ou une dépendance explicite peut exprimer la précédence nécessaire sans ordonner artificiellement des événements indépendants. Le contrôle négatif permute des notes sans effet sur l'état ; le calcul doit les ignorer selon sa politique.

Pour le travail avec les sources, lisez les champs capturés par le pont et les preuves d'intégration du prérequis. Transformez chaque historique en tableau d'états manuel, puis rédigez le résumé le plus court conservant la décision finale. Demandez à un assistant de retrouver cette décision à partir du seul résumé. Rejetez-le s'il fusionne les historiques, approuve une autre version ou invente des tests réussis à partir d'un horodatage. Conservez le résumé défaillant comme contre-exemple concret.

## Cas fixe et calculs attendus

```json
{
  "values": {
    "history_A": [
      "approve:r1",
      "edit:r2"
    ],
    "history_B": [
      "edit:r2",
      "approve:r2"
    ],
    "initial": "unapproved"
  },
  "formula": "edit invalidates approval; approve:r marks only exact revision r; fold events in retained order",
  "expected": {
    "A_final_revision": "r2",
    "A_approved": false,
    "B_final_revision": "r2",
    "B_approved": true,
    "same_edit_count": 1,
    "same_approval_count": 1,
    "order_free_summary": "one edit; one approval"
  },
  "negative_control": "Permuting independent notes without a state-changing effect leaves the state unchanged.",
  "assumptions": [
    "Single fictional source stream, complete causal sequence, explicit revision in each event, editing invalidates prior approval."
  ],
  "limits": "No distributed-clock total order, authenticated approval or live bridge execution is established."
}
```

## Conserver une tentative d’apprenant avec ses sources

Travaillez à partir des entrées épinglées ci-dessus. Avant de demander de l’aide, écrivez votre prédiction pour le cas fixe et son contrôle négatif, avec l’unité de chaque quantité et la frontière exacte de comparaison. Un petit tableau sur papier constitue la référence manuelle directe. Gardez les valeurs intermédiaires, surtout celles qui contredisent votre première prédiction. Cette tâche d’explication utilise des sources existantes et des données fixes ; elle ne demande ni installation, ni service payant, ni nouveau programme.

Utilisez ensuite un assistant pour retrouver le passage pertinent et critiquer votre calcul. Conservez la consigne initiale, la réponse, l’emplacement cité et les modifications acceptées ou rejetées. Une citation est utile seulement si le contenu inspecté étaye l’affirmation précise. Une étape déclarée, un type de données et un commentaire n’apportent pas les mêmes preuves qu’un résultat exécuté. Expliquez cette frontière dans votre réponse finale plutôt que d’emprunter l’autorité d’une étiquette rassurante.

Remettez ensemble référence manuelle, résultat corrigé, résultat du contrôle, critère de réfutation et historique d’aide. Les critères préparés demandent si la portée est identifiée, le calcul correct, le contre-exemple conservé, l’explication étayée et la conclusion limitée à ses preuves. Ils restent indécidés sans réponse réelle d’un apprenant. Les corrigés ci-dessous sont préparés : ils ne prouvent aucun apprentissage. L’évaluateur doit garder un critère échoué et sa cause avant la correction, puis juger séparément la tentative révisée. Les preuves d’exécution et de publication, recueillies ultérieurement, exigent leurs propres relevés liés à la version.

### Exercice 1

Appliquez l’historique A.

<details>
<summary>Réponse 1</summary>

Version finale `r2`, non approuvée : la modification invalide l’approbation de `r1`.

</details>

### Exercice 2

Appliquez l’historique B.

<details>
<summary>Réponse 2</summary>

Version finale `r2`, approuvée dans le modèle par `approve:r2`.

</details>

### Exercice 3

Comparez les effectifs sans ordre.

<details>
<summary>Réponse 3</summary>

Chacun contient `1` modification et `1` approbation ; ces nombres ne déterminent pas l’état final.

</details>

### Exercice 4

Que doit donner le contrôle de notes indépendantes ?

<details>
<summary>Réponse 4</summary>

Laisser l’état inchangé si seules des notes sans effet sont permutées.

</details>

### Exercice 5

L’horodatage authentifie-t-il l’approbation ?

<details>
<summary>Réponse 5</summary>

Non. Version, contexte causal, preuves et évaluateur autorisé restent nécessaires.

</details>

[Dossier de preuves fixes](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/unit-b.json) · [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/journal.md)
