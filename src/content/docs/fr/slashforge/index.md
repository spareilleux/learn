---
title: SlashForge, des commandes de workflow pour Claude Code — Mission
description: Lire, installer et démonter SlashForge, un paquet npm qui donne à Claude Code un workflow de développement en dix phases, jalonné de points de contrôle et écrit entièrement en Markdown — ce qu'écrit son installeur, comment un fichier devient une commande slash, et où le kit et Claude Code ne sont pas d'accord sur un même fichier.
sidebar:
  label: Mission
  order: 0
---

:::note[Version étudiée, et ce que la CI peut tester ou non]
[SlashForge](https://github.com/rajdeepratan/SlashForge) **4.4.3**, tag [`v4.4.3`](https://github.com/rajdeepratan/SlashForge/tree/bd75a4f770bb2e323551c05fab0d3f326c72ae98) (l'installeur est identique sur `main` le 2026-09-22), avec [Node.js](https://nodejs.org/) 24 et [Claude Code](https://code.claude.com/docs/en/overview), sous Windows 11, en septembre 2026. Le code de ce cours se trouve dans [`code/slashforge`](https://github.com/spareilleux/learn/tree/main/code/slashforge), et [`.github/workflows/slashforge-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/slashforge-examples.yml) l'exécute sous Linux, Windows et macOS.

Ce que teste la CI, c'est **l'installeur** : elle le lance dans un répertoire personnel jetable et compare tout ce qu'il affiche et écrit. Ce que font les commandes une fois que Claude Code les exécute dépend du modèle et coûte des tokens — des dizaines de milliers par exécution, selon l'estimation de SlashForge lui-même — si bien que ces leçons-là sont des captures, datées, jamais présentées comme reproductibles.
:::

## Pourquoi j'apprends cela

Le [cours de programmation agentique](../agentic-coding/) a présenté les pièces que fournit Claude Code : instructions de projet, commandes, skills, sous-agents, hooks. Il n'a pas montré à quoi ressemble un workflow complet construit à partir de ces pièces. SlashForge en est un : quatre commandes et neuf skills qui font passer une demande par le recueil, le plan, la confirmation, la branche, l'implémentation, la vérification, la revue, la pull request, les retours et le nettoyage, et qui s'arrêtent à quatre *points de contrôle* (*gates*) où rien ne continue tant que tu n'as pas répondu.

C'est un bon spécimen pour deux raisons. Il est assez petit pour être lu — un installeur de 676 lignes et vingt-neuf modèles Markdown — et il est honnête sur son coût : son README dit qu'il est *"deliberately heavy"* (délibérément lourd) et donne un budget de tokens pour chaque commande. Et chacun de ses comportements vit dans du texte brut que l'on peut ouvrir, ce qui veut dire que l'on peut confronter chacune de ses affirmations au fichier censé l'implémenter.

C'est ce que fait ce cours. Il installe SlashForge là où il ne peut pas faire de dégâts, lit ce qu'il a écrit, et compare entre eux la documentation, l'installeur et les règles de Claude Code lui-même. Ils ne sont pas toujours d'accord : le [tableau QA](journal/#qa) du journal indique où.

## À qui s'adresse ce cours

Tu écris du C# ou du Java, tu as utilisé Claude Code — le [cours de programmation agentique](../agentic-coding/) jusqu'à sa [leçon 3](../agentic-coding/03-hooks-skills-subagents/) suffit — et tu veux savoir ce qu'apporte un kit de workflow opiniâtre, ce qu'il coûte et ce qu'il installe sur ta machine avant de le lancer. Tu n'as pas besoin de connaître JavaScript : l'installeur se lit, il ne s'écrit pas.

## Un kit de workflow, en termes .NET et Java

| | .NET / Java | SlashForge |
|---|---|---|
| Distribution | un paquet NuGet ou Maven | un paquet [npm](https://docs.npmjs.com/), lancé une fois avec `npx` |
| Ce qu'il installe | des assemblys, des modèles (`dotnet new install`) | des fichiers Markdown sous `~/.claude/` ou `./.claude/` |
| La partie exécutable | du code compilé | un installeur de 676 lignes ; le reste est du texte que lit Claude Code |
| Comment on l'invoque | un verbe de CLI, une commande de l'IDE | une commande slash : `/slashforge:code` |
| Garde-fous | politiques de branche, revues obligatoires | quatre points de contrôle écrits dans les instructions — on dit au modèle de s'arrêter |
| Configuration | `appsettings.json`, `pom.xml` | le `CLAUDE.md` et le `.claude/rules/` de ton dépôt |

Ce sont les deux dernières lignes qu'il faut garder en tête. Une politique de branche est appliquée par le serveur ; un point de contrôle de SlashForge est une phrase à laquelle on demande au modèle d'obéir. Le [cours de programmation agentique](../agentic-coding/03-hooks-skills-subagents/) trace la même frontière entre instructions et hooks.

## À la fin de ce cours, je saurai

- installer SlashForge globalement ou dans un seul dépôt sans toucher au reste de `~/.claude/`, et le retirer proprement ;
- dire, pour chaque fichier qu'il écrit, ce qu'en fait Claude Code et pourquoi son chemin compte ;
- lire un fichier de commande et le suivre jusque dans les guides auxquels il délègue ;
- lancer `/slashforge:setup`, `/slashforge:code` et son mode `-quick`, `/slashforge:investigate` et `/slashforge:review-pr` sur un vrai dépôt, et mesurer ce qu'ils coûtent ;
- décider, pour une modification donnée, si la cérémonie en vaut la peine.

## Plan

| # | Leçon | Tu connais déjà |
|---|---|---|
| 1 | [Ce qu'écrit l'installeur](01-what-the-installer-writes/) | `dotnet tool install`, `dotnet new install`, un paquet qui dépose des fichiers |
| 2 | [Dans les fichiers : commandes, skills, guides](02-inside-the-files/) | les paramètres de modèle, le routage par dossier, un validateur plus strict que le runtime |
| 3 | [`/slashforge:setup` face à `/init`](03-setup-against-init/) | un modèle de projet, une checklist d'intégration |
| 4 | [`/slashforge:code` : dix phases et quatre points de contrôle](04-code-phases-and-gates/) | les politiques de branche, un modèle de pull request |
| 5 | [`/slashforge:investigate` et `/slashforge:review-pr`](05-investigate-and-review-pr/) | un processus de correctif urgent, un rapport de bug, une revue de code |
| 6 | [Se l'approprier : règles, vérification, installation d'équipe](06-making-it-yours/) | `.editorconfig`, une configuration de build partagée |
| — | [Journal](journal/) | |

## Ressources

- [SlashForge sur GitHub](https://github.com/rajdeepratan/SlashForge), son [site de documentation](https://www.rajdeepratan.com/slashforge/) et son [changelog](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/CHANGELOG.md)
- [Le paquet `slashforge` sur npm](https://www.npmjs.com/package/slashforge)
- Claude Code : [skills et commandes personnalisées](https://code.claude.com/docs/en/skills), et [le répertoire `.claude`](https://code.claude.com/docs/en/claude-directory)
- [superpowers](https://github.com/obra/superpowers), la bibliothèque de skills dont sont adaptés les neuf skills de SlashForge, sous licence MIT
- [Agent Skills](https://agentskills.io/), le format ouvert des fichiers de skill
