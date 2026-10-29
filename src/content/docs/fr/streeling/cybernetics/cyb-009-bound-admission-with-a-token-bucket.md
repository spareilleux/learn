---
title: Limiter l’admission avec un seau à jetons
description: Limiter l’admission avec un seau à jetons — Cybernétique
sidebar:
  label: CYB-009 · Limiter l’admission avec un seau à jetons
  order: 9
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/cybernetics/fr/cyb-009-bound-admission-with-a-token-bucket.fr.md
---

:::note[Streeling University]
**CYB-009** · Limiter l’admission avec un seau à jetons · intermédiaire · 45 minutes

Généré par le département *Cybernétique* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/cybernetics/fr/cyb-009-bound-admission-with-a-token-bucket.fr.md) · [Mon journal](../../journal/)

Prérequis: [CYB-006](../../cybernetics/cyb-006-bound-retry-feedback-and-workload/)
:::

> **Portée du brouillon.** Modèles fixes construits à partir de sources inspectées. Les décisions humaines techniques, linguistiques et d’apprentissage restent en attente. Aucun résultat de flotte active, contrôleur de production, télémétrie utilisateur ou progrès d’apprentissage n’est revendiqué. Le journal distingue tests réellement exécutés, lectures et contrôles prévus.

## Sources à examiner

