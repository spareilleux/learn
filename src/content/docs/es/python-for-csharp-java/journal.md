---
title: Diario
description: Notas de progreso fechadas del curso de Python — la instalación de Python 3.14.7 con uv 0.12.14 sin tocar el Python de la máquina, sorpresas en uv, CPython y mypy, lo que encontraron las lecciones en el código Python de GuitarAlchemist/ga, ix y tars, y puntos por verificar.
sidebar:
  order: 99
---

## Progreso

- [x] Python 3.14.7 y uv 0.12.14 fijados en el propio proyecto del curso, [`code/python-for-csharp-java`](https://github.com/spareilleux/learn/tree/main/code/python-for-csharp-java), con mypy 2.3.1 y pytest 9.1.1 en `uv.lock`
- [x] `check.sh`: mypy sobre el proyecto y sobre cada fragmento de error, cada ejemplo, script y solución ejecutados, pytest, las comparaciones en C# y Java compiladas y ejecutadas, todo comparado con `expected/` en Windows
- [ ] CI en Linux, Windows y macOS (*por verificar*: el workflow está escrito, todavía no se ha hecho push)
- [x] Lección 1: instalar y ejecutar Python
- [x] Lección 2: el modelo de ejecución
- [x] Lección 3: tipos integrados y colecciones
- [x] Lección 4: funciones
- [ ] Lección 5: clases

## 2026-09-15 — Instalar Python sin tocar la máquina

- La máquina ya tenía un Python del sistema y uv 0.10.4 en su `PATH`, y otros proyectos usan sus propios entornos virtuales. El curso tenía que dejarlos todos intactos. Descargué el binario de uv 0.12.14 en una carpeta de pruebas y apunté `UV_PYTHON_INSTALL_DIR`, `UV_CACHE_DIR` y `UV_TOOL_DIR` a ella, con `UV_PYTHON_INSTALL_REGISTRY=0` para que el registro de Windows no se entere del intérprete, y `UV_NO_MODIFY_PATH=1`. `uv python install 3.14.7` descargó entonces una build de [python-build-standalone](https://github.com/astral-sh/python-build-standalone) solo en esa carpeta. La lección 1 muestra la instalación normal, que es lo que quiere un lector.
- Python 3.14.7 se publicó el 2026-08-05. En Windows, python.org recomienda ahora el [Python install manager](https://docs.python.org/3.14/using/windows.html); el instalador tradicional y el lanzador `py` que venía con él están obsoletos desde la 3.14. La lección 1 instala con uv en los tres SO, y menciona el install manager.
- **uv 0.12.0 cambió `uv init`.** Ahora crea por defecto un proyecto empaquetado: un `src/hello/__init__.py`, una entrada `[project.scripts]` y el backend `uv_build`, donde la 0.11 creaba un único `main.py`. `uv init --no-package` da la estructura anterior. Los tutoriales escritos antes de 2026 muestran los archivos antiguos; la lección 1 muestra los nuevos, a partir de `check.sh`.
- El `pyproject.toml` del curso pone `[tool.uv] package = false`: el curso es una carpeta de ejemplos, no un paquete que instalar.

## 2026-09-15 — Sorpresas al escribir las lecciones 1-4

**`uv init` dentro de un proyecto añade un miembro de workspace.** `check.sh` crea el proyecto `hello` de la lección 1 en `out/`, bajo el proyecto del curso, y la primera ejecución de `uv init` añadió `members = ["out/uv-demo/hello"]` al `pyproject.toml` del curso y lo volvió a bloquear. `--no-workspace` lo evita. Un lector que ejecute `uv init` en una subcarpeta de un proyecto uv obtiene la misma modificación.

**`uv tree` filtra por plataforma.** En Windows, `uv tree` lista `colorama` bajo pytest; en Linux no lo haría, ya que el archivo de bloqueo lo registra con `marker = "sys_platform == 'win32'"`. La lección 1 usa `uv tree --universal`, que imprime el mismo árbol en los tres SO. El propio archivo de bloqueo es el mismo en todas partes, que es su razón de ser.

**Las resoluciones cambian cada día.** `uv add httpx==0.28.1` fija httpx, no sus dependencias: `anyio`, `certifi` e `idna` se resuelven a lo más reciente. `check.sh` define `UV_EXCLUDE_NEWER=2026-09-15T00:00:00Z` para el proyecto de demostración de la lección 1, para que el árbol de la lección no cambie cuando certifi publique una versión.

**Un `.python-version` que contradice `requires-python` es un error bloqueante**, código de salida 2, no una advertencia; el tercer ejercicio de la lección 1 muestra el mensaje.

**Los mensajes de Python 3.14 son mejores de lo que muestran los tutoriales.** Una lista usada como clave de dict dice ahora `cannot use 'list' as a dict key (unhashable type: 'list')`, donde la 3.13 decía `unhashable type: 'list'`; el traceback pone marcas debajo de la parte de la expresión que falla; `is` con un literal y una secuencia de escape no válida son `SyntaxWarning`, impresas cuando se compila el archivo. El desensamblado de la lección 1 muestra el `LOAD_FAST_BORROW_LOAD_FAST_BORROW` de la 3.14, una superinstrucción que no aparece en los artículos más antiguos sobre `dis`.

**mypy 2.3.1 se deja más cosas de las que esperaba en modo strict.** No informa de ningún error para el `UnboundLocalError` de la lección 2, para una lista usada como clave de dict, para `is` con un literal, para una secuencia de escape no válida, ni para un argumento por defecto mutable. Tampoco para `ordered = tuning.sort()`, que asigna `None`. Sí detecta todas las llamadas incorrectas de la lección 4, y el subíndice sobre un resultado de `dict.get` que puede ser `None` (lección 2). Rechazó la lambda `i=i` (`Cannot infer type of lambda`), que pasó de `examples/` a `errors/`. Las lecciones 2 a 4 dicen, para cada fragmento de error, si mypy lo encuentra.

**`round` no es el bug de la lección 1.** Primero escribí que `f"{25.875:.2f}"` imprime `25.87`; imprime `25.88`. El total de la lección 1 imprime `25.87` porque el cálculo en float da `25.874999999999996`. La lección 3 usa ahora la propia fórmula de la lección 1, y muestra la versión con `Decimal`.

**El orden de un set depende de `PYTHONHASHSEED`.** Con las semillas 1 y 2, `{'E', 'A', 'D', 'G', 'B'}` se imprime en dos órdenes distintos; `check.sh` fija la semilla para esas dos líneas, y todos los demás ejemplos ordenan sus sets antes de imprimirlos.

**.NET y Java discrepan sobre modificar una colección mientras se recorre.** `Dictionary.Remove` dentro de un `foreach` no lanza excepción desde .NET Core 3.0, `List.Remove` sí, y el `LinkedHashMap` de Java lanza `ConcurrentModificationException`. La lección 3 imprime los tres casos.

**pytest 9 lee `[tool.pytest]`** en `pyproject.toml`, con tipos TOML nativos; las versiones anteriores solo leían `[tool.pytest.ini_options]`. El curso usa la nueva tabla.

**`dotnet run file.cs` guarda la build en caché.** Como en el curso de TypeScript, una segunda ejecución de un archivo sin cambios no llama al compilador, así que `check.sh` ejecuta `dotnet clean` y luego `dotnet run --no-cache` sobre cada comparación en C#. `compare/global.json` fija el SDK en 10.0.100 con `latestFeature`, ya que la máquina también tiene una preview de .NET 11.

**Todavía no se puede hacer push de la CI.** El token de GitHub usado para el push no tiene el scope `workflow`, y GitHub rechaza un push que añade un archivo bajo `.github/workflows/`. El código y las lecciones están publicados; `.github/workflows/python-examples.yml` espera a `gh auth refresh -s workflow`. Hasta que se ejecute, las partes de Linux y macOS de la lección 1 están *por verificar*.

## 2026-09-15 — Lo que encontraron las lecciones en GuitarAlchemist/ga (cc42d21)

Cloné [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga) en [`cc42d21`](https://github.com/GuitarAlchemist/ga/commit/cc42d215504631e168daf3bdf2c6d47b5c9fbe93) en una carpeta de pruebas, instalé cada proyecto Python con el uv del curso, y analicé los archivos Python con un pequeño script basado en el módulo `ast` (valores por defecto mutables, `except` desnudos, anotaciones).

- **Un bug: HTTP 400 se convierte en 500 en el servicio de grafo de conocimiento.** En [`Apps/ga-graphiti-service/main.py`](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Apps/ga-graphiti-service/main.py#L102-L115), cada endpoint lanza `HTTPException(status_code=400, ...)` dentro de un `try` cuyo `except Exception as e` lanza `HTTPException(status_code=500, detail=str(e))`. `HTTPException` es una `Exception`, así que el 400 se captura y el cliente recibe un 500 cuyo detalle es `400: episode has no user`. La misma forma está en las líneas 111, 127, 143 y 159. Reproducción, reducida a FastAPI 0.121 con un `TestClient`: el script imprime `500 {'detail': '400: episode has no user'}`. La corrección es un `except HTTPException: raise` antes de la cláusula general. La lección 7 (errores) lo usará; no he abierto ninguna issue.
- **El agente de gobernanza no tiene archivo de bloqueo.** [`Apps/demerzel-agent/pyproject.toml`](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Apps/demerzel-agent/pyproject.toml) declara solo cotas inferiores (`acp-sdk>=0.2.0`), y el [README](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Apps/demerzel-agent/README.md) dice `uv sync`, que resuelve las versiones del día: `acp-sdk` 1.0.3 el 2026-09-15, una versión mayor por encima de la cota. Los imports siguen funcionando.
- **Su punto de entrada nunca se instala.** `[project.scripts] demerzel = "src.server:main"` necesita un sistema de build, y el archivo no tiene ninguno: `uv sync` imprime una advertencia de que se salta los puntos de entrada, y `uv run demerzel` encontró entonces un `demerzel.exe` sin relación en otra parte de mi `PATH`. El paquete de nivel superior se llama además `src`. La lección 1 explica los proyectos empaquetados; la lección 8 volverá sobre la estructura.
- **Importar el servicio de gobernanza puede fallar.** [`src/services/governance.py`, líneas 13-28](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Apps/demerzel-agent/src/services/governance.py#L13-L28), llama a `find_governance_root()` en el nivel del módulo, que lanza `FileNotFoundError` cuando no encuentra ninguna carpeta `governance/demerzel`, así que cualquier import del módulo, incluido el de una prueba, falla fuera del repositorio. La variable de entorno `DEMERZEL_ROOT` solo se lee después de subir por las carpetas padre, así que no puede prevalecer sobre una carpeta que existe. La lección 2 lo reduce, y su tercer ejercicio lee la raíz de forma diferida.
- **Errores tragados.** El mismo archivo tiene `except Exception: continue` o equivalente en las líneas 46-56, 83 y 130, y `src/services/github.py` en las líneas 33 y 53; [`epistemic_agent.py`, líneas 145-148](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Apps/demerzel-agent/src/agents/epistemic_agent.py#L145-L148), tiene `except ValueError: pass`. Para la lección 7.
- **Colecciones a mano.** El resumen de tensores y el filtro `where` de `epistemic_agent.py` son los ejercicios 1 y 3 de la lección 3.
- **La imagen del servicio** usa `python:3.11-slim` y uv 0.10.4 con un `requirements.txt` de cotas inferiores, así que cada build de la imagen puede resolver versiones distintas.
- **Scripts con dependencias no declaradas.** [`Scripts/train-router-head.py`](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Scripts/train-router-head.py#L22-L25) importa NumPy y scikit-learn, y nada en el repositorio los declara; un bloque PEP 723 lo haría (lección 1, ejercicio 2). También lee JSON con `json.load(open(path))`, sin `with` ni codificación (líneas 63, 66 y 71). `Scripts/validate_optick_sae_artifacts.py` captura el `ImportError` de `jsonschema` en las líneas 34-39. Dos scripts empiezan con un BOM UTF-8, que Python acepta.
- **Ningún argumento por defecto mutable** en ningún archivo Python de los tres repositorios, según el análisis con `ast`.

## 2026-09-15 — GuitarAlchemist/ix (2190c68) y tars (26c5f67)

- **IX** entrena su autoencoder disperso desde [`crates/ix-optick-sae/python`](https://github.com/GuitarAlchemist/ix/tree/2190c685e3664488c9a3d0c1388c96b868a178cb/crates/ix-optick-sae/python), con un `requirements.txt` de cotas inferiores y sin bloqueo; el código importa `Dict`, `List` y `Optional` de `typing` (lección 3), y sus pruebas usan `unittest` con una modificación de `sys.path` en lugar de pytest (lección 9).
- **TARS hace commit de un entorno virtual.** [`Scripts/tts-venv`](https://github.com/GuitarAlchemist/tars/tree/26c5f67252c84f1b9da48a415c58b0725cb5b45c/Scripts/tts-venv) contiene 2,691 archivos: un `python.exe` de Windows, pip, Flask y el wheel compilado de NumPy 2.2.4 para CPython 3.12, añadidos en el commit `2402545` el 2025-04-01. Funciona en un SO y una versión de Python, y pesa en cada clonación. Un `pyproject.toml` y un archivo de bloqueo lo sustituirían (lección 1).
- **Las herramientas Python de TARS no declaran nada.** Siete de los 23 scripts de [`tools/python`](https://github.com/GuitarAlchemist/tars/tree/26c5f67252c84f1b9da48a415c58b0725cb5b45c/tools/python) importan `requests`, `aiohttp` o `websockets`, y la carpeta no tiene archivo de dependencias. 272 de sus 288 funciones no tienen anotación de retorno.
- **Secuencias de escape no válidas** en `implementation-starter.py`, línea 184, y `meta-programming-demo.py`, línea 497, señaladas por Python 3.14.7 (lección 3).
- **`except` desnudos o que se tragan errores** en `autonomous-quality-loop.py` (líneas 388, 408, 462, 482 y 491), `tars-mcp-client.py` (89), `tars-evolve-cli.py` (443 y 462) y `real-multimedia-processor.py` (142). Para la lección 7.

## 2026-09-15 — Este sitio

- El [curso de aprendizaje automático](../../machine-learning-ix/01-data-and-evaluation/) instala NumPy y scikit-learn con `pip install` en el Python que haya en el `PATH`. Las versiones están fijadas, lo cual está bien, pero los paquetes acaban en el Python del sistema o del usuario, y pueden entrar en conflicto con los de otro proyecto. Un bloque PEP 723 y `uv run --script`, o un pequeño proyecto uv en `code/`, los aislarían. No he modificado ese curso.

## Por verificar

- La instalación de la lección 1 en Linux y macOS: la salida de `uv python install` y los nombres de las builds, a partir de los logs de la CI cuando se ejecute el workflow.
- `check.sh` en los tres SO: las salidas se capturaron en Windows, y los separadores de ruta, los finales de línea y la cultura de C# podrían diferir.
- El comportamiento del Python install manager en Windows, que no instalé en esta máquina.
