---
title: Journal
description: Preuves datées du cours TypeSafe AI System One et Jev — faits officiels vérifiés, expérience mock déterministe, mesures live encore absentes et hypothèses à évaluer sur des corpus étiquetés.
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
- [ ] Appel Jev live
- [x] Corpus étiqueté et harness de scoring hors ligne
- [x] Plan de batching à état identique corrigé; fixture synthétique de résistance du gate et 23 tests exécutés
- [ ] Étude de calibration live

## Expériences

| Question | Hypothèse avant mesure | Résultat mesuré | Verdict | Preuve |
|---|---|---|---|---|
| La politique peut-elle échouer proprement sans fournisseur? | Une réponse mock fermée doit exercer la validation et refuser le dispatch sans autorité | 14/14 tests réussis en 0,078 s; route `human_review:no_explicit_authority` | confirmé pour la politique locale seulement | [entrée du 20 septembre](#2026-09-20--point-de-référence-hors-ligne), [`code/typesafe-ai-system-one`](https://github.com/spareilleux/learn/tree/main/code/typesafe-ai-system-one) |
| Un harness borné peut-il tester l'hypothèse d'une économie de 50 % avant toute dépense ? | Un corpus fixe et un plan exact doivent exposer coût, qualité et retries sans contacter Jev | Plan historique : 12 cas, 13 appels, 17 663 octets UTF-8, 19/19 tests; il nommait ces octets « tokens » et changeait l'état entre les bras | invalidé comme borne de tokens/coût; [corrigé ci-dessous](#2026-09-22--correction-du-protocole-de-batching-et-test-du-gate) | [entrée du 20 septembre](#2026-09-20--harness-du-benchmark-de-coût), [leçon 4](../04-token-cost-benchmark/) |
| Un seuil de confiance suffit-il à éviter les faux supports ? | Un support erroné très confiant doit encore passer un seuil, tandis que relever celui-ci réduit la couverture | Fixture synthétique : à 0,95, 1/12 passe et il est faux; plan corrigé de 13 appels à 46 318 octets; 23/23 tests en 0,086 s | hypothèse du gate fondé seulement sur la confiance réfutée; ni qualité Jev ni coût facturé mesurés | [entrée du 22 septembre](#2026-09-22--correction-du-protocole-de-batching-et-test-du-gate), [leçon 5](../05-confidence-gate-stress/) |
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

**Croyances réelles** ([pré-inscription](https://github.com/spareilleux/learn/blob/main/code/typesafe-ai-system-one/demerzel-real-beliefs-PREREG.md)) : les 8 fichiers de croyances publiés dans Demerzel à `50d1163` (3 T, 5 P), 16 appels, 0,0007 $. Jev ne répond jamais F, D ou C, mais répond T pour deux croyances enregistrées P, dans les deux ordres. Le verdict pré-enregistré est donc **FAIL**. L'explication, notée après coup et sans changer le verdict : b02 a trois éléments favorables et aucun contraire, et Demerzel la garde à P parce que sa confiance de 0,82 reste sous le seuil T de son échelle. Chez Demerzel, passer de P à T est un seuil, pas une étiquette lisible dans les preuves. La vérification a aussi révélé un défaut d'encodage dans ce fichier (`â€”` au lieu d'un tiret cadratin).

**Ce qu'on en retient.** Les quatre exécutions justifient une répartition des rôles plutôt qu'une nouvelle définition. Un contrôle d'existence tranche U contre F/D, l'échelle de confiance tranche T contre P, et la résolution d'un C est une transition explicite et consignée. L'étiquette du modèle n'est qu'un avis entre ces frontières. Cette règle est proposée pour `logic/hexavalent-logic.md` dans [une PR Demerzel](https://github.com/GuitarAlchemist/Demerzel/pull/1127).

**Les autres dépôts, vérifiés par leurs propres sessions :**
- **Gaia** n'a aucune étape où la réponse d'un modèle sur des preuves décide d'une route. Ses « insuffisant » sont déterministes, et l'absence s'y lit déjà comme inconnue ou refusée, jamais comme contradiction (main `8ed4dfc`). La règle applicable à une future étape Jev est déposée en [gaia#159](https://github.com/GuitarAlchemist/gaia/issues/159).
- **IX** n'utilise Jev que dans le spike hors ligne de routage d'intentions, jamais sur des valeurs hexavalentes. Sa tolérance est de 1e-3, donc le piège du 0,99 ne mordrait que si elle passait à 0,01 sans epsilon.

## À vérifier

- Fusionner la règle de répartition des rôles dans Demerzel ([Demerzel#1127](https://github.com/GuitarAlchemist/Demerzel/pull/1127)) ; ne revenir à Jev sur des preuves que si un dépôt construit une étape où un modèle juge des preuves ([gaia#159](https://github.com/GuitarAlchemist/gaia/issues/159)).
- Exécuter exactement un appel live après export de `TYPESAFE_API_KEY`, sans consigner le secret.
- Confirmer le schéma de réponse et envisager un JSON Schema officiel.
- Exécuter la calibration live de 13 appels uniquement après approbation explicite du plafond de 0,0021 $.
- Mesurer exactitude, calibration, taux de revue, coût et latence face à un baseline déterministe.
- Revérifier prix, modèles et limites juste avant l'appel.

## Questions ouvertes

- Quel dépôt possède assez de décisions historiques étiquetées pour une première calibration utile?
- L'adaptateur partagé doit-il exposer confiance, probabilités complètes ou les deux, sans qu'elles deviennent une autorité?
- Quel contrat de caviardage faut-il avant d'envoyer un artefact à un fournisseur externe?
