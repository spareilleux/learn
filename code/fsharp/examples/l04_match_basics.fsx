// match tries the patterns from top to bottom; the first one that fits wins
let intervalName semitones =
    match semitones with
    | 0 -> "unison"
    | 3 | 4 -> "third" // or-pattern
    | 7 -> "perfect fifth"
    | 12 -> "octave"
    | n when n > 12 -> $"compound interval ({n - 12} above an octave)" // guard
    | _ -> "other" // wildcard

for semitones in [ 0; 4; 7; 10; 19 ] do
    printfn "%d: %s" semitones (intervalName semitones)

// A tuple matches several values at once
let position (stringNumber, fret) =
    match stringNumber, fret with
    | _, 0 -> "open string"
    | (5 | 6), f -> $"bass string, fret {f}"
    | s, f -> $"string {s}, fret {f}"

printfn "%s" (position (6, 0))
printfn "%s" (position (5, 3))
printfn "%s" (position (2, 1))
