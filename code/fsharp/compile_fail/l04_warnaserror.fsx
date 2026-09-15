// check.sh args: --warnaserror+:25
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
