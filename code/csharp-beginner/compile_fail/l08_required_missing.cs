Song song = new Song();
Console.WriteLine(song.Title);

class Song
{
    public required string Title { get; init; }
}
