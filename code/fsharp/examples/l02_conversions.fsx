let semitones = 7
let ratio = 2.0 ** (float semitones / 12.0) // float converts explicitly

printfn "A fifth multiplies the frequency by %.4f" ratio
printfn "A2 = 110 Hz, so E3 = %.2f Hz" (110.0 * ratio)

printfn "%d" (int 3.99) // int truncates, like a cast in C#
printfn "%s" (string 440) // string calls ToString
printfn "%d" (int "22") // int also parses a string, and throws if it can't
