---
title: "Lección 7: Nombres de acorde que el chatbot no sabe leer"
description: "Peticiones de improvisación con nombres de acorde no válidos, con nombres válidos y con ambos, enviadas a la skill de improvisación de Guitar Alchemist en el commit fijado del curso y en la versión de la pull request #749, que rechaza las peticiones que solo nombran acordes no válidos — compilada junto al commit fijado con un extern alias, y calificadas por un pequeño reconocedor de cifrados de acorde. La guarda funciona; los nombres en minúsculas, las cualidades erróneas, los signos de bemol, una fundamental con sostenido sin cualidad, C+ y Bø7 todavía se cuelan o se leen mal."
sidebar:
  label: 7. Nombres de acorde que no sabe leer
  order: 7
---

El 2026-09-28, una ejecución del tracer preguntó al chatbot público "which arpeggio fits Hm Q7" (¿qué arpegio encaja sobre Hm Q7?). Ni Hm ni Q7 son acordes en notación inglesa, y la respuesta debería haberlo dicho. Dijo esto: "The note Hm Q7 (also known as H) is a perfect 4th above the note Q.To create an arpeggio based on this note, you'll need to find a chord that includes H and its neighboring notes. …" (la nota Hm Q7, también llamada H, está una cuarta justa por encima de la nota Q; para crear un arpegio a partir de ella hay que encontrar un acorde que incluya H y sus notas vecinas). De ahí salió la issue [#745](https://github.com/GuitarAlchemist/ga/issues/745) de GA, y ese mismo día la pull request [#749](https://github.com/GuitarAlchemist/ga/pull/749) añadió una guarda que rechaza esas peticiones. Esta lección pone a prueba esa guarda, y la skill de improvisación de la lección 5 antes y después de ella, con dieciséis peticiones, y califica lo que hacen con un pequeño reconocedor de cifrados de acorde. La pregunta va más allá de la #745: ¿qué nombres de acorde sabe leer el chatbot, en realidad?

Todos los enlaces a GA apuntan al commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), el commit fijado del curso, salvo los que llevan a los archivos de la #749, que apuntan a su commit de fusión, [`d7efd41`](https://github.com/GuitarAlchemist/ga/commit/d7efd4142908542d469e0b1a9e6dd3dceba8ecc5). Los tres archivos que compila la lección siguen sin cambios en el `main` de GA, en [`f4f4d30`](https://github.com/GuitarAlchemist/ga/commit/f4f4d30465b39be7ec36aba3742c218782cf9127), comprobado el 2026-09-28. Las salidas proceden de:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l7
```

## Cómo llegó Hm Q7 al modelo

La descripción de la #749 traza dos caminos desde ese mensaje hasta el modelo de lenguaje, los dos a través del respaldo de GA:

1. **No coincide nada.** El enrutador semántico de intenciones de la lección 4 puntúa el mensaje por debajo de su umbral en todas las intenciones, el enrutador de agentes no encuentra nada mejor, y la respuesta sale de la llamada directa al modelo. Es el camino que registró el tracer: enrutamiento `fallback-direct`, método `low-confidence-fallback`.
2. **La skill coincide, y su respuesta se sustituye.** Si el enrutador sí elige la skill de improvisación, la skill no encuentra ningún cifrado de acorde, pasa el mensaje a su extractor, que llama a un modelo, y termina con su respuesta para cuando no hay acorde, "I couldn't find a chord name in your request…" (no he encontrado ningún nombre de acorde en tu petición…), con confianza 0,2. [`OrchestratedChatApplicationService`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/GaChatbot.Api/Services/OrchestratedChatApplicationService.cs#L17) sustituye toda respuesta por debajo de `Chatbot:FallbackMinConfidence`, 0,25, por la del modelo.

Un modelo sin guarda responde a cualquier cosa. Sin conexión, el curso ve el primer paso del segundo camino: en el commit fijado, la skill pasa "which arpeggio fits Hm Q7" a su extractor, y el extractor del curso detiene ahí la ejecución, como en las lecciones 5 y 6.

La #749 añade [`InvalidChordNames`](https://github.com/GuitarAlchemist/ga/blob/d7efd4142908542d469e0b1a9e6dd3dceba8ecc5/Common/GA.Business.ML/Agents/Skills/InvalidChordNames.cs). Su `Find` devuelve los tokens con forma de cifrado de acorde cuya fundamental es una letra fuera de A–G, pero solo cuando el mensaje hace una pregunta de improvisación y no nombra ningún acorde válido. El orquestador lo llama después del despacho semántico y antes del enrutador de agentes, en sus dos vías de respuesta ([`ProductionOrchestrator.cs` líneas 828-840](https://github.com/GuitarAlchemist/ga/blob/d7efd4142908542d469e0b1a9e6dd3dceba8ecc5/Common/GA.Business.Core.Orchestration/Services/ProductionOrchestrator.cs#L828-L840), llamado en las líneas 259 y 550), y la skill lo llama antes de su extractor. En los dos casos, el rechazo tiene confianza 0,9, por encima del umbral del respaldo, así que es la respuesta.

## Compilar una corrección junto al commit fijado

El curso compila contra GA en `a826864`, y cambiar el commit fijado cambiaría la salida de todas las lecciones. Así que el programa compila solo los tres archivos de la #749, `InvalidChordNames.cs`, `ImprovisationSkill.cs` y `ChordIntentMatching.cs`, tomados del commit de fusión, en un pequeño proyecto propio que referencia el `GA.Business.ML` fijado. [`fetch-ga.sh`](https://github.com/spareilleux/learn/blob/main/code/ga-ai/fetch-ga.sh) los extrae del clon sin blobs con `git show`, de modo que el repositorio del curso no guarda ninguna copia del código de GA:

```xml
<ItemGroup>
  <Compile Include="../.ga-fix/*.cs" />
  <!-- The global usings the three files were written against, from the pinned project -->
  <Compile Include="$(GaRoot)Common/GA.Business.ML/GlobalUsings.cs" Link="GlobalUsings.cs" />
