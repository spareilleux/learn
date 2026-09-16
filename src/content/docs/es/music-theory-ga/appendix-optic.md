---
title: "Apéndice B: la jerarquía OPTIC"
description: De una digitación hasta una clase de conjuntos, una equivalencia cada vez —octava, permutación, cardinalidad, transposición, inversión—, con el tipo de Guitar Alchemist en cada peldaño, su esquema de embeddings OPTIC-K al lado y dos herramientas para subir la escalera a mano.
sidebar:
  label: "Apéndice B: la jerarquía OPTIC"
  order: 91
---

Las lecciones 1 a 4 suben una escalera sin nombrarla. La lección 1 convierte una posición del mástil en una altura, y una altura en una clase de altura. La lección 2 convierte un conjunto de clases de altura en una escala y compara escalas que son transposiciones unas de otras. La lección 4 identifica los conjuntos relacionados por transposición e inversión y llama al resultado una clase de conjuntos. Cada uno de esos pasos **olvida** algo a propósito, y el orden en que los olvidas es una jerarquía que la teoría musical tiene bautizada.

Callender, Quinn y Tymoczko llaman **OPTIC** a las cinco equivalencias, en ["Generalized Voice-Leading Spaces"](https://www.science.org/doi/10.1126/science.1153021) (*Science*, 2008):

| | equivalencia | dos cosas son la misma cuando solo se diferencian en… |
|---|---|---|
| **O** | octava | mover notas octavas enteras |
| **P** | permutación | el orden de las notas |
| **T** | transposición | mover todo el mismo intervalo |
| **I** | inversión | dar la vuelta a los intervalos |
| **C** | cardinalidad | doblar una nota que ya está |

Son independientes: puedes aplicar cualquier subconjunto de ellas, y cada subconjunto nombra un objeto musical distinto. «Acorde» suele ser OPC. «Tipo de escala» es OPTC. «Clase de conjuntos» es OPTIC, las cinco.

```bash
dotnet run --project code/music-theory-ga/GaTheory -c Release -- l10
```

## La subida

Empieza por abajo, con algo que puedes hacer de verdad con las manos: el acorde de C abierto, `x32010`.

```text
== One fingering, climbed rung by rung
rung                       the object                         what it forgets
a fingering                x32010                             nothing: strings, frets, muted strings
the pitches                C3 E3 G3 C4 E4                     which string each note was played on
- O, octave                0 4 7 0 4                          the octave of each note
- P, permutation           0 0 4 4 7                          the order of the notes
- C, cardinality           0 4 7                              doubled notes
- T, transposition         0 4 7                              which key it is in
- I, inversion             (037)                              major against minor
```

Lee la tercera columna de arriba abajo y tienes el apéndice entero. Una digitación lo sabe todo. Al llegar arriba, lo único que sobrevive es la forma `(037)`: una nota, una nota tres semitonos más arriba, una nota cuatro semitonos por encima de esa, en alguna tonalidad y en cualquiera de los dos sentidos.

Fíjate en lo que *no* está en la escalera. El primer paso, de `x32010` a `C3 E3 G3 C4 E4`, no es en absoluto una equivalencia OPTIC: es el instrumento. Dos digitaciones distintas que suenan como las mismas cinco alturas son la misma *música* y distinta *guitarra*. OPTIC no tiene nada que decir sobre esa diferencia, que es justamente por lo que un programa que trabaja con clases de conjuntos no puede decirte dónde poner los dedos.

## Qué tira cada peldaño

```text
== What each rung identifies
rung                       distinct objects     of the C major triad
fingerings, frets 0 to 4   63                   ways to play these three pitch classes
pitch multisets            5                    notes sounding in x32010
the pitch-class set        1                    0 4 7
- T: transposition class   1                    one of the 12 major triads
- I: set class             1                    one of the 24 major and minor triads
```

Sesenta y tres maneras de tocar esas tres clases de altura en los cinco primeros trastes, y los tres primeros peldaños de la escalera las aplastan todas en un solo objeto. Ese es el sentido de una equivalencia, y también su coste: todo lo que le importa a quien toca la guitarra vive por debajo del peldaño donde empieza la escalera.

```text
== How many objects there are at each rung
rung                           course   GA       check
pitch-class sets (P, O, C)     4096     4096     ok
transposition classes (+T)     352      352      ok
set classes (+I)               224      224      ok
cardinalities (+C)             13       13       ok
```

4096 subconjuntos de doce clases de altura; 352 de ellos salvo transposición; 224 salvo transposición e inversión. El `PitchClassSet`, el `TranspositionClass` y el `SetClass` de GA coinciden con el curso en los tres recuentos, que es la manera que tiene este apéndice de decir que la jerarquía está de verdad en el código.

## Dos acordes a la vez

```text
== The same climb for four chords
chord          pitch classes      transposition class / set class
C              0 4 7              0 4 7  /  (037)
A minor        0 4 9              0 3 7  /  (037)
G              2 7 E              0 4 7  /  (037)
F              0 5 9              0 4 7  /  (037)
C and G are different chords, the same transposition class, the same set class.
C and A minor are different transposition classes and the same set class: I joins them.
```

C y G son acordes distintos que se encuentran en el peldaño T. C y A menor son clases de transposición distintas que se encuentran en el peldaño I, que es la versión formal del hecho, visto en la lección 5, de que una tonalidad mayor y su relativa menor comparten un conjunto de notas. F y G son otras dos tríadas mayores: el mismo peldaño, el mismo objeto.

## El tipo de GA en cada peldaño

```text
== GA's types, one per rung
rung                       course                     GA                         check
- O, P, C: a set           id 145: 0 4 7              id 145: 0 4 7              ok
cardinality                3                          3                          ok
- I: prime form            (037)                      (037)                      ok
interval-class vector      <0 0 1 1 1 0>              <0 0 1 1 1 0>              ok
GA's SetClass for this set: SetClass[3 (Tritonic)-<0 0 1 1 1 0>/137]
its Forte number: 3-11
```

- **[`PitchClassSet`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSet.cs)** es el objeto que queda tras O, P y C: un id de 12 bits, sin octavas, sin orden, sin duplicados. El error de búsqueda de tonalidad de la lección 7 es una consecuencia directa: un `PitchClassSet` no puede saber qué nota es la tónica, porque «qué nota va primero» es precisamente lo que tiró P.
- **[`TranspositionClass`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/TranspositionClass.cs)** añade T: 352 elementos.
- **[`SetClass`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/SetClass.cs)** añade I: 224 elementos, cada uno con una forma prima, una cardinalidad y un vector interválico.
- **`Cardinality`** es C, conservada como propiedad y no como cociente.

Dos peldaños no tienen tipo, y las dos ausencias reaparecen en otros lugares de este curso. No hay ningún objeto entre una altura y una clase de altura —ninguna «altura con grafía» que sobreviva a un acorde—, que es el problema de grafía de la lección 3. Y no hay nada *por debajo* de `PitchClassSet` que conserve el orden de las notas, que es el de la lección 7.

## El esquema de embeddings OPTIC-K de GA

GA usa el mismo vocabulario para el aprendizaje automático. Su esquema de embeddings, documentado en [`.agent/skills/optic-k-schema-guardian/SKILL.md`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.agent/skills/optic-k-schema-guardian/SKILL.md) e implementado en `Common/GA.Business.ML/Embeddings/EmbeddingSchema.cs`, tiene **216 dimensiones** repartidas en particiones con nombre. Dos de ellas son esta escalera, partida por la mitad:

| Partición | Dimensiones | Peso | Finalidad, en palabras de GA |
|---|---|---|---|
| STRUCTURE | 6-29 | 0.45 | "Pitch-class set invariants (O+P+T+I). Core musical identity." |
| MORPHOLOGY | 30-53 | 0.25 | "Physical fretboard realization (geometry/fingering)." |

STRUCTURE es la **cima** de la escalera: las cuatro equivalencias y el objeto que sobrevive a ellas, con el peso más alto porque dos voicings de una misma clase de conjuntos son de verdad la misma armonía. MORPHOLOGY es todo lo que la escalera **descartó** por el camino: qué cuerda, qué traste, qué dedo; el paso de `x32010` a `C3 E3 G3 C4 E4` que OPTIC no modela.

Ese reparto es el acertado, y vale la pena decir por qué. Una búsqueda que usara solo STRUCTURE devolvería la tríada de C mayor tocada en cualquier parte, incluidos sitios a los que no llega ninguna mano. Una búsqueda que usara solo MORPHOLOGY devolvería formas que se parecen y suenan sin relación. Las dos particiones son las dos mitades de este apéndice, con sus pesos.

*Por verificar*: los rangos de dimensiones y los pesos anteriores están leídos en el documento de la skill en el commit fijado, cuyo front matter llama al esquema v1.4; el programa del curso no compila `GA.Business.ML`, así que nada de esto está comprobado ejecutándolo, al contrario que las tablas anteriores.

## Subir la escalera a mano

Dos sitios permiten recorrer con el ratón cada peldaño de este apéndice, y los dos valen una tarde.

El **[buscador de escalas de Ian Ring](https://ianring.com/musictheory/scales/finder/)** es un brazalete de doce cuentas, exactamente el diagrama de la lección 2. Haz clic en las cuentas para construir un conjunto; la página lo nombra y enlaza a su ficha. Sus tres botones son tres peldaños de la escalera:

- **Rotate up** y **Rotate down** aplican **T**, un semitono cada vez. Rota doce veces y vuelves al punto de partida: esa órbita es la clase de transposición.
- **Reflect** aplica **I**. Si al reflejar obtienes el conjunto que ya tenías, el conjunto es simétrico por inversión y su clase de conjuntos contiene 12 conjuntos en lugar de 24; la colección diatónica, la escala de tonos enteros y la escala octatónica se comportan todas así, que es la sección sobre simetría de la lección 2.
- El número de la escala es el id de 12 bits de la lección 2, y [la página de cada escala](https://ianring.com/musictheory/scales/2477) da sus modos, su vector interválico y si tiene pareja en relación Z, que es la lección 4.

Es la manera más rápida de comprobar una afirmación de este curso: los recuentos de la lección 2 y los vectores de la lección 4 se pueden confirmar conjunto a conjunto en las páginas de Ring, y así se confirmaron varios de ellos.

**[Harmonious](https://harmoniousapp.net/)** aborda el mismo material desde el otro extremo. Se presenta como "a map of all chromatic-cluster-free hexatonic, heptatonic, and octotonic scales and modes and their compatible chords (Levine 1995) in twelve-tone equal temperament", y está organizado por armadura y por acorde en lugar de por número de conjunto. Donde Ring te da el *cociente* —una página por escala, con las transposiciones colapsadas—, Harmonious te da la *fibra*: esta tonalidad, estos acordes, estas sustituciones. Entre los dos son las dos direcciones de este apéndice, y ninguno sustituye al otro:

| | Ian Ring | Harmonious |
|---|---|---|
| Unidad | una clase de conjuntos, sin tonalidad | una tonalidad y sus acordes |
| Peldaños que muestra | T e I, como botones | por debajo de la escalera: voicings y pares acorde–escala |
| Va mejor para | comprobar un recuento o un vector | encontrar una sustitución que puedas tocar |
| Relación con GA | la misma numeración de 12 bits | la misma idea de acorde–escala que las lecciones 6 y 7 |

GA se sitúa entre los dos: `SetClass` es el objeto de Ring, `Voicing` y `Fretboard` están más cerca de los de Harmonious, y el esquema OPTIC-K anterior es un intento deliberado de sostener ambos en un solo vector.

## Qué recordar

- OPTIC son cinco cosas independientes que olvidar, no una sola operación. Decir cuáles has aplicado te dice qué puede responder tu tipo y qué no.
- Cada uno de los defectos 8, 9, 12 y 19 del apéndice C es un peldaño que se sube y luego una pregunta que necesitaba la información descartada: una grafía después de O, una tónica después de P, un recuento después de C.
- El instrumento está *por debajo* del peldaño más bajo. OPTIC no dice nada sobre la digitación, que es la razón de que GA necesite una segunda partición para ella.

## Fuentes

- Clifton Callender, Ian Quinn y Dmitri Tymoczko, ["Generalized Voice-Leading Spaces"](https://www.science.org/doi/10.1126/science.1153021), *Science* 320 (2008), el artículo que da nombre a OPTIC.
- Dmitri Tymoczko, [*A Geometry of Music*](https://dmitri.mycpanel.princeton.edu/geometry-of-music.html) (Oxford, 2011), capítulos 2 y 3.
- Ian Ring, [*A Study of Musical Scales*](https://ianring.com/musictheory/scales/) y su [buscador de escalas](https://ianring.com/musictheory/scales/finder/).
- [Harmonious](https://harmoniousapp.net/), y Mark Levine, *The Jazz Theory Book* (1995), que cita para sus pares acorde–escala.
- GuitarAlchemist/ga en [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Common/GA.Domain.Core/Theory/Atonal` y [`.agent/skills/optic-k-schema-guardian/SKILL.md`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.agent/skills/optic-k-schema-guardian/SKILL.md).
- El programa del curso: [`Lesson10.cs`](https://github.com/spareilleux/learn/blob/main/code/music-theory-ga/GaTheory/Lesson10.cs), [`expected/l10.txt`](https://github.com/spareilleux/learn/blob/main/code/music-theory-ga/expected/l10.txt).
