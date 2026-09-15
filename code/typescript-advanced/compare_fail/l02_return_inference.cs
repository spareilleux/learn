// compare_fail/l02_return_inference.cs
List<string> chords = EmptyList();
Console.WriteLine(chords.Count);

static List<T> EmptyList<T>() => [];
