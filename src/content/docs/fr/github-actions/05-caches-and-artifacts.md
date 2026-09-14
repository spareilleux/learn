---
title: 5. Caches et artefacts
description: Les fichiers de verrouillage NuGet et le cache de setup-dotnet, actions/cache et ses clés, envoyer et télécharger des artefacts entre jobs — avec le temps que le cache a vraiment fait gagner.
sidebar:
  order: 5
---

## Deux façons de garder des fichiers

Chaque job démarre sur une machine neuve ([leçon 1](../01-first-workflow/)). GitHub propose deux stockages qui survivent à un job, et la documentation insiste : ils « ne peuvent pas être utilisés de manière interchangeable » :

| | Cache | Artefact |
|---|---|---|
| Contient | des fichiers que tu pourrais régénérer : paquets téléchargés, builds intermédiaires | des fichiers qu'un job a **produits** : rapports de tests, paquets, binaires |
| Partagé entre | les exécutions du dépôt (par clé et par branche) | les jobs d'**une** exécution, et les personnes qui le téléchargent |
| Absent ? | le job doit quand même fonctionner, simplement plus lentement | le job qui en a besoin échoue |
| Durée de vie | supprimé après 7 jours sans accès, 10 Go par dépôt par défaut | 90 jours par défaut, `retention-days` pour la raccourcir |
| Actions | [`actions/cache`](https://github.com/actions/cache), ou `cache:` dans les actions `setup-*` | [`actions/upload-artifact`](https://github.com/actions/upload-artifact), [`actions/download-artifact`](https://github.com/actions/download-artifact) |
| Azure Pipelines | `Cache@2` | `PublishPipelineArtifact@1`, `DownloadPipelineArtifact@2` |

## Un cache NuGet a besoin de fichiers de verrouillage

La [leçon 2](../02-build-and-test/) l'a mesuré : le cache Maven de `setup-java` a fait gagner de 6 à 15 secondes par job, tandis que les jobs .NET ne mettaient rien en cache. `setup-dotnet` a un input `cache: true`, mais son README indique que la clé de cache est le hash des fichiers `packages.lock.json`, et que « si le fichier de verrouillage n'existe pas, cette action lève une erreur ». Le projet d'exemple n'en avait aucun.

Un [fichier de verrouillage NuGet](https://learn.microsoft.com/nuget/consume-packages/package-references-in-project-files#locking-dependencies) enregistre la version exacte et le hash du contenu de chaque paquet, direct ou transitif — l'équivalent de `package-lock.json` pour npm. Une seule propriété dans un [`Directory.Build.props`](https://learn.microsoft.com/visualstudio/msbuild/customize-by-directory) placé à côté de la solution l'active pour tous les projets ([`dotnet/Directory.Build.props`](https://github.com/spareilleux/learn/blob/main/code/github-actions/dotnet/Directory.Build.props)) :

```xml
<Project>

  <PropertyGroup>
    <!-- Write packages.lock.json next to each project: setup-dotnet's cache key is its hash (lesson 5) -->
    <RestorePackagesWithLockFile>true</RestorePackagesWithLockFile>
  </PropertyGroup>

</Project>
```

Un `dotnet restore` en local a alors écrit `Slugs/packages.lock.json` (5 lignes, aucun paquet) et `Slugs.Tests/packages.lock.json` (170 lignes : les trois paquets de test et leurs dépendances). Les deux sont commités. En CI, `dotnet restore --locked-mode` échoue au lieu de mettre le fichier à jour en silence quand un paquet ne lui correspond plus.

## Le workflow

[`.github/workflows/gha-05-artifacts.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-05-artifacts.yml) a quatre jobs : `test` sur trois OS avec le cache NuGet et un rapport de tests, `pack` construit un paquet NuGet, `cache-demo` utilise directement `actions/cache`, et `report` télécharge les artefacts des deux premiers.

```yaml
# GitHub Actions course, lesson 5: dependency caches, actions/cache, build artifacts between jobs
name: "GHA 05: caches and artifacts"

on:
  workflow_dispatch:
  push:
    branches: [main]
    paths: ['.github/workflows/gha-05-artifacts.yml', 'code/github-actions/dotnet/**']

jobs:
  test:
    name: test (${{ matrix.os }})
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    env:
      NUGET_PACKAGES: ${{ github.workspace }}/.nuget/packages
    defaults:
      run:
        working-directory: code/github-actions/dotnet
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-dotnet@v6
        with:
          global-json-file: code/github-actions/dotnet/global.json
          cache: true
          cache-dependency-path: code/github-actions/dotnet/*/packages.lock.json
      - run: dotnet restore --locked-mode
      - run: dotnet test --no-restore --report-xunit-junit --report-xunit-junit-filename slugs.junit.xml --results-directory TestResults
      - name: Upload the test report
        if: always()
        uses: actions/upload-artifact@v7
        with:
          name: test-results-${{ matrix.os }}
          path: code/github-actions/dotnet/TestResults/
          retention-days: 7

  pack:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: code/github-actions/dotnet
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-dotnet@v6
        with:
          global-json-file: code/github-actions/dotnet/global.json
      - run: dotnet pack Slugs/Slugs.csproj --configuration Release --output dist -p:Version=1.0.${{ github.run_number }}
      - uses: actions/upload-artifact@v7
        with:
          name: package
          path: code/github-actions/dotnet/dist/*.nupkg
          if-no-files-found: error

  cache-demo:
    runs-on: ubuntu-latest
    steps:
      - name: Restore the cache
        id: cache
        uses: actions/cache@v6
        with:
          path: expensive
          key: gha-05-expensive-${{ runner.os }}-v1
      - name: Show the cache-hit output
        run: echo "cache-hit='${{ steps.cache.outputs.cache-hit }}'"
      - name: Produce the files only on a miss
        if: steps.cache.outputs.cache-hit != 'true'
        run: |
          mkdir -p expensive
          date -u +%FT%TZ > expensive/created-at.txt
          echo "produced"
      - run: cat expensive/created-at.txt

  report:
    needs: [test, pack]
    if: ${{ !cancelled() }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/download-artifact@v8
        with:
          pattern: test-results-*
          path: results
      - uses: actions/download-artifact@v8
        with:
          name: package
          path: package
      - run: find results package -type f | sort
      - name: Tests per OS
        run: |
          for f in results/*/slugs.junit.xml; do
            echo "$(dirname "$f"): $(grep -o 'tests="[0-9]*" failures="[0-9]*"' "$f" | head -1)"
          done
```

| Élément | Pourquoi |
|---|---|
| `NUGET_PACKAGES` | déplace le dossier global des paquets NuGet dans le workspace, comme le recommande le README de `setup-dotnet` : le cache ne contient alors que les paquets de ce projet, pas ce que l'image du runner a déjà |
| `cache-dependency-path` | les fichiers de verrouillage ne sont pas à la racine du dépôt, là où `setup-dotnet` cherche par défaut |
| `--report-xunit-junit` | une option de xUnit v3 (voir `dotnet test --help`) qui écrit un rapport JUnit XML ; `--results-directory` choisit le dossier |
| `if: always()` sur l'envoi | le rapport est surtout utile quand les tests **échouent** |
| `name: test-results-${{ matrix.os }}` | un artefact par job de la matrix, avec un nom distinct |
| `if-no-files-found: error` | la valeur par défaut est `warn` : un mauvais chemin n'enverrait rien et le job passerait quand même |

## Exécution 1 → exécution 2 : ce qu'a fait le cache

La première exécution, sur le push, n'a trouvé aucun cache et en a enregistré un par OS à la fin du job (le step *Post*) :

```text
test (ubuntu-latest) | Dotnet cache is not found
test (ubuntu-latest) | Cache saved with the key: dotnet-cache-Linux-557e0cce818be1e496015809f30b8f55625063a595165d73158bbd2bdf0b419c
```

Une deuxième exécution, lancée avec `gh workflow run gha-05-artifacts.yml`, l'a restauré :

```text
test (ubuntu-latest) | Cache hit for: dotnet-cache-Linux-557e0cce818be1e496015809f30b8f55625063a595165d73158bbd2bdf0b419c
test (ubuntu-latest) | Cache Size: ~54 MB (56306437 B)
test (ubuntu-latest) | Cache restored from key: dotnet-cache-Linux-557e0cce818be1e496015809f30b8f55625063a595165d73158bbd2bdf0b419c
test (ubuntu-latest) |   Restored /home/runner/work/learn/learn/code/github-actions/dotnet/Slugs.Tests/Slugs.Tests.csproj (in 294 ms).
test (ubuntu-latest) | Cache hit occurred on the primary key dotnet-cache-Linux-557e0cce818be1e496015809f30b8f55625063a595165d73158bbd2bdf0b419c, not saving cache.
```

Le même hash sur les trois OS (les fichiers de verrouillage sont identiques), préfixé par `Linux`, `Windows` ou `macOS` : trois caches d'environ 54 Mo chacun, visibles avec `gh cache list`.

Maintenant, ce qui compte vraiment — les durées des steps, d'après `gh api repos/spareilleux/learn/actions/runs/<run-id>/jobs` :

| Step | Ubuntu sans cache → cache trouvé | Windows sans cache → cache trouvé | macOS sans cache → cache trouvé |
|---|---|---|---|
| `setup-dotnet` (installation du SDK + restauration du cache) | 9 s → 11 s | 35 s → 29 s | 20 s → 12 s |
| `dotnet restore --locked-mode` | 3 s → 1 s | 5 s → 4 s | 3 s → 1 s |
| *Post* `setup-dotnet` (enregistrement du cache) | 1 s → 0 s | 5 s → 1 s | 4 s → 0 s |

Le step de restauration lui-même est passé de 3 s à 1 s. Télécharger 54 Mo de cache coûte à peu près autant : sur ce tout petit projet, le cache NuGet **ne fait presque rien gagner**, et les grandes variations du step `setup-dotnet` viennent du téléchargement du SDK, pas du cache. Il devient rentable quand une restauration télécharge des centaines de paquets, et c'est à ce moment-là qu'il faut l'ajouter — après avoir mesuré, comme ici. Les fichiers de verrouillage valent la peine d'être gardés de toute façon : ils font restaurer à la CI exactement ce qui a été testé en local.

## `actions/cache` directement

`setup-java` et `setup-dotnet` construisent la clé pour toi. Avec [`actions/cache`](https://github.com/actions/cache), tu choisis toi-même `path` et `key`. Le job `cache-demo`, sur les deux exécutions :

```text
Run 1
Cache not found for input keys: gha-05-expensive-Linux-v1
cache-hit=''
produced
2026-09-14T13:12:25Z
Cache saved with key: gha-05-expensive-Linux-v1

Run 2
Cache restored from key: gha-05-expensive-Linux-v1
cache-hit='true'
2026-09-14T13:12:25Z
Cache hit occurred on the primary key gha-05-expensive-Linux-v1, not saving cache.
```

- Quand le cache n'est pas trouvé, `cache-hit` est une **chaîne vide**, pas `'false'` : teste `!= 'true'`, jamais `== 'false'`.
- La deuxième exécution a affiché la date écrite par la première : les fichiers sont revenus.
- Un cache n'est **jamais mis à jour** : quand il est trouvé, rien n'est enregistré, même si le job a modifié les fichiers. Pour stocker un nouveau contenu, change la clé — ici le suffixe `-v1`, ou un `hashFiles()` des fichiers qui définissent le contenu.
- Le cache est enregistré par un step *Post*, à la fin du job, seulement si le job a réussi (`post-if: success()` dans le `action.yml` de l'action).

### Quels caches une exécution peut voir

D'après la documentation : « les exécutions de workflow peuvent restaurer les caches créés soit dans la branche courante, soit dans la branche par défaut », plus la branche de base pour une pull request ; pas les caches des branches enfants ou sœurs. Un cache créé par une exécution `pull_request` appartient à la ref de merge et « ne peut être restauré que par les réexécutions de la pull request ». En pratique : laisse un `push` sur `main` remplir les caches, et chaque branche et chaque pull request partent de ceux-là.

## Artefacts

Chaque job `test` a envoyé son rapport, `pack` a envoyé le paquet :

```text
test (ubuntu-latest) | Artifact test-results-ubuntu-latest has been successfully uploaded! Final size is 510 bytes. Artifact ID is 10348099499
pack                 | Successfully created package '/home/runner/work/learn/learn/code/github-actions/dotnet/dist/Slugs.1.0.1.nupkg'.
pack                 | Artifact package has been successfully uploaded! Final size is 3463 bytes. Artifact ID is 10349121193
```

`report` les a téléchargés. Avec `pattern`, chaque artefact correspondant va dans son propre sous-dossier (`merge-multiple: true` mettrait tous les fichiers dans un seul dossier) :

```text
Found 4 artifact(s)
Filtering artifacts by pattern 'test-results-*'
Total of 3 artifact(s) downloaded
package/Slugs.1.0.1.nupkg
results/test-results-macos-latest/slugs.junit.xml
results/test-results-ubuntu-latest/slugs.junit.xml
results/test-results-windows-latest/slugs.junit.xml
results/test-results-macos-latest: tests="4" failures="0"
results/test-results-ubuntu-latest: tests="4" failures="0"
results/test-results-windows-latest: tests="4" failures="0"
```

Dates d'expiration, d'après `gh api repos/spareilleux/learn/actions/runs/<run-id>/artifacts` : 7 jours pour les rapports (`retention-days: 7`), 90 jours pour le paquet — la valeur par défaut du dépôt, le maximum autorisé pour un dépôt public.

Les mêmes artefacts sur ta machine, avec la [GitHub CLI](https://cli.github.com/manual/gh_run_download) :

```powershell
gh run download 34848185308 --repo spareilleux/learn --name package --dir package
gh run download 34848185308 --repo spareilleux/learn --pattern "test-results-*" --dir results
```

```text
package/Slugs.1.0.2.nupkg
results/test-results-macos-latest/slugs.junit.xml
results/test-results-ubuntu-latest/slugs.junit.xml
results/test-results-windows-latest/slugs.junit.xml
```

## À retenir

- Cache = fichiers régénérables partagés entre exécutions ; artefact = fichiers produits par une exécution, partagés entre ses jobs et avec des personnes.
- `setup-dotnet` `cache: true` exige `packages.lock.json` (`RestorePackagesWithLockFile`) ; restaure avec `--locked-mode`.
- Mesure : ici le cache NuGet a fait passer une restauration de 3 s à 1 s, et a coûté autant à télécharger.
- `cache-hit` vaut `'true'` ou est vide ; un cache est immuable, change donc la clé pour le rafraîchir.
- Donne à chaque job de matrix son propre nom d'artefact, fixe `if-no-files-found: error`, et raccourcis `retention-days` pour les rapports.

## Exercices

1. Deux jobs de matrix (`ubuntu-latest`, `macos-latest`) envoient un artefact avec le **même** nom, `os`, contenant un fichier avec le nom de l'OS. Un job suivant télécharge `name: os`. Que se passe-t-il ?

<details>
<summary>Solution</summary>

Le README d'upload-artifact dit que « les artefacts créés par upload-artifact@v4 sont immuables », et avertit que dans une matrix, envoyer vers le même artefact signifie que « tu rencontreras des erreurs de conflit ». Ce n'est pas ce qui s'est passé dans [`gha-05-exercises.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-05-exercises.yml), trois fois de suite : les deux envois ont réussi et l'exécution avait **deux** artefacts nommés `os`.

```text
same-name (macos-latest)  | Artifact os has been successfully uploaded! Final size is 141 bytes. Artifact ID is 10348738133
same-name (ubuntu-latest) | Artifact os has been successfully uploaded! Final size is 142 bytes. Artifact ID is 10348957530
same-name-download        | Downloading single artifact
same-name-download        | ubuntu-latest
```

Le téléchargement a pris l'un des deux sans le moindre avertissement — celui d'Ubuntu, aussi bien dans le job qu'avec `gh run download --name os`. Le choix n'est pas documenté : *à vérifier* s'il est stable. Dans tous les cas, un rapport peut disparaître en silence. Mets la valeur de la matrix dans le nom.

</details>

2. Retire l'input `cache-dependency-path` et utilise `dotnet-version: 10.0.x` au lieu de `global-json-file`, en gardant `cache: true`. Que fait le job ?

<details>
<summary>Solution</summary>

Il échoue dans le step `setup-dotnet`, après avoir installé le SDK :

```text
##[error]Dependencies lock file is not found in /home/runner/work/learn/learn. Supported file patterns: packages.lock.json
```

Sans `cache-dependency-path`, l'action cherche `packages.lock.json` uniquement à la racine du dépôt. Le cache n'est pas facultatif une fois que tu le demandes : pas de fichier de verrouillage, pas de job.

</details>

3. Un step utilise `key: counter-${{ github.run_id }}` et `restore-keys: counter-`, puis incrémente un nombre stocké dans le dossier mis en cache. Qu'affichent `cache-hit` et le compteur à la première exécution, et à la deuxième ?

<details>
<summary>Solution</summary>

```text
Run 1
Cache not found for input keys: gha-05-counter-34847802892, gha-05-counter-
cache-hit=''
counter is now 1
Cache saved with key: gha-05-counter-34847802892

Run 2
Cache restored from key: gha-05-counter-34847802892
cache-hit='false'
counter is now 2
Cache saved with key: gha-05-counter-34848189352
```

À l'exécution 2, la clé exacte n'existait pas (nouveau `run_id`), mais le préfixe `gha-05-counter-` correspondait au cache le plus récent : `cache-hit` vaut `'false'` — une correspondance partielle —, les fichiers sont quand même restaurés, et comme la clé exacte n'a pas été trouvée, un nouveau cache est enregistré à la fin. C'est ainsi qu'on construit un cache incrémental qui s'améliore d'exécution en exécution, au prix d'une nouvelle entrée de cache par exécution.

</details>

## Sources

- [Référence de la mise en cache des dépendances](https://docs.github.com/actions/reference/workflows-and-actions/dependency-caching)
- [Artefacts de workflow](https://docs.github.com/actions/concepts/workflows-and-actions/workflow-artifacts)
- [Stocker et partager des données avec les artefacts de workflow](https://docs.github.com/actions/tutorials/store-and-share-data)
- [`actions/setup-dotnet` : mettre en cache les paquets NuGet](https://github.com/actions/setup-dotnet#caching-nuget-packages)
- [`actions/upload-artifact`](https://github.com/actions/upload-artifact) et [`actions/download-artifact`](https://github.com/actions/download-artifact)
- [Verrouiller les dépendances — NuGet](https://learn.microsoft.com/nuget/consume-packages/package-references-in-project-files#locking-dependencies)
