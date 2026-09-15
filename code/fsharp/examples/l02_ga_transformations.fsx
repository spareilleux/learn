// Guitar Alchemist's HarmonicTransformationService, loaded from the copies in external/ga
#load "../external/ga/MusicalSetTypes.fs" "../external/ga/HarmonicTransformationService.fs"

open GA.Business.DSL.Services

let service = HarmonicTransformationService()
let cMajor = set [ 0; 4; 7 ] // C E G

printfn "%A" (service.Transpose 7 cMajor) // up a fifth: G B D

let upAFifth = service.Transpose 7 // a method with curried parameters can be partially applied
printfn "%A" (cMajor |> upAFifth |> upAFifth) // D F# A

printfn "%A" (service.Invert 0 cMajor) // mirrored around C: C F Ab

// Compiled, the curried member is an ordinary .NET method with two parameters: C# calls Transpose(2, set)
let transpose = typeof<HarmonicTransformationService>.GetMethod "Transpose"

for parameter in transpose.GetParameters() do
    printfn "%s %s" parameter.ParameterType.Name parameter.Name

// A normal form must be the same for a chord and for any transposition of it
let chord = set [ 0; 4; 7; 8 ]
printfn "%A" (service.GetNormalForm chord)
printfn "%A" (service.GetNormalForm(service.Transpose 8 chord))
