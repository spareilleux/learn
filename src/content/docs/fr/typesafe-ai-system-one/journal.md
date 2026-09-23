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
| Le batching à état identique réduit-il l'entrée Jev sur 12 cas synthétiques ? | Partager l'état doit coûter moins que le répéter sans changer les décisions | 11/12 décisions dans les deux bras; 2 487 tokens d'entrée en lot contre 14 939 en appels unitaires, soit 83,4 % de moins pour cette comparaison | prometteur ici, sans preuve d'économie de bout en bout | [essai live ci-dessous](#2026-09-22--essai-live-du-batching) |
| Une règle explicite distingue-t-elle mieux absence et contradiction ? | Elle corrigera au moins une erreur sans perdre de bonnes réponses | Corpus exploratoire de neuf cas : 8/9 avec la consigne générale, puis 9/9 et 9/9 avec la règle explicite; +702 tokens d'entrée par lot (+36,5 %) | préliminaire, corpus élaboré après la première erreur | [défi ci-dessous](#2026-09-22--défi-live-absence-contre-contradiction) |
| Les égalités structurées de publication Gaia ont-elles besoin de Jev ? | Une règle déterministe classera neuf scénarios dérivés du code sans appel au modèle | 9/9 étiquettes de fixture; trois tests hors ligne passent; zéro appel fournisseur | confirmé pour ces comparaisons synthétiques simples seulement | [contrôle négatif ci-dessous](#2026-09-23--contrôle-négatif-sur-les-preuves-gaia-structurées) |

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

## 2026-09-22 — Essai live du batching

Sur le même corpus synthétique de 12 cas, l'état a été envoyé une fois avec 12 questions, puis répété dans 12 appels unitaires. Jev obtient 11/12 dans chaque bras, sans faux `supported`. Usage déclaré par le fournisseur : 2 487 tokens d'entrée en lot contre 14 939 en appels unitaires (83,4 % de moins pour l'entrée Jev); scores de Brier multiclasses : 0,1505 et 0,1452. L'erreur persistante classe un digest ou une révision manquante comme `contradicted` au lieu de `insufficient`. Deux répétitions du lot et une inversion de l'ordre des choix conservent les décisions. Sur 17 appels relevés : 25 236 tokens d'entrée, soit 0,001059912 $ **estimés** au [tarif publié](https://docs.typesafe.ai/models); facturation réelle non vérifiée. Aucun gain global de workflow ni transfert d'autorité mesuré.

## 2026-09-22 — Défi live absence contre contradiction

Après cette erreur, nous avons préparé un [nouveau corpus synthétique de neuf cas](https://github.com/spareilleux/learn/blob/main/code/typesafe-ai-system-one/absence-vs-conflict-corpus.json), **non tenu à l'écart** de la mise au point : trois preuves absentes, trois contradictions et trois supports. Hypothèse écrite avant les appels : une règle explicite corrigera au moins une erreur sans dégrader les autres. `jev-latest` résolvait vers `jev-1.13.0`. La consigne générale donne 8/9, aucun faux support, Brier 0,103067 et 1 921 tokens d'entrée. La règle explicite donne 9/9, aucun faux support, Brier 0,005356 et 2 623 tokens; sa répétition exacte donne 9/9, Brier 0,006067 et 2 623 tokens. Le cas corrigé est `missing_receipt_sha` (`contradicted` → `insufficient`). Les trois appels relevés totalisent 7 167 tokens d'entrée, soit 0,000301014 $ estimés au tarif publié. Ce développement de consigne n'est ni une calibration ni une preuve de généralisation; les 702 tokens supplémentaires par lot peuvent annuler d'autres économies. Jev reste consultatif : il ne peut autoriser aucun effet.

## 2026-09-23 — Contrôle négatif sur les preuves Gaia structurées

Règle fixée avant l'essai : une divergence connue est `contradicted` ; sinon, une observation requise absente est `insufficient` ; sinon, les contrôles concordants sont `supported`. Neuf scénarios caviardés proviennent des seams `validateObservation`, `validateAuthorization` et `validatePullRequest` de Gaia, épinglés à `c94df3f5a53cd9f472e8a97b656dc23d7c940389`. Le [corpus](https://github.com/spareilleux/learn/blob/main/code/typesafe-ai-system-one/gaia-structured-evidence-corpus.json) contient trois cas par classe, mais aucun reçu de production. La [baseline hors ligne](https://github.com/spareilleux/learn/blob/main/code/typesafe-ai-system-one/test_gaia_structured_evidence.py) classe 9/9 cas ; ses trois tests passent. Un cas mêlant absence et divergence vérifie la priorité d'un conflit connu. Aucun appel Jev ni effet externe. Ces cas conçus pour la règle ne mesurent ni la précision terrain ni la supériorité d'un modèle. **Décision :** conserver ces égalités structurées dans un validateur déterministe ; réserver les essais Jev aux preuves réellement ambiguës sur le plan sémantique, sans lui confier l'autorité d'agir.

## À vérifier

- Vérifier la facturation réelle auprès du fournisseur; ne pas confondre tarif publié et facture constatée.
- Confirmer le schéma de réponse et envisager un JSON Schema officiel.
- Évaluer sur un corpus de dépôts étiqueté, caviardé et intact, avec baseline, latence et coût de bout en bout.
- Revérifier prix, modèles et limites juste avant l'appel.

## Questions ouvertes

- Quel dépôt possède assez de décisions historiques étiquetées pour une première calibration utile?
- L'adaptateur partagé doit-il exposer confiance, probabilités complètes ou les deux, sans qu'elles deviennent une autorité?
- Quel contrat de caviardage faut-il avant d'envoyer un artefact à un fournisseur externe?
