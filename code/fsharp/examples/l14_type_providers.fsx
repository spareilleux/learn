#r "nuget: FSharp.Data, 8.2.0"

open FSharp.Data

type Voicings =
    CsvProvider<"""name,strings,frets
C major,6,x32010
D minor,6,xx0231""">

let voicings = Voicings.GetSample()

for row in voicings.Rows do
    printfn "%s: %d strings, frets %s" row.Name row.Strings row.Frets

type GovernanceNode =
    JsonProvider<"""{
      "id": "ga.chord-parser",
      "health": { "resilienceScore": 0.98 },
      "tags": ["music", "dsl"]
    }""">

let node = GovernanceNode.GetSample()
printfn "%s: %.2f [%s]" node.Id node.Health.ResilienceScore (String.concat ", " node.Tags)
