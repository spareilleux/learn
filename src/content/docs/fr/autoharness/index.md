---
title: AutoHarness, des skills qui s'écrivent seuls pour Claude Code — Mission
description: Évaluer AutoHarness, un plugin Claude Code qui transforme les sessions terminées en skills et élague ceux qui ne servent plus — lu à un commit épinglé, testé par des fixtures préinscrites dans un labo isolé sans l'installer ni appeler de modèle, et jugé sur les preuves plutôt que sur son README.
sidebar:
  label: Mission
  order: 0
---

:::note[Version étudiée, et ce qui a été exécuté]
[AutoHarness](https://github.com/tigerless-labs/autoharness) au commit [`ca39a72`](https://github.com/tigerless-labs/autoharness/tree/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b) (2026-09-25), licence MIT, avec Python 3.14.2 sous Windows 11, en septembre 2026. Le code de ce cours est dans [`code/autoharness`](https://github.com/spareilleux/learn/tree/main/code/autoharness).

Ce qui a été exécuté, c'est la partie d'AutoHarness qui n'a pas besoin de modèle : le promoteur, la file d'intentions, le magasin de skills et le masqueur de secrets, importés depuis un clone dans des sous-processus isolés. Il n'a **jamais été installé** : aucun plugin, hook, dossier de skills ni réglage MCP de Claude Code n'a été modifié, et aucun modèle n'a été appelé. Tout ce que le *reflector* (un modèle) écrirait est hors de portée de ce cours, et chaque leçon le dit là où ça compte. Les exécutions ont eu lieu sous Windows seulement ; Linux et macOS sont *à vérifier*.
:::

:::caution[Verdict à `ca39a72` : ne pas adopter]
Deux fixtures préinscrites cassent la promesse centrale du projet, selon laquelle les skills écrits à la main ne sont jamais touchés ; une seule ligne tronquée arrête la promotion pour de bon ; et le masqueur laisse passer les secrets écrits en JSON. Les défauts sont petits et locaux, et l'évaluation liste ce qui changerait le verdict : [`evaluation.md`](https://github.com/spareilleux/learn/blob/main/code/autoharness/results/evaluation.md).
:::

## Pourquoi j'apprends cela

Le [cours de programmation agentique](../agentic-coding/) a présenté les pièces que Claude Code te donne : hooks, skills, sous-agents, serveurs MCP. Tu écris un skill, tu le commites, et il reste ce que tu as écrit. AutoHarness te prend la plume. Il observe tes sessions par des hooks, demande à un modèle en arrière-plan de distiller ce qui s'est passé en skills, les dépose dans `.claude/skills/` sans demander, puis archive plus tard ceux qui ne servent plus. Son README promet qu'il *« stays clean on its own »* (reste propre tout seul), en ne touchant *« only the skills it wrote itself »* (qu'aux skills qu'il a écrits lui-même).

Un outil qui écrit des instructions que ta prochaine session *« MUST consider »* (doit envisager) mérite plus d'examen qu'un outil qui se contente de lire. Et chacune de ses promesses se teste : la partie qui décide de ce qui arrive sur le disque est du Python ordinaire, qui tourne sans modèle. Ce cours fait donc ce que le [cours SlashForge](../slashforge/) a fait avec un installeur, un cran plus loin : il lit le code épinglé, écrit à quoi ressemblerait chaque promesse si elle était fausse, puis exécute le code face à ces prédictions, dans un labo où rien ne peut atteindre le vrai `~/.claude`.

## À qui s'adresse ce cours

Tu écris du C# ou du Java, tu utilises Claude Code et tu sais ce que sont un hook et un skill — le [cours de programmation agentique](../agentic-coding/) jusqu'à sa [leçon 3](../agentic-coding/03-hooks-skills-subagents/) suffit —, et tu te demandes s'il faut laisser un outil réécrire les instructions de ton agent à ta place. Pas besoin de bien connaître Python : le code du labo est court, et chaque ligne de sortie est expliquée.

## Une couche de skills qui se modifie elle-même, en termes .NET et Java

| | .NET / Java | AutoHarness |
|---|---|---|
| Distribution | un paquet NuGet ou Maven | un [plugin Claude Code](https://code.claude.com/docs/en/plugins) : des hooks, deux agents, un serveur MCP, du code Python |
| Quand il s'exécute | quand tu l'appelles | à chaque appel d'outil, à chaque tour et à chaque début de session, par des [hooks](https://code.claude.com/docs/en/hooks) |
| Ce qu'il produit | des assemblies que tu livres | des [skills](https://code.claude.com/docs/en/skills) en Markdown que les sessions suivantes chargent |
| Qui écrit le résultat | toi, relu dans une pull request | un `claude -p` en arrière-plan sur Haiku, puis un *promoteur* déterministe qui le dépose — sans étape de relecture |
| Propriété | l'auteur d'un fichier dans `git blame` | un `.sidecar.json` à côté du skill qui dit `"created_by": "agent"` |
| Nettoyage | tu supprimes le code mort | les skills inutilisés assez longtemps sont archivés automatiquement |

C'est la cinquième ligne qui occupe la plus grande partie de ce cours. Un simple fichier JSON décide de ce qu'AutoHarness considère comme sien, et la question est ce qui se passe autour de cette décision.

## À la fin de ce cours, je saurai

- dire quels événements font capturer, réfléchir, promouvoir, injecter et archiver AutoHarness, et lesquels font intervenir un modèle ;
- exécuter la partie d'un outil qui n'a pas besoin de modèle dans des sous-processus isolés, avec un répertoire personnel jetable et un environnement construit à partir de rien ;
- préinscrire une fixture — question, hypothèse, témoin, falsificateur, empreinte des entrées — avant de l'exécuter, et garder ce qui revient même quand ça me donne tort ;
- distinguer ce qu'affirme un README, ce que montre le code, ce que reproduit une fixture et ce que seul un modèle en direct pourrait dire ;
- décider, preuves à l'appui, s'il faut laisser un tel outil toucher un vrai projet.

## Plan

| # | Leçon | Tu connais déjà |
|---|---|---|
| 1 | [Un labo de fixtures : six promesses testées sans installer](01-fixture-lab/) | un test unitaire avec un faux, un test qui doit d'abord échouer, un environnement de test propre |
| 2 | *Prévue :* la boucle et ses frontières d'autorité — hooks, reflector, promoteur, et ce qu'un dépôt cloné peut mettre en file | un job en arrière-plan, un compte de service, un pipeline de déploiement sans étape d'approbation |
| 3 | *Prévue :* pourquoi l'usage n'est pas la qualité — compteurs, maturité et capacité | la couverture de code comme métrique, un feature flag que personne ne retire |
| 4 | *Prévue :* plantages, concurrence et historique — ce qui survit à une promotion interrompue | une file « au moins une fois », une mise à jour perdue, une sauvegarde qui écrase la précédente |
| 5 | *Prévue :* l'évaluation et une liste de contrôle d'adoption | une preuve de concept, une revue go/no-go |
| — | [Journal](journal/) | |

Les leçons 2 à 5 sont prévues, pas écrites. Leurs hypothèses sont déjà listées dans l'évaluation (§2, *read in the source, not run*), et chacune demandera ses propres fixtures préinscrites avant d'affirmer quoi que ce soit.

## Ressources

- [AutoHarness sur GitHub](https://github.com/tigerless-labs/autoharness), et son [README au commit épinglé](https://github.com/tigerless-labs/autoharness/blob/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b/README.md)
- Claude Code : [hooks](https://code.claude.com/docs/en/hooks), [skills](https://code.claude.com/docs/en/skills), [sous-agents](https://code.claude.com/docs/en/sub-agents) et [plugins](https://code.claude.com/docs/en/plugins)
- [HAL](https://arxiv.org/abs/2510.11977), l'article que le README cite pour sa ligne *42% → 78% on CORE-Bench* — un résultat de cet article, pas d'AutoHarness
- La [préinscription](https://github.com/spareilleux/learn/blob/main/code/autoharness/results/preregistration.md) et l'[évaluation](https://github.com/spareilleux/learn/blob/main/code/autoharness/results/evaluation.md) de ce cours
