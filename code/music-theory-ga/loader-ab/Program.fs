// Lesson 17: what GA's NeoRiemannianConfig returns once built, whichever way its three YAML records are declared
open GA.Business.Config

[<EntryPoint>]
let main _ =
    let transforms = NeoRiemannianConfig.GetAllTransforms() |> Seq.toList
    printfn "transforms %d, hexatonic cycles %d, octatonic cycles %d"
        transforms.Length (Seq.length (NeoRiemannianConfig.GetHexatonicCycles())) (Seq.length (NeoRiemannianConfig.GetOctatonicCycles()))
    for t in transforms do
        printfn "%s: %d mappings, cost %d" t.Name t.Mappings.Count t.VoiceLeadingCost
    // the requests of the lesson's second prediction: the file's own spellings, then names and words it does not write
    for transform, triad in
        [ "P", "C_maj"; "P", "C#_maj"; "L", "G#_maj"; "S", "C_maj"
          "P", "Db_maj"; "P", "Ab_maj"; "P", "c_maj"; "P", "C"; "P", "C major"; "p", "C_maj"; "PL", "C_maj"; "LPR", "C_maj" ] do
        printfn "Apply \"%s\" \"%s\" -> %A" transform triad (NeoRiemannianConfig.Apply transform triad)
    for name in [ "H"; "h"; "Hexatonic pole"; "PL" ] do
        let found = NeoRiemannianConfig.TryGetTransform name |> Option.map (fun t -> t.Name)
        printfn "TryGetTransform \"%s\" -> %A" name found
    0
