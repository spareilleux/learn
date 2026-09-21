---
title: "3. Cas d'usage dans nos dépôts"
description: Des hypothèses pratiques et bornées pour Gaia, GA, Demerzel, IX et TARS, avec le seam déterministe, le rôle consultatif du modèle, les données d'évaluation et les critères de rejet.
sidebar:
  order: 3
---

La bonne question n'est pas « Où ajouter de l'IA? », mais :

> Où avons-nous déjà un jugement flou, répété et rapide, dont l'espace de réponses est fermé et dont l'effet peut rester derrière une gate déterministe?

Ces propositions sont des expériences, pas des fonctionnalités. Aucune n'a été testée avec Jev.

| Dépôt | Jugement candidat | Primitive | Propriétaire déterministe | Première évaluation |
|---|---|---|---|---|
| [Gaia](https://github.com/GuitarAlchemist/gaia) | router une preuve vers revue, implémentation bornée, rejet ou inconnu | Choice + Noul | vérificateur d'autorité et machine d'état | anciens reçus étiquetés à l'aveugle |
| [GA](https://github.com/GuitarAlchemist/ga) | router une question musicale ou évaluer une intention ambiguë | Choice + Score | parseur, registre de capacités et recherche en lecture seule | corpus de requêtes étiquetées |
| [Demerzel](https://github.com/GuitarAlchemist/Demerzel) | choisir le tribunal ou la file humaine qui doit examiner un dossier | Choice | constitution, schémas et code du tribunal | anciens verdicts, sans champs d'autorité dans l'entrée modèle |
| [IX](https://github.com/GuitarAlchemist/ix) | évaluer une observation d'expérience pour anomalie ou priorité | Score + Noul | pipeline Rust et tests statistiques | rapports d'expérience tenus à l'écart |
| [TARS](https://github.com/GuitarAlchemist/tars) | choisir parmi plusieurs parses DSL valides | Choice | parseur F# et validation de l'AST typé | corpus d'ambiguïtés et candidats du parseur |

## Gaia — un avis à côté de la gate

Jev pourrait estimer l'étape suivante, le risque et la présence apparente d'un langage d'autorité. Il ne doit jamais transformer cette probabilité en preuve. Les reçus exacts, digests, générations et grants de Gaia restent la source de vérité. Rejetez l'intégration si une réponse peut créer un successeur, envoyer un wake, produire un grant ou contourner l'exact replay sans que le contrôleur déterministe prouve chaque précondition.

## GA — router l'intention floue, préserver la vérité musicale

« Cette question concerne-t-elle la recherche de voicings, l'harmonie, la lecture ou le support? » est un Choice. Mais le modèle ne doit inventer ni notes, ni accords, ni accordages, ni dimensions OPTIC-K. Ces objets appartiennent aux types et algorithmes de GA. Comparez le tracer à un corpus étiqueté et rejetez-le s'il masque `unknown` ou touche un endpoint à effets.

## Demerzel — trier les preuves sans interpréter la constitution

Un Choice fermé peut prioriser le tribunal ou la file de revue. La constitution, les schémas et l'autorité restent déterministes. Le cas négatif essentiel est une proposition séduisante mais non autorisée : elle doit aller en revue, jamais muter la gouvernance.

## IX — transformer des rapports en features, pas en conclusions

Jev peut transformer des observations textuelles en features structurées : risque de reproductibilité, probabilité d'une baseline manquante, priorité du suivi. Les statistiques et invariants Rust décident encore du résultat. Comparez aussi aux regexes, métadonnées explicites ou petit classifieur; rejetez Jev si une donnée déterministe suffit.

## TARS — choisir parmi les candidats du parseur

Le seam le plus net vient après que le parseur a produit plusieurs AST valides. Jev classe leurs identifiants fermés; TARS valide encore l'AST et demande à l'utilisateur si la distribution est partagée. Ne demandez pas au modèle de générer librement du code source destiné à être exécuté.

## Un adaptateur partagé

Si deux expériences réussissent, préférez un petit port indépendant du fournisseur à cinq intégrations SDK :

```text
evaluate(state, questions, budget) -> typed answers + provider evidence
```

Chaque dépôt possède ses questions, seuils, corpus et politiques d'effet. L'adaptateur possède HTTP, modèle épinglé, timeout, coûts, validation et caviardage. Gaia peut journaliser la preuve sans devenir le service universel de décision.

## Garde-fous coût et fournisseur

- mock et replay par défaut en CI;
- flag live explicite et clé d'environnement;
- modèle, taille d'entrée, nombre d'appels, retries, temps et dollars bornés séparément;
- fournisseur, modèle et usage consignés sans secret;
- repli vers du déterministe ou une revue humaine, jamais vers un autre fournisseur payant en silence;
- comparaison avec le baseline sans modèle le plus simple.

## Exercices

1. Quel cas offre le tracer le plus propre?

<details><summary>Solution</summary>

Le classement des candidats TARS : le parseur fournit une liste fermée et valide l'AST sélectionné. Le modèle ne peut pas inventer une commande, et un corpus d'ambiguïtés permet une mesure nette.

</details>

2. GA appelle Jev puis un LLM si la confiance est faible. Quels garde-fous manquent?

<details><summary>Solution</summary>

Un plafond global fournisseur/coût explicite et une autorisation du fallback. Le second appel élargit silencieusement l'autorité et la dépense.

</details>

## Sources

- TypeSafe AI : [fan-out spéculatif](https://docs.typesafe.ai/patterns/fan-out), [routage par confiance](https://docs.typesafe.ai/patterns/confidence-routing), [score composite](https://docs.typesafe.ai/patterns/composite-scoring)
- Dépôts : [Gaia](https://github.com/GuitarAlchemist/gaia), [GA](https://github.com/GuitarAlchemist/ga), [Demerzel](https://github.com/GuitarAlchemist/Demerzel), [IX](https://github.com/GuitarAlchemist/ix), [TARS](https://github.com/GuitarAlchemist/tars)
