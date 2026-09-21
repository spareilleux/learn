---
title: Incuber, intégrer, rejeter
description: Convertir une preuve prometteuse en plus petit changement réversible, avec autorité et rollback explicites.
sidebar:
  order: 4
---

L'incubation n'est pas une adoption déguisée : le candidat y affronte la solution actuelle.

| Transition | Gate |
|---|---|
| discovered → experimenting | Douleur et hypothèse prouvées; alternative plus simple consignée |
| experimenting → incubating | Baseline, résultat reproductible et revue indépendante |
| incubating → integrating | Le tracer bullet gagne sur les mesures et possède un rollback |
| integrating → adopted | Checks du dépôt réussis, autorité responsable d'accord, preuve opérationnelle saine |
| any → rejected | Falsifier atteint, seam inutile ou alternative plus simple gagnante |

- intégrer un tracer bullet vertical, pas une plateforme horizontale;
- préserver les contrats actuels avant preuve de remplacement;
- épingler versions et révisions;
- séparer auteur, reviewer et autorité de merge;
- conserver le rejet et ses preuves.

Pour Jev, une bonne calibration autorise seulement l'A/B borné suivant, pas le routing fournisseur dans GA, Gaia ou Demerzel.

<details>
<summary>Exercice : écrire un reçu de rejet</summary>

Choisissez un candidat battu par son alternative simple. Consignez baseline, résultat, critère violé, artefact retenu et condition de réexamen. Mettez `status` à `rejected` sans supprimer la ligne.

</details>
