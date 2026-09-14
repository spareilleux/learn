---
title: 2. Compiler et tester .NET et Java
description: Une matrix sur trois systèmes d'exploitation, setup-dotnet et setup-java, le cache Maven, et les pièges de xUnit v3 avec le SDK .NET 10.
sidebar:
  order: 2
---

## Le projet

[`code/github-actions`](https://github.com/spareilleux/learn/tree/main/code/github-actions) contient deux fois la même petite fonction — transformer un titre en slug d'URL — avec quatre tests de chaque côté :

| | .NET | Java |
|---|---|---|
| Code | `dotnet/Slugs/Slug.cs` | `java/src/main/java/com/example/slugs/Slug.java` |
| Tests | [xUnit v3](https://xunit.net/) `[Theory]` + `[InlineData]` | [JUnit 6](https://docs.junit.org/) `@ParameterizedTest` + `@CsvSource` |
| Commande | `dotnet test` | `mvn -B verify` |
| SDK fixé par | `global.json` | `maven.compiler.release` dans `pom.xml` |

Extrait de [`dotnet/Slugs.Tests/SlugTests.cs`, lignes 8-14](https://github.com/spareilleux/learn/blob/93f6f82/code/github-actions/dotnet/Slugs.Tests/SlugTests.cs#L8-L14) :

```csharp
[Theory]
[InlineData("Hello, Wörld!", "hello-world")]
[InlineData("  GitHub   Actions  ", "github-actions")]
[InlineData("C# 14 & .NET 10", "c-14-net-10")]
[InlineData("", "")]
public void From_builds_a_lowercase_ascii_slug(string text, string expected) =>
    Assert.Equal(expected, Slug.From(text));
```

Avant tout YAML : **ça doit passer en local**, avec les mêmes commandes que la CI. C'est là que sont apparus les deux premiers pièges de cette leçon.

## Piège 1 : xUnit v3 et `dotnet test` avec le SDK .NET 10

Avec `xunit.v3` 4.0.1, le premier `dotnet test` a échoué avant d'exécuter quoi que ce soit :

```text
error : Testing with VSTest target is no longer supported by Microsoft.Testing.Platform on .NET 10 SDK and later. If you use dotnet test, you should opt-in to the new dotnet test experience. For more information, see https://aka.ms/dotnet-test-mtp-error
```

xUnit v3 s'exécute sur [Microsoft.Testing.Platform](https://learn.microsoft.com/dotnet/core/testing/microsoft-testing-platform-intro), et le SDK .NET 10 veut que tu actives explicitement le nouveau `dotnet test`, dans `global.json` ([`dotnet/global.json`](https://github.com/spareilleux/learn/blob/main/code/github-actions/dotnet/global.json)) :

```json
{
  "sdk": {
    "version": "10.0.100",
    "rollForward": "latestFeature"
  },
  "test": {
    "runner": "Microsoft.Testing.Platform"
  }
}
```

## Piège 2 : pas de `using Xunit` implicite

Erreur suivante :

```text
CS0246: The type or namespace name 'Theory' could not be found (are you missing a using directive or an assembly reference?)
CS0246: The type or namespace name 'InlineData' could not be found (are you missing a using directive or an assembly reference?)
```

Avec `ImplicitUsings` activé, ce paquet 4.0.1 n'ajoutait pas `Xunit` aux usings globaux : le fichier de test a besoin de `using Xunit;`. Ensuite :

```text
Test run summary: Passed!
  total: 4
  failed: 0
  succeeded: 4
  skipped: 0
```

## Le workflow

[`.github/workflows/gha-02-build.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-02-build.yml) :

```yaml
# GitHub Actions course, lesson 2: build and test .NET and Java on three OSes
name: "GHA 02: build and test"

on:
  workflow_dispatch:
  push:
    branches: [main]
    paths: ['code/github-actions/**', '.github/workflows/gha-02-build.yml']
  pull_request:
    paths: ['code/github-actions/**', '.github/workflows/gha-02-build.yml']

jobs:
  dotnet:
    name: dotnet (${{ matrix.os }})
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    defaults:
      run:
        working-directory: code/github-actions/dotnet
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-dotnet@v6
        with:
          global-json-file: code/github-actions/dotnet/global.json
      - run: dotnet --version
      - run: dotnet test

  java:
    name: java (${{ matrix.os }})
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    defaults:
      run:
        working-directory: code/github-actions/java
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-java@v6
        with:
          distribution: temurin
          java-version: '25'
          cache: maven
      - run: java --version
      - run: mvn -B verify
```

| Élément | Effet |
|---|---|
| `strategy.matrix.os` | un job par valeur : 3 jobs `dotnet` et 3 jobs `java`, tous en parallèle |
| `fail-fast: false` | un échec sous Windows n'annule pas le job macOS encore en cours (la valeur par défaut, `true`, l'annule) |
| `name: dotnet (${{ matrix.os }})` | le nom du job affiché dans l'exécution ; sans `name`, GitHub utilise l'id du job et toutes les valeurs de la matrix, par exemple `java (ubuntu-latest, 22)` |
| `defaults.run.working-directory` | chaque `run:` démarre dans ce dossier (les steps `uses:` ne sont pas concernés) |
| [`actions/setup-dotnet`](https://github.com/actions/setup-dotnet) avec `global-json-file` | installe le SDK demandé par `global.json` |
| [`actions/setup-java`](https://github.com/actions/setup-java) avec `cache: maven` | installe Temurin 25 et met en cache `~/.m2/repository`, avec une clé basée sur le hash de `pom.xml` |
| `mvn -B` | mode batch : pas de couleurs, pas de barres de progression des téléchargements dans le log |

## Ce que montre l'exécution

Les six jobs sont passés. Extraits :

```text
dotnet (ubuntu-latest) | dotnet-install: Installed version is 10.0.401
dotnet (ubuntu-latest) | 10.0.401
java (ubuntu-latest)   | Resolved Java 25.0.4+1 from tool-cache
java (ubuntu-latest)   | openjdk 25.0.4.1 2026-08-18 LTS
java (ubuntu-latest)   | [INFO] Tests run: 4, Failures: 0, Errors: 0, Skipped: 0
java (ubuntu-latest)   | [INFO] BUILD SUCCESS
```

- `global.json` indique `10.0.100` avec `rollForward: latestFeature` : `setup-dotnet` a installé la **dernière** feature band 10.0, 10.0.401. Fixe `"rollForward": "disable"` si tu as besoin d'exactement un SDK.
- Temurin 25 était déjà dans l'image Ubuntu (`from tool-cache`) : aucun téléchargement.

**Le shell n'est pas le même partout.** Le même step `run: dotnet test` a journalisé :

```text
dotnet (ubuntu-latest)  | shell: /usr/bin/bash -e {0}
dotnet (macos-latest)   | shell: /bin/bash -e {0}
dotnet (windows-latest) | shell: C:\Program Files\PowerShell\7\pwsh.EXE -command ". '{0}'"
```

Sous Windows, `run:` utilise PowerShell 7 par défaut. `dotnet test` et `mvn -B verify` se comportent de la même façon dans les deux, mais pas un script avec `$(pwd)`, `export` ou des enchaînements `&&`. Fixe `defaults.run.shell: bash` pour le job (Git Bash est installé sur les runners Windows) quand un script doit être identique sur les trois OS.

## Le cache, mesuré

La première exécution n'a trouvé aucun cache Maven et en a enregistré un ; une deuxième exécution (lancée avec `gh workflow run gha-02-build.yml`) l'a restauré :

```text
maven cache is not found
Cache saved with the key: setup-java-Linux-x64-maven-4b450ab7781caaed20d3b55ef20c4500aaacb6aad3f54b145929988a7515a1eb
```

```text
Cache restored from key: setup-java-Linux-x64-maven-4b450ab7781caaed20d3b55ef20c4500aaacb6aad3f54b145929988a7515a1eb
Cache hit occurred on the primary key setup-java-Linux-x64-maven-4b450ab7781caaed20d3b55ef20c4500aaacb6aad3f54b145929988a7515a1eb, not saving cache.
```

| Job | 1re exécution (sans cache) | 2e exécution (cache trouvé) |
|---|---|---|
| java (ubuntu-latest) | 16 s | 10 s |
| java (windows-latest) | 43 s | 28 s |
| java (macos-latest) | 20 s | 9 s |
| dotnet (ubuntu-latest) | 21 s | 22 s |
| dotnet (windows-latest) | 60 s | 57 s |
| dotnet (macos-latest) | 20 s | 22 s |

Les jobs .NET ne sont pas devenus plus rapides : rien ne met encore en cache les paquets NuGet. `setup-dotnet` a une option `cache: true` basée sur les fichiers `packages.lock.json`, mesurée dans la [leçon 5](../05-caches-and-artifacts/). La clé contient l'OS (`Linux-x64`, `Windows-x64`, `macOS-arm64`) : chaque OS a son propre cache. Et `macos-latest` est une machine **arm64**.

## À retenir

- Fais d'abord passer le build en local, avec exactement les commandes de la CI.
- Une `matrix` multiplie un job ; `fail-fast: false` laisse chaque combinaison aller au bout.
- `setup-dotnet` lit `global.json` ; `setup-java` installe un JDK et met en cache Maven ou Gradle.
- `run:` utilise bash sous Linux/macOS et PowerShell 7 sous Windows, sauf si tu fixes `shell`.
- Mesure : un cache Maven trouvé a fait gagner ici de 6 à 15 secondes par job ; les jobs Windows sont les plus lents.

## Exercices

1. Ajoute `22` à côté de `25` pour que le job Java s'exécute aussi sur Java 22, sur les trois OS. Combien de jobs Java vont s'exécuter ?

<details>
<summary>Solution</summary>

```yaml
    name: java ${{ matrix.java }} (${{ matrix.os }})
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        java: ['25', '22']
    steps:
      - uses: actions/setup-java@v6
        with:
          distribution: temurin
          java-version: ${{ matrix.java }}
          cache: maven
```

6 jobs (3 × 2). Mais le build échoue sur 22 : `pom.xml` fixe `maven.compiler.release` à 25. Vérifié avec [`gha-02-exercises.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-02-exercises.yml) :

```text
[INFO] BUILD FAILURE
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-compiler-plugin:3.15.0:compile (default-compile) on project slugs: Fatal error compiling: error: release version 25 not supported -> [Help 1]
```

Une matrix teste des combinaisons ; le projet doit les prendre en charge.

</details>

2. Tu veux que le job Windows exécute `dotnet test` dans bash, comme les autres. Où places-tu `shell: bash` pour qu'il s'applique à chaque `run:` du job ?

<details>
<summary>Solution</summary>

```yaml
    defaults:
      run:
        shell: bash
        working-directory: code/github-actions/dotnet
```

`defaults.run` au niveau du job (ou au niveau du workflow pour tous les jobs). Sous Windows, le log affiche alors :

```text
shell: C:\Program Files\Git\bin\bash.EXE --noprofile --norc -e -o pipefail {0}
bash 5.3.15(2)-release, options ehB
```

Remarque `-o pipefail` : un `shell: bash` explicite échoue aussi quand une commande au milieu d'un pipe échoue, ce que ne fait pas le `bash -e {0}` implicite des runners Linux.

</details>

3. Sans `using Xunit;`, quelle erreur la CI afficherait-elle, et sur combien de jobs ?

<details>
<summary>Solution</summary>

`CS0246: The type or namespace name 'Theory' could not be found`, sur les trois jobs `dotnet`. Avec `fail-fast: false`, les trois vont au bout ; avec la valeur par défaut `fail-fast: true`, le premier échec annule les autres jobs `dotnet` encore en cours — les jobs `java` viennent d'une autre définition de job, avec sa propre matrix, et ne sont pas concernés.

</details>

## Sources

- [Compiler et tester du .NET — GitHub Docs](https://docs.github.com/actions/tutorials/build-and-test-code/net)
- [Compiler et tester du Java avec Maven — GitHub Docs](https://docs.github.com/actions/tutorials/build-and-test-code/java-with-maven)
- [Exécuter des variantes de jobs dans un workflow (matrix)](https://docs.github.com/actions/how-tos/write-workflows/choose-what-workflows-do/run-job-variations)
- [Tester avec `dotnet test` et Microsoft.Testing.Platform](https://learn.microsoft.com/dotnet/core/testing/unit-testing-with-dotnet-test)
- [Vue d'ensemble de `global.json`](https://learn.microsoft.com/dotnet/core/tools/global-json)
