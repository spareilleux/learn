module Music =
    module Pitch =
        let private normalize pitchClass = ((pitchClass % 12) + 12) % 12

        let name pitchClass =
            [| "C"; "C#"; "D"; "Eb"; "E"; "F"; "F#"; "G"; "Ab"; "A"; "Bb"; "B" |]
            |> Array.item (normalize pitchClass)

    module Chord =
        type Quality = Major | Minor

        let symbol root quality =
            Pitch.name root + if quality = Minor then "m" else ""

printfn "%s" (Music.Pitch.name -1)
printfn "%s" (Music.Chord.symbol 0 Music.Chord.Major)
printfn "%s" (Music.Chord.symbol 9 Music.Chord.Minor)

module Reporting =
    let internal formatCount count = $"{count} notes"

printfn "%s" (Reporting.formatCount 6)

