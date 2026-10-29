---
title: Tester le retard de retour avant de réutiliser un gain
description: Tester le retard de retour avant de réutiliser un gain — Cybernétique
sidebar:
  label: CYB-012 · Tester le retard de retour avant de réutiliser un gain
  order: 12
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/cybernetics/fr/cyb-012-test-feedback-delay-before-reusing-a-gain.fr.md
---

:::note[Streeling University]
**CYB-012** · Tester le retard de retour avant de réutiliser un gain · intermédiaire · 45 minutes

Généré par le département *Cybernétique* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/cybernetics/fr/cyb-012-test-feedback-delay-before-reusing-a-gain.fr.md) · [Mon journal](../../journal/)

Prérequis: [CYB-008](../../cybernetics/cyb-008-check-convergence-before-repeating-a-correction/)
:::

> Ce cours s’appuie sur un cas construit et des sources consultées. Les effectifs, durées, étiquettes et signaux sont des données pédagogiques inventées. La revue technique humaine, la relecture linguistique, les tentatives réelles, l’exécution, l’adoption en production et la publication restent à décider.

Un agent voit un résidu diminuer après une correction et propose de réutiliser un gain choisi pour un retour immédiat. L’observation suivante peut encore décrire l’état antérieur à cette correction. Le prérequis emploie le résidu courant dans la mise à jour. Ici, le résidu arrive avec un retard d’une mise à jour ; prédire la suite exige donc la valeur précédente autant que la valeur courante.

Gardez l’initialisation explicite. Les deux erreurs initiales sont supposées égales et la séquence commence par la valeur courante. Appliquer le gain à la valeur précédente crée un dépassement, même lorsque le retour immédiat conduirait vers zéro sans changement de signe. Un changement de signe ne suffit donc pas à signaler une erreur de calcul. Il faut reproduire la récurrence avant de juger la trace.

CYB008 introduit déjà un résidu retardé et un contre-exemple instable fondé sur les racines. La nouvelle tâche est de dériver tout l’intervalle scalaire du gain. Écrivons g pour le gain dans r^2-r+g=0. Pour 0<g<=1/4, les racines (1+/-sqrt(1-4*g))/2 sont strictement entre 0 et 1 ; à g=1/4, la racine double vaut 1/2 et son éventuel facteur k*(1/2)^k tend encore vers zéro. Pour 1/4<g<1, les racines conjuguées ont pour module sqrt(g)<1. À g=0, une racine unité empêche la stabilité asymptotique ; pour g<0, une racine réelle dépasse 1 ; pour g>=1, le module conjugué vaut au moins 1. La stabilité asymptotique pour toute paire initiale finie équivaut donc exactement à 0<gain<1. Les six mises à jour illustrent deux points de cet intervalle dérivé analytiquement ; leur nombre fini ne le démontre pas.

Le polynôme caractéristique s’obtient en substituant une suite géométrique dans la récurrence retardée. Pour le gain principal, ses racines conjuguées ont un module inférieur à l’unité : ce modèle linéaire exact converge. Pour le gain modifié, elles se trouvent sur le cercle unité et la trace se répète. Les valeurs finies illustrent la différence ; la condition sur les racines fournit l’argument asymptotique sous les hypothèses déclarées.

Le fichier d’observations conservé rappelle qu’une relecture ne constitue pas un nouvel essai et que les rapports historiques ne calibrent pas un contrôleur inventé. C’est la frontière utile au projet : un agent doit identifier la mise à jour décrite par une observation avant de la traiter comme preuve corrective fraîche. Une fiche d’étape composable pourrait garder cette association, mais son utilité reste une hypothèse. Comparez d’abord les équations à la main, sans introduire de contrôleur ni déduire un délai réel.

