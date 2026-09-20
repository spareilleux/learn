---
title: "5. Skills de Matt Pocock : des méthodes d’ingénierie exécutables"
description: Installer une seule distribution des skills AI Hero, la configurer pour un dépôt et transformer une idée en tracer bullet avec des preuves explicites.
sidebar:
  order: 5
---

Un `SKILL.md` est une procédure qu’un agent charge lorsqu’une tâche correspond. Il est plus ciblé qu’`AGENTS.md` : les instructions du projet s’appliquent à chaque tour, tandis qu’un skill décrit une tâche répétable comme la recherche, le TDD ou la revue de code.

Cette leçon utilise les [skills de Matt Pocock](https://github.com/mattpocock/skills/tree/c55ee46073ed923f86ce59a5eb3b6d895095d1b7), épinglés à `c55ee460` le 20 septembre 2026, ainsi que la méthode décrite par [AI Hero](https://www.aihero.dev/skills).

## Installer une seule distribution

Le projet upstream offre deux modes d’installation. Installer les deux duplique les mêmes skills.

```bash
# Claude Code : plugin géré et en lecture seule
claude plugins install mattpocock-skills

# Codex et autres agents compatibles : fichiers modifiables dans le projet
npx skills@latest add mattpocock/skills
```

Pour les skills copiés, la mise à jour se fait avec `npx skills update`. Invoque ensuite `setup-matt-pocock-skills` une fois dans le dépôt. Ce skill inspecte le gestionnaire d’issues, les labels de triage et l’organisation des documents métier, propose des changements et demande confirmation avant d’écrire. Relis la proposition : ce n’est pas un installateur déterministe.

## Le flux principal

```mermaid
flowchart LR
    A[Idée ambiguë] --> B[grill-with-docs]
    B --> C[to-spec]
    C --> D[to-tickets]
    D --> E[tdd ou implement]
    E --> F[code-review]
```

- `grill-with-docs` précise les exigences et consigne le vocabulaire métier ou les ADR.
- `to-spec` transforme la conversation validée en spécification sans recommencer l’entretien.
- `to-tickets` produit des tracer bullets vérifiables indépendamment avec leurs dépendances.
- `tdd` fixe une seam publique, écrit un test rouge, puis l’implémentation minimale qui le rend vert.
- `code-review` vérifie séparément le même diff par rapport aux standards du dépôt et à la spécification.

Un tracer bullet est une fine tranche verticale qui traverse toutes les couches nécessaires. Ce n’est pas une tâche horizontale comme « construire toute la couche de données ». Il doit révéler tôt les erreurs d’intégration et finir par une preuve observable.

## Exercice borné

Choisis une fonctionnalité sans danger dans un dépôt jetable.

1. Écris le résultat visible par l’utilisateur en une phrase.
2. Lance `grill-with-docs` et ne réponds qu’aux questions qui changent la conception.
3. Inspecte la spec avant de l’accepter.
4. Refuse les tickets impossibles à vérifier seuls ou limités à une couche.
5. Implémente un tracer bullet avec une seam de test.
6. Relis le diff figé par rapport aux standards et à la spec.

Arrête-toi après une tranche. Note le commit, la commande de test et l’incertitude restante. Un tour d’agent terminé ne prouve pas que le résultat attendu fonctionne.

## Au-delà d’une fenêtre de contexte

Utilise `wayfinder` pour cartographier les décisions, pas comme synonyme d’un vaste plan d’implémentation. Ses tickets lèvent les inconnues par recherche, prototype, grilling ou tâche bornée. La carte est terminée lorsque la route est claire, pas lorsque toutes les fonctionnalités imaginables sont listées.

## Échecs fréquents

- installer à la fois le plugin géré et les skills copiés ;
- prendre un article ou un alias mémorisé pour le contrat d’exécution au lieu de lire le `SKILL.md` installé ;
- produire des tickets horizontaux qui repoussent l’intégration ;
- laisser un skill étendre silencieusement l’autorité à push, merge, dépenser ou contacter des systèmes externes.

L’autorité propre au dépôt vient toujours de l’utilisateur et du host. Un skill change la procédure, pas les permissions.

Continue avec [Sandcastle](../06-sandcastle/) pour exécuter un agent dans une frontière explicite.

