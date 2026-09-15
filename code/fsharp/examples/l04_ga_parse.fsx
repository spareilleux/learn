#r "nuget: FParsec, 1.1.1"
#load "../external/ga/ChordAst.fs" "../external/ga/ChordRenderer.fs" "../external/ga/ChordParser.fs"

open GA.Business.DSL.Parsers
open GA.Business.DSL.Generators

// Guitar Alchemist's ChordParser.parse returns a Result: Ok with the AST, or Error with FParsec's message
let normalize (input: string) =
    match ChordParser.parse input with
    | Ok ast -> $"{input} -> {ChordRenderer.render ast}"
    | Error message -> $"{input} -> error:\n{message}"

for input in [ "Cmi7"; "EbΔ9"; "F#m7b5/C"; "C7sus4"; "Am(maj7)"; "H7" ] do
    printfn "%s" (normalize input)