- [cyb-006-bound-retry-feedback-and-workload.md](../../cybernetics/cyb-006-bound-retry-feedback-and-workload/)
- [dag.rs](https://raw.githubusercontent.com/GuitarAlchemist/ix/456df065ee837e33b5bbe22a4df0616a4fcb76e5/crates/ix-pipeline/src/dag.rs)
- [rfc2697.html](https://www.rfc-editor.org/rfc/rfc2697.html)

Un coordinateur IX peut identifier correctement les tâches prêtes tout en en admettant trop lors d'une rafale. Le prérequis sur les relances compte le travail supplémentaire proposé ; il ne définit pas de limite de rafale. Un seau à jetons construit ici donne une règle d'admission calculable sur papier. Il contrôle les événements d'admission ; une règle distincte de places disponibles contrôlerait l'exécution simultanée. Les deux contrôles répondent à des questions différentes.

Le RFC décrit des seaux à jetons pour mesurer des paquets, avec une capacité et un débit de remplissage. Nous reprenons cette comptabilité, sans prétendre implémenter toute sa spécification de coloration. Nos jetons autorisent l'admission de tâches pédagogiques de coût unitaire. La source du graphe IX décrit les dépendances ; elle ne prouve pas l'installation de ce seau. Une tâche peut donc être prête selon le graphe et refusée par notre modèle indépendant.

Partez d'un seau plein et traitez les arrivées dans l'ordre déclaré, y compris celles du même instant. Ajoutez seulement le crédit correspondant au temps écoulé depuis l'arrivée précédente, sans dépasser la capacité. Une tâche admise dépense son coût ; une tâche refusée ne dépense rien et ne devient pas fictivement terminée. Traiter séquentiellement les entrées d'une rafale ne lui procure aucun temps de recharge. Il faut donc préciser l'horloge et l'ordre des événements.

La trace conserve les refus. Les supprimer cacherait la demande proposée et ferait paraître le limiteur plus généreux. Notre modèle n'a pas de file d'attente : le refus concerne cette arrivée. Mettre les refus en attente exigerait de définir propriété, expiration, relance et annulation. Modifier la capacité change aussi la permission de rafale même lorsque le débit de remplissage reste constant.

Le contrôle négatif désactive le remplissage afin de distinguer le crédit initial du crédit ultérieur. Pour le travail avec les sources, comparez les unités de capacité et de débit du RFC à nos unités de tâches, puis notez la différence sur un registre manuel. Examinez ensuite la requête des prédécesseurs IX pour identifier séparément la disponibilité du graphe. Rejetez une proposition qui assimile les jetons à des places de travail mesurées, recharge entre arrivées simultanées ou présente cette trace construite comme une flotte active.

## Cas fixe et calculs attendus

```json
{
  "values": {
    "capacity_tokens": 3,
    "refill_tokens_per_second": 1,
    "cost_per_job": 1,
    "arrivals_seconds": [
      0,
      0,
      0,
      0,
      1,
      1,
      2
    ]
  },
  "formula": "available=min(capacity, previous_tokens+rate*elapsed); admit iff available>=cost; debit only on admission",
  "expected": {
    "admitted": [
      true,
      true,
      true,
      false,
      true,
      false,
      true
    ],
    "remaining": [
      2,
      1,
      0,
      0,
      0,
      0,
      0
    ],
    "admissions": 5,
    "denials": 2
  },
  "negative_control": "With refill zero only the initial burst of three is admitted.",
  "assumptions": [
    "Chronological arrivals, initial bucket full, unit job cost, exact seconds, no refund."
  ],
  "limits": "Authored job-admission model; not RFC2697 packet coloring or production IX scheduling."
}
```

## Conserver une tentative d’apprenant avec ses sources

Travaillez à partir des entrées épinglées ci-dessus. Avant de demander de l’aide, écrivez votre prédiction pour le cas fixe et son contrôle négatif, avec l’unité de chaque quantité et la frontière exacte de comparaison. Un petit tableau sur papier constitue la référence manuelle directe. Gardez les valeurs intermédiaires, surtout celles qui contredisent votre première prédiction. Cette tâche d’explication utilise des sources existantes et des données fixes ; elle ne demande ni installation, ni service payant, ni nouveau programme.

Utilisez ensuite un assistant pour retrouver le passage pertinent et critiquer votre calcul. Conservez la consigne initiale, la réponse, l’emplacement cité et les modifications acceptées ou rejetées. Une citation est utile seulement si le contenu inspecté étaye l’affirmation précise. Une étape déclarée, un type de données et un commentaire n’apportent pas les mêmes preuves qu’un résultat exécuté. Expliquez cette frontière dans votre réponse finale plutôt que d’emprunter l’autorité d’une étiquette rassurante.

Remettez ensemble référence manuelle, résultat corrigé, résultat du contrôle, critère de réfutation et historique d’aide. Les critères préparés demandent si la portée est identifiée, le calcul correct, le contre-exemple conservé, l’explication étayée et la conclusion limitée à ses preuves. Ils restent indécidés sans réponse réelle d’un apprenant. Les corrigés ci-dessous sont préparés : ils ne prouvent aucun apprentissage. L’évaluateur doit garder un critère échoué et sa cause avant la correction, puis juger séparément la tentative révisée. Les preuves d’exécution et de publication, recueillies ultérieurement, exigent leurs propres relevés liés à la version.

### Exercice 1

Donnez les décisions d’admission.

<details>
<summary>Réponse 1</summary>

`[true,true,true,false,true,false,true]` ; `5` admissions et `2` refus.

</details>

### Exercice 2

Donnez les soldes restants.

<details>
<summary>Réponse 2</summary>

`[2,1,0,0,0,0,0]` ; les arrivées simultanées n’ajoutent aucun temps écoulé.

</details>

### Exercice 3

Évaluez le contrôle sans remplissage.

<details>
<summary>Réponse 3</summary>

Seulement `3` admissions ; les arrivées suivantes ne reçoivent aucun crédit.

</details>

### Exercice 4

L’admission limite-t-elle les tâches simultanées ?

<details>
<summary>Réponse 4</summary>

Pas sans durées et règle de places ; les jetons comptent le crédit d’admission.

</details>

### Exercice 5

Que faut-il ajouter pour une variante avec file ?

<details>
<summary>Réponse 5</summary>

Des règles explicites d’attente, propriété, expiration et relance ; aucune capacité réelle n’est mesurée.

</details>

[Dossier de preuves fixes](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/unit-b.json) · [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/journal.md)
