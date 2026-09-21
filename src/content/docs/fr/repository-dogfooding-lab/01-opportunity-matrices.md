---
title: Matrices d'opportunities
description: Utiliser plusieurs petites matrices pour exposer couverture, valeur, preuves et promotion sans masquer l'incertitude dans un score unique.
sidebar:
  order: 1
---

Un classement géant masque trop de choses. Ce laboratoire conserve cinq vues distinctes. Les valeurs actuelles sont publiées dans le [`matrices.md`](https://github.com/spareilleux/learn/blob/main/code/repository-dogfooding-lab/matrices.md) généré; `python dogfood.py check` échoue si cet artefact dérive du registre JSON.

## 1. Couverture cours × dépôts

Elle révèle les transferts possibles et les angles morts. Une technique applicable à plusieurs dépôts ne doit pas être adoptée partout.

## 2. Score d'opportunity

Le score additionne douleur, fit, valeur attendue, preuve et réversibilité, puis soustrait coût et risque. Chaque dimension vaut de 0 à 5. Il ordonne uniquement l'investigation.

- le score ne peut modifier ni `status` ni `authority`;
- un score élevé avec peu de preuves reste une découverte, pas une incubation.

## 3. État de promotion

```text
discovered → experimenting → incubating → integrating → adopted
       └──────────────→ rejected                         → retired
```

Une promotion exige des artefacts. `adopted` exige aussi un verdict confirmé. Les rejets restent dans le registre pour éviter qu'un autre agent répète la même idée.

## 4. Résultats et preuves

Cette vue dit ce qui a réellement été mesuré, où se trouve l'artefact et quand revoir la conclusion. Un agent `running`, un commentaire ou une narration plausible ne sont pas des preuves.

## 5. Qualité de la méthode de cours

La méthode est elle-même dogfoodée : exemples exécutables, preuves du journal, parité EN/FR/ES, retour d'adoption et efficacité agentique.

<details>
<summary>Exercice : ajouter un candidat sans le sur-vendre</summary>

Ajoutez une opportunity avec douleur observée, alternative plus simple et falsifier. Gardez-la `discovered` tant que la baseline manque. Exécutez `python dogfood.py write` puis `python -m unittest -v`.

</details>
