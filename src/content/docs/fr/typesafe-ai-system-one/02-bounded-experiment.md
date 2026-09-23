---
title: "2. Une expérience reproductible au coût borné"
description: Exécuter d'abord la fixture déterministe, examiner les tests du contrat et du routage, puis préparer un appel Jev facultatif avec garde locale sur la taille de requête, conditions d'arrêt et dossier de preuve.
sidebar:
  order: 2
---

L'expérience commence par une question falsifiable :

> Peut-on insérer une recommandation probabiliste typée dans une gate façon Gaia sans laisser le fournisseur créer de l'autorité ni un coût non borné?

L'hypothèse est précise : la même politique déterministe doit accepter une réponse fermée valide, refuser une option inventée, refuser des probabilités mal formées et router vers un humain quand l'autorité explicite manque. Un appel live mesurerait ensuite seulement le comportement du modèle.

## Phase A — point de référence hors ligne

```bash
cd code/typesafe-ai-system-one
python typesafe_lab.py mock
python -m unittest -v
```

Mesuré localement le 20 septembre 2026 avec Python 3.14.2 :

```text
{
  "mode": "mock",
  "model": "mock-jev-course/1",
  "decision": "human_review:no_explicit_authority",
  "request_sha256": "67c1ee4bcd36b497f60872c0715d435b364c3b7743ad06f9be543071af044a1b"
}

Ran 14 tests in 0.078s
OK
```

Ces tests prouvent uniquement les propriétés locales : validation de la fixture, refus sans autorité, refus d'un Choice inconnu et somme des probabilités égale à 1. Ils ne prouvent ni que TypeSafe a produit la fixture, ni que le seuil de 0,9 est calibré, ni que l'option connue est juste.

## Phase B — probe facultative à un appel

Ne collez pas la clé dans un argument de commande. Définissez `TYPESAFE_API_KEY` par le mécanisme secret de votre système, puis lancez :

```bash
python typesafe_lab.py live --out live-result.json
```

Le script :

- refuse avant tout accès réseau si la variable manque;
- construit une seule requête pour `jev-1.13.0`;
- compte les octets UTF-8 de la requête comme proxy local de taille, pas comme estimation des tokens facturés;
- refuse au-delà de 2 500 octets ou de son **proxy de coût par octets de 0,000105 $** au tarif consulté le 22 septembre 2026;
- envoie exactement une requête avec un timeout de 20 secondes;
- refuse les redirections afin de garder le bearer token lié à l'origine API configurée;
- ne réessaie jamais automatiquement après 429, 529, timeout ou panne réseau;
- n'imprime ni n'écrit l'en-tête d'autorisation;
- valide la réponse et exige le modèle épinglé exact avant le routage;
- exige une autorité prouvée par le code local de confiance, jamais par la réponse Noul du modèle;
- consigne date, modèle concret, usage, digest, proxy avant appel et décision, mais pas la réponse complète du fournisseur.

Le comptage des octets limite la taille locale de la requête. Ce n'est **pas** une borne démontrée des tokens ni des dollars facturés : le cadrage côté serveur et les contrôles de dépenses du compte sont distincts. Le coût observé doit utiliser `usage.input_tokens` et le prix officiel au moment de l'appel. Un appel payant exige une autorisation séparée.

:::caution[Probe live non exécutée]
La probe live est **à vérifier**. Aucun appel API n'a été fait pendant la rédaction; aucune latence, réponse, consommation, dépense ni calibration n'est donc mesurée.
:::

## Conditions d'arrêt

Arrêtez immédiatement si la clé manque ou apparaît dans une sortie, si la limite locale d'octets/proxy est dépassée, si le contrat est invalide, si le fournisseur renvoie 401/422/429/529 ou un statut inattendu, si le modèle concret diffère, si la décision pourrait autoriser/fusionner/déployer/publier/supprimer, ou si l'entrée contient un secret ou des données non approuvées. La limite d'un appel ne garantit aucun plafond en dollars.

## Tableau de preuves à remplir

| Champ | Preuve exigée | État actuel |
|---|---|---|
| identité de requête | SHA-256 du script | mock seulement |
| modèle | champ `model` concret | live non testé |
| usage et coût | tokens d'entrée × prix courant | live non testé |
| latence | `elapsed_ms` | live non testé |
| forme | validateur réussi | mock réussi; live non testé |
| décision | valeur exacte | mock : refus du dispatch |
| qualité métier | résultat face à une étiquette fixée avant l'appel | non testé |

Un appel réussi est une probe de connectivité, pas une évaluation. L'étape utile suivante est un corpus versionné avec cas clairs, frontières et contre-exemples, évalué avant de déplacer les seuils.

## Exercices

1. Pourquoi épingler `jev-1.13.0` au lieu de `jev-latest`?

<details><summary>Solution</summary>

Parce qu'un alias peut changer sans changement de code. Les seuils et mesures appartiennent au modèle concret qui les a produits.

</details>

2. Le SDK officiel sait réessayer, mais cette probe refuse de le faire. Est-ce un bogue?

<details><summary>Solution</summary>

Non. Son budget est exactement un appel. Un retry automatique rendrait le coût et le nombre d'observations ambigus. En production, les tentatives et leur coût maximal doivent rester explicites et testés.

</details>

## Sources

- TypeSafe AI : [référence API](https://docs.typesafe.ai/api), [modèles et prix](https://docs.typesafe.ai/models), [démarrage rapide](https://docs.typesafe.ai/introduction/quickstart)
- Code : [`code/typesafe-ai-system-one`](https://github.com/spareilleux/learn/tree/main/code/typesafe-ai-system-one)
