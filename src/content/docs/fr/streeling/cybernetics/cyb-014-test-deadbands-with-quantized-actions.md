---
title: Tester les bandes mortes avec des actions quantifiées
description: Tester les bandes mortes avec des actions quantifiées — Cybernétique
sidebar:
  label: CYB-014 · Tester les bandes mortes avec des actions quantifiées
  order: 14
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/cybernetics/fr/cyb-014-test-deadbands-with-quantized-actions.fr.md
---

:::note[Streeling University]
**CYB-014** · Tester les bandes mortes avec des actions quantifiées · intermédiaire · 45 minutes

Généré par le département *Cybernétique* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/cybernetics/fr/cyb-014-test-deadbands-with-quantized-actions.fr.md) · [Mon journal](../../journal/)

Prérequis: [CYB-005](../../cybernetics/cyb-005-stop-render-policy-flapping/), [CYB-011](../../cybernetics/cyb-011-prevent-integral-accumulation-under-saturation/)
:::

> Ce cours s’appuie sur un cas construit et des sources consultées. Les effectifs, durées, étiquettes et signaux sont des données pédagogiques inventées. La revue technique humaine, la relecture linguistique, les tentatives réelles, l’exécution, l’adoption en production et la publication restent à décider.

Un agent propose de corriger tout résidu non nul par une unité entière d’action. Près de la cible, l’actionneur ne peut pas réaliser le petit déplacement souhaité. Il peut franchir la cible puis revenir de l’autre côté. Le prérequis sur les oscillations utilise une hystérésis avec mémoire et des règles temporelles ; ce cours étudie une bande morte sans mémoire avec une amplitude d’action discrète. Le modèle ne contient ni série d’observations, ni horloge d’attente, ni mode précédent.

Appliquez la comparaison stricte avant chaque action. Dans la bande morte, y compris à sa frontière, gardez l’erreur courante. À l’extérieur, soustrayez un pas entier dans le sens de l’erreur. Cette correction peut dépasser la cible. Le résidu conservé est une conséquence voulue, sans constituer une convergence exacte cachée. Comparez à la fois le nombre d’actions et l’erreur restante avec une politique qui corrige toujours.

Le cas principal agit puis s’arrête à une erreur non nulle. Le contrôle resserre la bande, ce qui exige une action pour chacune des erreurs visitées. Une paire se répète sans bruit de mesure. La quantification suffit donc au cycle construit, sans expliquer toutes les oscillations réelles. Ajouter une intégrale ou un retard définirait un autre modèle exigeant une nouvelle trace.

Le dossier conservé ne contient aucune nouvelle observation de contrôleur. Son lien maintient la séparation entre raisonnement construit et rapports historiques. Un assistant peut aider à produire un tableau de transitions ou un prédicat DSL, mais une trace plus calme ne justifie pas seule un réglage produit. La référence manuelle doit préciser la tolérance qui rend le résidu acceptable et le coût des actions répétées. Ces choix dépendent de la tâche réelle et restent ouverts ici.

