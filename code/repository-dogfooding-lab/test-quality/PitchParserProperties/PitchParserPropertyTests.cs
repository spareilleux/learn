namespace PitchParserProperties;

using FsCheck;
using FsCheck.Fluent;
using FsCheck.NUnit;
using GA.Domain.Core.Primitives.Notes;
using NUnit.Framework;
using PropertyAttribute = FsCheck.NUnit.PropertyAttribute;

/// <summary>
///     Generative tests of GA's pitch parsing, through the public <see cref="Pitch.Sharp.TryParse" /> and
///     <see cref="Pitch.Flat.TryParse" /> only (they are the sole callers of the internal <c>PitchParser.TryParse</c>).
///     Every oracle restates a contract GA's own tests already assert: the result, the canonical <c>ToString()</c>,
///     a case-insensitive letter, octaves -1..9 and one accidental of the parser's own kind. Nothing here depends on
///     how the parser is written.
/// </summary>
[TestFixture]
public class PitchParserPropertyTests
{
    private const int Cases = 10_000;
    private const string Seed = "(20260926,7)";

    public enum Kind { Sharp, Flat }

    /// <summary>A pitch written as text, with the canonical text GA prints for it.</summary>
    public sealed record Spelling(Kind Kind, string Text, string Canonical);

    private static bool TryParse(Kind kind, string? s, out string? printed)
    {
        if (kind == Kind.Sharp)
        {
            var ok = Pitch.Sharp.TryParse(s, null, out var sharp);
            printed = ok ? sharp.ToString() : null;
            return ok;
        }

        var okFlat = Pitch.Flat.TryParse(s, null, out var flat);
        printed = okFlat ? flat.ToString() : null;
        return okFlat;
    }

    private static string Accidental(Kind kind) => kind == Kind.Sharp ? "#" : "b";

    private static string OtherAccidental(Kind kind) => kind == Kind.Sharp ? "b" : "#";

    // Built from small integers and booleans, which FsCheck knows how to shrink: a failing case shrinks towards
    // letter A, no accidental, octave -1.
    private static Spelling FromParts(Kind kind, byte letter, bool accidental, bool lowerCase, byte octave)
    {
        var upper = "ABCDEFG"[letter % 7];
        var octaveValue = octave % 11 - 1;
        var acc = accidental ? Accidental(kind) : "";
        var text = $"{(lowerCase ? char.ToLowerInvariant(upper) : upper)}{acc}{octaveValue}";
        return new Spelling(kind, text, $"{upper}{acc}{octaveValue}");
    }

    // FsCheck generates and shrinks the tuple; the spelling is derived from it inside each property.
    private static Arbitrary<(byte, bool, bool, byte)> Parts => ArbMap.Default.ArbFor<(byte, bool, bool, byte)>();

    private static Spelling Valid(Kind kind, (byte, bool, bool, byte) t) => FromParts(kind, t.Item1, t.Item2, t.Item3, t.Item4);

    // One edit that no pitch grammar of GA's tests accepts, applied to a valid spelling.
    private static readonly string[] Edits =
    [
        "append-letter", "append-space", "append-digit", "prepend-letter", "prepend-space", "prepend-accidental",
        "octave-too-high", "octave-too-low", "other-accidental", "double-accidental", "no-octave"
    ];

    private static string Break(Spelling s, string edit, int n)
    {
        var letter = s.Canonical[0];
        var acc = Accidental(s.Kind);
        return edit switch
        {
            "append-letter" => s.Text + "ACxz"[n % 4],
            "append-space" => s.Text + " ",
            "append-digit" => s.Text + (n % 10), // "C4" -> "C45", "C-1" -> "C-10": never a valid octave
            "prepend-letter" => "xzH"[n % 3] + s.Text, // never a pitch letter: "A" + "b3" would be the valid flat "Ab3"
            "prepend-space" => " " + s.Text,
            "prepend-accidental" => "#" + s.Text, // "#" never starts a pitch; a "b" could, since "bb3" is a valid flat
            "octave-too-high" => $"{letter}{10 + n % 90}",
            "octave-too-low" => $"{letter}-{2 + n % 8}",
            "other-accidental" => $"{letter}{OtherAccidental(s.Kind)}{n % 10}",
            "double-accidental" => $"{letter}{acc}{acc}{n % 10}",
            "no-octave" => $"{letter}{(n % 2 == 0 ? acc : "")}",
            _ => throw new ArgumentOutOfRangeException(nameof(edit))
        };
    }

