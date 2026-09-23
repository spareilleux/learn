---
title: Journal
description: Preuves détaillées du laboratoire de dogfooding, y compris sa propre méthode, ses matrices et ses décisions de promotion.
sidebar:
  order: 99
---

## Progression

- [x] Registre machine-readable et renderer déterministe
- [x] Cinq matrices générées
- [x] Invariants de promotion et test de sortie périmée
- [x] Premières opportunities classiques et agentiques
- [x] Méthode du cours traitée comme opportunity
- [x] Checks CI de parité des langues et de structure du journal
- [ ] Première revue contradictoire indépendante
- [ ] Premier candidat promu ou rejeté sur preuve de dépôt

## Expériences

| Question | Hypothèse avant mesure | Résultat mesuré | Verdict | Preuve |
|---|---|---|---|---|
| Un registre peut-il générer plusieurs vues sans laisser un score accorder l'autorité? | Renderer déterministe et invariants séparent priorité et promotion | 4 opportunities, 5 matrices, 6/6 tests en 0,002 s; score sans effet sur statut ni autorité | confirmé pour le tracer local | [entrée](#2026-09-20--premier-tracer-de-matrices), [`code/repository-dogfooding-lab`](https://github.com/spareilleux/learn/tree/main/code/repository-dogfooding-lab) |
| Jev peut-il réduire de 50 % le coût aval à qualité égale? | Un gate typé résout assez de cas sans faux support | Plan hors ligne : 12 cas, 13 appels, zéro retry, limite locale de 0,0021 $ estimée par les octets — pas un plafond de facturation; aucun résultat live | inconclusif | [benchmark TypeSafe](../../typesafe-ai-system-one/04-token-cost-benchmark/) |
| Un oracle de Pétri hors ligne expose-t-il le saut dangereux entre avis Jev et autorité ? | Le flux fondé sur le seul avis atteint un effet ; le flux protégé exige preuve indépendante et mandat d'implémentation | Faux support synthétique à 0,98 ; 3/3 tests C# ciblés et 1/1 test de parité de la fixture passent ; aucun replay sur un vrai dépôt | prometteur localement, non intégré | [leçon](05-jev-petri-authority/), [`JevEvidenceGateTests.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/Tests/JevEvidenceGateTests.cs) |

## 2026-09-20 — Premier tracer de matrices

Implémentation de `opportunities.json`, du validateur et du renderer avec la bibliothèque standard Python. Le registre contient Jev, la méthode Learn, un audit de seam hexagonal et une frontière RabbitMQ.

```text
python dogfood.py write
python dogfood.py check
python -m unittest -v
```

Résultat : `validated=4 matrices=current mirrors=current`; 6/6 tests en 0,002 s. Les tests refusent une promotion sans artefacts et une adoption sans verdict confirmé, et vérifient la parité EN/FR/ES ainsi que la structure des journaux. Aucun réseau externe ni mutation de dépôt.

## 2026-09-22 — Frontière d'autorité Jev × Pétri synthétique

Hypothèse posée avant mesure : si une classification Jev très confiante mène directement à un effet, un faux `supported` peut autoriser du travail ; des jetons séparés de preuve vérifiée et de mandat d'implémentation bloquent ce chemin. Baseline : le cas synthétique épinglé `gaia_design_authority` renvoie `supported` à 0,98 alors que l'attendu est `contradicted`.

Le test Python lie la fixture JSON partagée à la réponse synthétique. Le test C# rejoue `classify → authorize_from_advisory` dans le réseau non protégé, puis parcourt complètement le réseau protégé pour les trois combinaisons où manque au moins un jeton indépendant. Un chemin valide reste possible avec les deux jetons. Résultat local : 3/3 tests C# ciblés et 1/1 test de parité passent ; après régénération, `dogfood.py check` annonce `validated=5 matrices=current mirrors=current`. Aucun appel fournisseur, token facturé, effet en production ni replay Gaia/IX sur une révision exacte. Verdict : expérience de spécification prometteuse, pas encore admissible à l'incubation.

## À vérifier

- Confirmer le premier run CI hébergé des matrices, de la parité et des journaux.
- Mesurer le temps d'écriture avant d'affirmer que la méthode coûte moins cher.
- Faire une revue contradictoire indépendante du schéma et des scores.
- Exécuter la calibration Jev seulement avec approbation explicite de la dépense.
- Associer le réseau protégé à un seam public Gaia ou IX sur une révision exacte, rejouer le témoin dangereux et comparer avec un simple test de garde déterministe.
- Choisir un seam hexagonal exact ou rejeter l'opportunity.

## Questions ouvertes

- Quelles mesures prédisent qu'une découverte survivra à l'intégration?
- Ownership de l'opportunity et autorité de merge doivent-ils toujours être séparés?
- Quand réexaminer un rejet plutôt que le retirer définitivement?
