// Guitar Alchemist's chord AST and renderer, loaded from the copies in external/ga
#load "../external/ga/ChordAst.fs" "../external/ga/ChordRenderer.fs"

open GA.Business.DSL.Types
open GA.Business.DSL.Generators

// F#m7b5/C as a value of GA's ChordAst record
let halfDiminished =
    { Root = "F"
      RootAccidental = Sharp
      Quality = Some Minor
      Components = [ Extension "7"; Alteration(Flat, "5") ]
      Bass = Some("C", Natural) }

printfn "%s" (ChordRenderer.render halfDiminished)
printfn "%A" halfDiminished

let c = { Root = "C"; RootAccidental = Natural; Quality = None; Components = []; Bass = None }
printfn "%s" (ChordRenderer.render c)
printfn "%s" (ChordRenderer.render { c with Quality = Some Major; Components = [ Extension "9" ] })
