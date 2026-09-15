module Fretboard

// Uses Tuning, which Hello.fsproj lists after this file
let positions frets = Tuning.strings * (frets + 1)
