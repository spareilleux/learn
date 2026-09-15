let normalize pc = ((pc % 12) + 12) % 12

// Semitones to go up from one pitch class to another
let interval fromPc toPc = normalize (toPc - fromPc)

let fromE = interval 4 // partial application: int -> int

printfn "E up to G: %d semitones" (fromE 7)
printfn "E up to C: %d semitones" (fromE 0)
printfn "E up to E: %d semitones" (4 |> fromE)
