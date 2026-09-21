---
title: Journal
description: Preuves datées du cours TypeSafe AI System One et Jev — faits officiels vérifiés, expérience mock déterministe, mesures live encore absentes et hypothèses à évaluer sur des corpus étiquetés.
sidebar:
  order: 99
---

## Progression

- [x] Documentation officielle sur introduction, primitives, modèle, prix, confiance, API et patterns
- [x] Requête hors ligne, validateur de contrat et politique de routage sans autorité
- [x] Runner mock et quatorze tests déterministes exécutés
- [x] Protocole live détaillé, à un appel, avec budget et conditions d'arrêt
- [x] Hypothèses bornées pour Gaia, GA, Demerzel, IX et TARS
- [x] Versions française et espagnole
- [ ] Appel Jev live
- [ ] Corpus étiqueté et étude de calibration

## Expériences

| Question | Hypothèse avant mesure | Résultat mesuré | Verdict | Preuve |
|---|---|---|---|---|
| La politique peut-elle échouer proprement sans fournisseur? | Une réponse mock fermée doit exercer la validation et refuser le dispatch sans autorité | 14/14 tests réussis en 0,078 s; route `human_review:no_explicit_authority` | confirmé pour la politique locale seulement | [entrée du 20 septembre](#2026-09-20--point-de-référence-hors-ligne), [`code/typesafe-ai-system-one`](https://github.com/spareilleux/learn/tree/main/code/typesafe-ai-system-one) |

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

## À vérifier

- Exécuter exactement un appel live après export de `TYPESAFE_API_KEY`, sans consigner le secret.
- Confirmer le schéma de réponse et envisager un JSON Schema officiel.
- Constituer un corpus étiqueté pour un dépôt avant toute modification de production.
- Mesurer exactitude, calibration, taux de revue, coût et latence face à un baseline déterministe.
- Revérifier prix, modèles et limites juste avant l'appel.
- La matrice CI Windows, Linux et macOS avec Python 3.14 est ajoutée; confirmer son premier résultat hébergé.

## Questions ouvertes

- Quel dépôt possède assez de décisions historiques étiquetées pour une première calibration utile?
- L'adaptateur partagé doit-il exposer confiance, probabilités complètes ou les deux, sans qu'elles deviennent une autorité?
- Quel contrat de caviardage faut-il avant d'envoyer un artefact à un fournisseur externe?
