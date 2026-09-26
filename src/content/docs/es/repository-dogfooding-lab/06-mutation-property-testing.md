---
title: "6. Pruebas de mutación y de propiedades sobre un parser real"
description: Un laboratorio acotado y prerregistrado sobre el parser de alturas de GA. Stryker.NET mide qué fallos detectan las pruebas; propiedades de FsCheck comprueban el contrato público; un control negativo demuestra que el banco puede fallar.
sidebar:
  order: 6
---

:::caution[Alcance de la evidencia]
Un solo archivo de un solo repositorio, en un solo commit fijado: [`PitchParser.cs`](https://github.com/GuitarAlchemist/ga/blob/aa22f9101d5bb86800ff2819381f97986fc81fb1/Common/GA.Domain.Core/Primitives/Notes/PitchParser.cs) en GuitarAlchemist/ga en `aa22f91`. Medido solo en Windows 11; Linux y macOS están *por verificar*. Nada de esto dice algo sobre la calidad de las pruebas de GA en su conjunto.
:::

Una suite de pruebas en verde dice que las pruebas escritas pasan. No dice si notarían un error. Dos técnicas plantean esa segunda pregunta desde lados opuestos:

- Las **pruebas de mutación** cambian el código de producción en pequeños detalles (un `<` por `<=`, un `true` por `false`) y vuelven a ejecutar las pruebas. Un cambio que las pruebas notan queda *eliminado* (*killed*); uno que se les escapa *sobrevive*. [Stryker.NET](https://stryker-mutator.io/docs/stryker-net/introduction/) hace esto para .NET.
- Las **pruebas de propiedades** enuncian una regla que debe cumplirse para toda entrada y dejan que un generador busque un contraejemplo. [FsCheck](https://fscheck.github.io/FsCheck/) genera las entradas y, cuando una falla, la *reduce* (*shrinking*) a un caso mínimo.

Esta lección aplica ambas a una función real, con las hipótesis escritas antes de cualquier medición.

## La costura

`PitchParser` es una clase `internal` de `GA.Domain.Core`. Convierte un texto como `C#4` o `Bb3` en una altura. Sus únicos llamadores son los métodos públicos [`Pitch.Sharp.TryParse`](https://github.com/GuitarAlchemist/ga/blob/aa22f9101d5bb86800ff2819381f97986fc81fb1/Common/GA.Domain.Core/Primitives/Notes/Pitch.cs#L114) y [`Pitch.Flat.TryParse`](https://github.com/GuitarAlchemist/ga/blob/aa22f9101d5bb86800ff2819381f97986fc81fb1/Common/GA.Domain.Core/Primitives/Notes/Pitch.cs#L285). El laboratorio solo prueba esos dos puntos de entrada públicos: sin `InternalsVisibleTo`, sin reflexión y sin ningún cambio en GA.

El núcleo del parser es una expresión regular anclada por tipo de alteración:

```csharp
// PitchParser.cs:7-8 en aa22f91
new(@"\A([A-G])(#?)(-1|[0-9])\z", PcreOptions.Compiled | PcreOptions.IgnoreCase);  // sostenido
new(@"\A([A-G])(b?)(-1|[0-9])\z", PcreOptions.Compiled | PcreOptions.IgnoreCase);  // bemol
```

Tras una coincidencia, el código vuelve a comprobar que cada grupo está definido y analiza cada parte, y devuelve `false` ante cualquier fallo (líneas 36 a 68).

## Prerregistrar antes de medir

El [prerregistro](https://github.com/spareilleux/learn/blob/main/code/repository-dogfooding-lab/test-quality/results/preregistration.md) se escribió y se calculó su hash antes de la primera compilación. Su SHA-256 quedó anotado en un archivo aparte. Fija:

- **B (línea base):** Stryker con el proyecto de pruebas propio de GA, mutando solo `PitchParser.cs`.
- **T (tratamiento):** el mismo comando, añadiendo el proyecto de propiedades del laboratorio.
- **Detección:** solo cuenta *Killed*. Los tiempos agotados se informarían aparte, nunca como mutantes eliminados.
- **H1:** B deja al menos un mutante Survived o NoCoverage; los candidatos probables son las comprobaciones defensivas que la regex ya garantiza.
- **H2:** T elimina al menos un mutante que B dejó vivo, afirmando solo lo que las pruebas de GA ya afirman.
- **H3:** ninguna entrada (null, vacía, espacios, Unicode arbitrario) hace lanzar una excepción a ninguno de los dos `TryParse`, en 10 000 casos por propiedad.
- **Control negativo:** una propiedad deliberadamente falsa, que debe fallar, reducirse y reproducirse desde su semilla.
- **Presupuesto:** un archivo, concurrencia 2, 10 minutos por ejecución, sin compilar la solución completa.

Una corrección hecha después del hash no se oculta: va en una sección *Post-measurement edits*, con cuándo y por qué. Este laboratorio tiene tres, entre ellas un error del generador detectado antes de cualquier ejecución: anteponer `b` a `b3` da `bb3`, un bemol válido, así que una entrada «malformada» no lo era.

## Las propiedades

Las alturas válidas se construyen a partir de enteros pequeños y booleanos, que FsCheck sabe reducir. El texto se deriva dentro de la propiedad:

```csharp
private static Spelling FromParts(Kind kind, byte letter, bool accidental, bool lowerCase, byte octave)
{
    var upper = "ABCDEFG"[letter % 7];
    var octaveValue = octave % 11 - 1;
    var acc = accidental ? Accidental(kind) : "";
    var text = $"{(lowerCase ? char.ToLowerInvariant(upper) : upper)}{acc}{octaveValue}";
    return new Spelling(kind, text, $"{upper}{acc}{octaveValue}");
}
```

El [archivo de pruebas](https://github.com/spareilleux/learn/blob/main/code/repository-dogfooding-lab/test-quality/PitchParserProperties/PitchParserPropertyTests.cs) contiene cinco propiedades y una prueba por ejemplo:

| Prueba | Oráculo |
|---|---|
| Sostenido válido / bemol válido | `TryParse` devuelve verdadero y `ToString()` imprime la forma canónica (`c#4` → `C#4`) |
| Sostenido malformado / bemol malformado | Un cambio de una lista cerrada (letra de más, espacio, dígito, octava fuera de rango, la otra alteración, una alteración doble, sin octava) hace que `TryParse` devuelva falso |
| Cadena cualquiera | Ninguna excepción; un texto aceptado se vuelve a analizar como el mismo texto |
| Null, vacía, espacios | Rechazados sin excepción |

## Ejecutarlo

Desde `code/repository-dogfooding-lab/test-quality/`, en un shell POSIX (Git Bash en Windows):

```bash
bash fetch-ga.sh                                    # extracción parcial de GA en aa22f91 dentro de .ga/ (12 MB)
dotnet tool restore                                 # dotnet-stryker 5.0.0 desde dotnet-tools.json
dotnet test PitchParserProperties -c Release --filter "TestCategory!=NegativeControl"
dotnet test PitchParserProperties -c Release --filter "TestCategory=NegativeControl"   # debe fallar
dotnet tool run dotnet-stryker -f stryker-config.baseline.json -O out/stryker-B        # B
dotnet tool run dotnet-stryker -f stryker-config.json -O out/stryker-T                 # T
```

## Qué se midió (2026-09-26, Windows 11, SDK de .NET 10.0.112)

| Ejecución | Pruebas | Killed | Survived | NoCoverage | Ignored | Timeout | Puntuación | Duración |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| B — pruebas de GA | 706 | 25 | 0 | 5 | 9 | 0 | 83,33 % | 109 s |
| T — GA + propiedades | 710 en el informe | 25 | 0 | 5 | 9 | 0 | 83,33 % | 142 s |
| P — solo propiedades (exploratoria) | 6 | 25 | 0 | 5 | 9 | 0 | 83,33 % | 93 s |

Stryker genera 39 mutantes en el archivo. La puntuación es Killed dividido entre Killed + Survived + NoCoverage, es decir 25/30. Los 9 mutantes *Ignored* están en bloques que Stryker ya había mutado por completo.

- **H1 confirmada.** B deja 5 mutantes sin cobertura: `return false` cambiado a `return true` en las líneas 38, 43, 49, 58 y 67. Los cinco están en las ramas defensivas que siguen a una coincidencia correcta de la regex.
- **H2 refutada.** T elimina exactamente los mismos 25 mutantes. Los mismos 5 siguen sin cobertura, porque ninguna entrada descrita por el contrato público los alcanza.
- **H3 se cumple para esta semilla.** 10 000 casos por propiedad, y ninguna excepción.
- **Control negativo:** `Falsifiable, after 2 tests (2 shrinks)`, reducido a `a#-1` (el parser de sostenidos lo acepta, el de bemoles no), y una salida idéntica en una segunda ejecución desde la semilla `(20260926,7)`.

La ejecución **P** no estaba en el prerregistro. Se declaró en la sección posterior a la medición después de T y antes de lanzarla, y se informa como exploratoria. Responde a una pregunta que T no podía zanjar: ¿detectan las seis pruebas de propiedades *por sí solas* lo que detectan las 706 pruebas de GA en este archivo? Sí: los mismos 25 mutantes eliminados. La mayoría de los primeros «eliminadores» son las dos propiedades «válidas», 20 cada una.

## Leer el resultado con honestidad

Tres conclusiones son defendibles:

1. Las pruebas existentes de GA ya eliminan todo mutante de este archivo alcanzable desde fuera.
2. Los cinco mutantes sin cobertura son probablemente **inalcanzables** desde la API pública: la regex rechaza las entradas que harían ejecutar esas ramas. Para la línea 58, `FlatAccidental.TryParse` pasa su entrada a minúsculas ([FlatAccidental.cs:96](https://github.com/GuitarAlchemist/ga/blob/aa22f9101d5bb86800ff2819381f97986fc81fb1/Common/GA.Domain.Core/Primitives/Notes/FlatAccidental.cs#L96)), así que ni siquiera `CB4` debería alcanzarla. Es una lectura del código, no una ejecución: *por verificar*. El código inalcanzable es una observación de diseño, no un hueco de pruebas. Ninguna prueba puede eliminar un mutante equivalente.
3. Un puñado de propiedades igualó a una gran suite de ejemplos en este único archivo. Eso no dice nada de otros archivos. Aquí el contrato es pequeño y la regex hace casi todo el trabajo.

Una afirmación no es defendible: que las pruebas de propiedades «mejoraron las pruebas de GA». Aquí no lo hicieron, y la tabla lo muestra.

## Lo que esto **no** establece

- Nada sobre ningún otro archivo de GA, ni sobre la puntuación de mutación global de GA. Stryker creó 4781 mutantes en el proyecto, de los cuales 4439 quedaron ignorados por el filtro de mutación.
- No se cambió código de producción ni se abrió ninguna issue en GA. Mantener o no las ramas defensivas es decisión del mantenedor.
- Stryker también señaló 303 mutantes con error de compilación en otras partes del proyecto, fuera del filtro. No afectan a las cifras de este archivo.
- Las 710 pruebas del informe de T no están conciliadas con 706 + 6: *por verificar*.
- No ha habido ejecución en CI ni en Linux o macOS.

## Ejercicios

1. Haz que el control negativo pase corrigiendo su afirmación, no el parser. ¿Cuál es la afirmación verdadera más pequeña sobre el análisis de sostenidos y bemoles que puedes escribir como propiedad?
2. Añade un cambio malformado a la lista cerrada: una letra fuera de `A–G` en lugar de la nota, como `H4`. Ejecuta las propiedades «malformadas». ¿Cambia la puntuación? Explica por qué.
3. Quita la restricción sobre los prefijos (permite una `b` o cualquier letra de nota) y ejecuta la propiedad de bemol malformado. ¿Qué informa FsCheck y qué te enseña sobre los generadores?
4. Encuentra una entrada escrita a mano que alcance la línea 58 a través de `Pitch.Flat.TryParse`, o argumenta a partir del código que no existe ninguna.

<details>
<summary>Soluciones</summary>

1. Por ejemplo: «un texto que aceptan ambos parsers no contiene ninguna alteración». Ambas regex aceptan una altura natural, y solo una acepta cada alteración. Escríbela con `Prop.ForAll(Parts, …)` y sácala de la categoría `NegativeControl` cuando sea verdadera.
2. La puntuación no cambia. La regex ya rechaza `H`, así que el nuevo cambio ejercita un camino que las propiedades válidas ya eliminan: la rama `!match.Success` de la línea 28. Un cambio nuevo solo ayuda si alcanza una rama que ninguna prueba alcanza todavía.
3. FsCheck informa un caso falsado como `bb3` o `Ab3` para el parser de bemoles, que son bemoles válidos. El que estaba mal era el generador, no el parser. Es exactamente el defecto detectado aquí antes de la primera ejecución. Los generadores también son código, y una propiedad vale lo que vale el dominio que muestrea.
4. La regex deja pasar `b` o `B` como grupo bemol. `FlatAccidental.TryParse` pasa su entrada a minúsculas y acepta `b`, así que nunca devuelve falso para lo que la regex deja pasar. Ninguna entrada alcanza la línea 58, y el mutante que hay allí es equivalente. Compruébalo ejecutando `Pitch.Flat.TryParse("CB4", null, out var p)`: debería devolver verdadero e imprimir `Cb4`. Este laboratorio no ha ejecutado esa comprobación.

</details>

## Fuentes

- [Documentación de Stryker.NET](https://stryker-mutator.io/docs/stryker-net/introduction/), y su [referencia de configuración](https://stryker-mutator.io/docs/stryker-net/configuration/).
- [Documentación de FsCheck](https://fscheck.github.io/FsCheck/), la [guía de propiedades](https://fscheck.github.io/FsCheck/Properties.html), y [NUnit](https://docs.nunit.org/) como ejecutor de pruebas.
- Código del laboratorio y resultados en bruto: [`code/repository-dogfooding-lab/test-quality`](https://github.com/spareilleux/learn/tree/main/code/repository-dogfooding-lab/test-quality). El [diario](../journal/) contiene la entrada fechada.
