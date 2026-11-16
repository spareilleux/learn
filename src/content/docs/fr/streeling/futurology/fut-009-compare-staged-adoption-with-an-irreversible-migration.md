---
title: Comparer adoption progressive et migration irréversible
description: Comparer adoption progressive et migration irréversible — Futurologie
sidebar:
  label: FUT-009 · Comparer adoption progressive et migration irréversible
  order: 9
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/futurology/fr/fut-009-compare-staged-adoption-with-an-irreversible-migration.fr.md
---

:::note[Streeling University]
**FUT-009** · Comparer adoption progressive et migration irréversible · intermédiaire · 40 minutes

Généré par le département *Futurologie* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/futurology/fr/fut-009-compare-staged-adoption-with-an-irreversible-migration.fr.md) · [Mon journal](../../journal/)

Prérequis: [FUT-004](../../futurology/fut-004-scenario-test-an-observatory-renderer/), [FUT-005](../../futurology/fut-005-value-a-renderer-pilot-before-running-it/)
:::

> Brouillon à soumettre à une relecture humaine. Les cas fixes ci-dessous sont des modèles mathématiques rédigés après lecture des sources ; ce ne sont pas de nouvelles mesures du projet. Les avis techniques, artisanaux, linguistiques et pédagogiques restent en attente. Aucun moteur de scène, échantillon physique, GPU, exécuteur de politique ni essai avec un apprenant n’a été utilisé pour cette leçon.

## Question du projet

Une future migration du rendu artisanal supprime immédiatement l’ancien chemin. Une autre approche le conserve jusqu’au franchissement d’un contrôle d’acceptation. Quel plan limite la perte si le candidat convient mal ? L’ancien dossier BRUTAL contient un échec de coexistence et un suivi non concluant ; il ne fournit aucune probabilité de réussite. Cette leçon compare les pertes conditionnelles par scénario en explicitant le retour arrière, sans inventer de pilote réel.

[Prérequis: fut-004-scenario-test-an-observatory-renderer](../../futurology/fut-004-scenario-test-an-observatory-renderer/); [Prérequis: fut-005-value-a-renderer-pilot-before-running-it](../../futurology/fut-005-value-a-renderer-pilot-before-running-it/)

## Lire le périmètre avant de calculer

Lisez le prérequis et le document du projet avant de calculer. Distinguez les affirmations tirées du code inspecté, les résultats consignés antérieurement et les conséquences des seules hypothèses ci-dessous. Un commentaire de code, un corrigé préparé et une observation exécutée n’ont pas la même valeur probante. Conservez la date d’origine ainsi que tout contrôle échoué ou non concluant dans votre résumé d’un ancien document. La référence manuelle est un petit calcul sur papier accompagné d’un tableau des emplacements dans les sources ; un agent peut aider à trouver une définition, mais son résumé doit être confronté à celle-ci. Ce cas fini ne nécessite aucun nouveau langage ni automatisme.

Utilisez deux états construits, adapté et inadapté, et des points de perte comparables. La migration directe coûte moins dans l’état favorable mais perd davantage dans l’autre. Le passage par étapes coûte plus quand tout va bien, car il maintient deux chemins et vérifie un contrôle. Dans l’état défavorable, il préserve une sortie. Comparez pertes maximales et regrets avant d’invoquer des probabilités. Contrairement à la valeur d’information attendue du prérequis, nous n’estimons aucune vraisemblance ni moyenne d’états. Un contrôle défectueux peut laisser passer le candidat inadapté et supprimer la protection. Le retour arrière exige un artefact conservé et une compatibilité réelle, pas un mot rassurant.

## Cas fixe et hypothèses

```text
states=["suitable","unsuitable"]; unit="authored loss points"
direct=[6,26]; staged_with_correct_gate=[10,8]
state_best=[6,8]
direct_regret=[0,18]; staged_regret=[4,0]
direct_worst=26; staged_worst=10
direct_max_regret=18; staged_max_regret=4
control_staged_false_acceptance=[10,30]; control_worst=30
```

## Exercices corrigés

### Exercice 1

Quel plan perd le moins dans chaque état ?

> **Réponse:** Le direct gagne si adapté avec `6` contre `10` ; les étapes gagnent si inadapté avec `8` contre `26`. Aucun plan ne domine les deux états.

### Exercice 2

Comparez les pertes maximales.

> **Réponse:** Elles valent `26` pour le direct et `10` pour les étapes. Préférer la moindre perte maximale favorise les étapes dans cette table, sans établir de probabilités réelles.

### Exercice 3

Déduisez les deux vecteurs de regret.

> **Réponse:** Soustrayez la meilleure perte par état : le direct donne `[0,18]`, les étapes `[4,0]`. Les regrets maximaux sont `18` et `4`.

### Exercice 4

Appliquez le contrôle de filtre défectueux. Les étapes restent-elles automatiquement plus sûres ?

> **Réponse:** Non. La perte maximale devient `30`, au-delà des `26` du direct. Le bon fonctionnement du contrôle est une hypothèse décisive, pas une garantie des étapes.

### Exercice 5

L’ancien rapport de rendu non concluant autorise-t-il la migration ?

> **Réponse:** Non. Il conserve une coexistence non résolue. Le plan réel exige acceptation liée à la source, artefacts de retour conservés et autorisation applicable ; la table ne fournit aucune de ces observations.

## Tâche assistée par les sources

Lisez l’ancien échec et le suivi non concluant. Préparez manuellement les pertes directes et par étapes, avec exigences d’artefact conservé et de contrôle clairement proposées. Faites expliquer l’avantage des étapes par une aide, puis testez la fausse acceptation. Ce contrôle réfute toute sécurité inconditionnelle.

Réalisez la tâche en masquant les corrigés. Gardez vos réponses initiales, les étapes de calcul, les emplacements dans les sources, les incertitudes et toutes les aides reçues, y compris un indice, un terme traduit ou une suggestion d’agent. Comparez ensuite avec les réponses préparées et consignez les corrections sans effacer votre premier essai. Rédigez une courte note de décision présentant l’affirmation, ses hypothèses, le calcul, le contrôle négatif et l’observation susceptible de la réfuter. Un résultat juste dépourvu d’unité ou d’identité de source ne suffit pas à démontrer le transfert. Le dossier comporte cinq critères préparés pour l’apprenant ; leur décision reste null tant qu’il n’existe pas d’essai réel et de relecture autorisée. La réussite de ces calculs établirait seulement une compétence sur le cas déclaré. Elle ne prouverait ni adaptateur opérationnel, ni procédé matériel réussi, ni moteur de rendu plus rapide, ni progrès d’apprentissage dans le projet. Comparez votre note assistée à la référence manuelle : si l’aide masque une hypothèse ou supprime un refus, corrigez la note avant de proposer un changement de méthode.

## Sources et journal de validation

- [Document du projet](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/brutal-composition-2026-10-22/historical-comparison.json)
- [Source primaire](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/README.md)
- [Dossier de preuves fixes](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/unit-c.json)
- [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/journal.md)
