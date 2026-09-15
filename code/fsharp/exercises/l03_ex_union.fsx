type Technique =
    | Picked
    | HammerOn of fromFret: int * toFret: int
    | Slide of fromFret: int * toFret: int
    | Bend of semitones: float

let lick = [ Picked; HammerOn(5, 7); Slide(fromFret = 7, toFret = 9); Bend 1.0 ]
printfn "%A" lick
printfn "%b" (Slide(7, 9) = Slide(9, 7))
