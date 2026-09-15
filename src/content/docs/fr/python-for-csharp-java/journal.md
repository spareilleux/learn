---
title: Journal
description: Notes de progression datées du cours Python — l'installation de Python 3.14.7 avec uv 0.12.14 sans toucher au Python de la machine, les surprises d'uv, de CPython et de mypy, ce que les leçons ont trouvé dans le code Python de GuitarAlchemist/ga, ix et tars, et les points à vérifier.
sidebar:
  order: 99
---

## Progression

- [x] Python 3.14.7 et uv 0.12.14 épinglés dans le projet propre au cours, [`code/python-for-csharp-java`](https://github.com/spareilleux/learn/tree/main/code/python-for-csharp-java), avec mypy 2.3.1 et pytest 9.1.1 dans `uv.lock`
- [x] `check.sh` : mypy sur le projet et sur chaque extrait d'erreur, chaque exemple, script et solution exécutés, pytest, les comparaisons C# et Java compilées et exécutées, le tout comparé à `expected/` sous Windows
- [ ] CI sous Linux, Windows et macOS (*à vérifier* : le workflow est écrit, pas encore poussé)
- [x] Leçon 1 : installer et exécuter Python
- [x] Leçon 2 : le modèle d'exécution
- [x] Leçon 3 : types intégrés et collections
- [x] Leçon 4 : fonctions
- [ ] Leçon 5 : classes

## 2026-09-15 — Installer Python sans toucher à la machine

- La machine avait déjà un Python système et uv 0.10.4 dans son `PATH`, et d'autres projets utilisent leurs propres environnements virtuels. Le cours devait les laisser tous intacts. J'ai téléchargé le binaire d'uv 0.12.14 dans un dossier de travail et j'y ai fait pointer `UV_PYTHON_INSTALL_DIR`, `UV_CACHE_DIR` et `UV_TOOL_DIR`, avec `UV_PYTHON_INSTALL_REGISTRY=0` pour que le registre Windows n'apprenne rien de l'interpréteur, et `UV_NO_MODIFY_PATH=1`. `uv python install 3.14.7` a alors téléchargé un build de [python-build-standalone](https://github.com/astral-sh/python-build-standalone) dans ce seul dossier. La leçon 1 montre l'installation ordinaire, qui est ce que veut un lecteur.
- Python 3.14.7 est sorti le 2026-08-05. Sous Windows, python.org recommande maintenant le [Python install manager](https://docs.python.org/3.14/using/windows.html) ; l'installeur traditionnel et le lanceur `py` qui l'accompagnait sont dépréciés depuis la 3.14. La leçon 1 installe avec uv sur les trois OS, et mentionne l'install manager.
- **uv 0.12.0 a changé `uv init`.** Il crée maintenant par défaut un projet packagé : un `src/hello/__init__.py`, une entrée `[project.scripts]` et le backend `uv_build`, là où la 0.11 créait un seul `main.py`. `uv init --no-package` donne l'ancienne organisation. Les tutoriels écrits avant 2026 montrent les anciens fichiers ; la leçon 1 montre les nouveaux, tirés de `check.sh`.
- Le `pyproject.toml` du cours fixe `[tool.uv] package = false` : le cours est un dossier d'exemples, pas un package à installer.

## 2026-09-15 — Surprises en écrivant les leçons 1-4

**`uv init` à l'intérieur d'un projet ajoute un membre de workspace.** `check.sh` crée le projet `hello` de la leçon 1 dans `out/`, sous le projet du cours, et la première exécution d'`uv init` a ajouté `members = ["out/uv-demo/hello"]` au `pyproject.toml` du cours et l'a verrouillé à nouveau. `--no-workspace` l'en empêche. Un lecteur qui lance `uv init` dans un sous-dossier d'un projet uv obtient la même modification.

**`uv tree` filtre par plateforme.** Sous Windows, `uv tree` liste `colorama` sous pytest ; sous Linux il ne le ferait pas, puisque le fichier de verrouillage l'enregistre avec `marker = "sys_platform == 'win32'"`. La leçon 1 utilise `uv tree --universal`, qui affiche le même arbre sur les trois OS. Le fichier de verrouillage lui-même est le même partout, c'est tout son intérêt.

**Les résolutions changent tous les jours.** `uv add httpx==0.28.1` fixe httpx, pas ses dépendances : `anyio`, `certifi` et `idna` se résolvent vers la version la plus récente. `check.sh` fixe `UV_EXCLUDE_NEWER=2026-09-15T00:00:00Z` pour le projet de démonstration de la leçon 1, pour que l'arbre de la leçon ne change pas quand certifi publie une version.

**Un `.python-version` qui contredit `requires-python` est une erreur bloquante**, code de sortie 2, pas un avertissement ; le troisième exercice de la leçon 1 montre le message.

**Les messages de Python 3.14 sont meilleurs que ce que montrent les tutoriels.** Une liste utilisée comme clé de dict dit maintenant `cannot use 'list' as a dict key (unhashable type: 'list')`, là où la 3.13 disait `unhashable type: 'list'` ; le traceback place des accents circonflexes sous la partie de l'expression qui échoue ; `is` avec un littéral et une séquence d'échappement invalide sont des `SyntaxWarning`, affichés à la compilation du fichier. Le désassemblage de la leçon 1 montre le `LOAD_FAST_BORROW_LOAD_FAST_BORROW` de la 3.14, une super-instruction qu'ignorent les articles plus anciens sur `dis`.

**mypy 2.3.1 laisse passer plus de choses que je ne l'attendais en mode strict.** Il ne signale aucune erreur pour l'`UnboundLocalError` de la leçon 2, pour une liste utilisée comme clé de dict, pour `is` avec un littéral, pour une séquence d'échappement invalide, ni pour un argument par défaut mutable. Ni pour `ordered = tuning.sort()`, qui assigne `None`. Il détecte en revanche chaque mauvais appel de la leçon 4, et l'indexation d'un résultat de `dict.get` qui peut être `None` (leçon 2). Il a refusé la lambda `i=i` (`Cannot infer type of lambda`), qui est passée d'`examples/` à `errors/`. Les leçons 2 à 4 disent, pour chaque extrait d'erreur, si mypy le détecte.

**`round` n'est pas le bug de la leçon 1.** J'ai d'abord écrit que `f"{25.875:.2f}"` affiche `25.87` ; il affiche `25.88`. Le total de la leçon 1 affiche `25.87` parce que le calcul en flottants donne `25.874999999999996`. La leçon 3 utilise maintenant la formule même de la leçon 1, et montre la version `Decimal`.

**L'ordre d'un set dépend de `PYTHONHASHSEED`.** Avec les graines 1 et 2, `{'E', 'A', 'D', 'G', 'B'}` s'affiche dans deux ordres différents ; `check.sh` fixe la graine pour ces deux lignes, et tous les autres exemples trient leurs sets avant de les afficher.

**.NET et Java ne sont pas d'accord sur la modification d'une collection pendant qu'on la parcourt.** `Dictionary.Remove` dans un `foreach` ne lève plus d'exception depuis .NET Core 3.0, `List.Remove` si, et la `LinkedHashMap` de Java lève `ConcurrentModificationException`. La leçon 3 affiche les trois.

**pytest 9 lit `[tool.pytest]`** dans `pyproject.toml`, avec les types TOML natifs ; les versions plus anciennes ne lisaient que `[tool.pytest.ini_options]`. Le cours utilise la nouvelle table.

**`dotnet run file.cs` met le build en cache.** Comme dans le cours TypeScript, une seconde exécution d'un fichier inchangé n'appelle pas le compilateur, donc `check.sh` exécute `dotnet clean` puis `dotnet run --no-cache` sur chaque comparaison C#. `compare/global.json` fixe le SDK à 10.0.100 avec `latestFeature`, puisque la machine a aussi une préversion de .NET 11.

**La CI ne peut pas encore être poussée.** Le jeton GitHub utilisé pour pousser n'a pas le scope `workflow`, et GitHub refuse un push qui ajoute un fichier sous `.github/workflows/`. Le code et les leçons sont poussés ; `.github/workflows/python-examples.yml` attend `gh auth refresh -s workflow`. Tant qu'il ne tourne pas, les parties Linux et macOS de la leçon 1 sont *à vérifier*.

## 2026-09-15 — Ce que les leçons ont trouvé dans GuitarAlchemist/ga (cc42d21)

J'ai cloné [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga) au commit [`cc42d21`](https://github.com/GuitarAlchemist/ga/commit/cc42d215504631e168daf3bdf2c6d47b5c9fbe93) dans un dossier de travail, installé chaque projet Python avec l'uv du cours, et analysé les fichiers Python avec un petit script basé sur le module `ast` (valeurs par défaut mutables, `except` nus, annotations).

- **Un bug : HTTP 400 devient 500 dans le service de graphe de connaissances.** Dans [`Apps/ga-graphiti-service/main.py`](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Apps/ga-graphiti-service/main.py#L102-L115), chaque endpoint lève `HTTPException(status_code=400, ...)` à l'intérieur d'un `try` dont le `except Exception as e` lève `HTTPException(status_code=500, detail=str(e))`. `HTTPException` est une `Exception`, donc le 400 est intercepté et le client reçoit un 500 dont le détail est `400: episode has no user`. La même forme se trouve aux lignes 111, 127, 143 et 159. Reproduction, réduite à FastAPI 0.121 avec un `TestClient` : le script affiche `500 {'detail': '400: episode has no user'}`. La correction est un `except HTTPException: raise` avant la clause générale. La leçon 7 (erreurs) l'utilisera ; je n'ai pas ouvert d'issue.
- **L'agent de gouvernance n'a pas de fichier de verrouillage.** [`Apps/demerzel-agent/pyproject.toml`](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Apps/demerzel-agent/pyproject.toml) ne déclare que des bornes inférieures (`acp-sdk>=0.2.0`), et le [README](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Apps/demerzel-agent/README.md) dit `uv sync`, qui résout les versions du jour : `acp-sdk` 1.0.3 le 2026-09-15, une version majeure au-dessus de la borne. Les imports fonctionnent encore.
- **Son point d'entrée n'est jamais installé.** `[project.scripts] demerzel = "src.server:main"` demande un système de build, et le fichier n'en a pas : `uv sync` affiche un avertissement disant qu'il saute les points d'entrée, et `uv run demerzel` a ensuite trouvé un `demerzel.exe` sans rapport ailleurs dans mon `PATH`. Le package de niveau supérieur s'appelle en outre `src`. La leçon 1 explique les projets packagés ; la leçon 8 reviendra sur l'organisation.
- **Importer le service de gouvernance peut échouer.** [`src/services/governance.py`, lignes 13-28](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Apps/demerzel-agent/src/services/governance.py#L13-L28), appelle `find_governance_root()` au niveau du module, qui lève `FileNotFoundError` quand aucun dossier `governance/demerzel` n'est trouvé, donc tout import du module, y compris celui d'un test, échoue hors du dépôt. La variable d'environnement `DEMERZEL_ROOT` n'est lue qu'après la remontée des dossiers parents, donc elle ne peut pas l'emporter sur un dossier qui existe. La leçon 2 le réduit, et son troisième exercice lit la racine de façon paresseuse.
- **Des erreurs avalées.** Le même fichier a `except Exception: continue` ou l'équivalent aux lignes 46-56, 83 et 130, et `src/services/github.py` aux lignes 33 et 53 ; [`epistemic_agent.py`, lignes 145-148](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Apps/demerzel-agent/src/agents/epistemic_agent.py#L145-L148), a `except ValueError: pass`. Pour la leçon 7.
- **Des collections à la main.** Le résumé des tenseurs et le filtre `where` d'`epistemic_agent.py` sont les exercices 1 et 3 de la leçon 3.
- **L'image du service** utilise `python:3.11-slim` et uv 0.10.4 avec un `requirements.txt` de bornes inférieures, donc chaque build de l'image peut résoudre des versions différentes.
- **Des scripts aux dépendances non déclarées.** [`Scripts/train-router-head.py`](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Scripts/train-router-head.py#L22-L25) importe NumPy et scikit-learn, et rien dans le dépôt ne les déclare ; un bloc PEP 723 le ferait (leçon 1, exercice 2). Il lit aussi du JSON avec `json.load(open(path))`, sans `with` ni encodage (lignes 63, 66 et 71). `Scripts/validate_optick_sae_artifacts.py` intercepte l'`ImportError` de `jsonschema` aux lignes 34-39. Deux scripts commencent par un BOM UTF-8, que Python accepte.
- **Aucun argument par défaut mutable** dans aucun fichier Python des trois dépôts, d'après l'analyse `ast`.

## 2026-09-15 — GuitarAlchemist/ix (2190c68) et tars (26c5f67)

- **IX** entraîne son autoencodeur parcimonieux depuis [`crates/ix-optick-sae/python`](https://github.com/GuitarAlchemist/ix/tree/2190c685e3664488c9a3d0c1388c96b868a178cb/crates/ix-optick-sae/python), avec un `requirements.txt` de bornes inférieures et sans verrouillage ; le code importe `Dict`, `List` et `Optional` depuis `typing` (leçon 3), et ses tests utilisent `unittest` avec une modification de `sys.path` au lieu de pytest (leçon 9).
- **TARS committe un environnement virtuel.** [`Scripts/tts-venv`](https://github.com/GuitarAlchemist/tars/tree/26c5f67252c84f1b9da48a415c58b0725cb5b45c/Scripts/tts-venv) contient 2 691 fichiers : un `python.exe` Windows, pip, Flask et le wheel compilé de NumPy 2.2.4 pour CPython 3.12, ajoutés dans le commit `2402545` le 2025-04-01. Il fonctionne sur un seul OS et une seule version de Python, et alourdit chaque clone. Un `pyproject.toml` et un fichier de verrouillage le remplaceraient (leçon 1).
- **Les outils Python de TARS ne déclarent rien.** Sept des 23 scripts de [`tools/python`](https://github.com/GuitarAlchemist/tars/tree/26c5f67252c84f1b9da48a415c58b0725cb5b45c/tools/python) importent `requests`, `aiohttp` ou `websockets`, et le dossier n'a pas de fichier de dépendances. 272 de leurs 288 fonctions n'ont pas d'annotation de retour.
- **Des séquences d'échappement invalides** dans `implementation-starter.py`, ligne 184, et `meta-programming-demo.py`, ligne 497, signalées par Python 3.14.7 (leçon 3).
- **Des `except` nus ou qui avalent les erreurs** dans `autonomous-quality-loop.py` (lignes 388, 408, 462, 482 et 491), `tars-mcp-client.py` (89), `tars-evolve-cli.py` (443 et 462) et `real-multimedia-processor.py` (142). Pour la leçon 7.

## 2026-09-15 — Ce site

- Le [cours d'apprentissage automatique](../../machine-learning-ix/01-data-and-evaluation/) installe NumPy et scikit-learn avec `pip install` dans le Python qui se trouve dans le `PATH`. Les versions sont fixées, ce qui est bien, mais les packages atterrissent dans le Python du système ou de l'utilisateur, et peuvent entrer en conflit avec ceux d'un autre projet. Un bloc PEP 723 et `uv run --script`, ou un petit projet uv dans `code/`, les isoleraient. Je n'ai pas modifié ce cours.

## À vérifier

- L'installation de la leçon 1 sous Linux et macOS : la sortie d'`uv python install` et les noms des builds, à partir des logs de la CI une fois que le workflow tournera.
- `check.sh` sur les trois OS : les sorties ont été capturées sous Windows, et les séparateurs de chemins, les fins de ligne et la culture C# pourraient différer.
- Le comportement du Python install manager sous Windows, que je n'ai pas installé sur cette machine.
