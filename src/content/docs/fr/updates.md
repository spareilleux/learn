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

Les trois modules, l'index des mathématiques, le [journal Streeling](../streeling/journal/) et leurs entrées dans ce journal ont été relus sans authentification dans les trois langues. Lors de cette relecture, après #37, les pages servies renvoyaient à leur source à `8bd026f` ; cette mise à jour les réépingle à `0b13b9d`.

Ces trois modules passent donc d'en attente de vérification à vérifiés ; leurs entrées ci-dessus restent telles qu'écrites. Lors de la même relecture, le catalogue de mathématiques comptait cinq modules, de MAT-001 à MAT-005 ; cette mise à jour ajoute MAT-006, le sixième. Publié ne veut pas dire étudié : aucun n'a été exécuté ni étudié ici, et leurs expériences restent proposées.

## 2026-09-27 — Streeling MAT-006 synchronisé, en attente de vérification

La [PR Demerzel #1139](https://github.com/GuitarAlchemist/Demerzel/pull/1139) a été fusionnée en `0b13b9d`, après l'épingle de MAT-005. Cette mise à jour la synchronise dans Learn :
- le [module MAT-006](../streeling/mathematics/mat-006-svd-low-rank-approximation/) dans les trois langues ;
- l'index des mathématiques ;
- l'[entrée du journal Streeling](../streeling/journal/).

MAT-006 reste **en attente de vérification** jusqu'à ce que ce changement soit fusionné, que son déploiement réussisse et que les pages soient relues sans authentification.

## 2026-09-27 — Streeling MAT-006 publié

Codex a fusionné la [PR Learn #38](https://github.com/spareilleux/learn/pull/38) en `0853739`, après deux corrections de ce journal demandées en revue, et son [déploiement Pages](https://github.com/spareilleux/learn/actions/runs/36375002691) a réussi. Le [module MAT-006](../streeling/mathematics/mat-006-svd-low-rank-approximation/), l'index des mathématiques, le [journal Streeling](../streeling/journal/) et ce journal ont été relus sans authentification dans les trois langues : 12 pages, qui répondent toutes 200 et mentionnent MAT-006.

MAT-006 passe donc d'en attente de vérification à vérifié ; son entrée ci-dessus reste telle qu'écrite. Lors de cette relecture, les pages MAT-006 renvoyaient à leur source à `0b13b9d` ; cette mise à jour les réépingle à `8c14336`. Comme pour les modules précédents, publié ne veut pas dire étudié : MAT-006 n'a été ni exécuté ni étudié ici, et son expérience reste proposée.

## 2026-09-27 — Streeling MAT-007 synchronisé, en attente de vérification

La [PR Demerzel #1140](https://github.com/GuitarAlchemist/Demerzel/pull/1140) a été fusionnée en `8c14336`, après l'épingle de MAT-006. Cette mise à jour la synchronise dans Learn :
- le [module MAT-007](../streeling/mathematics/mat-007-least-squares-regularisation/) dans les trois langues ;
- l'index des mathématiques ;
- l'[entrée du journal Streeling](../streeling/journal/).

MAT-007 reste **en attente de vérification** jusqu'à ce que ce changement soit fusionné, que son déploiement réussisse et que les pages soient relues sans authentification.

## 2026-10-02 — Streeling MAT-007 publié

La [PR Learn #39](https://github.com/spareilleux/learn/pull/39) a été fusionnée en `0436325`, et son [déploiement Pages](https://github.com/spareilleux/learn/actions/runs/36377803965) a réussi. Le 2026-10-02, avec `main` à `c547150` et son [déploiement](https://github.com/spareilleux/learn/actions/runs/37065792242) réussi, le [module MAT-007](../streeling/mathematics/mat-007-least-squares-regularisation/), l'index des mathématiques, le [journal Streeling](../streeling/journal/) et ce journal ont été relus sans authentification dans les trois langues : 12 pages, qui répondent toutes 200 et mentionnent MAT-007.

MAT-007 passe donc d'en attente de vérification à vérifié ; son entrée ci-dessus reste telle qu'écrite. Lors de cette relecture, les pages MAT-007 renvoyaient à leur source à `8c14336` ; cette mise à jour les réépingle à `e203e5a`. Comme pour les modules précédents, publié ne veut pas dire étudié : MAT-007 n'a été ni exécuté ni étudié ici, et son expérience reste proposée.

## 2026-10-02 — Streeling MAT-008 à MAT-025 et cinq modules de musique synchronisés, en attente de vérification

Le `master` de Demerzel a atteint [`e203e5a`](https://github.com/GuitarAlchemist/Demerzel/commit/e203e5a25e10b85b8d22ece9a700e12447f4a236), après l'épingle de MAT-007. Cette mise à jour le synchronise dans Learn :
- 23 nouveaux modules dans les trois langues : [MAT-008 à MAT-025](../streeling/mathematics/) et, en [musique](../streeling/music/), MUS-007, MUS-008, MUS-009, MUS-018 et MUS-020 ;
- des pages françaises et espagnoles pour quinze modules qui n'avaient ici que l'anglais, et les corrections et accents espagnols rétablis fusionnés dans Demerzel depuis `8c14336` ;
- les index des départements ;
- l'[entrée du journal Streeling](../streeling/journal/).

Ces modules et traductions restent **en attente de vérification** jusqu'à ce que ce changement soit fusionné, que son déploiement réussisse et que les pages soient relues sans authentification.

## 2026-10-02 — Streeling MAT-008 à MAT-025, cinq modules de musique et quinze traductions publiés

La [PR Learn #114](https://github.com/spareilleux/learn/pull/114) a été fusionnée en `48d4e74`, après la correction de deux formulations du journal demandée en revue indépendante, et son [déploiement Pages](https://github.com/spareilleux/learn/actions/runs/37070579523) a réussi. Les pages ont ensuite été relues sans authentification dans les trois langues, 99 pages de modules en tout, qui répondent toutes 200, nomment leur module et renvoient à leur source à `e203e5a` :
- les 23 nouveaux modules, [MAT-008 à MAT-025](../streeling/mathematics/) et, en [musique](../streeling/music/), MUS-007, MUS-008, MUS-009, MUS-018 et MUS-020, en anglais, en français et en espagnol ;
- les pages françaises et espagnoles des quinze modules nouvellement traduits.

Les index des mathématiques et de la musique, le [journal Streeling](../streeling/journal/) et ce journal ont aussi répondu 200. Ces modules et traductions passent donc d'en attente de vérification à vérifiés ; leur entrée ci-dessus reste telle qu'écrite. Cette mise à jour réépingle leurs liens source à `d459d8e`. Publié ne veut pas dire étudié : aucun n'a été exécuté ni étudié ici, et leurs expériences restent proposées.

## 2026-10-02 — Leçons 9 à 14 de théorie musicale publiées

Chaque leçon a été fusionnée après le succès de sa CI et une revue indépendante de son dernier commit qui n'a rien laissé d'ouvert :
- [Leçon 9](../music-theory-ga/09-voice-leading-and-common-tones/) : [PR #90](https://github.com/spareilleux/learn/pull/90), fusionnée en `c547150` ;
- [Leçon 10](../music-theory-ga/10-substitutions-and-modal-mixture/) : [PR #99](https://github.com/spareilleux/learn/pull/99), fusionnée en `9722af8` ;
- [Leçon 11](../music-theory-ga/11-modes-in-depth/) : [PR #100](https://github.com/spareilleux/learn/pull/100), fusionnée en `c0abd0e` ;
- [Leçon 12](../music-theory-ga/12-symmetry-and-limited-transposition/) : [PR #104](https://github.com/spareilleux/learn/pull/104), fusionnée en `641df75` ;
- [Leçon 13](../music-theory-ga/13-extended-and-altered-chords/) : [PR #108](https://github.com/spareilleux/learn/pull/108), fusionnée en `e2ce788` ;
- [Leçon 14](../music-theory-ga/14-guitar-voicings/) : [PR #111](https://github.com/spareilleux/learn/pull/111), fusionnée en `1364ba4`.

Le [déploiement Pages](https://github.com/spareilleux/learn/actions/runs/37070289373) de `1364ba4` a réussi, comme le suivant, celui de #114. Les six leçons ont répondu 200 sans authentification dans les trois langues, 18 pages en tout.

## 2026-10-02 — Correction de Streeling PHY-001 synchronisée, en attente de vérification

La [PR Demerzel #1179](https://github.com/GuitarAlchemist/Demerzel/pull/1179) a été fusionnée en `d459d8e`, après l'épingle de `e203e5a`. Cette mise à jour la synchronise dans Learn :
- l'exercice corrigé du [module PHY-001](../streeling/physics/phy-001-science-of-guitar-sound/), dans les trois langues : les 2/3 d'une quinte juste se mesurent de la frette 7 au chevalet, pas depuis le sillet ;
- l'[entrée du journal Streeling](../streeling/journal/).

La correction de PHY-001 reste **en attente de vérification** jusqu'à ce que ce changement soit fusionné, que son déploiement réussisse et que les pages soient relues sans authentification.

## 2026-10-03 — Correction de Streeling PHY-001 publiée

La [PR Learn #117](https://github.com/spareilleux/learn/pull/117) a été fusionnée en `8183127`, et son [déploiement Pages](https://github.com/spareilleux/learn/actions/runs/37072084405) a réussi. Le [module PHY-001](../streeling/physics/phy-001-science-of-guitar-sound/) et le [journal Streeling](../streeling/journal/) ont ensuite été relus sans authentification dans les trois langues : six pages, qui répondent toutes 200. Les pages du module nomment PHY-001 et renvoient à leur source à `d459d8e` ; celles du journal portent son entrée du 2026-10-02.

La correction de PHY-001 passe donc d'en attente de vérification à vérifiée ; son entrée ci-dessus reste telle qu'écrite. Cette mise à jour réépingle les liens source du module à `450fc67`. Publié ne veut pas dire étudié : PHY-001 n'a été ni exécuté ni étudié ici.

## 2026-10-03 — Leçon 15 de théorie musicale publiée

La [leçon 15](../music-theory-ga/15-the-fretboard/) a été fusionnée après le succès de sa CI : [PR #119](https://github.com/spareilleux/learn/pull/119), fusionnée en `89dc3e6`. Son [déploiement Pages](https://github.com/spareilleux/learn/actions/runs/37083729662) a réussi. La leçon et le [journal du cours](../music-theory-ga/journal/) ont répondu 200 sans authentification dans les trois langues, six pages en tout.

## 2026-10-03 — Streeling MUS-012 synchronisé, en attente de vérification

La [PR Demerzel #1180](https://github.com/GuitarAlchemist/Demerzel/pull/1180) a été fusionnée en `450fc67`, après l'épingle de `d459d8e`. Cette mise à jour la synchronise dans Learn :
- le nouveau [module MUS-012](../streeling/music/mus-012-chord-formulas-essential-tones-doubling/), Formules d'accords, notes essentielles et redoublements, dans les trois langues ;
- sa ligne dans l'[index de la musique](../streeling/music/) et dans le [journal Streeling](../streeling/journal/), avec une entrée datée dans ce dernier.

MUS-012 reste **en attente de vérification** jusqu'à ce que ce changement soit fusionné, que son déploiement réussisse et que les pages soient relues sans authentification.

## 2026-10-03 — Streeling MUS-012 publié

La [PR Learn #124](https://github.com/spareilleux/learn/pull/124) a été fusionnée en `062e3cb`, après deux corrections du journal Streeling demandées en revue indépendante, et son [déploiement Pages](https://github.com/spareilleux/learn/actions/runs/37143956527) a réussi. Les pages ont ensuite été relues sans authentification dans les trois langues : douze pages, qui répondent toutes 200. Les pages du [module MUS-012](../streeling/music/mus-012-chord-formulas-essential-tones-doubling/) nomment MUS-012 et renvoient à leur source à `450fc67` ; l'[index de la musique](../streeling/music/) le liste, et le [journal Streeling](../streeling/journal/) et ce journal portent leurs entrées du 2026-10-03.

MUS-012 passe donc d'en attente de vérification à vérifié ; son entrée ci-dessus reste telle qu'écrite. Cette mise à jour réépingle ses liens source à `928fbb2`. Publié ne veut pas dire étudié : MUS-012 n'a été ni exécuté ni étudié ici, et son expérience reste proposée.

## 2026-10-03 — Streeling MUS-013 synchronisé, en attente de vérification

La [PR Demerzel #1181](https://github.com/GuitarAlchemist/Demerzel/pull/1181) a été fusionnée en `928fbb2`, après l'épingle de `450fc67`. Cette mise à jour la synchronise dans Learn :
- le nouveau [module MUS-013](../streeling/music/mus-013-root-bass-pitch-class-set/), Fondamentale, basse et ensemble de classes de hauteurs, dans les trois langues ;
- sa ligne dans l'[index de la musique](../streeling/music/) et dans le [journal Streeling](../streeling/journal/), avec une entrée datée dans ce dernier.

MUS-013 reste **en attente de vérification** jusqu'à ce que ce changement soit fusionné, que son déploiement réussisse et que les pages soient relues sans authentification.

## 2026-10-03 — Streeling MUS-013 publié

La [PR Learn #128](https://github.com/spareilleux/learn/pull/128) a été fusionnée en `0c918c8`, et son [déploiement Pages](https://github.com/spareilleux/learn/actions/runs/37144727921) a réussi. Les pages ont ensuite été relues sans authentification dans les trois langues : douze pages, qui répondent toutes 200. Les pages du [module MUS-013](../streeling/music/mus-013-root-bass-pitch-class-set/) nomment MUS-013 et renvoient à leur source à `928fbb2` ; l'[index de la musique](../streeling/music/) le liste, et le [journal Streeling](../streeling/journal/) et ce journal portent leurs entrées du 2026-10-03.

MUS-013 passe donc d'en attente de vérification à vérifié ; son entrée ci-dessus reste telle qu'écrite. Cette mise à jour réépingle ses liens source à `d8c8da5`. Publié ne veut pas dire étudié : MUS-013 n'a été ni exécuté ni étudié ici, et son expérience reste proposée.

## 2026-10-03 — Streeling MUS-010 synchronisé, en attente de vérification

La [PR Demerzel #1183](https://github.com/GuitarAlchemist/Demerzel/pull/1183) a été fusionnée en `d8c8da5`, après l'épingle de `928fbb2`. Cette mise à jour la synchronise dans Learn :
- le nouveau [module MUS-010](../streeling/music/mus-010-scales-pattern-set-interval-vector/), Formules de gammes, ensembles et vecteur d'intervalles diatonique, dans les trois langues ;
- sa ligne dans l'[index de la musique](../streeling/music/) et dans le [journal Streeling](../streeling/journal/), avec une entrée datée dans ce dernier.

MUS-010 reste **en attente de vérification** jusqu'à ce que ce changement soit fusionné, que son déploiement réussisse et que les pages soient relues sans authentification.

## 2026-10-03 — Streeling MUS-010 publié

La [PR Learn #132](https://github.com/spareilleux/learn/pull/132) a été fusionnée en `9e03205`, et son [déploiement Pages](https://github.com/spareilleux/learn/actions/runs/37152236058) a réussi. Les pages ont ensuite été relues sans authentification dans les trois langues : douze pages, qui répondent toutes 200. Les pages du [module MUS-010](../streeling/music/mus-010-scales-pattern-set-interval-vector/) nomment MUS-010 et renvoient à leur source à `d8c8da5` ; l'[index de la musique](../streeling/music/) le liste, et le [journal Streeling](../streeling/journal/) et ce journal portent leurs entrées du 2026-10-03.

MUS-010 passe donc d'en attente de vérification à vérifié ; son entrée ci-dessus reste telle qu'écrite. Cette mise à jour réépingle ses liens source à `499fc64`. Publié ne veut pas dire étudié : MUS-010 n'a été ni exécuté ni étudié ici, et son expérience reste proposée.

## 2026-10-03 — Streeling MUS-011 synchronisé, en attente de vérification

La [PR Demerzel #1184](https://github.com/GuitarAlchemist/Demerzel/pull/1184) a été fusionnée en `499fc64`, après l'épingle de `d8c8da5`. Cette mise à jour la synchronise dans Learn :
- le nouveau [module MUS-011](../streeling/music/mus-011-modes-modal-families/), Modes et familles modales, dans les trois langues ;
- sa ligne dans l'[index de la musique](../streeling/music/) et dans le [journal Streeling](../streeling/journal/), avec une entrée datée dans ce dernier.

MUS-011 reste **en attente de vérification** jusqu'à ce que ce changement soit fusionné, que son déploiement réussisse et que les pages soient relues sans authentification.

## À vérifier

- Contrôler les URL publiques de cette mise à jour et le catalogue après déploiement ; conserver le reçu de déploiement avec le compte rendu d'intégration.
- Examiner l'historique TARS à des révisions précises avant d'expliquer l'évolution de v1.
- Ajouter un calendrier seulement après établissement des responsables, dépendances et estimations. Aucune date de fin fictive.

## Questions ouvertes

- Les reçus de candidats et d'opérations existants dans Gaia peuvent-ils imposer ces distinctions sans créer une seconde machine à états concurrente ?
- Quelles lacunes Streeling faut-il combler en amont avant la synchronisation canonique de Learn ?
