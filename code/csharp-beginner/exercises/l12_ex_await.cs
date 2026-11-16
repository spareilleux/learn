// Exercise 3: the forgotten await, fixed
Console.WriteLine("Before");
await WriteLater();   // the program waits here until WriteLater has finished
Console.WriteLine("After");

async Task WriteLater()
{
    await Task.Delay(100);
    Console.WriteLine("Later");
}
