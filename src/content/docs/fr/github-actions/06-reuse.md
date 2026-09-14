---
title: 6. Workflows réutilisables et actions composites
description: Arrête de copier du YAML — une action composite pour des steps répétés, un workflow réutilisable pour des jobs entiers, avec inputs, outputs, une matrix, et ce que le workflow appelé peut voir ou non.
sidebar:
  order: 6
---

## Le problème du copier-coller

Après cinq leçons, les mêmes quatre lignes reviennent dans plusieurs workflows : `setup-dotnet` avec `global-json-file`, le cache NuGet, `dotnet restore --locked-mode`. GitHub Actions a deux façons de les partager, que les développeurs C# peuvent rapprocher d'idées familières :

| | Action composite | Workflow réutilisable |
|---|---|---|
| Partage | une suite de **steps** | des **jobs** entiers |
| Fichier | `action.yml` dans son propre dossier | un workflow dans `.github/workflows/` avec `on: workflow_call` |
| Appelé depuis | un step : `uses: ./.github/actions/<name>` | un job : `uses: ./.github/workflows/<file>.yml` |
| Choisit le runner | non, s'exécute dans le job de l'appelant | oui, chaque job a son propre `runs-on` |
| Secrets | « Ne peut pas utiliser de secrets » directement — passe-les en inputs | reçoit `secrets:` ou `secrets: inherit` |
| Dans le log | « Journalisée comme un seul step même si elle contient plusieurs steps » | chaque job et chaque step journalisés normalement |
| Analogie C# | une méthode utilitaire appelée au milieu de ton code | un template de build complet |
| Azure Pipelines | template de step | template de job ou de stage |

Les citations viennent du tableau comparatif de la documentation. Les deux peuvent vivre dans le même dépôt ou être appelés depuis un autre (`owner/repo/path@ref`).

## Une action composite

