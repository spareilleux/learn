// compare/l02_values.cs
// Boxing an int creates a new object every time: == on object compares references
object small = 100, alsoSmall = 100;
object big = 1000, alsoBig = 1000;
Console.WriteLine($"{small == alsoSmall} {small.Equals(alsoSmall)}");
Console.WriteLine($"{big == alsoBig} {big.Equals(alsoBig)}");

// The compiler converts the int to text
int quantity = 3;
Console.WriteLine("quantity: " + quantity);
