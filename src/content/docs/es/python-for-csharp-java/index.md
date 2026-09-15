---
title: Python para desarrolladores C#/Java — Misión
description: Python idiomático, tipado y probado para desarrolladores que conocen C# o Java — cada ejemplo, traceback, error de mypy y solución ejecutado por Python 3.14.7 con uv, con el equivalente en C# y Java al lado.
sidebar:
  label: Misión
  order: 0
---

:::note[Versión estudiada]
[Python](https://www.python.org/) **3.14.7**, publicado el 2026-08-05, gestionado por [uv](https://docs.astral.sh/uv/) **0.12.14**, con [mypy](https://mypy.readthedocs.io/en/stable/) **2.3.1** y [pytest](https://docs.pytest.org/en/stable/) **9.1.1**. Cada ejemplo está en [`code/python-for-csharp-java`](https://github.com/spareilleux/learn/tree/main/code/python-for-csharp-java), un proyecto uv cuyo `.python-version` fija el intérprete y cuyo `uv.lock` fija las herramientas. Su `check.sh` ejecuta mypy sobre el proyecto y sobre cada fragmento de error, ejecuta con Python cada ejemplo, script y solución, ejecuta las pruebas, compila las comparaciones en C# y Java, y compara todas las salidas con las que se pegan en las lecciones; el workflow que lo ejecuta en Linux, Windows y macOS está *por verificar* en CI (ver el [diario](journal/)). Python 3.15 está previsto para el 2026-10-01, según su [calendario de publicación](https://peps.python.org/pep-0790/).
:::

## Por qué aprendo esto

Python está por todas partes alrededor del código C# y Java en el que trabajo. [Guitar Alchemist](https://github.com/GuitarAlchemist/ga) ejecuta en Python un agente de gobernanza y un servicio de grafo de conocimiento, y entrena una cabeza de enrutamiento con scikit-learn. [IX](https://github.com/GuitarAlchemist/ix) entrena su autoencoder disperso con PyTorch. [TARS](https://github.com/GuitarAlchemist/tars) tiene un par de docenas de herramientas en Python, y el [curso de aprendizaje automático](../machine-learning-ix/) de este sitio contrasta sus resultados en Rust con scikit-learn.

Puedo leer ese código, y parece sencillo, hasta que deja de parecerlo: una lista por defecto que recuerda la llamada anterior, un módulo que falla al importarlo, una anotación de tipo que nada comprueba, una dependencia que no está declarada en ningún sitio. Este curso aprende Python tal como se escribe hoy, con sus tipos, sus herramientas y sus pruebas, en lugar de traducir C# a Python línea por línea.

## Para quién es este curso

Te manejas bien con C# o Java: clases e interfaces, genéricos, colecciones y LINQ o streams, excepciones, una herramienta de build y un gestor de paquetes. Lees y escribes Python en scripts, notebooks o servicios, y quieres escribirlo como lo hacen los desarrolladores Python.

No se supone ninguna experiencia en Python. Las lecciones explican cada característica a partir de la característica de C# o Java que ya conoces, y muestran en qué se diferencian con programas que se ejecutan.

## Python en una tabla

| | C# | Java | Python |
|---|---|---|---|
| Entorno de ejecución | el CLR, a través de `dotnet` | la JVM, a través de `java` | CPython, el intérprete `python`, que compila a bytecode cuando se carga un archivo |
| Archivo de proyecto | `.csproj` | `pom.xml`, `build.gradle` | `pyproject.toml` |
| Paquetes | NuGet | Maven Central | PyPI, instalados en un entorno virtual por proyecto |
| Herramientas | el SDK de .NET | Maven, Gradle | uv, o pip y venv |
| Tipos | estáticos, verificados por `csc` | estáticos, verificados por `javac` | dinámicos en tiempo de ejecución; anotaciones opcionales verificadas por mypy o pyright |
| Valor ausente | `null`, tipos de referencia anulables | `null`, `Optional<T>` | `None`, un objeto, y `X \| None` en las anotaciones |
| Parámetros | posicionales, con nombre, valores por defecto constantes | solo posicionales, sobrecargas | posicionales, por palabra clave, valores por defecto evaluados una sola vez, `*args` y `**kwargs` |
| Bloques | llaves | llaves | sangría |

## Los datos

Las lecciones usan código real como material, clonado en una carpeta de pruebas y fijado en un commit:

- [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga) en [`cc42d21`](https://github.com/GuitarAlchemist/ga/commit/cc42d215504631e168daf3bdf2c6d47b5c9fbe93): el agente de gobernanza [`Apps/demerzel-agent`](https://github.com/GuitarAlchemist/ga/tree/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Apps/demerzel-agent), el servicio de grafo de conocimiento [`Apps/ga-graphiti-service`](https://github.com/GuitarAlchemist/ga/tree/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Apps/ga-graphiti-service), y los scripts de [`Scripts`](https://github.com/GuitarAlchemist/ga/tree/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Scripts);
- [GuitarAlchemist/ix](https://github.com/GuitarAlchemist/ix) en [`2190c68`](https://github.com/GuitarAlchemist/ix/commit/2190c685e3664488c9a3d0c1388c96b868a178cb): el código de entrenamiento de [`crates/ix-optick-sae`](https://github.com/GuitarAlchemist/ix/tree/2190c685e3664488c9a3d0c1388c96b868a178cb/crates/ix-optick-sae/python);
- [GuitarAlchemist/tars](https://github.com/GuitarAlchemist/tars) en [`26c5f67`](https://github.com/GuitarAlchemist/tars/commit/26c5f67252c84f1b9da48a415c58b0725cb5b45c): las herramientas de [`tools/python`](https://github.com/GuitarAlchemist/tars/tree/26c5f67252c84f1b9da48a415c58b0725cb5b45c/tools/python).

Las lecciones reducen las líneas que citan a archivos que se ejecutan por sí solos, e indican de dónde viene cada una. Lo que encontré en esos repositorios, con una forma de reproducirlo, está en el [diario](journal/).

## Al final de este curso, sabré

- configurar un proyecto Python con uv, fijar su intérprete y sus dependencias, y ejecutarlo de la misma manera en Windows, Linux y macOS;
- explicar qué son en Python un nombre, un objeto y un import, y predecir cuándo dos nombres comparten un mismo objeto;
- elegir entre una lista, una tupla, un dict y un set, y escribir comprensiones donde C# usaría LINQ;
- diseñar firmas de funciones con parámetros solo por palabra clave y solo posicionales, y escribir decoradores que conservan la firma que envuelven;
- modelar datos con dataclasses y protocolos, y anotar el código para que mypy detecte lo que habría detectado `csc`;
- gestionar errores y recursos con excepciones y `with`;
- estructurar un paquete, probarlo con pytest y mantenerlo limpio con Ruff en CI;
- escribir iteradores, generadores y código asíncrono, y saber cuándo convienen los hilos, los procesos o `asyncio`;
- leer código NumPy y pandas, y servir una API con FastAPI.

## Plan

| # | Lección | Ya conoces |
|---|---|---|
| 1 | [Instalar y ejecutar Python](01-install-and-run/) | `dotnet`, `java`, NuGet, Maven y Gradle, `global.json`, archivos de bloqueo |
| 2 | [El modelo de ejecución](02-execution-model/) | tipos por referencia y por valor, `==` y `Equals`, `null`, ámbito de bloque, constructores estáticos |
| 3 | [Tipos integrados y colecciones](03-collections/) | `List<T>`, `Dictionary`, `HashSet`, arrays, LINQ, streams, `decimal` |
| 4 | [Funciones](04-functions/) | argumentos opcionales y con nombre, `params`, varargs, lambdas y closures, atributos y anotaciones |
| 5 | Clases: dataclasses, propiedades, métodos especiales, herencia y protocolos (próximamente) | clases, records, `IEquatable`, `ToString`, interfaces |
| 6 | Anotaciones de tipo: mypy y pyright, genéricos, `Protocol`, `TypedDict`, lo que nunca se comprueba en tiempo de ejecución | genéricos, tipos de referencia anulables, interfaces |
| 7 | Errores y recursos: excepciones, `with` y gestores de contexto | excepciones, `using`, try-with-resources |
| 8 | Módulos y paquetes: imports, `__init__.py`, estructura del proyecto, publicación | ensamblados, espacios de nombres, paquetes NuGet, JAR |
| 9 | Pruebas: pytest, fixtures, parametrización, Hypothesis | xUnit, JUnit, FsCheck, jqwik |
| 10 | Iteradores y generadores: `yield`, `itertools` | `IEnumerable`, `yield return`, streams |
| 11 | Concurrencia: el GIL y el free-threading, `asyncio`, `concurrent.futures`, multiprocessing | `Task`, `async`/`await`, grupos de hilos, `CompletableFuture` |
| 12 | Datos y cálculo: NumPy, pandas o Polars, y una mirada honesta al ecosistema de ML | arrays, `Span<T>`, ML.NET |
| 13 | Herramientas de calidad: Ruff, formateo, pre-commit, CI | analizadores, `dotnet format`, Checkstyle, Spotless |
| 14 | Servicios: FastAPI, comparado con las minimal APIs de ASP.NET Core y con Spring WebFlux | ASP.NET Core, Spring |
| — | [Diario](journal/) | |

El [curso de aprendizaje automático](../machine-learning-ix/) y el [curso sobre la IA de GA](../ga-ai/) usan Python como contraste; la lección 12 enlaza a ellos en lugar de repetirlos.

## Recursos

- [The Python Tutorial](https://docs.python.org/3.14/tutorial/), [The Python Language Reference](https://docs.python.org/3.14/reference/) y [The Python Standard Library](https://docs.python.org/3.14/library/), para Python 3.14
- [What's New in Python 3.14](https://docs.python.org/3.14/whatsnew/3.14.html), y las [Python Enhancement Proposals](https://peps.python.org/) que citan las lecciones
- [Documentación de uv](https://docs.astral.sh/uv/), y su [registro de cambios](https://github.com/astral-sh/uv/blob/main/CHANGELOG.md)
- [Documentación de mypy](https://mypy.readthedocs.io/en/stable/), [documentación de pyright](https://microsoft.github.io/pyright/), [documentación de pytest](https://docs.pytest.org/en/stable/)
- [Python Packaging User Guide](https://packaging.python.org/), para `pyproject.toml` y los formatos que uv lee y escribe
