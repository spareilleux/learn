---
title: Python for C#/Java developers — Mission
description: Idiomatic, typed and tested Python for developers who know C# or Java — every example, traceback, mypy error and solution run by Python 3.14.7 with uv in CI on Windows, Linux and macOS, with the C# and Java side next to it.
sidebar:
  label: Mission
  order: 0
---

:::note[Version studied]
[Python](https://www.python.org/) **3.14.7**, released on 2026-08-05, managed by [uv](https://docs.astral.sh/uv/) **0.12.14**, with [mypy](https://mypy.readthedocs.io/en/stable/) **2.3.1** and [pytest](https://docs.pytest.org/en/stable/) **9.1.1**. Every example is in [`code/python-for-csharp-java`](https://github.com/spareilleux/learn/tree/main/code/python-for-csharp-java), a uv project whose `.python-version` pins the interpreter and whose `uv.lock` pins the tools. Its `check.sh` runs mypy on the project and on every error snippet, runs every example, script and solution with Python, runs the tests, compiles the C# and Java comparisons, and compares all the outputs with the ones pasted in the lessons; the workflow that runs it on Linux, Windows and macOS is *to verify* in CI (see the [journal](journal/)). Python 3.15 is due on 2026-10-01, according to its [release schedule](https://peps.python.org/pep-0790/).
:::

## Why I'm learning this

Python is everywhere around the C# and Java code I work on. [Guitar Alchemist](https://github.com/GuitarAlchemist/ga) runs a governance agent and a knowledge-graph service in Python, and trains a router head with scikit-learn. [IX](https://github.com/GuitarAlchemist/ix) trains its sparse autoencoder with PyTorch. [TARS](https://github.com/GuitarAlchemist/tars) has two dozen Python tools, and the [machine learning course](../machine-learning-ix/) of this site checks its Rust results against scikit-learn.

I can read that code, and it looks simple, until it doesn't: a default list that remembers the previous call, a module that fails when it is imported, a type annotation that nothing checks, a dependency that isn't declared anywhere. This course learns Python as it is written today, with its types, its tools and its tests, instead of translating C# into it line by line.

## Who this course is for

You are comfortable with C# or Java: classes and interfaces, generics, collections and LINQ or streams, exceptions, a build tool and a package manager. You read and write Python in scripts, notebooks or services, and you want to write it the way Python developers do.

No Python experience is assumed. The lessons explain each feature from the C# or Java feature you already know, and show where the two differ with programs that run.

## Python in one table

| | C# | Java | Python |
|---|---|---|---|
| Runtime | the CLR, through `dotnet` | the JVM, through `java` | CPython, the `python` interpreter, which compiles to bytecode when a file is loaded |
| Project file | `.csproj` | `pom.xml`, `build.gradle` | `pyproject.toml` |
| Packages | NuGet | Maven Central | PyPI, installed into a virtual environment per project |
| Tooling | the .NET SDK | Maven, Gradle | uv, or pip and venv |
| Types | static, checked by `csc` | static, checked by `javac` | dynamic at run time; optional annotations checked by mypy or pyright |
| Absent value | `null`, nullable reference types | `null`, `Optional<T>` | `None`, an object, and `X \| None` in annotations |
| Parameters | positional, named, constant defaults | positional only, overloads | positional, keyword, defaults evaluated once, `*args` and `**kwargs` |
| Blocks | braces | braces | indentation |

## The data

The lessons use real code as material, cloned into a scratch folder and pinned on a commit:

- [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga) at [`cc42d21`](https://github.com/GuitarAlchemist/ga/commit/cc42d215504631e168daf3bdf2c6d47b5c9fbe93): the governance agent [`Apps/demerzel-agent`](https://github.com/GuitarAlchemist/ga/tree/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Apps/demerzel-agent), the knowledge-graph service [`Apps/ga-graphiti-service`](https://github.com/GuitarAlchemist/ga/tree/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Apps/ga-graphiti-service), and the scripts of [`Scripts`](https://github.com/GuitarAlchemist/ga/tree/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Scripts);
- [GuitarAlchemist/ix](https://github.com/GuitarAlchemist/ix) at [`2190c68`](https://github.com/GuitarAlchemist/ix/commit/2190c685e3664488c9a3d0c1388c96b868a178cb): the training code of [`crates/ix-optick-sae`](https://github.com/GuitarAlchemist/ix/tree/2190c685e3664488c9a3d0c1388c96b868a178cb/crates/ix-optick-sae/python);
- [GuitarAlchemist/tars](https://github.com/GuitarAlchemist/tars) at [`26c5f67`](https://github.com/GuitarAlchemist/tars/commit/26c5f67252c84f1b9da48a415c58b0725cb5b45c): the tools of [`tools/python`](https://github.com/GuitarAlchemist/tars/tree/26c5f67252c84f1b9da48a415c58b0725cb5b45c/tools/python).

The lessons reduce the lines they quote to files that run on their own, and say where each one comes from. What I found in those repositories, with a way to reproduce it, is in the [journal](journal/).

## By the end of this course, I will be able to

- set up a Python project with uv, pin its interpreter and its dependencies, and run it the same way on Windows, Linux and macOS;
- explain what a name, an object and an import are in Python, and predict when two names share one object;
- choose between a list, a tuple, a dict and a set, and write comprehensions where C# would use LINQ;
- design function signatures with keyword-only and positional-only parameters, and write decorators that keep the signature they wrap;
- model data with dataclasses and protocols, and annotate code so that mypy catches what `csc` would have;
- handle errors and resources with exceptions and `with`;
- structure a package, test it with pytest, and keep it clean with Ruff in CI;
- write iterators, generators and asynchronous code, and know when threads, processes or `asyncio` fit;
- read NumPy and pandas code, and serve an API with FastAPI.

## Outline

| # | Lesson | You already know |
|---|---|---|
| 1 | [Installing and running Python](01-install-and-run/) | `dotnet`, `java`, NuGet, Maven and Gradle, `global.json`, lock files |
| 2 | [The execution model](02-execution-model/) | reference and value types, `==` and `Equals`, `null`, block scope, static constructors |
| 3 | [Built-in types and collections](03-collections/) | `List<T>`, `Dictionary`, `HashSet`, arrays, LINQ, streams, `decimal` |
| 4 | [Functions](04-functions/) | optional and named arguments, `params`, varargs, lambdas and closures, attributes and annotations |
| 5 | Classes: dataclasses, properties, special methods, inheritance and protocols (coming next) | classes, records, `IEquatable`, `ToString`, interfaces |
| 6 | Type annotations: mypy and pyright, generics, `Protocol`, `TypedDict`, what is never checked at run time | generics, nullable reference types, interfaces |
| 7 | Errors and resources: exceptions, `with` and context managers | exceptions, `using`, try-with-resources |
| 8 | Modules and packages: imports, `__init__.py`, project layout, publishing | assemblies, namespaces, NuGet packages, JARs |
| 9 | Tests: pytest, fixtures, parametrization, Hypothesis | xUnit, JUnit, FsCheck, jqwik |
| 10 | Iterators and generators: `yield`, `itertools` | `IEnumerable`, `yield return`, streams |
| 11 | Concurrency: the GIL and free-threading, `asyncio`, `concurrent.futures`, multiprocessing | `Task`, `async`/`await`, thread pools, `CompletableFuture` |
| 12 | Data and computation: NumPy, pandas or Polars, and an honest look at the ML ecosystem | arrays, `Span<T>`, ML.NET |
| 13 | Quality tooling: Ruff, formatting, pre-commit, CI | analyzers, `dotnet format`, Checkstyle, Spotless |
| 14 | Services: FastAPI, compared with ASP.NET Core minimal APIs and Spring WebFlux | ASP.NET Core, Spring |
| — | [Journal](journal/) | |

The [machine learning course](../machine-learning-ix/) and the [course on GA's AI](../ga-ai/) use Python as a cross-check; lesson 12 links to them rather than repeating them.

## Resources

- [The Python Tutorial](https://docs.python.org/3.14/tutorial/), [The Python Language Reference](https://docs.python.org/3.14/reference/) and [The Python Standard Library](https://docs.python.org/3.14/library/), for Python 3.14
- [What's New in Python 3.14](https://docs.python.org/3.14/whatsnew/3.14.html), and the [Python Enhancement Proposals](https://peps.python.org/) that the lessons cite
- [uv documentation](https://docs.astral.sh/uv/), and its [changelog](https://github.com/astral-sh/uv/blob/main/CHANGELOG.md)
- [mypy documentation](https://mypy.readthedocs.io/en/stable/), [pyright documentation](https://microsoft.github.io/pyright/), [pytest documentation](https://docs.pytest.org/en/stable/)
- [Python Packaging User Guide](https://packaging.python.org/), for `pyproject.toml` and the formats that uv reads and writes
