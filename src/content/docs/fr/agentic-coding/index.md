---
title: Programmation agentique avec Claude Code et Codex — Mission
description: Comprendre comment fonctionnent les agents de code, à partir de ce qu'un développeur C# ou Java connaît déjà — la boucle d'outils, les permissions, les instructions de projet, les hooks, les skills, les sous-agents et MCP — sur le dépôt de ce site et sur GuitarAlchemist/ga, avec Claude Code et la CLI Codex.
sidebar:
  label: Mission
  order: 0
---

:::note[Versions étudiées, et ce que la CI peut tester ou non]
[Claude Code](https://code.claude.com/docs/en/overview) **2.1.270**, mis à jour en 2.1.271 pendant la rédaction, et la [CLI Codex](https://learn.chatgpt.com/docs/codex/cli) **0.154.0**, sous Windows 11, en septembre 2026. Le code de ce cours se trouve dans [`code/agentic-coding`](https://github.com/spareilleux/learn/tree/main/code/agentic-coding) : un hook, un serveur MCP en C# et les fichiers de configuration des deux agents. [`.github/workflows/agentic-coding-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/agentic-coding-examples.yml) teste le tout sous Linux, Windows et macOS, **sans agent et sans clé d'API** : le hook lit des appels d'outils en JSON, le serveur est piloté par un client MCP, les fichiers de configuration sont analysés.

Ce que répond un agent ne peut pas se tester ainsi : cela dépend du modèle, du jour et de l'abonnement. Chaque session d'agent citée dans ces leçons est une capture, datée avec son heure UTC, jamais présentée comme reproductible.
:::

## Pourquoi j'apprends cela

La plus grande partie de ce site a été écrite avec un agent de code. Je décris une tâche, l'agent lit des fichiers, lance des commandes, modifie, exécute les tests, et revient avec un diff et un résumé. Quand ça marche, c'est plus rapide que de le faire moi-même ; quand ça ne marche pas, l'erreur peut être subtile : un test qu'il n'a pas lancé, une règle qu'il a oubliée, une branche qu'il a poussée.

Je veux comprendre ce qui se passe entre ma demande et le diff : quels fichiers l'agent lit, ce qu'il a le droit d'exécuter, ce dont il se souvient, et comment poser des garde-fous qui ne dépendent pas de la bonne volonté de l'agent. Puis m'en servir sur [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga), une solution .NET de 111 projets, et plus tard sur Gaia et IX.

## À qui s'adresse ce cours

Tu écris du C# ou du Java professionnellement. Tu connais ton IDE, Git, un outil de build et un framework de test. Tu as peut-être utilisé la complétion de code (IntelliSense, les suggestions en ligne de GitHub Copilot), mais tu n'as **jamais laissé un agent lancer des commandes dans ton dépôt**. Tu n'as besoin de rien savoir des modèles de langage.

## Les agents de code en un tableau

| | Complétion de code de l'IDE | Claude Code | CLI Codex |
|---|---|---|---|
| S'exécute | dans l'éditeur, à chaque frappe | dans un terminal, sous forme de session | dans un terminal, sous forme de session |
| Agit sur | la ligne que tu écris | tout le dépôt : lit, modifie, lance des commandes | la même chose |
| Demande avant d'agir | n'agit jamais | modes et règles de permission | modes de bac à sable et politiques d'approbation |
| Instructions de projet | aucune | `CLAUDE.md` | `AGENTS.md` |
| Garde-fous déterministes | aucun | hooks | hooks, bac à sable |
| Outils supplémentaires | extensions de l'éditeur | serveurs MCP, skills, sous-agents | serveurs MCP, skills, sous-agents |
| Non interactif | non | `claude -p` | `codex exec` |

Sources : [comment fonctionne Claude Code](https://code.claude.com/docs/en/how-claude-code-works), [CLI Codex](https://learn.chatgpt.com/docs/codex/cli), [approbations et sécurité de Codex](https://learn.chatgpt.com/docs/agent-approvals-security).

## Les dépôts

- **Ce site**, [spareilleux/learn](https://github.com/spareilleux/learn) : un site Astro avec des cours en trois langues, une CI qui exécute le code de chaque cours, et un [`AGENTS.md`](https://github.com/spareilleux/learn/blob/main/AGENTS.md) qui a grandi à chaque erreur commise ici par un agent. Plusieurs sessions d'agent y travaillent en même temps.
- **[GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga)**, figé au commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6) (2026-09-14) : une application de théorie musicale en C# et F#, avec un `CLAUDE.md`, un `AGENTS.md`, des skills et des sous-agents de projet, et [`GaMcpServer`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer), un serveur MCP qui expose sa théorie musicale aux agents. Ce cours lit ga ; il n'y écrit jamais.

## À la fin de ce cours, je saurai

- expliquer la boucle entre le modèle et les outils, et ce qu'un agent peut faire sans demander ;
- installer Claude Code et la CLI Codex sous Windows, Linux et macOS, et les lancer en interactif et depuis un script ;
- écrire des instructions de projet que les deux agents lisent, et savoir ce qu'elles ne peuvent pas imposer ;
- bloquer une commande dangereuse avec un hook, empaqueter une procédure dans un skill, et déléguer à un sous-agent ;
- écrire un serveur MCP en C#, le tester sans agent, et le connecter aux deux agents ;
- utiliser ces outils sur une vraie solution .NET, et relire ce que l'agent a fait.

## Plan

| # | Leçon | Tu connais déjà |
|---|---|---|
| 1 | [Agents, outils et permissions](01-agents-and-permissions/) | les refactorings de l'IDE, lancer un build depuis le terminal |
| 2 | [Le contexte du projet : `CLAUDE.md`, `AGENTS.md`, mémoire et compaction](02-project-context/) | `README.md`, `.editorconfig`, une page de wiki que personne ne lit |
| 3 | [Hooks, skills et sous-agents](03-hooks-skills-subagents/) | les hooks Git, les analyseurs, les scripts dans `tools/` |
| 4 | [MCP : un serveur C# pour les deux agents](04-mcp/) | un service JSON-RPC ou gRPC, l'injection de dépendances |
| 5 | [Skills de Matt Pocock : des méthodes d’ingénierie exécutables](05-matt-pocock-skills/) | les runbooks, le TDD, le découpage en issues |
| 6 | [Sandcastle : une exécution agent isolée](06-sandcastle/) | les conteneurs, les branches, l’isolation des processus |
| 7 | [Compound Engineering : fermer la boucle d’apprentissage](07-compound-engineering/) | les pipelines de livraison, les postmortems, la documentation réutilisable |
| 8 | Travailler sur GuitarAlchemist/ga : planifier, compiler, tester, relire (à venir) | la revue d'une pull request |
| 9 | Les agents en CI, et plusieurs agents sur un même dépôt | GitHub Actions, la protection de branche |
| 10 | Gaia et IX : des agents qui lancent d'autres agents | l'orchestration, les files d'attente |
| — | [Journal](journal/) | |

## Ressources

- [Documentation de Claude Code](https://code.claude.com/docs/en/overview), aussi disponible en Markdown ([index](https://code.claude.com/docs/llms.txt))
- [Documentation de Codex](https://learn.chatgpt.com/docs/codex/cli), et le [code source de Codex](https://github.com/openai/codex)
- [Model Context Protocol](https://modelcontextprotocol.io/), sa [spécification](https://modelcontextprotocol.io/specification/2026-07-28/architecture) et le [SDK C#](https://github.com/modelcontextprotocol/csharp-sdk)
- [Agent Skills](https://agentskills.io/), le format ouvert des fichiers `SKILL.md` que lisent les deux agents
