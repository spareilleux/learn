#load "../external/ga/ChordAst.fs" "../external/ga/ChordRenderer.fs"

open GA.Business.DSL.Types
open GA.Business.DSL.Generators

// Record patterns name only the fields they test
let family (chord: ChordAst) =
    match chord with
    | { Quality = Some Diminished } -> "diminished"
    | { Quality = Some Minor; Components = [ Extension "7"; Alteration(Flat, "5") ] } -> "half-diminished"
    | { Quality = Some Minor } -> "minor"
    | { Quality = None; Components = Extension "7" :: _ } -> "dominant seventh"
    | { Quality = (None | Some Major) } -> "major"
    | _ -> "other"

let chord root quality components =
    { Root = root; RootAccidental = Natural; Quality = quality; Components = components; Bass = None }

let chords =
    [ chord "B" (Some Diminished) []
      chord "B" (Some Minor) [ Extension "7"; Alteration(Flat, "5") ]
      chord "A" (Some Minor) [ Extension "7" ]
      chord "G" None [ Extension "7"; Alteration(Flat, "9") ]
      chord "C" None [ Extension "maj7" ]
      chord "D" (Some Suspended) [ Extension "4" ] ]

for c in chords do
    printfn "%-8s %s" (ChordRenderer.render c) (family c)
