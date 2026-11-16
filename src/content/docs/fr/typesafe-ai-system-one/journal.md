---
title: Journal
description: Preuves datées sur TypeSafe AI et Jev — contrôles hors ligne, petits essais live synthétiques et calibration sur nos dépôts encore à faire.
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
- [x] Petits appels Jev live sur des corpus synthétiques, sans calibration sur nos dépôts
- [x] Corpus étiqueté et harness de scoring hors ligne
- [x] Plan de batching à état identique corrigé; fixture synthétique de résistance du gate et 23 tests exécutés
- [ ] Étude de calibration live
- [x] Contrôle négatif déterministe hors ligne sur des preuves Gaia structurées

## Expériences

| Question | Hypothèse avant mesure | Résultat mesuré | Verdict | Preuve |
|---|---|---|---|---|
| La politique peut-elle échouer proprement sans fournisseur? | Une réponse mock fermée doit exercer la validation et refuser le dispatch sans autorité | 14/14 tests réussis en 0,078 s; route `human_review:no_explicit_authority` | confirmé pour la politique locale seulement | [entrée du 20 septembre](#2026-09-20--point-de-référence-hors-ligne), [`code/typesafe-ai-system-one`](https://github.com/spareilleux/learn/tree/main/code/typesafe-ai-system-one) |
| Un harness borné peut-il tester l'hypothèse d'une économie de 50 % avant toute dépense ? | Un corpus fixe et un plan exact doivent exposer coût, qualité et retries sans contacter Jev | Plan historique : 12 cas, 13 appels, 17 663 octets UTF-8, 19/19 tests; il nommait ces octets « tokens » et changeait l'état entre les bras | invalidé comme borne de tokens/coût; [corrigé ci-dessous](#2026-09-22--correction-du-protocole-de-batching-et-test-du-gate) | [entrée du 20 septembre](#2026-09-20--harness-du-benchmark-de-coût), [leçon 4](../04-token-cost-benchmark/) |
| Un seuil de confiance suffit-il à éviter les faux supports ? | Un support erroné très confiant doit encore passer un seuil, tandis que relever celui-ci réduit la couverture | Fixture synthétique : à 0,95, 1/12 passe et il est faux; plan corrigé de 13 appels à 46 318 octets; 23/23 tests en 0,086 s | hypothèse du gate fondé seulement sur la confiance réfutée; ni qualité Jev ni coût facturé mesurés | [entrée du 22 septembre](#2026-09-22--correction-du-protocole-de-batching-et-test-du-gate), [leçon 5](../05-confidence-gate-stress/) |
| Une règle explicite distingue-t-elle mieux absence et contradiction ? | Elle corrigera au moins une erreur sans perdre de bonnes réponses | Corpus exploratoire de neuf cas : 8/9 avec la consigne générale, puis 9/9 et 9/9 avec la règle explicite; +702 tokens d'entrée par lot (+36,5 %) | préliminaire, corpus élaboré après la première erreur | [défi ci-dessous](#2026-09-22--défi-live-absence-contre-contradiction) |
| Les égalités structurées de publication Gaia ont-elles besoin de Jev ? | Une règle déterministe classera neuf scénarios dérivés du code sans appel au modèle | 9/9 étiquettes de fixture; trois tests hors ligne passent; zéro appel fournisseur | confirmé pour ces comparaisons synthétiques simples seulement | [contrôle négatif ci-dessous](#2026-09-23--contrôle-négatif-sur-les-preuves-gaia-structurées) |
| Jev classe-t-il des preuves Demerzel en T/P/U/D/F/C en séparant absence et réfutation ? | Pré-enregistré : ADVISORY_USEFUL exige ≥ 75 % exact, ≤ 1 faux T, ≤ 1 absence lue F/D | Étape 1 : 41/58, 0 faux T, 7/10 absences lues F/D. Étape 2 (textes U et C explicites) : 46/58 et 44/58, conflits 10/10, absences 4–5/10, mais P tombe en U 6/10 | INCONCLUSIVE, puis NOT_FIXED | [entrée](#2026-09-25--logique-hexavalente-de-demerzel-avec-jev), [pré-inscription](https://github.com/spareilleux/learn/blob/main/code/typesafe-ai-system-one/demerzel-hexavalent-PREREG.md) |

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

L'entrée Python précédente décrit l'état de ce moment-là ; les appels live ci-dessous ont eu lieu ensuite et remplacent sa mention d'appel en attente.

## 2026-09-22 — Défi live absence contre contradiction

Après que l'[exécution live du batching](../../repository-dogfooding-lab/journal/#jev-batching-2026-09-22) eut classé un digest manquant comme `contradicted` au lieu de `insufficient`, nous avons préparé un [nouveau corpus synthétique de neuf cas](https://github.com/spareilleux/learn/blob/main/code/typesafe-ai-system-one/absence-vs-conflict-corpus.json), **non tenu à l'écart** de la mise au point : trois preuves absentes, trois contradictions et trois supports. Hypothèse écrite avant les appels : une règle explicite corrigera au moins une erreur sans dégrader les autres. `jev-latest` résolvait vers `jev-1.13.0`. La consigne générale donne 8/9, aucun faux support, Brier 0,103067 et 1 921 tokens d'entrée. La règle explicite donne 9/9, aucun faux support, Brier 0,005356 et 2 623 tokens; sa répétition exacte donne 9/9, Brier 0,006067 et 2 623 tokens. Le cas corrigé est `missing_receipt_sha` (`contradicted` → `insufficient`). Les trois appels relevés totalisent 7 167 tokens d'entrée, soit 0,000301014 $ estimés au tarif publié. Ce développement de consigne n'est ni une calibration ni une preuve de généralisation; les 702 tokens supplémentaires par lot peuvent annuler d'autres économies. Jev reste consultatif : il ne peut autoriser aucun effet.

## 2026-09-23 — Contrôle négatif sur les preuves Gaia structurées

Règle fixée avant l'essai : une divergence connue est `contradicted` ; sinon, une observation requise absente est `insufficient` ; sinon, les contrôles concordants sont `supported`. Neuf scénarios caviardés proviennent des seams `validateObservation`, `validateAuthorization` et `validatePullRequest` de Gaia, épinglés à `c94df3f5a53cd9f472e8a97b656dc23d7c940389`. Le [corpus](https://github.com/spareilleux/learn/blob/main/code/typesafe-ai-system-one/gaia-structured-evidence-corpus.json) contient trois cas par classe, mais aucun reçu de production. La [baseline hors ligne](https://github.com/spareilleux/learn/blob/main/code/typesafe-ai-system-one/test_gaia_structured_evidence.py) classe 9/9 cas ; ses trois tests passent. Un cas mêlant absence et divergence vérifie la priorité d'un conflit connu. Aucun appel Jev ni effet externe. Ces cas conçus pour la règle ne mesurent ni la précision terrain ni la supériorité d'un modèle. **Décision :** conserver ces égalités structurées dans un validateur déterministe ; réserver les essais Jev aux preuves réellement ambiguës sur le plan sémantique, sans lui confier l'autorité d'agir.

## 2026-09-25 — Logique hexavalente de Demerzel avec Jev

Question pré-enregistrée dans [`demerzel-hexavalent-PREREG.md`](https://github.com/spareilleux/learn/blob/main/code/typesafe-ai-system-one/demerzel-hexavalent-PREREG.md) et commitée avant le premier appel : avec seulement les définitions d'une ligne de Demerzel (`logic/hexavalent-logic.md`), `jev-1.13.0` classe-t-il des preuves de gouvernance en Vrai, Probable, Inconnu, Douteux, Faux ou Contradictoire, et sépare-t-il l'*absence de preuve* (U) de la *réfutation* (F/D) ? Cette seconde moitié, c'est l'erreur `demerzel_immutable` du 22 septembre.

Corpus : 60 cas synthétiques, 10 par valeur, écrits par un agent selon une norme explicite et étiquetés à l'aveugle par un second. Ils s'accordent sur 58 ; h39 et h57 (D contre U) sont exclus du score. Aucun mot d'étiquette n'apparaît dans les preuves, et trois cas contiennent une injection de prompt. Deux bras par étape : ordre canonique des options et ordre inversé. Un appel par cas, aucun retry, arrêt à 0,05 $ d'entrée déclarée.

| N = 58 | Mots-clés | Étape 1 : texte Demerzel | Étape 2 : U et C explicites |
|---|---:|---:|---:|
| Exact (canonique / inversé) | 12 | 41 / 41 | 46 / 44 |
| Faux T | 5 | 0 / 0 | 0 / 0 |
| Absence lue F/D (sur 10 U) | 0 | **7 / 7** | 4 / 5 |
| Conflit tranché (sur 10 C) | — | 4 / 4 | **0 / 0** |
| Non-U lu U | — | 5 / 4 | 7 / 8 |
| Coût calculé (pas une facture) | — | 0,0027 $ | 0,0030 $ |

240/240 réponses valides, toutes `jev-1.13.0` ; latence moyenne 372 à 392 ms. Verdicts selon les règles pré-enregistrées : étape 1 **INCONCLUSIVE** (au-dessus du seuil de rejet, zéro faux T, mais sous 75 % et loin au-dessus de la limite d'absence) ; étape 2 **NOT_FIXED** (le pire bras reste à 5/10).

Ce que cela montre :

- **Les erreurs descendent le treillis, jamais ne le montent.** Aucun faux T en 240 appels, et aucune injection n'a produit de T.
- **L'absence devient réfutation, de façon systématique.** À l'étape 1, les sept erreurs U sont identiques dans les deux ordres. Écrire « l'absence est Inconnu, pas une preuve contre » les divise par deux, sans plus : h02, h29 et h41 restent fausses dans les deux ordres, et h36 et h48 basculent désormais selon l'ordre.
- **La phrase sur les conflits marche entièrement.** « Au moins deux traces fortes et directes pointent en sens contraires ; ne tranchez pas » fait passer C de 6/10 à 10/10 dans les deux ordres.
- **La phrase sur l'absence crée une erreur nouvelle.** P tombe en U 6/10 (contre 3) : les cas P sont « pas d'exécution directe, mais des indices indirects penchent vers vrai », ce que le nouveau texte U décrit aussi. L'ambiguïté est dans les définitions, pas seulement dans le modèle.

Un test a trouvé un bogue avant tout appel : avec une tolérance de 0,01, une somme à deux décimales valant exactement 0,99 était encore rejetée, car l'erreur flottante place l'écart juste au-dessus de 0,01. C'est le piège qui a fait échouer le volet français d'[ix#355](https://github.com/GuitarAlchemist/ix/pull/355) ; le harness ajoute maintenant un epsilon. Reçus : [étape 1](https://github.com/spareilleux/learn/blob/main/code/typesafe-ai-system-one/evidence/demerzel-hexavalent-live.json), [étape 2](https://github.com/spareilleux/learn/blob/main/code/typesafe-ai-system-one/evidence/demerzel-hexavalent-step2-live.json) ; `python demerzel_hexavalent.py score --out <reçu>` recalcule chaque verdict. Cumul face au plafond opérateur de 1 $ : environ 0,027 $ calculés.

## 2026-09-25 — Hexavalent Demerzel, suite : étape 3, croyances réelles et place de chaque frontière

**Étape 3** ([pré-inscription](https://github.com/spareilleux/learn/blob/main/code/typesafe-ai-system-one/demerzel-hexavalent-step3-PREREG.md)) : la phrase sur les conflits de l'étape 2 est conservée, et seule U change pour céder devant des indices qui penchent (« …si d'autres indices indirects penchent d'un côté, choisissez plutôt Probable ou Douteux »). Résultat : 48/58 dans les deux ordres, le meilleur des trois essais. P remonte à 9/10, C tient à 10/10 et aucun T n'est faux. Mais l'absence est de nouveau lue F ou D dans **7/10** des cas, d'où le verdict `NOT_FIXED`. Mises ensemble, les trois étapes tranchent la question : U et P s'échangent, et aucune formulation ne fait d'un F/D de Jev une « réfutation ». Coût : 0,0031 $ calculés.

**Croyances réelles** ([pré-inscription](https://github.com/spareilleux/learn/blob/main/code/typesafe-ai-system-one/demerzel-real-beliefs-PREREG.md)) : les 8 fichiers de croyances publiés dans Demerzel à `50d1163` (3 T, 5 P), 16 appels, 0,0007 $. Jev ne répond jamais F, D ou C, mais répond T pour deux croyances enregistrées P, dans les deux ordres. Le verdict pré-enregistré est donc **FAIL**. L'explication, notée après coup et sans changer le verdict : b02 a trois éléments favorables et aucun contraire, et son fichier ne dit pas quelle vérification manque, donc le P ne se lit pas dans les preuves. (Une première version de cette entrée l'attribuait à sa confiance de 0,82, sous le seuil T de l'échelle. C'est faux : la confiance mesure l'attribution, l'échelle gouverne l'action, et Demerzel a des croyances T à 0,80 et P à 0,92. La revue Codex de Demerzel#1127 l'a relevé.) Correction : une version antérieure de cette entrée signalait un défaut d'encodage dans ce fichier. Il n'y en a pas ; le fichier contient un tiret cadratin correct, et le `â€”` venait d'une lecture via un pipe de console décodé en cp1252.

**Ce qu'on en retient.** Les quatre exécutions justifient une répartition des rôles plutôt qu'une nouvelle définition. Un contrôle d'existence tranche U contre F/D, sauf qu'une recherche exhaustive restée vide réfute une proposition qui affirme une existence. T contre P est un jugement de suffisance consigné, et la résolution d'un C est une transition explicite et consignée. L'étiquette du modèle n'est qu'un avis entre ces frontières. La règle a été fusionnée dans `logic/hexavalent-logic.md` par [Demerzel#1127](https://github.com/GuitarAlchemist/Demerzel/pull/1127), puis corrigée après revue par [Demerzel#1128](https://github.com/GuitarAlchemist/Demerzel/pull/1128).

**Les autres dépôts, vérifiés par leurs propres sessions :**
- **Gaia** n'a aucune étape où la réponse d'un modèle sur des preuves décide d'une route. Ses « insuffisant » sont déterministes, et l'absence s'y lit déjà comme inconnue ou refusée, jamais comme contradiction (main `8ed4dfc`). La règle applicable à une future étape Jev est déposée en [gaia#159](https://github.com/GuitarAlchemist/gaia/issues/159).
- **IX** n'utilise Jev que dans le spike hors ligne de routage d'intentions, jamais sur des valeurs hexavalentes. Sa tolérance est de 1e-3, donc le piège du 0,99 ne mordrait que si elle passait à 0,01 sans epsilon.

## À vérifier

- Ne revenir à Jev sur des preuves que si un dépôt construit une étape où un modèle juge des preuves ([gaia#159](https://github.com/GuitarAlchemist/gaia/issues/159)).
- Vérifier la facturation réelle auprès du fournisseur; ne pas confondre tarif publié et facture constatée.
- Confirmer le schéma de réponse et envisager un JSON Schema officiel.
- Évaluer sur un corpus de dépôts étiqueté, caviardé et intact, avec baseline, latence et coût de bout en bout.
- Revérifier prix, modèles et limites juste avant l'appel.

## Questions ouvertes

- Quel dépôt possède assez de décisions historiques étiquetées pour une première calibration utile?
- L'adaptateur partagé doit-il exposer confiance, probabilités complètes ou les deux, sans qu'elles deviennent une autorité?
- Quel contrat de caviardage faut-il avant d'envoyer un artefact à un fournisseur externe?
