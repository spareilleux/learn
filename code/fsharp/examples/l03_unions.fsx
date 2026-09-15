// A discriminated union: a value is exactly one of the cases
type Accidental =
    | Natural
    | Sharp
    | Flat

// Each case can carry its own data
type Fingering =
    | Open
    | Fretted of fret: int
    | Barre of fret: int * strings: int
    | Muted

// C major, from the low E string to the high E string: x32010
let cMajor = [ Muted; Fretted 3; Fretted 2; Open; Fretted 1; Open ]
printfn "%A" cMajor

let fMajor = Barre(fret = 1, strings = 6) // named fields
printfn "%A" fMajor
printfn "%b %b" (Fretted 3 = Fretted 3) (Sharp = Flat)
