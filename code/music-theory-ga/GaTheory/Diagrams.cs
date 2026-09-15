using System.Globalization;
using System.Text;

namespace GaTheory;

// The SVG diagrams of the lessons, drawn from the course's own theory (Theory.cs) and written to
// src/assets/music-theory-ga. The pages inline them, so `currentColor` and Starlight's CSS
// variables follow the reader's theme. They hold note names and numbers only: no text to translate.
public static class Diagrams
{
    // Colours: the text colour, then Starlight's accent, orange and green, with fallbacks for other viewers
    const string Ink = "currentColor";
    static readonly string[] Palette =
    [
        "var(--sl-color-accent-high, #3b2d99)",
        "var(--sl-color-orange-high, #9a3412)",
        "var(--sl-color-green-high, #166534)",
    ];
    const string Paper = "var(--sl-color-bg, #ffffff)";
    const string Font = "font-family:var(--sl-font-system, system-ui, sans-serif)";

    static string F(double value) => Math.Round(value, 2).ToString(CultureInfo.InvariantCulture);

    static string Open(double width, double height) =>
        $"<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 {F(width)} {F(height)}\" width=\"{F(width)}\" height=\"{F(height)}\" " +
        $"style=\"max-width:100%;height:auto;{Font}\">\n";

    const string Close = "</svg>\n";

    static readonly string[] NoteNames = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"];

    // ---- Bracelets: the twelve pitch classes on a clock face, 0 (C) at the top, clockwise

    public sealed record Layer(int[] PitchClasses, int Colour);

    public enum Labels { Numbers, Notes }

    static (double X, double Y) OnCircle(double cx, double cy, double r, double pc)
    {
        var angle = (pc * 30 - 90) * Math.PI / 180;
        return (cx + r * Math.Cos(angle), cy + r * Math.Sin(angle));
    }