    [Property(MaxTest = Cases, Replay = Seed, QuietOnSuccess = true)]
    public Property Valid_sharp_pitches_parse_and_print_canonically() => ValidParses(Kind.Sharp);

    [Property(MaxTest = Cases, Replay = Seed, QuietOnSuccess = true)]
    public Property Valid_flat_pitches_parse_and_print_canonically() => ValidParses(Kind.Flat);

    private static Property ValidParses(Kind kind) =>
        Prop.ForAll(Parts, t =>
        {
            var s = Valid(kind, t);
            return (TryParse(kind, s.Text, out var printed) && printed == s.Canonical).Label($"{s.Text} -> {printed}");
        });

    [Property(MaxTest = Cases, Replay = Seed, QuietOnSuccess = true)]
    public Property Malformed_sharp_pitches_are_refused() => MalformedRefused(Kind.Sharp);

    [Property(MaxTest = Cases, Replay = Seed, QuietOnSuccess = true)]
    public Property Malformed_flat_pitches_are_refused() => MalformedRefused(Kind.Flat);

    private static Property MalformedRefused(Kind kind) =>
        Prop.ForAll(Parts, Gen.Elements(Edits).ToArbitrary(), ArbMap.Default.ArbFor<byte>(), (t, edit, n) =>
        {
            var broken = Break(Valid(kind, t), edit, n);
            return (!TryParse(kind, broken, out var printed)).Label($"{edit}: {broken} -> {printed}");
        });

    [Property(MaxTest = Cases, Replay = Seed, QuietOnSuccess = true)]
    public Property Any_string_never_throws_and_accepted_text_round_trips() =>
        Prop.ForAll(ArbMap.Default.ArbFor<string>(), s =>
            Enum.GetValues<Kind>().All(kind =>
            {
                if (!TryParse(kind, s, out var printed))
                {
                    return true;
                }

                return TryParse(kind, printed, out var again) && again == printed;
            }));

    [Test]
    public void Null_empty_and_whitespace_are_refused_without_throwing()
    {
        foreach (var kind in Enum.GetValues<Kind>())
        foreach (var s in new[] { null, "", " ", "\t", "\n" })
        {
            Assert.That(TryParse(kind, s, out _), Is.False, $"{kind} {s ?? "null"}");
        }
    }

    /// <summary>
    ///     Negative control: a deliberately false claim, that the sharp and the flat parser accept exactly the same
    ///     texts. It must fail, shrink, and replay from its seed. FsCheck.NUnit 3.4.0's <c>[Property]</c> ignores NUnit's
    ///     <c>[Explicit]</c> (observed on the first run), so it is excluded by category instead: every normal run and the
    ///     Stryker configuration use <c>TestCategory!=NegativeControl</c>, and <c>--filter TestCategory=NegativeControl</c>
    ///     runs it alone.
    /// </summary>
    [Property(MaxTest = Cases, Replay = Seed)]
    [Category("NegativeControl")]
    public Property Negative_control_sharp_and_flat_accept_the_same_texts() =>
        Prop.ForAll(Parts, t =>
        {
            var s = Valid(Kind.Sharp, t);
            return (TryParse(Kind.Sharp, s.Text, out _) == TryParse(Kind.Flat, s.Text, out _)).Label(s.Text);
        });
}
