---
title: 9. Déboguer les exécutions
description: Lire une exécution en échec depuis le terminal, regrouper et annoter les logs, activer les logs de débogage, ne relancer que ce qui a échoué, et comprendre les timeouts, les annulations et continue-on-error.
sidebar:
  order: 9
---

## Un workflow qui échoue exprès

[`.github/workflows/gha-09-debug.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-09-debug.yml) a quatre jobs, chacun une situation que tu rencontreras :

```yaml
# GitHub Actions course, lesson 9: reading a failing run, debug logging, re-runs, timeouts
name: "GHA 09: debugging"

on:
  workflow_dispatch:
    inputs:
      fail:
        description: Make the test step fail
        type: boolean
        default: true
  push:
    branches: [main]
    paths: ['.github/workflows/gha-09-debug.yml']

permissions:
  contents: read

jobs:
  noisy:
    runs-on: ubuntu-latest
    steps:
      - name: Groups, debug and notice messages
        run: |
          echo "::group::Environment of the step"
          echo "RUNNER_OS=$RUNNER_OS RUNNER_ARCH=$RUNNER_ARCH"
          echo "RUNNER_DEBUG='${RUNNER_DEBUG:-}'"
          echo "::endgroup::"
          echo "::debug::only visible when step debug logging is on"
          echo "::notice title=Lesson 9::a notice annotation"
      - name: Trace the commands with set -x
        run: |
          set -x
          version=$(date -u +%Y.%m.%d)
          test -n "$version"
      - name: Tests (fail on demand, attempt ${{ github.run_attempt }})
        run: |
          if [ "${{ inputs.fail }}" = "true" ] && [ "${{ github.run_attempt }}" = "1" ]; then
            echo "::error title=Flaky test::failed on attempt ${{ github.run_attempt }}"
            exit 1
          fi
          echo "tests passed on attempt ${{ github.run_attempt }}"

  independent:
    runs-on: ubuntu-latest
    steps:
      - run: echo "this job doesn't depend on noisy"

  allowed-to-fail:
    runs-on: ubuntu-latest
    continue-on-error: true
    steps:
      - run: exit 3

  timeout:
    runs-on: ubuntu-latest
    timeout-minutes: 1
    steps:
      - run: sleep 90
```

Le step de tests n'échoue qu'à la première tentative : un **test instable (flaky)**, la raison la plus courante de relancer.

## Étape 1 : le résumé, depuis le terminal

```powershell
gh workflow run gha-09-debug.yml --field fail=true
gh run view 34850662582
```

La fin de la sortie liste les annotations — chaque `::error`, `::warning` et `::notice`, plus les erreurs ajoutées par le runner :

```text
ANNOTATIONS
X The job has exceeded the maximum execution time of 1m0s
timeout: .github#1

X The operation was canceled.
timeout: .github#5

X Process completed with exit code 1.
noisy: .github#10

X failed on attempt 1
noisy: .github#9

- a notice annotation
noisy: .github#14

X Process completed with exit code 3.
allowed-to-fail: .github#5
```

Lis-les avant tout log : ici, elles disent déjà *quels* jobs ont échoué et *pourquoi* — un timeout, un test, un échec attendu. Le `title=` d'une annotation apparaît dans la page web, pas dans cette liste.

## Étape 2 : seulement les logs en échec

```powershell
gh run view 34850662582 --log-failed
```

Le log complet de cette tentative fait 169 lignes ; `--log-failed` en a renvoyé 15, uniquement les steps en échec de `noisy` et `allowed-to-fail` :

```text
noisy	Tests (fail on demand, attempt 1)	##[error]failed on attempt 1
noisy	Tests (fail on demand, attempt 1)	##[error]Process completed with exit code 1.
allowed-to-fail	Run exit 3	##[error]Process completed with exit code 3.
```

Le job `timeout` n'y est pas : son step a été **annulé**, pas mis en échec. Quand un job semble disparaître de `--log-failed`, regarde sa conclusion.

## Les commandes de workflow qui structurent un log

Dans le log normal du premier step :

```text
##[group]Environment of the step
RUNNER_OS=Linux RUNNER_ARCH=X64
RUNNER_DEBUG=''
##[endgroup]
##[notice]a notice annotation
```

- `::group::title` … `::endgroup::` regroupent des lignes dans une section repliable du log web.
- `::notice`, `::warning`, `::error` créent des annotations (avec `title=`, `file=`, `line=` — [leçon 4](../04-expressions-and-outputs/)).
- `::debug::` n'a **rien** affiché : les messages de débogage sont masqués tant que les logs de débogage ne sont pas activés.

Pour les scripts shell, `set -x` affiche chaque commande après expansion, l'équivalent d'une exécution pas à pas :

```text
++ date -u +%Y.%m.%d
+ version=2026.09.14
+ test -n 2026.09.14
```

## Les logs de débogage

Deux interrupteurs, en secrets ou en variables du dépôt, ou pour une seule relance avec `--debug` :

| Paramètre | Ajoute |
|---|---|
| `ACTIONS_STEP_DEBUG` = `true` | des lignes `##[debug]` : évaluation des conditions, inputs, fichier de script exécuté, messages `::debug::` |
| `ACTIONS_RUNNER_DEBUG` = `true` | les logs de diagnostic du runner dans l'archive des logs |

La troisième tentative de l'exécution a été lancée avec :

```powershell
gh run rerun 34850662582 --debug
```

Le même step, maintenant :

```text
##[debug]Evaluating condition for step: 'Groups, debug and notice messages'
##[debug]Evaluating: success()
##[debug]Evaluating success:
##[debug]=> true
##[debug]Result: true
##[debug]Starting: Groups, debug and notice messages
...
##[debug]/usr/bin/bash -e /home/runner/work/_temp/e3c00f12-b91a-4ef4-830d-2340170b7bc7.sh
::group::Environment of the step
##[group]Environment of the step
RUNNER_OS=Linux RUNNER_ARCH=X64
RUNNER_DEBUG='1'
::endgroup::
##[endgroup]
##[debug]only visible when step debug logging is on
##[notice]a notice annotation
```

- Chaque `if:` montre comment il a été évalué — le moyen le plus rapide de comprendre un step qui a été ignoré.
- `RUNNER_DEBUG` vaut `1` : un script peut afficher davantage quand cette variable est définie.
- Le job `noisy` est passé de 70 à 190 lignes de log.

L'archive des logs de cette tentative, téléchargée avec `gh api repos/spareilleux/learn/actions/runs/34850662582/attempts/3/logs > attempt3.zip`, contient un dossier par job avec un fichier par step, et un dossier `runner-diagnostic-logs` :

```text
runner-diagnostic-logs/103998873521-noisy.zip
    13448  Runner_20260914-134407-utc.log
    73191  Worker_20260914-134409-utc.log
```

Le log *Runner* est celui de l'agent qui prend en charge les jobs ; le log *Worker* est celui du processus qui exécute les steps. Tu en as rarement besoin, sauf quand un job échoue avant son premier step.

## Relancer

La documentation : « Les relances utilisent les privilèges de l'acteur qui a initialement déclenché le workflow … Le workflow utilisera aussi le même `GITHUB_SHA` (SHA du commit) et le même `GITHUB_REF` ». Une relance teste le **même commit** : elle peut révéler un test instable, pas valider un correctif que tu viens de pousser.

La tentative 2 a été lancée avec `gh run rerun 34850662582 --failed` :

```text
noisy            success    attempt=2  13:42:13 → 13:42:16
timeout          cancelled  attempt=2  13:42:13 → 13:43:42
allowed-to-fail  failure    attempt=2  13:42:13 → 13:42:16
independent      success    attempt=2  13:40:15 → 13:40:18
```

- `noisy` a réussi : `github.run_attempt` valait `2`, et même le nom du step a changé (`Tests (fail on demand, attempt 2)`).
- Les trois jobs qui n'avaient pas réussi ont tourné à nouveau — celui qui avait été annulé compris ; `independent` n'a pas été relancé : ses horaires sont ceux de la tentative 1, repris tels quels.
- Chaque tentative garde ses propres logs (`attempts/1/logs`, `attempts/2/logs`…).

## Timeouts et conclusions

`timeout-minutes` vaut par défaut **360** minutes par job. Le job `timeout` était limité à 1 minute et exécutait `sleep 90` :

```text
2026-09-14T13:44:10.0526092Z ##[group]Run sleep 90
2026-09-14T13:45:37.2574842Z ##[error]The operation was canceled.
2026-09-14T13:45:37.3009029Z Terminate orphan process: pid (2052) (sleep)
```

Annulé au bout de 87 secondes, pas 60 — à chaque tentative, et dans l'exercice avec `sleep 300`. Considère la limite comme « annulé un certain temps après la limite », et fixe-la bien en dessous de la durée que tu es prêt à payer.

Les conclusions des exécutions, qui décident de l'icône rouge ou grise :

| Exécution | Jobs | Conclusion de l'exécution |
|---|---|---|
| push | `noisy` ✓, `independent` ✓, `allowed-to-fail` ✗ (continue-on-error), `timeout` annulé | `cancelled` |
| dispatch, tentative 1 | `noisy` ✗, `timeout` annulé, les autres comme ci-dessus | `failure` |
| dispatch, tentatives 2 et 3 | `noisy` ✓, `timeout` annulé | `cancelled` |

Un timeout rend l'exécution *cancelled*, pas *failed* — et une règle de notification ou un check obligatoire qui ne surveille que les échecs passe à côté.

## À retenir

- Commence par `gh run view <id>` (annotations), puis `gh run view <id> --log-failed` ; les jobs annulés ne figurent pas dans les logs en échec.
- `::group::`, `::notice::` et `set -x` rendent les logs lisibles ; `::debug::` a besoin des logs de débogage.
- `gh run rerun --debug` montre comment chaque `if:` a été évalué, et ajoute les logs de diagnostic du runner.
- `gh run rerun --failed` relance chaque job qui n'a pas réussi, sur le même commit.
- Un timeout de job annule le job (ici 87 s pour une limite d'1 minute) et rend l'exécution *cancelled*.

## Exercices

1. Déplace le timeout du job vers le step : `timeout-minutes: 1` sur un step `sleep 300`, suivi d'un step avec `if: always()`. Quelle est la conclusion du step, et le step suivant s'exécute-t-il ?

<details>
<summary>Solution</summary>

Vérifié avec [`gha-09-exercises.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-09-exercises.yml) :

```text
step-timeout | Run date -u +%T | 13:46:49
step-timeout | Run date -u +%T | ##[error]The action 'Run date -u +%T' has timed out after 1 minutes.
step-timeout | Run date -u +%T | 13:48:01
```

Le step a **échoué** (il n'a pas été annulé) au bout de 72 secondes, le step `always()` s'est exécuté, et la conclusion du job était `failure`. Le timeout au niveau du job, dans la même exécution, a annulé son job au bout de 87 secondes (13:46:49 → 13:48:16), avec `sleep 300` : le délai ne dépend pas du script.

</details>

2. Le seul job en échec d'une exécution a `continue-on-error: true`, et un autre job le référence dans `needs`. Quelle est la conclusion de l'exécution, et que contient `needs.allowed-to-fail.result` ?

<details>
<summary>Solution</summary>

```text
allowed-to-fail  failure
after            success
run conclusion   success
needs.allowed-to-fail.result=success
```

Le job est affiché en échec, mais l'exécution réussit — « Mets `true` pour permettre à une exécution de workflow de réussir quand ce job échoue » — et pour le job dépendant, le résultat est `success` : `after` s'est exécuté sans aucun `if:`. Un job dépendant ne peut pas savoir que l'échec a été toléré.

</details>

3. Un job s'est exécuté alors que tu t'attendais à ce que son `if:` le fasse ignorer. Où peux-tu voir comment GitHub a évalué la condition, sans les logs de débogage ?

<details>
<summary>Solution</summary>

Dans le log *system* du job, qui fait partie de l'archive des logs (`gh api repos/<owner>/<repo>/actions/runs/<run-id>/attempts/<n>/logs`), fichier `<job>/system.txt`. Pour `noisy`, à la tentative 1, sans débogage :

```text
Requested labels: ubuntu-latest
Job defined at: spareilleux/learn/.github/workflows/gha-09-debug.yml@refs/heads/main
Waiting for a runner to pick up this job...
Evaluating noisy.if
Evaluating: success()
Result: true
```

Un job sans `if:` est évalué comme `success()`. Pour le `if:` des **steps**, relance avec `--debug` : les lignes `##[debug]Evaluating condition for step` apparaissent dans le log du step.

</details>

## Sources

- [Activer la journalisation de débogage](https://docs.github.com/actions/how-tos/monitor-workflows/enable-debug-logging)
- [Relancer des workflows et des jobs](https://docs.github.com/actions/how-tos/manage-workflow-runs/re-run-workflows-and-jobs)
- [Commandes de workflow](https://docs.github.com/actions/reference/workflows-and-actions/workflow-commands)
- [Syntaxe des workflows : `timeout-minutes`, `continue-on-error`](https://docs.github.com/actions/reference/workflows-and-actions/workflow-syntax#jobsjob_idtimeout-minutes)
- [`gh run view`](https://cli.github.com/manual/gh_run_view) et [`gh run rerun`](https://cli.github.com/manual/gh_run_rerun)