La branche adaptative [BRUTAL](https://raw.githubusercontent.com/GuitarAlchemist/ga/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs) épinglée change `bounces` par pas entier et comporte aussi des seuils distincts de remontée et de réduction ainsi qu’une attente minimale. Examinez ces prédicats avant de les comparer à notre règle sans mémoire. La source montre un choix quantifié ; la bande construite isole un autre mécanisme.

## Sources et périmètre du projet

Lisez le prérequis avant d’utiliser le modèle. Examinez l’artefact conservé du projet à la révision indiquée dans le dossier et repérez le champ ou la branche qui étaye l’observation. La source fournit une représentation ou un comportement déclaré ; elle ne transforme pas le cas inventé en résultat observé du projet. La lecture primaire apporte le concept nommé dans les limites annoncées.

[Prérequis: cyb-005-stop-render-policy-flapping](../../cybernetics/cyb-005-stop-render-policy-flapping/)

[Prérequis: cyb-011-prevent-integral-accumulation-under-saturation](../../cybernetics/cyb-011-prevent-integral-accumulation-under-saturation/)

[Artefact conservé du projet](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/pilot-value-2026-10-22/source-observations.json)

[Lecture primaire: W3C Recommendation 2013-04-30](https://www.w3.org/TR/2013/REC-prov-dm-20130430/)

[Lecture primaire: GA 76efbffd5af82b46c3146957a6bd4504008eeb89](https://raw.githubusercontent.com/GuitarAlchemist/ga/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs)

## Modèle fixé et contrôle

```json
{
  "values": {
    "initial_error": 0.6,
    "action_step": 1,
    "deadband": 0.5,
    "updates": 4
  },
  "formula": "If abs(x)>deadband, x_next=x-action_step*sign(x); otherwise x_next=x. Equality retains the state.",
  "expected": {
    "trace": [
      0.6,
      -0.4,
      -0.4,
      -0.4,
      -0.4
    ],
    "final_error": -0.4,
    "action_count": 1
  },
  "negative_control": {
    "values": {
      "initial_error": 0.6,
      "action_step": 1,
      "deadband": 0.3,
      "updates": 4
    },
    "expected": {
      "trace": [
        0.6,
        -0.4,
        0.6,
        -0.4,
        0.6
      ],
      "final_error": 0.6,
      "action_count": 4
    },
    "why": "A narrower deadband excludes both quantized residuals and sustains alternating action."
  },
  "assumptions": [
    "Exact decimal arithmetic and instantaneous fixed-size actions.",
    "No noise, plant lag, integral term or actuator saturation."
  ],
  "limits": "Deadband reduces action in this example at the cost of nonzero residual; no production threshold or stability guarantee follows."
}
```

### Exercice 1

Appliquez la première action et expliquez le changement de signe.

<details><summary>Réponse 1</summary>

En partant de `0.6`, soustraire le pas `1` donne `-0.4`. Le signe change parce que l’action dépasse l’erreur. Cela respecte l’actionneur quantifié déclaré et ne vient pas d’un arrondi.

</details>

### Exercice 2

Complétez la trace principale et comptez les actions.

<details><summary>Réponse 2</summary>

La trace est `[0.6,-0.4,-0.4,-0.4,-0.4]` et le nombre d’actions `1`. Dans la bande `0.5`, la règle conserve l’état. Elle ne ramène pas l’erreur restante à zéro.

</details>

### Exercice 3

Appliquez le contrôle plus étroit et expliquez l’alternance.

<details><summary>Réponse 3</summary>

Avec la bande `0.3`, la trace est `[0.6,-0.4,0.6,-0.4,0.6]` et le nombre d’actions `4`. Les deux amplitudes dépassent la bande : le pas fixe franchit donc la cible à chaque fois.

</details>

### Exercice 4

La bande morte possède-t-elle la même mémoire que l’hystérésis du prérequis ?

<details><summary>Réponse 4</summary>

Non. La décision dépend seulement de l’amplitude présente et du seuil fixe. Elle ne contient ni mode conservé, ni compteur de persistance, ni délai minimal. Les confondre changerait le contrat de transition.

</details>

### Exercice 5

Qu’est-ce qui rendrait la trace principale utile à un projet réel ?

<details><summary>Réponse 5</summary>

Il faut une erreur admissible, un coût d’action, un comportement mesuré de l’actionneur et une tâche de comparaison conservée. Rejetez une recommandation qui parle de convergence exacte ou adopte cette bande sans preuve du projet.

</details>

## Travail avec consultation des sources

Commencez par un tableau sur papier avant d’ouvrir les réponses. Recopiez les entrées et leurs unités, appliquez l’opération déclarée et conservez les résultats intermédiaires. Ce calcul direct constitue la référence manuelle pour comparer une réponse assistée ou une notation composable proposée. Une réponse plus courte ne présente aucun avantage démontré si elle perd l’identité d’une entrée, une catégorie d’échec ou le contre-exemple.

Examinez ensuite le passage précis consigné dans le dossier. Ne citez que le petit champ ou la branche nécessaire à votre explication, avec sa révision. Après avoir enregistré votre première réponse, demandez à un assistant de contester une hypothèse. Conservez la consigne, sa réponse, les corrections retenues et les suggestions rejetées. La consultation des sources et la calculatrice sont autorisées ; signalez cette aide pour ne pas présenter le résultat comme un rappel sans assistance.

Appliquez l’entrée modifiée du contrôle négatif et énoncez un résultat observable qui réfuterait votre conclusion avant de recommander un changement. Un contrôle inattendu impose de vérifier le calcul et les hypothèses avant de modifier le fonctionnement du projet. Remettez ensemble la réponse initiale, la réponse corrigée, l’historique des aides et l’incertitude restante. Le dossier prépare cinq critères, un par exercice, dont les décisions restent indéterminées. Les corrigés et vérifications de l’auteur ne remplissent pas ces décisions. Une future comparaison en dogfooding exige des tentatives réelles sur la même tâche et une référence manuelle conservée ; ce cours ne demande aucune nouvelle implémentation d’agent ou de DSL.

[Dossier fixé de l’unité](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/unit-b.json) · [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/journal.md)