[`.github/actions/dotnet-restore/action.yml`](https://github.com/spareilleux/learn/blob/main/.github/actions/dotnet-restore/action.yml) :

```yaml
# GitHub Actions course, lesson 6: a composite action that installs the SDK and restores with the NuGet cache
name: Set up and restore a .NET solution
description: Installs the SDK pinned by global.json, then restores with the NuGet cache and the lock files.

inputs:
  directory:
    description: Folder that contains global.json, the solution and the packages.lock.json files
    required: true

outputs:
  sdk-version:
    description: The SDK version reported by dotnet --version
    value: ${{ steps.sdk.outputs.version }}

runs:
  using: composite
  steps:
    - name: Keep NuGet packages in the workspace
      shell: bash
      run: echo "NUGET_PACKAGES=$GITHUB_WORKSPACE/.nuget/packages" >> "$GITHUB_ENV"
    - uses: actions/setup-dotnet@v6
      with:
        global-json-file: ${{ inputs.directory }}/global.json
        cache: true
        cache-dependency-path: ${{ inputs.directory }}/*/packages.lock.json
    - id: sdk
      shell: bash
      working-directory: ${{ inputs.directory }}
      run: echo "version=$(dotnet --version)" >> "$GITHUB_OUTPUT"
    - shell: bash
      working-directory: ${{ inputs.directory }}
      run: dotnet restore --locked-mode
```

- Les `inputs` se lisent avec `${{ inputs.directory }}` ; un output doit être relié explicitement à un step interne (`value: ${{ steps.sdk.outputs.version }}`).
- Chaque step `run:` d'une action composite a besoin d'un `shell:` — l'exercice 1 montre ce qui se passe sans.
- Le premier step écrit dans `$GITHUB_ENV` : la variable existe pour les steps suivants de l'action **et** pour le reste du job de l'appelant. Une action composite partage la machine, le workspace et l'environnement du job.

## Un workflow réutilisable

[`.github/workflows/gha-06-dotnet-test.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-06-dotnet-test.yml) utilise l'action et lance les tests :

```yaml
# GitHub Actions course, lesson 6: a reusable workflow that tests the .NET sample on one OS
name: "GHA 06: reusable .NET test"

on:
  workflow_call:
    inputs:
      os:
        description: Runner label
        type: string
        default: ubuntu-latest
    outputs:
      sdk-version:
        description: SDK used by the tests
        value: ${{ jobs.test.outputs.sdk-version }}
      tested-on:
        description: Operating system of the runner
        value: ${{ jobs.test.outputs.tested-on }}

jobs:
  test:
    runs-on: ${{ inputs.os }}
    outputs:
      sdk-version: ${{ steps.setup.outputs.sdk-version }}
      tested-on: ${{ runner.os }}
    steps:
      - uses: actions/checkout@v7
      - id: setup
        uses: ./.github/actions/dotnet-restore
        with:
          directory: code/github-actions/dotnet
      - run: dotnet test --no-restore
        working-directory: code/github-actions/dotnet
      - name: What the called workflow sees
        shell: bash
        run: |
          echo "event_name:         ${{ github.event_name }}"
          echo "github.workflow:    ${{ github.workflow }}"
          echo "github.workflow_ref: ${{ github.workflow_ref }}"
          echo "job.workflow_ref:   ${{ job.workflow_ref }}"
          echo "COURSE from caller: '$COURSE'"
          echo "NUGET_PACKAGES:     $NUGET_PACKAGES"
```

Les outputs remontent deux niveaux : step → job (`jobs.test.outputs`) → workflow (`on.workflow_call.outputs`).

Et l'appelant, [`.github/workflows/gha-06-reuse.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-06-reuse.yml) :

```yaml
# GitHub Actions course, lesson 6: calling a reusable workflow with a matrix, and reading its outputs
name: "GHA 06: reuse"

on:
  workflow_dispatch:
  push:
    branches: [main]
    paths: ['.github/workflows/gha-06-reuse.yml', '.github/workflows/gha-06-dotnet-test.yml', '.github/actions/dotnet-restore/**']

env:
  COURSE: github-actions

jobs:
  test:
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, windows-latest]
    uses: ./.github/workflows/gha-06-dotnet-test.yml
    with:
      os: ${{ matrix.os }}

  summary:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - run: |
          echo "COURSE in the caller: '$COURSE'"
          echo "sdk-version: ${{ needs.test.outputs.sdk-version }}"
          echo "tested-on:   ${{ needs.test.outputs.tested-on }}"
```

Un job qui appelle un workflow réutilisable n'a **pas** de `runs-on` ni de `steps` : seulement `name`, `uses`, `with`, `secrets`, `strategy`, `needs`, `if`, `concurrency`, `permissions` et `cache-mode`.

## Ce que montre l'exécution

```text
test (ubuntu-latest) / test   success
test (windows-latest) / test  success
summary                       success
```

Les jobs s'appellent `<caller job> / <called job>`. Dans l'API, le job Ubuntu a ces steps :

```text
1 Set up job
2 Run actions/checkout@v7
3 Run ./.github/actions/dotnet-restore
4 Run dotnet test --no-restore
5 What the called workflow sees
9 Post Run ./.github/actions/dotnet-restore
10 Post Run actions/checkout@v7
11 Complete job
```

Les quatre steps de l'action composite forment **un seul** step (3), et leurs logs sont des groupes imbriqués à l'intérieur ; les numéros 6 à 8 n'apparaissent pas dans la liste. Le step *Post* 9 est le step post de `setup-dotnet` dans l'action — l'enregistrement du cache NuGet, ignoré ici parce que le cache a été trouvé.

### Ce que voit le workflow appelé

```text
event_name:         push
github.workflow:    GHA 06: reuse
github.workflow_ref: spareilleux/learn/.github/workflows/gha-06-reuse.yml@refs/heads/main
job.workflow_ref:   spareilleux/learn/.github/workflows/gha-06-dotnet-test.yml@refs/heads/main
COURSE from caller: ''
NUGET_PACKAGES:     /home/runner/work/learn/learn/.nuget/packages
```

- Le contexte `github` est celui de l'**appelant** : même événement, même nom de workflow. Pour savoir quel fichier définit le job en cours, lis `job.workflow_ref`.
- `COURSE` est vide. La documentation est explicite : « les variables d'environnement définies dans un contexte `env` au niveau du workflow dans le workflow appelant ne sont pas propagées au workflow appelé ». Passe les valeurs en `inputs`, ou utilise `vars` (variables du dépôt).
- `NUGET_PACKAGES` venait du `$GITHUB_ENV` de l'action composite et a atteint les steps suivants du job.

Et les caches ? L'action a restauré `dotnet-cache-Linux-557e0cce…`, le cache enregistré par le workflow de la [leçon 5](../05-caches-and-artifacts/) : même clé, même chemin, même branche — les caches appartiennent au dépôt, pas à un workflow.

### Les outputs d'une matrix

```text
COURSE in the caller: 'github-actions'
sdk-version: 10.0.401
tested-on:   Windows
```

Deux jobs de matrix définissent `tested-on`, l'appelant a reçu une seule valeur : Windows, le job qui a fini en dernier (13:25:06, contre 13:24:29 pour Ubuntu). C'est la règle documentée : « l'output sera celui défini par le dernier workflow réutilisable de la matrix à se terminer avec succès et à définir réellement une valeur ». N'utilise pas un output de matrix pour quoi que ce soit qui diffère entre les combinaisons ; envoie plutôt un artefact par combinaison.

## Limites à connaître

D'après la référence :

- « Tu peux connecter jusqu'à dix niveaux de workflows » (l'appelant plus neuf niveaux imbriqués) ;
- « Tu peux appeler au maximum 50 workflows réutilisables uniques depuis un même fichier de workflow » ;
- un workflow réutilisable référencé par branche ou par tag peut changer sans prévenir ; un SHA de commit, non. La [leçon 7](../07-security/) revient sur l'épinglage.

