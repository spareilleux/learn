---
title: Composer des blocs qui se chevauchent sans dupliquer les trames
description: Composer des blocs qui se chevauchent sans dupliquer les trames — Informatique
sidebar:
  label: CS-015 · Composer des blocs qui se chevauchent sans dupliquer les trames
  order: 15
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/computer-science/fr/cs-015-compose-overlapping-chunks-without-duplicate-frames.fr.md
---

:::note[Streeling University]
**CS-015** · Composer des blocs qui se chevauchent sans dupliquer les trames · intermédiaire · 45 minutes

Généré par le département *Informatique* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/computer-science/fr/cs-015-compose-overlapping-chunks-without-duplicate-frames.fr.md) · [Mon journal](../../journal/)

Prérequis: [CS-013](../../computer-science/cs-013-preserve-spectral-axes-and-units/)
:::

> **Portée du brouillon.** Modèles fixes construits à partir de sources inspectées. Les décisions humaines techniques, linguistiques et d’apprentissage restent en attente. Aucun résultat de flotte active, contrôleur de production, télémétrie utilisateur ou progrès d’apprentissage n’est revendiqué. Le journal distingue tests réellement exécutés, lectures et contrôles prévus.

## Sources à examiner

- [cs-013-preserve-spectral-axes-and-units.md](../../computer-science/cs-013-preserve-spectral-axes-and-units/)

Un rapport audio de GA peut sembler cohérent alors que son assemblage émet deux fois la même trame d'analyse. Le cours précédent retrouve le support des trames et les unités des axes à partir d'un gestionnaire IX. Ici, ces coordonnées sont supposées correctes : il faut déterminer quel bloc possède chaque trame globale. Le registre d'intervalles est un exemple construit, sans capture d'un service audio en cours d'exécution. Ses indices désignent des trames d'analyse, pas des amplitudes ni des secondes.

Chaque intervalle inclut son début et exclut sa fin. Deux intervalles adjacents peuvent ainsi se rejoindre sans partager la trame frontière. Chaque bloc conserve l'identité du flux et son décalage global. Concaténer les tableaux locaux en supprimant ces décalages masque leur chevauchement. Le contrôle de longueur compte alors des entrées stockées plutôt que des observations globales distinctes. Conservez le registre initial pour pouvoir auditer un export apparemment réussi.

La règle du premier propriétaire ne s'applique que si les indices répétés portent des valeurs identiques et une provenance compatible. Le premier bloc possède tout son intervalle. Les suivants n'émettent que les indices encore libres. Une valeur différente au même indice exige une décision de conflit distincte : retenir silencieusement la première masquerait le désaccord. Ce cours ne définit ni fondu, ni moyenne, ni reconstruction du signal. Ces opérations ont d'autres significations physiques et demandent leurs propres contrats.

Le registre attendu ci-dessous distingue le nombre brut et l'union conservée. Calculez-les séparément avant de consulter les réponses. L'élimination des doublons réussit seulement si l'union couvre exactement l'intervalle cible. Une lacune reste un échec, même si la longueur finale correspond par hasard à une autre attente. Réciproquement, une couverture complète ne valide ni l'audio, ni sa cadence, ni son association à la bonne note. L'identité et la couverture se contrôlent séparément.

Pour le travail avec les sources, ouvrez les sections du prérequis consacrées à la forme et à la fin du signal. Repérez la différence entre le support des fenêtres complètes et l'étendue affichée. Annotez ce registre à la main, puis demandez à un assistant d'expliquer la propriété des indices à partir de ces passages. La référence manuelle est une liste triée d'indices globaux. Rejetez l'abstraction proposée si elle cache un indice manquant ou écarte un doublon contradictoire sans en garder la cause.

## Cas fixe et calculs attendus

```json
{
  "values": {
    "chunks": [
      [
        0,
        6
      ],
      [
        4,
        10
      ],
      [
        8,
        12
      ]
    ],
    "target": [
      0,
      12
    ]
  },
  "formula": "half-open intervals; first writer owns an index; retain sorted union",
  "expected": {
    "raw_frames": 16,
    "distinct_frames": 12,
    "duplicate_emissions": 4,
    "owned": [
      [
        0,
        6
      ],
      [
        6,
        10
      ],
      [
        10,
        12
      ]
    ],
    "gap_control": [
      [
        0,
        6
      ],
      [
        7,
        12
      ]
    ],
    "missing_index": 6
  },
  "negative_control": "A gap at index6 cannot be repaired by dropping duplicates.",
  "assumptions": [
    "Integer frame indices, half-open intervals, identical values for repeated indices, one declared stream identity."
  ],
  "limits": "Coverage is not audio quality, overlap-add synthesis or observed streaming behavior."
}
```

## Conserver une tentative d’apprenant avec ses sources

Travaillez à partir des entrées épinglées ci-dessus. Avant de demander de l’aide, écrivez votre prédiction pour le cas fixe et son contrôle négatif, avec l’unité de chaque quantité et la frontière exacte de comparaison. Un petit tableau sur papier constitue la référence manuelle directe. Gardez les valeurs intermédiaires, surtout celles qui contredisent votre première prédiction. Cette tâche d’explication utilise des sources existantes et des données fixes ; elle ne demande ni installation, ni service payant, ni nouveau programme.

Utilisez ensuite un assistant pour retrouver le passage pertinent et critiquer votre calcul. Conservez la consigne initiale, la réponse, l’emplacement cité et les modifications acceptées ou rejetées. Une citation est utile seulement si le contenu inspecté étaye l’affirmation précise. Une étape déclarée, un type de données et un commentaire n’apportent pas les mêmes preuves qu’un résultat exécuté. Expliquez cette frontière dans votre réponse finale plutôt que d’emprunter l’autorité d’une étiquette rassurante.

Remettez ensemble référence manuelle, résultat corrigé, résultat du contrôle, critère de réfutation et historique d’aide. Les critères préparés demandent si la portée est identifiée, le calcul correct, le contre-exemple conservé, l’explication étayée et la conclusion limitée à ses preuves. Ils restent indécidés sans réponse réelle d’un apprenant. Les corrigés ci-dessous sont préparés : ils ne prouvent aucun apprentissage. L’évaluateur doit garder un critère échoué et sa cause avant la correction, puis juger séparément la tentative révisée. Les preuves d’exécution et de publication, recueillies ultérieurement, exigent leurs propres relevés liés à la version.

### Exercice 1

Comptez les trames brutes et distinctes.

<details>
<summary>Réponse 1</summary>

`6+6+4=16` ; longueur de l’union `12` ; émissions en double `4`.

</details>

### Exercice 2

Donnez les intervalles attribués.

<details>
<summary>Réponse 2</summary>

`[0,6), [6,10), [10,12)` selon la règle du premier propriétaire.

</details>

### Exercice 3

Expliquez le contrôle avec lacune.

<details>
<summary>Réponse 3</summary>

`[0,6), [7,12)` omet l’indice `6` ; supprimer les doublons ne peut le fournir.

</details>

### Exercice 4

Peut-on écarter silencieusement des doublons contradictoires ?

<details>
<summary>Réponse 4</summary>

Non. Conservez les valeurs et leur provenance : l’hypothèse d’identité a échoué.

</details>

### Exercice 5

Qu’est-ce qui réfute la correction de l’assemblage ?

<details>
<summary>Réponse 5</summary>

Un indice cible absent, une émission répétée ou un conflit caché ; la couverture ne prouve aucune qualité audio.

</details>

[Dossier de preuves fixes](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/unit-b.json) · [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/journal.md)
