let restring () =
    let mutable strings = 6
    strings = 7 // = compares: this line computes false and drops it
    printfn "%d strings" strings

restring ()
