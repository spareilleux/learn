let intervalName semitones =
    match semitones with
    | 0 -> "unison"
    | _ -> "other"
    | 7 -> "perfect fifth"

printfn "%s" (intervalName 7)
