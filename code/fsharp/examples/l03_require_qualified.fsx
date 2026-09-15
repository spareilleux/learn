// RequireQualifiedAccess: the cases must be written PartialFailure.Warning and PartialFailure.Error
[<RequireQualifiedAccess>]
type PartialFailure =
    | Warning of message: string
    | Error of message: string

let checkFret fret : Result<int, string> =
    if fret >= 0 then Ok fret else Error "negative fret" // Error is Result's case again

printfn "%A" (checkFret 3)
printfn "%A" (checkFret -1)
printfn "%A" (PartialFailure.Warning "low confidence")
