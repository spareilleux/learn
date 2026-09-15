// A tuple groups values without declaring a type: here string * int
let lowString = ("E", 2)
printfn "%A" lowString
printfn "%s" (fst lowString)

// Deconstruction, like var (note, octave) = ... in C#
let (note, octave) = lowString
printfn "%s%d" note octave

// A function returns several values in a tuple
let octavesAndSemitones interval = (interval / 12, interval % 12)
let octaves, semitones = octavesAndSemitones 29 // the parentheses are optional
printfn "29 semitones = %d octaves and %d semitones" octaves semitones

// F# tuples are System.Tuple objects; struct tuples are System.ValueTuple, the tuples of C#
let structTuple = struct ("A", 4)
printfn "%s and %s" (lowString.GetType().Name) (structTuple.GetType().Name)
