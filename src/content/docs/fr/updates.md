---
title: Journal des mises à jour
description: Publications, preuves de livraison et demandes non terminées.
---

## Règle de livraison

Demandé, délégué, réalisé localement, fusionné, déployé et vérifié publiquement sont des états distincts. Un agent actif ou une PR ouverte n'est pas une livraison. Chaque entrée vérifiée doit indiquer une révision, des preuves de validation et une destination publique. Ce journal est un état daté, pas une connexion en direct à GitHub ou wmux.

## Tableau de livraison — 2026-09-27

| Publication vérifiée | Publication ou vérification restante | Demandé, non livré |
| --- | --- | --- |
| [Leçon 9 de LadybugDB, laboratoire de graphe](../ladybugdb/09-graph-lab/) : PR #25 fusionnée en `438b320`, déploiement Pages réussi, leçon et entrée de journal EN/FR/ES relues anonymement | [Streeling MAT-003](../streeling/mathematics/) : source fusionnée dans Demerzel (`89a1bdb`) ; PR #26 du générateur fusionnée en `67ffd4e` et PR #24 du laboratoire Learn en `00ae641` ; synchronisation canonique en attente de revue | Modules de mathématiques Streeling au-delà de MAT-001 et MAT-003 : aucun n'existe encore dans la source canonique ; MAT-002 et MAT-004 sont en file d'attente |

Ce tableau ajoute ce qui a été réglé ou ouvert le 2026-09-27 ; celui du 2026-09-26 ci-dessous est inchangé.

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

## 2026-09-27 — Leçon 9 de LadybugDB et Streeling MAT-003 publiées

