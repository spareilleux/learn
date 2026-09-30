---
title: "Leçon 6 : la réponse du chatbot sur le fil"
description: "Les réponses du chat de Guitar Alchemist diffusées en événements envoyés par le serveur depuis le vrai hôte, relues avec un lecteur écrit d'après le standard HTML et comparées à la réponse calculée par GA — l'échec que la page affiche comme une réponse, le découpage en phrases qui écrasait les listes markdown jusqu'à GA #743, et l'émetteur de GaApi du ticket #746, qui perd des lignes entières."
sidebar:
  label: 6. La réponse sur le fil
  order: 6
---

Les leçons 4 et 5 lisaient les réponses du chatbot là où GA les calcule : le JSON de `POST /api/chatbot/chat`, et le texte que renvoie un skill. Un utilisateur ne voit ni l'un ni l'autre. La page qu'il a sous les yeux lit `POST /api/chatbot/chat/stream`, qui envoie la même réponse sous forme d'[événements envoyés par le serveur](https://html.spec.whatwg.org/multipage/server-sent-events.html) (*server-sent events*), quelques phrases à la fois ; la page la reconstruit de l'autre côté. Cette leçon vérifie que le texte que reçoit l'utilisateur est bien celui que GA a calculé. Elle redémarre le vrai hôte, comme la leçon 4, lit son flux avec un lecteur écrit d'après le standard HTML, puis met côte à côte deux émetteurs et trois lecteurs de GA sur la réponse d'improvisation de la leçon 5.

Tous les liens vers GA pointent sur le commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6). Du code que lit cette leçon, seul `SseChunker.cs` a changé depuis sur le `main` de GA : il a été corrigé le 2026-09-28 par la pull request [#743](https://github.com/GuitarAlchemist/ga/pull/743). Le programme exécute la version épinglée et une copie de l'expression corrigée, et affiche les deux. Les sorties viennent de :

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l6
```

## Les événements envoyés par le serveur en cinq règles

Un flux d'événements, c'est du texte. Les [règles d'analyse du standard HTML](https://html.spec.whatwg.org/multipage/server-sent-events.html#event-stream-interpretation) tiennent en cinq lignes :

1. Une ligne se termine par CRLF, LF ou CR.
2. Une ligne `data: value` ajoute `value` et un LF au tampon de données de l'événement. Un espace après le deux-points est retiré.
3. Une ligne vide déclenche l'événement : ses données sont le tampon sans son dernier LF. Un tampon vide ne déclenche rien.
4. Une ligne qui commence par un deux-points est un commentaire. Une ligne sans aucun deux-points est un champ à la valeur vide ; un champ que le lecteur ne connaît pas est ignoré.
5. À la fin du flux, un événement qu'aucune ligne vide n'a terminé est abandonné.

Un texte qui contient des sauts de ligne demande donc une ligne `data:` par ligne de texte, et une ligne vide à l'intérieur du texte ne doit pas arriver sur le fil comme une ligne vide : elle terminerait l'événement trop tôt, et la ligne suivante serait lue comme un champ, pas comme des données. Les navigateurs appliquent ces règles dans [`EventSource`](https://developer.mozilla.org/docs/Web/API/EventSource), mais `EventSource` n'envoie que des requêtes GET : les clients de GA lisent donc le flux d'un `POST` avec `fetch` et l'analysent eux-mêmes. Le programme a aussi son propre lecteur, `Standard` dans [`Lesson6.cs`](https://github.com/spareilleux/learn/blob/main/code/ga-ai/GaAi/Lesson6.cs), écrit d'après les cinq règles ; il ne garde que le champ `data`, le seul qu'envoie GA :

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

## Le flux de l'hôte

Le programme démarre `GaChatbot.Api` dans son propre processus, avec l'adresse du modèle sur un port fermé, comme à la leçon 4, et demande des voicings, la question dont la leçon 4 a montré qu'elle fonctionne sans modèle :

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

Trois événements. Le premier est un objet JSON qui porte la décision de routage, celle que la leçon 4 lisait dans `/chat`, et la trace, avec des durées qui changent à chaque exécution ; le programme n'en affiche que le début. Le deuxième est la réponse, une ligne `data:` par ligne de texte, y compris la ligne vide (`data:` suivi d'un espace, que l'affichage supprime). Le troisième est `[DONE]`, le marqueur de fin qu'attendent les clients ; il ne fait pas partie du standard.

```text
== The same stream, read as the HTML standard says
event 1  routing  1 line(s)
event 2  text     10 line(s)
event 3  [DONE]   1 line(s)

POST /api/chatbot/chat               HTTP 200, answer of 199 characters
text events joined, equal to it      yes (line breaks as LF)
the course's copy of the host's writer gives the host's bytes  yes
```

Mis bout à bout, les événements de texte redonnent exactement la réponse de `/chat`. GA construit ses réponses avec `StringBuilder.AppendLine`, dont le saut de ligne est [`Environment.NewLine`](https://learn.microsoft.com/dotnet/api/system.environment.newline), CRLF sous Windows, et l'émetteur retire tous les CR. Le programme compare les deux avec des sauts de ligne LF, grâce à [`String.ReplaceLineEndings`](https://learn.microsoft.com/dotnet/api/system.string.replacelineendings) : le résultat est donc le même sur les trois systèmes de la CI.

L'émetteur est [`WriteSseLineAsync`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/GaChatbot.Api/Controllers/ChatbotController.cs#L449-L474), et son commentaire raconte son histoire : jusqu'au 2026-05-13, « chatbot responses with markdown tables rendered only their leading paragraph in the UI even though `/chat` returned the full text », les réponses qui contenaient des tableaux markdown n'affichaient que leur premier paragraphe dans l'interface, alors que `/chat` renvoyait le texte complet. Le programme en a une copie, et la dernière ligne de la sortie vérifie cette copie : encodés par elle, les fragments de la réponse de `/chat` donnent les octets qu'a envoyés l'hôte, `[DONE]` compris. Tout ce qui suit utilise cette copie, et une copie de l'émetteur de GaApi : le clone de GA du cours ne contient pas GaApi, et le programme ne peut donc pas le démarrer.

```csharp
static string GaChatbotEvent(string data) =>
    string.Concat(data.Replace("\r", "").Split('\n').Select(l => $"data: {l}\n")) + "\n";

// Le WriteSseLineAsync de GaApi (ChatbotController.cs, lignes 318-322 à a826864) : le fragment tel quel
static string GaApiEvent(string data) => $"data: {data}\n\n";
```

Il y a une chose que ce flux ne fait pas : s'écouler au fur et à mesure. [`ChatStreamAsync`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/GaChatbot.Api/Services/OrchestratedChatApplicationService.cs#L127-L140) attend la réponse entière de `ChatAsync`, puis la découpe en phrases. Le premier octet de texte part quand le dernier est connu ; les événements permettent seulement à la page d'afficher la réponse phrase par phrase.

## Quand la réponse échoue

La leçon 4 a montré que, sans serveur de modèles, chaque question que les deux gardes n'attrapent pas finit en HTTP 500 sur `/chat` : le routage vers les agents lève une exception, et le repli appelle le modèle. « which arpeggio fits Am F C G » en fait partie, alors que le skill qui y répond n'a besoin d'aucun modèle. Les deux points d'accès signalent l'échec différemment :

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

Le flux ne peut pas répondre 500 : il envoie son statut et ses en-têtes avant que l'orchestrateur ne démarre ([ligne 39](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/GaChatbot.Api/Controllers/ChatbotController.cs#L34-L39)), pour que le client voie le flux d'événements s'ouvrir. Un échec devient donc un événement, `{"error": …}` ([lignes 91-95](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/GaChatbot.Api/Controllers/ChatbotController.cs#L91-L95)), sans `[DONE]` derrière. Rien dans le standard ne distingue une erreur d'une réponse : c'est à chaque client de le faire.

- La propre page de GaChatbot.Api, `wwwroot/index.html`, ne cherche dans un événement JSON que `"type"`, qui signale l'événement de routage ([`consumeSseStream`, lignes 740-809](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/GaChatbot.Api/wwwroot/index.html#L740-L809)). L'objet d'erreur n'a pas de `type` : la page l'affiche donc comme la réponse de l'assistant, du JSON brut dans une bulle de chat. Puis le flux se termine, et la page le range dans l'historique de la conversation ([ligne 984](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/GaChatbot.Api/wwwroot/index.html#L984)), que la requête suivante renvoie au serveur comme le tour précédent de l'assistant.
- Le [`parseSseBuffer`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/ga-client/src/services/chatService.ts#L29-L77) de ga-client lève une exception avec le message de l'erreur, ce qu'un appelant peut traiter.

## Les phrases

Les fragments viennent de [`SseChunker.SplitIntoChunks`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Helpers/SseChunker.cs#L19-L29), qui découpe la réponse sur l'expression régulière `(?<=[.!?])\s+` : une suite de blancs qui suit un point, un point d'interrogation ou un point d'exclamation. La réponse de voicing n'a aucune suite de ce genre. La réponse d'improvisation de la leçon 5 en a six :

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

[`Regex.Split`](https://learn.microsoft.com/dotnet/api/system.text.regularexpressions.regex.split) retire ce que l'expression reconnaît, et ici, ce sont les blancs entre les phrases : le saut de ligne après chaque élément de la liste, et la ligne vide avant la dernière phrase. Tous les clients ajoutent les fragments à mesure qu'ils arrivent, si bien que l'utilisateur reçoit le texte recollé :

```text
joined, as the page renders it:
  | Over **Am – F – C – G**, for each chord:
  |
  | - **Am** → arpeggio **Am**, play **A Aeolian (natural minor)** (diatonic minor — fits most i chords).- **F** → arpeggio **F**, play **F Ionian (major)** (diatonic, includes the 7 — careful on the IV chord).- **C** → arpeggio **C**, play **C Ionian (major)** (diatonic, includes the 7 — careful on the IV chord).- **G** → arpeggio **G**, play **G Ionian (major)** (diatonic, includes the 7 — careful on the IV chord).Each arpeggio spells the chord tones; the scale adds the passing notes for lines between them.
```

Rendu en markdown, c'est une seule puce : les quatre accords s'enchaînent sans coupure, et la dernière phrase aussi. C'est ce qu'a affiché un navigateur sur le chatbot public le 2026-09-28, lors du tracer qui a mené à #743 et #744. Les réponses en prose perdent leurs espaces de la même façon : « …the note Q.To create… », dans la description de #743.

#743 rend le découpage de largeur nulle. Son expression ne reconnaît aucun caractère, seulement une position : après la fin d'une phrase et les blancs qui la suivent (un [*lookbehind*](https://learn.microsoft.com/dotnet/standard/base-types/grouping-constructs-in-regular-expressions#zero-width-positive-lookbehind-assertions), une assertion arrière que .NET autorise de longueur quelconque), et avant le caractère suivant qui n'est pas un blanc (un *lookahead*, une assertion avant). Chaque fragment garde les blancs qui le suivent :

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

## Chaque émetteur avec chaque lecteur

Les fragments ne sont que la moitié du contrat ; l'émetteur et le lecteur en sont l'autre moitié. GA a deux émetteurs de ce flux, celui de GaChatbot.Api et celui de GaApi, l'hôte que la décision d'architecture [ADR-0005](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/docs/adr/0005-gaapi-single-canonical-chat-host.md) désigne comme le futur hôte unique du chat. Il a trois lecteurs dans cette leçon : le standard, la page de GaChatbot, et le `chatService` de ga-client, qui ne garde que la première ligne `data:` de chaque événement et [en retire les blancs aux deux bouts](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/ga-client/src/services/chatService.ts#L41-L48). Le programme porte les deux clients en C#, ligne à ligne, et fait tourner chaque paire sur les deux découpages :

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

Deux paires sur six sont exactes, et seulement avec les fragments de #743 : l'émetteur de GaChatbot.Api, lu par le standard ou par sa propre page. #743 a corrigé le découpage, pas le fil.

L'émetteur de GaApi, [`WriteSseLineAsync`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/ga-server/GaApi/Controllers/ChatbotController.cs#L318-L322), place le fragment derrière un seul `data: `. Le premier fragment contient une ligne vide : l'événement se termine donc là ; la ligne suivante, `- **Am** → arpeggio **Am**, …`, n'a pas de deux-points et devient un nom de champ, que tous les lecteurs ignorent. La ligne sur le premier accord de la progression a disparu, quel que soit le lecteur. C'est le ticket de GA [#746](https://github.com/GuitarAlchemist/ga/issues/746), ouvert le 2026-09-28. Côté GaApi, `WriteSseLineAsync` est inchangé sur `main` au commit [`8621c3e`](https://github.com/GuitarAlchemist/ga/commit/8621c3e9c049e7b16fd105ad0b0ee96e0ef722b2), vérifié le 2026-09-28.

`chatService` perd la même ligne, quel que soit l'émetteur, puisqu'il lit une ligne `data:` par événement, et son nettoyage des blancs supprime tous les sauts de ligne qui lui parviennent. Le correctif que demande #746 porte sur les deux côtés : le serveur écrit une ligne `data:` par ligne de texte, comme GaChatbot.Api, et le client joint les lignes `data:` d'un événement avec un LF.

Où cela se voit-il ? À `a826864`, nulle part encore. Aucun composant de ga-client n'appelle `sendChatMessageStream`, ni [`streamChat`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/ga-client/src/services/chatApi.ts#L73-L172), l'autre client SSE, qui lit une ligne à la fois (un `git grep` de `Apps/ga-client/src` au commit épinglé ne trouve que leurs définitions). Le chat React parle [AG-UI](https://docs.ag-ui.com/) à la place : chaque événement est un objet JSON sur une seule ligne `data:`, et JSON écrit un saut de ligne à l'intérieur d'une chaîne sous la forme `\n`, si bien qu'aucune ligne de texte n'arrive sur le fil comme une ligne ([`AgUiEventWriter.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/ga-server/GaApi/AgUi/AgUiEventWriter.cs), [`parseAgUiFrames`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/ga-client/src/services/agUiChatService.ts#L57-L70)). Le défaut attend le premier client qui utilisera le flux simple de GaApi, ce que ferait la migration d'ADR-0005.

## Exercices

1. Sans rien exécuter, prédis ce que le lecteur standard obtient de l'émetteur de GaChatbot.Api pour le fragment `"a\r\nb"`, puis de celui de GaApi. Lequel des deux résultats dépend du système sur lequel tourne GA ?
2. Écris la moitié GaApi du correctif de #746 dans la copie de l'émetteur que contient le cours, et un lecteur pour `chatService` qui joint les lignes `data:` d'un événement. Que devrait afficher le tableau ensuite ?
3. La page de GaChatbot affiche l'événement d'erreur comme une réponse. Modifie le portage `Page` pour qu'une erreur termine le flux, et dis ce que la page devrait afficher et ce qu'elle devrait garder dans l'historique.
4. L'expression de #743 découpe après `e.g. ` et après `3. ` dans une liste numérotée. Est-ce que cela casse quelque chose que voit l'utilisateur ? Qu'est-ce qui le casserait ?

<details>
<summary>Solutions</summary>

1. L'émetteur de GaChatbot.Api retire d'abord le CR : `data: a`, `data: b`, une ligne vide ; le standard donne `"a\nb"`, sur n'importe quel système. L'émetteur de GaApi envoie `data: a\r\nb\n\n` : le standard termine la première ligne au CRLF, lit ensuite `b` comme un champ sans valeur et l'ignore, puis déclenche `"a"`. La ligne est perdue sur tous les systèmes. Ce qui dépend du système, c'est la réponse elle-même : `AppendLine` écrit CRLF sous Windows et LF ailleurs, et un émetteur qui ne retire pas les CR envoie un flux différent depuis un hôte Windows.
2. Écris `string.Concat(data.Split('\n').Select(l => $"data: {l}\n")) + "\n"` dans `GaApiEvent`, ce qui en fait l'émetteur de GaChatbot.Api sans le retrait des CR ; dans le lecteur, prends toutes les lignes `data:` de l'événement, retire `data:` et un espace, et joins-les avec `'\n'`, sans toucher aux blancs. Le tableau affiche alors `exact` pour les six paires avec les fragments de #743, et `6 line breaks missing` pour les six avec les fragments épinglés : une fois le fil réparé, il ne reste que le découpage. Vérifié avec le programme du cours le 2026-09-28, en modifiant `Lesson6.cs` le temps d'une exécution ; la modification n'est pas gardée.
3. Quand un événement est un objet JSON avec une propriété `error`, lève une erreur avec son message. La page sait déjà traiter ce cas : le bloc `catch` de sa fonction d'envoi affiche « Request failed: Failed to process message. Please try again. » dans la bulle de l'assistant, et le `history.push` qui suit `consumeSseStream` dans le bloc `try` est sauté : la requête suivante ne renvoie donc pas l'erreur comme le tour de l'assistant. Non exécuté dans un navigateur (*à vérifier*).
4. Non : #743 garde chaque caractère, et un fragment qui se termine après `e.g. ` veut seulement dire que la page affiche la phrase en deux temps. Cela compte si un client traite les fragments comme des unités, par exemple en leur retirant les blancs de début et de fin, comme `chatService`, ou en ajoutant un espace ou un saut de ligne entre eux ; l'un comme l'autre changerait le texte à chaque découpe, voulue ou non.

</details>

## À retenir

- GaChatbot.Api diffuse une réponse en événements envoyés par le serveur : un événement de routage, la réponse en phrases, puis `[DONE]`. Son émetteur préfixe chaque ligne de texte par `data: ` : un lecteur qui suit le standard HTML retrouve donc la réponse à l'identique.
- Le flux ne s'écoule pas au fur et à mesure : la réponse entière est calculée avant le premier événement, et les fragments permettent seulement à la page de l'afficher phrase par phrase.
- Une requête qui échoue donne un HTTP 500 sur `/chat`, mais un HTTP 200 sur le flux, avec un événement `{"error": …}` et pas de `[DONE]`. La propre page de GaChatbot.Api affiche ce JSON comme la réponse de l'assistant et le garde dans l'historique.
- À `a826864`, `SseChunker` retirait les blancs entre les phrases, et les listes markdown s'écrasaient en une seule puce sur la page publique. #743 a rendu le découpage de largeur nulle ; les fragments recollés redonnent maintenant exactement la réponse.
- L'émetteur de GaApi place un fragment entier derrière un seul `data: ` : une ligne vide dans le fragment termine l'événement, et la ligne suivante est perdue, quel que soit le lecteur (#746). Aucun composant de ga-client ne lit ce flux à `a826864` : le défaut attend donc la migration vers GaApi.

## Sources

- WHATWG, *HTML Living Standard*, [section 9.2, "Server-sent events"](https://html.spec.whatwg.org/multipage/server-sent-events.html), en particulier [9.2.5, "Parsing an event stream"](https://html.spec.whatwg.org/multipage/server-sent-events.html#parsing-an-event-stream) et [9.2.6, "Interpreting an event stream"](https://html.spec.whatwg.org/multipage/server-sent-events.html#event-stream-interpretation) ; lu le 2026-09-28.
- GuitarAlchemist/ga au commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6) : `Apps/GaChatbot.Api` (`Controllers/ChatbotController.cs`, `Services/OrchestratedChatApplicationService.cs`, `wwwroot/index.html`), `Apps/ga-server/GaApi` (`Controllers/ChatbotController.cs`, `AgUi/AgUiEventWriter.cs`), `Apps/ga-client/src/services` (`chatService.ts`, `chatApi.ts`, `agUiChatService.ts`), `Common/GA.Business.Core.Orchestration/Helpers/SseChunker.cs`.
- Pull request de GA [#743](https://github.com/GuitarAlchemist/ga/pull/743), fusionnée le 2026-09-28 sous le commit [`43e0eae`](https://github.com/GuitarAlchemist/ga/commit/43e0eae22431425fce7e039431c5b5d094585453), et ticket de GA [#746](https://github.com/GuitarAlchemist/ga/issues/746), ouvert le 2026-09-28.
- MDN, [`EventSource`](https://developer.mozilla.org/docs/Web/API/EventSource) ; le [protocole AG-UI](https://docs.ag-ui.com/).
- Microsoft Learn : [`Regex.Split`](https://learn.microsoft.com/dotnet/api/system.text.regularexpressions.regex.split), [constructions de regroupement et assertions de voisinage](https://learn.microsoft.com/dotnet/standard/base-types/grouping-constructs-in-regular-expressions), [`String.ReplaceLineEndings`](https://learn.microsoft.com/dotnet/api/system.string.replacelineendings), [`Environment.NewLine`](https://learn.microsoft.com/dotnet/api/system.environment.newline).
