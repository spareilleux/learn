#:project ../.ga-main/GaMcpServer/GaMcpServer.csproj
#:property TreatWarningsAsErrors=false
#:property PublishAot=false
#:property JsonSerializerIsReflectionEnabledByDefault=true
// Regression check of GA against the findings of this course and its neighbours (ga-lab, fsharp):
// each line calls a GA MCP tool method or parser with an input a journal recorded as wrong at
// a826864, and prints only the facts that finding is about. results.txt holds the expected output;
// .github/workflows/ga-recheck.yml runs this against GA's main every week and fails on any
// difference, so a finding that comes back, or a fix that changes an answer, shows up.
//
//   git clone https://github.com/GuitarAlchemist/ga.git ../.ga-main
//   dotnet run probe.cs > results.txt
//
// The last two properties turn off the file-based app defaults (AOT, source-generated JSON) that
// GaMcpServer's reflection-based JsonSerializer calls do not support.
using System.Text.Json;
using System.Text.RegularExpressions;
using GaMcpServer.Tools;
using GA.Business.DSL.Parsers;

GA.Business.DSL.GaClosureBootstrap.init();

// Only the named fields of a tool's text answer, in order: "Field: value" lines
static string Fields(string answer, params string[] names) =>
    string.Join("; ", names.Select(n =>
        Regex.Match(answer, $@"^\s*{Regex.Escape(n)}:\s*(.+?)\s*$", RegexOptions.Multiline) is { Success: true } m
            ? $"{n}: {m.Groups[1].Value}"
            : $"{n}: (missing)"));

static string OneLine(string s) => Regex.Replace(s.Trim(), @"\s+", " ");

// music-theory-ga QA: ga_chord_to_set spells altered and diminished sevenths (ga-lab P5 too)
foreach (var c in new[] { "Cdim7", "Cm7b5" })
    Console.WriteLine($"ga_chord_to_set('{c}') -> {Fields(await ChordAtonalTool.GaChordToSet(c), "Pitch set", "Forte", "Prime form")}");

// music-theory-ga QA: ga_set_class_subs groups each chord under its own quality
foreach (var c in new[] { "Am", "G7" })
{
    var groups = Regex.Matches(await ChordAtonalTool.GaSetClassSubs(c), @"^\s*\[(\w+)\]\s*(.+?)\s*$", RegexOptions.Multiline)
        .Select(m => $"[{m.Groups[1].Value}] {OneLine(m.Groups[2].Value)}");
    Console.WriteLine($"ga_set_class_subs('{c}') -> {string.Join(" | ", groups)}");
}

// music-theory-ga entry of 2026-09-14: ga_icv_neighbors listed one set twelve times
Console.WriteLine($"ga_icv_neighbors('C', 1) -> {OneLine(await ChordAtonalTool.GaIcvNeighbors("C", 1))}");

// music-theory-ga QA: scale lookups by id and by mode name
Console.WriteLine($"ga_scale_by_id(2741) -> {Fields(ScaleTool.GaScaleById(2741), "Name", "Forte Number")}");
Console.WriteLine($"ga_scale_by_name('Dorian') -> {Fields(ScaleTool.GaScaleByName("Dorian"), "Name", "Binary Scale ID", "Forte Number")}");

// music-theory-ga QA: tools that answered "An error occurred"
try { Console.WriteLine($"get_neighboring_keys('Key of C') -> {JsonSerializer.Serialize(KeyTool.GetNeighboringKeys("Key of C"))}"); }
catch (Exception e) { Console.WriteLine($"get_neighboring_keys('Key of C') -> {e.GetType().Name}"); }

// fsharp QA: ChordParser.parse must read the whole symbol
foreach (var c in new[] { "C7sus4", "Am(maj7)", "Cmaj7" })
{
    var r = ChordParser.parse(c);
    Console.WriteLine(r.IsOk
        ? $"ChordParser.parse('{c}') -> Ok {OneLine(r.ResultValue.ToString())}"
        : $"ChordParser.parse('{c}') -> Error {Regex.Match(r.ErrorValue, @"Ln: \d+ Col: \d+").Value}");
}

// music-theory-ga QA: key detection (GA #625, #729)
foreach (var p in new[] { new[] { "Am", "F", "C", "G" }, new[] { "C", "G", "Am", "F" }, new[] { "Dm7", "G7", "Cmaj7" }, new[] { "Am", "Dm", "E7", "Am" }, new[] { "D", "C#7", "F#m" } })
{
    using var doc = JsonDocument.Parse(GaKeyFromProgressionTool.GaKeyFromProgression(p));
    var r = doc.RootElement;
    var cands = string.Join("; ", r.GetProperty("candidates").EnumerateArray().Select(x => $"{x.GetProperty("key").GetString()} {x.GetProperty("confidence").GetString()}"));
    Console.WriteLine($"ga_key_from_progression([{string.Join(",", p)}]) -> best {r.GetProperty("bestGuess").GetString()} | {cands}");
}
foreach (var s in new[] { "Am Dm E7 Am", "Dm7 G7 Cmaj7", "Am F C G" })
    Console.WriteLine($"ga_analyze_progression(\"{s}\") -> {OneLine(await GaDslTool.GaAnalyzeProgression(s))}");
