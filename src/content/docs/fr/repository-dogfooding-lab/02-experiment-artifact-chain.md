---
title: Expérience et artifact chain
description: Construire une chaîne rejouable de l'observation au verdict, avec expérience bornée et revue indépendante.
sidebar:
  order: 2
---

Une expérience est utile quand une autre personne ou un autre agent peut établir exactement ce qui s'est passé sans faire confiance à l'auteur.

| Artefact | Contenu requis |
|---|---|
| Observation | Douleur concrète, source épinglée ou symptôme mesuré |
| Hypothèse | Affirmation directionnelle et falsifiable écrite avant la mesure |
| Baseline | Qualité, coût, latence ou surface de changement actuelle |
| Protocole | Corpus fixe, commandes exactes, limites et conditions d'arrêt |
| Preuve brute | Sorties, usage, hashes et environnement, sans secrets |
| Verdict | Confirmé, réfuté ou inconclusif selon les critères annoncés |
| Reçu de promotion | Autorité responsable, preuve exacte et étape réversible suivante |

Pour le software engineering classique, mesurez défauts, surface de fichiers modifiés, setup de test, p50/p95, récupération et charge opérationnelle. Pour l'agentique, ajoutez qualité acceptée, faux positifs, calibration, escalade, retries, tokens entrée/cache/sortie par fournisseur et dollars. N'additionnez pas des tokenizers différents.

Le reviewer cherche à réfuter : fuite du corpus, règle déterministe moins chère, coût humain déplacé, cas d'échec absent ou artefact ne correspondant pas à la révision testée.

<details>
<summary>Exercice : définir une économie de tokens de 50 %</summary>

Fixez un corpus et un modèle aval. Comparez son appel systématique à son appel seulement après un gate Jev. Conservez le même quality gate. Réfutez au premier faux support sensible à l'autorité ou si retries et revue humaine effacent l'économie.

</details>
