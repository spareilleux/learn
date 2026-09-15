---
title: 4. Fonctions
description: Paramètres positionnels, nommés, positional-only et keyword-only, valeurs par défaut évaluées une seule fois, *args et **kwargs, closures et liaison tardive, lambdas, et décorateurs qui conservent la signature qu'ils enveloppent — comparés aux paramètres optionnels, à params, aux lambdas et aux attributs de C#, et aux surcharges, varargs et annotations de Java.
sidebar:
  order: 4
---

Code : les fichiers [`examples/l04_*`](https://github.com/spareilleux/learn/tree/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/examples) et [`errors/l04_*`](https://github.com/spareilleux/learn/tree/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/errors), et les côtés C# et Java dans [`compare_fail/l04_defaults.cs`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/compare_fail/l04_defaults.cs), [`compare/l04_closures.cs`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/compare/l04_closures.cs), [`compare_fail/L04Capture.java`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/compare_fail/L04Capture.java) et [`compare/l04_attributes.cs`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/compare/l04_attributes.cs).

Une fonction est un objet, créé quand son instruction `def` s'exécute ([leçon 2](../02-execution-model/#importer-exécute-le-module)). Elle peut être stockée dans une liste ou un dict, passée à une autre fonction et renvoyée par une fonction, c'est ainsi que fonctionnait `sorted(..., key=...)` dans la [leçon 3](../03-collections/#des-compréhensions-au-lieu-de-linq). Cette leçon porte sur ce que déclare un `def`, ce qu'il capture, et ce qui peut l'envelopper.

## Les paramètres

Python n'a pas de surcharge : un nom, une fonction. Ce que C# fait avec des surcharges et des paramètres optionnels, et Java avec des surcharges seulement, une fonction Python le fait avec des valeurs par défaut et avec la façon dont chaque paramètre peut être passé :

```python
# examples/l04_parameters.py
NOTES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]


# note est positional-only (avant /), semitones peut être passé des deux façons, et flats est keyword-only (après *)
def transpose(note: str, /, semitones: int = 0, *, flats: bool = False) -> str:
    result = NOTES[(NOTES.index(note) + semitones) % 12]
    if flats and result.endswith("#"):
        return NOTES[NOTES.index(result) + 1] + "b"
    return result


print(transpose("E"))
print(transpose("E", 3), transpose("E", semitones=3))
print(transpose("A", 1, flats=True))


def describe(root: str, quality: str = "major", seventh: str | None = None) -> str:
    return f"{root} {quality}" + (f" with a {seventh} seventh" if seventh else "")


# Les arguments nommés peuvent sauter les paramètres qui ont une valeur par défaut, dans n'importe quel ordre
print(describe("G", seventh="minor"))
print(describe(seventh="major", root="C"))
```

```text
> uv run python examples/l04_parameters.py
E
G G
Bb
G major with a minor seventh
C major with a major seventh
```

Chaque paramètre peut être passé par position ou par nom, comme en C#, où `Describe("G", seventh: "minor")` est un argument nommé. Deux marqueurs dans la liste des paramètres restreignent cela :

- les paramètres avant `/` sont **positional-only** ([PEP 570](https://peps.python.org/pep-0570/)) : l'appelant ne peut pas écrire `note=`, donc le nom peut changer sans casser personne, et un `**kwargs` peut accepter une clé appelée `note`. Beaucoup de fonctions intégrées sont déclarées ainsi : `len(obj=[1])` est une erreur.
- les paramètres après `*` sont **keyword-only** ([PEP 3102](https://peps.python.org/pep-3102/)) : `flats` doit s'écrire `flats=True`. Un booléen passé par position, `transpose("A", 1, True)`, ne dit rien à l'endroit de l'appel ; C# peut seulement y recommander un argument nommé, Python peut l'exiger.

Un mauvais appel est une `TypeError` levée par l'appel lui-même, quand cette ligne s'exécute. mypy trouve les cinq mêmes erreurs sans rien exécuter :

```python
# errors/l04_calls.py
from collections.abc import Callable


def transpose(note: str, /, semitones: int = 0, *, flats: bool = False) -> str:
    return note


calls: list[Callable[[], str]] = [
    lambda: transpose(),
    lambda: transpose("E", 3, True),
    lambda: transpose(note="E"),
    lambda: transpose("E", 3, semitones=4),
    lambda: transpose("E", octave=2),
]
for call in calls:
    try:
        call()
    except TypeError as e:
        print(e)
```

```text
> uv run python errors/l04_calls.py
transpose() missing 1 required positional argument: 'note'
transpose() takes from 1 to 2 positional arguments but 3 were given
transpose() got some positional-only arguments passed as keyword arguments: 'note'
transpose() got multiple values for argument 'semitones'
transpose() got an unexpected keyword argument 'octave'
> uv run mypy errors/l04_calls.py
errors/l04_calls.py:10: error: Too few arguments for "transpose"  [call-arg]
errors/l04_calls.py:11: error: Too many positional arguments for "transpose"  [call-arg]
errors/l04_calls.py:12: error: Unexpected keyword argument "note" for "transpose"  [call-arg]
errors/l04_calls.py:13: error: "transpose" gets multiple values for keyword argument "semitones"  [misc]
errors/l04_calls.py:14: error: Unexpected keyword argument "octave" for "transpose"  [call-arg]
Found 5 errors in 1 file (checked 1 source file)
```

Chaque appel est enveloppé dans une `lambda` pour que la boucle puisse les exécuter un par un et afficher chaque message ; `try` et `except` sont le sujet de la leçon 7.

## Les valeurs par défaut sont évaluées une seule fois

Une valeur par défaut est une expression, et Python l'évalue **une seule fois, quand `def` s'exécute**, puis stocke l'objet obtenu dans la fonction. Chaque appel qui ne passe pas l'argument reçoit ce même objet :

```python
# examples/l04_defaults.py
def add_note(note: str, chord: list[str] = []) -> list[str]:
    chord.append(note)  # la liste par défaut a été créée une fois, quand def s'est exécuté, et tous les appels la partagent
    return chord


print(add_note("C"))
print(add_note("E"))
print(add_note("G", ["G"]))
print(add_note("B"))
print(add_note.__defaults__)


# Une valeur par défaut est une expression évaluée une fois, quand def s'exécute, comme toute autre instruction
calls = 0


def next_id() -> int:
    global calls
    calls += 1
    return calls


def log(message: str, entry_id: int = next_id()) -> str:
    return f"#{entry_id} {message}"


print(log("first"), log("second"), "next_id was called", calls, "time")

# Les arguments sont évalués avant l'appel, même la valeur par défaut de dict.get qui ne sert pas
entry = {"id": "methylation-42"}
print(entry.get("id", f"generated-{next_id()}"), "next_id was called", calls, "times")
```

```text
> uv run python examples/l04_defaults.py
['C']
['C', 'E']
['G', 'G']
['C', 'E', 'B']
(['C', 'E', 'B'],)
#1 first #1 second next_id was called 1 time
methylation-42 next_id was called 2 times
```

Le second appel a renvoyé `['C', 'E']` : la liste qu'a remplie le premier appel est la valeur par défaut, visible dans `add_note.__defaults__`. Avec une valeur par défaut immuable, `0`, `""`, `None` ou un tuple, le partage est sans danger, puisque rien ne peut modifier l'objet. Avec une liste, un dict ou un set, c'est le piège le plus célèbre du langage. La correction, `None` comme valeur par défaut et une nouvelle liste dans la fonction, est l'exercice 1.

`log` montre l'autre moitié : `next_id()` s'est exécuté une fois, quand `def log` s'est exécuté, donc les deux entrées sont `#1`. Une valeur par défaut n'est pas un moyen de calculer une valeur neuve à chaque appel. Et la dernière ligne ne concerne pas du tout les valeurs par défaut : `entry.get("id", f"generated-{next_id()}")` évalue son second argument avant l'appel, même si la clé existe.

C# refuse les deux pièges à la compilation, puisqu'une valeur par défaut doit être une constante :

```cs
// compare_fail/l04_defaults.cs
Console.WriteLine(string.Join(" ", AddNote("C")));

static List<string> AddNote(string note, List<string> chord = new List<string>())
{
    chord.Add(note);
    return chord;
}
```

```text
> dotnet run l04_defaults.cs
compare_fail/l04_defaults.cs(4,63): error CS1736: Default parameter value for 'chord' must be a compile-time constant

The build failed. Fix the build errors and run again.
```

C# stocke la constante dans le code compilé de l'appelant, c'est pourquoi elle doit être une constante ; Java n'a pas de paramètres par défaut et utilise des surcharges. mypy 2.3.1 accepte `chord: list[str] = []` sans un mot. [Ruff](https://docs.astral.sh/ruff/) le signale avec sa règle [B006](https://docs.astral.sh/ruff/rules/mutable-argument-default/) (leçon 13).

## `*args` et `**kwargs`

Un paramètre écrit `*name` rassemble les arguments positionnels en trop dans un tuple, comme le `params` de C# et les varargs de Java. Un paramètre écrit `**name` rassemble les arguments nommés en trop dans un dict, ce qu'aucun des deux langages n'a :

```python
# examples/l04_varargs.py
from typing import Any


def chord(root: str, *intervals: int, **options: Any) -> str:
    # intervals est un tuple des arguments positionnels en trop, options un dict des arguments nommés en trop
    return f"{root} {intervals} {options}"


print(chord("C"))
print(chord("C", 4, 7, 11, voicing="drop 2", inversion=1))

shape = [4, 7]
settings = {"voicing": "open"}
print(chord("A", *shape, **settings))  # * et ** déballent une séquence et un dict en arguments


def logged(*args: Any, **kwargs: Any) -> str:
    print("forwarding", args, kwargs)
    return chord(*args, **kwargs)  # tout transmettre, quelle que soit la signature


print(logged("G", 4, 7, 10, inversion=2))
```

```text
> uv run python examples/l04_varargs.py
C () {}
C (4, 7, 11) {'voicing': 'drop 2', 'inversion': 1}
A (4, 7) {'voicing': 'open'}
forwarding ('G', 4, 7, 10) {'inversion': 2}
G (4, 7, 10) {'inversion': 2}
```

L'annotation décrit chaque élément : `*intervals: int` est un tuple de `int`, et `**options: Any` un dict de `str` vers `Any`. À l'endroit de l'appel, `*` et `**` font l'inverse et déballent une séquence et un dict en arguments. `logged` transmet tout ce qu'il reçoit, c'est ainsi qu'une fonction en enveloppe une autre sans répéter sa signature, et c'est ce que fait un décorateur plus bas. Un `*` seul dans une signature, comme dans `transpose`, est le même marqueur sans nom : il ne rassemble rien et rend les paramètres suivants keyword-only.

`**kwargs` est pratique et opaque : la signature ne dit plus quelles clés sont acceptées, et une clé mal orthographiée voyage jusqu'à ce que quelque chose la rejette, ou pas. Utilise-le pour transmettre des arguments, pas pour concevoir une API ; la leçon 6 montre comment `TypedDict` et `Unpack` donnent des types à ses clés.

## Closures

Une fonction définie à l'intérieur d'une autre peut lire les variables de la fonction englobante, et les garde en vie après que cette fonction a retourné : c'est une **closure**, comme l'est une lambda en C# ou en Java.

```python
# examples/l04_closures.py
from collections.abc import Callable


def make_counter() -> Callable[[], int]:
    count = 0

    def increment() -> int:
        nonlocal count  # assigner la variable de la fonction englobante, pas une nouvelle variable locale
        count += 1
        return count

    return increment


counter = make_counter()
print(counter(), counter(), counter())

# Une closure capture la variable, pas sa valeur du moment : les trois lambdas voient la dernière valeur de i
transposers: list[Callable[[int], int]] = [lambda note: note + i for i in range(3)]
print([transpose(10) for transpose in transposers])

# lambda est une expression qui contient une seule expression ; les instructions demandent def
by_length: Callable[[list[str]], int] = lambda notes: len(notes)
print(sorted([["C", "E", "G", "B"], ["A", "C", "E"]], key=by_length))
```

```text
> uv run python examples/l04_closures.py
1 2 3
[12, 12, 12]
[['A', 'C', 'E'], ['C', 'E', 'G', 'B']]
```

`increment` assigne `count`, et la [leçon 2](../02-execution-model/#portée--des-fonctions-pas-des-blocs) a montré qu'une assignation rend un nom local à toute la fonction. `nonlocal count` dit que le nom appartient plutôt à la fonction englobante, comme `global` le fait pour le module. Sans lui, le premier appel lèverait `UnboundLocalError`. Les lambdas de C# et de Java n'ont pas besoin de cette déclaration : C# capture les variables et laisse la lambda les assigner, et Java interdit l'assignation.

La liste de lambdas affiche `[12, 12, 12]`, pas `[10, 11, 12]`. Une closure capture la **variable** `i`, pas sa valeur au moment où la lambda a été créée, et au moment où les lambdas s'exécutent, la boucle a laissé `i` à `2`. C# se comporte de la même façon avec une boucle `for`, et a modifié `foreach` en C# 5 pour que chaque itération ait sa propre variable :

```cs
// compare/l04_closures.cs
var fromFor = new List<Func<int, int>>();
for (int i = 0; i < 3; i++)
{
    fromFor.Add(note => note + i); // un seul i pour toute la boucle, comme en Python
}
Console.WriteLine(string.Join(", ", fromFor.Select(transpose => transpose(10))));

var fromForeach = new List<Func<int, int>>();
foreach (var i in Enumerable.Range(0, 3))
{
    fromForeach.Add(note => note + i); // depuis C# 5, un nouveau i à chaque itération
}
Console.WriteLine(string.Join(", ", fromForeach.Select(transpose => transpose(10))));
```

```text
> dotnet run l04_closures.cs
13, 13, 13
10, 11, 12
> javac L04Capture.java
L04Capture.java:10: error: local variables referenced from a lambda expression must be final or effectively final
            transposers.add(note -> note + i);
                                           ^
1 error
```

La boucle `for` de C# donne `13`, puisque son `i` finit à `3`, là où le `range` de Python laisse `i` sur la dernière valeur qu'il a produite. Java évite la question : une lambda ne peut capturer qu'une variable qui n'est jamais réassignée, donc la valeur et la variable sont la même chose.

Le contournement classique en Python transforme la variable en valeur par défaut, évaluée à la création de chaque lambda. Il s'exécute, et mypy ne sait pas le typer :

```python
# errors/l04_capture.py
from collections.abc import Callable

# Une valeur par défaut est évaluée à la création de chaque lambda, donc i=i stocke la valeur courante de i
transposers: list[Callable[[int], int]] = [lambda note, i=i: note + i for i in range(3)]
print([transpose(10) for transpose in transposers])
```

```text
> uv run python errors/l04_capture.py
[10, 11, 12]
> uv run mypy errors/l04_capture.py
errors/l04_capture.py:5: error: Cannot infer type of lambda  [misc]
Found 1 error in 1 file (checked 1 source file)
```

`i=i` ajoute aussi un paramètre que n'importe quel appelant peut remplacer. [`functools.partial`](https://docs.python.org/3.14/library/functools.html#functools.partial) ou une petite fonction fabrique sont plus propres, et font l'objet de l'exercice 2.

Une `lambda` contient une seule expression, sans instructions et sans annotations. Elle convient à un argument `key=` ; en assigner une à un nom, comme le fait ici `by_length` pour montrer son type, c'est ce que la [PEP 8](https://peps.python.org/pep-0008/#programming-recommendations) demande de remplacer par un `def`, qui a un nom dans les tracebacks.

## Les décorateurs

Un **décorateur** est une fonction qui reçoit une fonction et renvoie la fonction qui la remplace. La syntaxe `@log_calls` au-dessus d'un `def` signifie `interval = log_calls(interval)`, appliqué une fois, juste après que `def` a créé la fonction :

```python
# examples/l04_decorators.py
import functools
from collections.abc import Callable


# Un décorateur est une fonction qui reçoit une fonction et renvoie celle qui la remplace
def log_calls[**P, R](func: Callable[P, R]) -> Callable[P, R]:
    @functools.wraps(func)  # copie __name__, __doc__ et le reste de func vers wrapper
    def wrapper(*args: P.args, **kwargs: P.kwargs) -> R:
        result = func(*args, **kwargs)
        print(f"{func.__name__}{args} -> {result!r}")
        return result

    return wrapper


@log_calls  # équivaut à : interval = log_calls(interval)
def interval(low: str, high: str) -> int:
    notes = ["C", "D", "E", "F", "G", "A", "B"]
    return notes.index(high) - notes.index(low)


interval("C", "G")
print(interval.__name__)

# Un décorateur s'exécute une fois, quand def s'exécute : ce registre est rempli à l'import, avant tout appel
AGENTS: dict[str, Callable[[str], str]] = {}


def agent(name: str) -> Callable[[Callable[[str], str]], Callable[[str], str]]:
    print(f"agent({name!r}) is called")

    def register(handler: Callable[[str], str]) -> Callable[[str], str]:
        print(f"registering {handler.__name__} as {name!r}")
        AGENTS[name] = handler
        return handler

    return register


@agent(name="governance")  # agent(name=...) renvoie le décorateur, qui reçoit ensuite la fonction
def governance_handler(text: str) -> str:
    return f"governance: {text}"


print("registered:", list(AGENTS))
print(AGENTS["governance"]("show beliefs"))


# functools.cache garde chaque résultat, avec les arguments pour clé
@functools.cache
def fibonacci(n: int) -> int:
    return n if n < 2 else fibonacci(n - 1) + fibonacci(n - 2)


print(fibonacci(90), fibonacci.cache_info())
```

```text
> uv run python examples/l04_decorators.py
interval('C', 'G') -> 4
interval
agent('governance') is called
registering governance_handler as 'governance'
registered: ['governance']
governance: show beliefs
2880067194370816120 CacheInfo(hits=88, misses=91, maxsize=None, currsize=91)
```

Trois décorateurs, trois usages :

- **`log_calls` enveloppe**. `wrapper` est une closure sur `func`, et lui transmet `*args` et `**kwargs`. [`functools.wraps`](https://docs.python.org/3.14/library/functools.html#functools.wraps) copie le nom, la docstring et les autres attributs de `func` sur `wrapper`, c'est pourquoi `interval.__name__` vaut toujours `interval` ; sans lui, chaque fonction décorée s'appellerait `wrapper` dans les tracebacks et dans la sortie de pytest. L'annotation `[**P, R]` déclare une *spécification de paramètres* `P` et une variable de type `R` ([PEP 612](https://peps.python.org/pep-0612/), avec la syntaxe de la [PEP 695](https://peps.python.org/pep-0695/)) : `Callable[P, R]` en entrée, `Callable[P, R]` en sortie dit à mypy que la fonction décorée garde exactement la signature de l'originale, donc `interval(1, 2)` reste une erreur. Un décorateur typé `Callable[..., Any]` l'effacerait.
- **`agent` enregistre**. `@agent(name="governance")` est d'abord un appel : `agent` renvoie `register`, et `register` reçoit la fonction. La sortie montre l'ordre : les deux affichages ont lieu quand le module exécute le `def`, avant que quoi que ce soit n'appelle le handler. C'est ainsi que le `@app.route` de Flask, le `@app.post` de FastAPI et les fixtures de pytest rattachent des fonctions à un framework.
- **`functools.cache` mémoïse**. [`functools.cache`](https://docs.python.org/3.14/library/functools.html#functools.cache) stocke chaque résultat dans un dict dont la clé est formée des arguments, qui doivent donc être hachables ([leçon 3](../03-collections/#le-hachage-et-modifier-une-collection-pendant-litération)). Chacune des 91 valeurs de `fibonacci(0)` à `fibonacci(90)` est calculée une fois, les 91 échecs de cache (*misses*) ; la récursion naïve ferait plusieurs milliards de milliards d'appels.

Les attributs de C# et les annotations de Java se ressemblent, et ne sont pas la même chose. Un attribut est une métadonnée attachée à la méthode : rien ne s'exécute quand la méthode est déclarée, et l'objet attribut n'est créé que quand du code le demande par réflexion :

```cs
// compare/l04_attributes.cs
using System.Reflection;

Console.WriteLine("the program starts");
var handler = typeof(Program).GetMethod(nameof(GovernanceHandler), BindingFlags.NonPublic | BindingFlags.Static)!;
Console.WriteLine("reading the attributes");
var agent = handler.GetCustomAttribute<AgentAttribute>()!; // l'objet attribut est créé ici
Console.WriteLine($"{agent.Name} -> {handler.Invoke(null, ["show beliefs"])}");

partial class Program
{
    // Un attribut est une métadonnée : rien ne s'exécute tant que du code ne le demande pas par réflexion
    [Agent("governance")]
    static string GovernanceHandler(string text) => $"governance: {text}";
}

[AttributeUsage(AttributeTargets.Method)]
class AgentAttribute : Attribute
{
    public AgentAttribute(string name)
    {
        Console.WriteLine($"AgentAttribute({name}) is created");
        Name = name;
    }

    public string Name { get; }
}
```

```text
> dotnet run l04_attributes.cs
the program starts
reading the attributes
AgentAttribute(governance) is created
governance -> governance: show beliefs
```

Ce qu'un décorateur Python fait en code ordinaire, les frameworks .NET et Java le font avec cette métadonnée plus un mécanisme qui la lit : ASP.NET Core analyse `[HttpPost]` au démarrage, Spring crée un [proxy](https://docs.spring.io/spring-framework/reference/core/aop/proxying.html) autour d'un bean pour `@Transactional`, et un [générateur de source](https://learn.microsoft.com/dotnet/csharp/roslyn-sdk/source-generators-overview) écrit du code à la compilation. En Python, le décorateur est le mécanisme, et il remplace l'objet fonction lui-même.

## Dans de vrais projets

**L'agent de gouvernance de GA** déclare ses deux agents avec une fabrique de décorateurs du [SDK ACP](https://github.com/i-am-bee/acp) : [`src/server.py`, lignes 36-56](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Apps/demerzel-agent/src/server.py#L36-L56) appelle `@agent(name="demerzel-governance", description=..., metadata=...)` au-dessus de `async def governance_handler(input: list[Message])`, la forme de l'`agent(name="governance")` ci-dessus. Le paramètre s'appelle `input`, ce qui masque la fonction intégrée `input` dans le handler, légal et sans conséquence ici ; [`src/agents/epistemic_agent.py`, ligne 15](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Apps/demerzel-agent/src/agents/epistemic_agent.py#L15) fait de même.

**Son service de gouvernance** calcule une valeur de repli rarement utilisée : [`src/services/governance.py`, ligne 140](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Apps/demerzel-agent/src/services/governance.py#L140) écrit `slug = entry.get("id", datetime.now(timezone.utc).strftime("%Y%m%d-%H%M%S"))`, qui formate l'heure courante à chaque appel, y compris quand l'entrée a un `id`, comme l'a montré la dernière ligne de `l04_defaults.py`. Cela coûte quelques microsecondes et ne change rien ; `entry.get("id") or datetime.now(...)...` n'évaluerait l'heure qu'en cas de besoin, et remplacerait aussi un `id` vide.

**Son service de graphe de connaissances** utilise les valeurs par défaut comme marqueurs : [`Apps/ga-graphiti-service/main.py`, lignes 102-106](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Apps/ga-graphiti-service/main.py#L102-L106) déclare `service: GraphitiMusicService = Depends(get_graphiti_service)`. `Depends(...)` est évalué une fois, quand `def` s'exécute, et c'est tout l'intérêt : [FastAPI](https://fastapi.tiangolo.com/tutorial/dependencies/) lit l'objet marqueur dans la signature et appelle `get_graphiti_service` pour chaque requête. Un objet par défaut partagé par tous les appels est sans danger quand personne ne le modifie.

**Son entraîneur de tête de routage** mémoïse à la main : [`Scripts/train-router-head.py`, lignes 37-47](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Scripts/train-router-head.py#L37-L47) cherche un MD5 du texte dans un dict avant d'appeler Ollama, puis enregistre le dict en JSON. `functools.cache` ne le remplacerait pas, puisque son cache ne vit que le temps du processus. Le même fichier définit `head_probs` comme une closure sur les poids entraînés `W` et `b` ([lignes 90-95](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Scripts/train-router-head.py#L90-L95)), et arrête tout l'entraînement au premier embedding qui échoue ([lignes 78-81](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Scripts/train-router-head.py#L78-L81)), d'où vient l'exercice 3.

Une analyse des fichiers Python de GA, IX et TARS aux commits épinglés avec le module [`ast`](https://docs.python.org/3.14/library/ast.html) de Python n'a trouvé aucun argument par défaut mutable (voir le [journal](../journal/)).

## À retenir

- Une fonction par nom : les valeurs par défaut et les arguments nommés remplacent les surcharges. `/` rend positional-only les paramètres qui le précèdent, `*` rend keyword-only ceux qui le suivent ; utilise keyword-only pour les options booléennes.
- Une valeur par défaut est évaluée une seule fois, quand `def` s'exécute. N'utilise jamais une liste, un dict ou un set comme valeur par défaut : utilise `None` et crée l'objet à l'intérieur.
- `*args` est un tuple et `**kwargs` un dict ; `*` et `**` déballent à l'endroit de l'appel. Transmets avec eux, ne conçois pas d'API avec `**kwargs`.
- Une closure capture des variables, pas des valeurs : les lambdas créées dans une boucle voient toutes la dernière valeur. Utilise `functools.partial` ou une fabrique. Assigner une variable capturée demande `nonlocal`.
- Un décorateur est une fonction appliquée quand `def` s'exécute, qui remplace la fonction. Utilise `functools.wraps`, et type-le avec `[**P, R]` pour que la signature survive.
- Les attributs de C# et les annotations de Java sont des métadonnées lues plus tard ; un décorateur est du code qui s'exécute à l'import.

## Exercices

1. Corrige `add_note` d'[`examples/l04_defaults.py`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/examples/l04_defaults.py) pour que chaque appel sans accord parte d'une liste vide, en gardant la même syntaxe d'appel, et écris un test qui échoue sur l'original.

<details>
<summary>Solution</summary>

[`solutions/l04_ex1_add_note.py`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/solutions/l04_ex1_add_note.py) :

```python
# solutions/l04_ex1_add_note.py
def add_note(note: str, chord: list[str] | None = None) -> list[str]:
    # None est immuable, donc la valeur par défaut partagée est sans danger ; la liste est créée à chaque appel
    if chord is None:
        chord = []
    chord.append(note)
    return chord


if __name__ == "__main__":
    print(add_note("C"), add_note("E"), add_note("G", ["G"]))
```

```text
> uv run python solutions/l04_ex1_add_note.py
['C'] ['E'] ['G', 'G']
```

Le test, dans [`tests/test_l04.py`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/tests/test_l04.py), appelle la fonction deux fois, puisque le premier appel réussit toujours :

```python
def test_each_call_gets_its_own_list() -> None:
    assert add_note("C") == ["C"]
    assert add_note("E") == ["E"]
```

`if chord is None`, pas `if not chord` : une liste vide passée par l'appelant est fausse ([leçon 2](../02-execution-model/#truthiness)), et `not chord` la remplacerait par une nouvelle liste, que l'appelant ne verrait jamais remplie. Un champ de dataclass a le même problème et le même genre de réponse, `field(default_factory=list)`, dans la leçon 5.

</details>

2. Écris `make_transposers(count)`, qui renvoie `count` fonctions où la fonction d'index `k` transpose une note de `k` demi-tons, sans l'astuce `i=i`. Écris-la deux fois, une fois avec `functools.partial` et une fois avec une fonction fabrique.

<details>
<summary>Solution</summary>

[`solutions/l04_ex2_transposers.py`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/solutions/l04_ex2_transposers.py) :

```python
# solutions/l04_ex2_transposers.py
import functools
from collections.abc import Callable

NOTES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]


def transpose(semitones: int, note: str) -> str:
    return NOTES[(NOTES.index(note) + semitones) % 12]


def make_transposers(count: int) -> list[Callable[[str], str]]:
    # partial stocke la valeur de semitones maintenant, à la création de chaque fonction
    return [functools.partial(transpose, semitones) for semitones in range(count)]


def make_transposers_with_a_factory(count: int) -> list[Callable[[str], str]]:
    def by(semitones: int) -> Callable[[str], str]:
        return lambda note: transpose(semitones, note)  # chaque appel de by a son propre semitones

    return [by(semitones) for semitones in range(count)]


if __name__ == "__main__":
    print([t("E") for t in make_transposers(4)])
    print([t("E") for t in make_transposers_with_a_factory(4)])
```

```text
> uv run python solutions/l04_ex2_transposers.py
['E', 'F', 'F#', 'G']
['E', 'F', 'F#', 'G']
```

`partial(transpose, semitones)` évalue `semitones` au moment où il est appelé, comme n'importe quel argument, et stocke la valeur. La fabrique fonctionne parce que chaque appel de `by` crée une nouvelle portée avec son propre `semitones`, ce qui est exactement ce qu'a fait C# 5 pour `foreach`. mypy type les deux, là où la lambda `i=i` échouait.

</details>

3. Écris un décorateur `retry(times, exceptions)` qui rappelle la fonction décorée quand elle lève l'une des `exceptions`, jusqu'à `times` tentatives, affiche chaque échec, relève la dernière exception, et laisse passer immédiatement toute autre exception. La fonction décorée doit garder son nom et sa signature pour mypy. Essaie-le sur un faux appel d'embedding, le genre d'appel qui arrête [`train-router-head.py`](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Scripts/train-router-head.py#L78-L81), dans GA, au premier échec.

<details>
<summary>Solution</summary>

Un décorateur avec arguments a trois niveaux de fonctions : `retry` reçoit les réglages et renvoie `decorate`, qui reçoit la fonction et renvoie `wrapper`. [`solutions/l04_ex3_retry.py`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/solutions/l04_ex3_retry.py) :

```python
# solutions/l04_ex3_retry.py
import functools
from collections.abc import Callable


def retry[**P, R](
    times: int, exceptions: tuple[type[Exception], ...] = (Exception,)
) -> Callable[[Callable[P, R]], Callable[P, R]]:
    def decorate(func: Callable[P, R]) -> Callable[P, R]:
        @functools.wraps(func)
        def wrapper(*args: P.args, **kwargs: P.kwargs) -> R:
            for attempt in range(1, times + 1):
                try:
                    return func(*args, **kwargs)
                except exceptions as e:
                    if attempt == times:
                        raise
                    print(f"{func.__name__}: attempt {attempt} failed ({e}), retrying")
            raise AssertionError("unreachable")  # la boucle renvoie ou lève toujours une exception

        return wrapper

    return decorate


if __name__ == "__main__":
    answers = iter([ConnectionError("refused"), TimeoutError("slow"), "nomic-embed-text"])

    @retry(times=3, exceptions=(ConnectionError, TimeoutError))
    def embedder_model(endpoint: str) -> str:
        answer = next(answers)
        if isinstance(answer, Exception):
            raise answer
        return f"{endpoint}: {answer}"

    print(embedder_model("http://localhost:11434"))
    print(embedder_model.__name__)
```

```text
> uv run python solutions/l04_ex3_retry.py
embedder_model: attempt 1 failed (refused), retrying
embedder_model: attempt 2 failed (slow), retrying
http://localhost:11434: nomic-embed-text
embedder_model
```

`except exceptions` accepte un tuple de classes d'exceptions, et un `raise` seul relève l'exception courante avec son traceback. Le `raise AssertionError` final n'est jamais atteint, mais sans lui mypy verrait un chemin où `wrapper` ne renvoie rien. Les deux tests de [`tests/test_l04.py`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/tests/test_l04.py) vérifient qu'il abandonne après la dernière tentative et qu'une `KeyError` passe immédiatement. Un vrai client attendrait entre les tentatives, avec un délai croissant ; des bibliothèques comme [Tenacity](https://tenacity.readthedocs.io/) le font, comme [Polly](https://www.pollydocs.org/) en .NET et Resilience4j en Java.

</details>

## Sources

- [Tutoriel Python — Davantage sur la définition des fonctions](https://docs.python.org/3.14/tutorial/controlflow.html#more-on-defining-functions), y compris les [paramètres spéciaux](https://docs.python.org/3.14/tutorial/controlflow.html#special-parameters) et les [valeurs par défaut des arguments](https://docs.python.org/3.14/tutorial/controlflow.html#default-argument-values)
- [Référence Python — Définitions de fonctions](https://docs.python.org/3.14/reference/compound_stmts.html#function-definitions), [Appels](https://docs.python.org/3.14/reference/expressions.html#calls), [Lambdas](https://docs.python.org/3.14/reference/expressions.html#lambda), [L'instruction `nonlocal`](https://docs.python.org/3.14/reference/simple_stmts.html#the-nonlocal-statement)
- [`functools`](https://docs.python.org/3.14/library/functools.html)
- [PEP 318 — Décorateurs pour les fonctions et les méthodes](https://peps.python.org/pep-0318/), [PEP 3102 — Arguments keyword-only](https://peps.python.org/pep-3102/), [PEP 570 — Paramètres positional-only](https://peps.python.org/pep-0570/), [PEP 612 — Variables de spécification de paramètres](https://peps.python.org/pep-0612/), [PEP 695 — Syntaxe des paramètres de type](https://peps.python.org/pep-0695/)
- [mypy — Déclarer des décorateurs](https://mypy.readthedocs.io/en/stable/generics.html#declaring-decorators)
- [Microsoft — Arguments nommés et facultatifs](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/named-and-optional-arguments), [Expressions lambda : capture des variables externes](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/lambda-expressions#capture-of-outer-variables-and-variable-scope-in-lambda-expressions), [Attributs](https://learn.microsoft.com/dotnet/csharp/advanced-topics/reflection-and-attributes/), [Erreur du compilateur CS1736](https://learn.microsoft.com/dotnet/csharp/language-reference/compiler-messages/cs1736)
- [The Java Language Specification, §15.27.2 — Lambda body](https://docs.oracle.com/javase/specs/jls/se25/html/jls-15.html#jls-15.27.2), pour les variables capturées effectivement finales
