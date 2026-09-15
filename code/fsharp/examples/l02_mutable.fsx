// mutable opts in to assignment, and <- assigns
let mutable total = 0

for fret in 1..12 do
    total <- total + fret

printfn "Frets 1 to 12 add up to %d" total
