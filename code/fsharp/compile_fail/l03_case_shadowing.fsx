// Reduced from TARS (v2/src/Tars.Core/Domain.fs): a union with a case named Error
type PartialFailure =
    | Warning of message: string
    | Error of message: string

let checkFret fret : Result<int, string> =
    if fret >= 0 then Ok fret else Error "negative fret"
