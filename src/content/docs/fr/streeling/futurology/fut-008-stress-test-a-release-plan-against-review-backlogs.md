---
title: Éprouver un plan de publication face à l’accumulation des relectures
description: Éprouver un plan de publication face à l’accumulation des relectures — Futurologie
sidebar:
  label: FUT-008 · Éprouver un plan de publication face à l’accumulation des relectures
  order: 8
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/futurology/fr/fut-008-stress-test-a-release-plan-against-review-backlogs.fr.md
---

:::note[Streeling University]
**FUT-008** · Éprouver un plan de publication face à l’accumulation des relectures · intermédiaire · 40 minutes

Généré par le département *Futurologie* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/futurology/fr/fut-008-stress-test-a-release-plan-against-review-backlogs.fr.md) · [Mon journal](../../journal/)

Prérequis: [FUT-003](../../futurology/fut-003-agent-substitution-readiness-drill/), [DV-008](../../data-visualization/dv-008-streeling-evidence-stage-map/)
:::

> Brouillon à soumettre à une relecture humaine. Les cas fixes ci-dessous sont des modèles mathématiques rédigés après lecture des sources ; ce ne sont pas de nouvelles mesures du projet. Les avis techniques, artisanaux, linguistiques et pédagogiques restent en attente. Aucun moteur de scène, échantillon physique, GPU, exécuteur de politique ni essai avec un apprenant n’a été utilisé pour cette leçon.

## Question du projet

Un plan Streeling augmente la rédaction tandis que la file de relecture s’allonge. L’horizon de publication s’améliorera-t-il ? Le prérequis montrait que rédiger plus vite n’augmente pas forcément les sorties acceptées. Ici, nous calculons l’arriéré par semaines explicites et éprouvons les hypothèses d’arrivées et de service. C’est un scénario fini, pas une prévision d’effectifs ni une observation des relecteurs actuels.

[Prérequis: fut-003-agent-substitution-readiness-drill](../../futurology/fut-003-agent-substitution-readiness-drill/); [Prérequis: dv-008-streeling-evidence-stage-map](../../data-visualization/dv-008-streeling-evidence-stage-map/)

## Lire le périmètre avant de calculer

Lisez le prérequis et le document du projet avant de calculer. Distinguez les affirmations tirées du code inspecté, les résultats consignés antérieurement et les conséquences des seules hypothèses ci-dessous. Un commentaire de code, un corrigé préparé et une observation exécutée n’ont pas la même valeur probante. Conservez la date d’origine ainsi que tout contrôle échoué ou non concluant dans votre résumé d’un ancien document. La référence manuelle est un petit calcul sur papier accompagné d’un tableau des emplacements dans les sources ; un agent peut aider à trouver une définition, mais son résumé doit être confronté à celle-ci. Ce cas fini ne nécessite aucun nouveau langage ni automatisme.

Supposons que les arrivées précèdent le service chaque semaine, que chaque élément relu quitte cette file et que le service ne dépasse jamais le travail disponible. La récurrence s’arrête à zéro au lieu de produire une file négative. Une sortie signifie seulement un travail de relecture terminé ; approbation, lecture publique et apprentissage restent distincts. Service constant et absence de reprise sont de fortes simplifications. Une boucle de corrections réelle peut créer des arrivées, qui doivent être comptées au lieu d’être gratuites par défaut. Comparez croissance et contrôle de vidage avec la même file initiale. Aucun scénario n’est une probabilité de disponibilité.

## Cas fixe et hypothèses

```text
B0=12 items; arrivals=8 items/week; capacity=6 items/week
B_next=max(0,B+arrivals-capacity)
B_weeks=[12,14,16,18]
departures_per_week=[6,6,6]; total_departures=18
control_arrivals=3; control_B_weeks=[12,9,6,3,0]
zero_arrival_capacity=6; zero_arrival_drain_weeks=2
```

## Exercices corrigés

### Exercice 1

Calculez la file hebdomadaire du scénario de croissance.

> **Réponse:** À partir de `12`, les valeurs de fin de semaine sont `14`, `16`, `18`. La file croît de `2` éléments par semaine.

### Exercice 2

Quel travail de relecture sort pendant l’horizon modélisé ?

> **Réponse:** On compte `18` sorties en `3` semaines. Une file croissante peut coexister avec du travail réellement terminé ; les sorties ne sont pas automatiquement des approbations.

### Exercice 3

Calculez le contrôle de vidage.

> **Réponse:** Avec `3` arrivées par semaine, la file est `[12,9,6,3,0]`. Elle atteint zéro après `4` semaines selon l’ordre arrivées-service déclaré.

### Exercice 4

Arrêtez complètement les arrivées. Quel est l’horizon de vidage ?

> **Réponse:** Il est de `2` semaines à capacité `6`. Cet horizon suppose absence de corrections et disponibilité, sans promettre de date réelle.

### Exercice 5

Rédiger plus vite répare-t-il la file croissante ?

> **Réponse:** Non, si cela augmente les arrivées à capacité fixe. Examinez reprises et disponibilité réelles avant de modifier le plan ; gardez inconnus les avis humains absents.

## Tâche assistée par les sources

Lisez l’ancien bilan synthétique et la frontière de génération Learn. Préparez une trace manuelle distinguant sortie de relecture et publication. Faites proposer une date par une aide, puis examinez ses hypothèses. Une trace croissante à capacité dite stable réfute la promesse que la rédaction seule videra la file.

Réalisez la tâche en masquant les corrigés. Gardez vos réponses initiales, les étapes de calcul, les emplacements dans les sources, les incertitudes et toutes les aides reçues, y compris un indice, un terme traduit ou une suggestion d’agent. Comparez ensuite avec les réponses préparées et consignez les corrections sans effacer votre premier essai. Rédigez une courte note de décision présentant l’affirmation, ses hypothèses, le calcul, le contrôle négatif et l’observation susceptible de la réfuter. Un résultat juste dépourvu d’unité ou d’identité de source ne suffit pas à démontrer le transfert. Le dossier comporte cinq critères préparés pour l’apprenant ; leur décision reste null tant qu’il n’existe pas d’essai réel et de relecture autorisée. La réussite de ces calculs établirait seulement une compétence sur le cas déclaré. Elle ne prouverait ni adaptateur opérationnel, ni procédé matériel réussi, ni moteur de rendu plus rapide, ni progrès d’apprentissage dans le projet. Comparez votre note assistée à la référence manuelle : si l’aide masque une hypothèse ou supprime un refus, corrigez la note avant de proposer un changement de méthode.

## Sources et journal de validation

- [Document du projet](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/agentic-composition-2026-10-22/pm003-synthetic-ledger-calculation.json)
- [Source primaire](https://github.com/spareilleux/learn/blob/8f13637ae4596b614c2ba493b596b6a08e1cf43a/scripts/sync-streeling.mjs)
- [Dossier de preuves fixes](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/unit-c.json)
- [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/journal.md)