Dans le bloc de requête [BRUTAL](https://raw.githubusercontent.com/GuitarAlchemist/ga/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs) épinglé, les résultats de mesure terminés alimentent une valeur lissée conservée avant la décision sur les rebonds. C’est une frontière réelle où identité et moment de l’observation comptent. La récurrence ci-dessous diffère volontairement de ce contrôleur ; ses racines ne certifient pas le rendu.

## Sources et périmètre du projet

Lisez le prérequis avant d’utiliser le modèle. Examinez l’artefact conservé du projet à la révision indiquée dans le dossier et repérez le champ ou la branche qui étaye l’observation. La source fournit une représentation ou un comportement déclaré ; elle ne transforme pas le cas inventé en résultat observé du projet. La lecture primaire apporte le concept nommé dans les limites annoncées.

[Prérequis: cyb-008-check-convergence-before-repeating-a-correction](../../cybernetics/cyb-008-check-convergence-before-repeating-a-correction/)

[Artefact conservé du projet](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/pilot-value-2026-10-22/source-observations.json)

[Lecture primaire: W3C Recommendation 2013-04-30](https://www.w3.org/TR/2013/REC-prov-dm-20130430/)

[Lecture primaire: GA 76efbffd5af82b46c3146957a6bd4504008eeb89](https://raw.githubusercontent.com/GuitarAlchemist/ga/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs)

## Modèle fixé et contrôle

```json
{
  "values": {
    "gain": 0.5,
    "initial_previous": 1,
    "initial_current": 1,
    "steps": 6,
    "delay_updates": 1
  },
  "formula": "x[k+1]=x[k]-gain*x[k-1], initialized x[-1]=x[0]=1; roots solve r^2-r+gain=0.",
  "expected": {
    "trace_from_k0": [
      1,
      0.5,
      0,
      -0.25,
      -0.25,
      -0.125,
      0
    ],
    "root_modulus": 0.7071067811865476,
    "asymptotically_stable": true
  },
  "negative_control": {
    "values": {
      "gain": 1,
      "initial_previous": 1,
      "initial_current": 1,
      "steps": 6,
      "delay_updates": 1
    },
    "expected": {
      "trace_from_k0": [
        1,
        0,
        -1,
        -1,
        0,
        1,
        1
      ],
      "root_modulus": 1,
      "asymptotically_stable": false
    },
    "why": "Gain that zeros an immediate-feedback scalar error gives a nondecaying delayed cycle."
  },
  "assumptions": [
    "Exact linear scalar recurrence, fixed gain, one-update delay and no saturation or noise.",
    "Update index is dimensionless; no seconds or worker latency are inferred."
  ],
  "limits": "Root argument concerns this recurrence only; finite trace does not establish real fleet stability."
}
```

### Exercice 1

Calculez les premières nouvelles valeurs de la récurrence retardée.

<details><summary>Réponse 1</summary>

Elles valent `0.5`, `0` et `-0.25`. Chaque correction utilise l’erreur précédente, y compris l’initialisation déclarée. Employer la valeur courante juste calculée supprimerait silencieusement le retard.

</details>

### Exercice 2

Expliquez le polynôme caractéristique et le module des racines du cas principal.

<details><summary>Réponse 2</summary>

La substitution géométrique donne `r^2-r+0.5=0`. Les racines conjuguées ont pour module `sqrt(0.5)=0.7071067811865476`, inférieur à l’unité. Cela soutient la convergence asymptotique de cette seule récurrence linéaire fixe.

</details>

### Exercice 3

Appliquez le gain du contrôle et conservez toute la trace déclarée.

<details><summary>Réponse 3</summary>

La trace est `[1,0,-1,-1,0,1,1]`. Le module vaut `1`, donc la convergence pour toute erreur initiale échoue. Le retour à la paire initiale révèle un cycle persistant plutôt qu’un progrès.

</details>

### Exercice 4

Le gain du contrôle échouerait-il aussi avec un retour immédiat ?

<details><summary>Réponse 4</summary>

Non. Pour `x[k+1]=(1-gain)*x[k]` et `gain=1`, l’erreur suivante est nulle. La conclusion sur le gain dépend du moment de l’observation ; le retard change la transition étudiée.

</details>

### Exercice 5

Quelles preuves réelles faut-il avant d’appliquer ce cours à une boucle d’agent ?

<details><summary>Réponse 5</summary>

Conservez l’identité des actions et des observations, leur association causale, le retard mesuré et la règle réelle. La lecture des sources et une trace construite par indice ne mesurent pas la latence des workers et ne prouvent pas la stabilité en production.

</details>

## Travail avec consultation des sources

Commencez par un tableau sur papier avant d’ouvrir les réponses. Recopiez les entrées et leurs unités, appliquez l’opération déclarée et conservez les résultats intermédiaires. Ce calcul direct constitue la référence manuelle pour comparer une réponse assistée ou une notation composable proposée. Une réponse plus courte ne présente aucun avantage démontré si elle perd l’identité d’une entrée, une catégorie d’échec ou le contre-exemple.

Examinez ensuite le passage précis consigné dans le dossier. Ne citez que le petit champ ou la branche nécessaire à votre explication, avec sa révision. Après avoir enregistré votre première réponse, demandez à un assistant de contester une hypothèse. Conservez la consigne, sa réponse, les corrections retenues et les suggestions rejetées. La consultation des sources et la calculatrice sont autorisées ; signalez cette aide pour ne pas présenter le résultat comme un rappel sans assistance.

Appliquez l’entrée modifiée du contrôle négatif et énoncez un résultat observable qui réfuterait votre conclusion avant de recommander un changement. Un contrôle inattendu impose de vérifier le calcul et les hypothèses avant de modifier le fonctionnement du projet. Remettez ensemble la réponse initiale, la réponse corrigée, l’historique des aides et l’incertitude restante. Le dossier prépare cinq critères, un par exercice, dont les décisions restent indéterminées. Les corrigés et vérifications de l’auteur ne remplissent pas ces décisions. Une future comparaison en dogfooding exige des tentatives réelles sur la même tâche et une référence manuelle conservée ; ce cours ne demande aucune nouvelle implémentation d’agent ou de DSL.

[Dossier fixé de l’unité](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/unit-b.json) · [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/journal.md)
