extern alias fix749;

namespace GaAi;

using System.Text.Json;
using System.Text.RegularExpressions;
using GA.Business.ML.Agents;
using GA.Business.ML.Agents.Skills;
using GA.Business.ML.Search;
using Microsoft.Extensions.Logging.Abstractions;
using static Report;
using Fixed = fix749::GA.Business.ML.Agents.Skills;

// Lesson 7: input that isn't a chord. The program sends improvisation requests that name valid
// chords, invalid ones, or both, to the pinned improvisation skill and to the one of GA pull
// request #749, which declines requests that name only invalid chords (issue #745), and grades
// both against a small recognizer of chord symbols written from the textbook convention
public static class Lesson7
{
    static readonly string[] Messages =
    [
        // Only invalid chord names: what #749 declines
        "which arpeggio fits Hm Q7",
        "which arpeggio fits X7alt",
        "Q7, which arpeggio should I use?",
        "which arpeggio fits H7",
        "which arpeggio fits hm q7",
        "which arpeggio fits Cq7",
        // Only valid chord names
        "which arpeggio fits Am F C G",
        "which arpeggio fits Bb Eb F",
        "which arpeggio fits B♭ E♭ F",
        "which arpeggio fits B F# G#m E",
        "which arpeggio fits C C+ F",
        "which arpeggio fits Bø7 E7 Am",
        // Both
        "which arpeggio fits Am F Q7 G",
        "which arpeggio fits C and Q7",
        // No chord symbol
        "Hm, which mode is brightest?",
        "which arpeggio fits V7",
    ];

    public static void Run()
    {
        var pinned = new ImprovisationSkill(NullLogger<ImprovisationSkill>.Instance, new NoExtractor());
        var fixedSkill = new Fixed.ImprovisationSkill(NullLogger<Fixed.ImprovisationSkill>.Instance, new NoExtractor());

        Title("What each message holds, read as chord symbols are written");
        int[] w = [3, 34, 12];
        Row(w, "#", "message", "chords", "not chord symbols");
        var readings = Messages.Select(Read).ToList();
        for (var i = 0; i < Messages.Length; i++)
            Row(w, i + 1, Messages[i], Words(readings[i].Chords), readings[i].Describe());

        Title("What GA does with them");
        int[] v = [3, 22, 12, 22];
        Row(v, "#", "skill at a826864", "#749 guard", "#749 skill", "verdict (#749)");
        for (var i = 0; i < Messages.Length; i++)
        {
            var before = Outcome(pinned.ExecuteAsync, Messages[i]);
            var guard = Fixed.InvalidChordNames.Find(Messages[i]);
            var after = Outcome(fixedSkill.ExecuteAsync, Messages[i]);
            Row(v, i + 1, before.Text, Words(guard), after.Text, Verdict(readings[i], after));
        }

        foreach (var message in new[] { Messages[0], Messages[3] })
        {
            var response = fixedSkill.ExecuteAsync(message).GetAwaiter().GetResult();
            Title($"#749's skill on \"{message}\"");
            Line($"confidence {response.Confidence:0.0#}");
            Line($"  | {response.Result}");
            foreach (var assumption in response.Assumptions) Line($"assumption: {assumption}");
        }
    }

    // ---- The recognizer: chord symbols as textbooks write them ----

    // A root from A to G, uppercase, an optional accidental, then one of these qualities, and an
    // optional bass note after a slash. The list covers the chords of lessons 5 and 7
    static readonly string[] Qualities =
    [
        "", "m", "-", "7", "maj7", "m7", "-7", "6", "m6", "9", "maj9", "m9", "11", "13", "5",
        "dim", "dim7", "°", "°7", "ø", "ø7", "m7b5", "aug", "+", "sus2", "sus4", "7sus4", "add9",
        "mMaj7", "7b9", "7#9", "7#11", "7alt", "alt",
    ];

    static readonly Regex Symbol = new(@"^(?<letter>[A-Za-z])(?<accidental>[#b♯♭]?)(?<quality>[^/]*)(?:/(?<bass>[A-G][#b♯♭]?))?$");

    // Roman numerals of harmony: "V7", "ii", "IV". A single "I" is left out: it is the pronoun
    static readonly Regex Roman = new(@"^(?=.{2})(?:VII|VI|V|IV|III|II|I|vii|vi|v|iv|iii|ii|i)(?:7|°|ø)?$");

