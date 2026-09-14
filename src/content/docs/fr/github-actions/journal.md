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
- [x] Leçon 6 : workflows réutilisables et actions composites
- [x] Leçon 7 : sécurité — permissions, secrets, épinglage, OIDC
- [x] Leçon 8 : déployer sur GitHub Pages
- [x] Leçon 9 : déboguer les exécutions
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

## 2026-09-14 — Leçon 6 : la réutilisation, et une branche pour un workflow invalide

- L'action composite `dotnet-restore` a restauré le cache NuGet enregistré par `gha-05` : même clé et même chemin, un autre workflow. Les caches appartiennent au dépôt et à la branche.
- Dans le workflow appelé : `github.workflow` est le nom de l'appelant, `job.workflow_ref` pointe vers `gha-06-dotnet-test.yml`, l'`env` de niveau workflow de l'appelant est vide.
- Matrix de deux appels de workflow réutilisable : l'output `tested-on` valait `Windows`, le job qui a fini en dernier.
- `run:` d'action composite sans `shell:` : `Required property is missing: shell`, seulement quand un job exécute l'action.
- Input non déclaré : `startup_failure`, aucun job, et `gh run view` n'affiche pas la raison (la page de l'exécution, si). Testé depuis une branche temporaire `gha-06-invalid` pour que `main` ne porte jamais de workflow invalide. La suppression de la branche distante a été bloquée par un hook de sécurité local : elle est toujours là, à supprimer à la main.

## 2026-09-14 — Leçon 7 : des permissions qui ne restreignent pas, et une injection qui s'exécute

- `gh run list` depuis un job avec seulement `contents: read` (sans `actions: read`) a fonctionné : données publiques d'un dépôt public. Remplacé par la création d'une étiquette au nom vide : 403 `Resource not accessible by integration` sans `issues: write`, 422 `Validation Failed` avec — rien de créé dans les deux cas.
- `permissions: actions: read` au niveau du job → le token a perdu `Contents`, et `actions/checkout` a quand même fonctionné sur ce dépôt public.
- L'input `workflow_dispatch` `$(whoami)`, collé avec `${{ }}` dans `run:`, a affiché `runner` ; passé par `env:`, il a affiché `$(whoami)`.
- `::add-mask::` ne masque la valeur que dans les lignes affichées après lui.
- Token OIDC pour l'audience `learn-course` : durée de vie 300 s, `sub` = `repo:spareilleux@6644695/learn@1368550922:ref:refs/heads/main`, le format immuable des dépôts créés après le 2026-07-15.

## 2026-09-14 — Leçon 8 : le déploiement de ce site, démonté

- Une exécution de déploiement : `build` 30 s (310 pages construites en 7,47 s, artefact `github-pages` de 9 108 634 octets conservé 1 jour), `deploy` 8 s. Statuts du déploiement : `waiting` → `queued` → `in_progress` → `success` en 13 s.
- La file d'attente de concurrence a fonctionné : un push 41 s après un autre a attendu 14 s, et son job `build` a été créé à 13:32:18, la seconde où le job `deploy` précédent s'est terminé.
- `gh workflow run deploy.yml --ref gha-06-invalid` : le build a tourné, le job de déploiement a été rejeté (`Branch "gha-06-invalid" is not allowed to deploy to github-pages due to environment protection rules`), le site en ligne n'a pas changé. Vérifié au préalable qu'aucun déploiement de `main` n'était en attente, puisque l'exécution de la branche partage le groupe de concurrence `pages`.
- `https://spareilleux.github.io/method/` → 404 : un lien absolu depuis la racine sort du site du projet.

## 2026-09-14 — Leçon 9 : des timeouts qui prennent plus de temps, et un échec qui compte comme un succès

- `gh run view --log-failed` : 15 lignes sur 169 ; le job annulé par son timeout n'y figure pas.
- `gh run rerun --debug` : évaluations de conditions `##[debug]`, `RUNNER_DEBUG=1`, le job `noisy` passé de 70 à 190 lignes, et un dossier `runner-diagnostic-logs` (logs Runner et Worker) dans l'archive.
- `gh run rerun --failed` a relancé les jobs en échec et le job annulé, et a conservé celui qui avait réussi à la tentative 1.
- `timeout-minutes: 1` sur un job : annulé au bout de 87 s, trois fois, avec `sleep 90` ou `sleep 300`. Sur un step : en échec au bout de 72 s, `The action 'Run date -u +%T' has timed out after 1 minutes.`
- Une exécution dont les jobs ont réussi, échoué avec `continue-on-error` ou été annulés par un timeout se termine `cancelled`. Avec seulement l'échec `continue-on-error`, elle se termine `success`, et `needs.<job>.result` vaut `success`.

## Questions ouvertes

- Le déclencheur `schedule` de `gha-03` (le lundi à 06:17 UTC) s'exécute-t-il à l'heure ? *À vérifier le 2026-09-21.*
- Quel artefact `download-artifact` choisit-il quand deux portent le même nom, et ce choix est-il stable ? *À vérifier.*
- `actions/checkout` échoue-t-il sur un dépôt privé quand le token du job n'a pas la permission `contents` ? *À vérifier.*
- Pourquoi un timeout de job d'1 minute s'applique-t-il au bout de 87 s ? *À vérifier* avec des limites plus longues.
- Qu'affiche exactement la page d'une pull request pour un check obligatoire ignoré à cause de `paths` ? *À vérifier.*
