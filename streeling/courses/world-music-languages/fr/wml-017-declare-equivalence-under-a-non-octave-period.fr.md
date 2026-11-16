---
module_id: wml-017-declare-equivalence-under-a-non-octave-period
department: world-music-languages
course: "Déclarer l’équivalence selon une période autre que l’octave"
level: advanced
prerequisites: ["wml-014-quantize-a-ratio-on-a-declared-octave-division"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Déclarer l’équivalence selon une période autre que l’octave

> Modèle construit et lecture délimitée de sources. Les avis techniques humains, linguistiques, musicaux et pédagogiques restent en attente. Aucun nouveau jeu, résultat d’écoute, rendu du moteur, analyse exécutée ou usage en production n’est revendiqué.

Une proposition de transfert suppose que toute répétition est une octave et réduit les fréquences en conséquence. C’est un choix de représentation, pas une conséquence d’un champ générique de période. Nous comparons l’équivalence exacte selon une période construite avec celle de l’octave. La relation de regroupement change, alors que le prérequis gardait l’octave et modifiait sa subdivision.

Ramenez chaque rapport positif dans l’intervalle semi-ouvert allant de l’unité à la période exclue. Gardez séparément le nombre entier de périodes retirées comme coordonnée de registre. Des rapports normalisés égaux ne sont équivalents que pour cette période. La frontière choisie évite de doubler le sommet d’un registre et le bas du suivant. Les fractions exactes rendent les identités vérifiables sans tolérance en cents.

Le témoin reprend les mêmes rapports avec une autre période. Certaines équivalences disparaissent et une nouvelle paire apparaît. Un relevé limité aux classes d’octave ne reconstruit pas les deux règles sans conserver la période. C’est un exercice mathématique, sans attribution à une tradition nommée. Le dossier conservé distingue déjà rapports exacts et projection entière. Conservez aussi période et compte de registre avant de proposer un DSL. Aucun son, jugement d’écoute ou transfert de catalogue n’a été exécuté ; la normalisation manuelle ne fournit que les classes déclarées.

## Lire les éléments du projet conservés

Le prérequis fournit l’opération antérieure et sa limite de preuve. Examinez l’artefact lié avant de proposer un changement à partir du cas construit. Les observations conservées gardent leur portée initiale : un fichier ou une donnée d’exemple ne prouve pas un déploiement actuel. Le dossier fixe conserve entrées, résultats préparés et provenance des lectures. Les empreintes locales identifient les octets complets sans élargir le passage réellement lu. Une page primaire étaye seulement la définition consultée, sans révision immuable ni empreinte inventée.

[Prérequis](../../world-music-languages/en/wml-014-quantize-a-ratio-on-a-declared-octave-division.md)

[Artefact du projet conservé](../../../../code/streeling/evidence/intonation-listening-2026-10-22/intonation.json)

[Dossier des cas construits](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-a.json)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "ratios": [
      "1",
      "3",
      "9",
      "2"
    ],
    "period_ratio": "3"
  },
  "formula": "choose integer k with 1<=r/P^k<P; canonical=r/P^k; equivalence groups share exact canonical ratio; retain k separately",
  "expected": {
    "period_counts": [
      0,
      1,
      2,
      0
    ],
    "canonical_ratios": [
      "1",
      "1",
      "1",
      "2"
    ],
    "equivalence_groups": [
      [
        0,
        1,
        2
      ],
      [
        3
      ]
    ]
  },
  "negative_control": {
    "values": {
      "ratios": [
        "1",
        "3",
        "9",
        "2"
      ],
      "period_ratio": "2"
    },
    "expected": {
      "period_counts": [
        0,
        1,
        3,
        1
      ],
      "canonical_ratios": [
        "1",
        "3/2",
        "9/8",
        "1"
      ],
      "equivalence_groups": [
        [
          0,
          3
        ],
        [
          1
        ],
        [
          2
        ]
      ]
    }
  }
}
```

## Hypothèses et limites des preuves

Supposez des rapports rationnels positifs exacts et une période rationnelle supérieure à l’unité. Utilisez l’intervalle canonique semi-ouvert. L’équivalence est une relation choisie, pas une identité culturelle ni une preuve perceptive.

## Interpréter l’opération avant de choisir une abstraction

Avant de révéler le corrigé, reformulez le contrat d’entrée et dérivez le résultat principal à la main. Conservez les grandeurs intermédiaires ou transitions d’état plutôt que le seul résultat final. Appliquez la même règle au témoin et repérez l’entrée modifiée. Le modèle est un exemple construit fini. Un calcul concordant étaye son affirmation précise ; il ne fournit ni observation d’utilisateur ni validation d’une fonctionnalité en production.

### Exercice 1

Normalisez les rapports et gardez les comptes de périodes.

<details><summary>Réponse 1</summary>

Divisez exactement par la période ; les valeurs affichées sont dans l’intervalle fondamental semi-ouvert.

</details>

### Exercice 2

Quels rapports appartiennent au même groupe principal ?

<details><summary>Réponse 2</summary>

Ceux de même rapport canonique exact, même si les comptes de périodes diffèrent.

</details>

### Exercice 3

Pourquoi garder le compte de périodes ?

<details><summary>Réponse 3</summary>

Il distingue les registres identifiés par normalisation et permet de reconstruire le rapport initial.

</details>

### Exercice 4

Que change le témoin à période d’octave ?

<details><summary>Réponse 4</summary>

Rapports canoniques et groupes changent puisque la relation elle-même change.

</details>

### Exercice 5

Qu’est-ce qui réfute un transfert sans période ?

<details><summary>Réponse 5</summary>

Un relevé incapable de distinguer ces relations ne conserve pas le sens de période demandé.

</details>

## Travail avec consultation des sources

Construisez les tables à la main. Proposez un transfert GA conservant période exacte, rapport canonique et registre sans attribution culturelle.

Conservez votre réponse sans aide avant de consulter source ou calculatrice. Repérez ensuite un passage précis et sa révision, notez toutes les aides et gardez la réponse initiale avec sa correction éventuelle. Un flux d’agent ou un DSL proposé doit conserver le résultat manuel et son contre-cas avant que son intérêt puisse être évalué. Si une entrée manque, laissez la décision non résolue au lieu d’inventer une valeur plausible.

Formulez un critère de réfutation observable face à la règle, puis précisez l’observation nécessaire à l’étape suivante. Les réponses sont des contrôles préparés, pas la trace de votre tentative. Le dossier contient un critère distinct par exercice ; toutes les décisions d’apprenant restent indécises jusqu’à conservation d’une réponse réelle et de sa revue. Joignez aides, corrections et limites à la note finale pour ne pas confondre calcul juste, rappel autonome, avis musical et validation d’exécution.
