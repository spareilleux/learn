---
title: Journal
description: Notes de progression datées — exécutions, erreurs et points à vérifier.
sidebar:
  order: 99
---

## Progression

- [x] Code d'exemple : la même fonction de slug en .NET (xUnit v3) et en Java (JUnit 6)
- [x] Leçon 1 : premier workflow, lire les exécutions avec `gh`
- [x] Leçon 2 : build en matrix sur trois OS, setup-dotnet, setup-java, cache Maven
- [x] Leçon 3 : déclencheurs, filtres, inputs, concurrence
- [x] Leçon 4 : expressions, contextes, outputs, conditions
- [x] Leçon 5 : caches et artefacts (cache NuGet avec `packages.lock.json`, `actions/cache`, artefacts entre jobs)
- [ ] Leçon 6 : workflows réutilisables et actions composites
- [ ] Leçon 7 : sécurité — permissions, secrets, épinglage, OIDC
- [ ] Leçon 8 : déployer sur GitHub Pages
- [ ] Leçon 9 : déboguer les exécutions
- [ ] Leçon 10 : écrire sa propre action

## 2026-09-14 — D'abord en local : deux pièges de xUnit v3

Avant d'écrire le moindre workflow, `dotnet test` sur le projet d'exemple (SDK 10.0.112 en local, `xunit.v3` 4.0.1) a échoué deux fois :

1. `Testing with VSTest target is no longer supported by Microsoft.Testing.Platform on .NET 10 SDK and later.` Correction : `"test": { "runner": "Microsoft.Testing.Platform" }` dans `global.json`.
2. `CS0246: The type or namespace name 'Theory' could not be found`. Avec `ImplicitUsings` activé, cette version du paquet n'ajoutait pas `using Xunit`. Correction : le `using` dans le fichier de test.

Le côté Java (`mvn -B verify`, JUnit 6.1.3, Maven 3.9.16) est passé du premier coup.

## 2026-09-14 — Premier push : quatre workflows, dont un invalide

Le push des quatre workflows des leçons (commit `61e7e42`) les a tous démarrés. `GHA 01`, `GHA 02` (6 jobs) et `GHA 04` sont passés. `GHA 03` est apparu sous son nom de fichier, en échec en 0 s, sans aucun job : `You have an error in your yaml syntax on line 41`, une ligne `run: echo "cron: …"` (une valeur sans guillemets contenant `: `). Le push suivant, sans rapport avec ce fichier, l'a de nouveau mis en échec, malgré son filtre `paths`.

Un second commit le même après-midi a répété l'erreur dans `gha-04-exercises.yml` (`run: echo "next: $BUILD_LABEL"`) ; cette fois, `python -c "import yaml; yaml.safe_load(...)"` l'a attrapée avant le push. Leçon : valider le YAML en local, à chaque fois.

## 2026-09-14 — Deux déploiements de ce site sont entrés en collision

Les push `61e7e42` et `cb69dca`, à 14 s d'écart, ont chacun démarré `Deploy to GitHub Pages`. Le second job de déploiement a échoué :

```text
##[error]HttpError: Deployment request failed for cb69dca950b667b876d8d32cfe778a24b6320c59 due to in progress deployment. Please cancel 61e7e4235b7bc138f2f35cd7f61195bdaed4b019 first or wait for it to complete.
```

Le site est resté sur la version précédente jusqu'au push suivant. Correction dans `deploy.yml` (commit `5c9896f`) : `concurrency: { group: pages, cancel-in-progress: false }`. Plusieurs sessions poussent sur ce dépôt, donc les collisions allaient forcément se reproduire.

## 2026-09-14 — Mesures

- Cache Maven, `gha-02`, première exécution → deuxième exécution : Ubuntu 16 s → 10 s, Windows 43 s → 28 s, macOS 20 s → 9 s. Jobs .NET inchangés (21/60/20 s → 22/57/22 s) : pas encore de cache NuGet.
- `global.json` `10.0.100` + `latestFeature` → `setup-dotnet` a installé le SDK 10.0.401.
- Temurin 25.0.4 était préinstallé sur `ubuntu-latest` (`Resolved Java 25.0.4+1 from tool-cache`).
- `macos-latest` est en arm64 (clé de cache `setup-java-macOS-arm64-maven-…`).
- Shell par défaut de `run:` : `/usr/bin/bash -e {0}` (Ubuntu), `/bin/bash -e {0}` (macOS), `pwsh -command ". '{0}'"` (Windows). `shell: bash` explicite sous Windows : `bash.EXE --noprofile --norc -e -o pipefail {0}`, bash 5.3.15.
- Permissions par défaut du `GITHUB_TOKEN` sur ce dépôt : `Contents: read`, `Metadata: read`, `Packages: read`. Le token faisait 377 caractères.
- Concurrence avec `cancel-in-progress: true` : exécution du push annulée par une exécution manuelle 41 s plus tard, elle-même annulée 10 s après par une autre, avant le démarrage de son job.

## 2026-09-14 — Leçon 5 : un cache qui ne fait rien gagner, un conflit d'artefacts qui n'arrive pas

- `setup-dotnet` `cache: true` sans aucun `packages.lock.json` : `Dependencies lock file is not found in /home/runner/work/learn/learn`. Ajout de `RestorePackagesWithLockFile` dans `Directory.Build.props`, commit des deux fichiers de verrouillage, `dotnet restore --locked-mode` en CI.
- Cache NuGet, sans cache → cache trouvé : step de restauration 3 s → 1 s (Ubuntu, macOS), 5 s → 4 s (Windows), pour un cache de 54 Mo par OS. Le téléchargement du cache coûte à peu près ce qu'il fait gagner sur un projet à trois paquets de test. Gardé pour la leçon et pour les fichiers de verrouillage.
- Output `cache-hit` d'`actions/cache` : vide quand aucun cache n'est trouvé, `false` sur une correspondance `restore-keys`, `true` quand la clé exacte est trouvée.
- Deux jobs de matrix qui envoient un artefact nommé `os` : le README annonce des erreurs de conflit ; trois exécutions sur trois, les deux envois ont réussi et l'exécution avait deux artefacts nommés `os`. `download-artifact` et `gh run download --name os` ont tous deux renvoyé celui d'Ubuntu, sans avertissement.
- Expiration des artefacts : 7 jours avec `retention-days: 7`, sinon 90 jours (`gh api repos/spareilleux/learn/actions/permissions/artifact-and-log-retention` → `{"days":90,"maximum_allowed_days":90}`).

## Questions ouvertes

- Le déclencheur `schedule` de `gha-03` (le lundi à 06:17 UTC) s'exécute-t-il à l'heure ? *À vérifier le 2026-09-21.*
- Quel artefact `download-artifact` choisit-il quand deux portent le même nom, et ce choix est-il stable ? *À vérifier.*
- Qu'affiche exactement la page d'une pull request pour un check obligatoire ignoré à cause de `paths` ? *À vérifier.*
