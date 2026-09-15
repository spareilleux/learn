// Exercise 1: FizzBuzz from 1 to 15, with a switch expression on two remainders
for (int i = 1; i <= 15; i++)
{
    string text = (i % 3, i % 5) switch
    {
        (0, 0) => "FizzBuzz",
        (0, _) => "Fizz",
        (_, 0) => "Buzz",
        _ => i.ToString(),
    };
    Console.Write($"{text} ");
}
Console.WriteLine();
