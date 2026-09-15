---
title: Python pour développeurs C#/Java — Mission
description: Du Python idiomatique, typé et testé pour les développeurs qui connaissent C# ou Java — chaque exemple, traceback, erreur mypy et solution est exécuté par Python 3.14.7 avec uv, avec en regard le côté C# et Java.
sidebar:
  label: Mission
  order: 0
---

:::note[Version étudiée]
[Python](https://www.python.org/) **3.14.7**, publié le 2026-08-05, géré par [uv](https://docs.astral.sh/uv/) **0.12.14**, avec [mypy](https://mypy.readthedocs.io/en/stable/) **2.3.1** et [pytest](https://docs.pytest.org/en/stable/) **9.1.1**. Chaque exemple se trouve dans [`code/python-for-csharp-java`](https://github.com/spareilleux/learn/tree/main/code/python-for-csharp-java), un projet uv dont le `.python-version` fixe l'interpréteur et dont le `uv.lock` fixe les outils. Son `check.sh` exécute mypy sur le projet et sur chaque extrait d'erreur, exécute chaque exemple, script et solution avec Python, lance les tests, compile les comparaisons C# et Java, et compare toutes les sorties avec celles collées dans les leçons ; le workflow qui l'exécute sous Linux, Windows et macOS est *à vérifier* en CI (voir le [journal](journal/)). Python 3.15 est attendu le 2026-10-01, d'après son [calendrier de publication](https://peps.python.org/pep-0790/).
:::

## Pourquoi j'apprends ça

Python est partout autour du code C# et Java sur lequel je travaille. [Guitar Alchemist](https://github.com/GuitarAlchemist/ga) fait tourner un agent de gouvernance et un service de graphe de connaissances en Python, et entraîne une tête de routage avec scikit-learn. [IX](https://github.com/GuitarAlchemist/ix) entraîne son autoencodeur parcimonieux avec PyTorch. [TARS](https://github.com/GuitarAlchemist/tars) compte deux douzaines d'outils Python, et le [cours d'apprentissage automatique](../machine-learning-ix/) de ce site vérifie ses résultats Rust avec scikit-learn.

Je sais lire ce code, et il paraît simple, jusqu'au moment où il ne l'est plus : une liste par défaut qui se souvient de l'appel précédent, un module qui échoue quand on l'importe, une annotation de type que rien ne vérifie, une dépendance déclarée nulle part. Ce cours apprend Python tel qu'on l'écrit aujourd'hui, avec ses types, ses outils et ses tests, au lieu d'y traduire du C# ligne par ligne.

## À qui s'adresse ce cours

Tu es à l'aise avec C# ou Java : classes et interfaces, génériques, collections et LINQ ou streams, exceptions, un outil de build et un gestionnaire de packages. Tu lis et écris du Python dans des scripts, des notebooks ou des services, et tu veux l'écrire comme le font les développeurs Python.

Aucune expérience de Python n'est supposée. Les leçons expliquent chaque fonctionnalité à partir de celle de C# ou de Java que tu connais déjà, et montrent où les deux diffèrent avec des programmes qui s'exécutent.

## Python en un tableau

| | C# | Java | Python |
|---|---|---|---|
| Environnement d'exécution | le CLR, via `dotnet` | la JVM, via `java` | CPython, l'interpréteur `python`, qui compile en bytecode au chargement d'un fichier |
| Fichier de projet | `.csproj` | `pom.xml`, `build.gradle` | `pyproject.toml` |
| Packages | NuGet | Maven Central | PyPI, installés dans un environnement virtuel par projet |
| Outillage | le SDK .NET | Maven, Gradle | uv, ou pip et venv |
| Types | statiques, vérifiés par `csc` | statiques, vérifiés par `javac` | dynamiques à l'exécution ; annotations optionnelles vérifiées par mypy ou pyright |
| Valeur absente | `null`, types référence nullables | `null`, `Optional<T>` | `None`, un objet, et `X \| None` dans les annotations |
| Paramètres | positionnels, nommés, valeurs par défaut constantes | positionnels seulement, surcharges | positionnels, nommés, valeurs par défaut évaluées une seule fois, `*args` et `**kwargs` |
| Blocs | accolades | accolades | indentation |

## Les données

Les leçons prennent du vrai code comme matériau, cloné dans un dossier de travail et épinglé sur un commit :

- [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga) au commit [`cc42d21`](https://github.com/GuitarAlchemist/ga/commit/cc42d215504631e168daf3bdf2c6d47b5c9fbe93) : l'agent de gouvernance [`Apps/demerzel-agent`](https://github.com/GuitarAlchemist/ga/tree/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Apps/demerzel-agent), le service de graphe de connaissances [`Apps/ga-graphiti-service`](https://github.com/GuitarAlchemist/ga/tree/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Apps/ga-graphiti-service), et les scripts de [`Scripts`](https://github.com/GuitarAlchemist/ga/tree/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Scripts) ;
- [GuitarAlchemist/ix](https://github.com/GuitarAlchemist/ix) au commit [`2190c68`](https://github.com/GuitarAlchemist/ix/commit/2190c685e3664488c9a3d0c1388c96b868a178cb) : le code d'entraînement de [`crates/ix-optick-sae`](https://github.com/GuitarAlchemist/ix/tree/2190c685e3664488c9a3d0c1388c96b868a178cb/crates/ix-optick-sae/python) ;
- [GuitarAlchemist/tars](https://github.com/GuitarAlchemist/tars) au commit [`26c5f67`](https://github.com/GuitarAlchemist/tars/commit/26c5f67252c84f1b9da48a415c58b0725cb5b45c) : les outils de [`tools/python`](https://github.com/GuitarAlchemist/tars/tree/26c5f67252c84f1b9da48a415c58b0725cb5b45c/tools/python).

Les leçons réduisent les lignes qu'elles citent à des fichiers qui s'exécutent seuls, et indiquent d'où vient chacune. Ce que j'ai trouvé dans ces dépôts, avec un moyen de le reproduire, se trouve dans le [journal](journal/).

## À la fin de ce cours, je saurai

- mettre en place un projet Python avec uv, fixer son interpréteur et ses dépendances, et l'exécuter de la même façon sous Windows, Linux et macOS ;
- expliquer ce que sont un nom, un objet et un import en Python, et prédire quand deux noms partagent un même objet ;
- choisir entre une liste, un tuple, un dict et un set, et écrire des compréhensions là où C# utiliserait LINQ ;
- concevoir des signatures de fonctions avec des paramètres keyword-only et positional-only, et écrire des décorateurs qui conservent la signature qu'ils enveloppent ;
- modéliser des données avec des dataclasses et des protocoles, et annoter le code pour que mypy détecte ce que `csc` aurait détecté ;
- gérer les erreurs et les ressources avec les exceptions et `with` ;
- structurer un package, le tester avec pytest, et le garder propre avec Ruff en CI ;
- écrire des itérateurs, des générateurs et du code asynchrone, et savoir quand les threads, les processus ou `asyncio` conviennent ;
- lire du code NumPy et pandas, et servir une API avec FastAPI.

## Plan

| # | Leçon | Tu connais déjà |
|---|---|---|
| 1 | [Installer et exécuter Python](01-install-and-run/) | `dotnet`, `java`, NuGet, Maven et Gradle, `global.json`, les fichiers de verrouillage |
| 2 | [Le modèle d'exécution](02-execution-model/) | types référence et types valeur, `==` et `Equals`, `null`, portée de bloc, constructeurs statiques |
| 3 | [Types intégrés et collections](03-collections/) | `List<T>`, `Dictionary`, `HashSet`, tableaux, LINQ, streams, `decimal` |
| 4 | [Fonctions](04-functions/) | arguments optionnels et nommés, `params`, varargs, lambdas et fermetures, attributs et annotations |
| 5 | Classes : dataclasses, propriétés, méthodes spéciales, héritage et protocoles (à venir) | classes, records, `IEquatable`, `ToString`, interfaces |
| 6 | Annotations de type : mypy et pyright, génériques, `Protocol`, `TypedDict`, ce qui n'est jamais vérifié à l'exécution | génériques, types référence nullables, interfaces |
| 7 | Erreurs et ressources : exceptions, `with` et gestionnaires de contexte | exceptions, `using`, try-with-resources |
| 8 | Modules et packages : imports, `__init__.py`, organisation d'un projet, publication | assemblies, espaces de noms, packages NuGet, JAR |
| 9 | Tests : pytest, fixtures, paramétrage, Hypothesis | xUnit, JUnit, FsCheck, jqwik |
| 10 | Itérateurs et générateurs : `yield`, `itertools` | `IEnumerable`, `yield return`, streams |
| 11 | Concurrence : le GIL et le free-threading, `asyncio`, `concurrent.futures`, multiprocessing | `Task`, `async`/`await`, pools de threads, `CompletableFuture` |
| 12 | Données et calcul : NumPy, pandas ou Polars, et un regard honnête sur l'écosystème ML | tableaux, `Span<T>`, ML.NET |
| 13 | Outillage qualité : Ruff, formatage, pre-commit, CI | analyseurs, `dotnet format`, Checkstyle, Spotless |
| 14 | Services : FastAPI, comparé aux API minimales d'ASP.NET Core et à Spring WebFlux | ASP.NET Core, Spring |
| — | [Journal](journal/) | |

Le [cours d'apprentissage automatique](../machine-learning-ix/) et le [cours sur l'IA de GA](../ga-ai/) utilisent Python comme contre-vérification ; la leçon 12 renvoie vers eux au lieu de les répéter.

## Ressources

- [Le tutoriel Python](https://docs.python.org/3.14/tutorial/), [la référence du langage Python](https://docs.python.org/3.14/reference/) et [la bibliothèque standard](https://docs.python.org/3.14/library/), pour Python 3.14
- [Nouveautés de Python 3.14](https://docs.python.org/3.14/whatsnew/3.14.html), et les [Python Enhancement Proposals](https://peps.python.org/) (PEP) que citent les leçons
- [Documentation d'uv](https://docs.astral.sh/uv/), et son [journal des modifications](https://github.com/astral-sh/uv/blob/main/CHANGELOG.md)
- [Documentation de mypy](https://mypy.readthedocs.io/en/stable/), [documentation de pyright](https://microsoft.github.io/pyright/), [documentation de pytest](https://docs.pytest.org/en/stable/)
- [Python Packaging User Guide](https://packaging.python.org/), pour `pyproject.toml` et les formats que lit et écrit uv
