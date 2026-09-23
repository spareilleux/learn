---
title: "Benchmark du coût en tokens : batch, gate et rejet"
description: Mesurer si Jev réduit le travail des fournisseurs coûteux sans masquer une perte de qualité, des retries ou un déplacement de coût.
sidebar:
  order: 4
---

Un nombre de tokens plus faible n'est utile que si la tâche réussit encore. Cette leçon mesure donc le **coût par résultat accepté**, et non un pourcentage brut flatteur.

## L'hypothèse

> Sur un corpus étiqueté fixe, une décision Jev typée peut réduire d'au moins 50 % les entrées d'un fournisseur coûteux tout en conservant les critères d'acceptation et sans faux `supported`.

C'est une hypothèse, pas une promesse. Elle est réfutée si la qualité baisse, si la revue humaine efface l'économie ou si le travail est simplement déplacé vers un autre fournisseur.

## Le corpus et les trois modes

[`benchmark-corpus.json`](https://github.com/spareilleux/learn/blob/main/code/typesafe-ai-system-one/benchmark-corpus.json) contient 12 cas caviardés de GA, Gaia et Demerzel, étiquetés `supported`, `contradicted` ou `insufficient`. Un cas contient une tentative de prompt injection : elle reste une preuve, jamais une instruction.

```text
python jev_benchmark.py plan
python jev_benchmark.py mock
python -W error::ResourceWarning -m unittest -v
```

- `plan` n'appelle aucun réseau et affiche le nombre exact d'appels et un proxy de coût fondé sur les octets de la requête;
- `mock` valide le scoring avec une fixture explicitement non-Jev;
- `live` est une expérience autorisée séparément : un batch plus 12 appels à une question sur **le même état de 12 cas**, `jev-1.13.0` épinglé, zéro retry. Garder l'état constant isole l'effet du batching; l'essai de qualité avec un état par cas reste distinct.

Le plan local corrigé mesure 13 appels : 8 034 octets UTF-8 pour le batch et 38 284 pour les appels unitaires, soit 46 318 octets. Multipliés par le tarif vérifié le 22 septembre 2026, ces octets donnent un **proxy de coût de 0,001945356 $**, sous la limite locale de proxy de 0,0021 $. Les octets ne sont pas les tokens facturés, et le cadrage côté serveur est inconnu : **ceci ne garantit pas un plafond réel en dollars**. Vérifiez les contrôles de dépenses du compte et obtenez une autorisation distincte avant tout appel live.

## Comparer les catégories, pas des tokenizers différents

| Mesure | Pourquoi |
|---|---|
| Entrées et sorties Jev | Usage et coût Jev directs |
| Entrées, cache et sorties du fournisseur aval | Travail évité ou ajouté |
| Résultats acceptés | Dénominateur de l'efficacité réelle |
| Faux supports et calibration | Garde-fous contre les erreurs bon marché |
| Revues humaines, retries, latences p50 et p95 | Coût opérationnel déplacé |

Le résultat principal est le coût en dollars par résultat accepté sous le même quality gate. Une baisse de 50 % avec un faux support est un échec pour une route sensible à l'autorité.

## Protocole A/B live

Le mode live exige `TYPESAFE_API_KEY` et `JEV_BENCHMARK_APPROVED=YES`. Il réserve le fichier de preuve avant le premier appel, l'actualise après chaque réponse et ne retente jamais automatiquement. Sa garde locale fondée sur un proxy n'est **pas** un plafond de dépenses imposé par le fournisseur.

```text
python jev_benchmark.py live --out evidence/jev-live.json
```

Si la calibration passe, l'expérience suivante sera un gate aval : comparer un modèle coûteux fixe appelé sur tous les cas au même modèle appelé seulement quand Jev ne résout pas le cas sans risque. C'est là qu'une économie réelle de 50 % pourra être confirmée ou réfutée.

Avant un appel payant, essayez le [test hors ligne du gate de confiance](../05-confidence-gate-stress/) : un score élevé ne constitue pas une autorité.

## Sources primaires

- [Modèles Jev et prix actuels](https://docs.typesafe.ai/models)
- [Questions parallèles](https://docs.typesafe.ai/cookbooks/parallel_questions)
- [Limites documentées de Jev 1.13](https://docs.typesafe.ai/model-jaggedness/jev-1.13)
- [Cascade de développement logiciel](https://docs.typesafe.ai/cookbooks/sde_cascade)
- [Catégories de tokens OpenAI](https://platform.openai.com/docs/api-reference/responses/object#responses/object-usage)
- [Prompt caching Anthropic](https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching)
