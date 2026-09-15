let label (name: string) =
    let name = name.Trim() // a new value that hides the parameter
    let name = name.ToUpperInvariant() // and another one
    $"[{name}]"

printfn "%s" (label "  e minor ")
