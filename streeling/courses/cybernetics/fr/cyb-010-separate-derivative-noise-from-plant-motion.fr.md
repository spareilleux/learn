---
module_id: "cyb-010-separate-derivative-noise-from-plant-motion"
department: "cybernetics"
course: "Distinguer le bruit de dérivation du mouvement du système"
title: "Distinguer le bruit de dérivation du mouvement du système"
level: "intermediate"
prerequisites: ["cyb-008-check-convergence-before-repeating-a-correction"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Distinguer le bruit de dérivation du mouvement du système

> **Portée du brouillon.** Modèles fixes construits à partir de sources inspectées. Les décisions humaines techniques, linguistiques et d’apprentissage restent en attente. Aucun résultat de flotte active, contrôleur de production, télémétrie utilisateur ou progrès d’apprentissage n’est revendiqué. Le journal distingue tests réellement exécutés, lectures et contrôles prévus.

## Sources à examiner

- [cyb-008-check-convergence-before-repeating-a-correction.md](../../cybernetics/en/cyb-008-check-convergence-before-repeating-a-correction.md)
- [discretepidcontroller.html](https://www.mathworks.com/help/simulink/slref/discretepidcontroller.html)

Un agent observe une variation soudaine dans un tableau de bord et propose une forte correction. Le système bouge-t-il, ou la mesure fluctue-t-elle ? Le prérequis sur la convergence étudie des résidus exacts. Ici, la position réelle reste constante tandis qu'une perturbation déclarée entre dans l'estimation de dérivée. L'exemple vérifie unités et sensibilité ; il ne modélise pas un service GA mesuré.

La documentation primaire du contrôleur décrit une contribution dérivée et un filtre. Nos équations de différence finie et de lissage sont définies indépendamment ci-dessous ; elles ne reproduisent pas toutes les options de ce produit. Des unités de position divisées par des secondes donnent des unités de position par seconde. Un gain dérivé devrait avoir des unités compatibles avant de contribuer à une commande. Nommer un nombre correction ne fournit pas ce contrat dimensionnel.

Calculez les variations mesurées avant de les diviser par l'intervalle d'échantillonnage. Le mouvement apparent alterne alors que le système supposé ne bouge jamais. La récurrence de lissage part de la valeur initiale déclarée et conserve une partie de son état précédent. Ses sorties ne se comparent donc pas à une moyenne nouvellement initialisée. Garder l'initialisation est essentiel lorsqu'un agent reprend une analyse ou compare des traces courtes.

Diviser l'intervalle par deux en conservant les mêmes sauts de mesure double les différences finies. Cette propriété concerne l'entrée construite, pas une loi universelle du bruit des capteurs à cadence accrue. Une rampe réelle, un capteur retardé et des impulsions isolées pourraient demander d'autres analyses. Le lissage peut aussi retarder un vrai changement : réduire les fluctuations visibles ne prouve ni une meilleure commande ni une attribution correcte.

Pour le travail avec les sources, repérez la description du filtre dérivé dans la documentation primaire et comparez-la à l'équation exacte du prérequis. Calculez manuellement les traces brute et filtrée, en conservant le contrôle à entrée constante. Demandez à un assistant de distinguer mouvement réel supposé et valeurs mesurées. Rejetez son explication si elle déduit une réponse physique de cette perturbation ou présente une courbe plus calme comme preuve de stabilité.

## Cas fixe et calculs attendus

```json
{
  "values": {
    "dt_seconds": 0.1,
    "true_position": [
      10,
      10,
      10
    ],
    "measurement": [
      10,
      10.2,
      10
    ],
    "gain": 1,
    "filter_alpha": 0.5,
    "filter_initial": 0
  },
  "formula": "d[k]=(y[k]-y[k-1])/dt; z[k]=alpha*d[k]+(1-alpha)*z[k-1]",
  "expected": {
    "true_derivative": [
      0,
      0
    ],
    "raw_derivative": [
      2,
      -2
    ],
    "filtered_derivative": [
      1,
      -0.5
    ],
    "half_dt_raw": [
      4,
      -4
    ]
  },
  "negative_control": "A constant measured sequence gives zero raw and filtered derivatives.",
  "assumptions": [
    "Uniform sample intervals, fixed position units, no plant motion, stipulated perturbation, no missing samples."
  ],
  "limits": "No physical sensor, GA controller or noise distribution was measured; smoothing does not establish closed-loop stability."
}
```

## Conserver une tentative d’apprenant avec ses sources

Travaillez à partir des entrées épinglées ci-dessus. Avant de demander de l’aide, écrivez votre prédiction pour le cas fixe et son contrôle négatif, avec l’unité de chaque quantité et la frontière exacte de comparaison. Un petit tableau sur papier constitue la référence manuelle directe. Gardez les valeurs intermédiaires, surtout celles qui contredisent votre première prédiction. Cette tâche d’explication utilise des sources existantes et des données fixes ; elle ne demande ni installation, ni service payant, ni nouveau programme.

Utilisez ensuite un assistant pour retrouver le passage pertinent et critiquer votre calcul. Conservez la consigne initiale, la réponse, l’emplacement cité et les modifications acceptées ou rejetées. Une citation est utile seulement si le contenu inspecté étaye l’affirmation précise. Une étape déclarée, un type de données et un commentaire n’apportent pas les mêmes preuves qu’un résultat exécuté. Expliquez cette frontière dans votre réponse finale plutôt que d’emprunter l’autorité d’une étiquette rassurante.

Remettez ensemble référence manuelle, résultat corrigé, résultat du contrôle, critère de réfutation et historique d’aide. Les critères préparés demandent si la portée est identifiée, le calcul correct, le contre-exemple conservé, l’explication étayée et la conclusion limitée à ses preuves. Ils restent indécidés sans réponse réelle d’un apprenant. Les corrigés ci-dessous sont préparés : ils ne prouvent aucun apprentissage. L’évaluateur doit garder un critère échoué et sa cause avant la correction, puis juger séparément la tentative révisée. Les preuves d’exécution et de publication, recueillies ultérieurement, exigent leurs propres relevés liés à la version.

### Exercice 1

Calculez la dérivée brute.

<details>
<summary>Réponse 1</summary>

`[2,-2]` unités de position par seconde ; la dérivée réelle vaut `[0,0]`.

</details>

### Exercice 2

Calculez la suite filtrée.

<details>
<summary>Réponse 2</summary>

`[1,-0.5]` avec l’état initial et la récurrence déclarés.

</details>

### Exercice 3

Divisez l’intervalle d’échantillonnage par deux.

<details>
<summary>Réponse 3</summary>

Pour `dt=0.05`, les mêmes sauts donnent `[4,-4]`.

</details>

### Exercice 4

Évaluez le contrôle à entrée constante.

<details>
<summary>Réponse 4</summary>

Les deux traces restent nulles ; une sortie non nulle contredirait la récurrence ou son initialisation.

</details>

### Exercice 5

Le lissage prouve-t-il une meilleure commande ?

<details>
<summary>Réponse 5</summary>

Non. Attribution du mouvement, retard, actionneur et stabilité restent non testés.

</details>

[Dossier de preuves fixes](../../../../code/streeling/evidence/batch50-2026-10-23/unit-b.json) · [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)
