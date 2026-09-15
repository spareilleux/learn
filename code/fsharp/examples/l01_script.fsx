// A script runs from top to bottom, like the top-level statements of a C# file
let tuning = "E2 A2 D3 G3 B3 E4"   // let gives a name to a value
let strings = 6

printfn "Guitar Alchemist tunes a guitar like this: %s" tuning
printfn "%d strings, %d frets each" strings 22

// Interpolated strings: {expression}, or %d{expression} to check the type too
printfn $"{strings} strings x 22 frets = {strings * 22} positions"
printfn $"%d{strings} strings"

// %A prints any value the way F# writes it
printfn "%A" [ "E2"; "A2"; "D3"; "G3"; "B3"; "E4" ]
