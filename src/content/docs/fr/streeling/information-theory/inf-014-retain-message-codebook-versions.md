---
title: Conserver les versions des dictionnaires de messages
description: Conserver les versions des dictionnaires de messages — Théorie de l'information
sidebar:
  label: INF-014 · Conserver les versions des dictionnaires de messages
  order: 14
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/information-theory/fr/inf-014-retain-message-codebook-versions.fr.md
---

:::note[Streeling University]
**INF-014** · Conserver les versions des dictionnaires de messages · intermédiaire · 45 minutes

Généré par le département *Théorie de l'information* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/information-theory/fr/inf-014-retain-message-codebook-versions.fr.md) · [Mon journal](../../journal/)

Prérequis: [INF-004](../../information-theory/inf-004-information-loss-in-agent-handoffs/)
:::

> Ce cours s’appuie sur un cas construit et des sources consultées. Les effectifs, durées, étiquettes et signaux sont des données pédagogiques inventées. La revue technique humaine, la relecture linguistique, les tentatives réelles, l’exécution, l’adoption en production et la publication restent à décider.

Un handoff compact remplace les verdicts par de petites étiquettes. Elles arrivent intactes, mais l’agent destinataire annonce les verdicts opposés. Le prérequis examine les champs perdus dans un résumé. Ce cours isole une autre défaillance : les mêmes symboles changent de sens selon deux dictionnaires parfaitement inversibles. Une transmission réussie ne prouve pas que les deux agents ont choisi la même interprétation.

La version du dictionnaire fait partie du contexte du message. Décodez selon la règle de l’expéditeur pour obtenir les étiquettes voulues, puis selon celle du destinataire, sans changer les symboles. Comptez les désaccords par position au lieu de comparer seulement les totaux. Inverser la correspondance peut conserver fréquence et longueur tout en changeant chaque verdict. Une empreinte des symboles ne détecterait pas ce désaccord ni la version sémantique manquante.

