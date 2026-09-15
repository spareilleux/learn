// A script can reference a NuGet package: dotnet fsi downloads it on the first run
#r "nuget: FParsec, 1.1.1"

open FParsec

// FParsec is the parser library of Guitar Alchemist's music DSL (lesson 11)
printfn "%A" (run pint32 "22")
printfn "%A" (run pint32 "twenty-two")
