---
title: TypeSafe AI System One et Jev — Mission
description: Composer des décisions probabilistes typées avec Jev, les valider hors ligne, exécuter une probe facultative au coût borné et cerner des usages utiles mais sans autorité dans Gaia, GA, Demerzel, IX et TARS.
sidebar:
  label: Mission
  order: 0
---

:::caution[Ce qui a été testé — et ce qui ne l'a pas été]
Ce cours s'appuie sur la [documentation officielle de TypeSafe AI](https://docs.typesafe.ai/introduction), sa [référence API](https://docs.typesafe.ai/api), la [page des modèles](https://docs.typesafe.ai/models) et l'[annonce de Jev](https://typesafe.ai/blog/introducing-system-one-models-and-jev), consultées le 20 septembre 2026. Le laboratoire hors ligne dans [`code/typesafe-ai-system-one`](https://github.com/spareilleux/learn/tree/main/code/typesafe-ai-system-one) a été exécuté localement avec Python 3.14.2 : **14 tests réussis**, et le routage mock a refusé le dispatch faute d'autorité explicite.

Aucun identifiant n'a été lu, aucune session console n'a été ouverte et aucun appel à l'API TypeSafe n'a été effectué. Tous les résultats live, temps de réponse, nombres de tokens, affirmations de calibration sur nos données et bénéfices propres à nos dépôts restent **à vérifier**.
:::

## Pourquoi j'apprends cela

Les agents de code savent produire du texte, des plans et des patchs. Nos dépôts contiennent aussi des décisions plus petites, répétées et consommées par du logiciel : classer un candidat Gaia, évaluer un résultat de recherche GA, signaler un dossier de gouvernance Demerzel, router une expérience IX ou désambiguïser une grammaire TARS. Un LLM peut répondre en JSON, mais le programme doit encore rejeter les valeurs inventées, mesurer l'incertitude et garder l'autorité hors de la prose.

[Jev](https://docs.typesafe.ai/introduction) adopte une approche plus étroite : un état, des questions typées, puis des réponses fermées. Le modèle choisit parmi les valeurs que nous définissons; notre code conserve les seuils, la composition et les effets. La forme est plus facile à valider, mais elle ne rend pas la décision vraie par elle-même.

## La thèse de sûreté

> Un modèle estime; du code déterministe valide, contrôle et agit.

- un `Choice` valide peut choisir la mauvaise option;
- une confiance élevée n'est pas une autorité;
- un alias mobile peut changer de comportement sans changement de code;
- un faible prix peut seulement rendre une mauvaise décision moins chère et plus fréquente;
- une réponse fournisseur ne doit jamais créer un grant Gaia, fusionner une PR ou modifier la gouvernance.

## Ce que vous allez construire

1. **Mock d'abord :** rejouer une réponse sauvegardée, valider ses formes fermées et ses distributions, puis appliquer la vraie politique de routage sans réseau ni clé.
2. **Une probe live facultative :** lire `TYPESAFE_API_KEY` dans l'environnement, estimer le budget d'entrée, faire exactement un appel, ne jamais imprimer la clé, puis consigner digest, modèle concret, usage, latence et décision.

## Plan

| # | Leçon | Résultat |
|---|---|---|
| 1 | [Des décisions, pas des chaînes](01-decisions-not-strings/) | Choisir entre Choice, Score et Noul sans confondre type et vérité |
| 2 | [Une expérience reproductible au coût borné](02-bounded-experiment/) | Exécuter le point de référence hors ligne et comprendre la probe facultative à un appel |
| 3 | [Cas d'usage dans nos dépôts](03-repository-use-cases/) | Choisir des seams utiles dans Gaia, GA, Demerzel, IX et TARS tout en préservant l'autorité |
| — | [Journal](journal/) | Faits mesurés, questions ouvertes et travail live restant |

## Prérequis

- [Python](https://docs.python.org/3/) 3.10 ou plus récent; le laboratoire n'utilise que la bibliothèque standard.
- JSON et des branchements ordinaires.
- Un compte TypeSafe et une clé API uniquement pour la probe facultative. Placez la clé dans `TYPESAFE_API_KEY`; ne la collez jamais dans une leçon, un fichier source, un transcript de terminal ou un chat.

## Sources primaires

- [Introduction](https://docs.typesafe.ai/introduction) et [démarrage rapide](https://docs.typesafe.ai/introduction/quickstart)
- [Primitives](https://docs.typesafe.ai/primitives), [confiance](https://docs.typesafe.ai/confidence) et [patterns](https://docs.typesafe.ai/patterns)
- [Modèles et prix](https://docs.typesafe.ai/models), [référence HTTP](https://docs.typesafe.ai/api) et [annonce de Jev](https://typesafe.ai/blog/introducing-system-one-models-and-jev)
