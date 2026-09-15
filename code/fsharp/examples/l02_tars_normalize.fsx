open System
open System.Text.RegularExpressions

// TextNormalizer.normalize from TARS (v2/src/Tars.Core/TextNormalizer.fs, lines 51-58 at commit 87464ce), retyped
let normalize (text: string) =
    if String.IsNullOrWhiteSpace(text) then
        ""
    else
        text.ToLowerInvariant()
        |> fun s -> Regex.Replace(s, @"[^a-z0-9\s]", "") // Keep only alphanumeric and space
        |> fun s -> Regex.Replace(s, @"\s+", " ") // Collapse multiple spaces
        |> fun s -> s.Trim()

printfn "[%s]" (normalize "  How do I   learn F#? ")
printfn "[%s]" (normalize "C# and F# on .NET 10")
printfn "[%s]" (normalize "Qu'est-ce qu'un café ? ¿Qué es un acorde?")
