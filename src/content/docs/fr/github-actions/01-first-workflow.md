---
title: 1. Premier workflow
description: Workflows, événements, jobs, steps et runners — et lire une exécution depuis GitHub CLI.
sidebar:
  order: 1
---

## Le vocabulaire, mis en correspondance

Un **workflow** est un fichier YAML dans `.github/workflows/`. Un **événement** (un push, une pull request, un clic sur *Run workflow*) en démarre une **exécution** (run). Une exécution contient des **jobs** ; chaque job reçoit une machine virtuelle neuve, le **runner**, et exécute ses **steps** dans l'ordre. Un step lance soit un script shell (`run:`), soit une **action** (`uses:`), un morceau de code réutilisable publié dans un dépôt.

| GitHub Actions | Azure Pipelines | Jenkins (déclaratif) |
|---|---|---|
| workflow (`.github/workflows/*.yml`) | pipeline (`azure-pipelines.yml`) | `Jenkinsfile` |
| événement (`on:`) | `trigger:`, `pr:`, `schedules:` | `triggers { }` |
| job | job (les stages sont facultatifs) | `stage` |
| step : `run:` | `script:` / `pwsh:` | `sh` / `bat` |
| step : `uses:` (action) | tâche (`DotNetCoreCLI@2`) | step de plugin |
| runner (`runs-on: ubuntu-latest`) | agent (`pool: vmImage: ubuntu-latest`) | `agent { label '…' }` |

Deux conséquences de « chaque job reçoit une machine neuve » surprennent ceux qui viennent de Jenkins :

- rien n'est sur le disque au début d'un job, **pas même ton code** : tu le récupères explicitement (checkout) ;
- les fichiers ne passent pas d'un job au suivant : les jobs partagent des données par des outputs (leçon 4) ou des artefacts ([leçon 5](../05-caches-and-artifacts/)).

## Le plus petit workflow utile

