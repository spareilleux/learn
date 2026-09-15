let normalize pc = ((pc % 12) + 12) % 12
let transpose interval pc = normalize (pc + interval)

printfn "%d" (transpose - 1 0)
