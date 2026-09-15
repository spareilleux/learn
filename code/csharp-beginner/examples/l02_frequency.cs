// The open A string vibrates at 110 Hz. Each fret raises the note by a semitone,
// which multiplies the frequency by the 12th root of 2.
double openA = 110.0;
int fret = 7;

double wrong = openA * Math.Pow(2, fret / 12);     // 7 / 12 is an integer division: 0
double right = openA * Math.Pow(2, fret / 12.0);   // 7 / 12.0 is 0.5833...

Console.WriteLine($"Fret {fret}, wrong: {wrong} Hz");
Console.WriteLine($"Fret {fret}, right: {right} Hz");
Console.WriteLine($"Rounded: {right:F2} Hz");
Console.WriteLine($"Fret 12: {openA * Math.Pow(2, 12 / 12.0)} Hz");
