// Step 2: a triple-quoted interpolated string may contain "..." in its expressions
let names = [ "Major"; "Ionian mode" ]
printfn $"""  Alternate Names: %s{String.Join(", ", names)}"""
