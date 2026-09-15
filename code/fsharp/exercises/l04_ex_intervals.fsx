let quality semitones =
    match semitones with
    | n when n < 0 -> "negative: turn it into an upward interval first"
    | 0
    | 5
    | 7
    | 12 -> "perfect"
    | 1
    | 3
    | 8
    | 10 -> "minor"
    | 2
    | 4
    | 9
    | 11 -> "major"
    | 6 -> "tritone"
    | _ -> "compound: larger than an octave"

for semitones in [ -3; 0; 3; 4; 6; 7; 11; 14 ] do
    printfn "%3d: %s" semitones (quality semitones)
