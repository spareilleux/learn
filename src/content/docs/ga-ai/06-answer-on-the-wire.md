---
title: "Lesson 6: The chatbot's answer on the wire"
description: Guitar Alchemist's chat answers streamed as server-sent events from the real host, read back with a reader written from the HTML standard, and checked against the answer GA computed — the failure case the page shows as an answer, the sentence splitter that collapsed markdown lists until GA #743, and the GaApi writer of issue #746 that loses whole lines.
sidebar:
  label: 6. The answer on the wire
  order: 6
---

Lessons 4 and 5 read the chatbot's answers where GA computes them: the JSON of `POST /api/chatbot/chat`, and the text a skill returns. A user never sees either. The page in front of them reads `POST /api/chatbot/chat/stream`, which sends the same answer as [server-sent events](https://html.spec.whatwg.org/multipage/server-sent-events.html), a few sentences at a time, and rebuilds it on the other side. This lesson checks that the text the user gets is the text GA computed. It starts the real host again, as lesson 4 did, reads its stream with a reader written from the HTML standard, then puts two of GA's writers and three of its readers side by side on the improvisation answer of lesson 5.

All GA links point to commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6). Of the code this lesson reads, only `SseChunker.cs` has changed on GA's `main` since then, fixed on 2026-09-28 by pull request [#743](https://github.com/GuitarAlchemist/ga/pull/743); the program runs the pinned version and a copy of the fixed expression, and prints both. The outputs come from:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l6
```

## Server-sent events in five rules

An event stream is text. The [HTML standard's parsing rules](https://html.spec.whatwg.org/multipage/server-sent-events.html#event-stream-interpretation) fit in five lines:

1. A line ends at CRLF, LF or CR.
2. A line `data: value` appends `value` and a line feed to the event's data buffer. One space after the colon is dropped.
3. A blank line dispatches the event: its data is the buffer without the last line feed. An empty buffer dispatches nothing.
4. A line that starts with a colon is a comment. A line with no colon at all is a field with an empty value; a field the reader doesn't know is ignored.
5. At the end of the stream, an event that no blank line has ended is discarded.

So text that holds line breaks needs one `data:` line per line of text, and a blank line inside the text must not reach the wire as a blank line: it would end the event early, and the line after it would be read as a field, not as data. Browsers apply these rules in [`EventSource`](https://developer.mozilla.org/docs/Web/API/EventSource), but `EventSource` only sends GET requests, so GA's clients read the stream of a `POST` with `fetch` and parse it themselves. The program has its own reader too, `Standard` in [`Lesson6.cs`](https://github.com/spareilleux/learn/blob/main/code/ga-ai/GaAi/Lesson6.cs), written from the five rules; it keeps only the `data` field, the only one GA sends:

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

## The host's stream

The program starts `GaChatbot.Api` in its own process, with the model's address on a closed port, as lesson 4 did, and asks for voicings, the question lesson 4 showed working without a model:

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

Three events. The first is a JSON object with the routing decision, the one lesson 4 read from `/chat`, and the trace, which holds timings that change on every run; the program prints only its start. The second is the answer, one `data:` line per line of text, including the blank one (`data:` then a space, which the display trims). The third is `[DONE]`, the end marker the clients wait for; it isn't part of the standard.

```text
== The same stream, read as the HTML standard says
event 1  routing  1 line(s)
event 2  text     10 line(s)
event 3  [DONE]   1 line(s)

POST /api/chatbot/chat               HTTP 200, answer of 199 characters
text events joined, equal to it      yes (line breaks as LF)
the course's copy of the host's writer gives the host's bytes  yes
```

The text events, joined, give back the answer of `/chat` exactly. GA builds its answers with `StringBuilder.AppendLine`, whose line break is [`Environment.NewLine`](https://learn.microsoft.com/dotnet/api/system.environment.newline), CRLF on Windows, and the writer strips every CR. The program compares the two with LF line breaks, through [`String.ReplaceLineEndings`](https://learn.microsoft.com/dotnet/api/system.string.replacelineendings), so the result is the same on the three systems of the CI.

The writer is [`WriteSseLineAsync`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/GaChatbot.Api/Controllers/ChatbotController.cs#L449-L474), and its comment tells its history: until 2026-05-13, "chatbot responses with markdown tables rendered only their leading paragraph in the UI even though `/chat` returned the full text". The program has a copy of it, and the last line of the output checks the copy: encoded by it, the chunks of the `/chat` answer give the bytes the host sent, `[DONE]` included. Everything below uses that copy, and a copy of GaApi's writer: the course's clone of GA doesn't include GaApi, so the program can't start it.

```csharp
static string GaChatbotEvent(string data) =>
    string.Concat(data.Replace("\r", "").Split('\n').Select(l => $"data: {l}\n")) + "\n";

