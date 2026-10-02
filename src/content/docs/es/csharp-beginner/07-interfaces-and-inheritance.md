---
title: 7. Interfaces y herencia
description: Construir una clase sobre otra mediante herencia, reemplazar métodos virtuales con override, exigirlos con una clase abstracta y compartir un contrato entre tipos sin relación con una interfaz.
sidebar:
  order: 7
---

Las clases de las lecciones 5 y 6 eran todas `sealed`: no se podía construir nada sobre ellas. Sin embargo, una guitarra y un ukelele son instrumentos de cuerda, con el mismo tipo de datos, un nombre y una afinación, y casi el mismo comportamiento. C# permite que una clase [**herede**](https://learn.microsoft.com/dotnet/csharp/fundamentals/object-oriented/inheritance) de otra y cambie solo lo que difiere. Esta lección presenta la herencia, `virtual` y `override`, las clases abstractas y las interfaces. Una idea las une, el [**polimorfismo**](https://learn.microsoft.com/dotnet/csharp/fundamentals/object-oriented/polymorphism): la misma llamada, `instrument.Describe()`, ejecuta código distinto según el objeto.

Todos los programas de esta lección están en [`code/csharp-beginner`](https://github.com/spareilleux/learn/tree/main/code/csharp-beginner); ejecuta uno con [`dotnet run`](https://learn.microsoft.com/dotnet/core/tools/dotnet-run) seguido de su ruta, por ejemplo `examples/l07_inheritance.cs`. `check.sh` compara sus salidas, y los errores del compilador de los fragmentos rechazados, con los archivos de `expected/`.

## La herencia: una clase construida sobre otra

```csharp
// Guitar y Ukulele derivan de StringInstrument: heredan sus miembros
List<StringInstrument> instruments = [new Guitar(), new Ukulele()];

foreach (StringInstrument instrument in instruments)
{
    // La variable es de tipo StringInstrument; la clase del objeto elige el Describe que se ejecuta
    Console.WriteLine(instrument.Describe());
}

Guitar guitar = new Guitar();
Console.WriteLine($"{guitar.Name} has {guitar.StringCount} strings and {guitar.FretCount} frets");
Console.WriteLine(guitar);                  // Console.WriteLine llama a la redefinición de ToString

class StringInstrument
{
    public string Name { get; }
    public string[] Tuning { get; }

    public StringInstrument(string name, string[] tuning)
    {
        Name = name;
        Tuning = tuning;
    }

    public int StringCount => Tuning.Length;

    public virtual string Describe() => $"{Name}: {string.Join(" ", Tuning)}";

    public override string ToString() => $"{Name} ({StringCount} strings)";
}

sealed class Guitar : StringInstrument
{
    public int FretCount => 22;

    public Guitar() : base("Guitar", ["E2", "A2", "D3", "G3", "B3", "E4"])
    {
    }
}

sealed class Ukulele : StringInstrument
{
    public Ukulele() : base("Ukulele", ["G4", "C4", "E4", "A4"])
    {
    }

    public override string Describe() => base.Describe() + ", re-entrant: G4 is above C4";
}
```

```text
Guitar: E2 A2 D3 G3 B3 E4
Ukulele: G4 C4 E4 A4, re-entrant: G4 is above C4
Guitar has 6 strings and 22 frets
Guitar (6 strings)
```

`class Guitar : StringInstrument` indica que `Guitar` **deriva** de `StringInstrument`, su **clase base**. Una `Guitar` tiene todo lo que tiene un `StringInstrument`, `Name`, `Tuning`, `StringCount`, `Describe` y `ToString`, más su propia `FretCount`. Los constructores son la excepción: no se heredan. El constructor `Guitar()` llama al de la clase base con [`base(...)`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/base) y le pasa el nombre y la afinación que necesita.

[`virtual`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/virtual) marca un método que las clases derivadas pueden reemplazar, y [`override`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/override) lo reemplaza. `Ukulele` redefine `Describe` y llama a la versión que reemplaza con `base.Describe()`, así que completa el texto en lugar de reescribirlo entero. `Guitar` no la redefine y conserva la versión base.

El bucle muestra el polimorfismo. Su variable es un `StringInstrument` y, aun así, para el ukelele, `instrument.Describe()` ejecuta la versión de `Ukulele`: decide la clase del objeto, no el tipo de la variable. Una `List<StringInstrument>` puede contener una `Guitar` y un `Ukulele` porque cada uno *es* un `StringInstrument`.

Toda clase deriva de [`object`](https://learn.microsoft.com/dotnet/api/system.object), aunque no nombre ninguna clase base. `object` tiene un método virtual [`ToString`](https://learn.microsoft.com/dotnet/api/system.object.tostring), que por defecto devuelve el nombre del tipo y al que `Console.WriteLine` llama para mostrar un objeto. `StringInstrument` lo redefine, así que `Console.WriteLine(guitar)` muestra `Guitar (6 strings)`. Los records de la lección 6 escriben esa redefinición por ti.

`Guitar` y `Ukulele` siguen siendo [`sealed`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/sealed): nada deriva de ellas. `StringInstrument` no lo es, porque derivar de ella es justamente el objetivo.

### Tres errores con la herencia

`override` solo funciona sobre un método que la clase base permite reemplazar. Sin `virtual`, el fragmento rechazado `compile_fail/l07_override_not_virtual.cs` falla:

```csharp
class StringInstrument
{
    public string Describe() => "a string instrument";
}

sealed class Ukulele : StringInstrument
{
    public override string Describe() => "a ukulele";
}
```

```text
l07_override_not_virtual.cs(11,28): error CS0506: 'Ukulele.Describe()': cannot override inherited member 'StringInstrument.Describe()' because it is not marked virtual, abstract, or override
```

El error contrario compila, con una simple advertencia. En `examples/l07_hiding_warning.cs`, el método base es `virtual`, pero `Ukulele` olvida `override`:

```csharp
StringInstrument uke = new Ukulele();
Console.WriteLine(uke.Describe());   // se ejecuta la versión base: el método de Ukulele solo la oculta

Ukulele sameKind = new Ukulele();
Console.WriteLine(sameKind.Describe());   // una variable de tipo Ukulele encuentra el método que oculta

class StringInstrument
{
    public virtual string Describe() => "a string instrument";
}

sealed class Ukulele : StringInstrument
{
    public string Describe() => "a ukulele";   // falta override
}
```

```text
l07_hiding_warning.cs(14,19): warning CS0114: 'Ukulele.Describe()' hides inherited member 'StringInstrument.Describe()'. To make the current member override that implementation, add the override keyword. Otherwise add the new keyword.
a string instrument
a ukulele
```

Sin `override`, el método de `Ukulele` no reemplaza al de la base; lo **oculta**, y solo una variable de tipo `Ukulele` lo encuentra. Mediante una variable `StringInstrument`, el programa muestra `a string instrument`: el polimorfismo se pierde, sin ningún error. El [modificador `new`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/new-modifier) que menciona la advertencia hace que la ocultación sea deliberada; la guía [saber cuándo usar override y new](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/knowing-when-to-use-override-and-new-keywords) compara ambos. Cuando empiezas y ves [CS0114](https://learn.microsoft.com/dotnet/csharp/misc/cs0114), casi siempre has olvidado `override`.

Por último, una clase `sealed` se niega a ser clase base. `compile_fail/l07_sealed_base.cs` hace derivar `TwelveString` de una `Guitar` sellada:

```text
l07_sealed_base.cs(8,22): error CS0509: 'TwelveString': cannot derive from sealed type 'Guitar'
```

## Las clases abstractas: una base que nunca es un objeto

¿Qué toca «un instrumento»? Nada: una guitarra se pulsa, un piano se toca golpeando sus teclas, un violín se toca con arco. Una [**clase abstracta**](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/abstract) describe una idea general de este tipo, que solo sus clases derivadas hacen concreta:

```csharp
// Instrument es abstracta: un objeto es una Guitar, un Piano o un Violin, nunca un simple Instrument
Instrument[] band = [new Guitar(), new Piano(), new Violin()];

foreach (Instrument instrument in band)
{
    Console.WriteLine(instrument.Play("A4"));
}

abstract class Instrument
{
    public string Name { get; }

    protected Instrument(string name) => Name = name;

    // Cada clase derivada debe decir cómo toca una nota
    public abstract string Play(string note);
}

sealed class Guitar : Instrument
{
    public Guitar() : base("Guitar")
    {
    }

    public override string Play(string note) => $"{Name}: pluck {note}";
}

sealed class Piano : Instrument
{
    public Piano() : base("Piano")
    {
    }

    public override string Play(string note) => $"{Name}: strike the {note} key";
}

sealed class Violin : Instrument
{
    public Violin() : base("Violin")
    {
    }

    public override string Play(string note) => $"{Name}: bow {note}";
}
```

```text
Guitar: pluck A4
Piano: strike the A4 key
Violin: bow A4
```

`public abstract string Play(string note);` no tiene cuerpo, solo un punto y coma. Un método abstracto es implícitamente virtual, y toda clase derivada que no sea ella misma abstracta debe redefinirlo. `Name` y el constructor, en cambio, se escriben una sola vez, en `Instrument`, y los comparten los tres instrumentos. El constructor es [`protected`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/protected): solo las clases derivadas pueden llamarlo.

El compilador vigila los dos extremos de la regla. `compile_fail/l07_new_abstract.cs` intenta `new Instrument("Kazoo")`:

```text
l07_new_abstract.cs(1,20): error CS0144: Cannot create an instance of the abstract type or interface 'Instrument'
```

Y `compile_fail/l07_missing_override.cs` declara una `Flute` que olvida `Play`:

```text
l07_missing_override.cs(9,14): error CS0534: 'Flute' does not implement inherited abstract member 'Instrument.Play(string)'
```

Las plantillas de acordes de Guitar Alchemist siguen este patrón, con un record. En el commit `5c3a52a`, [`ChordTemplate`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Domain.Core/Theory/Harmony/ChordTemplate.cs#L15-L18) es un `public abstract record` con un `abstract string Name`, y sus dos records derivados, [`TonalModal`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Domain.Core/Theory/Harmony/ChordTemplate.cs#L44-L46) y [`Analytical`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Domain.Core/Theory/Harmony/ChordTemplate.cs#L66-L68), redefinen cada uno `Name`.

## Las interfaces: un contrato que cualquier tipo puede firmar

Un instrumento y un cantante no tienen nada en común como clases, pero ambos tienen una tesitura, de una nota más grave a una nota más aguda. Una [**interfaz**](https://learn.microsoft.com/dotnet/csharp/fundamentals/types/interfaces) enuncia un contrato así, sin código, y cualquier tipo puede firmarlo:

```csharp
// Una interfaz es un contrato: una clase y un record lo firman, sin clase base común
List<IHasRange> performers =
[
    new FrettedInstrument("Guitar", 40, 64, 22),    // cuerdas al aire de mi2 a mi4, 22 trastes
    new FrettedInstrument("Ukulele", 60, 69, 12),   // cuerdas al aire de do4 a la4, 12 trastes
    new Voice("Alto", 53, 77),                      // de fa3 a fa5
];

foreach (IHasRange performer in performers)
{
    Console.WriteLine($"{performer.Name}: MIDI {performer.LowestMidi} to {performer.HighestMidi}");
}

foreach (int midi in new[] { 40, 55, 69, 84 })
{
    List<string> names = [];
    foreach (IHasRange performer in performers)
    {
        if (CanPlay(performer, midi))
        {
            names.Add(performer.Name);
        }
    }
    Console.WriteLine($"MIDI {midi}: {string.Join(", ", names)}");
}

bool CanPlay(IHasRange performer, int midi) => midi >= performer.LowestMidi && midi <= performer.HighestMidi;

interface IHasRange
{
    string Name { get; }
    int LowestMidi { get; }
    int HighestMidi { get; }
}

sealed class FrettedInstrument : IHasRange
{
    public string Name { get; }
    public int LowestMidi { get; }
    public int HighestMidi { get; }

    public FrettedInstrument(string name, int lowestOpen, int highestOpen, int frets)
    {
        Name = name;
        LowestMidi = lowestOpen;
        HighestMidi = highestOpen + frets;
    }
}

record Voice(string Name, int LowestMidi, int HighestMidi) : IHasRange;
```

```text
Guitar: MIDI 40 to 86
Ukulele: MIDI 60 to 81
Alto: MIDI 53 to 77
MIDI 40: Guitar
MIDI 55: Guitar, Alto
MIDI 69: Guitar, Ukulele, Alto
MIDI 84: Guitar
```

[`interface IHasRange`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/interface) enumera tres propiedades y nada de código. Un tipo que escribe `: IHasRange` después de su nombre **implementa** la interfaz: debe proporcionar cada uno de sus miembros. `FrettedInstrument` calcula su nota más aguda a partir de su cuerda al aire más aguda y de su número de trastes. Las propiedades posicionales de `Voice` ya tienen los nombres y tipos correctos, así que el record no necesita nada más. Los dos tipos no comparten ninguna clase base aparte de `object` y, aun así, una `List<IHasRange>` contiene ambos, y `CanPlay` acepta cualquiera de los dos: solo se apoya en el contrato. Los números MIDI cuentan semitonos, 12 por octava, como los do de la lección 4; los comentarios dan el nombre de las notas.

Una clase deriva de una sola clase base, pero puede implementar tantas interfaces como quiera, separadas por comas. El [`PositionLocation`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Domain.Core/Instruments/Positions/PositionLocation.cs#L5) de Guitar Alchemist, el record struct de la lección 6, implementa tres: `IStr` e `IFret`, dos interfaces de GA con una sola propiedad (por ejemplo, [`IStr`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Domain.Core/Instruments/Primitives/IStr.cs#L3-L6) solo pide un `Str Str { get; }`), y la interfaz de .NET [`IComparable<T>`](https://learn.microsoft.com/dotnet/api/system.icomparable-1), que permite ordenar las posiciones. Los nombres de interfaces empiezan por `I`, una convención de las [reglas de nomenclatura de .NET](https://learn.microsoft.com/dotnet/standard/design-guidelines/names-of-classes-structs-and-interfaces).

El compilador comprueba el contrato. En `compile_fail/l07_missing_interface_member.cs`, `record Voice(string Name, int LowestMidi) : IHasRange;` no tiene `HighestMidi`:

```text
l07_missing_interface_member.cs(11,45): error CS0535: 'Voice' does not implement interface member 'IHasRange.HighestMidi'
```

Entonces, ¿clase abstracta o interfaz? Una clase abstracta comparte código y datos: `Name` y su constructor existen una sola vez, en `Instrument`, y una clase solo puede tener esa única base. Una interfaz solo comparte un contrato, pero tipos que no tienen nada más en común, records incluidos, pueden firmarla todos, además de otras interfaces.

## Ejercicios

### Ejercicio 1 — ¿qué método se ejecuta?

Sin ejecutarlo, predice las cuatro líneas que muestra `exercises/l07_ex_predict.cs`.

```csharp
StringInstrument a = new Ukulele();
Ukulele b = new Ukulele();
StringInstrument c = new StringInstrument();

Console.WriteLine(a.Describe());
Console.WriteLine(b.Describe());
Console.WriteLine(c.Describe());
Console.WriteLine(a.Family());

class StringInstrument
{
    public virtual string Describe() => "strings";

    public string Family() => "chordophone";
}

sealed class Ukulele : StringInstrument
{
    public override string Describe() => "ukulele, " + base.Describe();
}
```

<details>
<summary>Solución</summary>

```text
ukulele, strings
ukulele, strings
strings
chordophone
```

`a` y `b` señalan objetos `Ukulele`: la redefinición se ejecuta en ambos casos, sea cual sea el tipo de la variable, y completa el texto base con `base.Describe()`. `c` es un simple `StringInstrument`. `Family` no es virtual y nadie la reemplaza: todos los objetos usan la versión base.

</details>

### Ejercicio 2 — una pedalera

Escribe una clase abstracta `Effect` con un `Name` y un método abstracto `string Apply(string sound)`, y dos efectos: `Distortion`, que convierte `E2` en `distortion(E2)`, y `Delay`, que recibe un número de repeticiones y convierte `E2` en `delay(E2, 3)`. Escribe después un método que pase un sonido por una `List<Effect>`, en orden, y devuelva los nombres de los efectos y el resultado. Prueba los dos órdenes. La solución comprobada está en `exercises/l07_ex_pedals.cs`.

<details>
<summary>Solución</summary>

```csharp
List<Effect> distortionFirst = [new Distortion(), new Delay(3)];
List<Effect> delayFirst = [new Delay(3), new Distortion()];

Console.WriteLine(Run(distortionFirst, "E2"));
Console.WriteLine(Run(delayFirst, "E2"));

string Run(List<Effect> pedalboard, string sound)
{
    List<string> names = [];
    foreach (Effect effect in pedalboard)
    {
        sound = effect.Apply(sound);
        names.Add(effect.Name);
    }
    return $"{string.Join(" -> ", names)}: {sound}";
}

abstract class Effect
{
    public string Name { get; }

    protected Effect(string name) => Name = name;

    public abstract string Apply(string sound);
}

sealed class Distortion : Effect
{
    public Distortion() : base("Distortion")
    {
    }

    public override string Apply(string sound) => $"distortion({sound})";
}

sealed class Delay : Effect
{
    private readonly int _repeats;

    public Delay(int repeats) : base("Delay") => _repeats = repeats;

    public override string Apply(string sound) => $"delay({sound}, {_repeats})";
}
```

```text
Distortion -> Delay: delay(distortion(E2), 3)
Delay -> Distortion: distortion(delay(E2, 3))
```

`Run` no sabe nada de la distorsión ni del delay: llama a `Apply` sobre cada `Effect`, y la redefinición de cada objeto hace el trabajo. Añadir un tercer efecto es escribir una clase más, sin tocar `Run`. `Delay` guarda su número de repeticiones en un campo privado, como en la lección 5.

</details>

### Ejercicio 3 — un teclado firma el contrato

Copia `IHasRange` y `Voice` del ejemplo de las interfaces, y añade un record `MidiKeyboard(int Keys, int LowestMidi)` que implemente `IHasRange`: su `Name` es `Keyboard (25 keys)` para 25 teclas, y su `HighestMidi` se calcula a partir de los otros dos. Muestra la tesitura de una contralto (53 a 77) y de un teclado de 25 teclas que empieza en do3 (48), y después quién puede tocar las notas MIDI 50, 60 y 75. La solución comprobada está en `exercises/l07_ex_keyboard.cs`.

<details>
<summary>Solución</summary>

```csharp
List<IHasRange> performers =
[
    new Voice("Alto", 53, 77),
    new MidiKeyboard(25, 48),       // 25 teclas a partir de do3
];

foreach (IHasRange performer in performers)
{
    Console.WriteLine($"{performer.Name}: MIDI {performer.LowestMidi} to {performer.HighestMidi}");
}

foreach (int midi in new[] { 50, 60, 75 })
{
    List<string> names = [];
    foreach (IHasRange performer in performers)
    {
        if (midi >= performer.LowestMidi && midi <= performer.HighestMidi)
        {
            names.Add(performer.Name);
        }
    }
    Console.WriteLine($"MIDI {midi}: {string.Join(", ", names)}");
}

interface IHasRange
{
    string Name { get; }
    int LowestMidi { get; }
    int HighestMidi { get; }
}

record Voice(string Name, int LowestMidi, int HighestMidi) : IHasRange;

record MidiKeyboard(int Keys, int LowestMidi) : IHasRange
{
    public string Name => $"Keyboard ({Keys} keys)";
    public int HighestMidi => LowestMidi + Keys - 1;
}
```

```text
Alto: MIDI 53 to 77
Keyboard (25 keys): MIDI 48 to 72
MIDI 50: Keyboard (25 keys)
MIDI 60: Alto, Keyboard (25 keys)
MIDI 75: Alto
```

`LowestMidi` viene de los paréntesis del record, `Name` y `HighestMidi` de propiedades calculadas entre sus llaves: a la interfaz no le importa cómo se escribe un miembro, solo que exista. 25 teclas a partir de 48 terminan en 72, no en 73, porque la primera tecla cuenta.

</details>

## Lo que debes recordar

- Una clase derivada hereda los miembros de su clase base, salvo los constructores; llama al constructor base con `base(...)`.
- `virtual` permite que una clase derivada reemplace un método, `override` lo reemplaza, y `base.Metodo()` llama a la versión reemplazada.
- La clase del objeto, y no el tipo de la variable, decide qué redefinición se ejecuta: eso es el polimorfismo.
- Olvidar `override` oculta el método en lugar de reemplazarlo (advertencia CS0114).
- Una clase abstracta no se puede instanciar, y sus miembros abstractos deben redefinirse.
- Una interfaz es un contrato sin código; una clase tiene una sola clase base pero puede implementar varias interfaces.

La siguiente lección, [excepciones y seguridad frente a null](../08-exceptions-and-null-safety/), tratará los casos en que un método no puede hacer lo que se le pide.

## Fuentes

- [Herencia](https://learn.microsoft.com/dotnet/csharp/fundamentals/object-oriented/inheritance), [polimorfismo](https://learn.microsoft.com/dotnet/csharp/fundamentals/object-oriented/polymorphism), [`System.Object`](https://learn.microsoft.com/dotnet/api/system.object), [`Object.ToString`](https://learn.microsoft.com/dotnet/api/system.object.tostring)
- Palabras clave: [`virtual`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/virtual), [`override`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/override), [`base`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/base), [`abstract`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/abstract), [`sealed`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/sealed), [`protected`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/protected), [`interface`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/interface), [el modificador `new`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/new-modifier)
- [Clases abstractas y selladas](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/abstract-and-sealed-classes-and-class-members), [saber cuándo usar override y new](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/knowing-when-to-use-override-and-new-keywords), [interfaces](https://learn.microsoft.com/dotnet/csharp/fundamentals/types/interfaces), [`IComparable<T>`](https://learn.microsoft.com/dotnet/api/system.icomparable-1)
- [Nombres de clases, estructuras e interfaces](https://learn.microsoft.com/dotnet/standard/design-guidelines/names-of-classes-structs-and-interfaces), [advertencia del compilador CS0114](https://learn.microsoft.com/dotnet/csharp/misc/cs0114)
