string? answer = Console.ReadLine();     // no input: ReadLine returns null
string title = answer;                   // a string? goes into a string

Song song = new Song();
Console.WriteLine(song.Title.Length);    // no warning on this line, and yet Title is null

class Song
{
    public string Title { get; set; }    // no constructor sets it
}
