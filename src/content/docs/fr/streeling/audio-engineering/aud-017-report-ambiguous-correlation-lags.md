---
title: Signaler les retards de corrélation ambigus
description: Signaler les retards de corrélation ambigus — Ingénierie audio
sidebar:
  label: AUD-017 · Signaler les retards de corrélation ambigus
  order: 17
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/audio-engineering/fr/aud-017-report-ambiguous-correlation-lags.fr.md
---

:::note[Streeling University]
**AUD-017** · Signaler les retards de corrélation ambigus · avancé · 60 minutes

Généré par le département *Ingénierie audio* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/audio-engineering/fr/aud-017-report-ambiguous-correlation-lags.fr.md) · [Mon journal](../../journal/)

Prérequis: [AUD-009](../../audio-engineering/aud-009-declare-alignment-before-a-null-test/)
:::

> Modèle construit et lecture de sources. Les avis techniques humains, linguistiques, musicaux et pédagogiques restent en attente. Aucun nouveau jeu, essai d’écoute, analyse exécutée, rendu du moteur ou usage en production n’est revendiqué.

Un algorithme peut annoncer un décalage précis en échantillons alors que plusieurs réponses optimisent également son critère. Les signaux périodiques de guitare rendent ce risque concret. Avant de compenser une comparaison [GA](https://github.com/GuitarAlchemist/ga), distinguez le critère signé de sa valeur absolue et conservez les ex æquo. Le retard choisi dépend d’une convention ; ce n’est pas un horodatage de la source.

## Lire les éléments conservés

La référence officielle définit une corrélation linéaire avec prolongement par zéro. Notre somme circulaire est donc explicitée séparément. Le script conservé compare les valeurs sans estimer de retard ; le calcul proposé ajoute une opération de revue distincte.

[Prérequis](../../audio-engineering/aud-009-declare-alignment-before-a-null-test/)

[Artefact du projet conservé](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/run.mjs)

[Dossier des cas construits](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/unit-a.json)

[Lecture principale](https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.correlate.html)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "x": [
      1,
      0,
      -1,
      0
    ],
    "y": [
      0,
      1,
      0,
      -1
    ],
    "lags": [
      0,
      1,
      2,
      3
    ]
  },
  "formula": "C(k)=sum_n x[n]*y[(n+k)%N]; signed_argmax=argmax(C); absolute_argmax=argmax(abs(C))",
  "expected": {
    "correlation": [
      0,
      2,
      0,
      -2
    ],
    "signed_argmax": [
      1
    ],
    "absolute_argmax": [
      1,
      3
    ]
  },
  "negative_control": {
    "values": {
      "x": [
        1,
        0,
        0,
        0
      ],
      "y": [
        0,
        1,
        0,
        0
      ],
      "lags": [
        0,
        1,
        2,
        3
      ]
    },
    "expected": {
      "correlation": [
        0,
        1,
        0,
        0
      ],
      "signed_argmax": [
        1
      ],
      "absolute_argmax": [
        1
      ]
    }
  }
}
```

## Distinguer le choix d’estimation de la preuve d’unicité

La corrélation circulaire rend voisins le dernier échantillon et le premier. Cette hypothèse convient à la construction périodique, mais peut produire une fausse correspondance à la coupure d’un enregistrement ordinaire. La corrélation linéaire choisit d’autres limites. Le nom d’une fonction ne suffit pas à déduire la convention. Conservez l’équation et précisez si le signal a été construit périodique ou seulement découpé dans une prise plus longue.

Maximiser la valeur absolue donne aussi la même importance à une inversion de polarité. Cela peut convenir si la polarité est un facteur secondaire déclaré, mais change la question d’une comparaison exigeant des échantillons inchangés. Une crête négative ne devient pas une preuve positive parce que sa magnitude est élevée. Le relevé doit distinguer le critère qui choisit le retard des transformations appliquées ensuite.

Une règle de départage rend la sortie reproductible sans établir l’identifiabilité. Choisir le premier retard fournit toujours une réponse, même quand les données ne permettent pas de trancher. Le vecteur manuel constitue la référence minimale et expose les candidats. Avant d’automatiser sur des prises réelles, déclarez plage de retards, limites, critère et départage. Un déclenchement enregistré ou un repère d’attaque indépendant pourrait apporter la preuve temporelle manquante ; le signal périodique seul ne le peut pas.

### Exercice 1

Évaluez la somme circulaire pour chaque retard déclaré. Pourquoi préciser la convention ?

<details><summary>Réponse 1</summary>

Le vecteur de corrélation figure ci-dessus. Le bouclage des indices diffère du prolongement par zéro ; inverser le signe du retard en changerait aussi le sens.

</details>

### Exercice 2

Trouvez tous les maxima du critère signé. Quelle information le signe conserve-t-il ?

<details><summary>Réponse 2</summary>

Le maximum signé sélectionne la correspondance positive. Le signe distingue cette correspondance d’une forme d’onde de polarité inversée dans le produit déclaré.

</details>

### Exercice 3

Maximisez maintenant la valeur absolue. Peut-on annoncer un retard identifié de façon unique ?

<details><summary>Réponse 3</summary>

Le critère absolu admet la paire de maxima indiquée. Renvoyer systématiquement le premier rend le choix déterministe, mais ne lève pas l’ambiguïté des données.

</details>

### Exercice 4

Appliquez le témoin impulsionnel. En quoi aide-t-il le diagnostic ?

<details><summary>Réponse 4</summary>

Les critères ont le même maximum unique. Une méthode qui trouve encore un ex æquo traite mal ce témoin ; cette unicité ne se généralise pas au signal périodique.

</details>

### Exercice 5

Quel résultat réfuterait un relevé annonçant un maximum absolu unique ?

<details><summary>Réponse 5</summary>

Un autre retard ayant la même valeur du critère réfute l’unicité. Conservez le critère complet, l’intervalle de recherche et la règle de polarité avant toute compensation.

</details>

## Travail avec consultation des sources

Calculez les vecteurs à la main et préparez un relevé de retard pour une comparaison GA envisagée. Gardez les ex æquo et précisez si l’inversion de polarité est autorisée. Comparez ce relevé à la comparaison directe sans alignement ; la latence réelle et la fidélité audio restent indéterminées.

Conservez d’abord votre raisonnement sans aide, avant de révéler les réponses. Examinez ensuite un passage précis avec sa révision, consignez chaque aide reçue et gardez séparément la réponse initiale et sa correction. Votre résultat manuel sert de référence pour toute calculatrice, proposition de DSL ou intervention d’agent. Une donnée manquante reste non résolue. Le dossier contient un critère préparé par exercice, sans décision d’apprenant. Une réponse correcte ne justifie que le cas déclaré ; l’acceptation exige une tentative réelle et sa revue. Formulez un critère de réfutation avant toute abstraction, puis indiquez les preuves humaines ou d’exécution nécessaires à la prochaine étape.
