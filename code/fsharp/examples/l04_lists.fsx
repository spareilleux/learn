// List patterns: [] is the empty list, head :: tail splits off the first element
let describeStrings strings =
    match strings with
    | [] -> "no strings"
    | [ single ] -> $"only {single}"
    | [ low; high ] -> $"{low} and {high}"
    | lowest :: rest -> $"{lowest}, then {List.length rest} more"

printfn "%s" (describeStrings [])
printfn "%s" (describeStrings [ "G4" ])
printfn "%s" (describeStrings [ "C4"; "G4" ])
printfn "%s" (describeStrings [ "E2"; "A2"; "D3"; "G3"; "B3"; "E4" ])

// A recursive function (rec) walks the list one element at a time
let rec total frets =
    match frets with
    | [] -> 0
    | fret :: rest -> fret + total rest

printfn "%d" (total [ 3; 2; 0; 1; 0 ])

// Patterns also work in let and in parameters
let (note, octave) = ("A", 4)
let lowest (first :: _) = first // warning: [] is not handled
printfn "%s%d %s" note octave (lowest [ "E2"; "A2" ])
