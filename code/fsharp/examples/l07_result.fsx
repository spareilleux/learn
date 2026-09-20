open System

type Fret = private Fret of int

module Fret =
    let create value =
        if value >= 0 && value <= 24 then Ok (Fret value)
        else Error $"fret {value} is outside 0..24"

    let value (Fret value) = value

let parseInt (text: string) =
    match Int32.TryParse text with
    | true, value -> Ok value
    | false, _ -> Error $"'{text}' is not an integer"

let parseFret text =
    text |> parseInt |> Result.bind Fret.create

for input in [ "3"; "-1"; "x" ] do
    match parseFret input with
    | Ok fret -> printfn "OK %s -> %d" input (Fret.value fret)
    | Error message -> printfn "ERROR %s -> %s" input message

let addFrets left right =
    match parseFret left, parseFret right with
    | Ok leftFret, Ok rightFret -> Ok (Fret.value leftFret + Fret.value rightFret)
    | Error message, _
    | _, Error message -> Error message

printfn "sum: %A" (addFrets "3" "7")
