let normalize (pc: int) = ((pc % 12) + 12) % 12
let transpose (interval: int) (pc: int) = normalize (pc + interval)

let g = transpose(7, 0)
