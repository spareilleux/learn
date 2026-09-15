// Option: Some value, or None, instead of null
let capo: int option = Some 2
let noCapo: int option = None

let describe capo =
    capo
    |> Option.map (fun fret -> $"capo on fret {fret}")
    |> Option.defaultValue "no capo"

printfn "%s, %s" (describe capo) (describe noCapo)
printfn "%A %A" capo noCapo

// A .NET method may return null: Option.ofObj turns it into None
let variable = System.Environment.GetEnvironmentVariable "FSHARP_COURSE_VARIABLE_THAT_IS_NOT_SET"
printfn "%A" (Option.ofObj variable)
