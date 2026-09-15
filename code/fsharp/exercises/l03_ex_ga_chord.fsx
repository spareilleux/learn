#load "../external/ga/ChordAst.fs" "../external/ga/ChordRenderer.fs"

open GA.Business.DSL.Types
open GA.Business.DSL.Generators

let bFlatMajor7OverD =
    { Root = "B"
      RootAccidental = Flat
      Quality = None
      Components = [ Extension "maj7" ]
      Bass = Some("D", Natural) }

let eAugmented = { bFlatMajor7OverD with Root = "E"; RootAccidental = Natural; Quality = Some Augmented; Components = []; Bass = None }

printfn "%s" (ChordRenderer.render bFlatMajor7OverD)
printfn "%s" (ChordRenderer.render eAugmented)

// The same chord written with a quality: same text, different tree
let withQuality = { bFlatMajor7OverD with Quality = Some Major; Components = [ Extension "7" ] }
printfn "%s %b" (ChordRenderer.render withQuality) (withQuality = bFlatMajor7OverD)
