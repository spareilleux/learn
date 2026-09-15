---
title: 4. Funciones
description: Parámetros posicionales, por palabra clave, solo posicionales y solo por palabra clave, valores por defecto evaluados una sola vez, *args y **kwargs, closures y enlace tardío, lambdas, y decoradores que conservan la firma que envuelven — comparado con los parámetros opcionales, params, las lambdas y los atributos de C#, y con las sobrecargas, los varargs y las anotaciones de Java.
sidebar:
  order: 4
---

Código: los archivos [`examples/l04_*`](https://github.com/spareilleux/learn/tree/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/examples) y [`errors/l04_*`](https://github.com/spareilleux/learn/tree/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/errors), y los equivalentes en C# y Java en [`compare_fail/l04_defaults.cs`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/compare_fail/l04_defaults.cs), [`compare/l04_closures.cs`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/compare/l04_closures.cs), [`compare_fail/L04Capture.java`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/compare_fail/L04Capture.java) y [`compare/l04_attributes.cs`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/compare/l04_attributes.cs).

Una función es un objeto, creado cuando se ejecuta su instrucción `def` ([lección 2](../02-execution-model/#importar-ejecuta-el-módulo)). Se puede guardar en una lista o un dict, pasar a otra función y devolver desde otra, que es como funcionó `sorted(..., key=...)` en la [lección 3](../03-collections/#comprensiones-en-lugar-de-linq). Esta lección trata de lo que declara un `def`, de lo que captura, y de lo que puede envolverlo.

## Parámetros

Python no tiene sobrecarga: un nombre, una función. Lo que C# hace con sobrecargas y parámetros opcionales, y Java solo con sobrecargas, una función Python lo hace con valores por defecto y con la forma en que se puede pasar cada parámetro:

```python
# examples/l04_parameters.py
NOTES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]


# note es solo posicional (antes de /), semitones se puede pasar de las dos formas, y flats es solo por palabra clave (después de *)
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


# Los argumentos por palabra clave pueden saltarse los parámetros que tienen valor por defecto, en cualquier orden
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

Todo parámetro se puede pasar por posición o por nombre, como en C#, donde `Describe("G", seventh: "minor")` es un argumento con nombre. Dos marcadores en la lista de parámetros lo restringen:

- los parámetros antes de `/` son **solo posicionales** ([PEP 570](https://peps.python.org/pep-0570/)): el llamador no puede escribir `note=`, así que el nombre puede cambiar sin romper nada a nadie, y un `**kwargs` puede aceptar una clave llamada `note`. Muchas funciones integradas se declaran así: `len(obj=[1])` es un error.
- los parámetros después de `*` son **solo por palabra clave** ([PEP 3102](https://peps.python.org/pep-3102/)): `flats` debe escribirse `flats=True`. Un booleano pasado por posición, `transpose("A", 1, True)`, no dice nada en el punto de llamada; C# solo puede recomendar ahí un argumento con nombre, Python puede exigirlo.

Una llamada incorrecta es un `TypeError` lanzado por la propia llamada, cuando se ejecuta esa línea. mypy encuentra los mismos cinco errores sin ejecutar nada:

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

Cada llamada está envuelta en una `lambda` para que el bucle pueda ejecutarlas una a una e imprimir cada mensaje; `try` y `except` son el tema de la lección 7.

## Los valores por defecto se evalúan una sola vez

Un valor por defecto es una expresión, y Python la evalúa **una sola vez, cuando se ejecuta `def`**, y luego guarda el objeto resultante en la función. Cada llamada que no pasa el argumento recibe ese mismo objeto:

```python
# examples/l04_defaults.py
def add_note(note: str, chord: list[str] = []) -> list[str]:
    chord.append(note)  # la lista por defecto se creó una vez, cuando se ejecutó def, y todas las llamadas la comparten
    return chord


print(add_note("C"))
print(add_note("E"))
print(add_note("G", ["G"]))
print(add_note("B"))
print(add_note.__defaults__)


# Un valor por defecto es una expresión evaluada una vez, cuando se ejecuta def, como cualquier otra instrucción
calls = 0


def next_id() -> int:
    global calls
    calls += 1
    return calls


def log(message: str, entry_id: int = next_id()) -> str:
    return f"#{entry_id} {message}"


print(log("first"), log("second"), "next_id was called", calls, "time")

# Los argumentos se evalúan antes de la llamada, incluso el valor por defecto de dict.get que no hace falta
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

La segunda llamada devolvió `['C', 'E']`: la lista que llenó la primera llamada es el valor por defecto, visible en `add_note.__defaults__`. Con un valor por defecto inmutable, `0`, `""`, `None` o una tupla, compartirlo no tiene consecuencias, ya que nada puede modificar el objeto. Con una lista, un dict o un set, es la trampa más famosa del lenguaje. La corrección, `None` como valor por defecto y una lista nueva dentro de la función, es el ejercicio 1.

`log` muestra la otra mitad: `next_id()` se ejecutó una vez, cuando se ejecutó `def log`, así que las dos entradas son `#1`. Un valor por defecto no es una forma de calcular un valor nuevo en cada llamada. Y la última línea no tiene nada que ver con los valores por defecto: `entry.get("id", f"generated-{next_id()}")` evalúa su segundo argumento antes de la llamada, aunque la clave exista.

C# rechaza las dos trampas en tiempo de compilación, ya que un valor por defecto debe ser una constante:

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

C# guarda la constante en el código compilado del llamador, y por eso debe ser una constante; Java no tiene parámetros por defecto y usa sobrecargas. mypy 2.3.1 acepta `chord: list[str] = []` sin decir nada. [Ruff](https://docs.astral.sh/ruff/) lo señala con su regla [B006](https://docs.astral.sh/ruff/rules/mutable-argument-default/) (lección 13).

## `*args` y `**kwargs`

Un parámetro escrito `*name` recoge los argumentos posicionales sobrantes en una tupla, como `params` en C# y los varargs en Java. Un parámetro escrito `**name` recoge los argumentos por palabra clave sobrantes en un dict, algo que no tiene ninguno de los dos lenguajes:

```python
# examples/l04_varargs.py
from typing import Any


def chord(root: str, *intervals: int, **options: Any) -> str:
    # intervals es una tupla de los argumentos posicionales sobrantes, options un dict de los argumentos por palabra clave sobrantes
    return f"{root} {intervals} {options}"


print(chord("C"))
print(chord("C", 4, 7, 11, voicing="drop 2", inversion=1))

shape = [4, 7]
settings = {"voicing": "open"}
print(chord("A", *shape, **settings))  # * y ** desempaquetan una secuencia y un dict en argumentos


def logged(*args: Any, **kwargs: Any) -> str:
    print("forwarding", args, kwargs)
    return chord(*args, **kwargs)  # reenviar todo, sea cual sea la firma


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

La anotación describe cada elemento: `*intervals: int` es una tupla de `int`, y `**options: Any` un dict de `str` a `Any`. En el punto de llamada, `*` y `**` hacen lo contrario y desempaquetan una secuencia y un dict en argumentos. `logged` reenvía lo que recibe, que es como una función envuelve a otra sin repetir su firma, y lo que hace un decorador más abajo. Un `*` solo en una firma, como en `transpose`, es el mismo marcador sin nombre: no recoge nada y hace que los parámetros siguientes sean solo por palabra clave.

`**kwargs` es cómodo y opaco: la firma ya no dice qué claves se aceptan, y una mal escrita viaja hasta que algo la rechaza, o no. Úsalo para reenviar argumentos, no para diseñar una API; la lección 6 muestra cómo `TypedDict` y `Unpack` dan tipos a sus claves.

## Closures

Una función definida dentro de otra puede leer las variables de la función contenedora, y las mantiene vivas después de que esa función haya retornado: es un **closure**, como lo es una lambda de C# o de Java.

```python
# examples/l04_closures.py
from collections.abc import Callable


def make_counter() -> Callable[[], int]:
    count = 0

    def increment() -> int:
        nonlocal count  # asignar la variable de la función contenedora, no una nueva variable local
        count += 1
        return count

    return increment


counter = make_counter()
print(counter(), counter(), counter())

# Un closure captura la variable, no su valor en ese momento: las tres lambdas ven el último valor de i
transposers: list[Callable[[int], int]] = [lambda note: note + i for i in range(3)]
print([transpose(10) for transpose in transposers])

# lambda es una expresión que contiene una sola expresión; para instrucciones hace falta def
by_length: Callable[[list[str]], int] = lambda notes: len(notes)
print(sorted([["C", "E", "G", "B"], ["A", "C", "E"]], key=by_length))
```

```text
> uv run python examples/l04_closures.py
1 2 3
[12, 12, 12]
[['A', 'C', 'E'], ['C', 'E', 'G', 'B']]
```

`increment` asigna `count`, y la [lección 2](../02-execution-model/#ámbito-funciones-no-bloques) mostró que una asignación hace que un nombre sea local en toda la función. `nonlocal count` dice que el nombre pertenece en cambio a la función contenedora, como hace `global` para el módulo. Sin él, la primera llamada lanzaría `UnboundLocalError`. Las lambdas de C# y Java no necesitan esta declaración: C# captura las variables y deja que la lambda las asigne, y Java prohíbe la asignación.

La lista de lambdas imprime `[12, 12, 12]`, no `[10, 11, 12]`. Un closure captura la **variable** `i`, no su valor en el momento en que se creó la lambda, y cuando las lambdas se ejecutan, el bucle ha dejado `i` en `2`. C# se comporta igual con un bucle `for`, y cambió `foreach` en C# 5 para que cada iteración tenga su propia variable:

```cs
// compare/l04_closures.cs
var fromFor = new List<Func<int, int>>();
for (int i = 0; i < 3; i++)
{
    fromFor.Add(note => note + i); // un solo i para todo el bucle, como en Python
}
Console.WriteLine(string.Join(", ", fromFor.Select(transpose => transpose(10))));

var fromForeach = new List<Func<int, int>>();
foreach (var i in Enumerable.Range(0, 3))
{
    fromForeach.Add(note => note + i); // desde C# 5, un i nuevo en cada iteración
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

El bucle `for` de C# da `13`, ya que su `i` termina en `3`, mientras que el `range` de Python deja `i` en el último valor que produjo. Java evita la cuestión: una lambda solo puede capturar una variable que no se vuelve a asignar nunca, así que el valor y la variable son lo mismo.

La solución clásica en Python convierte la variable en un valor por defecto, que se evalúa cuando se crea cada lambda. Se ejecuta, y mypy no puede tiparla:

```python
# errors/l04_capture.py
from collections.abc import Callable

# Un valor por defecto se evalúa cuando se crea cada lambda, así que i=i guarda el valor actual de i
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

`i=i` también añade un parámetro que cualquier llamador puede sobrescribir. [`functools.partial`](https://docs.python.org/3.14/library/functools.html#functools.partial) o una pequeña función fábrica son más limpias, y son el ejercicio 2.

Una `lambda` contiene una sola expresión, sin instrucciones y sin anotaciones. Encaja en un argumento `key=`; asignar una a un nombre, como hace aquí `by_length` para mostrar su tipo, es lo que [PEP 8](https://peps.python.org/pep-0008/#programming-recommendations) pide sustituir por un `def`, que tiene un nombre en los tracebacks.

## Decoradores

Un **decorador** es una función que recibe una función y devuelve la función que la sustituye. La sintaxis `@log_calls` encima de un `def` significa `interval = log_calls(interval)`, aplicada una vez, justo después de que `def` haya creado la función:

```python
# examples/l04_decorators.py
import functools
from collections.abc import Callable


# Un decorador es una función que recibe una función y devuelve la que la sustituye
def log_calls[**P, R](func: Callable[P, R]) -> Callable[P, R]:
    @functools.wraps(func)  # copia __name__, __doc__ y lo demás de func a wrapper
    def wrapper(*args: P.args, **kwargs: P.kwargs) -> R:
        result = func(*args, **kwargs)
        print(f"{func.__name__}{args} -> {result!r}")
        return result

    return wrapper


@log_calls  # lo mismo que: interval = log_calls(interval)
def interval(low: str, high: str) -> int:
    notes = ["C", "D", "E", "F", "G", "A", "B"]
    return notes.index(high) - notes.index(low)


interval("C", "G")
print(interval.__name__)

# Un decorador se ejecuta una vez, cuando se ejecuta def: este registro se llena al importar, antes de cualquier llamada
AGENTS: dict[str, Callable[[str], str]] = {}


def agent(name: str) -> Callable[[Callable[[str], str]], Callable[[str], str]]:
    print(f"agent({name!r}) is called")

    def register(handler: Callable[[str], str]) -> Callable[[str], str]:
        print(f"registering {handler.__name__} as {name!r}")
        AGENTS[name] = handler
        return handler

    return register


@agent(name="governance")  # agent(name=...) devuelve el decorador, que luego recibe la función
def governance_handler(text: str) -> str:
    return f"governance: {text}"


print("registered:", list(AGENTS))
print(AGENTS["governance"]("show beliefs"))


# functools.cache conserva cada resultado, con los argumentos como clave
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

Tres decoradores, tres usos:

- **`log_calls` envuelve**. `wrapper` es un closure sobre `func`, y le reenvía `*args` y `**kwargs`. [`functools.wraps`](https://docs.python.org/3.14/library/functools.html#functools.wraps) copia el nombre, la docstring y los demás atributos de `func` en `wrapper`, y por eso `interval.__name__` sigue siendo `interval`; sin él, todas las funciones decoradas se llamarían `wrapper` en los tracebacks y en la salida de pytest. La anotación `[**P, R]` declara una *especificación de parámetros* `P` y una variable de tipo `R` ([PEP 612](https://peps.python.org/pep-0612/), con la sintaxis de [PEP 695](https://peps.python.org/pep-0695/)): `Callable[P, R]` a la entrada y `Callable[P, R]` a la salida le dice a mypy que la función decorada conserva exactamente la firma de la original, así que `interval(1, 2)` sigue siendo un error. Un decorador tipado `Callable[..., Any]` la borraría.
- **`agent` registra**. `@agent(name="governance")` es primero una llamada: `agent` devuelve `register`, y `register` recibe la función. La salida muestra el orden: los dos prints ocurren cuando el módulo ejecuta el `def`, antes de que nada llame al handler. Así es como `@app.route` de Flask, `@app.post` de FastAPI y las fixtures de pytest asocian funciones a un framework.
- **`functools.cache` memoiza**. [`functools.cache`](https://docs.python.org/3.14/library/functools.html#functools.cache) guarda cada resultado en un dict cuya clave son los argumentos, que por tanto deben ser hashables ([lección 3](../03-collections/#hashing-y-modificar-una-colección-mientras-se-recorre)). Cada uno de los 91 valores de `fibonacci(0)` a `fibonacci(90)` se calcula una vez, los 91 fallos de caché; la recursión ingenua haría varios trillones de llamadas.

Los atributos de C# y las anotaciones de Java se parecen, y no son lo mismo. Un atributo es metadatos asociados al método: nada se ejecuta cuando se declara el método, y el objeto atributo solo se crea cuando el código lo pide mediante reflexión:

```cs
// compare/l04_attributes.cs
using System.Reflection;

Console.WriteLine("the program starts");
var handler = typeof(Program).GetMethod(nameof(GovernanceHandler), BindingFlags.NonPublic | BindingFlags.Static)!;
Console.WriteLine("reading the attributes");
var agent = handler.GetCustomAttribute<AgentAttribute>()!; // el objeto atributo se crea aquí
Console.WriteLine($"{agent.Name} -> {handler.Invoke(null, ["show beliefs"])}");

partial class Program
{
    // Un atributo es metadatos: nada se ejecuta hasta que el código lo pide mediante reflexión
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

Lo que un decorador de Python hace en código normal, los frameworks de .NET y Java lo hacen con esos metadatos más un mecanismo que los lee: ASP.NET Core examina `[HttpPost]` al arrancar, Spring crea un [proxy](https://docs.spring.io/spring-framework/reference/core/aop/proxying.html) alrededor de un bean para `@Transactional`, y un [generador de código fuente](https://learn.microsoft.com/dotnet/csharp/roslyn-sdk/source-generators-overview) escribe código en tiempo de compilación. En Python, el decorador es el mecanismo, y sustituye al propio objeto función.

## En proyectos reales

**El agente de gobernanza de GA** declara sus dos agentes con una fábrica de decoradores del [ACP SDK](https://github.com/i-am-bee/acp): [`src/server.py`, líneas 36-56](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Apps/demerzel-agent/src/server.py#L36-L56) llama a `@agent(name="demerzel-governance", description=..., metadata=...)` encima de `async def governance_handler(input: list[Message])`, la forma del `agent(name="governance")` de arriba. El parámetro se llama `input`, lo que oculta la función integrada `input` dentro del handler, algo legal y aquí sin consecuencias; [`src/agents/epistemic_agent.py`, línea 15](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Apps/demerzel-agent/src/agents/epistemic_agent.py#L15) hace lo mismo.

**Su servicio de gobernanza** calcula un valor de reserva que rara vez se usa: [`src/services/governance.py`, línea 140](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Apps/demerzel-agent/src/services/governance.py#L140) escribe `slug = entry.get("id", datetime.now(timezone.utc).strftime("%Y%m%d-%H%M%S"))`, que formatea la hora actual en cada llamada, también cuando la entrada tiene un `id`, como mostró la última línea de `l04_defaults.py`. Cuesta unos pocos microsegundos y no cambia nada; `entry.get("id") or datetime.now(...)...` solo evaluaría la hora cuando hiciera falta, y también sustituiría un `id` vacío.

**Su servicio de grafo de conocimiento** usa los valores por defecto como marcadores: [`Apps/ga-graphiti-service/main.py`, líneas 102-106](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Apps/ga-graphiti-service/main.py#L102-L106) declara `service: GraphitiMusicService = Depends(get_graphiti_service)`. `Depends(...)` se evalúa una vez, cuando se ejecuta `def`, y esa es la idea: [FastAPI](https://fastapi.tiangolo.com/tutorial/dependencies/) lee el objeto marcador en la firma y llama a `get_graphiti_service` en cada petición. Un objeto por defecto compartido por todas las llamadas no tiene consecuencias cuando nadie lo modifica.

**Su entrenador de la cabeza de enrutamiento** memoiza a mano: [`Scripts/train-router-head.py`, líneas 37-47](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Scripts/train-router-head.py#L37-L47) busca un MD5 del texto en un dict antes de llamar a Ollama, y luego guarda el dict en JSON. `functools.cache` no lo sustituiría, ya que su caché solo vive lo que dura el proceso. El mismo archivo define `head_probs` como un closure sobre los pesos entrenados `W` y `b` ([líneas 90-95](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Scripts/train-router-head.py#L90-L95)), y detiene todo el entrenamiento en el primer embedding que falla ([líneas 78-81](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Scripts/train-router-head.py#L78-L81)), de donde viene el ejercicio 3.

Un análisis de los archivos Python de GA, IX y TARS en los commits fijados con el módulo [`ast`](https://docs.python.org/3.14/library/ast.html) de Python no encontró ningún argumento por defecto mutable (ver el [diario](../journal/)).

## Puntos clave

- Una función por nombre: los valores por defecto y los argumentos por palabra clave sustituyen a las sobrecargas. `/` hace que los parámetros anteriores sean solo posicionales, `*` que los siguientes sean solo por palabra clave; usa solo por palabra clave para los flags.
- Un valor por defecto se evalúa una vez, cuando se ejecuta `def`. No uses nunca una lista, un dict o un set como valor por defecto: usa `None` y crea el objeto dentro.
- `*args` es una tupla y `**kwargs` un dict; `*` y `**` desempaquetan en el punto de llamada. Reenvía con ellos, no diseñes APIs con `**kwargs`.
- Un closure captura variables, no valores: las lambdas creadas en un bucle ven todas el último valor. Usa `functools.partial` o una fábrica. Asignar una variable capturada requiere `nonlocal`.
- Un decorador es una función aplicada cuando se ejecuta `def`, que sustituye a la función. Usa `functools.wraps`, y típalo con `[**P, R]` para que la firma sobreviva.
- Los atributos de C# y las anotaciones de Java son metadatos leídos más tarde; un decorador es código que se ejecuta al importar.

## Ejercicios

1. Corrige `add_note` de [`examples/l04_defaults.py`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/examples/l04_defaults.py) para que cada llamada sin acorde empiece con una lista vacía, conservando la misma sintaxis de llamada, y escribe una prueba que falle con el original.

<details>
<summary>Solución</summary>

[`solutions/l04_ex1_add_note.py`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/solutions/l04_ex1_add_note.py):

```python
# solutions/l04_ex1_add_note.py
def add_note(note: str, chord: list[str] | None = None) -> list[str]:
    # None es inmutable, así que compartir el valor por defecto no tiene consecuencias; la lista se crea en cada llamada
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

La prueba, en [`tests/test_l04.py`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/tests/test_l04.py), llama dos veces a la función, ya que la primera llamada siempre funciona:

```python
def test_each_call_gets_its_own_list() -> None:
    assert add_note("C") == ["C"]
    assert add_note("E") == ["E"]
```

`if chord is None`, no `if not chord`: una lista vacía pasada por el llamador es falsy ([lección 2](../02-execution-model/#valores-truthy)), y `not chord` la sustituiría por una lista nueva, que el llamador nunca vería llena. Un campo de dataclass tiene el mismo problema y el mismo tipo de respuesta, `field(default_factory=list)`, en la lección 5.

</details>

2. Escribe `make_transposers(count)`, que devuelve `count` funciones donde la función del índice `k` transporta una nota `k` semitonos, sin el truco `i=i`. Escríbela dos veces, una con `functools.partial` y otra con una función fábrica.

<details>
<summary>Solución</summary>

[`solutions/l04_ex2_transposers.py`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/solutions/l04_ex2_transposers.py):

```python
# solutions/l04_ex2_transposers.py
import functools
from collections.abc import Callable

NOTES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]


def transpose(semitones: int, note: str) -> str:
    return NOTES[(NOTES.index(note) + semitones) % 12]


def make_transposers(count: int) -> list[Callable[[str], str]]:
    # partial guarda el valor de semitones ahora, cuando se crea cada función
    return [functools.partial(transpose, semitones) for semitones in range(count)]


def make_transposers_with_a_factory(count: int) -> list[Callable[[str], str]]:
    def by(semitones: int) -> Callable[[str], str]:
        return lambda note: transpose(semitones, note)  # cada llamada a by tiene su propio semitones

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

`partial(transpose, semitones)` evalúa `semitones` cuando se llama, como cualquier argumento, y guarda el valor. La fábrica funciona porque cada llamada a `by` crea un ámbito nuevo con su propio `semitones`, que es exactamente lo que hizo C# 5 para `foreach`. mypy tipa las dos, donde la lambda `i=i` fallaba.

</details>

3. Escribe un decorador `retry(times, exceptions)` que vuelve a llamar a la función decorada cuando lanza una de `exceptions`, hasta `times` intentos, imprime cada fallo, vuelve a lanzar el último, y deja pasar de inmediato cualquier otra excepción. La función decorada debe conservar su nombre y su firma para mypy. Pruébalo con una llamada de embedding falsa, el tipo de llamada que detiene [`train-router-head.py`](https://github.com/GuitarAlchemist/ga/blob/cc42d215504631e168daf3bdf2c6d47b5c9fbe93/Scripts/train-router-head.py#L78-L81) de GA en el primer fallo.

<details>
<summary>Solución</summary>

Un decorador con argumentos tiene tres funciones de profundidad: `retry` recibe la configuración y devuelve `decorate`, que recibe la función y devuelve `wrapper`. [`solutions/l04_ex3_retry.py`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/solutions/l04_ex3_retry.py):

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
            raise AssertionError("unreachable")  # el bucle siempre retorna o lanza una excepción

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

`except exceptions` acepta una tupla de clases de excepción, y un `raise` solo vuelve a lanzar la excepción actual con su traceback. El `raise AssertionError` final nunca se alcanza, pero sin él mypy vería un camino en el que `wrapper` no devuelve nada. Las dos pruebas de [`tests/test_l04.py`](https://github.com/spareilleux/learn/blob/7d3b4bcda19a81326612cd833dc03b9ca77d3451/code/python-for-csharp-java/tests/test_l04.py) comprueban que se rinde después del último intento y que un `KeyError` pasa de inmediato. Un cliente real esperaría entre intentos, con un retardo creciente; bibliotecas como [Tenacity](https://tenacity.readthedocs.io/) lo hacen, como [Polly](https://www.pollydocs.org/) en .NET y Resilience4j en Java.

</details>

## Fuentes

- [Tutorial de Python — More on defining functions](https://docs.python.org/3.14/tutorial/controlflow.html#more-on-defining-functions), incluidos [special parameters](https://docs.python.org/3.14/tutorial/controlflow.html#special-parameters) y [default argument values](https://docs.python.org/3.14/tutorial/controlflow.html#default-argument-values)
- [Referencia de Python — Function definitions](https://docs.python.org/3.14/reference/compound_stmts.html#function-definitions), [Calls](https://docs.python.org/3.14/reference/expressions.html#calls), [Lambdas](https://docs.python.org/3.14/reference/expressions.html#lambda), [The `nonlocal` statement](https://docs.python.org/3.14/reference/simple_stmts.html#the-nonlocal-statement)
- [`functools`](https://docs.python.org/3.14/library/functools.html)
- [PEP 318 — Decorators for functions and methods](https://peps.python.org/pep-0318/), [PEP 3102 — Keyword-only arguments](https://peps.python.org/pep-3102/), [PEP 570 — Positional-only parameters](https://peps.python.org/pep-0570/), [PEP 612 — Parameter specification variables](https://peps.python.org/pep-0612/), [PEP 695 — Type parameter syntax](https://peps.python.org/pep-0695/)
- [mypy — Declaring decorators](https://mypy.readthedocs.io/en/stable/generics.html#declaring-decorators)
- [Microsoft — Argumentos opcionales y con nombre](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/named-and-optional-arguments), [Expresiones lambda: captura de variables externas](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/lambda-expressions#capture-of-outer-variables-and-variable-scope-in-lambda-expressions), [Atributos](https://learn.microsoft.com/dotnet/csharp/advanced-topics/reflection-and-attributes/), [Error del compilador CS1736](https://learn.microsoft.com/dotnet/csharp/language-reference/compiler-messages/cs1736)
- [The Java Language Specification, §15.27.2 — Lambda body](https://docs.oracle.com/javase/specs/jls/se25/html/jls-15.html#jls-15.27.2), para las variables capturadas efectivamente finales
