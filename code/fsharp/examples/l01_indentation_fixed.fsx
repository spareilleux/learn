let describe name =
    let label = name + " major"
    label   // the last expression of the block is the result of the function

printfn "%s" (describe "C")