La [PR Learn #25](https://github.com/spareilleux/learn/pull/25) a été fusionnée en `438b320`, et son [déploiement Pages](https://github.com/spareilleux/learn/actions/runs/36341917142) a réussi. La [leçon 9 de LadybugDB](../ladybugdb/09-graph-lab/) et son [entrée de journal](../ladybugdb/journal/) ont été relues anonymement dans les trois langues. Les deux scripts du laboratoire ont passé la CI du cours sous Linux, Windows et macOS ; les mesures elles-mêmes ont été prises sous Windows.

[Streeling MAT-003](../streeling/mathematics/mat-003-floating-point-conditioning/) est arrivé par trois fusions :
- le laboratoire Learn ([PR #24](https://github.com/spareilleux/learn/pull/24), `00ae641`) ;
- les libellés « en anglais » du générateur ([PR #26](https://github.com/spareilleux/learn/pull/26), `67ffd4e`) ;
- la synchronisation canonique au commit Demerzel `89a1bdb` ([PR #27](https://github.com/spareilleux/learn/pull/27), `ce6021f`), dont le [déploiement Pages](https://github.com/spareilleux/learn/actions/runs/36343842316) a réussi.

Le module, l'index des mathématiques, l'[entrée du journal Streeling](../streeling/journal/) et le tableau du 2026-09-27 ci-dessus ont été relus anonymement dans les trois langues. Ce tableau est un état pris avant ces fusions, et il reste tel qu'il a été écrit.

Ces deux éléments passent donc de « restant » à « vérifié ». Le catalogue de mathématiques compte toujours deux modules, MAT-001 et MAT-003.

## 2026-09-27 — Illustrations de l'accueil et d'IX publiées

La [PR Learn #23](https://github.com/spareilleux/learn/pull/23) a été fusionnée en `3c8c1de`, et son [déploiement Pages](https://github.com/spareilleux/learn/actions/runs/36299159809) a réussi. La [page d'accueil](../) et l'[introduction du cours IX](../machine-learning-ix/) montrent désormais les deux images générées localement avec ComfyUI et des modèles en cache. Dans les trois langues, chacune est présentée comme de l'art conceptuel, pas un schéma. Les six pages ont répondu 200 sans authentification, et les deux images étaient identiques, octet pour octet, à un build local.

Ce sont les deux images ComfyUI que le tableau du 2026-09-26 range dans les demandes. Ce tableau reste tel qu'il a été écrit.

## 2026-09-27 — Leçon 16 des réseaux de Petri et cours AutoHarness publiés

La [PR Learn #28](https://github.com/spareilleux/learn/pull/28) a été fusionnée en `e5a4ddd`, et la [PR #29](https://github.com/spareilleux/learn/pull/29) en `c406126`, dont le [déploiement Pages](https://github.com/spareilleux/learn/actions/runs/36368118824) a réussi. La [leçon 16 des réseaux de Petri](../petri-nets/16-interoperability-lab/), son [journal](../petri-nets/journal/), le [cours AutoHarness](../autoharness/) et son [journal](../autoharness/journal/) ont été relus sans authentification dans les trois langues.

- **Les deux PR ont été réparées après la revue.** La revue de Codex demandait des changements à chacune :
  - la comparaison d'aller-retour de la leçon 16 et sa garde sur le genre d'arc ont été corrigées, avec des tests qui échouaient d'abord, et ses liens QA pointent désormais vers un commit fixe ;
  - les fixtures d'AutoHarness tournent désormais en CI sous Linux, Windows et macOS.
- **Les têtes réparées ont été fusionnées à la demande de l'utilisateur,** sans seconde revue indépendante.
- **Ce qui reste non mesuré.** Les analyseurs externes de la leçon 16 (TINA, pm4py, Graphviz) sont des recettes qui n'ont pas été exécutées. AutoHarness a été évalué sans être installé, et son verdict est « ne pas adopter » à `ca39a72`.

## 2026-09-27 — Streeling MAT-002 synchronisé, en attente de vérification

La [PR Demerzel #1136](https://github.com/GuitarAlchemist/Demerzel/pull/1136) a été relue indépendamment à `5e6b733` et fusionnée en `a3a07df`. Cette mise à jour la synchronise dans Learn :
- le [module MAT-002](../streeling/mathematics/mat-002-counterexamples-and-exhaustive-checks/) dans les trois langues ;
- l'index des mathématiques ;
- l'[entrée du journal Streeling](../streeling/journal/).

MAT-002 reste **en attente de vérification** jusqu'à ce que ce changement soit fusionné, que son déploiement réussisse et que les pages soient relues sans authentification. MAT-004 a été fusionné dans Demerzel après cette épingle (`d451c90`, [PR #1137](https://github.com/GuitarAlchemist/Demerzel/pull/1137)) ; il n'est pas synchronisé ici.

## 2026-09-27 — Streeling MAT-004 synchronisé, en attente de vérification

La [PR Demerzel #1137](https://github.com/GuitarAlchemist/Demerzel/pull/1137) a été fusionnée en `d451c90`, après l'épingle de MAT-002. Cette mise à jour la synchronise dans Learn :
- le [module MAT-004](../streeling/mathematics/mat-004-vectors-matrices-norms/) dans les trois langues ;
- l'index des mathématiques ;
- l'[entrée du journal Streeling](../streeling/journal/).

MAT-004 reste **en attente de vérification** jusqu'à ce que ce changement soit fusionné, que son déploiement réussisse et que les pages soient relues sans authentification.

## 2026-09-27 — Streeling MAT-005 synchronisé, en attente de vérification

La [PR Demerzel #1138](https://github.com/GuitarAlchemist/Demerzel/pull/1138) a été fusionnée en `8bd026f`, après l'épingle de MAT-004. Cette mise à jour la synchronise dans Learn :
- le [module MAT-005](../streeling/mathematics/mat-005-symmetric-eigenproblems/) dans les trois langues ;
- l'index des mathématiques ;
- l'[entrée du journal Streeling](../streeling/journal/).

MAT-005 reste **en attente de vérification** jusqu'à ce que ce changement soit fusionné, que son déploiement réussisse et que les pages soient relues sans authentification.

## 2026-09-27 — Streeling MAT-002, MAT-004 et MAT-005 publiés

Codex a fusionné les trois synchronisations canoniques, et chaque déploiement Pages a réussi :
- [MAT-002](../streeling/mathematics/mat-002-counterexamples-and-exhaustive-checks/), Demerzel `a3a07df` : [PR #35](https://github.com/spareilleux/learn/pull/35), fusionnée en `1b4ec84`, [déploiement](https://github.com/spareilleux/learn/actions/runs/36371547922) ;
- [MAT-004](../streeling/mathematics/mat-004-vectors-matrices-norms/), Demerzel `d451c90` : [PR #36](https://github.com/spareilleux/learn/pull/36), fusionnée en `b0f4380`, [déploiement](https://github.com/spareilleux/learn/actions/runs/36372857458) ;
- [MAT-005](../streeling/mathematics/mat-005-symmetric-eigenproblems/), Demerzel `8bd026f` : [PR #37](https://github.com/spareilleux/learn/pull/37), fusionnée en `36d4d17`, [déploiement](https://github.com/spareilleux/learn/actions/runs/36373405733).

Les trois modules, l'index des mathématiques, le [journal Streeling](../streeling/journal/) et leurs entrées dans ce journal ont été relus sans authentification dans les trois langues. Les pages servies renvoient désormais à leur source à `8bd026f`, l'épingle de la dernière synchronisation.

Ces trois modules passent donc d'en attente de vérification à vérifiés ; leurs entrées ci-dessus restent telles qu'écrites. Le catalogue de mathématiques compte maintenant cinq modules, de MAT-001 à MAT-005. Publié ne veut pas dire étudié : aucun n'a été exécuté ni étudié ici, et leurs expériences restent proposées.

## 2026-09-27 — Streeling MAT-006 synchronisé, en attente de vérification

La [PR Demerzel #1139](https://github.com/GuitarAlchemist/Demerzel/pull/1139) a été fusionnée en `0b13b9d`, après l'épingle de MAT-005. Cette mise à jour la synchronise dans Learn :
- le [module MAT-006](../streeling/mathematics/mat-006-svd-low-rank-approximation/) dans les trois langues ;
- l'index des mathématiques ;
- l'[entrée du journal Streeling](../streeling/journal/).

MAT-006 reste **en attente de vérification** jusqu'à ce que ce changement soit fusionné, que son déploiement réussisse et que les pages soient relues sans authentification.

## À vérifier

- Contrôler les URL publiques de cette mise à jour et le catalogue après déploiement ; conserver le reçu de déploiement avec le compte rendu d'intégration.
- Examiner l'historique TARS à des révisions précises avant d'expliquer l'évolution de v1.
- Ajouter un calendrier seulement après établissement des responsables, dépendances et estimations. Aucune date de fin fictive.

## Questions ouvertes

- Les reçus de candidats et d'opérations existants dans Gaia peuvent-ils imposer ces distinctions sans créer une seconde machine à états concurrente ?
- Quelles lacunes Streeling faut-il combler en amont avant la synchronisation canonique de Learn ?
