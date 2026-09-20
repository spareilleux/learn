---
title: "6. Sandcastle : une exécution agent isolée"
description: Construire un labo Sandcastle borné avec Docker, une branche explicite, une itération et une vérification contrôlée par le host.
sidebar:
  order: 6
---

[Sandcastle](https://github.com/mattpocock/sandcastle/tree/e99f832f26dc9d245c019a9ddd19fa5dee792427) est une bibliothèque TypeScript qui exécute des agents de code dans des sandboxes et gère leurs branches et commits. Cette leçon est épinglée au commit `e99f832f` et à la version 0.12.0, vérifiés le 20 septembre 2026.

Sandcastle est un harness d’exécution, pas une méthode d’expression des besoins. Le prompt et le host déterminent encore quel travail est valide, comment le vérifier et si un commit peut être fusionné.

## Préparer un labo jetable

Prérequis : Git, Node.js et Docker ou Podman. Ne commence pas dans un dépôt de production.

```bash
npm install --save-dev @ai-hero/sandcastle
npx @ai-hero/sandcastle init
```

L’initialiseur crée `.sandcastle/`. Place les identifiants du fournisseur uniquement dans `.sandcastle/.env`, garde ce fichier ignoré et ne copie jamais un token dans une leçon ou une transcription. Un token d’abonnement et une clé API n’ont pas le même coût : vérifie le fournisseur sélectionné avant l’exécution.

## La plus petite exécution utile

```ts
import { run, claudeCode } from "@ai-hero/sandcastle";
import { docker } from "@ai-hero/sandcastle/sandboxes/docker";

const result = await run({
  agent: claudeCode("<verified-model-id>"),
  sandbox: docker(),
  branchStrategy: { type: "branch", branch: "agent/tutorial" },
  promptFile: ".sandcastle/prompt.md",
  maxIterations: 1,
});

console.log(result.branch, result.commits);
```

Exécute le point d’entrée généré, avec le nom créé par ta version installée, actuellement :

```bash
npx tsx .sandcastle/main.mts
```

`prompt.md` est une convention, pas un fallback automatique : passe-le avec `promptFile`. Une stratégie `branch` explicite laisse le travail disponible pour inspection. `head` écrit directement dans le checkout du host ; `merge-to-head` fusionne une branche temporaire dans `HEAD`. Aucun des deux ne convient au premier exercice.

## La porte de preuve

Après l’exécution, le host — pas le modèle — doit inspecter :

1. `result.branch` et `result.commits` ;
2. le diff exact par rapport au commit initial ;
3. la sortie déterministe des tests ;
4. le journal et le code de sortie de la sandbox ;
5. toute frontière réseau, d’identifiants ou de coût franchie.

Ne fusionne rien pendant cet exercice. Une itération suffit pour prouver le harness, la frontière de branche et le chemin de preuve.

## Isolation n’est pas autorisation

Une sandbox limite un système de fichiers et un environnement de processus. Elle ne rend pas un prompt non fiable correct, ne protège pas tous les secrets réseau, n’autorise pas un push et ne prouve pas la satisfaction du besoin. Les valeurs par défaut du fournisseur peuvent automatiser les approbations dans la sandbox : le host doit toujours imposer portée, budget et condition d’arrêt.

Évite `noSandbox()` dans ce labo : il supprime volontairement l’isolation. Évite les fournisseurs cloud et API payantes tant que leur budget et le chemin des identifiants n’ont pas été explicitement revus.

:::caution[Dérive de la documentation upstream]
À la révision épinglée, une ancienne page parle encore de `.sandcastle/config.json` et de dix itérations par défaut. Le README et les templates générés actuels configurent directement l’API TypeScript et documentent une itération par défaut. Suis le README épinglé et le template généré, puis revérifie upstream avant d’actualiser cette leçon.
:::

## Exercice

Crée un dépôt jetable avec un test rouge et demande à l’agent de rendre uniquement ce test vert. Utilise Docker, une branche nommée et `maxIterations: 1`. L’exercice réussit seulement si le host peut montrer le SHA initial, le commit produit, le diff et le test vert sans aucune fusion.

Continue avec [Compound Engineering](../07-compound-engineering/) pour rendre explicites les artefacts de planification, d’implémentation, de revue et d’apprentissage.

