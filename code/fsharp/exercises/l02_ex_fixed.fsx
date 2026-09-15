let mutable capo = 2
capo <- 3
let ratio = 2.0 ** (float capo / 12.0)
let label = if capo = 0 then "no capo" else $"capo on fret {capo}"

printfn "%s: frequencies multiplied by %.4f" label ratio
