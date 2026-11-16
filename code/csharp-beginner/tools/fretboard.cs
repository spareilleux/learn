// Draws the fretboard diagram of lesson 3: the notes of frets 0 to 5 in standard tuning, string 6 at the top,
// as l03_fretboard.cs prints them. The diagram has no words, so the three locales share it.
//   dotnet run tools/fretboard.cs             writes src/assets/csharp-beginner/l03-fretboard.svg
//   dotnet run tools/fretboard.cs -- --check  exits 1 if the committed file differs (check.sh runs it)
// Every coordinate is an int: a double would print 2,5 instead of 2.5 under a French culture.
using System.Text;

string[] names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];
int[] open = [4, 9, 2, 7, 11, 4];        // semitones above C of strings 6, 5, 4, 3, 2 and 1: E A D G B E
const int Frets = 5;
const int Left = 40, Top = 24, OpenWidth = 48, FretWidth = 60, StringGap = 32;
int nut = Left + OpenWidth;
int width = nut + Frets * FretWidth + 12;
int bottom = Top + 5 * StringGap;
int height = bottom + 40;

var svg = new StringBuilder();
svg.Append($"<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 {width} {height}\" width=\"{width}\" height=\"{height}\" style=\"max-width:100%;height:auto;font-family:var(--sl-font-system, system-ui, sans-serif)\">\n");

// Strings, thickest at the top (string 6), with their number on the left
for (int row = 0; row < 6; row++)
{
    int y = Top + row * StringGap;
    int thickness = 30 - 3 * row;        // tenths of a pixel: 3.0 for string 6 down to 1.5 for string 1
    svg.Append($"  <line x1=\"{Left}\" y1=\"{y}\" x2=\"{nut + Frets * FretWidth}\" y2=\"{y}\" stroke=\"currentColor\" stroke-width=\"{thickness / 10}.{thickness % 10}\"/>\n");
    svg.Append($"  <text x=\"{Left / 2}\" y=\"{y}\" font-size=\"13\" text-anchor=\"middle\" dominant-baseline=\"central\" fill=\"currentColor\" fill-opacity=\"0.8\">{6 - row}</text>\n");
}

// The nut, then one wire at the end of each fret; the fret numbers below
svg.Append($"  <line x1=\"{nut}\" y1=\"{Top}\" x2=\"{nut}\" y2=\"{bottom}\" stroke=\"currentColor\" stroke-width=\"5\"/>\n");
for (int fret = 0; fret <= Frets; fret++)
{
    int center = fret == 0 ? Left + OpenWidth / 2 - 4 : nut + fret * FretWidth - FretWidth / 2;
    if (fret > 0)
    {
        svg.Append($"  <line x1=\"{nut + fret * FretWidth}\" y1=\"{Top}\" x2=\"{nut + fret * FretWidth}\" y2=\"{bottom}\" stroke=\"currentColor\" stroke-width=\"1.5\" stroke-opacity=\"0.7\"/>\n");
    }
    svg.Append($"  <text x=\"{center}\" y=\"{bottom + 28}\" font-size=\"13\" text-anchor=\"middle\" fill=\"currentColor\" fill-opacity=\"0.8\">{fret}</text>\n");
}

// One note per string and fret. The C at string 2, fret 1, (11 + 1) % 12 in the lesson, is highlighted.
for (int row = 0; row < 6; row++)
{
    for (int fret = 0; fret <= Frets; fret++)
    {
        int x = fret == 0 ? Left + OpenWidth / 2 - 4 : nut + fret * FretWidth - FretWidth / 2;
        int y = Top + row * StringGap;
        string name = names[(open[row] + fret) % 12];
        bool highlighted = row == 4 && fret == 1;
        string circle = highlighted
            ? "style=\"fill:var(--sl-color-accent-high, #3b2d99)\""
            : "stroke=\"currentColor\" stroke-width=\"1.2\" style=\"fill:var(--sl-color-bg, #ffffff)\"";
        string text = highlighted
            ? "font-weight=\"700\" style=\"fill:var(--sl-color-bg, #ffffff)\""
            : "fill=\"currentColor\"";
        svg.Append($"  <circle cx=\"{x}\" cy=\"{y}\" r=\"13\" {circle}/>\n");
        svg.Append($"  <text x=\"{x}\" y=\"{y}\" font-size=\"12\" text-anchor=\"middle\" dominant-baseline=\"central\" {text}>{name}</text>\n");
    }
}
svg.Append("</svg>\n");

// The SVG goes next to the site's other images, found from this file's folder, not from the current directory
string folder = (string)AppContext.GetData("EntryPointFileDirectoryPath")!;
string path = Path.GetFullPath(Path.Combine(folder, "..", "..", "..", "src", "assets", "csharp-beginner", "l03-fretboard.svg"));

if (args.Contains("--check"))
{
    string committed = File.Exists(path) ? File.ReadAllText(path).Replace("\r\n", "\n") : "";
    if (committed != svg.ToString())
    {
        Console.WriteLine($"{path} is not up to date");
        return 1;
    }
    Console.WriteLine($"{path} is up to date");
    return 0;
}

Directory.CreateDirectory(Path.GetDirectoryName(path)!);
File.WriteAllText(path, svg.ToString());
Console.WriteLine($"wrote {path}");
return 0;
