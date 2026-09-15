---
title: 4. Functions
description: Positional, keyword, positional-only and keyword-only parameters, defaults evaluated once, *args and **kwargs, closures and late binding, lambdas, and decorators that keep the signature they wrap — compared with C# optional parameters, params, lambdas and attributes, and with Java overloads, varargs and annotations.
sidebar:
  order: 4
---

Code: the files [`examples/l04_*`](https://github.com/spareilleux/learn/tree/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/examples) and [`errors/l04_*`](https://github.com/spareilleux/learn/tree/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/errors), and the C# and Java sides in [`compare_fail/l04_defaults.cs`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/compare_fail/l04_defaults.cs), [`compare/l04_closures.cs`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/compare/l04_closures.cs), [`compare_fail/L04Capture.java`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/compare_fail/L04Capture.java) and [`compare/l04_attributes.cs`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/compare/l04_attributes.cs).

A function is an object, created when its `def` statement runs ([lesson 2](../02-execution-model/#importing-runs-the-module)). It can be stored in a list or a dict, passed to another function and returned by one, which is how `sorted(..., key=...)` worked in [lesson 3](../03-collections/#comprehensions-instead-of-linq). This lesson is about what a `def` declares, what it captures, and what can wrap it.

## Parameters

Python has no overloading: one name, one function. What C# does with overloads and optional parameters, and Java with overloads alone, a Python function does with defaults and with the way each parameter may be passed:

```python
# examples/l04_parameters.py
NOTES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]


# note is positional-only (before /), semitones can be passed either way, and flats is keyword-only (after *)
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


# Keyword arguments can skip the parameters that have a default, in any order
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

Every parameter can be passed by position or by name, as in C#, where `Describe("G", seventh: "minor")` is a named argument. Two markers in the list of parameters restrict that:

- the parameters before `/` are **positional-only** ([PEP 570](https://peps.python.org/pep-0570/)): the caller can't write `note=`, so the name can change without breaking anyone, and a `**kwargs` can accept a key called `note`. Many built-ins are declared this way: `len(obj=[1])` is an error.
- the parameters after `*` are **keyword-only** ([PEP 3102](https://peps.python.org/pep-3102/)): `flats` must be written `flats=True`. A boolean passed by position, `transpose("A", 1, True)`, says nothing at the call site; C# can only recommend a named argument there, Python can require it.

A wrong call is a `TypeError` raised by the call itself, when that line runs. mypy finds the same five errors without running anything:

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

Each call is wrapped in a `lambda` so that the loop can run them one by one and print each message; `try` and `except` are the subject of lesson 7.

## Defaults are evaluated once

A default value is an expression, and Python evaluates it **once, when `def` runs**, then stores the resulting object in the function. Every call that doesn't pass the argument receives that same object:

```python
# examples/l04_defaults.py
def add_note(note: str, chord: list[str] = []) -> list[str]:
    chord.append(note)  # the default list was created once, when def ran, and every call shares it
    return chord


print(add_note("C"))
print(add_note("E"))
print(add_note("G", ["G"]))
print(add_note("B"))
print(add_note.__defaults__)


# A default is an expression evaluated once, when def runs, like any other statement
calls = 0


def next_id() -> int:
    global calls
    calls += 1
    return calls


def log(message: str, entry_id: int = next_id()) -> str:
    return f"#{entry_id} {message}"


print(log("first"), log("second"), "next_id was called", calls, "time")

# Arguments are evaluated before the call, even the default of dict.get that isn't needed
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

The second call returned `['C', 'E']`: the list that the first call filled is the default, visible in `add_note.__defaults__`. With an immutable default, `0`, `""`, `None` or a tuple, the sharing is harmless, since nothing can change the object. With a list, a dict or a set, it is the most famous trap of the language. The fix, `None` as the default and a new list inside the function, is exercise 1.

`log` shows the other half: `next_id()` ran once, when `def log` ran, so both entries are `#1`. A default is not a way to compute a fresh value per call. And the last line is not about defaults at all: `entry.get("id", f"generated-{next_id()}")` evaluates its second argument before the call, even though the key exists.

C# refuses both traps at compile time, since a default must be a constant:

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

C# stores the constant in the caller's compiled code, which is why it must be a constant; Java has no default parameters and uses overloads. mypy 2.3.1 accepts `chord: list[str] = []` without a word. [Ruff](https://docs.astral.sh/ruff/)'s rule [B006](https://docs.astral.sh/ruff/rules/mutable-argument-default/) reports it (lesson 13).

## `*args` and `**kwargs`

A parameter written `*name` collects the extra positional arguments into a tuple, like C#'s `params` and Java's varargs. A parameter written `**name` collects the extra keyword arguments into a dict, which neither language has:

```python
# examples/l04_varargs.py
from typing import Any


def chord(root: str, *intervals: int, **options: Any) -> str:
    # intervals is a tuple of the extra positional arguments, options a dict of the extra keyword arguments
    return f"{root} {intervals} {options}"


print(chord("C"))
print(chord("C", 4, 7, 11, voicing="drop 2", inversion=1))

shape = [4, 7]
settings = {"voicing": "open"}
print(chord("A", *shape, **settings))  # * and ** unpack a sequence and a dict into arguments


def logged(*args: Any, **kwargs: Any) -> str:
    print("forwarding", args, kwargs)
    return chord(*args, **kwargs)  # forward everything, whatever the signature


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

The annotation describes each item: `*intervals: int` is a tuple of `int`, and `**options: Any` a dict from `str` to `Any`. At the call site, `*` and `**` do the reverse and unpack a sequence and a dict into arguments. `logged` forwards whatever it receives, which is how a function wraps another without repeating its signature, and what a decorator does below. A bare `*` in a signature, as in `transpose`, is the same marker without a name: it collects nothing and makes the following parameters keyword-only.

`**kwargs` is convenient and opaque: the signature no longer says which keys are accepted, and a misspelled one travels until something rejects it, or doesn't. Use it to forward arguments, not to design an API; lesson 6 shows how `TypedDict` and `Unpack` give its keys types.

## Closures

A function defined inside another one can read the variables of the enclosing function, and keeps them alive after that function has returned: it is a **closure**, as a C# or Java lambda is.

```python
# examples/l04_closures.py
from collections.abc import Callable


def make_counter() -> Callable[[], int]:
    count = 0

    def increment() -> int:
        nonlocal count  # assign to the variable of the enclosing function, not to a new local one
        count += 1
        return count

    return increment


counter = make_counter()
print(counter(), counter(), counter())

# A closure captures the variable, not its value at the time: the three lambdas see the last value of i
transposers: list[Callable[[int], int]] = [lambda note: note + i for i in range(3)]
print([transpose(10) for transpose in transposers])

# lambda is an expression that holds one expression; def is needed for statements
by_length: Callable[[list[str]], int] = lambda notes: len(notes)
print(sorted([["C", "E", "G", "B"], ["A", "C", "E"]], key=by_length))
```

```text
> uv run python examples/l04_closures.py
1 2 3
[12, 12, 12]
[['A', 'C', 'E'], ['C', 'E', 'G', 'B']]
```

`increment` assigns `count`, and [lesson 2](../02-execution-model/#scope-functions-not-blocks) showed that an assignment makes a name local to the whole function. `nonlocal count` says that the name belongs to the enclosing function instead, as `global` does for the module. Without it, the first call would raise `UnboundLocalError`. C# and Java lambdas don't need this declaration: C# captures variables and lets the lambda assign them, and Java forbids the assignment.

The list of lambdas prints `[12, 12, 12]`, not `[10, 11, 12]`. A closure captures the **variable** `i`, not its value when the lambda was created, and by the time the lambdas run, the loop has left `i` at `2`. C# behaves the same with a `for` loop, and changed `foreach` in C# 5 so that each iteration has its own variable:

```cs
// compare/l04_closures.cs
var fromFor = new List<Func<int, int>>();
for (int i = 0; i < 3; i++)
{
    fromFor.Add(note => note + i); // one i for the whole loop, as in Python
}
Console.WriteLine(string.Join(", ", fromFor.Select(transpose => transpose(10))));

var fromForeach = new List<Func<int, int>>();
foreach (var i in Enumerable.Range(0, 3))
{
    fromForeach.Add(note => note + i); // since C# 5, a new i for each iteration
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

The C# `for` loop gives `13`, since its `i` ends at `3`, where Python's `range` leaves `i` on the last value it produced. Java avoids the question: a lambda can only capture a variable that is never assigned again, so the value and the variable are the same thing.

The classic Python workaround turns the variable into a default value, which is evaluated when each lambda is created. It runs, and mypy can't type it:

```python
# errors/l04_capture.py
from collections.abc import Callable

# A default value is evaluated when each lambda is created, so i=i stores the current value of i
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

`i=i` also adds a parameter that any caller can override. [`functools.partial`](https://docs.python.org/3.14/library/functools.html#functools.partial) or a small factory function are cleaner, and are exercise 2.

A `lambda` holds a single expression, with no statements and no annotations. It fits a `key=` argument; assigning one to a name, as `by_length` does here to show its type, is what [PEP 8](https://peps.python.org/pep-0008/#programming-recommendations) asks you to replace with a `def`, which has a name in tracebacks.

## Decorators

A **decorator** is a function that receives a function and returns the function that replaces it. The syntax `@log_calls` above a `def` means `interval = log_calls(interval)`, applied once, right after `def` has created the function:

```python
# examples/l04_decorators.py
import functools
from collections.abc import Callable


# A decorator is a function that receives a function and returns the one that replaces it
def log_calls[**P, R](func: Callable[P, R]) -> Callable[P, R]:
    @functools.wraps(func)  # copies __name__, __doc__ and the rest from func to wrapper
    def wrapper(*args: P.args, **kwargs: P.kwargs) -> R:
        result = func(*args, **kwargs)
        print(f"{func.__name__}{args} -> {result!r}")
        return result

    return wrapper


@log_calls  # the same as: interval = log_calls(interval)
def interval(low: str, high: str) -> int:
    notes = ["C", "D", "E", "F", "G", "A", "B"]
    return notes.index(high) - notes.index(low)


interval("C", "G")
print(interval.__name__)

# A decorator runs once, when def runs: this registry is filled at import time, before any call
AGENTS: dict[str, Callable[[str], str]] = {}


def agent(name: str) -> Callable[[Callable[[str], str]], Callable[[str], str]]:
    print(f"agent({name!r}) is called")

    def register(handler: Callable[[str], str]) -> Callable[[str], str]:
        print(f"registering {handler.__name__} as {name!r}")
        AGENTS[name] = handler
        return handler

    return register


@agent(name="governance")  # agent(name=...) returns the decorator, which then receives the function
def governance_handler(text: str) -> str:
    return f"governance: {text}"


print("registered:", list(AGENTS))
print(AGENTS["governance"]("show beliefs"))


# functools.cache keeps every result, keyed by the arguments
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

Three decorators, three uses:

- **`log_calls` wraps**. `wrapper` is a closure over `func`, and forwards `*args` and `**kwargs` to it. [`functools.wraps`](https://docs.python.org/3.14/library/functools.html#functools.wraps) copies the name, the docstring and the other attributes of `func` onto `wrapper`, which is why `interval.__name__` is still `interval`; without it, every decorated function would be called `wrapper` in tracebacks and in pytest's output. The annotation `[**P, R]` declares a *parameter specification* `P` and a type variable `R` ([PEP 612](https://peps.python.org/pep-0612/), with the syntax of [PEP 695](https://peps.python.org/pep-0695/)): `Callable[P, R]` in, `Callable[P, R]` out tells mypy that the decorated function keeps the exact signature of the original, so `interval(1, 2)` is still an error. A decorator typed `Callable[..., Any]` would erase it.
- **`agent` registers**. `@agent(name="governance")` is a call first: `agent` returns `register`, and `register` receives the function. The output shows the order: both prints happen when the module runs the `def`, before anything calls the handler. This is how Flask's `@app.route`, FastAPI's `@app.post` and pytest's fixtures attach functions to a framework.
- **`functools.cache` memoizes**. [`functools.cache`](https://docs.python.org/3.14/library/functools.html#functools.cache) stores each result in a dict keyed by the arguments, which must therefore be hashable ([lesson 3](../03-collections/#hashing-and-changing-a-collection-while-iterating)). Each of the 91 values from `fibonacci(0)` to `fibonacci(90)` is computed once, the 91 misses; the naive recursion would make several billion billion calls.

C# attributes and Java annotations look the same, and are not. An attribute is metadata attached to the method: nothing runs when the method is declared, and the attribute object is only created when code asks for it through reflection:

```cs
// compare/l04_attributes.cs
using System.Reflection;

Console.WriteLine("the program starts");
var handler = typeof(Program).GetMethod(nameof(GovernanceHandler), BindingFlags.NonPublic | BindingFlags.Static)!;
Console.WriteLine("reading the attributes");
var agent = handler.GetCustomAttribute<AgentAttribute>()!; // the attribute object is created here
Console.WriteLine($"{agent.Name} -> {handler.Invoke(null, ["show beliefs"])}");

partial class Program
{
    // An attribute is metadata: nothing runs until code asks for it through reflection
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

What a Python decorator does in plain code, .NET and Java frameworks do with that metadata plus a mechanism that reads it: ASP.NET Core scans `[HttpPost]` at startup, Spring creates a [proxy](https://docs.spring.io/spring-framework/reference/core/aop/proxying.html) around a bean for `@Transactional`, and a [source generator](https://learn.microsoft.com/dotnet/csharp/roslyn-sdk/source-generators-overview) writes code at compile time. In Python, the decorator is the mechanism, and it replaces the function object itself.

## In real projects

**GA's governance agent** declares its two agents with a decorator factory from the [ACP SDK](https://github.com/i-am-bee/acp): [`src/server.py`, lines 36-56](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Apps/demerzel-agent/src/server.py#L36-L56) calls `@agent(name="demerzel-governance", description=..., metadata=...)` above `async def governance_handler(input: list[Message])`, the shape of `agent(name="governance")` above. The parameter is called `input`, which hides the built-in function `input` inside the handler, legal and harmless here; [`src/agents/epistemic_agent.py`, line 15](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Apps/demerzel-agent/src/agents/epistemic_agent.py#L15) does the same.

**Its governance service** computes a fallback that is rarely used: [`src/services/governance.py`, line 140](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Apps/demerzel-agent/src/services/governance.py#L140) writes `slug = entry.get("id", datetime.now(timezone.utc).strftime("%Y%m%d-%H%M%S"))`, which formats the current time on every call, including when the entry has an `id`, as the last line of `l04_defaults.py` showed. It costs a few microseconds and changes nothing; `entry.get("id") or datetime.now(...)...` would evaluate the time only when needed, and would also replace an empty `id`.

**Its knowledge-graph service** uses defaults as markers: [`Apps/ga-graphiti-service/main.py`, lines 102-106](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Apps/ga-graphiti-service/main.py#L102-L106) declares `service: GraphitiMusicService = Depends(get_graphiti_service)`. `Depends(...)` is evaluated once, when `def` runs, and that is the point: [FastAPI](https://fastapi.tiangolo.com/tutorial/dependencies/) reads the marker object from the signature and calls `get_graphiti_service` for each request. A default object shared by every call is harmless when nobody mutates it.

**Its router-head trainer** memoizes by hand: [`Scripts/train-router-head.py`, lines 37-47](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Scripts/train-router-head.py#L37-L47) looks up an MD5 of the text in a dict before calling Ollama, then saves the dict to JSON. `functools.cache` wouldn't replace it, since its cache lives only as long as the process. The same file defines `head_probs` as a closure over the trained weights `W` and `b` ([lines 90-95](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Scripts/train-router-head.py#L90-L95)), and stops the whole training at the first embedding that fails ([lines 78-81](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Scripts/train-router-head.py#L78-L81)), which is where exercise 3 comes from.

A scan of the Python files of GA, IX and TARS at the pinned commits with Python's [`ast`](https://docs.python.org/3.14/library/ast.html) module found no mutable default argument (see the [journal](../journal/)).

## Key takeaways

- One function per name: defaults and keyword arguments replace overloads. `/` makes the parameters before it positional-only, `*` makes the ones after it keyword-only; use keyword-only for flags.
- A default is evaluated once, when `def` runs. Never use a list, dict or set as a default: use `None` and create the object inside.
- `*args` is a tuple and `**kwargs` a dict; `*` and `**` unpack at the call site. Forward with them, don't design APIs with `**kwargs`.
- A closure captures variables, not values: lambdas created in a loop all see the last value. Use `functools.partial` or a factory. Assigning a captured variable needs `nonlocal`.
- A decorator is a function applied when `def` runs, which replaces the function. Use `functools.wraps`, and type it with `[**P, R]` so the signature survives.
- C# attributes and Java annotations are metadata read later; a decorator is code that runs at import.

## Exercises

1. Fix `add_note` from [`examples/l04_defaults.py`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/examples/l04_defaults.py) so that each call without a chord starts from an empty list, keeping the same call syntax, and write a test that fails on the original.

<details>
<summary>Solution</summary>

[`solutions/l04_ex1_add_note.py`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/solutions/l04_ex1_add_note.py):

```python
# solutions/l04_ex1_add_note.py
def add_note(note: str, chord: list[str] | None = None) -> list[str]:
    # None is immutable, so the shared default is harmless; the list is created on each call
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

The test, in [`tests/test_l04.py`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/tests/test_l04.py), calls the function twice, since the first call always succeeds:

```python
def test_each_call_gets_its_own_list() -> None:
    assert add_note("C") == ["C"]
    assert add_note("E") == ["E"]
```

`if chord is None`, not `if not chord`: an empty list passed by the caller is falsy ([lesson 2](../02-execution-model/#truthiness)), and `not chord` would replace it with a new list, which the caller would never see filled. A dataclass field has the same problem and the same kind of answer, `field(default_factory=list)`, in lesson 5.

</details>

2. Write `make_transposers(count)`, which returns `count` functions where the function at index `k` transposes a note by `k` semitones, without the `i=i` trick. Write it twice, once with `functools.partial` and once with a factory function.

<details>
<summary>Solution</summary>

[`solutions/l04_ex2_transposers.py`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/solutions/l04_ex2_transposers.py):

```python
# solutions/l04_ex2_transposers.py
import functools
from collections.abc import Callable

NOTES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]


def transpose(semitones: int, note: str) -> str:
    return NOTES[(NOTES.index(note) + semitones) % 12]


def make_transposers(count: int) -> list[Callable[[str], str]]:
    # partial stores the value of semitones now, when each function is created
    return [functools.partial(transpose, semitones) for semitones in range(count)]


def make_transposers_with_a_factory(count: int) -> list[Callable[[str], str]]:
    def by(semitones: int) -> Callable[[str], str]:
        return lambda note: transpose(semitones, note)  # each call of by has its own semitones

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

`partial(transpose, semitones)` evaluates `semitones` when it is called, like any argument, and stores the value. The factory works because each call of `by` creates a new scope with its own `semitones`, which is exactly what C# 5 did for `foreach`. mypy types both, where the `i=i` lambda failed.

</details>

3. Write a decorator `retry(times, exceptions)` that calls the decorated function again when it raises one of `exceptions`, up to `times` attempts, prints each failure, re-raises the last one, and lets any other exception through at once. The decorated function must keep its name and its signature for mypy. Try it on a fake embedding call, the kind of call that stops GA's [`train-router-head.py`](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Scripts/train-router-head.py#L78-L81) at the first failure.

<details>
<summary>Solution</summary>

A decorator with arguments is three functions deep: `retry` receives the settings and returns `decorate`, which receives the function and returns `wrapper`. [`solutions/l04_ex3_retry.py`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/solutions/l04_ex3_retry.py):

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
            raise AssertionError("unreachable")  # the loop always returns or raises

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

`except exceptions` accepts a tuple of exception classes, and a bare `raise` re-raises the current exception with its traceback. The final `raise AssertionError` is never reached, but without it mypy would see a path where `wrapper` returns nothing. The two tests in [`tests/test_l04.py`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/tests/test_l04.py) check that it gives up after the last attempt and that a `KeyError` goes through at once. A real client would wait between attempts, with a growing delay; libraries such as [Tenacity](https://tenacity.readthedocs.io/) do this, like [Polly](https://www.pollydocs.org/) in .NET and Resilience4j in Java.

</details>

## Sources

- [Python tutorial — More on defining functions](https://docs.python.org/3.14/tutorial/controlflow.html#more-on-defining-functions), including [special parameters](https://docs.python.org/3.14/tutorial/controlflow.html#special-parameters) and [default argument values](https://docs.python.org/3.14/tutorial/controlflow.html#default-argument-values)
- [Python reference — Function definitions](https://docs.python.org/3.14/reference/compound_stmts.html#function-definitions), [Calls](https://docs.python.org/3.14/reference/expressions.html#calls), [Lambdas](https://docs.python.org/3.14/reference/expressions.html#lambda), [The `nonlocal` statement](https://docs.python.org/3.14/reference/simple_stmts.html#the-nonlocal-statement)
- [`functools`](https://docs.python.org/3.14/library/functools.html)
- [PEP 318 — Decorators for functions and methods](https://peps.python.org/pep-0318/), [PEP 3102 — Keyword-only arguments](https://peps.python.org/pep-3102/), [PEP 570 — Positional-only parameters](https://peps.python.org/pep-0570/), [PEP 612 — Parameter specification variables](https://peps.python.org/pep-0612/), [PEP 695 — Type parameter syntax](https://peps.python.org/pep-0695/)
- [mypy — Declaring decorators](https://mypy.readthedocs.io/en/stable/generics.html#declaring-decorators)
- [Microsoft — Named and optional arguments](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/named-and-optional-arguments), [Lambda expressions: capture of outer variables](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/lambda-expressions#capture-of-outer-variables-and-variable-scope-in-lambda-expressions), [Attributes](https://learn.microsoft.com/dotnet/csharp/advanced-topics/reflection-and-attributes/), [Compiler error CS1736](https://learn.microsoft.com/dotnet/csharp/language-reference/compiler-messages/cs1736)
- [The Java Language Specification, §15.27.2 — Lambda body](https://docs.oracle.com/javase/specs/jls/se25/html/jls-15.html#jls-15.27.2), for effectively final captured variables
