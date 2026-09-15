type Tuning = { Name: string; Notes: string list; Capo: int option }

let standard = { Name = "Standard"; Notes = [ "E2"; "A2"; "D3"; "G3"; "B3"; "E4" ]; Capo = None }
let dropD = { standard with Name = "Drop D"; Notes = [ "D2"; "A2"; "D3"; "G3"; "B3"; "E4" ] }
let capoOn2 = { standard with Capo = Some 2 }

printfn "%A" dropD
printfn "%b" (capoOn2 = { standard with Capo = Some 2 })
printfn "%b" (standard.Notes = capoOn2.Notes)
