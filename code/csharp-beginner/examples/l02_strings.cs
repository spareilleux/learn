string note = "A";
int octave = 4;
double frequency = 440;

// Interpolation: $ before the quotes, expressions between braces
Console.WriteLine($"{note}{octave} vibrates at {frequency} Hz");
Console.WriteLine($"One octave higher: {frequency * 2} Hz");

// Format and alignment: {value,width:format}
Console.WriteLine($"[{note,-5}] [{octave,5}] [{frequency,8:F1}]");
Console.WriteLine($"{1234567.891:N2}");

// A few string methods
string model = "Les Paul";
Console.WriteLine(model.Length);
Console.WriteLine(model.ToUpper());
Console.WriteLine(model.Contains("Paul"));
Console.WriteLine(model.Replace("Paul", "Standard"));
Console.WriteLine(model[0]);          // the first character: a char

// Special characters
Console.WriteLine("Tab:\tafter\nNew line, and a quote: \"");
Console.WriteLine(@"C:\Users\ada\music");     // verbatim: \ is just a character
Console.WriteLine("""
    A raw string literal keeps "quotes"
    and line breaks as they are.
    """);
