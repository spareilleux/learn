// Step 3: String.Join is System.String.Join, so the script needs open System
open System

let names = [ "Major"; "Ionian mode" ]
printfn $"""  Alternate Names: %s{String.Join(", ", names)}"""
