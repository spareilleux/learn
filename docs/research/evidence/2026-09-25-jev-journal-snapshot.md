---
title: Journal
description: Preuves datées du cours TypeSafe AI System One et Jev — sources officielles, tests hors ligne, premier essai live borné et hypothèses à évaluer sur de plus grands corpus étiquetés.
sidebar:
  order: 99
---

## Progression

- [x] Documentation officielle sur introduction, primitives, modèle, prix, confiance, API et patterns
- [x] Requête hors ligne, validateur de contrat et politique de routage sans autorité
- [x] Runner mock, corpus de 12 cas et 19 tests déterministes exécutés
- [x] Protocole live détaillé, à un appel, avec budget et conditions d'arrêt
- [x] Hypothèses bornées pour Gaia, GA, Demerzel, IX et TARS
- [x] Versions française et espagnole
- [x] Premier essai Jev live dans le Playground, sur des preuves synthétiques caviardées, sans lecture de clé API
- [x] Corpus étiqueté et harness de scoring hors ligne
- [x] Plan de batching à état identique corrigé; fixture synthétique de résistance du gate et 23 tests exécutés
- [x] Dépassement de l'usage déclaré reproduit hors ligne et arrêt du runner testé (25 tests)
- [x] Patterns Jev communautaires confrontés aux sources primaires, sans adopter leurs chiffres d'économie
- [x] Batch de 12 questions comparé live à 12 appels unitaires avec le même état; deux répétitions et une permutation des options
- [x] Routage d'intents GA en live côté IX : 126 appels pré-enregistrés, verdict `COMPETITIVE_WITH_HEAD` ([ix#354](https://github.com/GuitarAlchemist/ix/pull/354))
- [x] Robustesse du routage côté IX : ordre des options, français, espagnol et corpus aveugle, 506 appels pré-enregistrés ([ix#355](https://github.com/GuitarAlchemist/ix/pull/355))
- [x] Runner API à un appel validé en live sur le modèle épinglé, sans retry et avec refus local de l'autorité
- [ ] Étude de calibration live

## QA

| Attendu | Observé | Où | Mesure | Statut |
|---|---|---|---|---|
| Arrêter les appels suivants quand l'usage déclaré dépasse le proxy local de coût | L'ancienne boucle terminait toutes les requêtes sans contrôler l'usage cumulé | [`jev_benchmark.py` à la révision examinée](https://github.com/spareilleux/learn/blob/b86115b25fdd2e043bfaf5983c1a315f9b7ab968/code/typesafe-ai-system-one/jev_benchmark.py#L292-L306) | Stub hors ligne : première réponse à 50 001 tokens d'entrée, mais 13 appels exécutés | Reproduit; correction locale testée, non publiée |

## Expériences

| Question | Hypothèse avant mesure | Résultat mesuré | Verdict | Preuve |
|---|---|---|---|---|
| La politique peut-elle échouer proprement sans fournisseur? | Une réponse mock fermée doit exercer la validation et refuser le dispatch sans autorité | 14/14 tests réussis en 0,078 s; route `human_review:no_explicit_authority` | confirmé pour la politique locale seulement | [entrée du 20 septembre](#2026-09-20--point-de-référence-hors-ligne), [`code/typesafe-ai-system-one`](https://github.com/spareilleux/learn/tree/main/code/typesafe-ai-system-one) |
| Un harness borné peut-il tester l'hypothèse d'une économie de 50 % avant toute dépense ? | Un corpus fixe et un plan exact doivent exposer coût, qualité et retries sans contacter Jev | Plan historique : 12 cas, 13 appels, 17 663 octets UTF-8, 19/19 tests; il nommait ces octets « tokens » et changeait l'état entre les bras | invalidé comme borne de tokens/coût; [corrigé ci-dessous](#2026-09-22--correction-du-protocole-de-batching-et-test-du-gate) | [entrée du 20 septembre](#2026-09-20--harness-du-benchmark-de-coût), [leçon 4](https://spareilleux.github.io/learn/fr/typesafe-ai-system-one/04-token-cost-benchmark/) |
| Un seuil de confiance suffit-il à éviter les faux supports ? | Un support erroné très confiant doit encore passer un seuil, tandis que relever celui-ci réduit la couverture | Fixture synthétique : à 0,95, 1/12 passe et il est faux; plan corrigé de 13 appels à 46 318 octets; 23/23 tests en 0,086 s | hypothèse du gate fondé seulement sur la confiance réfutée; ni qualité Jev ni coût facturé mesurés | [entrée du 22 septembre](#2026-09-22--correction-du-protocole-de-batching-et-test-du-gate), [leçon 5](https://spareilleux.github.io/learn/fr/typesafe-ai-system-one/05-confidence-gate-stress/) |
| Le runner live s'arrête-t-il après un dépassement de l'usage déclaré ? | Sans contrôle après réponse, il poursuivra malgré le dépassement du proxy local | Avant correction, 13/13 appels simulés après une première réponse à 50 001 tokens; après, 1/13 et un reçu d'arrêt; 25/25 tests hors ligne passent | Défaut confirmé et corrigé localement; aucun coût fournisseur mesuré | [entrée du 22 septembre](#2026-09-22--gate-de-coût-après-réponse-hors-ligne), [`code/typesafe-ai-system-one`](https://github.com/spareilleux/learn/tree/main/code/typesafe-ai-system-one) |
| Le batching à état identique réduit-il d'au moins 50 % les tokens d'entrée déclarés sans changer les classes sur ce corpus ? | Un appel de 12 questions doit employer moins de la moitié des tokens de 12 appels unitaires avec le même état | Jev 1.13.0 live : 2 487 contre 14 939 tokens d'entrée (−83,4 %); les deux bras ont 11/12 classes correctes, aucun faux `supported`, une erreur commune | Confirmé pour ce seul corpus synthétique de 12 cas; ni qualité générale ni facture garanties | [essai live du 22 septembre](#2026-09-22--premier-essai-live-dans-le-playground), [`benchmark-corpus.json`](https://github.com/spareilleux/learn/blob/main/code/typesafe-ai-system-one/benchmark-corpus.json) |
| Jev sans exemples route-t-il les intents GA au moins aussi bien que la production ? | Pré-enregistré : KILL sous 83/110 in-scope ou 6/16 refus hors périmètre; `COMPETITIVE_WITH_HEAD` à partir de 87/110, 11/16 et macro-F1 0,787 | 106/110 in-scope, 16/16 hors périmètre refusés, macro-F1 0,967; McNemar contre la production p = 3,6e-8; 0,0040 $ calculés au tarif | `COMPETITIVE_WITH_HEAD` sur un TEST écrit par Gemini, en anglais; ne justifie pas de remplacer le router | [entrée du 23 septembre](#2026-09-23--routage-dintents-ga-dans-ix-126-appels-live), [ix#354](https://github.com/GuitarAlchemist/ix/pull/354) |
| Le runner API borné à un appel accepte-t-il le schéma live tout en refusant l'autorité ? | La requête épinglée doit produire une réponse valide sous le proxy local, tandis que le routage déterministe reste fail-closed | Jev 1.13.0; 506 tokens d'entrée et 77 de sortie; 354,5 ms de bout en bout; digest identique au mock; décision `human_review:no_explicit_authority`; un appel, aucun retry | confirmé uniquement pour cette requête et ce schéma live; facturation et arrêt cumulé des 13 appels non vérifiés | [entrée du 23 septembre](#2026-09-23--validation-du-runner-api-à-un-appel), reçu local ignoré |

## 2026-09-20 — Revue des sources officielles

- `jev-1.13.0` est le modèle concret annoncé; `jev-latest` est un alias mobile.
- Prix publié : 0,042 $/million de tokens d'entrée; sorties gratuites. C'est un fait daté, pas une promesse.
- Limites publiées : contexte total de 64k, 32k pour état plus question la plus longue, entrée texte, 250 000 tokens/s et 1 200 requêtes/minute; les limites peuvent changer.
- Aucun chiffre de l'annonce n'est traité comme une mesure sur nos dépôts.

## 2026-09-20 — Point de référence hors ligne

Windows 11, Python 3.14.2. Digest `67c1ee4bcd36b497f60872c0715d435b364c3b7743ad06f9be543071af044a1b`; décision `human_review:no_explicit_authority`; 14 tests réussis en 0,078 s. Aucun réseau externe; un test loopback hermétique prouve qu'une redirection s'arrête avant que le bearer token n'atteigne une seconde origine. La fixture s'identifie comme `mock-jev-course/1`, pas Jev.

```text
python typesafe_lab.py mock
python -W error::ResourceWarning -m unittest -v
```

## 2026-09-20 — Harness du benchmark de coût

Ajout de 12 cas caviardés de GA, Gaia et Demerzel, dont une prompt injection. Le `plan` historique indiquait 13 appels, zéro retry, 17 663 octets UTF-8 de requête appelés à tort borne de tokens, un proxy de coût fondé sur ces octets de 0,000741846 $ appelé à tort borne de coût et une limite locale de proxy de 0,0021 $ appelée à tort plafond strict. La suite combinée passait 19/19 tests en 0,078 s. Ces libellés et le protocole de batching ont été corrigés le 22 septembre 2026.

Le scorer mock affiche une exactitude parfaite de fixture, un Brier de 0,015 et un ratio entrées unitaires/batch de 2,4. Ces chiffres valident uniquement le scorer : la fixture est `mock-jev-benchmark/1`, aucun fournisseur n'a été appelé et ce ne sont pas des résultats Jev.

## 2026-09-22 — Correction du protocole de batching et test du gate

La revue des sources primaires a montré que l'ancien batch et les appels unitaires utilisaient des états de tailles différentes : leur ratio n'isolait donc pas le batching. Le plan corrigé garde le même état de 12 cas partout : 8 034 octets UTF-8 pour le batch, 38 284 pour 12 appels à une question, 46 318 au total. Au tarif consulté, 0,001945356 $ est un **proxy fondé sur les octets**, pas une facture fournisseur garantie. L'ancien ratio mock de 2,4 provenait d'une fixture arbitraire et a été retiré de la sortie actuelle.

Hypothèse écrite avant mesure : un seuil de confiance élevé ne suffira pas à éviter un faux `supported`. La fixture synthétique volontairement erronée confirme cette limite du gate : à 0,95, 1/12 passe et il est faux; à 0,99, aucun ne passe et les 12 partent en revue. `python jev_benchmark.py plan`, `python jev_gate_audit.py synthetic` et `python -W error::ResourceWarning -m unittest -v` ont été exécutés localement; 23/23 tests réussis en 0,086 s. Aucune clé lue, aucun appel Jev, aucune économie réelle de tokens mesurée. Voir la [note de recherche primaire](https://github.com/spareilleux/learn/blob/main/docs/research/2026-09-22-jev-experiment-design-primary-sources.md).

## 2026-09-22 — Python 3.10 à 3.14, hors ligne

Hypothèse avant l'essai : la suite hors ligne n'utilise que la bibliothèque standard, donc elle passe telle quelle de Python 3.10 à 3.14. Commande, sur un export neuf de `code/typesafe-ai-system-one` à `b3a9c16`, un interpréteur à la fois via uv 0.10.4 : `uv run --no-project --python <v> python -W error::ResourceWarning -m unittest`. Résultat sous Windows 11 : 23/23 tests passent sur 3.10.19, 3.11.14, 3.12.12, 3.13.12 et 3.14.3, en 0,104 à 0,132 s. La CI hébergée pour le même commit ([run 35804194871](https://github.com/spareilleux/learn/actions/runs/35804194871)) passe sur Ubuntu, Windows et macOS avec Python 3.14. Verdict : confirmé pour la suite hors ligne ; la CI ne teste toujours que 3.14. Aucune clé d'API n'a été lue et aucun fournisseur appelé : l'appel live et la calibration de 13 appels attendent toujours la `TYPESAFE_API_KEY` de l'opérateur et une approbation explicite du plafond, qui sont des décisions humaines.

## 2026-09-22 — Gate de coût après réponse, hors ligne

Hypothèse avant mesure : le runner à 13 appels vérifie son proxy de coût fondé sur les octets uniquement avant l'envoi; une première réponse déclarant plus que son équivalent de 50 000 tokens n'arrêtera pas les appels suivants. Un stub a renvoyé une première réponse conforme avec 50 001 tokens d'entrée. Avant correction, le runner a exécuté les 13 appels et marqué le reçu `complete`; le nouveau test de régression échouait comme prévu. Après ajout d'un contrôle de l'usage cumulé, un seul appel a été effectué, le statut `stopped-reported-usage-proxy` a été conservé et aucun autre envoi n'a suivi. Une fixture sous le seuil termine toujours les 13 appels. `python -W error::ResourceWarning -m unittest -v` passe 25/25 tests sous Windows 11, Python 3.14.3. Aucune clé, aucun réseau et aucun coût fournisseur. Cet arrêt **après réponse** n'est pas une borne de facturation avant appel : le premier appel peut déjà dépasser le proxy, et le tarif du compte reste inconnu.

## 2026-09-22 — Revue des patterns communautaires, pas un benchmark Jev

Ce [panorama Reddit](https://www.reddit.com/r/LLMDevs/comments/1wko2e5/i_reviewed_287_opensource_jev_projects_here_are/) suggère trois pistes. La [note fondée sur les sources primaires](https://github.com/spareilleux/learn/blob/main/docs/research/2026-09-22-jev-community-patterns-primary-sources.md) vérifie leurs dépôts : [compaction extractive des appels outil](https://github.com/tamaratran/fast-jev-compaction), [journal d'exécution où Jev ne donne qu'un avis sémantique](https://github.com/qkal/Canny) et [routage modèle/effort sous politique locale avec contexte complet pour l'exécuteur](https://github.com/0xNatoshi/jev-codex-router). Ce sont des patterns d'implémentation, pas des gains mesurés chez nous. Les prochains essais proposés comparent rétention des preuves, faux achèvements et coût total du routage à des baselines déterministes sur des fixtures caviardées GA/Gaia/Demerzel/IX. Preuves obligatoires, autorité et actions finales restent dans le code et chez les humains. Aucun chiffre communautaire de latence, de projets ou d'économies n'a été reproduit.

[AnyJev](https://github.com/nokia-applied-research/AnyJev), suggéré séparément, constitue un comparateur indépendant : décisions typées à partir des probabilités du prochain token d'un modèle existant, correction des biais de position/prior (L0), puis calibration par température avec étiquettes (L1). Ce n'est ni Jev ni un remplacement direct. Son [contrat de niveaux](https://github.com/nokia-applied-research/AnyJev/blob/main/docs/levels.md) précise que L0 n'est pas calibré et que L1 demande environ 100 à 500 exemples étiquetés par question; nos 12 cas sont insuffisants. L'essai proposé compare règles déterministes, Jev et AnyJev local sur les mêmes questions caviardées, avec permutation des options et jeu de calibration tenu à part : exactitude, score de Brier, abstention, latence et coût total. Aucun modèle n'a été téléchargé ni exécuté; les chiffres publiés par le projet n'ont pas été reproduits.

## 2026-09-22 — Premier essai live dans le Playground

Hypothèse posée avant les appels : un batch sur le même état de 12 cas réduira d'au moins 50 % les tokens d'entrée déclarés par rapport à 12 questions isolées, sans changer les classes. Le corpus est le fichier synthétique et caviardé [`benchmark-corpus.json`](https://github.com/spareilleux/learn/blob/main/code/typesafe-ai-system-one/benchmark-corpus.json); aucun fichier privé, identifiant ou clé API n'a été envoyé. Le compte disposait d'assez de crédits mensuels, ne présentait aucune consommation préalable et avait la recharge automatique désactivée. Tarif affiché : 0,042 $ par million de tokens d'entrée, sortie gratuite. `jev-latest` s'est résolu en `jev-1.13.0` dans chaque réponse. L'essai a utilisé l'interface du Playground, **pas** le runner `jev_benchmark.py live` : son arrêt sur dépassement n'est donc pas validé.

Premier appel Noul : une PR synthétique en brouillon et en échec CI reçoit 0,01 (`input_tokens=349`, `output_tokens=21`, évaluation 96 ms). Puis 13 appels à état identique : le batch déclare 2 487 tokens d'entrée, 566 de sortie et 120 ms d'évaluation; les 12 appels unitaires totalisent 14 939 tokens d'entrée, 599 de sortie et 1 612 ms d'évaluation cumulée. Le ratio d'entrée est de 6,01:1, soit **83,4 % de tokens d'entrée en moins** pour le batch. Au tarif affiché, les coûts *estimés* sont respectivement 0,000104454 $ et 0,000627438 $, pas des montants facturés confirmés. Les deux bras rendent les mêmes 12 classes : 11/12 correctes, aucun faux `supported`; score de Brier multiclasse 0,1505 pour le batch contre 0,1452 en unitaire. Au seuil de confiance de 0,95, 5/12 passeraient et tous sont corrects ici, mais ce petit corpus ne définit aucun seuil sûr. Les identifiants exacts des requêtes et les probabilités par cas restent dans un reçu local non publié.

L'erreur commune est importante : `demerzel_immutable` n'a ni digest ni révision immuable; son étiquette attendue est `insufficient`, mais les deux bras renvoient `contradicted` (confiance 0,70 et 0,71). Une absence de preuve n'est pas une preuve du contraire. Deux répétitions du batch conservent les 12 classes, avec des écarts maximaux de probabilité de 0,04 et 0,05. Une inversion de l'ordre des trois options dans un autre batch conserve aussi les 12 classes. Chacun de ces trois appels déclare 2 487 tokens d'entrée et 566 de sortie. Ce sont seulement trois observations répétées et une permutation, **pas** une étude de calibration ni une preuve de déterminisme général.

Sur les 17 appels au total (préliminaire, comparaison de 13 appels, deux répétitions et une permutation), les réponses déclarent 25 236 tokens d'entrée. Le coût théorique au tarif affiché est 0,001059912 $. Juste après, la page Usage affichait encore zéro requête, zéro token et 0,00 $, en précisant que les statistiques peuvent être différées : la dépense réellement comptabilisée reste **à vérifier**. Aucun réglage de recharge ou de paiement n'a été modifié. Jev n'a reçu aucune autorité de fusion ou d'implémentation.

## 2026-09-23 — Routage d'intents GA dans IX, 126 appels live

Hypothèse et règle de décision ont été pré-enregistrées avant tout appel dans le [`RESULTS.md` de ix#354](https://github.com/GuitarAlchemist/ix/blob/3427f7b320e224458754a27b4a950e731caa0757/state/router-spike/RESULTS.md) : Jev (`jev-1.13.0`, épinglé), interrogé sans exemples avec une question `Choice` par prompt (16 intents plus `__none__`), route-t-il le held-out de GA au moins aussi bien que le router de production, et à quelle distance du head appris ? L'essai a été mené par la session IX avec son runner `jev/run-live.ps1`, pas depuis ce dépôt : exactement 126 appels, aucun réessai, clé lue dans l'environnement sans être affichée, arrêt prévu dès que l'usage déclaré cumulé dépasserait 0,05 $.

Résultat : 126/126 réponses valides, toutes `jev-1.13.0`. Usage déclaré : 94 974 tokens d'entrée et 26 176 de sortie, soit 0,0040 $ au tarif de 0,042 $/M; c'est un calcul, pas une facture. Latence moyenne 264 ms, maximum 399 ms.

| Mesure (même TEST de 126 prompts) | Production | Head appris | Jev sans exemples |
|---|---|---|---|
| Exactitude in-scope | 83/110 | 90/110 | **106/110** |
| Refus hors périmètre | 6/16 | 11/16 | **16/16** |
| Macro-F1 (16 intents) | 0,745 | 0,817 | **0,967** |

Verdict pré-enregistré : `COMPETITIVE_WITH_HEAD`, la bande la plus haute prévue. Test apparié contre la production : Jev a raison et la production tort 36 fois, l'inverse 3 fois, McNemar exact p = 3,6e-8. Les 4 erreurs sont des cas limites; une seule est confiante (h-101 « does F G Am belong to C major? », 0,97). La confiance vaut 1,0 sur 109/126 réponses et aucun seuil exploratoire n'améliore l'exactitude : aucun n'est retenu.

Limites : le TEST a été écrit par Gemini et peut reprendre les descriptions d'intents que Jev lisait; pas de trafic réel; anglais seulement; ordre des options fixe. Comme la pré-inscription le prévoyait, ce résultat ne justifie **pas** de remplacer le router : il remplacerait un produit scalaire local par un appel hébergé à chaque requête. Pistes suivantes, chacune à pré-enregistrer à part : Jev comme étiqueteur du journal shadow sur trafic réel, et comme escalade des décisions du head à faible marge. La revue Codex de ix#354 a relevé trois P2 (tokens des réponses rejetées non comptés, corpus non figé, identifiants de reçu hors plan); d'après la session IX, ils sont corrigés et le rescoring du même reçu donne le même verdict et le même usage.

Suivi du plafond opérateur de 1 $ : les 17 appels Playground du 22 septembre (25 236 tokens d'entrée, 0,001059912 $ théoriques) plus ces 126 appels (0,003988908 $) font 143 appels et environ **0,0050 $** calculés au tarif affiché. La dépense réellement facturée reste **à vérifier**.

## 2026-09-23 — Étape 2 : le résultat de routage résiste-t-il aux perturbations ? ([ix#355](https://github.com/GuitarAlchemist/ix/pull/355))

L'étape 1 reposait sur un seul TEST, écrit par Gemini à partir de définitions proches du texte des options que Jev lit. Un effet d'écho était donc plausible. Quatre volets ont été [pré-enregistrés](https://github.com/GuitarAlchemist/ix/blob/755bc43eda1babb06fed609039de283e9b9a670c/state/router-spike/RESULTS.md) avant tout appel (même modèle `jev-1.13.0`, mêmes options, un prompt par état) :

| Volet | Verdict pré-enregistré | In-scope | Hors-scope |
|---|---|---|---|
| ordre des options inversé | ROBUST | 106/110 | 16/16 |
| traduction française | KILL | 100/110 | 15/16 |
| traduction espagnole | ROBUST | 103/110 | 16/16 |
| nouveau corpus, auteur ne voyant que les ID d'intents | ROBUST | 110/112 | 16/16 |
| head appris sur le nouveau corpus (rapporté) | — | 80/112 | 12/16 |

L'hypothèse d'écho n'est pas confirmée. Sur le corpus aveugle, Jev monte et le head entraîné baisse (34 prompts discordants contre 0, McNemar p ≈ 1,2e-10). Inverser l'ordre des options ne change qu'une seule décision.

Le français est KILL pour une raison de format, pas de routage. Trois réponses avaient des probabilités dont la somme vaut 0,99, parce que Jev arrondit à 2 décimales et que notre tolérance était de 1e-3 ; un quatrième appel a expiré. La relecture indépendante de l'étape 1 avait prédit ce risque d'arrondi. En post-hoc, le français serait dans la bande ROBUST (101/110), mais le verdict pré-enregistré est maintenu. Leçon : accepter une tolérance de 0,01 sur la somme, et pré-enregistrer une règle pour les timeouts.

506 appels, 381 914 tokens d'entrée déclarés, 0,016 $ calculés (pas une facture) ; l'usage de l'appel expiré est inconnu. Toujours pas de trafic réel : c'est l'étape suivante (log shadow de GA).

## 2026-09-23 — Ce que les runs de routage IX apprennent sur la méthode

Les deux entrées IX ci-dessus donnent des résultats. Celle-ci porte sur la manière de les obtenir, car deux des leçons valent pour toute expérience Jev.

**La règle de décision a été réparée avant le premier appel, pas après.** Le premier jet de la pré-registration a été confié à un relecteur indépendant avant qu'aucune requête ne quitte la machine. Il a trouvé la règle incohérente avec ses propres baselines : le score réel de la production, 83/110 = 0,7545, tombait *sous* la ligne de KILL à 0,755, si bien qu'une égalité avec la production aurait tué Jev ; les scores de 84 à 86/110 n'avaient aucun verdict ; le macro-F1 était déclaré primaire sans qu'aucune clause l'utilise. La règle a été réécrite en effectifs, avec une bande d'égalité explicite, et commitée avec le harness dans [efa904d](https://github.com/GuitarAlchemist/ix/commit/efa904d) avant les 126 appels. La révision est signalée dans le texte même (« revised the same day after an independent review found gaps — still pre-result ») ; ce n'est pas un commit séparé, la preuve d'ordre est donc que le commit de pré-registration précède celui des résultats ([c3a06c6](https://github.com/GuitarAlchemist/ix/commit/c3a06c6)).

**Un risque signalé mais corrigé à moitié reste un risque.** Le même relecteur avait prévenu que la tolérance de somme à 1 du validateur (1e-6) rejetterait des réponses simplement arrondies. Elle a été relâchée à 1e-3. Or Jev renvoie des probabilités à deux décimales : 17 valeurs arrondies peuvent sommer à 0,99. L'étape 1 n'est pas tombée dessus ; à l'étape 2, six réponses sommaient exactement à 0,99, dont trois dans le volet français, qui avec un timeout ont franchi la ligne « plus de 2 invalides » : le français est `KILL` selon la règle enregistrée alors que son routage (100/110, 15/16 ; 101/110 en post-hoc) était dans la bande robuste. Le verdict n'a pas été réécrit. Leçon pour la prochaine pré-registration : tolérance d'au moins 0,01, et une règle écrite d'avance pour les timeouts.

**Le soupçon d'écho avait une cause visible.** Le prompt utilisé en juin pour faire écrire le TEST par Gemini (`state/router-spike/_heldout-authoring-prompt.txt`) définissait chaque intent avec des mots proches du texte des options que lit Jev : un lecteur de ces définitions partait avec un avantage. Le corpus aveugle de l'étape 2 a été écrit par un agent qui ne recevait que les ID d'intents, et ses étiquettes ont été figées telles que livrées. Le head appris y a été re-mesuré avec un script qui reproduisait d'abord exactement ses chiffres de l'étape 1 (90/110, 10/16) : sa chute à 80/112 tient au corpus, pas au script.

**La contrainte décisive n'est pas le coût.** À 264 ms et environ 0,00003 $ par requête, latence et prix sont négligeables à côté d'une réponse de chatbot. Ce qui décide si Jev peut router le trafic de GA, c'est que chaque message d'utilisateur partirait chez un tiers : c'est une décision de l'opérateur, pas une mesure, et elle conditionne l'expérience du log shadow.

## 2026-09-23 — Validation du runner API à un appel

La probe pré-enregistrée dans la leçon demande si l'API réelle renvoie le schéma épinglé tout en laissant l'autorité et les effets hors du modèle. Après la réussite de 14/14 tests ciblés en 0,091 s, `python typesafe_lab.py live --out live-result.json` a effectué exactement une requête, sans retry. Jev a renvoyé le modèle `jev-1.13.0`, 506 tokens d'entrée et 77 de sortie en 354,5 ms de bout en bout. Le digest de la requête correspond au mock hors ligne, et le routage déterministe renvoie `human_review:no_explicit_authority`.

Le proxy fondé sur les octets avant appel était de 0,000043848 $. L'application du tarif consulté de 0,042 $ par million de tokens d'entrée à l'usage déclaré donne 0,000021252 $; les sorties étaient alors affichées comme gratuites. Aucun de ces montants n'est une facture vérifiée. Le reçu local ignoré ne conserve que les métadonnées de décision validées, l'usage, la durée et le digest; ni la clé API ni la réponse brute n'ont été écrites. Cette mesure valide le schéma, le contrôle du modèle épinglé et le chemin fail-closed du runner à un appel, pas l'arrêt cumulé du benchmark séparé à 13 appels.

## À vérifier

- Exercer l'arrêt cumulé des 13 appels avec `jev_benchmark.py live` uniquement comme nouvelle expérience approuvée; la probe API à un appel n'a pas testé cette boucle.
- Confirmer le schéma de réponse et envisager un JSON Schema officiel.
- L'opérateur autorise au plus 1 $ au total pour les expériences Jev, pas un objectif de dépense. Recontrôler la facturation une fois les statistiques actualisées et tout plafond strict côté fournisseur avant d'élargir l'essai; le coût estimé et l'arrêt après réponse ne garantissent pas la facture.
- Dépense connue au 23 septembre : environ 0,021 $ calculés sur 650 appels (Playground et probe API à un appel de ce cours, étapes 1 et 2 du routage IX), pas une facture vérifiée. Un appel de l'étape 2 a expiré et son usage est inconnu.
- Effectuer une étude de calibration live plus large, à étiquettes indépendantes, avant d'interpréter la confiance comme une garantie ou d'adopter Jev dans un chemin de décision du dépôt.
- Mesurer exactitude, calibration, taux de revue, coût et latence face à un baseline déterministe.
- Réunir assez d'étiquettes indépendantes avant la comparaison AnyJev L1; commencer hors ligne par la stabilité à l'ordre des options et la baseline L0/heuristique.
- Revérifier prix, modèles et limites juste avant l'appel.

## Questions ouvertes

- Quel dépôt possède assez de décisions historiques étiquetées pour une première calibration utile?
- L'adaptateur partagé doit-il exposer confiance, probabilités complètes ou les deux, sans qu'elles deviennent une autorité?
- Quel contrat de caviardage faut-il avant d'envoyer un artefact à un fournisseur externe?


## Research snapshot provenance

Captured on 2026-09-25 from `src/content/docs/fr/typesafe-ai-system-one/journal.md` in the local learn worktree. Original file SHA-256: `0cf9183f1ba0e426ee08237539cb16a5caa5a1a986ab1491d7fe97548faa5508`. This evidence copy preserves the journal's dated claims, including entries not yet deployed; navigation links are expanded for this location. It is not a new experiment, independent validation, or a deployment of the course. Research ticket: https://github.com/GuitarAlchemist/.github/issues/80.