[`.github/workflows/gha-01-hello.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-01-hello.yml) :

```yaml
# GitHub Actions course, lesson 1: the smallest useful workflow
name: "GHA 01: hello"

on:
  workflow_dispatch:
  push:
    branches: [main]
    paths: ['.github/workflows/gha-01-hello.yml']

jobs:
  hello:
    runs-on: ubuntu-latest
    steps:
      - name: Say hello
        run: echo "Hello from GitHub Actions"

      - name: Where am I?
        run: |
          echo "Event:   ${{ github.event_name }}"
          echo "Commit:  ${{ github.sha }}"
          echo "Runner:  $RUNNER_OS $RUNNER_ARCH"
          echo "Workdir: $(pwd)"
          ls -A

      - name: Check out the repository
        uses: actions/checkout@v7

      - name: Look again
        run: ls -A
```

| Ligne | Signification |
|---|---|
| `name:` | le nom affiché dans l'onglet *Actions* |
| `on: workflow_dispatch` | ajoute un bouton *Run workflow* (et `gh workflow run`) |
| `on: push` avec `branches` et `paths` | s'exécute lors d'un push sur `main` qui modifie ce fichier |
| `jobs.hello.runs-on` | l'image du runner : Ubuntu hébergé par GitHub |
| `run: \|` | un script sur plusieurs lignes, exécuté par `bash` sous Linux et macOS |
| `uses: actions/checkout@v7` | l'[action checkout](https://github.com/actions/checkout), version majeure 7 |

## L'exécution, étape par étape

Le push du fichier a démarré une exécution. Avec [GitHub CLI](https://cli.github.com/) :

```powershell
gh run list --workflow gha-01-hello.yml
gh run view 34845175861
gh run view 34845175861 --log
```

```text
✓ main GHA 01: hello · 34845175861
Triggered via push about 6 minutes ago

JOBS
✓ hello in 4s (ID 103979246921)
```

Le log du step `Where am I?` (horodatages retirés) :

```text
##[group]Run echo "Event:   push"
echo "Event:   push"
echo "Commit:  61e7e4235b7bc138f2f35cd7f61195bdaed4b019"
echo "Runner:  $RUNNER_OS $RUNNER_ARCH"
echo "Workdir: $(pwd)"
ls -A
shell: /usr/bin/bash -e {0}
Event:   push
Commit:  61e7e4235b7bc138f2f35cd7f61195bdaed4b019
Runner:  Linux X64
Workdir: /home/runner/work/learn/learn
```

Trois choses à y lire :

1. **`${{ github.event_name }}` a été remplacé avant l'exécution de bash.** Le script affiché par le runner contient déjà `push` : les expressions sont une substitution de texte faite par GitHub. `$RUNNER_OS` est différent : c'est une variable d'environnement, développée par bash. La leçon 4 y revient, parce que c'est important pour la sécurité.
2. **`ls -A` n'a rien affiché.** Le répertoire de travail `/home/runner/work/learn/learn` existe mais il est vide. Après `actions/checkout`, la même commande liste le dépôt :

   ```text
   .git
   .gitattributes
   .github
   .gitignore
   .vscode
   AGENTS.md
   CLAUDE.md
   README.md
   ```

3. **`shell: /usr/bin/bash -e {0}`** : chaque `run:` est écrit dans un script temporaire et exécuté avec `bash -e`, donc le step échoue à la première commande en échec.

Le step `Set up job` te dit ce que tu as obtenu :

```text
Current runner version: '2.337.0'
Ubuntu
24.04.5
LTS
Image: ubuntu-24.04
Version: 20260907.300.1
GITHUB_TOKEN Permissions
Contents: read
Metadata: read
Packages: read
```

`ubuntu-latest` est une étiquette mouvante : en septembre 2026, c'est Ubuntu 24.04. Et le job a reçu un `GITHUB_TOKEN` qui ne peut que **lire** le dépôt — la [leçon 7](../07-security/) explique comment l'élargir ou le restreindre.

## Piège : un workflow invalide échoue à chaque push

Ma première version du workflow de la leçon 3 contenait une erreur YAML. La liste des exécutions affichait le **chemin du fichier** au lieu du nom du workflow, un échec en 0 seconde, et aucun job :

```text
X main .github/workflows/gha-03-triggers.yml · 34845174629
Triggered via push less than a minute ago

X This run likely failed because of a workflow file issue.
```

La page web de l'exécution donne la raison : `You have an error in your yaml syntax on line 41`. Pire, le push suivant — qui ne touchait pas ce fichier, et le workflow a un filtre `paths` — a produit une autre exécution en échec : GitHub ne peut pas lire les filtres d'un fichier qu'il n'arrive pas à analyser. Le coupable :

```yaml
        run: echo "cron: ${{ github.event.schedule }}"
```

En YAML, une valeur sans guillemets ne peut pas contenir `: ` (deux-points suivi d'une espace). Une vérification locale l'attrape avant le push :

```powershell
python -c "import yaml; yaml.safe_load(open('.github/workflows/gha-03-triggers.yml'))"
```

```text
yaml.scanner.ScannerError: mapping values are not allowed here
  in ".github/workflows/gha-03-triggers.yml", line 41, column 24
```

La correction : un scalaire bloc (`run: |` et la commande sur la ligne suivante), ou mettre toute la valeur entre guillemets.

## À retenir

- Workflow → exécution → jobs (un runner neuf chacun) → steps (`run:` ou `uses:`).
- Un job démarre avec un espace de travail vide : `actions/checkout` est presque toujours le premier step.
- `${{ }}` est remplacé par GitHub avant l'exécution du script ; `$VAR` est développé par le shell.
- `gh run list`, `gh run view` et `gh run view --log` lisent les exécutions sans quitter le terminal.
- Un workflow qui ne s'analyse pas apparaît, à chaque push, comme un échec en 0 seconde portant le nom de son fichier.

## Exercices

1. Dans `gha-01-hello.yml`, qu'afficherait `ls -A` dans le step `Where am I?` si `actions/checkout` était le premier step ?

<details>
<summary>Solution</summary>

Les fichiers du dépôt (`.git`, `.github`, `AGENTS.md`…), comme le step `Look again`. Le checkout clone dans le répertoire de travail, `/home/runner/work/learn/learn`, là où démarre chaque `run:`.

</details>

2. Ajoute un step qui échoue, lance le workflow avec `gh workflow run gha-01-hello.yml`, et retrouve le step en échec depuis le terminal.

<details>
<summary>Solution</summary>

```yaml
      - name: Fail on purpose
        run: exit 1
```

```powershell
gh workflow run gha-01-hello.yml
gh run list --workflow gha-01-hello.yml --limit 1
gh run view <run-id> --log-failed
```

`--log-failed` n'affiche que les logs des steps en échec, qui se terminent par `##[error]Process completed with exit code 1.`. Les steps suivants ne s'exécutent pas, sauf s'ils ont une condition comme `if: always()` (leçon 4).

</details>

3. Pourquoi `echo "Runner: $RUNNER_OS"` fonctionne-t-il dans un step `run:` alors que `echo "cron: $X"` a cassé le YAML ?

<details>
<summary>Solution</summary>

La première ligne est dans un scalaire bloc (`run: |`), où YAML prend le texte tel quel. La seconde était un scalaire simple (sans guillemets) sur la même ligne que `run:`, et un scalaire simple ne peut pas contenir `: `. Le shell n'y est pour rien : le fichier est rejeté avant le démarrage de tout runner.

</details>

## Sources

- [Comprendre GitHub Actions](https://docs.github.com/actions/get-started/understand-github-actions)
- [Syntaxe des workflows pour GitHub Actions](https://docs.github.com/actions/reference/workflows-and-actions/workflow-syntax)
- [`gh run view` — manuel de GitHub CLI](https://cli.github.com/manual/gh_run_view)
- [Spécification YAML 1.2 — scalaires simples](https://yaml.org/spec/1.2.2/#733-plain-style)