Le problème de communication de [Shannon](https://people.math.harvard.edu/~ctm/home/text/others/shannon/entropy/entropy.pdf) distingue le message choisi de sa représentation transmise. Notre cas suppose un canal sans erreur et examine les correspondances. La provenance [W3C](https://www.w3.org/TR/2013/REC-prov-dm-20130430/) motive la conservation de l’entité qui fournit une règle de dérivation. Aucune de ces sources ne définit un nouveau schéma GA. La séparation des métadonnées et du corps dans le parseur Learn offre une représentation concrète à lire, sans implémenter ces étiquettes binaires.

Le contrôle change le dictionnaire du destinataire en conservant tous les symboles. Il rend l’accord manquant explicite et fournit une référence manuelle. Un DSL peut abréger la correspondance, mais doit garder l’identité du dictionnaire récupérable et laisser une version inconnue indéterminée. Choisir selon un verdict plausible inverserait le raisonnement : le sens souhaité ne doit pas déterminer le décodeur après coup. Aucune migration ni politique de compatibilité n’est implémentée ici.

## Sources et périmètre du projet

Lisez le prérequis avant d’utiliser le modèle. Examinez l’artefact conservé du projet à la révision indiquée dans le dossier et repérez le champ ou la branche qui étaye l’observation. La source fournit une représentation ou un comportement déclaré ; elle ne transforme pas le cas inventé en résultat observé du projet. La lecture primaire apporte le concept nommé dans les limites annoncées.

[Prérequis: inf-004-information-loss-in-agent-handoffs](../../information-theory/inf-004-information-loss-in-agent-handoffs/)

[Artefact conservé du projet](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Lecture primaire: Shannon 1948 corrected reprint, section 6](https://people.math.harvard.edu/~ctm/home/text/others/shannon/entropy/entropy.pdf)

[Lecture primaire: W3C Recommendation 2013-04-30](https://www.w3.org/TR/2013/REC-prov-dm-20130430/)

## Modèle fixé et contrôle

```json
{
  "values": {
    "codebooks": {
      "v1": {
        "0": "pass",
        "1": "fail"
      },
      "v2": {
        "0": "fail",
        "1": "pass"
      }
    },
    "sent_version": "v2",
    "decoded_version": "v1",
    "tags": [
      0,
      1,
      1
    ]
  },
  "formula": "Decode each tag by its versioned codebook; compare intended versus receiver labels positionwise.",
  "expected": {
    "intended": [
      "fail",
      "pass",
      "pass"
    ],
    "received": [
      "pass",
      "fail",
      "fail"
    ],
    "mismatches": 3
  },
  "negative_control": {
    "values": {
      "codebooks": {
        "v1": {
          "0": "pass",
          "1": "fail"
        },
        "v2": {
          "0": "fail",
          "1": "pass"
        }
      },
      "sent_version": "v2",
      "decoded_version": "v2",
      "tags": [
        0,
        1,
        1
      ]
    },
    "expected": {
      "intended": [
        "fail",
        "pass",
        "pass"
      ],
      "received": [
        "fail",
        "pass",
        "pass"
      ],
      "mismatches": 0
    },
    "why": "Correct decoder version restores intended labels without changing transported tags."
  },
  "assumptions": [
    "Codebooks are exact bijections on supplied symbols.",
    "Tags arrive in order without channel errors; version identity is trusted for this case."
  ],
  "limits": "No real wire format or production protocol change; transport fidelity alone does not certify semantic agreement."
}
```

### Exercice 1

Décodez les symboles avec la version de l’expéditeur.

<details><summary>Réponse 1</summary>

Les étiquettes voulues sont `[fail,pass,pass]` sous `v2`. C’est la correspondance qui détermine le sens, sans rapport avec la taille visuelle du symbole. Attachez sa version avant de comparer les verdicts.

</details>

### Exercice 2

Décodez les mêmes symboles avec la version du destinataire et comptez les désaccords.

<details><summary>Réponse 2</summary>

Le destinataire obtient `[pass,fail,fail]` sous `v1`. Il y a `3` désaccords positionnels. Les symboles restent inchangés : l’intégrité des octets ne distingue pas les interprétations.

</details>

### Exercice 3

Appliquez le contrôle avec la bonne version. Qu’est-ce qui répare le désaccord ?

<details><summary>Réponse 3</summary>

Utiliser `v2` aux deux extrémités donne `[fail,pass,pass]` et `0` désaccord. Aucun symbole transmis ne change. L’accord revient par le dictionnaire partagé, sans modifier les résultats après décodage.

</details>

### Exercice 4

Une empreinte de la séquence prouve-t-elle la compatibilité sémantique ?

<details><summary>Réponse 4</summary>

Non. Des octets égaux peuvent recevoir des interprétations différentes. La compatibilité exige l’identité du dictionnaire pertinent et son association au message, sans se limiter à l’empreinte du contenu.

</details>

### Exercice 5

Comment un assistant doit-il présenter une version inconnue ?

<details><summary>Réponse 5</summary>

Conservez les symboles d’origine et marquez le décodage indéterminé. Ne choisissez pas une règle parce que le verdict paraît plausible. Toute modification réelle exige un contrat de compatibilité et des tests au-delà de cette table construite.

</details>

## Travail avec consultation des sources

Commencez par un tableau sur papier avant d’ouvrir les réponses. Recopiez les entrées et leurs unités, appliquez l’opération déclarée et conservez les résultats intermédiaires. Ce calcul direct constitue la référence manuelle pour comparer une réponse assistée ou une notation composable proposée. Une réponse plus courte ne présente aucun avantage démontré si elle perd l’identité d’une entrée, une catégorie d’échec ou le contre-exemple.

Examinez ensuite le passage précis consigné dans le dossier. Ne citez que le petit champ ou la branche nécessaire à votre explication, avec sa révision. Après avoir enregistré votre première réponse, demandez à un assistant de contester une hypothèse. Conservez la consigne, sa réponse, les corrections retenues et les suggestions rejetées. La consultation des sources et la calculatrice sont autorisées ; signalez cette aide pour ne pas présenter le résultat comme un rappel sans assistance.

Appliquez l’entrée modifiée du contrôle négatif et énoncez un résultat observable qui réfuterait votre conclusion avant de recommander un changement. Un contrôle inattendu impose de vérifier le calcul et les hypothèses avant de modifier le fonctionnement du projet. Remettez ensemble la réponse initiale, la réponse corrigée, l’historique des aides et l’incertitude restante. Le dossier prépare cinq critères, un par exercice, dont les décisions restent indéterminées. Les corrigés et vérifications de l’auteur ne remplissent pas ces décisions. Une future comparaison en dogfooding exige des tentatives réelles sur la même tâche et une référence manuelle conservée ; ce cours ne demande aucune nouvelle implémentation d’agent ou de DSL.

[Dossier fixé de l’unité](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/unit-b.json) · [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/journal.md)