</ItemGroup>
```

Ahora el proyecto define él mismo `GA.Business.ML.Agents.Skills.ImprovisationSkill`, y también lo define el ensamblado al que hace referencia. Dentro del proyecto, el compilador usa su propia definición y lo avisa con la advertencia [CS0436](https://learn.microsoft.com/dotnet/csharp/language-reference/compiler-messages/using-directive-errors#cs0436), que el proyecto silencia a propósito. El programa del curso referencia los dos ensamblados, así que tiene dos tipos con el mismo nombre completo. Al nuevo le da un [extern alias](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/extern-alias), mediante los metadatos `Aliases` de su [referencia de proyecto](https://learn.microsoft.com/visualstudio/msbuild/common-msbuild-project-items#projectreference):

```xml
<ProjectReference Include="../GaFix749/GaFix749.csproj" Aliases="fix749" />
```

`Lesson7.cs` empieza con `extern alias fix749;` y llama `Fixed` al espacio de nombres corregido mediante un [alias de using](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/using-directive), `using Fixed = fix749::GA.Business.ML.Agents.Skills;`. Sin alias, los nombres se resuelven al ensamblado fijado, como en el resto del curso:

```csharp
var pinned = new ImprovisationSkill(NullLogger<ImprovisationSkill>.Instance, new NoExtractor());
var fixedSkill = new Fixed.ImprovisationSkill(NullLogger<Fixed.ImprovisationSkill>.Instance, new NoExtractor());
```

Los tres archivos llaman al resto de `GA.Business.ML` tal como está en el commit fijado, no tal como está en el commit de fusión de la #749. Aquí basta, porque la #749 no cambió nada más en ese proyecto; sus demás cambios están en el orquestador y en las pruebas. Si la corrección hubiera necesitado un tipo nuevo en otro sitio, la compilación fallaría y lo diría.

## Un reconocedor de cifrados de acorde

Para calificar las respuestas, el programa necesita saber qué palabras de un mensaje son cifrados de acorde. `Read`, en [`Lesson7.cs`](https://github.com/spareilleux/learn/blob/main/code/ga-ai/GaAi/Lesson7.cs), sigue la convención de los lead sheets, las partituras con la melodía y el cifrado: una fundamental en mayúscula de A a G, una alteración opcional, una cualidad tomada de una lista y una nota del bajo opcional tras una barra. Una palabra con esa forma pero rota, con una fundamental fuera de A–G, una fundamental en minúscula o una cualidad que no está en la lista, "no es un cifrado de acorde". Una palabra que no tiene esa forma en absoluto, "fits", "mode", "I", es texto:

```csharp
static readonly Regex Symbol = new(@"^(?<letter>[A-Za-z])(?<accidental>[#b♯♭]?)(?<quality>[^/]*)(?:/(?<bass>[A-G][#b♯♭]?))?$");

