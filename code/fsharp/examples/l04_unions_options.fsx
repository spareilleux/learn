type Fingering =
    | Open
    | Fretted of fret: int
    | Barre of fret: int * strings: int
    | Muted

let describe fingering =
    match fingering with
    | Open -> "open string"
    | Muted -> "not played"
    | Fretted 1 -> "first fret" // a case with a constant inside
    | Fretted fret -> $"fret {fret}" // a case that binds its data
    | Barre(fret, 6) -> $"full barre on fret {fret}"
    | Barre(fret = f; strings = n) -> $"barre on fret {f} across {n} strings" // by field name

for fingering in [ Open; Muted; Fretted 1; Fretted 5; Barre(1, 6); Barre(3, 4) ] do
    printfn "%s" (describe fingering)

// Option is a union too: Some and None are its cases
let capoLabel capo =
    match capo with
    | None
    | Some 0 -> "no capo"
    | Some fret -> $"capo on fret {fret}"

printfn "%s, %s, %s" (capoLabel None) (capoLabel (Some 0)) (capoLabel (Some 2))

// function is fun x -> match x with, as in Guitar Alchemist's ChordRenderer
let isPlayed =
    function
    | Muted -> false
    | _ -> true

printfn "%b %b" (isPlayed Muted) (isPlayed (Fretted 3))
