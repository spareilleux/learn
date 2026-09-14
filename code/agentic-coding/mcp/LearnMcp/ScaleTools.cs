using System.ComponentModel;
using ModelContextProtocol;
using ModelContextProtocol.Server;

namespace LearnMcp;

[McpServerToolType]
public static class ScaleTools
{
    private const string Letters = "CDEFGAB";
    private static readonly int[] LetterPitches = [0, 2, 4, 5, 7, 9, 11];
    private static readonly int[] MajorSteps = [2, 2, 1, 2, 2, 2, 1];
    private static readonly string[] Modes = ["ionian", "dorian", "phrygian", "lydian", "mixolydian", "aeolian", "locrian"];

    [McpServerTool(Name = "scale_notes", ReadOnly = true, Idempotent = true)]
    [Description("Spells the seven notes of a diatonic scale, one letter per degree: 'F major' gives Bb, not A#.")]
    public static string[] ScaleNotes(
        [Description("Root note: a letter A to G, optionally followed by # or b, for example C, F# or Bb")] string root,
        [Description("major, minor, or a mode name: ionian, dorian, phrygian, lydian, mixolydian, aeolian, locrian")] string mode = "major")
    {
        var (letter, pitch) = ParseNote(root);
        var rotation = mode.ToLowerInvariant() switch
        {
            "major" => 0,
            "minor" => 5,
            var name when Array.IndexOf(Modes, name) >= 0 => Array.IndexOf(Modes, name),
            _ => throw new McpException($"Unknown mode '{mode}'. Use major, minor or one of: {string.Join(", ", Modes)}."),
        };

        var notes = new string[7];
        var offset = 0;
        for (var degree = 0; degree < 7; degree++)
        {
            var noteLetter = (letter + degree) % 7;
            var target = (pitch + offset) % 12;
            // Distance from the natural letter to the target pitch, between -6 and +5 semitones
            var accidental = (target - LetterPitches[noteLetter] + 18) % 12 - 6;
            if (Math.Abs(accidental) > 2)
            {
                throw new McpException($"{root} {mode} would need more than two accidentals on {Letters[noteLetter]}.");
            }
            notes[degree] = Letters[noteLetter] + (accidental >= 0 ? new string('#', accidental) : new string('b', -accidental));
            offset += MajorSteps[(rotation + degree) % 7];
        }
        return notes;
    }

    private static (int Letter, int Pitch) ParseNote(string note)
    {
        var trimmed = note.Trim();
        var letter = trimmed.Length > 0 ? Letters.IndexOf(char.ToUpperInvariant(trimmed[0])) : -1;
        if (letter < 0 || trimmed.Skip(1).Any(c => c != '#' && c != 'b') || trimmed.Length > 3)
        {
            throw new McpException($"'{note}' is not a note: use a letter A to G, optionally followed by # or b.");
        }
        var accidentals = trimmed.Count(c => c == '#') - trimmed.Skip(1).Count(c => c == 'b');
        return (letter, (LetterPitches[letter] + accidentals + 12) % 12);
    }
}
