string[] strings = ["E2", "A2", "D3", "G3", "B3", "E4"];
for (int i = 0; i <= strings.Length; i++)     // <= goes one step too far
{
    Console.WriteLine($"{i}: {strings[i]}");
}
