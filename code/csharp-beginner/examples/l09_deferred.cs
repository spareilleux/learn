// A query runs when it is read, not when it is written; ToList keeps the result of one run
List<int> frets = [0, 3, 5, 7];

IEnumerable<int> high = frets.Where(f => f >= 5);
List<int> highNow = frets.Where(f => f >= 5).ToList();

frets.Add(12);

Console.WriteLine($"query:  {string.Join(" ", high)}");
Console.WriteLine($"ToList: {string.Join(" ", highNow)}");
