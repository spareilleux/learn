---
title: Repository Dogfooding Lab — Mission
description: Transformer cours et observations de dépôts en expériences falsifiables, incubation fondée sur les preuves et adoption mesurée dans GA, Gaia, Demerzel, IX, TARS et Learn.
sidebar:
  label: Mission
  order: 0
---

:::caution[Preuves actuelles]
Les tracer bullets restent locaux et hors ligne : un registre JSON de cinq opportunities, cinq matrices générées et un test synthétique de frontière d'autorité Jev × Pétri. Aucune intégration en production, économie Jev live, amélioration d'architecture ou valeur RabbitMQ n'est encore affirmée.
:::

## Mission

Ce cours transforme l'apprentissage en boucle de recherche :

```text
observation → hypothèse falsifiable → baseline → expérience bornée
            → revue contradictoire → incubation → intégration ou rejet
```

Il fait progresser deux disciplines ensemble :

- **software engineering classique :** architecture, fiabilité, tests, observabilité, performance et maintenabilité;
- **IA agentique :** coût par résultat accepté, calibration, escalade, retries, tokens par fournisseur et autonomie sûre.

Terminer un cours n'est pas une réussite. Le résultat utile est une adoption prouvée ou un rejet documenté qui évite du gaspillage.

## Ce que vous allez construire

[`code/repository-dogfooding-lab`](https://github.com/spareilleux/learn/tree/main/code/repository-dogfooding-lab) contient le registre machine-readable. Un outil Python valide les promotions et génère cinq vues : couverture cours × dépôts, score, état de promotion, résultats et preuves, puis qualité de la méthode de cours.

## Plan

| # | Leçon | Résultat |
|---|---|---|
| 1 | [Matrices d'opportunities](01-opportunity-matrices/) | Prioriser sans transformer un score en autorité |
| 2 | [Expérience et artifact chain](02-experiment-artifact-chain/) | Produire une preuve rejouable de l'hypothèse au verdict |
| 3 | [Dogfooder la méthode de cours](03-course-method-dogfood/) | Améliorer exemples, journaux, parité des langues et adoption |
| 4 | [Incuber, intégrer, rejeter](04-incubate-integrate-reject/) | Ne promouvoir que des candidats mesurés et réversibles |
| 5 | [Frontière d'autorité Jev × Pétri](05-jev-petri-authority/) | Montrer pourquoi un avis confiant n'accorde aucun effet |
| 6 | [Tests de mutation et de propriétés](06-mutation-property-testing/) | Mesurer quelles fautes détectent les tests d'un vrai parseur, avec une pré-inscription et un témoin négatif |
| — | [Journal](journal/) | Expériences détaillées, rejets et prochains gates |

```text
cd code/repository-dogfooding-lab
python dogfood.py write
python dogfood.py check
python -m unittest -v
```
