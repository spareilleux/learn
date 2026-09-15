// Integers: the division drops the decimals
Console.WriteLine(7 / 2);
Console.WriteLine(7 % 2);      // the remainder
Console.WriteLine(7 / 2.0);    // one double in the operation: the result is a double

// Each integer type has a range; int goes from about -2.1 billion to 2.1 billion
Console.WriteLine(int.MaxValue);
int big = int.MaxValue;
big = big + 1;                 // wraps around without an error
Console.WriteLine(big);
Console.WriteLine(long.MaxValue);

// double is fast but approximate: 0.1 has no exact binary form
Console.WriteLine(0.1 + 0.2);
Console.WriteLine(0.1 + 0.2 == 0.3);

// decimal is exact for decimal fractions: use it for money
Console.WriteLine(0.1m + 0.2m);
Console.WriteLine(0.1m + 0.2m == 0.3m);
decimal price = 19.99m;
Console.WriteLine(price * 3);
