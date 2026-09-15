let direction interval =
    match interval with
    | n when n > 0 -> "up"
    | n when n < 0 -> "down"
    | n when n = 0 -> "same note"

printfn "%s %s %s" (direction 5) (direction -2) (direction 0)
