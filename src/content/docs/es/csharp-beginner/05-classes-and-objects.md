---
title: 5. Clases y objetos
description: Reunir datos y comportamiento en una clase, crear objetos, inicializarlos con constructores y controlar el acceso mediante campos y propiedades.
sidebar:
  order: 5
---

En la lección 4, los métodos recibían valores separados: el nombre de una cuerda, su frecuencia al aire y el número de traste. A medida que crece un programa, pasar siempre los mismos valores a cada método resulta incómodo. Una [clase](https://learn.microsoft.com/dotnet/csharp/fundamentals/types/classes) reúne los datos y las operaciones que les corresponden. Un **objeto** es una instancia concreta de esa clase. `GuitarString` es una clase; la cuerda mi grave y la cuerda la son dos objetos con datos distintos.

Ejecuta el programa de [`code/csharp-beginner`](https://github.com/spareilleux/learn/tree/main/code/csharp-beginner) con [`dotnet run`](https://learn.microsoft.com/dotnet/core/tools/dotnet-run) `examples/l05_objects.cs`. `check.sh` comprueba su salida. El programa usa [`Console.WriteLine`](https://learn.microsoft.com/dotnet/api/system.console.writeline) para escribir, [`Math.Pow`](https://learn.microsoft.com/dotnet/api/system.math.pow) para calcular la frecuencia en un traste y [`CultureInfo.InvariantCulture`](https://learn.microsoft.com/dotnet/api/system.globalization.cultureinfo.invariantculture) para mantener el mismo punto decimal en todas las máquinas.

```csharp
using System.Globalization;

GuitarString lowE = new GuitarString("E2", 82.41);
GuitarString a = new GuitarString("A2", 110.0);

Console.WriteLine($"{lowE.Name}: {lowE.FrequencyAt(12).ToString("F2", CultureInfo.InvariantCulture)} Hz");
Console.WriteLine($"Created: {GuitarString.CreatedCount}");

GuitarString sameString = lowE;
sameString.Rename("E2 (retuned)");
Console.WriteLine(lowE.Name);
Console.WriteLine(a.Name);

sealed class GuitarString
{
    private readonly double _openHz;

    public string Name { get; private set; }
    public double OpenHz => _openHz;
    public static int CreatedCount { get; private set; }

    public GuitarString(string name, double openHz)
    {
        Name = name;
        _openHz = openHz;
        CreatedCount++;
    }

    public void Rename(string name) => Name = name;

    public double FrequencyAt(int fret) => _openHz * Math.Pow(2, fret / 12.0);
}
```

```text
E2: 164.82 Hz
Created: 2
E2 (retuned)
A2
```

## De la clase al objeto

La declaración `class` define un tipo nuevo. `new GuitarString("E2", 82.41)` crea un objeto y llama a su **constructor**. El segundo `new` crea otro objeto. El constructor lleva el nombre de la clase, no tiene tipo de retorno y recibe mediante parámetros los valores iniciales. Aquí, cada objeto tiene nombre y frecuencia al aire desde su creación. La [guía de constructores](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/constructors) presenta otras formas de inicializarlos.

`lowE.FrequencyAt(12)` llama a un **método de instancia**: utiliza el campo `_openHz` de ese objeto. `a.FrequencyAt(12)` utilizaría los 110 Hz de la cuerda la. Un método dentro de una clase puede leer sus campos y propiedades sin recibir el objeto completo como parámetro.

`sameString = lowE` **no** crea una tercera cuerda. Una variable de tipo clase contiene una referencia a un objeto: ahora ambas variables señalan el mismo objeto. Por eso, el cambio de nombre hecho mediante `sameString` se ve también mediante `lowE`. El objeto `a`, distinto, conserva su nombre. Esto contrasta con el parámetro `int` copiado en la lección 4; la lección 6 profundiza en los tipos por valor y por referencia.

## Campos, propiedades y acceso

El [campo](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/fields) privado `_openHz` guarda un valor dentro de cada objeto. `private` impide que el código externo a `GuitarString` use ese nombre. `readonly` permite que el constructor inicialice el campo, pero impide que los métodos le asignen otro valor después. La [propiedad](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/properties) pública `OpenHz` deja leer su valor sin exponer el campo para escritura.

`Name` es una **propiedad automática**. Su `get` es público, pero su `set` es privado. Quien utiliza la clase puede leer `lowE.Name`; debe llamar a `Rename` para cambiarlo. Así, la clase decide qué operaciones tienen sentido, en lugar de permitir que cualquiera modifique todos sus datos directamente. El modificador `sealed` indica que esta clase introductoria no se puede heredar; la herencia llega en la lección 7.

Intenta acceder al campo privado desde fuera. Este ejemplo mínimo, independiente del primero, da a `GuitarString` un constructor de un parámetro:

```csharp
GuitarString lowE = new GuitarString(82.41);
Console.WriteLine(lowE._openHz);
```

El fragmento rechazado `compile_fail/l05_private_field.cs` produce este diagnóstico real del compilador:

```text
l05_private_field.cs(2,24): error CS0122: 'GuitarString._openHz' is inaccessible due to its protection level
```

La asignación desde fuera a la propiedad que solo permite lectura también falla. El fragmento `compile_fail/l05_get_only_property.cs` contiene `lowE.OpenHz = 110.0;` y produce:

```text
l05_get_only_property.cs(2,1): error CS0200: Property or indexer 'GuitarString.OpenHz' cannot be assigned to -- it is read only
```

Estos errores ayudan a entender la interfaz de la clase: utiliza sus operaciones públicas o modifica su diseño de manera deliberada. No conviertas todos los campos en públicos solo para silenciar al compilador.

## Un miembro compartido por todos los objetos

`CreatedCount` lleva el [modificador `static`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/static). Pertenece a la clase `GuitarString`, no a una cuerda concreta. Cada llamada al constructor aumenta el mismo contador; el programa lo lee como `GuitarString.CreatedCount`, no como `lowE.CreatedCount`. En cambio, `_openHz`, `Name` y `FrequencyAt` pertenecen a cada objeto.

Este contador solo sirve como ejemplo didáctico: cuenta las construcciones, no los objetos que todavía existen en memoria.

## Ejercicio 1 — predecir las referencias

Sin ejecutar el programa, predice los valores de `lowE.Name`, `sameString.Name` y `a.Name` justo después de `sameString.Rename("E2 (retuned)")`. ¿Qué variables señalan el mismo objeto? Después ejecuta `examples/l05_objects.cs` para comprobarlo.

<details>
<summary>Solución</summary>

Tanto `lowE.Name` como `sameString.Name` valen `E2 (retuned)`: las dos variables señalan un solo objeto. `a.Name` sigue siendo `A2`: señala otro objeto. El programa muestra el primero y el tercero de esos valores en sus dos últimas líneas.

</details>

## Ejercicio 2 — una sesión de práctica

Crea una clase `PracticeSession` con un constructor que reciba un tema, una propiedad `Topic` de solo lectura, un campo privado para los minutos, un método `AddMinutes(int)` y un método `Summary()`. Crea dos sesiones; añade 20 y 15 minutos a la primera y 10 a la segunda. Muestra ambos resúmenes. La primera debe seguir indicando 35 minutos después de modificar la segunda. Por ahora, supón que los minutos no son negativos; la lección 8 explicará cómo rechazar entradas inválidas. La solución comprobada está en `exercises/l05_ex_practice.cs`.

<details>
<summary>Solución</summary>

```csharp
PracticeSession scales = new PracticeSession("Scales");
scales.AddMinutes(20);
scales.AddMinutes(15);

PracticeSession chords = new PracticeSession("Chords");
chords.AddMinutes(10);

Console.WriteLine(scales.Summary());
Console.WriteLine(chords.Summary());
Console.WriteLine(scales.Summary());

sealed class PracticeSession
{
    private int _minutes;

    public string Topic { get; }

    public PracticeSession(string topic)
    {
        Topic = topic;
    }

    public void AddMinutes(int minutes)
    {
        _minutes += minutes;
    }

    public string Summary() => $"{Topic}: {_minutes} min";
}
```

```text
Scales: 35 min
Chords: 10 min
Scales: 35 min
```

Los dos objetos tienen campos `_minutes` independientes. El constructor fija `Topic`, que el código externo ya no puede asignar directamente.

</details>

## Lo que debes recordar

- Una clase define un tipo; `new` crea un objeto de ese tipo.
- El constructor da su estado inicial a cada objeto nuevo.
- Un campo privado almacena datos internos; una propiedad o un método público ofrece un acceso elegido.
- Un miembro de instancia pertenece a un objeto; un miembro `static` pertenece al tipo.
- Asignar una variable de tipo clase a otra copia la referencia, no el objeto.

La siguiente lección, [records, estructuras y enumeraciones](../#plan), comparará las clases con tipos orientados a valores.
