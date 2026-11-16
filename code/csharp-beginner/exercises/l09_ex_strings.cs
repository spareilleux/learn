// Exercise 3: remove the E strings without changing the list inside its own foreach
List<string> strings = ["E2", "A2", "D3", "G3", "B3", "E4"];

// RemoveAll takes a lambda and removes every item for which it returns true
List<string> first = new List<string>(strings);
first.RemoveAll(s => s.StartsWith("E"));
Console.WriteLine(string.Join(" ", first));

// Or build a new list with Where, and keep the original
List<string> second = strings.Where(s => !s.StartsWith("E")).ToList();
Console.WriteLine(string.Join(" ", second));
Console.WriteLine(string.Join(" ", strings));
