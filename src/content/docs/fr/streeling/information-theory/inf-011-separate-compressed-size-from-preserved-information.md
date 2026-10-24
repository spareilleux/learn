---
title: Distinguer taille comprimée et information préservée
description: Distinguer taille comprimée et information préservée — Théorie de l'information
sidebar:
  label: INF-011 · Distinguer taille comprimée et information préservée
  order: 11
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/information-theory/fr/inf-011-separate-compressed-size-from-preserved-information.fr.md
---

:::note[Streeling University]
**INF-011** · Distinguer taille comprimée et information préservée · intermédiaire · 45 minutes

Généré par le département *Théorie de l'information* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/information-theory/fr/inf-011-separate-compressed-size-from-preserved-information.fr.md) · [Mon journal](../../journal/)

Prérequis: [INF-004](../../information-theory/inf-004-information-loss-in-agent-handoffs/)
:::

> **Portée du brouillon.** Modèles fixes construits à partir de sources inspectées. Les décisions humaines techniques, linguistiques et d’apprentissage restent en attente. Aucun résultat de flotte active, contrôleur de production, télémétrie utilisateur ou progrès d’apprentissage n’est revendiqué. Le journal distingue tests réellement exécutés, lectures et contrôles prévus.

## Sources à examiner

- [inf-004-information-loss-in-agent-handoffs.md](../../information-theory/inf-004-information-loss-in-agent-handoffs/)
- [rfc1950.html](https://www.rfc-editor.org/rfc/rfc1950.html)

Un agent raccourcit une note de passation et affirme que la compression a tout conservé puisque le fichier est plus petit. Le prérequis montre qu'un résumé peut fusionner des états exigeant des décisions différentes. Ce cours compare cette opération irréversible à un codage explicitement réversible. Les tailles proviennent d'un format pédagogique, sans mesure d'un vrai compresseur ni d'un gain de jetons.

La spécification primaire zlib décrit un format de données comprimées sans perte. Elle motive le contrôle de réversibilité ; notre notation par plages répétées reste un format construit distinct. L'alphabet d'entrée et le décodeur sont supposés connus. Chaque plage stocke son symbole et un caractère de longueur, auquel s'ajoute l'en-tête fixe. Cette hypothèse exclut les longues plages et les données binaires arbitraires ; les prendre en charge demanderait une autre règle comptable.

Pour l'entrée répétée, développez chaque plage codée et comparez la chaîne complète à l'original. Un aller-retour correct vérifie l'identité des octets pour cette entrée et ce décodeur. La taille stockée inclut l'en-tête. Un rapport limité à la charge utile exagérerait la réduction. Inversement, partager un gros en-tête entre plusieurs enregistrements exigerait d'allouer explicitement son coût, pas de le faire disparaître.

Le contrôle alterné grossit parce que chaque symbole demande sa propre paire. L'absence de perte ne garantit pas une réduction pour toute entrée. Le résumé limité à l'alphabet est encore plus court, mais des ordres et nombres différents y aboutissent. Il indique quels symboles sont apparus sans reconstruire la suite ni permettre une décision dépendant de l'ordre. La qualité du résumé dépend donc de la question du destinataire.

Pour le travail avec les sources, lisez la collision du prérequis et la portée sans perte de la spécification. Codez et décodez les deux chaînes à la main comme référence directe. Demandez à un assistant de distinguer identité des octets, suffisance pour la tâche et taille stockée dans une passation. Conservez le cas d'expansion et la collision avec perte. Rejetez toute proposition qualifiant de sans perte une représentation simplement plus petite ou tirant un taux de compression réel de ce registre pédagogique.

## Cas fixe et calculs attendus

```json
{
  "values": {
    "raw": "AAAAABBB",
    "payload": "A5B3",
    "header_bytes": 2,
    "raw_bytes": 8,
    "payload_bytes": 4,
    "control_raw": "ABABABAB",
    "control_payload": "A1B1A1B1A1B1A1B1"
  },
  "formula": "stored_bytes=header_bytes+payload_bytes; ratio=stored_bytes/raw_bytes; alphabet summary discards order and counts",
  "expected": {
    "stored_bytes": 6,
    "ratio": 0.75,
    "control_stored_bytes": 18,
    "control_ratio": 2.25,
    "decoded": "AAAAABBB",
    "lossy_collision": [
      "AAAAABBB",
      "ABAAAABB"
    ],
    "alphabet_summary": "AB"
  },
  "negative_control": "Alternating input expands under the stipulated run-length format.",
  "assumptions": [
    "ASCII symbols A/B, runs of single-digit length, symbol then count, fixed two-byte header, exact decoder known."
  ],
  "limits": "Toy run-length accounting, not measured zlib output, entropy coding efficiency or semantic preservation for arbitrary consumers."
}
```

## Conserver une tentative d’apprenant avec ses sources

Travaillez à partir des entrées épinglées ci-dessus. Avant de demander de l’aide, écrivez votre prédiction pour le cas fixe et son contrôle négatif, avec l’unité de chaque quantité et la frontière exacte de comparaison. Un petit tableau sur papier constitue la référence manuelle directe. Gardez les valeurs intermédiaires, surtout celles qui contredisent votre première prédiction. Cette tâche d’explication utilise des sources existantes et des données fixes ; elle ne demande ni installation, ni service payant, ni nouveau programme.

Utilisez ensuite un assistant pour retrouver le passage pertinent et critiquer votre calcul. Conservez la consigne initiale, la réponse, l’emplacement cité et les modifications acceptées ou rejetées. Une citation est utile seulement si le contenu inspecté étaye l’affirmation précise. Une étape déclarée, un type de données et un commentaire n’apportent pas les mêmes preuves qu’un résultat exécuté. Expliquez cette frontière dans votre réponse finale plutôt que d’emprunter l’autorité d’une étiquette rassurante.

Remettez ensemble référence manuelle, résultat corrigé, résultat du contrôle, critère de réfutation et historique d’aide. Les critères préparés demandent si la portée est identifiée, le calcul correct, le contre-exemple conservé, l’explication étayée et la conclusion limitée à ses preuves. Ils restent indécidés sans réponse réelle d’un apprenant. Les corrigés ci-dessous sont préparés : ils ne prouvent aucun apprentissage. L’évaluateur doit garder un critère échoué et sa cause avant la correction, puis juger séparément la tentative révisée. Les preuves d’exécution et de publication, recueillies ultérieurement, exigent leurs propres relevés liés à la version.

### Exercice 1

Décodez la charge conservée.

<details>
<summary>Réponse 1</summary>

`A5B3` se décode en `AAAAABBB`, identique à l’original.

</details>

### Exercice 2

Comptez la représentation stockée complète.

<details>
<summary>Réponse 2</summary>

`2+4=6` octets ; rapport `6/8=0.75`.

</details>

### Exercice 3

Calculez le contrôle alterné.

<details>
<summary>Réponse 3</summary>

`2+16=18` octets ; rapport `18/8=2.25`, soit une expansion.

</details>

### Exercice 4

Que perd la projection sur l’alphabet ?

<details>
<summary>Réponse 4</summary>

Ordre et effectifs ; `AB` n’identifie pas une suite originale unique.

</details>

### Exercice 5

Sans perte signifie-t-il plus petit ?

<details>
<summary>Réponse 5</summary>

Non. Réversibilité et taille sont distinctes ; le contrôle est réversible et plus grand.

</details>

[Dossier de preuves fixes](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/unit-b.json) · [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/journal.md)
