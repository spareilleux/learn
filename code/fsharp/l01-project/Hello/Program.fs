// For more information see https://aka.ms/fsharp-console-apps
printfn "Hello from F#"

// Program.fs is the last file of Hello.fsproj: it sees Tuning.fs, listed above it
printfn "%s" (Tuning.describe "Standard")
