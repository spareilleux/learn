// Reduced from Guitar Alchemist's Scripts/ModesConfig.fsx: the same printfn line, with a list instead of the config file
let names = [ "Major"; "Ionian mode" ]
printfn $"  Alternate Names: %s{String.Join(", ", names)}"
