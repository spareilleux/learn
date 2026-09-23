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
| Un oracle de Pétri hors ligne expose-t-il le saut dangereux entre avis Jev et autorité ? | Le flux fondé sur le seul avis atteint un effet ; le flux protégé exige preuve indépendante et mandat d'implémentation | Faux support synthétique à 0,98 ; 3/3 tests C# ciblés et 1/1 test de parité de la fixture passent ; aucun replay sur un vrai dépôt | prometteur localement, non intégré | [entrée datée](#jev-petri-2026-09-22), [leçon](../05-jev-petri-authority/), [`JevEvidenceGateTests.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/Tests/JevEvidenceGateTests.cs) |
| La frontière d'autorité tient-elle sur un seam Gaia épinglé ? | Un mandat lié à une autre révision d'intention ne doit produire aucun effet ; retirer cette comparaison doit faire échouer un test déterministe | À `c94df3f`, mauvaise révision → `AuthorityInvalid` avant `commit` ; le mutant appelle `commit` et échoue | confirmé pour ce seam séquentiel seulement ; aucun nouveau défaut de production | [entrée](#gaia-seam-2026-09-22), [`gaia-publication-authority-check.mjs`](https://github.com/spareilleux/learn/blob/main/code/repository-dogfooding-lab/gaia-publication-authority-check.mjs) |
| Une consigne explicite sur les preuves absentes améliore-t-elle Jev ? | Corriger au moins une erreur initiale sans perdre les autres bonnes étiquettes | `jev-1.13.0` live : 8/9 initial, 9/9 explicite sur deux appels ; 1 921 contre 2 623 tokens d'entrée ; aucun faux `supported` | exploratoire, ni calibration de dépôt ni autorité | [entrée](#gaia-seam-2026-09-22), [corpus synthétique](https://github.com/spareilleux/learn/blob/main/code/typesafe-ai-system-one/absence-vs-conflict-corpus.json) |

## 2026-09-20 — Premier tracer de matrices

Implémentation de `opportunities.json`, du validateur et du renderer avec la bibliothèque standard Python. Le registre contient Jev, la méthode Learn, un audit de seam hexagonal et une frontière RabbitMQ.

```text
python dogfood.py write
python dogfood.py check
python -m unittest -v
```

Résultat : `validated=4 matrices=current mirrors=current`; 6/6 tests en 0,002 s. Les tests refusent une promotion sans artefacts et une adoption sans verdict confirmé, et vérifient la parité EN/FR/ES ainsi que la structure des journaux. Aucun réseau externe ni mutation de dépôt.

<a id="jev-petri-2026-09-22"></a>

## 2026-09-22 — Frontière d'autorité Jev × Pétri synthétique

Hypothèse posée avant mesure : si une classification Jev très confiante mène directement à un effet, un faux `supported` peut autoriser du travail ; des jetons séparés de preuve vérifiée et de mandat d'implémentation bloquent ce chemin. Baseline : le cas synthétique épinglé `gaia_design_authority` renvoie `supported` à 0,98 alors que l'attendu est `contradicted`.

Le test Python lie la fixture JSON partagée à la réponse synthétique. Le test C# rejoue `classify → authorize_from_advisory` dans le réseau non protégé, puis parcourt complètement le réseau protégé pour les trois combinaisons où manque au moins un jeton indépendant. Un chemin valide reste possible avec les deux jetons. Résultat local : 3/3 tests C# ciblés et 1/1 test de parité passent ; après régénération, `dogfood.py check` annonce `validated=5 matrices=current mirrors=current`. Aucun appel fournisseur, token facturé, effet en production ni replay Gaia/IX sur une révision exacte. Verdict : expérience de spécification prometteuse, pas encore admissible à l'incubation.

<a id="gaia-seam-2026-09-22"></a>

## 2026-09-22 — Seam Gaia épinglé et classification live des preuves

Le prochain gate de la leçon a été essayé sur le commit Gaia [`c94df3f`](https://github.com/GuitarAlchemist/gaia/blob/c94df3f5a53cd9f472e8a97b656dc23d7c940389/src/github-portfolio-publication.mjs). Le seam public `createGitHubCandidatePublicationAdapter.publish` observe le candidat, consomme une réponse d'autorité liée à `intent.revision`, puis appelle `commit`, `push` et `openPullRequest`. La place Pétri `implementation_authority` ne correspond qu'approximativement à cette autorisation : le petit réseau ne modélise ni signature, ni consommation concurrente, ni idempotence, ni crash, ni réconciliation GitHub.

Hypothèse avant mutation : une réponse `AUTHORIZED` liée à une autre révision ne doit effectuer aucune mutation ; retirer la comparaison des révisions doit amener le test ciblé à observer un `commit` simulé. Dans un worktree Gaia détaché et propre à `c94df3f`, le [checker portable](https://github.com/spareilleux/learn/blob/main/code/repository-dogfooding-lab/gaia-publication-authority-check.mjs) n'utilise que des effets injectés : mauvaise révision → `AuthorityInvalid`, appels `observe, consume` ; bonne révision simulée → reçu terminé, appels `observe, consume, commit, push, openPullRequest`. Le fichier de tests Gaia passe 8/8. Un nouveau test de mauvaise révision passe deux fois ; après retrait de `value.intentRevision !== intentRevision`, il échoue avec `['commit']`. La garde a été restaurée, sans diff du code source. À part, la suite Pétri passe 3/3 ; retirer l'arc `implementation_authority → authorize` fait échouer 1/3 test, puis sa restauration ramène 3/3.

Le simple test de garde déterministe détecte donc le défaut injecté sans le réseau. **Verdict :** conserver Pétri comme aide pédagogique et de spécification, pas comme composant runtime ; aucun défaut Gaia nouveau n'est démontré. La vraie autorité Ed25519, les acteurs concurrents, les crashes/retries et les effets GitHub n'ont pas été exercés. Aucun résultat Jev n'a été fourni à `publish`.

Un [corpus synthétique de neuf cas](https://github.com/spareilleux/learn/blob/main/code/typesafe-ai-system-one/absence-vs-conflict-corpus.json) « preuve absente contre preuve contradictoire » a été préparé après une erreur sur douze cas antérieurs : ce n'est **pas** un holdout intact. Avant les appels live sur ce corpus, l'hypothèse était qu'une consigne explicite corrigerait au moins une étiquette sans dégrader les huit autres. Dans le Playground TypeSafe, `jev-latest` résout vers `jev-1.13.0` : 8/9 initial, 9/9 avec critères explicites et 9/9 à la répétition, sans faux `supported`. Le SHA absent d'un reçu était classé à tort `contradicted`, puis correctement `insufficient`. Usage : 1 921 contre 2 623 tokens d'entrée (+36,5 %) ; au [tarif publié](https://docs.typesafe.ai/models), coût estimé de 0,000080682 $ contre 0,000110166 $ par appel capturé, **pas** une facture constatée. Neuf étiquettes synthétiques et deux essais ne prouvent ni calibration ni économie du workflow complet. Le modèle reste consultatif.

## 2026-09-23 — Contrôle négatif déterministe pour les reçus Gaia

Cette tranche vérifie si Jev apporte quelque chose aux égalités structurées du seam de publication Gaia épinglé. Une fixture de neuf cas caviardés, dérivés du code source, couvre le HEAD observé du candidat, la révision du mandat consommé et le HEAD de la PR : trois concordances, trois conflits et trois preuves absentes. Avant l'essai, nous avons fixé la règle : conflit connu d'abord, puis observation requise absente, puis support. La baseline hors ligne classe 9/9 étiquettes de fixture et ses trois tests passent, sans appel Jev. Il ne s'agit ni de vrais reçus d'exécution ni d'un échantillon terrain inédit. Verdict : pas de modèle pour ces contrôles structurés ; les prochains essais Jev doivent viser l'ambiguïté sémantique, avec autorisation indépendante et sans effet pendant l'expérience. Voir le [journal TypeSafe](../../typesafe-ai-system-one/journal/) pour les limites.

## À vérifier

- Confirmer le premier run CI hébergé des matrices, de la parité et des journaux.
- Mesurer le temps d'écriture avant d'affirmer que la méthode coûte moins cher.
- Faire une revue contradictoire indépendante du schéma et des scores.
- Exécuter la calibration Jev seulement avec approbation explicite de la dépense.
- Faire revoir indépendamment la correspondance Pétri–Gaia ; forcer mandat dupliqué, observation périmée, crash après commit et réponse perdue avant toute prétention de sûreté concurrente.
- Comparer Jev à un parseur déterministe sur des reçus de dépôt inédits et caviardés ; mesurer le workflow complet et la facturation constatée avant toute incubation.
- Choisir un seam hexagonal exact ou rejeter l'opportunity.

## Questions ouvertes

- Quelles mesures prédisent qu'une découverte survivra à l'intégration?
- Ownership de l'opportunity et autorité de merge doivent-ils toujours être séparés?
- Quand réexaminer un rejet plutôt que le retirer définitivement?
