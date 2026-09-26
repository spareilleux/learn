---
title: Journal des mises à jour
description: Publications, preuves de livraison et demandes non terminées.
---

## Règle de livraison

Demandé, délégué, réalisé localement, fusionné, déployé et vérifié publiquement sont des états distincts. Un agent actif ou une PR ouverte n'est pas une livraison. Chaque entrée vérifiée doit indiquer une révision, des preuves de validation et une destination publique. Ce journal est un état daté, pas une connexion en direct à GitHub ou wmux.

## Tableau de livraison — 2026-09-26

| Publication vérifiée | Publication ou vérification restante | Demandé, non livré |
| --- | --- | --- |
| Retest SlashForge 4.5.0 et leçon de contribution : PR #21, déploiement Pages réussi | Ocean est partagé publiquement ; son entrée au catalogue est ajoutée avec cette mise à jour | Image d'accueil ComfyUI |
| Laboratoire de qualité des tests et format d'observation agentique : même publication | Narration studio : échantillons locaux, non validés à l'écoute ni intégrés | Illustration ComfyUI d'Ix |
| | Recette de conteneur présente, exécution non testée | Journal « prior art » TARS v1 → v2 |
| | | Nouveaux cours Streeling et liens vers les BD de Jean-Pierre Petit |
| | | Vue Gantt avec estimations étayées et dépendances |
| | | Proposition de contrats de livraison Gaia ; fonctionnalité non implémentée |

Ces colonnes résument uniquement les demandes récentes ci-dessus. Elles ne constituent pas un audit achevé de tous les dépôts ou de toute la conversation. Les dates et responsables non établis par des preuves restent non précisés.

## 2026-09-26 — Contributions SlashForge publiées

La [PR Learn #21](https://github.com/spareilleux/learn/pull/21) est fusionnée sous `26a2f79f7901d8e4cd937ad291b0c4764f6d837e`. Son [build et déploiement Pages](https://github.com/spareilleux/learn/actions/runs/36265141942) ont réussi. La publication comprend le [journal SlashForge](../slashforge/journal/), la [leçon de contribution](../slashforge/07-contributing-back/), l'illustration d'atelier ComfyUI et la [leçon de tests par mutation et propriétés](../repository-dogfooding-lab/06-mutation-property-testing/), dans les trois langues.

Le retest conserve les mesures 4.4.3 et présente séparément les résultats Windows de la 4.5.0. La CI SlashForge a réussi sous Linux, Windows et macOS ; cela ne transforme pas le retest live Windows en trois retests live. La narration reste un échantillon local et la recette de conteneur n'a pas été exécutée.

## 2026-09-26 — Artifact Ocean partagé vérifié

L'[Artifact GA Ocean](https://claude.ai/artifact/P5JPUkCRR1cYc4herNiR9F) s'est ouvert avec un lien de connexion facultatif, sans exiger de connexion, et a affiché les quatre presets et l'attribution de Saint-Malo. Il est désormais référencé dans le [catalogue des Artifacts](../artifacts/). Cela confirme l'accès à la page partagée, pas les performances WebGPU sur tous les appareils.

## À vérifier

- Contrôler les URL publiques de cette mise à jour et le catalogue après déploiement ; conserver le reçu de déploiement avec le compte rendu d'intégration.
- Publier et inspecter les deux images ComfyUI demandées ; un prompt ou une tâche en attente n'est pas une image.
- Examiner l'historique TARS à des révisions précises avant d'expliquer l'évolution de v1.
- Ajouter un calendrier seulement après établissement des responsables, dépendances et estimations. Aucune date de fin fictive.

## Questions ouvertes

- Les reçus de candidats et d'opérations existants dans Gaia peuvent-ils imposer ces distinctions sans créer une seconde machine à états concurrente ?
- Quelles lacunes Streeling faut-il combler en amont avant la synchronisation canonique de Learn ?
