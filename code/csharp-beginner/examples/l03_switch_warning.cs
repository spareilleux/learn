int stringNumber = 7;

// No arm for 7, and no _ arm: the compiler warns, and the program fails at run time
string open = stringNumber switch
{
    1 => "E4",
    2 => "B3",
    3 => "G3",
    4 => "D3",
    5 => "A2",
    6 => "E2",
};
Console.WriteLine(open);