## À retenir

- **Steps** répétés → action composite, appelée par un step, exécutée dans le job de l'appelant. **Jobs** répétés → workflow réutilisable, appelé par un job, avec ses propres runners.
- Les steps `run:` d'une action composite ont besoin de `shell:` ; les actions et workflows locaux ont besoin d'`actions/checkout` d'abord (pour les actions) et d'un chemin commençant par `./`.
- Le workflow appelé voit le contexte `github` de l'appelant mais pas son `env` ; utilise `inputs`, `outputs` et `job.workflow_ref`.
- Avec une matrix, l'output d'un workflow réutilisable est celui du dernier job à finir.

## Exercices

1. Retire `shell: bash` d'un step `run:` d'une action composite. Quand l'erreur est-elle détectée, et que dit-elle ?

<details>
<summary>Solution</summary>

Seulement quand un job exécute l'action — le push qui la commite ne signale rien. Vérifié avec [`gha-06-exercises.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-06-exercises.yml) et une action [`exercise-no-shell`](https://github.com/spareilleux/learn/blob/main/.github/actions/exercise-no-shell/action.yml) volontairement cassée :

```text
##[error]/home/runner/work/learn/learn/./.github/actions/exercise-no-shell/action.yml (Line: 8, Col: 7): Required property is missing: shell
##[error]Failed to load /home/runner/work/learn/learn/./.github/actions/exercise-no-shell/action.yml
```

Dans un workflow, `run:` a un shell par défaut ; dans une action composite, il n'en a aucun.

</details>

2. Un job commence directement par `uses: ./.github/actions/dotnet-restore`, sans `actions/checkout`. Que se passe-t-il ?

<details>
<summary>Solution</summary>

```text
##[error]Can't find 'action.yml', 'action.yaml' or 'Dockerfile' under '/home/runner/work/learn/learn/.github/actions/dotnet-restore'. Did you forget to run actions/checkout before running your local action?
```

Une action locale est lue depuis le workspace, qui reste vide jusqu'au checkout. Un workflow réutilisable référencé avec `./` n'a pas ce problème : GitHub le lit dans le dépôt avant le démarrage du job.

</details>

3. L'appelant passe `configuration: Release` dans `with:`, mais `gha-06-dotnet-test.yml` ne déclare que l'input `os`. Quand est-ce que ça échoue ?

<details>
<summary>Solution</summary>

Avant le démarrage de tout job. L'exécution se termine avec la conclusion `startup_failure` et aucun job ; `gh run view` dit seulement « This run likely failed because of a workflow file issue », et la page de l'exécution affiche :

```text
The workflow is not valid. .github/workflows/gha-06-invalid-input.yml (Line: 13, Col: 22): Invalid input, configuration is not defined in the referenced workflow.
```

Vérifié sur une branche temporaire, pour qu'un workflow invalide ne fasse pas échouer chaque push sur `main` (voir la [leçon 1](../01-first-workflow/)). Les inputs sont un contrat vérifié à la création de l'exécution, comme les paramètres d'une méthode à la compilation.

</details>

## Sources

- [Réutiliser des workflows](https://docs.github.com/actions/how-tos/reuse-automations/reuse-workflows)
- [Référence des workflows réutilisables](https://docs.github.com/actions/reference/workflows-and-actions/reusable-workflows)
- [Réutiliser des configurations de workflow : workflows réutilisables ou actions composites](https://docs.github.com/actions/concepts/workflows-and-actions/reusing-workflow-configurations)
- [Syntaxe des métadonnées pour GitHub Actions (`action.yml`)](https://docs.github.com/actions/reference/workflows-and-actions/metadata-syntax)
- [Référence des contextes : `job.workflow_ref`](https://docs.github.com/actions/reference/workflows-and-actions/contexts)
