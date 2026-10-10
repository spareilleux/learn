using System.Diagnostics;

// await: the program waits for the file without blocking its thread
string[] lines = await File.ReadAllLinesAsync(Path.Combine("data", "ga-projects.csv"));
Console.WriteLine($"{lines.Length - 1} projects");

// Two waits of half a second, one after the other
var watch = Stopwatch.StartNew();
await Task.Delay(500);
await Task.Delay(500);
Console.WriteLine($"One after the other, at least 1 s: {watch.ElapsedMilliseconds >= 1000}");

// The same two waits started together: Task.WhenAll finishes when both are done
watch.Restart();
Task first = Task.Delay(500);
Task second = Task.Delay(500);
await Task.WhenAll(first, second);
Console.WriteLine($"Together, under 0.9 s: {watch.ElapsedMilliseconds < 900}");
