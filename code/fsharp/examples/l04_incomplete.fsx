type Accidental =
    | Natural
    | Sharp
    | Flat
    | DoubleSharp
    | DoubleFlat

let symbol accidental =
    match accidental with
    | Natural -> ""
    | Sharp -> "#"
    | Flat -> "b"

printfn "C%s" (symbol Sharp)
printfn "C%s" (symbol DoubleFlat)
printfn "never printed"
