---
title: 3. Déclencheurs, filtres et concurrence
description: push et pull_request avec filtres de branches et de chemins, exécutions manuelles avec inputs, planifications, et groupes de concurrence qui annulent ou mettent en file d'attente les exécutions.
sidebar:
  order: 3
---

## Choisir les événements

La clé `on:` liste les événements qui démarrent une exécution. Ceux que tu utilises tous les jours :

| Événement | Démarre une exécution quand | Équivalent Azure Pipelines |
|---|---|---|
| `push` | des commits sont poussés sur une branche ou un tag | `trigger:` |
| `pull_request` | une pull request est ouverte, mise à jour (`synchronize`) ou rouverte | `pr:` |
| `workflow_dispatch` | quelqu'un clique sur *Run workflow*, ou lance `gh workflow run` | exécution manuelle avec `parameters:` |
| `schedule` | une expression cron correspond | `schedules:` |
| `workflow_call` | un autre workflow appelle celui-ci (leçon 6) | templates |

[`.github/workflows/gha-03-triggers.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-03-triggers.yml) en combine quatre :

```yaml
# GitHub Actions course, lesson 3: events, filters, manual inputs, schedules, concurrency
name: "GHA 03: triggers"

on:
  push:
    branches: [main]
    paths: ['.github/workflows/gha-03-triggers.yml']
  workflow_dispatch:
    inputs:
      greeting:
        description: Who to greet
        type: string
        default: world
      loud:
        description: Shout the greeting
        type: boolean
        default: false
  schedule:
    - cron: '17 6 * * 1'   # Mondays 06:17 UTC

concurrency:
  group: gha-03-${{ github.ref }}
  cancel-in-progress: true

jobs:
  show:
    runs-on: ubuntu-latest
    steps:
      - name: Which event?
        run: |
          echo "event_name: ${{ github.event_name }}"
          echo "ref:        ${{ github.ref }}"
          echo "actor:      ${{ github.actor }}"
      - name: Manual inputs
        if: github.event_name == 'workflow_dispatch'
        run: |
          echo "greeting: ${{ inputs.greeting }}"
          echo "loud:     ${{ inputs.loud }}"
      - name: Scheduled run
        if: github.event_name == 'schedule'
        run: |
          echo "cron: ${{ github.event.schedule }}"
      - name: Slow step (to see concurrency cancel a run)
        run: sleep 60
```

## Filtres : `branches` et `paths`

`branches: [main]` ignore les push sur les autres branches ; `paths` ignore les push qui ne modifient aucun fichier correspondant. Chaque workflow de ce site utilise `paths`, pour qu'une coquille corrigée dans une leçon ne recompile pas le cours Rust sur trois OS.

Deux avertissements de la documentation :

- **Checks obligatoires.** « Si un workflow est ignoré à cause d'un filtre de chemins, d'un filtre de branches ou d'un message de commit, les checks associés à ce workflow resteront à l'état *Pending*. » Si un workflow filtré par `paths` est un status check *obligatoire* dans une règle de protection de branche, une pull request qui ne touche pas ces chemins ne pourra jamais être fusionnée.
- **Gros diffs.** « Si le diff généré contient plus de 3 000 fichiers et que les fichiers correspondant au filtre du workflow ne figurent pas parmi les 3 000 premiers renvoyés par le filtre, le workflow ne s'exécutera **pas**. »

Et le piège vu dans la [leçon 1](../01-first-workflow/) : si le fichier ne s'analyse pas, ses filtres n'existent pas non plus, et chaque push produit une exécution en échec.

## Exécutions manuelles avec inputs

`workflow_dispatch.inputs` déclare des paramètres typés (`string`, `boolean`, `choice`, `number`, `environment`). Depuis le terminal :

```powershell
gh workflow run gha-03-triggers.yml --field greeting=Grace
```

```text
##[group]Run echo "greeting: Grace"
echo "greeting: Grace"
echo "loud:     false"
greeting: Grace
loud:     false
```

`loud` n'a pas été passé : il a pris sa valeur `default`. Deux limites : le fichier du workflow doit exister **sur la branche par défaut** pour que le bouton et `gh workflow run` fonctionnent, et un bloc `inputs` peut avoir au plus 25 propriétés de premier niveau.

**Les inputs sont vides sur les autres événements.** Le workflow de la leçon 4 a lui aussi un input, `fail`. Sur un `push`, le step `if [ "${{ inputs.fail }}" = "true" ]` est devenu :

```text
if [ "" = "true" ]; then
```

Pas d'erreur, pas de valeur par défaut : une chaîne vide. Teste `github.event_name` ou prévois une valeur de repli dans le script quand un workflow a plusieurs événements.

## Planifications

`cron: '17 6 * * 1'` signifie « minute 17, heure 6, n'importe quel jour du mois, n'importe quel mois, lundi ». D'après la documentation :

- les exécutions planifiées utilisent « le dernier commit de la branche par défaut » ;
- « l'intervalle le plus court pour exécuter des workflows planifiés est d'une fois toutes les 5 minutes » ;
- les exécutions « peuvent être retardées pendant les périodes de forte charge… Les périodes de forte charge incluent le début de chaque heure » — d'où la minute 17 plutôt que 0 ;
- « dans un dépôt public, les workflows planifiés sont automatiquement désactivés lorsqu'aucune activité n'a eu lieu dans le dépôt depuis 60 jours ».

L'expression est en UTC, sauf si tu indiques un fuseau horaire IANA, ce que la documentation permet désormais. *À vérifier : la première exécution du lundi de `gha-03`, à consigner dans le [journal](../journal/).*

## Concurrence : annuler ou mettre en file d'attente

Un **groupe de concurrence** est un nom ; « il ne peut y avoir au plus qu'un job ou workflow en cours d'exécution dans un groupe de concurrence à tout moment ». Ce qui arrive aux autres dépend de `cancel-in-progress` :

| `cancel-in-progress` | Une nouvelle exécution arrive pendant qu'une autre tourne |
|---|---|
| `false` (par défaut) | elle attend à l'état *pending* ; une exécution déjà en attente est **annulée** et remplacée |
| `true` | celle en cours est annulée, la nouvelle démarre |

`gha-03` utilise `group: gha-03-${{ github.ref }}` (un groupe par branche) et `cancel-in-progress: true`. J'ai poussé une modification du fichier, puis lancé deux exécutions manuelles à dix secondes d'écart pendant que la première était dans son `sleep 60` :

```powershell
gh workflow run gha-03-triggers.yml --field greeting=Ada --field loud=true
gh workflow run gha-03-triggers.yml --field greeting=Grace
gh run list --workflow gha-03-triggers.yml --limit 3
```

| Démarrage (UTC) | Événement | Résultat | Durée |
|---|---|---|---|
| 12:46:38 | push | cancelled | 1m10s |
| 12:47:19 | workflow_dispatch (Ada) | cancelled | 12s |
| 12:47:29 | workflow_dispatch (Grace) | success | 1m25s |

Le log de l'exécution du push se termine par :

```text
##[group]Run sleep 60
sleep 60
shell: /usr/bin/bash -e {0}
##[error]The operation was canceled.
```

L'exécution *Ada* a été annulée avant même le démarrage de son job : sa liste de jobs est vide. Seule la dernière exécution du groupe est allée au bout. C'est ce que tu veux pour un build de CI d'une branche : personne n'a besoin du résultat d'un commit déjà remplacé.

### Quand annuler est une erreur : les déploiements

Le workflow de déploiement de ce site n'avait pas de groupe de concurrence. Deux push à 14 secondes d'écart ont démarré deux déploiements, et le second a échoué :

```text
##[error]HttpError: Deployment request failed for cb69dca950b667b876d8d32cfe778a24b6320c59 due to in progress deployment. Please cancel 61e7e4235b7bc138f2f35cd7f61195bdaed4b019 first or wait for it to complete.
```

Annuler un déploiement à mi-chemin est pire qu'attendre, donc la correction [les met en file d'attente](https://github.com/spareilleux/learn/blob/main/.github/workflows/deploy.yml) :

```yaml
concurrency:
  group: pages
  cancel-in-progress: false
```

Avec un nom de groupe fixe (`pages`, pas un par branche) et sans annulation, un déploiement va jusqu'au bout ; si plusieurs push arrivent entre-temps, seul le plus récent attend — les intermédiaires sont annulés pendant leur attente, ce qui ne pose pas de problème, puisque le dernier commit les contient.

## À retenir

- Les filtres `branches` et `paths` économisent des exécutions, mais un check obligatoire ignoré reste *Pending*.
- Les inputs de `workflow_dispatch` sont typés, exigent le fichier sur la branche par défaut, et sont vides sur les autres événements.
- `schedule` fonctionne au mieux : branche par défaut, 5 minutes minimum, retards en début d'heure, désactivé après 60 jours sans activité dans un dépôt public.
- `concurrency` avec `cancel-in-progress: true` ne garde que la dernière exécution de CI ; pour les déploiements, utilise un groupe fixe sans annulation.

## Exercices

1. Une pull request ne modifie que `README.md`. `gha-02-build.yml` est un check obligatoire sur `main`. Qu'affiche la page de la pull request, et quelles sont deux façons d'en sortir ?

<details>
<summary>Solution</summary>

Le check `dotnet (ubuntu-latest)` (et les autres) reste à *Expected — Waiting for status to be reported*, et le bouton de fusion reste bloqué. Solutions : retirer `paths` du déclencheur `pull_request` et sauter plutôt le travail coûteux à l'intérieur du job ; ou ajouter un petit job qui s'exécute toujours, qui dépend des autres, et faire de *ce* job le check obligatoire. *À vérifier : le libellé exact du check en attente sur la page de la pull request.*

</details>

2. Écris un groupe de concurrence pour un workflow de CI qui annule les exécutions dépassées sur les pull requests, mais n'annule jamais celles de `main`.

<details>
<summary>Solution</summary>

```yaml
concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: ${{ github.ref != 'refs/heads/main' }}
```

`cancel-in-progress` accepte une expression. Sur une pull request, `github.ref` vaut `refs/pull/<number>/merge`, donc chaque pull request a son propre groupe et les nouveaux push annulent l'exécution précédente ; sur `main`, les exécutions se mettent en file d'attente.

</details>

3. Tu veux un build nocturne à 02:00, heure de Paris. Pourquoi `cron: '0 2 * * *'` est-il une double erreur ?

<details>
<summary>Solution</summary>

Sans fuseau horaire, c'est 02:00 **UTC** (03:00 ou 04:00 à Paris selon l'heure d'été), et la minute 0 est le moment le plus chargé, celui où les exécutions planifiées ont le plus de chances d'être retardées. Choisis une minute qui n'est pas ronde (`'23 0 * * *'` correspond à 01:23 ou 02:23 à Paris) ou indique le fuseau horaire.

</details>

## Sources

- [Événements qui déclenchent des workflows](https://docs.github.com/actions/reference/workflows-and-actions/events-that-trigger-workflows)
- [Syntaxe des workflows : `on.<push|pull_request>.paths`](https://docs.github.com/actions/reference/workflows-and-actions/workflow-syntax#onpushpull_requestpull_request_targetpathspaths-ignore)
- [Contrôler la concurrence des workflows et des jobs](https://docs.github.com/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency)
- [`gh workflow run` — manuel de GitHub CLI](https://cli.github.com/manual/gh_workflow_run)
