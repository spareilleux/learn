---
title: "Lección 6: La respuesta del chatbot en el cable"
description: "Las respuestas del chat de Guitar Alchemist, transmitidas desde el host real como eventos enviados por el servidor (server-sent events), leídas de nuevo con un lector escrito a partir del estándar HTML y comparadas con la respuesta que calculó GA — el caso de fallo que la página muestra como una respuesta, el divisor de frases que fundía las listas markdown en una sola viñeta hasta la #743 de GA, y el escritor de GaApi de la issue #746, que pierde líneas enteras."
sidebar:
  label: 6. La respuesta en el cable
  order: 6
---

Las lecciones 4 y 5 leían las respuestas del chatbot allí donde GA las calcula: el JSON de `POST /api/chatbot/chat` y el texto que devuelve una skill. El usuario no ve nunca ninguno de los dos. La página que tiene delante lee `POST /api/chatbot/chat/stream`: ese endpoint envía la misma respuesta como [eventos enviados por el servidor](https://html.spec.whatwg.org/multipage/server-sent-events.html) (server-sent events), unas pocas frases cada vez, y la página la reconstruye al otro lado. Esta lección comprueba que el texto que recibe el usuario es el texto que calculó GA. Vuelve a arrancar el host real, como hizo la lección 4, lee su flujo con un lector escrito a partir del estándar HTML, y después compara, uno junto a otro, dos escritores y tres lectores de GA sobre la respuesta de improvisación de la lección 5.

Todos los enlaces a GA apuntan al commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6). Del código que lee esta lección, solo `SseChunker.cs` ha cambiado desde entonces en el `main` de GA: lo corrigió el 2026-09-28 la pull request [#743](https://github.com/GuitarAlchemist/ga/pull/743). El programa ejecuta la versión fijada y una copia de la expresión corregida, e imprime las dos. Las salidas proceden de:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l6
```

## Los eventos enviados por el servidor en cinco reglas

Un flujo de eventos es texto. Las [reglas de análisis del estándar HTML](https://html.spec.whatwg.org/multipage/server-sent-events.html#event-stream-interpretation) caben en cinco líneas:

1. Una línea termina en CRLF, LF o CR.
2. Una línea `data: value` añade `value` y un avance de línea al búfer de datos del evento. Se descarta un único espacio tras los dos puntos.
3. Una línea en blanco emite el evento: sus datos son el búfer sin el último avance de línea. Un búfer vacío no emite nada.
4. Una línea que empieza por dos puntos es un comentario. Una línea sin ningún signo de dos puntos es un campo con valor vacío; un campo que el lector no conoce se ignora.
5. Al final del flujo, un evento que ninguna línea en blanco ha cerrado se descarta.

Así que un texto con saltos de línea necesita una línea `data:` por cada línea de texto, y una línea en blanco dentro del texto no debe llegar al cable como línea en blanco: cerraría el evento antes de tiempo, y la línea siguiente se leería como un campo, no como datos. Los navegadores aplican estas reglas en [`EventSource`](https://developer.mozilla.org/docs/Web/API/EventSource), pero `EventSource` solo envía peticiones GET, así que los clientes de GA leen el flujo de un `POST` con `fetch` y lo analizan ellos mismos. El programa también tiene su propio lector, `Standard` en [`Lesson6.cs`](https://github.com/spareilleux/learn/blob/main/code/ga-ai/GaAi/Lesson6.cs), escrito a partir de las cinco reglas; solo conserva el campo `data`, el único que envía GA:

```csharp
foreach (var line in Regex.Split(stream, "\r\n|\r|\n"))
{
    if (line.Length == 0)
    {
        if (data.Length > 0) events.Add(data.ToString(0, data.Length - 1));
        data.Clear();
        continue;
    }
    if (line[0] == ':') continue;
    var colon = line.IndexOf(':');
    var field = colon < 0 ? line : line[..colon];
    var value = colon < 0 ? "" : line[(colon + 1)..];
    if (value.StartsWith(' ')) value = value[1..];
    if (field == "data") data.Append(value).Append('\n');
}
```

## El flujo del host

El programa arranca `GaChatbot.Api` en su propio proceso, con la dirección del modelo en un puerto cerrado, como hizo la lección 4, y pide voicings, la pregunta que la lección 4 mostró funcionando sin modelo:

```text
== POST /api/chatbot/chat/stream "Show me Cmaj7 voicings"
HTTP 200
  | data: {"type":"routing","agentId":"voicing",…
  |
  | data: Found 2 voicings matching chord Cmaj7:
  | data:
  | data: - **Cmaj7** `3-0-x-2-3-x` (guitar, score 0.369)
  | data: ```vextab
  | data: 6/3 5/0 3/2 2/3
  | data: ```
  | data: - **Cmaj7** `3-0-0-2-3-x` (guitar, score 0.369)
  | data: ```vextab
  | data: 6/3 5/0 4/0 3/2 2/3
  | data: ```
  |
  | data: [DONE]
  |
```

Tres eventos. El primero es un objeto JSON con la decisión de enrutamiento, la que la lección 4 leyó de `/chat`, y la traza, que contiene tiempos que cambian en cada ejecución; el programa solo imprime su comienzo. El segundo es la respuesta, una línea `data:` por línea de texto, incluida la vacía (`data:` seguido de un espacio, que se recorta al mostrarlo). El tercero es `[DONE]`, el marcador de fin que esperan los clientes; no forma parte del estándar.

```text
== The same stream, read as the HTML standard says
event 1  routing  1 line(s)
event 2  text     10 line(s)
event 3  [DONE]   1 line(s)

POST /api/chatbot/chat               HTTP 200, answer of 199 characters
text events joined, equal to it      yes (line breaks as LF)
the course's copy of the host's writer gives the host's bytes  yes
```

Los eventos de texto, unidos, devuelven exactamente la respuesta de `/chat`. GA construye sus respuestas con `StringBuilder.AppendLine`, cuyo salto de línea es [`Environment.NewLine`](https://learn.microsoft.com/dotnet/api/system.environment.newline), CRLF en Windows, y el escritor elimina todos los CR. El programa compara las dos con saltos de línea LF, mediante [`String.ReplaceLineEndings`](https://learn.microsoft.com/dotnet/api/system.string.replacelineendings), de modo que el resultado es el mismo en los tres sistemas de la CI.

El escritor es [`WriteSseLineAsync`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/GaChatbot.Api/Controllers/ChatbotController.cs#L449-L474), y su comentario cuenta su historia: hasta el 2026-05-13, "chatbot responses with markdown tables rendered only their leading paragraph in the UI even though `/chat` returned the full text" (las respuestas del chatbot con tablas markdown solo mostraban su primer párrafo en la interfaz, aunque `/chat` devolvía el texto completo). El programa tiene una copia de ese escritor, y la última línea de la salida comprueba la copia: codificados por ella, los fragmentos de la respuesta de `/chat` dan los bytes que envió el host, `[DONE]` incluido. Todo lo que sigue usa esa copia, y una copia del escritor de GaApi: el clon de GA que usa el curso no incluye GaApi, así que el programa no puede arrancarlo.

```csharp
static string GaChatbotEvent(string data) =>
    string.Concat(data.Replace("\r", "").Split('\n').Select(l => $"data: {l}\n")) + "\n";

// WriteSseLineAsync de GaApi (ChatbotController.cs, líneas 318-322 en a826864): el fragmento tal cual
static string GaApiEvent(string data) => $"data: {data}\n\n";
```

Hay algo que el flujo no hace, y es fluir. [`ChatStreamAsync`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/GaChatbot.Api/Services/OrchestratedChatApplicationService.cs#L127-L140) espera la respuesta completa de `ChatAsync` y después la corta en frases. El primer byte de texto sale cuando ya se conoce el último; los eventos solo permiten que la página muestre la respuesta frase a frase.

## Cuando la respuesta falla

La lección 4 mostró que, sin servidor de modelos, toda pregunta que no capturan las dos guardas termina en HTTP 500 en `/chat`: el enrutamiento a agentes lanza una excepción, y el respaldo llama al modelo. "which arpeggio fits Am F C G" es una de ellas, aunque la skill que la responde no necesita modelo. Los dos endpoints comunican el fallo de forma distinta:

```text
== "which arpeggio fits Am F C G" with no model server
POST /api/chatbot/chat         HTTP 500
POST /api/chatbot/chat/stream  HTTP 200
  | data: {"error":"Failed to process message. Please try again."}
  |

reader                 what the user gets
HTML standard          {"error":"Failed to process message. Please try again."}
GaChatbot page         {"error":"Failed to process message. Please try again."}
ga-client chatService  (throws) Failed to process message. Please try again.
```

El flujo no puede responder con un 500: envía su estado y sus cabeceras antes de que arranque el orquestador ([línea 39](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/GaChatbot.Api/Controllers/ChatbotController.cs#L34-L39)), para que el cliente vea abrirse el flujo de eventos. Un fallo se convierte entonces en un evento, `{"error": …}` ([líneas 91-95](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/GaChatbot.Api/Controllers/ChatbotController.cs#L91-L95)), sin ningún `[DONE]` detrás. Nada en el estándar distingue un error de una respuesta, así que la decisión queda en manos de cada cliente:

- La propia página de GaChatbot.Api, `wwwroot/index.html`, solo comprueba en un evento JSON la presencia de `"type"`, que marca el evento de enrutamiento ([`consumeSseStream`, líneas 740-809](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/GaChatbot.Api/wwwroot/index.html#L740-L809)). El objeto de error no tiene `type`, así que la página lo muestra como la respuesta del asistente: JSON en bruto en una burbuja de chat. Después el flujo termina, y la página lo guarda en el historial de la conversación ([línea 984](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/GaChatbot.Api/wwwroot/index.html#L984)), que la siguiente petición devuelve al servidor como el turno anterior del asistente.
- [`parseSseBuffer`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/ga-client/src/services/chatService.ts#L29-L77), en ga-client, lanza una excepción con el mensaje del error, que es algo que quien llama puede gestionar.

## Frases

Los fragmentos salen de [`SseChunker.SplitIntoChunks`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Helpers/SseChunker.cs#L19-L29), que divide la respuesta con la expresión regular `(?<=[.!?])\s+`: una secuencia de espacios en blanco que sigue a un punto, a un signo de interrogación o a un signo de exclamación. La respuesta de voicings no tiene ninguna secuencia así. La respuesta de improvisación de la lección 5 tiene seis:

```text
== SseChunker.SplitIntoChunks on the improvisation skill's answer (GA at a826864)
answer: 6 lines of text, 8 line breaks, 558 characters
chunk 1  "Over **Am – F – C – G**, for each chord:\n\n- **Am** → arpeggio **Am**, play **A Aeolian (natural minor)** (diatonic minor — fits most i chords)."
chunk 2  "- **F** → arpeggio **F**, play **F Ionian (major)** (diatonic, includes the 7 — careful on the IV chord)."
chunk 3  "- **C** → arpeggio **C**, play **C Ionian (major)** (diatonic, includes the 7 — careful on the IV chord)."
chunk 4  "- **G** → arpeggio **G**, play **G Ionian (major)** (diatonic, includes the 7 — careful on the IV chord)."
chunk 5  "Each arpeggio spells the chord tones; the scale adds the passing notes for lines between them."
joined: 552 characters, 6 line breaks missing
```

[`Regex.Split`](https://learn.microsoft.com/dotnet/api/system.text.regularexpressions.regex.split) elimina lo que coincide con la expresión, y aquí la coincidencia es el espacio en blanco entre frases: el salto de línea tras cada elemento de la lista y la línea en blanco antes de la última frase. Todos los clientes añaden los fragmentos a medida que llegan, así que el texto unido es lo que recibe el usuario:

```text
joined, as the page renders it:
  | Over **Am – F – C – G**, for each chord:
  |
  | - **Am** → arpeggio **Am**, play **A Aeolian (natural minor)** (diatonic minor — fits most i chords).- **F** → arpeggio **F**, play **F Ionian (major)** (diatonic, includes the 7 — careful on the IV chord).- **C** → arpeggio **C**, play **C Ionian (major)** (diatonic, includes the 7 — careful on the IV chord).- **G** → arpeggio **G**, play **G Ionian (major)** (diatonic, includes the 7 — careful on the IV chord).Each arpeggio spells the chord tones; the scale adds the passing notes for lines between them.
```

Interpretado como markdown, eso es una sola viñeta: los cuatro acordes quedan pegados, y la última frase también. Es lo que mostró un navegador en el chatbot público el 2026-09-28, en la ejecución del tracer que dio lugar a la #743 y a la #744. Las respuestas en prosa pierden sus espacios de la misma manera: "…the note Q.To create…", en la descripción de la #743.

La #743 hace que el corte tenga ancho cero. Su expresión no coincide con ningún carácter, solo con una posición: después del final de una frase y de su espacio en blanco (una [aserción de búsqueda hacia atrás](https://learn.microsoft.com/dotnet/standard/base-types/grouping-constructs-in-regular-expressions#zero-width-positive-lookbehind-assertions), o *lookbehind*, que .NET admite de cualquier longitud), y antes del siguiente carácter que no sea un espacio en blanco (una búsqueda hacia delante, o *lookahead*). Cada fragmento conserva el espacio en blanco que lo sigue:

```csharp
static readonly Regex After743 = new(@"(?<=[.!?]\s+)(?=\S)");
```

```text
== The same answer split by #743's expression (?<=[.!?]\s+)(?=\S)
chunk 1  "Over **Am – F – C – G**, for each chord:\n\n- **Am** → arpeggio **Am**, play **A Aeolian (natural minor)** (diatonic minor — fits most i chords).\n"
chunk 2  "- **F** → arpeggio **F**, play **F Ionian (major)** (diatonic, includes the 7 — careful on the IV chord).\n"
chunk 3  "- **C** → arpeggio **C**, play **C Ionian (major)** (diatonic, includes the 7 — careful on the IV chord).\n"
chunk 4  "- **G** → arpeggio **G**, play **G Ionian (major)** (diatonic, includes the 7 — careful on the IV chord).\n\n"
chunk 5  "Each arpeggio spells the chord tones; the scale adds the passing notes for lines between them.\n"
joined: 558 characters, exact
```

## Cada escritor con cada lector

Los fragmentos son solo la mitad del contrato; el escritor y el lector son la otra mitad. GA tiene dos escritores para este flujo: el de GaChatbot.Api y el de GaApi, el host que la decisión de arquitectura [ADR-0005](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/docs/adr/0005-gaapi-single-canonical-chat-host.md) designa como futuro host único del chat. En esta lección tiene tres lectores: el estándar, la página de GaChatbot y el `chatService` de ga-client, que solo conserva la primera línea `data:` de cada evento y [la recorta](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/ga-client/src/services/chatService.ts#L41-L48). El programa porta los dos clientes a C#, línea por línea, y ejecuta cada pareja con las dos divisiones:

```text
== Each writer with each reader, on the improvisation answer
writer         reader                 chunks at a826864                            chunks after #743
GaChatbot.Api  HTML standard          6 line breaks missing                        exact
GaChatbot.Api  GaChatbot page         6 line breaks missing                        exact
GaChatbot.Api  ga-client chatService  1 of 6 lines missing, 8 line breaks missing  1 of 6 lines missing, 8 line breaks missing
GaApi          HTML standard          1 of 6 lines missing, 8 line breaks missing  1 of 6 lines missing, 8 line breaks missing
GaApi          GaChatbot page         1 of 6 lines missing, 8 line breaks missing  1 of 6 lines missing, 8 line breaks missing
GaApi          ga-client chatService  1 of 6 lines missing, 8 line breaks missing  1 of 6 lines missing, 8 line breaks missing
```

Dos parejas de seis son exactas, y solo con los fragmentos de la #743: el escritor de GaChatbot.Api, leído por el estándar o por su propia página. La #743 corrigió el divisor, no el cable.

El escritor de GaApi, [`WriteSseLineAsync`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/ga-server/GaApi/Controllers/ChatbotController.cs#L318-L322), pone el fragmento tras un único `data: `. El primer fragmento contiene una línea en blanco, así que el evento termina ahí; la línea siguiente, `- **Am** → arpeggio **Am**, …`, no tiene dos puntos y se convierte en un nombre de campo, que todos los lectores ignoran. La línea del primer acorde de la progresión desaparece, la lea quien la lea. Es la issue [#746](https://github.com/GuitarAlchemist/ga/issues/746) de GA, abierta el 2026-09-28. `WriteSseLineAsync` sigue sin cambios en el `main` de GaApi, en [`8621c3e`](https://github.com/GuitarAlchemist/ga/commit/8621c3e9c049e7b16fd105ad0b0ee96e0ef722b2), comprobado el 2026-09-28.

`chatService` pierde la misma línea con cualquiera de los dos escritores, ya que lee una línea `data:` por evento, y su recorte elimina todos los saltos de línea que le llegan. La corrección que pide la #746 afecta a los dos lados: el servidor escribe una línea `data:` por línea de texto, como hace GaChatbot.Api, y el cliente une las líneas `data:` de un evento con un avance de línea.

¿Dónde se nota? En `a826864`, todavía en ninguna parte. Ningún componente de ga-client llama a `sendChatMessageStream`, ni a [`streamChat`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/ga-client/src/services/chatApi.ts#L73-L172), el otro cliente SSE, que lee una línea cada vez (un `git grep` de `Apps/ga-client/src` en el commit fijado solo encuentra sus definiciones). El chat de React habla [AG-UI](https://docs.ag-ui.com/) en su lugar: cada evento es un objeto JSON en una sola línea `data:`, y JSON escribe un salto de línea dentro de una cadena como `\n`, así que ninguna línea de texto llega al cable como línea ([`AgUiEventWriter.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/ga-server/GaApi/AgUi/AgUiEventWriter.cs), [`parseAgUiFrames`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/ga-client/src/services/agUiChatService.ts#L57-L70)). El defecto espera al primer cliente que use el flujo simple de GaApi, que es justo lo que haría la migración de ADR-0005.

## Ejercicios

1. Sin ejecutar nada, predice qué obtiene el lector estándar del escritor de GaChatbot.Api para el fragmento `"a\r\nb"`, y después del escritor de GaApi. ¿El resultado de cuál de los dos escritores depende del sistema en el que se ejecuta GA?
2. Escribe la mitad de GaApi de la corrección de la #746 en la copia del escritor que tiene el curso, y un lector para `chatService` que una las líneas `data:` de un evento. ¿Qué debería imprimir la tabla después?
3. La página de GaChatbot muestra el evento de error como una respuesta. Cambia la versión portada `Page` para que un error termine el flujo, y di qué debería mostrar la página y qué debería guardar en el historial.
4. La expresión de la #743 corta después de `e.g. ` y después de `3. ` en una lista numerada. ¿Rompe eso algo que vea el usuario? ¿Qué lo rompería?

<details>
<summary>Soluciones</summary>

1. El escritor de GaChatbot.Api elimina primero el CR: `data: a`, `data: b` y una línea en blanco; el estándar da `"a\nb"`, en cualquier sistema. El escritor de GaApi envía `data: a\r\nb\n\n`: el estándar termina la primera línea en el CRLF, luego lee `b` como un campo sin valor y lo ignora, y emite `"a"`. La línea se pierde en todos los sistemas. Lo que depende del sistema es la propia respuesta: `AppendLine` escribe CRLF en Windows y LF en los demás, y un escritor que no elimina el CR envía un flujo distinto desde un host Windows.
2. Escribe `string.Concat(data.Split('\n').Select(l => $"data: {l}\n")) + "\n"` en `GaApiEvent`, lo que lo convierte en el escritor de GaChatbot.Api sin la eliminación de los CR, y en el lector toma todas las líneas `data:` del evento, quita `data:` y un espacio, y únelas con `'\n'`, sin recortar. La tabla imprime entonces `exact` para las seis parejas con los fragmentos de la #743, y `6 line breaks missing` para las seis con los fragmentos fijados: una vez corregido el cable, solo queda el divisor. Comprobado con el programa del curso el 2026-09-28, editando `Lesson6.cs` para una sola ejecución; el cambio no se conserva.
3. Cuando un evento sea un objeto JSON con una propiedad `error`, lanza un error con su mensaje. La página ya gestiona ese caso: el bloque `catch` de su función de envío muestra "Request failed: Failed to process message. Please try again." en la burbuja del asistente, y el `history.push` que sigue a `consumeSseStream` en el bloque `try` no se ejecuta, así que la siguiente petición no devuelve el error como turno del asistente. No se ha ejecutado en un navegador (*por verificar*).
4. No: la #743 conserva todos los caracteres, así que un fragmento que termina después de `e.g. ` solo significa que la página muestra la frase en dos pasos. Importa si un cliente trata los fragmentos como unidades, por ejemplo recortándolos, como `chatService`, o añadiendo un espacio o un salto de línea entre ellos; cualquiera de las dos cosas cambiaría el texto en cada corte, fuera intencionado o no.

</details>

## Puntos clave

- GaChatbot.Api transmite una respuesta como eventos enviados por el servidor: un evento de enrutamiento, la respuesta en frases, y luego `[DONE]`. Su escritor antepone `data: ` a cada línea de texto, así que un lector que sigue el estándar HTML recupera exactamente la respuesta.
- El flujo no fluye: toda la respuesta se calcula antes del primer evento, y los fragmentos solo permiten que la página la muestre frase a frase.
- Una petición fallida es un HTTP 500 en `/chat` pero un HTTP 200 en el flujo, con un evento `{"error": …}` y sin `[DONE]`. La propia página de GaChatbot.Api muestra ese JSON como la respuesta del asistente y lo guarda en el historial.
- En `a826864`, `SseChunker` eliminaba el espacio en blanco entre frases, y las listas markdown se fundían en una sola viñeta en la página pública. La #743 hizo que el corte tuviera ancho cero; los fragmentos unidos son ahora exactamente la respuesta.
- El escritor de GaApi pone un fragmento entero tras un solo `data: `: una línea en blanco dentro del fragmento termina el evento, y la línea siguiente se pierde, la lea quien la lea (#746). Ningún componente de ga-client lee ese flujo en `a826864`, así que el defecto espera a la migración a GaApi.

## Fuentes

- WHATWG, *HTML Living Standard*, [sección 9.2, "Server-sent events"](https://html.spec.whatwg.org/multipage/server-sent-events.html), en particular [9.2.5, "Parsing an event stream"](https://html.spec.whatwg.org/multipage/server-sent-events.html#parsing-an-event-stream) y [9.2.6, "Interpreting an event stream"](https://html.spec.whatwg.org/multipage/server-sent-events.html#event-stream-interpretation); leídas el 2026-09-28.
- GuitarAlchemist/ga en [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Apps/GaChatbot.Api` (`Controllers/ChatbotController.cs`, `Services/OrchestratedChatApplicationService.cs`, `wwwroot/index.html`), `Apps/ga-server/GaApi` (`Controllers/ChatbotController.cs`, `AgUi/AgUiEventWriter.cs`), `Apps/ga-client/src/services` (`chatService.ts`, `chatApi.ts`, `agUiChatService.ts`), `Common/GA.Business.Core.Orchestration/Helpers/SseChunker.cs`.
- Pull request de GA [#743](https://github.com/GuitarAlchemist/ga/pull/743), fusionada el 2026-09-28 como [`43e0eae`](https://github.com/GuitarAlchemist/ga/commit/43e0eae22431425fce7e039431c5b5d094585453); issue de GA [#746](https://github.com/GuitarAlchemist/ga/issues/746), abierta el 2026-09-28.
- Issue de GA [#760](https://github.com/GuitarAlchemist/ga/issues/760), abierta el 2026-09-29 a partir de esta lección: la página muestra el evento de error del flujo como la respuesta.
- MDN, [`EventSource`](https://developer.mozilla.org/docs/Web/API/EventSource); el [protocolo AG-UI](https://docs.ag-ui.com/).
- Microsoft Learn: [`Regex.Split`](https://learn.microsoft.com/dotnet/api/system.text.regularexpressions.regex.split), [construcciones de agrupamiento y aserciones de búsqueda](https://learn.microsoft.com/dotnet/standard/base-types/grouping-constructs-in-regular-expressions), [`String.ReplaceLineEndings`](https://learn.microsoft.com/dotnet/api/system.string.replacelineendings), [`Environment.NewLine`](https://learn.microsoft.com/dotnet/api/system.environment.newline).
