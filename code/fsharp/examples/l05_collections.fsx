let openStrings = [ 40; 45; 50; 55; 59; 64 ]
let upTwoFrets = openStrings |> List.map ((+) 2)
printfn "list: %A" upTwoFrets

let mutablePitches = openStrings |> List.toArray
mutablePitches[1] <- 46
printfn "array: %A" mutablePitches

let mutable evaluated = 0
let chromatic =
    seq {
        for pitch in 40 .. 44 do
            evaluated <- evaluated + 1
            yield pitch
    }

printfn "before Seq.take: %d" evaluated
printfn "first three: %A" (chromatic |> Seq.take 3 |> Seq.toList)
printfn "after Seq.take: %d" evaluated

let playedFrets = [ Some 0; None; Some 7; Some 9 ]
printfn "played: %A" (playedFrets |> List.choose id)

