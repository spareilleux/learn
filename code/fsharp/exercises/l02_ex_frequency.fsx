// Equal temperament: each semitone multiplies the frequency by 2^(1/12), and A4 is 440 Hz
let frequency semitonesFromA4 = 440.0 * 2.0 ** (float semitonesFromA4 / 12.0)

printfn "A4 = %.2f Hz" (frequency 0)
printfn "E4 = %.2f Hz" (frequency -5)
printfn "E2 = %.2f Hz" (frequency -29)
