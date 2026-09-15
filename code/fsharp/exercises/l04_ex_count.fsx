#r "nuget: FParsec, 1.1.1"
#load "../external/ga/ChordAst.fs" "../external/ga/ChordParser.fs"

open GA.Business.DSL.Types
open GA.Business.DSL.Parsers

let rec countAlterations components =
    match components with
    | [] -> 0
    | (Alteration _ | Alt) :: rest -> 1 + countAlterations rest
    | _ :: rest -> countAlterations rest

// The chord of GA's test Test_Complex_Alterations (Tests/Common/GA.Business.DSL.Tests/ChordDslTests.cs)
match ChordParser.parse "C13#11b9" with
| Ok chord -> printfn "%A: %d alterations" chord.Components (countAlterations chord.Components)
| Error message -> printfn "%s" message
