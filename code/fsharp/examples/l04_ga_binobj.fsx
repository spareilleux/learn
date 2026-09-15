// Guitar Alchemist's Scripts/BinObj.fsx defines a function that lists the bin and obj folders of a source tree
#load "../external/ga/BinObj.fsx"

open System
open System.IO
open BinObj

// A small tree in the temporary folder
let root = Path.Combine(Path.GetTempPath(), $"fsharp-course-binobj-{Environment.ProcessId}")

for folder in [ "App/bin"; "App/obj"; "App/src"; "Docs/cabin"; "Robin/Songs"; "Empty" ] do
    Directory.CreateDirectory(Path.Combine(root, folder)) |> ignore

for path in getFoldersToDelete root |> List.sort do
    printfn "%s" (Path.GetRelativePath(root, path).Replace('\\', '/'))

Directory.Delete(root, true)
