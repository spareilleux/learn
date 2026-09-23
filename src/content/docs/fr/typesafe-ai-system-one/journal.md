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

## À vérifier

- Exécuter exactement un appel live après export de `TYPESAFE_API_KEY`, sans consigner le secret.
- Confirmer le schéma de réponse et envisager un JSON Schema officiel.
- Exécuter la calibration live de 13 appels uniquement après approbation explicite du plafond de 0,0021 $.
- Mesurer exactitude, calibration, taux de revue, coût et latence face à un baseline déterministe.
- Revérifier prix, modèles et limites juste avant l'appel.

## Questions ouvertes

- Quel dépôt possède assez de décisions historiques étiquetées pour une première calibration utile?
- L'adaptateur partagé doit-il exposer confiance, probabilités complètes ou les deux, sans qu'elles deviennent une autorité?
- Quel contrat de caviardage faut-il avant d'envoyer un artefact à un fournisseur externe?
