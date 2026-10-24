---
module_id: dv-013-compare-learning-curves-at-equal-evaluation-budgets
department: data-visualization
course: "Comparer les courbes d’apprentissage à budget d’évaluation égal"
level: intermediate
prerequisites: ["dv-002-denominators-and-test-populations", "phi-007-test-a-learning-gain-against-counterfactuals"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Comparer les courbes d’apprentissage à budget d’évaluation égal

> Brouillon à soumettre à une relecture humaine. Les cas fixes ci-dessous sont des modèles mathématiques rédigés après lecture des sources ; ce ne sont pas de nouvelles mesures du projet. Les avis techniques, artisanaux, linguistiques et pédagogiques restent en attente. Aucun moteur de scène, échantillon physique, GPU, exécuteur de politique ni essai avec un apprenant n’a été utilisé pour cette leçon.

## Question du projet

Un graphique d’évaluation GA assistée par IX compare le dernier point de chaque courbe. Un candidat a été évalué plus longtemps. Son score final supérieur établit-il une meilleure méthode ? Le prérequis distinguait progrès et bénéfice causal. Le problème graphique étudié ici est plus limité : budget d’évaluation inégal et arrêt sélectif. Toutes les courbes sont des listes de scores construites, sans observation d’apprenants ni entraînement de modèle.

[Prérequis: dv-002-denominators-and-test-populations](../../data-visualization/en/dv-002-denominators-and-test-populations.md); [Prérequis: phi-007-test-a-learning-gain-against-counterfactuals](../../philosophy/en/phi-007-test-a-learning-gain-against-counterfactuals.md)

## Lire le périmètre avant de calculer

Lisez le prérequis et le document du projet avant de calculer. Distinguez les affirmations tirées du code inspecté, les résultats consignés antérieurement et les conséquences des seules hypothèses ci-dessous. Un commentaire de code, un corrigé préparé et une observation exécutée n’ont pas la même valeur probante. Conservez la date d’origine ainsi que tout contrôle échoué ou non concluant dans votre résumé d’un ancien document. La référence manuelle est un petit calcul sur papier accompagné d’un tableau des emplacements dans les sources ; un agent peut aider à trouver une définition, mais son résumé doit être confronté à celle-ci. Ce cas fini ne nécessite aucun nouveau langage ni automatisme.

Définissez l’axe horizontal comme le nombre cumulé d’items évalués selon un évaluateur et une règle fixes. Comparez des points observés à budgets identiques ; n’inventez pas un point manquant et n’interpolez pas tacitement. Un score peut progresser avec le budget alors qu’une autre méthode le domine à chaque budget commun. La comparaison reste descriptive ; coûts d’évaluation et d’entraînement peuvent différer. Conservez les tentatives et valeurs manquantes : supprimer les échecs change parfois budget et progrès apparent. Le type d’évaluation GA existant motive des résultats nommés, mais ne fournit ni cette trajectoire hypothétique ni son explication causale.

## Cas fixe et hypothèses

```text
budget_items=[10,20,30]
A_score=[0.60,0.70,0.75]
B_score=[0.65,0.72,null]
shared_budget_differences_B_minus_A=[0.05,0.02]
last_observed_A=0.75; last_observed_B=0.72
shared_mean_A=(0.60+0.70)/2=0.65
shared_mean_B=(0.65+0.72)/2=0.685
control_B_score=[0.60,0.70,null]; control_shared_differences=[0,0]
```

## Exercices corrigés

### Exercice 1

Comparez les derniers scores observés. Quel décalage apparaît ?

> **Réponse:** A termine à `0.75` et B à `0.72`, mais leurs budgets sont `30` et `20` items. Les points finaux ne comparent pas un travail égal.

### Exercice 2

Comparez uniquement les budgets communs.

> **Réponse:** B dépasse A de `0.05` et `0.02`. Ce constat descriptif inverse l’impression des derniers points sans établir de causalité.

### Exercice 3

Calculez les moyennes sur la grille commune. Sont-elles des aires sous des courbes continues ?

> **Réponse:** Les moyennes sont `0.65` et `0.685`, soit un écart de `0.035`. Ce sont des moyennes de points équipondérés, pas des intégrales ni estimations de population.

### Exercice 4

Peut-on tracer à zéro le point final manquant de B ?

> **Réponse:** Non : il vaut `null`. Le contrôle à scores égaux donne `[0,0]` aux budgets communs ; l’absence seule n’implique pas l’infériorité.

### Exercice 5

Ce graphique prouve-t-il qu’un agent enseigne mieux ?

> **Réponse:** Non. Il décrit des points construits. Le bénéfice réel exige résultats observés, aides consignées, comparaison justifiée et évaluateur fixe ; rien de cela n’a été observé ici.

## Tâche assistée par les sources

Lisez l’ancien dossier contrefactuel et repérez le type d’évaluation GA dans sa source figée. Préparez une légende manuelle à budget égal en conservant les points manquants. Faites comparer les scores finaux par une aide, puis corrigez sa conclusion avec les écarts à budget commun. Un point inventé ou une supériorité à budgets différents réfute la légende.

Réalisez la tâche en masquant les corrigés. Gardez vos réponses initiales, les étapes de calcul, les emplacements dans les sources, les incertitudes et toutes les aides reçues, y compris un indice, un terme traduit ou une suggestion d’agent. Comparez ensuite avec les réponses préparées et consignez les corrections sans effacer votre premier essai. Rédigez une courte note de décision présentant l’affirmation, ses hypothèses, le calcul, le contrôle négatif et l’observation susceptible de la réfuter. Un résultat juste dépourvu d’unité ou d’identité de source ne suffit pas à démontrer le transfert. Le dossier comporte cinq critères préparés pour l’apprenant ; leur décision reste null tant qu’il n’existe pas d’essai réel et de relecture autorisée. La réussite de ces calculs établirait seulement une compétence sur le cas déclaré. Elle ne prouverait ni adaptateur opérationnel, ni procédé matériel réussi, ni moteur de rendu plus rapide, ni progrès d’apprentissage dans le projet. Comparez votre note assistée à la référence manuelle : si l’aide masque une hypothèse ou supprime un refus, corrigez la note avant de proposer un changement de méthode.

## Sources et journal de validation

- [Document du projet](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/counterfactual-gains.json)
- [Source primaire](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Business.ML/Rag/RagEvaluationModels.cs)
- [Dossier de preuves fixes](../../../../code/streeling/evidence/batch50-2026-10-23/unit-c.json)
- [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)
