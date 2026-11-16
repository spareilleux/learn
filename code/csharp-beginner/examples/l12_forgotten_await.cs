Console.WriteLine("Before");
WriteLater();   // no await: the program goes on without waiting
Console.WriteLine("After");

async Task WriteLater()
{
    await Task.Delay(100);
    Console.WriteLine("Later");
}
