// Lesson 17: what GA's NeoRiemannianConfig returns once built, whichever way its three YAML records are declared
open GA.Business.Config

[<EntryPoint>]
let main _ =
    let transforms = NeoRiemannianConfig.GetAllTransforms() |> Seq.toList
    printfn "transforms %d, hexatonic cycles %d, octatonic cycles %d"
        transforms.Length (Seq.length (NeoRiemannianConfig.GetHexatonicCycles())) (Seq.length (NeoRiemannianConfig.GetOctatonicCycles()))
    for t in transforms do
        printfn "%s: %d mappings, cost %d" t.Name t.Mappings.Count t.VoiceLeadingCost
    for transform, triad in [ "P", "C_maj"; "L", "G#_maj"; "S", "C_maj"; "P", "Db_maj"; "p", "C_maj"; "PL", "C_maj" ] do
        printfn "Apply \"%s\" \"%s\" -> %A" transform triad (NeoRiemannianConfig.Apply transform triad)
    0