// GaApi's WriteSseLineAsync (ChatbotController.cs lines 318-322 at a826864): the chunk as is
static string GaApiEvent(string data) => $"data: {data}\n\n";
```

One thing the stream doesn't do is stream. [`ChatStreamAsync`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/GaChatbot.Api/Services/OrchestratedChatApplicationService.cs#L127-L140) awaits the whole answer from `ChatAsync`, then cuts it into sentences. The first byte of text leaves when the last one is known; the events only let the page render sentence by sentence.

## When the answer fails

Lesson 4 showed that without a model server, every question that the two guards don't catch ends in HTTP 500 on `/chat`: agent routing throws, and the fallback calls the model. "which arpeggio fits Am F C G" is one of them, although the skill that answers it needs no model. The two endpoints report the failure differently:

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

The stream can't answer 500: it sends its status and headers before the orchestrator starts ([line 39](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/GaChatbot.Api/Controllers/ChatbotController.cs#L34-L39)), so that the client sees the event stream open. A failure becomes an event instead, `{"error": …}` ([lines 91-95](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/GaChatbot.Api/Controllers/ChatbotController.cs#L91-L95)), with no `[DONE]` after it. Nothing in the standard tells an error from an answer, so it's up to each client:

- GaChatbot.Api's own page, `wwwroot/index.html`, tests a JSON event only for `"type"`, the routing event ([`consumeSseStream`, lines 740-809](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/GaChatbot.Api/wwwroot/index.html#L740-L809)). The error object has no `type`, so the page renders it as the assistant's answer, raw JSON in a chat bubble. Then the stream ends, and the page stores it in the conversation history ([line 984](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/GaChatbot.Api/wwwroot/index.html#L984)), which the next request sends back to the server as the assistant's previous turn.
- ga-client's [`parseSseBuffer`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/ga-client/src/services/chatService.ts#L29-L77) throws with the error's message, which is what a caller can handle.

## Sentences

The chunks come from [`SseChunker.SplitIntoChunks`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Helpers/SseChunker.cs#L19-L29), which splits the answer on the regular expression `(?<=[.!?])\s+`: a run of whitespace that follows a full stop, a question mark or an exclamation mark. The voicing answer has no such run. The improvisation answer of lesson 5 has six:

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

[`Regex.Split`](https://learn.microsoft.com/dotnet/api/system.text.regularexpressions.regex.split) removes what the expression matches, and here the match is the whitespace between sentences: the line break after each list item, and the blank line before the last sentence. Every client appends chunks as they come, so the joined text is what the user gets:

```text
joined, as the page renders it:
  | Over **Am – F – C – G**, for each chord:
  |
  | - **Am** → arpeggio **Am**, play **A Aeolian (natural minor)** (diatonic minor — fits most i chords).- **F** → arpeggio **F**, play **F Ionian (major)** (diatonic, includes the 7 — careful on the IV chord).- **C** → arpeggio **C**, play **C Ionian (major)** (diatonic, includes the 7 — careful on the IV chord).- **G** → arpeggio **G**, play **G Ionian (major)** (diatonic, includes the 7 — careful on the IV chord).Each arpeggio spells the chord tones; the scale adds the passing notes for lines between them.
