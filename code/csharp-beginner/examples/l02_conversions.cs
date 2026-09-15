// Implicit conversion: no information can be lost
int semitones = 7;
double asDouble = semitones;
Console.WriteLine(asDouble);

// Explicit conversion (a cast): the decimals are cut, not rounded
double hertz = 164.81;
int truncated = (int)hertz;
Console.WriteLine(truncated);

// Rounding: by default, halfway values go to the nearest even number
Console.WriteLine(Math.Round(2.5));
Console.WriteLine(Math.Round(3.5));
Console.WriteLine(Math.Round(2.5, MidpointRounding.AwayFromZero));

// From text to number
int frets = int.Parse("22");
Console.WriteLine(frets + 2);

// TryParse doesn't fail on bad text: it returns false
bool ok = int.TryParse("twenty-two", out int parsed);
Console.WriteLine($"{ok} {parsed}");
ok = int.TryParse("24", out parsed);
Console.WriteLine($"{ok} {parsed}");

// From number to text
string text = frets.ToString();
Console.WriteLine(text + "2");   // + on strings joins them
Console.WriteLine(frets + 2);    // + on numbers adds them
