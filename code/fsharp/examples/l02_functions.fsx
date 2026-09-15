// Pitch classes: 0 = C, 1 = C#, ..., 11 = B. Guitar Alchemist's HarmonicTransformationService uses this formula.
let normalize pc = ((pc % 12) + 12) % 12
printfn "%d %d" (-5 % 12) (normalize -5) // % keeps the sign, normalize doesn't

// Two parameters separated by spaces: transpose has the type int -> int -> int
let transpose interval pc = normalize (pc + interval)

let names = [| "C"; "C#"; "D"; "D#"; "E"; "F"; "F#"; "G"; "G#"; "A"; "A#"; "B" |]
let name pc = names[pc]

printfn "%s" (name (transpose 7 0))

// Partial application: give only the first argument, get a function back
let upAFifth = transpose 7
printfn "%s %s %s" (name (upAFifth 0)) (name (upAFifth 7)) (name (upAFifth 2))

// A negative number argument: the minus sign touches the number
printfn "%s" (name (transpose -1 0))

// Pipeline: x |> f is f x
printfn "%s" (0 |> upAFifth |> upAFifth |> upAFifth |> name)

// Composition: f >> g is fun x -> g (f x)
let fifthName = upAFifth >> name
printfn "%s" (fifthName 9)

// Lambda: fun pc -> ... is C#'s pc => ...
let downASemitone = fun pc -> transpose -1 pc
printfn "%s" (name (downASemitone 0))
