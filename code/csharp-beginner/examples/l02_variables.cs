// A variable is a named box that holds a value of one type
int strings = 6;
string tuning = "E A D G B E";
double scaleLength = 64.8;     // centimetres, a common guitar scale length
bool isAcoustic = true;
char lowest = 'E';

Console.WriteLine(strings);
Console.WriteLine(tuning);
Console.WriteLine(scaleLength);
Console.WriteLine(isAcoustic);
Console.WriteLine(lowest);

// The value can change; the type can't
strings = 7;
Console.WriteLine(strings);

// var: the compiler infers the type from the value
var frets = 22;                // int
var name = "Stratocaster";     // string
Console.WriteLine(frets.GetType());
Console.WriteLine(name.GetType());

// const: a value that never changes
const int SemitonesPerOctave = 12;
Console.WriteLine(SemitonesPerOctave * 2);
