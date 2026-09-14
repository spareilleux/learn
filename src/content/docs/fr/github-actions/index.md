---
title: GitHub Actions — Mission
description: Apprendre GitHub Actions à partir de vraies exécutions — compiler, tester et déployer des projets .NET et Java, avec chaque log des leçons capturé dans le dépôt de ce site.
sidebar:
  label: Mission
  order: 0
---

:::note[Comment ce cours est testé]
Chaque workflow de ce cours se trouve dans le dépôt de ce site ([`.github/workflows/gha-*.yml`](https://github.com/spareilleux/learn/tree/main/.github/workflows)) et tourne réellement sur GitHub. Les logs, erreurs et durées cités dans les leçons proviennent de ces exécutions, en septembre 2026 (runner `2.337.0`, image `ubuntu-24.04`). Le code d'exemple est dans [`code/github-actions`](https://github.com/spareilleux/learn/tree/main/code/github-actions).
:::

## Pourquoi j'apprends ça

Ce site est compilé, testé et déployé par [GitHub Actions](https://docs.github.com/actions) : un déploiement Pages à chaque push, et une CI qui compile les exemples Rust, Java et C# des cours sous Linux, Windows et macOS. J'ai écrit ces workflows en copiant et en ajustant. Je veux comprendre ce que fait chaque ligne, pourquoi une exécution échoue, et comment la rendre rapide et sûre.

## À qui s'adresse ce cours

Tu sais compiler et tester un projet .NET ou Java en ligne de commande (`dotnet test`, `mvn verify`), et tu connais Git. Tu as peut-être utilisé un autre système de CI — [Azure Pipelines](https://learn.microsoft.com/azure/devops/pipelines/), [Jenkins](https://www.jenkins.io/), [GitLab CI](https://docs.gitlab.com/ci/) — mais ce n'est pas nécessaire.

## À la fin de ce cours, je saurai

- lire n'importe quel fichier de workflow et dire quand il s'exécute, où, et dans quel ordre ;
- compiler et tester du .NET et du Java sur trois systèmes d'exploitation avec une matrix et des caches ;
- choisir les bons déclencheurs et filtres, et éviter les exécutions qui s'empilent ou ne démarrent jamais ;
- transmettre des données entre steps et entre jobs, et contrôler ce qui se passe après un échec ;
- réutiliser des workflows et des actions au lieu de les copier ;
- sécuriser un workflow : permissions du token, secrets, actions épinglées, OIDC ;
- déployer un site statique sur GitHub Pages ;
- diagnostiquer une exécution en échec à partir de ses logs.

## Plan

| # | Leçon | Si tu connais Azure Pipelines |
|---|---|---|
| 1 | [Premier workflow](01-first-workflow/) | pipeline, stage, job, step, agent |
| 2 | [Compiler et tester .NET et Java](02-build-and-test/) | `strategy: matrix`, `UseDotNet@2`, `Cache@2` |
| 3 | [Déclencheurs, filtres et concurrence](03-triggers/) | `trigger`, `pr`, `schedules`, paramètres |
| 4 | [Expressions, contextes et outputs](04-expressions-and-outputs/) | `$[ ]`, variables, variables de sortie, `condition` |
| 5 | [Caches et artefacts](05-caches-and-artifacts/) | `Cache@2`, `PublishPipelineArtifact@1` |
| 6 | [Workflows réutilisables et actions composites](06-reuse/) | templates de step, de job et de stage |
| 7 | [Sécurité : permissions, secrets, épinglage, OIDC](07-security/) | connexions de service, fédération d'identité de charge de travail |
| 8 | Déployer sur GitHub Pages *(à venir)* | environnements, approbations |
| 9 | Déboguer les exécutions *(à venir)* | logs de diagnostic |
| 10 | Écrire sa propre action *(à venir)* | tâches personnalisées |
| — | [Journal](journal/) | |

## Ressources

- [Documentation de GitHub Actions](https://docs.github.com/actions)
- [Référence de la syntaxe des workflows](https://docs.github.com/actions/reference/workflows-and-actions/workflow-syntax)
- [Événements qui déclenchent des workflows](https://docs.github.com/actions/reference/workflows-and-actions/events-that-trigger-workflows)
- [Manuel de GitHub CLI : `gh run`](https://cli.github.com/manual/gh_run)
- [Images des runners](https://github.com/actions/runner-images) : ce qui est installé sur `ubuntu-latest`, `windows-latest`, `macos-latest`
