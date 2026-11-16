---
module_id: aud-021-bound-feedback-delay-repeats
department: audio-engineering
course: "Borner les répétitions d’un retard avec rétroaction"
level: advanced
prerequisites: ["aud-007-translate-attack-coefficients-into-time"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Borner les répétitions d’un retard avec rétroaction

> Modèle construit et lecture délimitée de sources. Les avis techniques humains, linguistiques, musicaux et pédagogiques restent en attente. Aucun nouveau jeu, résultat d’écoute, rendu du moteur, analyse exécutée ou usage en production n’est revendiqué.

Une proposition audio réutilise un coefficient de décroissance dans un retard avec rétroaction et le juge sûr parce que la sortie initiale est faible. Ce coefficient agit maintenant à chaque retour dans le retard, pas nécessairement à chaque échantillon. Dérivez la réponse à une impulsion avant de comparer des durées ou d’annoncer une stabilité. Le script de guitare motive la conservation de l’état, sans exécuter cette nouvelle récurrence isolée.

Seuls les multiples successifs du retard portent les échos de l’impulsion. Leurs amplitudes forment une suite géométrique. Le retard fixe leur espacement et le gain leur rapport ; les modifier n’a donc pas le même effet. La liste finie montre les premiers retours. La formule de somme absolue concerne toute la queue infinie sous nos hypothèses, ce qui exige une borne stricte sur le gain.

Le témoin croissant peut respecter temporairement un contrôle de plage si l’entrée est assez faible. Sa réponse infinie ne devient pas pour autant sommable. Inversement, un système stable peut dépasser la plage d’exportation pour certaines entrées. Séparez stabilité mathématique, écrêtage et décroissance musicale. Initialisation, unités de l’horloge et traitement des nombres restent à vérifier dans une implémentation. Conservez la convention de signe avec la récurrence lorsque la source présente une notation de dénominateur différente.

## Lire les éléments du projet conservés

Le prérequis fournit l’opération antérieure et sa limite de preuve. Examinez l’artefact lié avant de proposer un changement à partir du cas construit. Les observations conservées gardent leur portée initiale : un fichier ou une donnée d’exemple ne prouve pas un déploiement actuel. Le dossier fixe conserve entrées, résultats préparés et provenance des lectures. Les empreintes locales identifient les octets complets sans élargir le passage réellement lu. Une page primaire étaye seulement la définition consultée, sans révision immuable ni empreinte inventée.

[Prérequis](../../audio-engineering/en/aud-007-translate-attack-coefficients-into-time.md)

[Artefact du projet conservé](../../../../code/streeling/guitar-runtime/run.mjs)

[Dossier des cas construits](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-a.json)

[Lecture primaire](https://www.dsprelated.com/freebooks/pasp/Feedback_Comb_Filters.html)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "delay_samples": 2,
    "gain": 0.5,
    "count": 7,
    "impulse": [
      1,
      0,
      0,
      0,
      0,
      0,
      0
    ]
  },
  "formula": "y[n]=x[n]+g*y[n-M]; y[n<0]=0; stable=abs(g)<1; absolute_sum_infinite=1/(1-abs(g)) if stable else null",
  "expected": {
    "output": [
      1,
      0,
      0.5,
      0,
      0.25,
      0,
      0.125
    ],
    "stable": true,
    "absolute_sum_infinite": 2
  },
  "negative_control": {
    "values": {
      "delay_samples": 2,
      "gain": 1.1,
      "count": 7,
      "impulse": [
        1,
        0,
        0,
        0,
        0,
        0,
        0
      ]
    },
    "expected": {
      "output": [
        1,
        0,
        1.1,
        0,
        1.21,
        0,
        1.331
      ],
      "stable": false,
      "absolute_sum_infinite": null
    }
  }
}
```

## Hypothèses et limites des preuves

Supposez un état initial nul, un retard entier positif et un gain réel constant. Aucun limiteur ne modifie la récurrence. La queue infinie mathématique se distingue de la robustesse numérique et de la plage d’exportation.

## Interpréter l’opération avant de choisir une abstraction

Avant de révéler le corrigé, reformulez le contrat d’entrée et dérivez le résultat principal à la main. Conservez les grandeurs intermédiaires ou transitions d’état plutôt que le seul résultat final. Appliquez la même règle au témoin et repérez l’entrée modifiée. Le modèle est un exemple construit fini. Un calcul concordant étaye son affirmation précise ; il ne fournit ni observation d’utilisateur ni validation d’une fonctionnalité en production.

### Exercice 1

Suivez les premiers retours et les échantillons intermédiaires.

<details><summary>Réponse 1</summary>

Les retours non nuls sont espacés du retard déclaré ; les autres échantillons restent nuls avec cet état initial.

</details>

### Exercice 2

Quelle entrée fixe l’espacement et laquelle fixe le rapport d’amplitude ?

<details><summary>Réponse 2</summary>

Le retard commande l’espacement. Le gain constant commande le rapport entre retours successifs.

</details>

### Exercice 3

Pourquoi le cas stable est-il absolument sommable ?

<details><summary>Réponse 3</summary>

La valeur absolue du gain est strictement inférieure à l’unité ; les amplitudes donnent la somme géométrique convergente affichée.

</details>

### Exercice 4

Un rendu bref certifie-t-il le témoin croissant ?

<details><summary>Réponse 4</summary>

Non. Son préfixe est fini, mais les retours croissent et leur somme absolue infinie ne converge pas.

</details>

### Exercice 5

Quel résultat réfute la récurrence annoncée stable ?

<details><summary>Réponse 5</summary>

Un gain hors de la borne stricte, ou une trace incompatible avec la récurrence, rejette cette affirmation dans le modèle.

</details>

## Travail avec consultation des sources

Préparez la table d’impulsion et séparez la borne de queue d’un futur contrôle PCM. Ce cas construit seul ne justifie pas une modification du moteur.

Conservez votre réponse sans aide avant de consulter source ou calculatrice. Repérez ensuite un passage précis et sa révision, notez toutes les aides et gardez la réponse initiale avec sa correction éventuelle. Un flux d’agent ou un DSL proposé doit conserver le résultat manuel et son contre-cas avant que son intérêt puisse être évalué. Si une entrée manque, laissez la décision non résolue au lieu d’inventer une valeur plausible.

Formulez un critère de réfutation observable face à la règle, puis précisez l’observation nécessaire à l’étape suivante. Les réponses sont des contrôles préparés, pas la trace de votre tentative. Le dossier contient un critère distinct par exercice ; toutes les décisions d’apprenant restent indécises jusqu’à conservation d’une réponse réelle et de sa revue. Joignez aides, corrections et limites à la note finale pour ne pas confondre calcul juste, rappel autonome, avis musical et validation d’exécution.
