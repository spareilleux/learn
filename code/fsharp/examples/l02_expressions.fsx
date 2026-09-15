// if/then/else is an expression: it has a value, like C#'s ?: operator
let fretLabel fret = if fret = 0 then "open" else $"fret {fret}"
printfn "%s, %s" (fretLabel 0) (fretLabel 3)

// A block is an expression too: its value is its last line
let positions =
    let strings = 6
    let frets = 22
    strings * (frets + 1)

printfn "%d positions, open strings included" positions

// Functions that only have an effect return unit, written ()
let nothing = printfn "printfn returns unit"
printfn "%A" nothing