```

Rendered as markdown, that is one bullet: the four chords run together, and so does the last sentence. It's what a browser showed on the public chatbot on 2026-09-28, in the tracer run that led to #743 and #744. Answers in prose lose their spaces the same way: "…the note Q.To create…", in #743's description.

#743 makes the split zero-width. Its expression matches no character, only a position: after a sentence's end and its whitespace (a [lookbehind](https://learn.microsoft.com/dotnet/standard/base-types/grouping-constructs-in-regular-expressions#zero-width-positive-lookbehind-assertions), which .NET allows to be of any length), and before the next character that isn't whitespace (a lookahead). Each chunk keeps the whitespace that follows it:

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

## Each writer with each reader

The chunks are only half of the contract; the writer and the reader are the other half. GA has two writers of this stream, GaChatbot.Api's and GaApi's, the host that architecture decision [ADR-0005](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/docs/adr/0005-gaapi-single-canonical-chat-host.md) names as the single chat host to come. It has three readers in this lesson: the standard, the GaChatbot page, and ga-client's `chatService`, which keeps only the first `data:` line of each event and [trims it](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/ga-client/src/services/chatService.ts#L41-L48). The program ports both clients to C#, line for line, and runs every pair on both splits:

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

Two pairs out of six are exact, and only with #743's chunks: GaChatbot.Api's writer, read by the standard or by its own page. #743 fixed the splitter, not the wire.

GaApi's writer, [`WriteSseLineAsync`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/ga-server/GaApi/Controllers/ChatbotController.cs#L318-L322), puts the chunk after a single `data: `. The first chunk holds a blank line, so the event ends there; the next line, `- **Am** → arpeggio **Am**, …`, has no colon and becomes a field name, which every reader ignores. The line about the first chord of the progression is gone, whoever reads it. That is GA issue [#746](https://github.com/GuitarAlchemist/ga/issues/746), open on 2026-09-28. `WriteSseLineAsync` is unchanged on GaApi's `main` at [`8621c3e`](https://github.com/GuitarAlchemist/ga/commit/8621c3e9c049e7b16fd105ad0b0ee96e0ef722b2), checked on 2026-09-28.

`chatService` loses the same line from either writer, since it reads one `data:` line per event, and its trim removes every line break that reaches it. The fix #746 asks for is on both sides: the server writes one `data:` line per line of text, as GaChatbot.Api does, and the client joins the `data:` lines of an event with a line feed.

Where does it show? At `a826864`, nowhere yet. No component of ga-client calls `sendChatMessageStream`, nor [`streamChat`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/ga-client/src/services/chatApi.ts#L73-L172), the other SSE client, which reads one line at a time (a `git grep` of `Apps/ga-client/src` at the pin finds only their definitions). The React chat talks [AG-UI](https://docs.ag-ui.com/) instead: every event is one JSON object on one `data:` line, and JSON writes a line break inside a string as `\n`, so no line of text reaches the wire as a line ([`AgUiEventWriter.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/ga-server/GaApi/AgUi/AgUiEventWriter.cs), [`parseAgUiFrames`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/ga-client/src/services/agUiChatService.ts#L57-L70)). The defect waits for the first client that uses GaApi's plain stream, which is what the migration of ADR-0005 would do.

## Exercises

1. Without running anything, predict what the standard reader gets from GaChatbot.Api's writer for the chunk `"a\r\nb"`, then for GaApi's writer. Which of the two writers' results depends on the system GA runs on?
2. Write the GaApi half of #746's fix in the course's copy of the writer, and a reader for `chatService` that joins the `data:` lines of an event. What should the table print afterwards?
3. The GaChatbot page renders the error event as an answer. Change the port `Page` so that an error ends the stream, and say what the page should show and what it should keep in the history.
4. #743's expression splits after `e.g. ` and after `3. ` in a numbered list. Does that break anything the user sees? What would?

<details>
<summary>Solutions</summary>

1. GaChatbot.Api's writer strips the CR first: `data: a`, `data: b`, a blank line; the standard gives `"a\nb"`, on any system. GaApi's writer sends `data: a\r\nb\n\n`: the standard ends the first line at CRLF, then reads `b` as a field with no value and ignores it, and dispatches `"a"`. The line is lost on every system. What depends on the system is the answer itself: `AppendLine` writes CRLF on Windows and LF elsewhere, and a writer that doesn't strip CR sends a different stream from a Windows host.
2. Write `string.Concat(data.Split('\n').Select(l => $"data: {l}\n")) + "\n"` in `GaApiEvent`, which makes it GaChatbot.Api's writer without the CR stripping, and in the reader take every `data:` line of the event, strip `data:` and one space, and join them with `'\n'`, without trimming. The table then prints `exact` for all six pairs with #743's chunks, and `6 line breaks missing` for all six with the pinned chunks: once the wire is fixed, only the splitter is left. Checked with the course program on 2026-09-28, by editing `Lesson6.cs` for one run; the change isn't kept.
3. When an event is a JSON object with an `error` property, throw an error with its message. The page already handles that: the `catch` block of its send function shows "Request failed: Failed to process message. Please try again." in the assistant's bubble, and the `history.push` that follows `consumeSseStream` in the `try` block is skipped, so the next request doesn't send the error back as the assistant's turn. Not run in a browser (*to verify*).
4. No: #743 keeps every character, so a chunk that ends after `e.g. ` only means that the page renders the sentence in two steps. It matters if a client treats chunks as units, for example by trimming them, like `chatService`, or by adding a space or a line break between them; either would change the text at every split, wanted or not.

</details>

## Key takeaways

- GaChatbot.Api streams an answer as server-sent events: a routing event, the answer in sentences, then `[DONE]`. Its writer prefixes every line of text with `data: `, so a reader that follows the HTML standard gets the answer back exactly.
- The stream isn't streaming: the whole answer is computed before the first event, and the chunks only let the page render it sentence by sentence.
- A failed request is an HTTP 500 on `/chat` but an HTTP 200 on the stream, with an `{"error": …}` event and no `[DONE]`. GaChatbot.Api's own page shows that JSON as the assistant's answer and keeps it in the history.
- At `a826864`, `SseChunker` removed the whitespace between sentences, and markdown lists collapsed into one bullet on the public page. #743 made the split zero-width; the joined chunks are now the answer, exactly.
- GaApi's writer puts a whole chunk after one `data: `: a blank line inside the chunk ends the event, and the next line is lost, for any reader (#746). No ga-client component reads that stream at `a826864`, so the defect is waiting for the migration to GaApi.

## Sources

- WHATWG, *HTML Living Standard*, [section 9.2, "Server-sent events"](https://html.spec.whatwg.org/multipage/server-sent-events.html), in particular [9.2.5, "Parsing an event stream"](https://html.spec.whatwg.org/multipage/server-sent-events.html#parsing-an-event-stream) and [9.2.6, "Interpreting an event stream"](https://html.spec.whatwg.org/multipage/server-sent-events.html#event-stream-interpretation); read on 2026-09-28.
- GuitarAlchemist/ga at [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Apps/GaChatbot.Api` (`Controllers/ChatbotController.cs`, `Services/OrchestratedChatApplicationService.cs`, `wwwroot/index.html`), `Apps/ga-server/GaApi` (`Controllers/ChatbotController.cs`, `AgUi/AgUiEventWriter.cs`), `Apps/ga-client/src/services` (`chatService.ts`, `chatApi.ts`, `agUiChatService.ts`), `Common/GA.Business.Core.Orchestration/Helpers/SseChunker.cs`.
- GA pull request [#743](https://github.com/GuitarAlchemist/ga/pull/743), merged on 2026-09-28 as [`43e0eae`](https://github.com/GuitarAlchemist/ga/commit/43e0eae22431425fce7e039431c5b5d094585453), and GA issue [#746](https://github.com/GuitarAlchemist/ga/issues/746), open on 2026-09-28.
- MDN, [`EventSource`](https://developer.mozilla.org/docs/Web/API/EventSource); the [AG-UI protocol](https://docs.ag-ui.com/).
- Microsoft Learn: [`Regex.Split`](https://learn.microsoft.com/dotnet/api/system.text.regularexpressions.regex.split), [grouping constructs and lookaround assertions](https://learn.microsoft.com/dotnet/standard/base-types/grouping-constructs-in-regular-expressions), [`String.ReplaceLineEndings`](https://learn.microsoft.com/dotnet/api/system.string.replacelineendings), [`Environment.NewLine`](https://learn.microsoft.com/dotnet/api/system.environment.newline).