// Números romanos de la armonía: "V7", "ii", "IV". Se deja fuera una "I" sola: es el pronombre
static readonly Regex Roman = new(@"^(?=.{2})(?:VII|VI|V|IV|III|II|I|vii|vi|v|iv|iii|ii|i)(?:7|°|ø)?$");
```

```text
== What each message holds, read as chord symbols are written
#   message                            chords       not chord symbols
1   which arpeggio fits Hm Q7          -            Hm (root H), Q7 (root Q)
2   which arpeggio fits X7alt          -            X7alt (root X)
3   Q7, which arpeggio should I use?   -            Q7 (root Q)
4   which arpeggio fits H7             -            H7 (root H)
5   which arpeggio fits hm q7          -            hm (lowercase root), q7 (lowercase root)
6   which arpeggio fits Cq7            -            Cq7 (quality q7)
7   which arpeggio fits Am F C G       Am F C G     -
8   which arpeggio fits Bb Eb F        Bb Eb F      -
9   which arpeggio fits B♭ E♭ F        Bb Eb F      -
10  which arpeggio fits B F# G#m E     B F# G#m E   -
11  which arpeggio fits C C+ F         C C+ F       -
12  which arpeggio fits Bø7 E7 Am      Bø7 E7 Am    -
13  which arpeggio fits Am F Q7 G      Am F G       Q7 (root Q)
14  which arpeggio fits C and Q7       C            Q7 (root Q)
15  Hm, which mode is brightest?       -            Hm (root H)
16  which arpeggio fits V7             -            V7 (Roman numeral)
```

B♭ y Bb son el mismo acorde, así que el reconocedor escribe los dos con alteraciones ASCII. La regla de calificación sigue los criterios de aceptación de la #745: un mensaje que contiene una palabra que no es un cifrado de acorde debería rechazarse, o al menos la respuesta debería nombrar esa palabra; un mensaje con dos acordes o más debería responderse acorde por acorde, exactamente para esos acordes. El resto, un solo acorde o ninguno, toma la vía del modelo de la skill y aquí no se califica.

## Qué hace GA con ellos

```text
== What GA does with them
#   skill at a826864       #749 guard   #749 skill             verdict (#749)
1   needs the model        Hm Q7        declines               same
2   needs the model        X7alt        declines               same
3   needs the model        Q7           declines               same
4   needs the model        H7           declines               same
5   needs the model        -            needs the model        DIFF reaches the model
6   needs the model        -            needs the model        DIFF reaches the model
7   answers Am F C G       -            answers Am F C G       same
8   answers Bb Eb F        -            answers Bb Eb F        same
9   answers B E F          -            answers B E F          DIFF reads Bb as B, Eb as E
10  answers B F G#m E      -            answers B F G#m E      DIFF reads F# as F
11  answers C C F          -            answers C C F          DIFF reads C+ as C
12  answers E7 Am          -            answers E7 Am          DIFF drops Bø7 without a word
13  answers Am F G         -            answers Am F G         DIFF drops Q7 without a word
14  needs the model        -            needs the model        DIFF reaches the model
15  needs the model        -            needs the model        DIFF reaches the model
16  needs the model        -            needs the model        n/a
```

"needs the model" significa que la skill pasó el mensaje a su extractor; en el chatbot desplegado, a partir de ahí responde un modelo, o el respaldo. La columna "#749 guard" es `InvalidChordNames.Find`, la llamada que hace el orquestador.

**Filas 1 a 4: la guarda cumple su función.** Se rechaza cada mensaje que solo nombra acordes con una fundamental fuera de A–G, incluido el que empieza por el acorde (`Q7, which arpeggio…`). En el commit fijado, los cuatro iban al modelo.

**Filas 5, 6 y 14: la guarda no salta, y el mensaje sigue hasta el modelo.** La expresión regular de la guarda distingue mayúsculas de minúsculas y busca fundamentales de H a Z, así que `hm q7` no coincide. `Cq7` tiene una fundamental válida y una cualidad desconocida, que la #749 declara fuera de su alcance. `C and Q7` nombra un acorde válido, `C`, así que la guarda calla por diseño: una petición que mezcla acordes válidos y no válidos "keeps its route" (conserva su ruta). En los tres casos, lo que lee el usuario depende de un modelo que ya ha inventado teoría sobre tokens no válidos.

**Filas 9 a 12: acordes válidos, mal leídos.** No interviene ningún modelo y no se rechaza nada: la skill responde, pero para otros acordes.

- `B♭ E♭ F` se responde como B, E y F: un arpegio de B mayor y B jónico para B♭. En todas las expresiones de la skill, tras la fundamental se admite `[#b]`, no `♭` ni `♯` ([líneas 447-462](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L447-L462)). Las skills de cejilla y de afinaciones alternativas de GA aceptan los dos signos.
- `F#` se lee como F, en ASCII puro. La serie de acordes sale de `ChordTokenRegex`, que termina en `\b`, un [límite de palabra](https://learn.microsoft.com/dotnet/standard/base-types/anchors-in-regular-expressions#word-boundary-b): una posición entre un [carácter de palabra](https://learn.microsoft.com/dotnet/standard/base-types/character-classes-in-regular-expressions#word-character-w) y un carácter que no lo es, o el principio o el final del texto. Tras `F#` viene un espacio, y ni `#` ni un espacio son caracteres de palabra, así que ahí no hay límite. El motor retrocede, descarta el `#` opcional y encuentra un límite entre `F` y `#`. `G#m` sobrevive porque termina en `m`; `Bb`, porque `b` es una letra.
- `C+` se lee como C por la misma razón: `+` es una de las cualidades que enumera la expresión, pero un `+` seguido de un espacio no deja ningún límite.
- `Bø7` desaparece de la serie: `ø` es una letra, así que ningún límite lo separa del `7`, y la lista tiene `°7` pero no `ø7`. La skill responde para E7 y Am y no dice nada del primer acorde.

El rechazo de las filas 1 a 4 le dice al usuario que un nombre de acorde es una fundamental "optionally followed by # or b" (seguida opcionalmente de # o b). La fila 10 muestra que la skill no sabe leer el más sencillo de ellos, un acorde mayor sobre una fundamental con sostenido.

**Fila 13: un acorde no válido descartado en silencio.** `Am F Q7 G` recibe una respuesta para Am, F y G. La lección 5 encontró el mismo silencio con acordes que la skill no sabe analizar, `C7sus4` y `CmMaj7`.

## El rechazo

```text
== #749's skill on "which arpeggio fits Hm Q7"
confidence 0.9
  | I don't recognize "Hm" and "Q7" as chord names, so I can't suggest arpeggios or scales for them. A chord name starts with a root letter from A to G, optionally followed by # or b, then the chord quality: for example 'Bm', 'G7' or 'Cmaj7'. In German notation H is B: "Hm" is written "Bm" here. Name the chords again and I'll give the arpeggio and scales for each.
assumption: Not chord names (root outside A-G): Hm, Q7.
```

La respuesta nombra los tokens, dice qué forma tiene un nombre de acorde y vuelve a preguntar, sin teoría sobre los tokens. Su último detalle es musical: en la notación alemana, y en los países nórdicos, H es B natural y B es B♭, así que "Hm" es un acorde real, B menor. La indicación es correcta, y aparece con cualquier token que empiece por H. Para `H7`, la respuesta dice "In German notation H is B: "H7" is written "B7" here." (en notación alemana, H es B: aquí "H7" se escribe "B7").

## Hasta dónde llega el reconocedor

- **La fila 15 es un error del reconocedor, no de GA.** "Hm, which mode is brightest?" (mmm, ¿qué modo es el más brillante?) empieza con una interjección. El reconocedor lee `Hm` como un cifrado de acorde roto; la guarda de GA se salta una interjección que abre un mensaje y va seguida de una coma, que es la lectura correcta. La pregunta en sí, qué modo suena más brillante, le corresponde a un modelo, y es correcto que vaya ahí.
- **Los números romanos no se califican.** `V7` solo nombra un acorde dentro de una tonalidad, y el mensaje no da ninguna. La guarda de GA deja fuera los números romanos a propósito; lo que debería ser la respuesta, una pregunta de vuelta sobre la tonalidad, aquí no se comprueba.
- **La lista de cualidades es finita.** Un cifrado válido que no esté en ella, `C13#11` por ejemplo, se declararía roto. La lista cubre los acordes de las lecciones 5 y 7, nada más.
- **Una sola notación.** El reconocedor conoce las letras de la notación inglesa, en mayúscula. La H y la B alemanas, el solfeo (`Do`, `Ré`) y los nombres de acorde en minúsculas, habituales al escribir deprisa, son todos para él "no cifrados de acorde", lo cual es una elección del curso, no un hecho musical.

## Comunicado upstream

- Los nombres de acorde no válidos que llegan al modelo: issue de GA [#745](https://github.com/GuitarAlchemist/ga/issues/745), corregida por la pull request [#749](https://github.com/GuitarAlchemist/ga/pull/749), fusionada el 2026-09-28. Las filas 1 a 4 son esa corrección.
- Las filas 5, 6, 9 a 12 y 13, los nombres en minúsculas, la cualidad desconocida, los signos de bemol, la fundamental con sostenido sin cualidad, `C+`, `Bø7` y el descarte silencioso: no se habían comunicado upstream cuando se escribió esta lección. Están listadas en el [diario](../journal/).

## Ejercicios

1. Sin ejecutar nada, predice qué responde la skill a "which arpeggio fits F♯ C♯m". ¿Cuál de los dos acordes conserva su cualidad?
2. Cambia la skill para que las filas 9 a 12 lean sus acordes. ¿Cuál es el cambio más pequeño en `ChordTokenRegex`, y qué más hace falta?
3. ¿Por qué sería difícil extender la guarda a los tokens en minúsculas? Nombra tres palabras que una regla para minúsculas tendría que dejar en paz.
4. ¿Qué debería decir la respuesta a la fila 13, "which arpeggio fits Am F Q7 G"? ¿En qué parte de la skill lo pondrías?

<details>
<summary>Soluciones</summary>

1. La skill responde para F y C: las dos fundamentales pierden su sostenido, porque `♯` no está en las expresiones, y `C♯m` pierde además su cualidad menor, ya que la coincidencia se detiene en `C`. Ninguno de los dos acordes conserva su cualidad tal como está escrita. Comprobado con el programa del curso el 2026-09-28, añadiendo el mensaje a `Messages` para una sola ejecución.
2. Tres cambios. Sustituye `♭` por `b` y `♯` por `#` en el mensaje antes de que lo lea la skill. Termina `ChordTokenRegex` con la búsqueda hacia delante `(?![\w#+°ø-])` en lugar de `\b`, para que un cifrado pueda terminar en `#`, `+` o `°` pero no en medio de una palabra. Añade `ø7` antes de `ø` en la lista de cualidades. Con esas tres modificaciones hechas en el `ImprovisationSkill.cs` de la #749 para una sola ejecución, las filas 9 a 12 dan `same`, y las filas 1 a 8 y 13 a 16 no cambian; comprobado con el programa del curso el 2026-09-28. `InferQuality` ya clasifica como semidisminuido un cifrado que contiene `ø`, y como aumentado uno que empieza por `+` tras su fundamental ([líneas 309-353](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L309-L353)).
3. Las letras minúsculas también son palabras. Una regla que tomara por nombre de acorde una letra minúscula seguida de un sufijo atraparía `am` (como en "I am"), `hm` y `mm` (interjecciones), y `a` delante de un número. La guarda necesitaría el contexto que la regla de las mayúsculas obtiene gratis: una serie de varios tokens, o una posición tras "fits" u "over".
4. Debería responder para Am, F y G y nombrar Q7, por ejemplo "I don't recognize "Q7" as a chord name; here are the other three." (no reconozco "Q7" como nombre de acorde; aquí están los otros tres). La skill ya tiene lo que necesita: `InvalidChordNames` encuentra el token, pero solo lo devuelve cuando no se nombra ningún acorde válido. Una variante que devolviera los tokens no válidos en todos los casos, llamada desde la vía de progresión, podría añadir una frase a la respuesta. No se ha compilado contra GA (*por verificar*).

</details>

## Puntos clave

- Un chatbot con un modelo detrás responde a cualquier mensaje, así que lo que no se puede responder hay que rechazarlo antes de que lo vea el modelo. La #749 lo hace con las peticiones de improvisación que solo nombran acordes con una fundamental fuera de A–G, con una confianza por encima del umbral del respaldo.
- Una corrección que no está en el commit fijado se puede ejecutar igualmente: se compilan sus archivos junto al ensamblado fijado, y se llega al tipo duplicado mediante un extern alias.
- A la guarda se le escapan los nombres en minúsculas, las cualidades desconocidas sobre una fundamental válida y las peticiones que mezclan acordes válidos y no válidos; esas siguen llegando al modelo o pierden un acorde en silencio.
- Los acordes válidos se leen mal sin que intervenga ningún modelo: los signos de bemol y de sostenido, una fundamental con sostenido sin cualidad en ASCII, `C+` y `Bø7`. La causa es el juego de caracteres de las expresiones de la skill y el `\b` final, que no puede ir detrás de `#`, `+` ni `°`.
- El reconocedor se equivoca en la fila de la interjección, donde GA acierta: un oráculo tiene que decir hasta dónde llega.

## Fuentes

- GuitarAlchemist/ga en [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs`, `Apps/GaChatbot.Api/Services/OrchestratedChatApplicationService.cs`.
- Pull request de GA [#749](https://github.com/GuitarAlchemist/ga/pull/749), fusionada el 2026-09-28 como [`d7efd41`](https://github.com/GuitarAlchemist/ga/commit/d7efd4142908542d469e0b1a9e6dd3dceba8ecc5): `InvalidChordNames.cs`, `ImprovisationSkill.cs`, `ChordIntentMatching.cs`, `ProductionOrchestrator.cs` y su descripción; issue de GA [#745](https://github.com/GuitarAlchemist/ga/issues/745), con la respuesta del tracer.
- Microsoft Learn: [extern alias](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/extern-alias), [CS0436](https://learn.microsoft.com/dotnet/csharp/language-reference/compiler-messages/using-directive-errors#cs0436), [la directiva `using`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/using-directive), [elementos comunes de proyectos de MSBuild](https://learn.microsoft.com/visualstudio/msbuild/common-msbuild-project-items#projectreference), [anclajes](https://learn.microsoft.com/dotnet/standard/base-types/anchors-in-regular-expressions#word-boundary-b) y [clases de caracteres](https://learn.microsoft.com/dotnet/standard/base-types/character-classes-in-regular-expressions#word-character-w) en las expresiones regulares de .NET.