    // One bracelet at (cx, cy): the circle, a polygon per layer, a bead per pitch class, the labels,
    // and optional mirror axes given as the pitch class (possibly half-integer) they pass through
    static string Bracelet(double cx, double cy, IReadOnlyList<Layer> layers, Labels labels, double[]? axes = null, string? caption = null)
    {
        const double r = 70, bead = 8.5, labelRadius = 94;
        var svg = new StringBuilder();
        svg.Append($"  <circle cx=\"{F(cx)}\" cy=\"{F(cy)}\" r=\"{F(r)}\" fill=\"none\" stroke=\"{Ink}\" stroke-opacity=\"0.35\" stroke-width=\"1.5\"/>\n");
        foreach (var axis in axes ?? [])
        {
            var (x1, y1) = OnCircle(cx, cy, r + 12, axis);
            var (x2, y2) = OnCircle(cx, cy, r + 12, axis + 6);
            svg.Append($"  <line x1=\"{F(x1)}\" y1=\"{F(y1)}\" x2=\"{F(x2)}\" y2=\"{F(y2)}\" stroke=\"{Ink}\" stroke-opacity=\"0.6\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"/>\n");
        }
        foreach (var layer in layers)
        {
            var colour = Palette[layer.Colour];
            var points = string.Join(" ", layer.PitchClasses.Order().Select(pc => OnCircle(cx, cy, r, pc)).Select(p => $"{F(p.X)},{F(p.Y)}"));
            svg.Append($"  <polygon points=\"{points}\" style=\"fill:{colour};stroke:{colour}\" fill-opacity=\"0.12\" stroke-width=\"2.5\" stroke-linejoin=\"round\"/>\n");
        }
        for (var pc = 0; pc < 12; pc++)
        {
            var (x, y) = OnCircle(cx, cy, r, pc);
            var owners = layers.Where(layer => layer.PitchClasses.Contains(pc)).ToList();
            if (owners.Count == 0)
            {
                svg.Append($"  <circle cx=\"{F(x)}\" cy=\"{F(y)}\" r=\"5\" style=\"fill:{Paper}\" stroke=\"{Ink}\" stroke-opacity=\"0.5\" stroke-width=\"1.5\"/>\n");
            }
            else
            {
                // a pitch class shared by several layers gets a ring in the next layer's colour
                if (owners.Count > 1)
                {
                    svg.Append($"  <circle cx=\"{F(x)}\" cy=\"{F(y)}\" r=\"{F(bead + 4)}\" style=\"fill:none;stroke:{Palette[owners[1].Colour]}\" stroke-width=\"3\"/>\n");
                }
                svg.Append($"  <circle cx=\"{F(x)}\" cy=\"{F(y)}\" r=\"{F(bead)}\" style=\"fill:{Palette[owners[0].Colour]}\"/>\n");
            }
            var (lx, ly) = OnCircle(cx, cy, labelRadius, pc);
            var text = labels == Labels.Numbers ? pc.ToString(CultureInfo.InvariantCulture) : NoteNames[pc];
            var weight = owners.Count > 0 ? "700" : "400";
            svg.Append($"  <text x=\"{F(lx)}\" y=\"{F(ly)}\" font-size=\"13\" font-weight=\"{weight}\" text-anchor=\"middle\" dominant-baseline=\"central\" fill=\"{Ink}\">{text}</text>\n");
        }
        if (caption is not null)
        {
            svg.Append($"  <text x=\"{F(cx)}\" y=\"{F(cy + 122)}\" font-size=\"15\" font-weight=\"700\" text-anchor=\"middle\" fill=\"{Ink}\">{caption}</text>\n");
        }
        return svg.ToString();
    }

    static string Bracelets(params (IReadOnlyList<Layer> Layers, Labels Labels, double[]? Axes, string? Caption)[] panels)
    {
        const double panel = 230;
        var captioned = panels.Any(p => p.Caption is not null);
        var height = captioned ? 262 : 230;
        var svg = new StringBuilder(Open(panel * panels.Length, height));
        for (var i = 0; i < panels.Length; i++)
        {
            svg.Append(Bracelet(panel * i + panel / 2, 115, panels[i].Layers, panels[i].Labels, panels[i].Axes, panels[i].Caption));
        }
        return svg.Append(Close).ToString();
    }

    static Layer Set(int id, int colour = 0) => new(Theory.PitchClasses(id), colour);

    // ---- Chord grids: string 6 (low E) on the left, the nut at the top, as on chord charts

    static readonly string[] Standard = ["E2", "A2", "D3", "G3", "B3", "E4"]; // string 6 to string 1

    static string ChordGrid(double left, string shape, string caption)
    {
        const double top = 40, stringGap = 24, fretGap = 30, frets = 4;
        var svg = new StringBuilder();
        var fretted = shape.Where(char.IsDigit).Select(ch => ch - '0').Where(f => f > 0).ToArray();
        var lowest = fretted.Length == 0 ? 1 : fretted.Min();
        var first = fretted.Length == 0 || fretted.Max() <= frets ? 1 : lowest; // first fret shown
        double X(int stringIndex) => left + stringIndex * stringGap;
        double Y(int fret) => top + fret * fretGap;

        for (var s = 0; s < 6; s++)
        {
            svg.Append($"  <line x1=\"{F(X(s))}\" y1=\"{F(Y(0))}\" x2=\"{F(X(s))}\" y2=\"{F(Y((int)frets))}\" stroke=\"{Ink}\" stroke-width=\"1.5\"/>\n");
        }
        for (var f = 0; f <= frets; f++)
        {
            var width = f == 0 && first == 1 ? 5 : 1.5;
            svg.Append($"  <line x1=\"{F(X(0))}\" y1=\"{F(Y(f))}\" x2=\"{F(X(5))}\" y2=\"{F(Y(f))}\" stroke=\"{Ink}\" stroke-width=\"{F(width)}\"/>\n");
        }
        if (first > 1)
        {
            svg.Append($"  <text x=\"{F(X(0) - 10)}\" y=\"{F(Y(0) + fretGap / 2)}\" font-size=\"13\" text-anchor=\"end\" dominant-baseline=\"central\" fill=\"{Ink}\">{first}</text>\n");
        }

        // a barre: the lowest fret held on every string from the first to the last string that uses it
        var barreStrings = Enumerable.Range(0, 6).Where(s => shape[s] - '0' == lowest).ToArray();
        var barre = barreStrings.Length >= 3
            && Enumerable.Range(barreStrings.First(), barreStrings.Last() - barreStrings.First() + 1).All(s => char.IsDigit(shape[s]) && shape[s] - '0' >= lowest);
        if (barre)
        {
            var y = Y(lowest - first) + fretGap / 2;
            svg.Append($"  <line x1=\"{F(X(barreStrings.First()))}\" y1=\"{F(y)}\" x2=\"{F(X(barreStrings.Last()))}\" y2=\"{F(y)}\" style=\"stroke:{Palette[0]}\" stroke-width=\"17\" stroke-linecap=\"round\"/>\n");
        }

        for (var s = 0; s < 6; s++)
        {
            var ch = shape[s];
            if (ch == 'x' || ch == '0')
            {
                var mark = ch == 'x' ? "×" : "○";
                svg.Append($"  <text x=\"{F(X(s))}\" y=\"{F(top - 14)}\" font-size=\"15\" text-anchor=\"middle\" dominant-baseline=\"central\" fill=\"{Ink}\">{mark}</text>\n");
            }
            else if (!(barre && ch - '0' == lowest))
            {
                var y = Y(ch - '0' - first) + fretGap / 2;
                svg.Append($"  <circle cx=\"{F(X(s))}\" cy=\"{F(y)}\" r=\"8.5\" style=\"fill:{Palette[0]}\"/>\n");
            }
            if (ch != 'x')
            {
                var midi = Theory.MidiOf(Standard[s]) + ch - '0';
                svg.Append($"  <text x=\"{F(X(s))}\" y=\"{F(Y((int)frets) + 16)}\" font-size=\"11\" text-anchor=\"middle\" dominant-baseline=\"central\" fill=\"{Ink}\">{Theory.PitchName(midi).Replace("#", "♯")}</text>\n");
            }
        }
        svg.Append($"  <text x=\"{F(X(0) + stringGap * 2.5)}\" y=\"{F(Y((int)frets) + 42)}\" font-size=\"15\" font-weight=\"700\" text-anchor=\"middle\" fill=\"{Ink}\">{caption}</text>\n");
        return svg.ToString();
    }

    static string ChordGrids(params (string Shape, string Caption)[] grids)
    {
        const double panel = 175;
        var svg = new StringBuilder(Open(panel * grids.Length, 228));
        for (var i = 0; i < grids.Length; i++)
        {
            svg.Append(ChordGrid(panel * i + 30, grids[i].Shape, grids[i].Caption));
        }
        return svg.Append(Close).ToString();
    }

    // ---- Fretboard: frets 0 to 12, string 1 (high E) at the top, as in tablature

    static string Fretboard(int pitchClass, int frets = 12)
    {
        const double left = 44, top = 24, stringGap = 26, fretGap = 52;
        var width = left + fretGap * (frets + 0.6);
        var svg = new StringBuilder(Open(width, top + stringGap * 5 + 44));
        double X(int fret) => left + fret * fretGap; // fret wire position; a note sits before its wire
        double NoteX(int fret) => fret == 0 ? left - 22 : X(fret) - fretGap / 2;
        double Y(int stringNumber) => top + (stringNumber - 1) * stringGap;

        foreach (var dotFret in new[] { 3, 5, 7, 9 }.Where(f => f <= frets))
        {
            svg.Append($"  <circle cx=\"{F(NoteX(dotFret))}\" cy=\"{F(Y(3) + stringGap / 2)}\" r=\"5\" fill=\"{Ink}\" fill-opacity=\"0.2\"/>\n");
        }
        if (frets >= 12)
        {
            svg.Append($"  <circle cx=\"{F(NoteX(12))}\" cy=\"{F(Y(2) + stringGap / 2)}\" r=\"5\" fill=\"{Ink}\" fill-opacity=\"0.2\"/>\n");
            svg.Append($"  <circle cx=\"{F(NoteX(12))}\" cy=\"{F(Y(4) + stringGap / 2)}\" r=\"5\" fill=\"{Ink}\" fill-opacity=\"0.2\"/>\n");
        }
        for (var s = 1; s <= 6; s++)
        {
            svg.Append($"  <line x1=\"{F(X(0))}\" y1=\"{F(Y(s))}\" x2=\"{F(X(frets))}\" y2=\"{F(Y(s))}\" stroke=\"{Ink}\" stroke-width=\"{F(0.8 + s * 0.3)}\"/>\n");
        }
        for (var f = 0; f <= frets; f++)
        {
            var w = f == 0 ? 5 : 1.5;
            svg.Append($"  <line x1=\"{F(X(f))}\" y1=\"{F(Y(1))}\" x2=\"{F(X(f))}\" y2=\"{F(Y(6))}\" stroke=\"{Ink}\" stroke-width=\"{F(w)}\"/>\n");
            svg.Append($"  <text x=\"{F(NoteX(f))}\" y=\"{F(Y(6) + 26)}\" font-size=\"12\" text-anchor=\"middle\" fill=\"{Ink}\" fill-opacity=\"0.8\">{f}</text>\n");
        }
        for (var s = 1; s <= 6; s++)
        {
            var open = Standard[6 - s];
            for (var f = 0; f <= frets; f++)
            {
                var midi = Theory.MidiOf(open) + f;
                if (Theory.Mod12(midi) != pitchClass) continue;
                svg.Append($"  <circle cx=\"{F(NoteX(f))}\" cy=\"{F(Y(s))}\" r=\"11.5\" style=\"fill:{Palette[0]}\"/>\n");
                svg.Append($"  <text x=\"{F(NoteX(f))}\" y=\"{F(Y(s))}\" font-size=\"10.5\" font-weight=\"700\" text-anchor=\"middle\" dominant-baseline=\"central\" style=\"fill:{Paper}\">{Theory.PitchName(midi).Replace("#", "♯")}</text>\n");
            }
        }
        return svg.Append(Close).ToString();
    }

    // ---- Circle of fifths: major keys outside, minor keys inside, signatures in between

    static string CircleOfFifths(int? related = null)
    {
        const double cx = 170, cy = 170, outer = 142, middle = 104, inner = 72;
        var svg = new StringBuilder(Open(340, 340));
        svg.Append($"  <circle cx=\"{F(cx)}\" cy=\"{F(cy)}\" r=\"{F(123)}\" fill=\"none\" stroke=\"{Ink}\" stroke-opacity=\"0.3\" stroke-width=\"1.5\"/>\n");
        svg.Append($"  <circle cx=\"{F(cx)}\" cy=\"{F(cy)}\" r=\"{F(88)}\" fill=\"none\" stroke=\"{Ink}\" stroke-opacity=\"0.3\" stroke-width=\"1.5\"/>\n");
        for (var position = 0; position < 12; position++)
        {
            // position 0 at the top; clockwise adds sharps, counter-clockwise adds flats
            var fifths = position <= 6 ? position : position - 12;
            var highlighted = related is { } home && Math.Abs(fifths - home) <= 1;
            if (highlighted)
            {
                var (hx, hy) = OnCircle(cx, cy, 104, position);
                svg.Append($"  <circle cx=\"{F(hx)}\" cy=\"{F(hy)}\" r=\"19\" style=\"fill:{Palette[0]}\" fill-opacity=\"0.14\"/>\n");
            }
            string Names(Func<int, string> tonic) => position switch
            {
                5 => $"{tonic(5)}/{tonic(-7)}",
                6 => $"{tonic(6)}/{tonic(-6)}",
                7 => $"{tonic(7)}/{tonic(-5)}",
                _ => tonic(fifths),
            };
            var major = Names(n => Pretty(Theory.MajorTonic(n)));
            var minor = Names(n => Pretty(Theory.MinorTonic(n)).ToLowerInvariant());
            var signature = fifths switch { 0 => "0", > 0 => $"{fifths}♯", _ => $"{-fifths}♭" };
            if (position is 5 or 6 or 7) signature = $"{position}♯/{12 - position}♭";
            var weight = highlighted ? "700" : "400";
            Text(outer, major, 15, "700");
            Text(middle, signature, 11, weight, 0.8);
            Text(inner, minor, 13, weight);

            void Text(double radius, string text, int size, string fontWeight, double opacity = 1)
            {
                var (x, y) = OnCircle(cx, cy, radius, position);
                var fill = highlighted && radius != middle ? $"style=\"fill:{Palette[0]}\"" : $"fill=\"{Ink}\"";
                svg.Append($"  <text x=\"{F(x)}\" y=\"{F(y)}\" font-size=\"{size}\" font-weight=\"{fontWeight}\" text-anchor=\"middle\" dominant-baseline=\"central\" {fill} fill-opacity=\"{F(opacity)}\">{text}</text>\n");
            }
        }
        return svg.Append(Close).ToString();
    }

    static string Pretty(string note) => note.Replace("#", "♯").Replace("b", "♭");

    // ---- All diagrams, by file name

    public static IReadOnlyDictionary<string, string> All()
    {
        int Id(params int[] pcs) => Theory.SetId(pcs);
        var major = Theory.FromSteps(Theory.MajorSteps);
        var dorian = Theory.FromSteps(Theory.MajorSteps.Skip(1).Concat(Theory.MajorSteps.Take(1)));
        var cMajorTriad = Id(0, 4, 7);

        return new SortedDictionary<string, string>(StringComparer.Ordinal)
        {
            ["l1-fretboard-c.svg"] = Fretboard(pitchClass: 0),
            ["l2-bracelet-major.svg"] = Bracelets(([Set(major)], Labels.Numbers, null, null)),
            ["l2-bracelet-transposition.svg"] = Bracelets(
                ([Set(major)], Labels.Numbers, null, "T0"),
                ([Set(Theory.Transpose(major, 2), 1)], Labels.Numbers, null, "T2")),
            ["l2-bracelet-modes.svg"] = Bracelets(
                ([Set(major)], Labels.Numbers, null, major.ToString(CultureInfo.InvariantCulture)),
                ([Set(dorian, 1)], Labels.Numbers, null, dorian.ToString(CultureInfo.InvariantCulture))),
            ["l2-bracelet-symmetric.svg"] = Bracelets(
                ([Set(Theory.FromSteps([2, 2, 2, 2, 2, 2]))], Labels.Numbers, null, "1365"),
                ([Set(Theory.FromSteps([2, 1, 2, 1, 2, 1, 2, 1]), 1)], Labels.Numbers, null, "2925")),
            ["l3-voicings.svg"] = ChordGrids(("x32010", "x32010"), ("032010", "032010"), ("320003", "320003"), ("133211", "133211")),
            ["l4-bracelet-inversion.svg"] = Bracelets(
                ([Set(cMajorTriad), Set(Theory.Invert(cMajorTriad), 1)], Labels.Numbers, [0], null)),
            ["l4-bracelet-z-relation.svg"] = Bracelets(
                ([Set(Id(0, 1, 4, 6))], Labels.Numbers, null, "4-Z15"),
                ([Set(Id(0, 1, 3, 7), 1)], Labels.Numbers, null, "4-Z29")),
            ["l5-circle-of-fifths.svg"] = CircleOfFifths(),
            ["l5-circle-related-c.svg"] = CircleOfFifths(related: 0),
            ["l5-bracelet-c-g.svg"] = Bracelets(
                ([Set(major), Set(Theory.Transpose(major, 7), 1)], Labels.Notes, null, null)),
            ["l6-bracelet-primary-triads.svg"] = Bracelets(
                ([Set(cMajorTriad), Set(Id(5, 9, 0), 1), Set(Id(7, 11, 2), 2)], Labels.Notes, null, null)),
            ["l7-ii-v-i.svg"] = ChordGrids(("xx0211", "Dm7"), ("320001", "G7"), ("x32000", "Cmaj7")),
            ["l7-bracelet-g7-c.svg"] = Bracelets(
                ([Set(Id(7, 11, 2, 5), 1), Set(cMajorTriad)], Labels.Notes, null, null)),
        };
    }

    // `svg <dir>` writes every diagram; `svg <dir> --check` only compares them with the files in <dir>
    public static int Run(string directory, bool check)
    {
        var diagrams = All();
        var status = 0;
        if (!check) Directory.CreateDirectory(directory);
        foreach (var (name, content) in diagrams)
        {
            var path = Path.Combine(directory, name);
            if (check)
            {
                var existing = File.Exists(path) ? File.ReadAllText(path).Replace("\r\n", "\n") : null;
                var same = existing == content;
                Console.WriteLine($"{(same ? "ok  " : "DIFF")} {name}");
                if (!same) status = 1;
            }
            else
            {
                File.WriteAllText(path, content, new UTF8Encoding(false));
                Console.WriteLine($"wrote {name}");
            }
        }
        if (check && Directory.Exists(directory))
        {
            foreach (var extra in Directory.GetFiles(directory, "*.svg").Select(Path.GetFileName).Where(n => !diagrams.ContainsKey(n!)))
            {
                Console.WriteLine($"DIFF {extra} (not generated)");
                status = 1;
            }
        }
        return status;
    }
}
