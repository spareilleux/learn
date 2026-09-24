// VexTab & VexFlow, lesson 4: every VexTab text GA writes or tests, run through GA's own F# parser.
// dotnet run -- <ga checkout> <course cases folder> <output folder>
// Writes each text to <output>/<id>.vextab for the VexTab side (render.cjs), and prints what GA's parser makes of it;
// when GA parses a text, what GA's generator writes back goes to <output>/<id>-generated.vextab.
open System
open System.IO
open System.Text.RegularExpressions
open GA.Business.DSL.Types.VexTabTypes
open GA.Business.DSL.Parsers
open GA.Business.DSL.Generators
open GA.Business.ML.Notation

type Case = { Id: string; Source: string; Text: string }

let slug (s: string) =
    Regex.Replace(s.ToLowerInvariant(), "[^a-z0-9]+", "-").Trim('-')

let read (ga: string) (path: string) = File.ReadAllText(Path.Combine(ga, path)).Replace("\r\n", "\n")

// The eight open chords of BeginnerChordsSkill, turned into fences by the formatter the chatbot uses
let beginnerCases ga =
    let file = "Common/GA.Business.ML/Agents/Skills/BeginnerChordsSkill.cs"
    [ for m in Regex.Matches(read ga file, "\\(\"([A-G][a-z ]+)\",\\s*\"([xX0-9-]+)\"") ->
          let name, diagram = m.Groups[1].Value, m.Groups[2].Value
          let fence = PlayableNotationFormatter.TryFormatChordDiagramAsMarkdownFence(diagram)
          let body = fence.Replace("\r\n", "\n").Split('\n') |> Array.filter (fun l -> not (l.StartsWith "```"))
          { Id = "beginner-" + slug name
            Source = $"BeginnerChordsSkill {name} {diagram}, PlayableNotationFormatter"
            Text = String.Join("\n", body) } ]

// The example the system prompt shows the model
let promptCase () =
    let lines = PlayableNotationFormatter.PromptGuidance.Replace("\r\n", "\n").Split('\n') |> Array.map (fun l -> l.Trim())
    let start = Array.findIndex (fun (l: string) -> l = "```vextab") lines
    let stop = Array.findIndexBack (fun (l: string) -> l = "```") lines
    [ { Id = "prompt-example"; Source = "PlayableNotationFormatter.PromptGuidance"; Text = String.Join("\n", lines[start + 1 .. stop - 1]) } ]

// The fences GA's front-end tests put in chat messages, deduplicated
let testCases ga =
    [ for file, prefix in
          [ "Apps/ga-client/tests/e2e/vextab-rendering.spec.ts", "e2e"
            "Apps/ga-client/src/test/ChatMessage.test.tsx", "unit"
            "Apps/ga-client/src/test/performance.test.ts", "perf" ] do
          let texts =
              [ for m in Regex.Matches(read ga file, "```vextab\\\\n(.*?)\\\\n```") -> m.Groups[1].Value.Replace("\\n", "\n") ]
              |> List.distinct
          yield! texts |> List.mapi (fun i t -> { Id = $"{prefix}-{i + 1}"; Source = Path.GetFileName file; Text = t }) ]

// The four examples at the end of GA's grammar
let ebnfCases ga =
    [ for m in Regex.Matches(read ga "Common/GA.Business.DSL/Grammars/VexTab.ebnf", "\\(\\* Example (\\d+): [^\\n]*\\n(.*?)\\*\\)", RegexOptions.Singleline) ->
          let body = m.Groups[2].Value.Split('\n') |> Array.map (fun l -> l.Trim()) |> Array.filter ((<>) "")
          { Id = "ebnf-" + m.Groups[1].Value; Source = "VexTab.ebnf"; Text = String.Join("\n", body) } ]

// The course's own probes, one feature each
let courseCases dir =
    [ for f in Directory.GetFiles(dir, "*.vextab") |> Array.sort ->
          { Id = Path.GetFileNameWithoutExtension f; Source = "course"; Text = File.ReadAllText(f).Replace("\r\n", "\n").TrimEnd() } ]

let describe item =
    match item with
    | TabNoteItem n ->
        let fret = match n.Fret with FretNumber f -> string f | Muted -> "X"
        $"fret {fret} on string {n.String}"
    | other -> VexTabGenerator.formatNoteItem other

let firstLines (s: string) = String.Join(" | ", s.Replace("\r\n", "\n").Trim().Split('\n') |> Array.map (fun l -> l.Trim()))

[<EntryPoint>]
let main argv =
    let ga, casesDir, outDir = argv[0], argv[1], argv[2]
    Directory.CreateDirectory outDir |> ignore
    let cases = beginnerCases ga @ promptCase () @ testCases ga @ ebnfCases ga @ courseCases casesDir
    for c in cases do
        File.WriteAllText(Path.Combine(outDir, c.Id + ".vextab"), c.Text + "\n")
        printfn "== %s (%s)" c.Id c.Source
        for line in c.Text.Split('\n') do printfn "   %s" line
        match VexTabParser.parse c.Text with
        | Ok doc ->
            let again = VexTabGenerator.generate doc
            printfn "parse: ok, %d line(s)" doc.Lines.Length
            printfn "generate: %s" (firstLines again)
            File.WriteAllText(Path.Combine(outDir, c.Id + "-generated.vextab"), again + "\n")
            match VexTabParser.parse again with
            | Ok doc2 when doc2 = doc -> printfn "round trip: same document"
            | Ok _ -> printfn "round trip: a different document"
            | Error e -> printfn "round trip: error %s" (firstLines e)
        | Error e -> printfn "parse: error %s" (firstLines e)
        match VexTabParser.parseNotes c.Text with
        | Ok items -> printfn "parseNotes: %s" (String.Join("; ", items |> List.map describe))
        | Error e -> printfn "parseNotes: error %s" (firstLines e)
    printfn "%d cases" cases.Length
    0