    sealed record Reading(List<string> Chords, List<(string Token, string Why)> NotChords, List<string> Numerals)
    {
        public string Describe() =>
            NotChords.Count > 0 ? string.Join(", ", NotChords.Select(n => $"{n.Token} ({n.Why})"))
            : Numerals.Count > 0 ? $"{string.Join(", ", Numerals)} (Roman numeral)"
            : "-";
    }

    static Reading Read(string message)
    {
        List<string> chords = [], numerals = [];
        List<(string, string)> notChords = [];
        foreach (var word in message.Split(' '))
        {
            var token = word.TrimEnd(',', '.', '?', '!');
            if (Roman.IsMatch(token)) { numerals.Add(token); continue; }
            var m = Symbol.Match(token);
            if (!m.Success) continue;
            var letter = m.Groups["letter"].Value[0];
            var quality = m.Groups["quality"].Value;
            var known = Qualities.Contains(quality);
            // A word that isn't shaped like a chord symbol at all ("fits", "mode", "I") is text
            if (!known && !quality.Any(char.IsDigit)) continue;
            if (quality.Length == 0 && m.Groups["accidental"].Length == 0 && letter is < 'A' or > 'G') continue;
            if (letter is >= 'A' and <= 'G' && known) chords.Add(Normalize(token));
            else if (char.IsLower(letter)) notChords.Add((token, "lowercase root"));
            else if (letter is < 'A' or > 'G') notChords.Add((token, $"root {letter}"));
            else notChords.Add((token, $"quality {quality}"));
        }
        return new Reading(chords, notChords, numerals);
    }

    static string Words(IEnumerable<string> items) => items.Any() ? string.Join(" ", items) : "-";

    // B♭ and Bb are the same chord; the program compares with ASCII accidentals
    static string Normalize(string chord) => chord.Replace('♭', 'b').Replace('♯', '#');

    // ---- What GA does ----

    sealed record Result(string Kind, List<string> Chords, string Text);

    static Result Outcome(Func<string, CancellationToken, Task<AgentResponse>> execute, string message)
    {
        try
        {
            var response = execute(message, CancellationToken.None).GetAwaiter().GetResult();
            if (response.Result.StartsWith("I don't recognize", StringComparison.Ordinal))
                return new("declines", [], "declines");
            var data = response.Data is null ? default : JsonSerializer.SerializeToElement(response.Data);
            if (data.ValueKind == JsonValueKind.Object && data.TryGetProperty("perChord", out var perChord))
            {
                var chords = perChord.EnumerateArray().Select(c => c.GetProperty("chord").GetString()!).ToList();
                return new("answers", chords, $"answers {string.Join(" ", chords)}");
            }
            return new("other", [], response.Result.Split('\n')[0]);
        }
        catch (ModelNeeded)
        {
            return new("model", [], "needs the model");
        }
    }

    static string Verdict(Reading reading, Result result)
    {
        if (reading.NotChords.Count > 0)
        {
            if (result.Kind == "declines") return "same";
            if (result.Kind == "model") return "DIFF reaches the model";
            var dropped = reading.NotChords.Select(n => n.Token).Where(t => !result.Text.Contains(t));
            return $"DIFF drops {string.Join(" ", dropped)} without a word";
        }
        if (reading.Chords.Count < 2) return "n/a";
        if (result.Kind != "answers") return $"DIFF {result.Text}";
        if (result.Chords.SequenceEqual(reading.Chords)) return "same";
        // Same number of chords: a chord read as another. Fewer: a chord left out of the run
        if (result.Chords.Count == reading.Chords.Count)
        {
            var misread = reading.Chords.Zip(result.Chords).Where(p => p.First != p.Second)
                .Select(p => $"{p.First} as {p.Second}");
            return $"DIFF reads {string.Join(", ", misread)}";
        }
        return $"DIFF drops {string.Join(" ", reading.Chords.Except(result.Chords))} without a word";
    }

    // The single-chord path asks a model to extract the chord; offline, the program stops there
    sealed class ModelNeeded() : Exception("the single-chord path asks the model to extract the chord");

    sealed class NoExtractor : IMusicalQueryExtractor
    {
        public Task<StructuredQuery> ExtractAsync(string query, CancellationToken cancellationToken = default) =>
            throw new ModelNeeded();
    }
}
