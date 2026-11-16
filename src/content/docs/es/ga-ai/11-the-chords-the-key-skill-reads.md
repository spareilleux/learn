---
title: "Lección 11: Los acordes que lee la skill de tonalidad"
description: "La skill de tonalidad de Guitar Alchemist saca los cifrados de acorde de la pregunta con una sola expresión regular, puntúa las 30 tonalidades y le pasa al modelo las que empatan en cabeza. El curso pregunta la tonalidad de seis progresiones de manual en las 30 tonalidades, con el servicio del commit fijado y con el del main de GA: el commit fijado no lee ningún acorde de séptima, los dos leen F♯ como F, main responde C♯ mayor para D♭ G♭ A♭ D♭, y C D G C sale en G mayor."
sidebar:
  label: 11. Los acordes que lee la skill de tonalidad
  order: 11
---

La [lección 10](../10-what-the-model-is-told-to-trust/) llamó a la herramienta en la que se le dice a un modelo que confíe. La skill de tonalidad va más allá: la respuesta se calcula antes de que el modelo vea la pregunta. [`KeyIdentificationSkill`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/KeyIdentificationSkill.cs) puntúa las tonalidades y después le pide al modelo que explique el resultado, con la instrucción "Use ONLY the data below — do not guess or add your own analysis" (usa SOLO los datos de abajo: no adivines ni añadas tu propio análisis) ([línea 97](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/KeyIdentificationSkill.cs#L97)). La otra superficie para "what key is …" (¿en qué tonalidad está…?), el [SKILL.md de key-identification](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/key-identification/SKILL.md), le dice al modelo que llame a la herramienta `ga_key_identify` y que no analice él mismo la progresión. Las dos siguen los mismos pasos. El `ExtractChords` de [`KeyIdentificationService`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/KeyIdentificationService.cs) saca los cifrados de acorde de la pregunta, y su `Identify` puntúa las 30 tonalidades mayores y menores; después, la herramienta, igual que la skill, conserva como coincidencias principales las tonalidades cuyo recuento es igual al de la primera, seguidas de hasta tres coincidencias parciales. Lo que producen estos pasos es lo que se le dice al modelo que diga, y el programa los ejecuta sin modelo.

Todos los enlaces a GA apuntan al commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), el commit fijado del curso, salvo los que nombran otro. La detección de la tonalidad ha cambiado desde entonces en el `main` de GA. La [#625](https://github.com/GuitarAlchemist/ga/pull/625), fusionada el 2026-09-24, trasladó el servicio a `GA.Domain.Services`, amplió su expresión regular a los acordes de séptima, empezó a contar las séptimas de dominante y añadió un peso para la cadencia final. La [#729](https://github.com/GuitarAlchemist/ga/pull/729), commit [`6baf32e`](https://github.com/GuitarAlchemist/ga/commit/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40), cambió la forma de deshacer los empates, después de que la [lección 7 del curso de teoría musical](../../music-theory-ga/07-cadences-and-progressions/) pusiera a prueba las herramientas del servidor MCP de GA. Esas herramientas reciben solo los acordes; esta lección hace la pregunta del chatbot, una frase de la que hay que sacar los acordes. En `main`, en [`5c3a52a`](https://github.com/GuitarAlchemist/ga/commit/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26) (2026-09-30), el servicio sigue como lo dejó `6baf32e`, el SKILL.md no ha cambiado, y la herramienta y la skill solo difieren del commit fijado en una línea `using` y, en la skill, en un indicador que marca un rechazo. `fetch-ga.sh` descarga el servicio en `6baf32e`, y el proyecto [`GaKeysMain`](https://github.com/spareilleux/learn/blob/main/code/ga-ai/GaKeysMain/GaKeysMain.csproj) lo compila contra el dominio fijado, cuyos `Key.Items` y `Key.Notes` no han cambiado en `main`. Las salidas proceden de:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l11
```

## Lo que recibe el modelo

La herramienta conserva las tonalidades cuyo recuento es igual al de la primera, y después las tres siguientes ([`KeyIdentificationMcpTools.cs` líneas 66-75](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Mcp/KeyIdentificationMcpTools.cs#L66-L75)):

```csharp
        var topScore = candidates[0].MatchCount;
        var topTied  = candidates
            .Where(c => c.MatchCount == topScore)
            .Select(ToCandidate)
            .ToArray();
        var partial  = candidates
            .Skip(topTied.Length)
            .Take(MaxPartialCandidates)
            .Select(ToCandidate)
            .ToArray();
```

`KeyIdentificationSkill` construye la misma lista de cabeza ([líneas 62-63](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/KeyIdentificationSkill.cs#L62-L63)) y la imprime en el prompt del modelo bajo "TOP MATCHES (all tied at the highest score)" (mejores coincidencias, todas empatadas en la puntuación más alta), seguida de las tres tonalidades siguientes bajo "PARTIAL MATCHES" (coincidencias parciales) ([líneas 100-114](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/KeyIdentificationSkill.cs#L100-L114)). [`Lesson11.cs`](https://github.com/spareilleux/learn/blob/main/code/ga-ai/GaAi/Lesson11.cs) llama a `ExtractChords` y a `Identify` de las dos versiones y aplica estas líneas a sus resultados. Para la versión fijada, llama además a la propia herramienta `ga_key_identify`, `KeyIdentificationMcpTools.IdentifyKey`, y se detiene si la herramienta lee otros acordes o devuelve otras tonalidades:

```text
== The pinned answers, checked against ga_key_identify
99 questions: KeyIdentificationMcpTools.IdentifyKey read the same chords and returned the same keys
```

El lado del manual es breve. Una progresión construida sobre la escala de una tonalidad está en esa tonalidad. Una tonalidad y su relativa comparten las siete tríadas, así que las tríadas solas no permiten distinguir C mayor de A menor; el primer acorde y el final, sí. El curso mira la primera tonalidad de las coincidencias principales y si la tonalidad del manual está entre ellas.

## Los ejemplos de la propia skill

Los siete prompts de ejemplo de `KeyIdentificationSkill`, y las progresiones de los dos ejemplos del SKILL.md:

```text
== The key skill's example prompts: the chords read, and the keys tied at the top
"What key is C Am F G in?"
  a826864  reads C Am F G       4/4: A minor, C major
  6baf32e  reads C Am F G       4/4: C major, A minor
"Identify the key of Dm G C"
  a826864  reads Dm G C         3/3: A minor, C major
  6baf32e  reads Dm G C         3/3: C major, A minor
"What key does Am F G E sound like?"
  a826864  reads Am F G E       3/4: A minor, C major
  6baf32e  reads Am F G E       3/4: A minor, C major
"Tell me the key of these chords: G D Em C"
  a826864  reads G D Em C       4/4: E minor, G major
  6baf32e  reads G D Em C       4/4: G major, E minor
"Find the tonic of A E F#m D"
  a826864  reads A E F#m D      4/4: A major, F# minor
  6baf32e  reads A E F#m D      4/4: A major, F# minor
"What's the tonic of these chords: C F G C"
  a826864  reads C F G          3/3: A minor, C major
  6baf32e  reads C F G          3/3: C major, A minor
"Identify the tonic of this progression: D A Bm G"
  a826864  reads D A Bm G       4/4: B minor, D major
  6baf32e  reads D A Bm G       4/4: D major, B minor
"Dm G C"
  a826864  reads Dm G C         3/3: A minor, C major
  6baf32e  reads Dm G C         3/3: C major, A minor
"C Am F G"
  a826864  reads C Am F G       4/4: A minor, C major
  6baf32e  reads C Am F G       4/4: C major, A minor
```

En el commit fijado, cada ejemplo empata una tonalidad con su relativa, y el empate se ordena por nombre ([línea 178](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/KeyIdentificationService.cs#L178)): A menor va antes que C mayor, E menor antes que G mayor, B menor antes que D mayor. El primer ejemplo del SKILL.md dice "The progression `Dm G C` is in **C major** (3/3 chords diatonic)" (la progresión está en C mayor, con todos sus acordes diatónicos) ([línea 60](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/key-identification/SKILL.md#L60)); la herramienta devuelve C mayor y A menor, y, cuando hay más de un candidato en cabeza, el SKILL.md le dice al modelo que nombre los dos ([línea 64](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/key-identification/SKILL.md#L64)). En `main`, C mayor va primero porque Dm G C termina con G C, un V–I de C mayor, y el peso de cadencia suma 2; A menor sigue entre las coincidencias principales, porque la herramienta agrupa las tonalidades por recuento y el de A menor también es 3. En los demás ejemplos, `main` resuelve un empate a favor de la tonalidad cuya tríada de tónica abre la progresión, y después a favor de la tonalidad mayor. En "Am F G E", ninguna de las dos versiones cuenta el E en A menor: el servicio compara con las tríadas de la menor natural ([líneas 40-45](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/KeyIdentificationService.cs#L40-L45)), cuya tríada sobre el quinto grado es E menor.

## Leer los acordes

El programa pone cada símbolo en "What key is X in?" (¿en qué tonalidad está X?) e imprime lo que devuelve `ExtractChords`. Detrás de la lectura de cada versión, una columna da la cualidad que el parser privado del servicio asigna a cada acorde leído; el programa llama al parser por reflexión.

```text
== What each version reads in "What key is X in?", and what each chord counts as
X        a826864 reads  counts as      6baf32e reads  counts as
C        C              major          C              major
Cm       Cm             minor          Cm             minor
Cdim     Cdim           diminished     Cdim           diminished
Caug     Caug           major          Caug           major
C+       C              major          C              major
C°       C              major          C              major
Cmin     nothing        -              Cmin           minor
C#       C              major          C              major
C#m      C#m            minor          C#m            minor
Db       Db             major          Db             major
F#       F              major          F              major
F#7      F#             major          F#7            dominant
B♭       B              major          B              major
F♯       F              major          F              major
C7       nothing        -              C7             dominant
Cm7      nothing        -              Cm7            minor
Cmaj7    nothing        -              Cmaj7          major
CM7      nothing        -              nothing        -
CΔ7      nothing        -              nothing        -
Cm7b5    nothing        -              Cm7b5          minor
Cø7      nothing        -              nothing        -
Cdim7    nothing        -              Cdim7          diminished
C6       nothing        -              C6             major
C9       nothing        -              C9             major
Csus4    nothing        -              Csus4          major
Cadd9    nothing        -              Cadd9          major
C7#9     nothing        -              C7#9           dominant
C/E      C E            major major    C E            major major
```

En el commit fijado, la expresión regular es esta ([línea 211](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/KeyIdentificationService.cs#L211)):

```csharp
    [GeneratedRegex(@"\b[A-G][b#]?(m|dim|aug|maj)?\b", RegexOptions.None)]
    private static partial Regex ChordPattern();
```

`\b` coincide entre un carácter de palabra (una letra, una cifra o `_`) y cualquier otro. En `Am7`, `m` y `7` son los dos caracteres de palabra, así que el `\b` final falla detrás de la `m`; sin la `m`, falla detrás de la `A`, y el acorde se salta. Todos los símbolos con una cifra justo detrás de una letra se saltan de la misma manera: `C7`, `Cm7`, `Cmaj7`, `Cm7b5`, `C6`. Y también los que llevan una cualidad que el grupo no enumera, `sus` en `Csus4` o `add` en `Cadd9`, con cifra o sin ella. El SKILL.md dice que la herramienta "doesn't distinguish a `Cmaj7` from a `C` for the purposes of key fitting" (no los distingue a la hora de encajar la tonalidad) ([línea 81](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/key-identification/SKILL.md#L81)); en el commit fijado, ni siquiera lee `Cmaj7`. En `F#` seguido de un espacio, ni el `#` ni el espacio son caracteres de palabra, así que el `\b` final falla detrás del `#`; la expresión devuelve el `#` y encuentra `F`. `F#m` conserva su sostenido porque `m` es una letra; `F#7` lo conserva porque `7` es una cifra, y pierde el `7`, porque la expresión se detiene en el sostenido. Es la causa de la [#757](https://github.com/GuitarAlchemist/ga/issues/757) en la skill de improvisación y de la [#767](https://github.com/GuitarAlchemist/ga/issues/767) en la de intervalos, aquí en una tercera expresión. `B♭` y `F♯` usan los signos musicales, que `[b#]` no incluye. `C°` se lee como `C` y cuenta como una tríada mayor. `C/E` se convierte en dos acordes.

En `main`, `Cm7b5` se lee y cuenta como menor: el parser borra todo a partir de la primera cifra ([líneas 316-321](https://github.com/GuitarAlchemist/ga/blob/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40/Common/GA.Domain.Services/Tonal/KeyIdentificationService.cs#L316-L321)), y queda `Cm`. La tríada de un acorde de séptima semidisminuida es disminuida. El parser del commit fijado hace lo mismo ([líneas 205-209](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/KeyIdentificationService.cs#L205-L209)), pero su expresión nunca le pasa el símbolo.

En `main`, la expresión admite cifras y alteraciones detrás de la cualidad ([línea 325](https://github.com/GuitarAlchemist/ga/blob/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40/Common/GA.Domain.Services/Tonal/KeyIdentificationService.cs#L325)):

```csharp
    [GeneratedRegex(@"\b[A-G][b#]?(?:maj|Maj|min|m|dim|aug|sus|add)?\d*(?:b5|#5|b9|#9|#11|b13)?\b", RegexOptions.None)]
    private static partial Regex ChordPattern();
```

Los acordes de séptima se leen. `C7` y `C7#9` cuentan como dominantes, que `Identify` acepta sobre el quinto grado de una tonalidad mayor o sobre el séptimo de una menor. El `\b` final sigue ahí: `C#` y `F#` siguen volviendo como `C` y `F`, y `CM7`, `CΔ7` y `Cø7` se siguen saltando.

## Seis progresiones en treinta tonalidades

El programa construye seis progresiones sobre la escala de cada tonalidad que tiene como mucho siete sostenidos o bemoles, las escribe como las escribe el manual y pregunta "What key is … in?". Tres están en las 15 tonalidades mayores: I IV V I; I II V I, donde II es una tríada mayor, la dominante de la dominante (C D G C); y ii7 V7 Imaj7 (Dm7 G7 Cmaj7). Tres están en las 15 tonalidades menores: i iv V i, con el V mayor de la menor armónica (Am Dm E Am); iiø7 V7 i (Bm7b5 E7 Am); y i VI III VII (Am F C G).

```text
== "What key is ... in?" for six textbook progressions in the 30 keys

major keys             Cb Gb Db Ab Eb Bb F  C  G  D  A  E  B  F# C#
I IV V I      a826864  ~  ~  ~  =  ~  =  ~  ~  ~  ~  =  ~  r  r  r
I IV V I      6baf32e  ~  ~  ~  =  =  =  =  =  =  =  =  =  r  r  r
I II V I      a826864  x  x  x  x  x  x  x  x  x  x  x  r  r  r  r
I II V I      6baf32e  x  x  x  x  x  x  x  x  x  x  x  r  r  r  r
ii7 V7 Imaj7  a826864  r  r  r  r  r  r  r  r  r  r  r  r  r  r  r
ii7 V7 Imaj7  6baf32e  ~  ~  ~  =  =  =  =  =  =  =  =  =  =  =  =

minor keys             Ab Eb Bb F  C  G  D  A  E  B  F# C# G# D# A#
i iv V i      a826864  =  ~  ~  ~  ~  ~  ~  =  ~  r  r  r  r  r  r
i iv V i      6baf32e  =  ~  ~  =  =  =  =  =  =  r  r  r  r  r  r
iiø7 V7 i     a826864  r  r  r  r  r  r  r  r  r  r  r  r  r  r  r
iiø7 V7 i     6baf32e  =  ~  ~  =  =  =  =  =  =  =  =  =  ~  =  =
i VI III VII  a826864  =  ~  ~  ~  =  ~  =  =  =  =  ~  =  r  r  r
i VI III VII  6baf32e  =  ~  ~  =  =  =  =  =  =  =  =  =  r  r  r

= every chord read as written, the textbook key first; ~ read, the key tied at the top but not first;
x read, the key not among the top; r a chord dropped or read as another chord
a826864: 90 questions, = 12, ~ 21, x 11, r 46; a key after the top with a higher count: 0
6baf32e: 90 questions, = 50, ~ 13, x 11, r 16; a key after the top with a higher count: 2
```

En el commit fijado, las 30 preguntas con acordes de séptima pierden todos sus acordes de séptima: lo que queda es el i de iiø7 V7 i y, cuando la fundamental lleva sostenido, la fundamental sola, `F#` para `F#m7`. Otras 16 pierden un sostenido: todas las preguntas con una tríada mayor sobre F♯, C♯, G♯, D♯, A♯ o E♯. De las 44 preguntas leídas tal como están escritas, 12 reciben primero la tonalidad del manual, 21 la reciben entre las tonalidades empatadas en cabeza, ordenada detrás de otra por nombre, y 11 no la reciben en absoluto.

En `main`, 50 preguntas reciben primero la tonalidad del manual. Las 16 con una tríada mayor sobre una nota con sostenido siguen perdiendo el sostenido. Las 13 casillas `~` corresponden todas a tonalidades que comparten sus siete clases de altura con otra tonalidad. D♭ mayor tiene las notas de C♯ mayor, y su relativa, B♭ menor, las de A♯ menor, así que las cuatro tonalidades empatan en el recuento. C♯ mayor y D♭ mayor abren las dos con su tónica y son las dos mayores, y la última regla, el nombre, elige C♯ mayor: una progresión escrita con cinco bemoles recibe una tonalidad con siete sostenidos. G♭ mayor se convierte en F♯ mayor, C♭ mayor en B mayor, E♭ menor en D♯ menor, B♭ menor en A♯ menor, y G♯ menor en A♭ menor. Las 11 casillas `x` son las mismas en las dos versiones: I II V I, en todas las tonalidades cuyos acordes se leen.

Cinco preguntas completas; para una pregunta que repite un acorde, el programa también le pasa al `Identify` de `main` los acordes como lista, tal como están escritos:

```text
Db major, I IV V I: "What key is Db Gb Ab Db in?"
  a826864  reads Db Gb Ab; top 3/3: A# minor, Bb minor, C# major, Db major; then Ab major 2/3, D# minor 2/3, Eb minor 2/3
  6baf32e  reads Db Gb Ab; top 3/3: C# major, Db major, A# minor, Bb minor; then Ab major 2/3, F# major 2/3, Gb major 2/3
           given Db Gb Ab Db as a list, Identify puts C# major first; top 3/3: C# major, Db major, A# minor, Bb minor; then Ab major 2/3, F# major 2/3, Gb major 2/3
C major, I II V I: "What key is C D G C in?"
  a826864  reads C D G; top 3/3: E minor, G major; then A minor 2/3, B minor 2/3, C major 2/3
  6baf32e  reads C D G; top 3/3: G major, E minor; then C major 2/3, D major 2/3, A minor 2/3
           given C D G C as a list, Identify puts C major first; top 2/3: C major, D major, A minor, B minor; then A minor 2/3, B minor 2/3, A major 1/3
E major, ii7 V7 Imaj7: "What key is F#m7 B7 Emaj7 in?"
  a826864  reads F#; top 1/1: A# minor, Ab minor, B major, Bb minor, C# major, Cb major, D# minor, Db major, Eb minor, F# major, G# minor, Gb major
  6baf32e  reads F#m7 B7 Emaj7; top 3/3: E major, C# minor; then F# minor 2/3, A major 2/3, B major 1/3
F# minor, i iv V i: "What key is F#m Bm C# F#m in?"
  a826864  reads F#m Bm C; top 2/3: A major, B minor, D major, E minor, F# minor, G major; then A minor 1/3, C major 1/3, C# minor 1/3
  6baf32e  reads F#m Bm C; top 2/3: F# minor, A major, D major, G major, B minor, E minor; then C major 1/3, E major 1/3, F major 1/3
           given F#m Bm C# F#m as a list, Identify puts F# minor first; top 2/3: F# minor, A major, D major, B minor; then Ab major 1/3, C# major 1/3, Db major 1/3
B minor, iiø7 V7 i: "What key is C#m7b5 F#7 Bm in?"
  a826864  reads C# F# Bm; top 2/3: A# minor, Bb minor, C# major, D# minor, Db major, Eb minor, F# major, Gb major; then A major 1/3, Ab major 1/3, Ab minor 1/3
  6baf32e  reads C#m7b5 F#7 Bm; top 1/3: B minor, C# minor, D major, E major, G major, E minor; then G# minor 2/3, C# minor 1/3, D major 1/3
```

`ExtractChords` descarta los acordes repetidos ([línea 299](https://github.com/GuitarAlchemist/ga/blob/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40/Common/GA.Domain.Services/Tonal/KeyIdentificationService.cs#L299)), así que el C final de C D G C nunca llega a `Identify`. El peso de cadencia de la #625 mira los dos últimos acordes ([líneas 231-246](https://github.com/GuitarAlchemist/ga/blob/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40/Common/GA.Domain.Services/Tonal/KeyIdentificationService.cs#L231-L246)):

```csharp
        var tonic = kd.DiatonicTriads[0];
        var last = ordered[^1];
        if (ordered.Count < 2 || last.RootPc != tonic.RootPc || last.Quality != tonic.Quality) return 0;
```

Con C D G, los dos últimos acordes son D G, un V–I de G mayor: G mayor contiene los tres acordes y además recibe el peso de cadencia. Con los cuatro acordes, `Identify` sí pone primero C mayor: su recuento es 2, porque D mayor no es una de las tríadas de C mayor, y la cadencia suma 2. La herramienta agrupa entonces las tonalidades cuyo recuento es 2 como "tied at the highest score" (empatadas en la puntuación más alta): C mayor, D mayor, A menor, B menor. Las tres siguientes se saltan tantas tonalidades como tiene el grupo de cabeza, no las tonalidades que contiene, así que A menor y B menor vuelven como coincidencias parciales, y G mayor, cuyo recuento es 3, no está en ninguna de las dos listas. La misma agrupación, sobre la pregunta tal como la lee el chatbot, da a C♯m7b5 F♯7 Bm un grupo de cabeza de seis tonalidades con 1/3, con B menor primero, y G♯ menor, con 2/3, entre las coincidencias parciales: al modelo se le dice que el grupo de cabeza tiene la puntuación más alta, y una coincidencia parcial puntúa más. Eso pasa dos veces en las 90 preguntas.

Los 16 sostenidos perdidos se leerían con un solo cambio en la expresión de `main`: sustituir el `\b` final por `(?!\w)`, "no seguido de un carácter de palabra". Comprobado con el motor de expresiones regulares de .NET sobre las 90 preguntas: 74 se leen tal como están escritas con la expresión actual, y 90 con la búsqueda hacia delante.

## La tonalidad relativa

Cada candidato lleva su tonalidad relativa, y el prompt de la skill se la muestra al modelo:

```text
== The relative key each candidate carries, against the textbook
a826864: 30 keys, 6 with another relative key: A# minor → Db major; B major → Ab minor; C# major → Bb minor; D# minor → Gb major; F# major → Eb minor; G# minor → Cb major
6baf32e: 30 keys, 6 with another relative key: A# minor → Db major; B major → Ab minor; C# major → Bb minor; D# minor → Gb major; F# major → Eb minor; G# minor → Cb major
```

El servicio encuentra la tonalidad relativa por el conjunto de clases de altura: la primera tonalidad del otro modo con las mismas siete clases de altura ([líneas 93-101](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/KeyIdentificationService.cs#L93-L101)):

```csharp
        return [.. items.Select(item =>
        {
            var (key, name, pcs, triads, symbols) = item;
            var mask     = pcs.Aggregate(0, (acc, pc) => acc | (1 << pc));
            var sibling  = byMask.GetValueOrDefault(mask)
                               ?.FirstOrDefault(x => x.Mode != key.KeyMode);
            return new DomainKeyData(name, sibling?.Name ?? string.Empty, symbols, pcs, triads);
        })];
```

`Key.Items` enumera las tonalidades mayores de C♭ a C♯, y después las menores de A♭ a A♯ ([`Key.cs` líneas 49-50](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Tonal/Key.cs#L49-L50)). B mayor tiene las clases de altura de C♭ mayor, A♭ menor y G♯ menor, y la primera tonalidad menor de las cuatro es A♭ menor. Seis tonalidades reciben la relativa de su gemela enarmónica. En la [lección 9](../09-every-interval-every-key/), `ScaleInfoSkill` se equivocaba en las mismas seis y de la misma manera ([#769](https://github.com/GuitarAlchemist/ga/issues/769)).

## Lo que lee el modelo

`BuildPrompt` también es privado; el programa lo llama por reflexión con lo que le pasa `ExecuteAsync`, e imprime la parte de datos del prompt:

```text
== The data KeyIdentificationSkill puts in the model's prompt for "What key is Db Gb Ab Db in?", at a826864
── TOP MATCHES (all tied at the highest score) ──
• A# minor  (3/3 chords diatonic)
  Relative key : Db major
  Diatonic set : A#m, B#dim, C#, D#m, E#m, F#, G#
• Bb minor  (3/3 chords diatonic)
  Relative key : Db major
  Diatonic set : Bbm, Cdim, Db, Ebm, Fm, Gb, Ab
• C# major  (3/3 chords diatonic)
  Relative key : Bb minor
  Diatonic set : C#, D#m, E#m, F#, G#, A#m, B#dim
• Db major  (3/3 chords diatonic)
  Relative key : Bb minor
  Diatonic set : Db, Ebm, Fm, Gb, Ab, Bbm, Cdim

── PARTIAL MATCHES ──
• Ab major  (2/3 chords diatonic)
• D# minor  (2/3 chords diatonic)
• Eb minor  (2/3 chords diatonic)
```

Las instrucciones que siguen piden al modelo que explique en qué tonalidad "(or keys)" (o tonalidades) está la progresión y, "If two keys tie (e.g. C major and A minor)" (si dos tonalidades empatan, por ejemplo C mayor y A menor), cómo distinguirlas escuchando la tónica. Aquí empatan cuatro tonalidades, que en realidad son dos, escritas cada una de dos maneras. A♯ menor va primero, con D♭ mayor como tonalidad relativa; el conjunto diatónico de C♯ mayor escribe E♯m y B♯dim para una pregunta escrita en D♭. En `main`, la misma lista empieza por C♯ mayor.

## Hasta dónde llega el curso

- **No se ejecuta el modelo.** Lo que dice cuando cuatro tonalidades están "all tied" (todas empatadas), o cuando se ha perdido un sostenido, necesita el modelo (*por verificar*).
- **No se prueba el enrutamiento.** Cuál de las dos superficies responde lo decide el enrutamiento, que necesita el modelo de embeddings; las dos calculan la misma respuesta.
- **El servicio de `main` se ejecuta contra el dominio fijado.** `Key.Items` y `Key.Notes` no han cambiado en `main`; el resto del chatbot de `main` no se ejecuta.
- **Una sola formulación.** Todas las preguntas son "What key is … in?", con los acordes separados por espacios.
- **Solo progresiones de manual**: tríadas y acordes de séptima en estado fundamental, sin inversiones, acordes prestados ni modulaciones.

## Comunicado upstream

- Se comunicaron después de escribir esta lección: los símbolos que `main` todavía se salta, los sostenidos perdidos y los acordes repetidos que descarta `ExtractChords`, en la issue de GA [#771](https://github.com/GuitarAlchemist/ga/issues/771); los empates entre tonalidades con las mismas clases de altura, las coincidencias principales agrupadas por recuento, las tonalidades relativas y el ejemplo de un solo candidato del SKILL.md, en la [#772](https://github.com/GuitarAlchemist/ga/issues/772). Desde la [#625](https://github.com/GuitarAlchemist/ga/pull/625), `main` lee los acordes de séptima que se salta el commit fijado. Todos están listados en el [diario](../journal/).

## Ejercicios

1. El `\b` final del `ChordPattern` de `main` pierde un sostenido delante de un espacio. Sustitúyelo para que `F#`, `C#` y `G#` conserven su sostenido y `C#m7b5` y `Cmaj7#11` se sigan leyendo enteros. ¿Cuáles de las 90 preguntas cambian?
2. `ExtractChords` elimina los acordes repetidos. ¿Qué respondería `main` para C D G C si los conservara, y qué más tiene que cambiar para que el modelo reciba C mayor sola en cabeza?
3. Reescribe la búsqueda de la tonalidad relativa para que B mayor reciba G♯ menor y G♯ menor reciba B mayor, sin comparar conjuntos de clases de altura.
4. Para "What key is Db Gb Ab Db in?", `main` pone primero C♯ mayor. ¿Qué regla, añadida antes del nombre, daría D♭ mayor, y qué daría para "What key is C# F# G# C# in?"?

<details>
<summary>Soluciones</summary>

1. Sustituye el `\b` final por `(?!\w)`: detrás de `F#`, el carácter siguiente es un espacio, que no es un carácter de palabra, así que la coincidencia conserva el `#`; detrás de `Cmaj7#11` también hay un espacio, y la expresión ya ha consumido el `#11`. Las 16 preguntas `r` de `main` se leen entonces tal como están escritas, y las otras 74 leen los mismos acordes que antes. Comprobado con el motor de expresiones regulares de .NET sobre las 90 preguntas; lo que responde `Identify` para las 16 necesita una ejecución (*por verificar*).
2. Con C D G C, `Identify` pone primero C mayor, con un recuento de 2 y una cadencia de 2. La herramienta agruparía entonces las cuatro tonalidades cuyo recuento es 2 y dejaría G mayor, cuyo recuento es 3, fuera de las dos listas (lo muestra la segunda de las preguntas completas de arriba). La selección tiene que usar el orden de `Identify`: el servicio expondría la puntuación de cada tonalidad, el recuento más la cadencia, y la herramienta conservaría las tonalidades cuya puntuación es igual a la de la primera, y después las tres que las siguen en el orden de `Identify`. C mayor quedaría sola con 4, seguida de G mayor y E menor con 3. Resuelto a mano a partir del código.
3. Toma la tonalidad relativa de la escala: la relativa menor de una tonalidad mayor empieza en su sexto grado, y la relativa mayor de una tonalidad menor, en su tercero. El `Key.Notes` del dominio escribe bien esos grados (lección 9): el sexto grado de B mayor es G♯, y el tercero de G♯ menor es B. La búsqueda se convierte en un nombre construido a partir de `key.Notes[5]` o `key.Notes[2]` y del otro modo, sin que intervenga ningún conjunto de clases de altura. Resuelto a mano; las seis tonalidades se contrastan con el manual en la salida de arriba.
4. Prefiere la tonalidad cuya tónica se escribe como la fundamental del primer acorde. `OpensOnTonic` compara clases de altura, así que D♭ y C♯ pasan las dos; comparando nombres, D♭ mayor pasa y C♯ mayor no. Para C♯ F♯ G♯ C♯, la misma regla da C♯ mayor, pero antes la pregunta tiene que conservar sus sostenidos (ejercicio 1): hoy se lee como C F G y se responde C mayor. Resuelto a mano a partir del código.

</details>

## Puntos clave

- Cuando se le dice al modelo que use solo los datos que recibe, la respuesta se decide antes de que el modelo se ejecute, según lo que la skill lee en la pregunta.
- Una expresión regular que saca los acordes de un texto en prosa decide lo que oye la skill de tonalidad: en el commit fijado se saltaba todos los acordes de séptima, y en `main` todavía lee F♯ como F.
- Un `\b` final detrás de `#` falla delante de un espacio. El mismo defecto está ya en tres expresiones del chatbot de GA.
- Eliminar los acordes repetidos corta el final de la progresión, y el peso de cadencia de `main` oye entonces el final cortado como la cadencia: D G en C D G C.
- Una clasificación y la selección construida sobre ella tienen que usar la misma puntuación: `main` ordena las tonalidades por recuento más cadencia, y la herramienta sigue agrupándolas por recuento.
- Las tonalidades con las mismas clases de altura solo se pueden distinguir por la grafía de la pregunta. Un orden por nombre elige C♯ mayor para D♭.

## Fuentes

- GuitarAlchemist/ga en [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Common/GA.Business.ML/Agents/KeyIdentificationService.cs`, `Common/GA.Business.ML/Agents/Mcp/KeyIdentificationMcpTools.cs`, `Common/GA.Business.ML/Agents/Skills/KeyIdentificationSkill.cs`, `skills/key-identification/SKILL.md`, `Common/GA.Domain.Core/Theory/Tonal/Key.cs`.
- GA en [`6baf32e`](https://github.com/GuitarAlchemist/ga/commit/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40), con commit del 2026-09-25 en UTC: `Common/GA.Domain.Services/Tonal/KeyIdentificationService.cs`, compilado por el curso. El `main` de GA en [`5c3a52a`](https://github.com/GuitarAlchemist/ga/commit/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26), con commit del 2026-09-30 en UTC, para la comparación del servicio, la herramienta, la skill y el SKILL.md.
- *Open Music Theory*, los capítulos sobre las tríadas diatónicas, la séptima elevada de la escala menor y las cadencias, para las progresiones del manual.
