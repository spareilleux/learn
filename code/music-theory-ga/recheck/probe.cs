#:project ../.ga-main/GaMcpServer/GaMcpServer.csproj
#:property TreatWarningsAsErrors=false
#:property PublishAot=false
#:property JsonSerializerIsReflectionEnabledByDefault=true
// Re-runs, on a later GA commit, the MCP tool calls and parser inputs this course and its
// neighbours (ga-lab, fsharp) recorded as wrong at a826864. Not part of check.sh: it needs a full
// GA clone and builds GaMcpServer, which the pinned sparse checkout does not contain.
//
//   git clone https://github.com/GuitarAlchemist/ga.git ../.ga-main
//   git -C ../.ga-main checkout 27a1257f7          # the commit results.txt was produced on
//   dotnet run probe.cs > results.txt
//
// The last two properties turn off the file-based app defaults (AOT, source-generated JSON) that
// GaMcpServer's reflection-based JsonSerializer calls do not support.
using System.Text.Json;
using GaMcpServer.Tools;
using GA.Business.DSL.Parsers;

GA.Business.DSL.GaClosureBootstrap.init();
string One(string s) => s.Replace("\r", "").Replace("\n", " / ");
foreach (var c in new[] { "Cdim7", "Cm7b5" }) Console.WriteLine($"ga_chord_to_set('{c}') -> {One(await ChordAtonalTool.GaChordToSet(c))}");
foreach (var c in new[] { "Am", "G7" }) Console.WriteLine($"ga_set_class_subs('{c}') -> {One(await ChordAtonalTool.GaSetClassSubs(c))}");
Console.WriteLine($"ga_icv_neighbors('C',1) -> {One(await ChordAtonalTool.GaIcvNeighbors("C", 1))}");
Console.WriteLine($"ga_scale_by_id(2741) -> {One(ScaleTool.GaScaleById(2741))}");
Console.WriteLine($"ga_scale_by_name('Dorian') -> {One(ScaleTool.GaScaleByName("Dorian"))}");
try { Console.WriteLine($"get_neighboring_keys('Key of C') -> {JsonSerializer.Serialize(KeyTool.GetNeighboringKeys("Key of C"))}"); }
catch (Exception e) { Console.WriteLine($"get_neighboring_keys('Key of C') -> {e.GetType().Name}: {e.Message}"); }
foreach (var c in new[] { "C7sus4", "Am(maj7)", "Cmaj7" }) Console.WriteLine($"ChordParser.parse('{c}') -> {(ChordParser.parse(c) is var r && r.IsOk ? "Ok " + One(r.ResultValue.ToString()) : "Error " + One(r.ErrorValue))}");

foreach (var p in new[] { new[] { "Am", "F", "C", "G" }, new[] { "Dm7", "G7", "Cmaj7" }, new[] { "Am", "Dm", "E7", "Am" } })
{
    using var doc = JsonDocument.Parse(GaKeyFromProgressionTool.GaKeyFromProgression(p));
    var r = doc.RootElement;
    var cands = string.Join("; ", r.GetProperty("candidates").EnumerateArray().Select(x => $"{x.GetProperty("key").GetString()} {x.GetProperty("confidence").GetString()}"));
    Console.WriteLine($"ga_key_from_progression([{string.Join(",", p)}]) -> best {r.GetProperty("bestGuess").GetString()} | {cands}");
}
foreach (var s in new[] { "Am Dm E7 Am", "Dm7 G7 Cmaj7", "Am F C G" })
    Console.WriteLine($"ga_analyze_progression(\"{s}\") -> {One(await GaDslTool.GaAnalyzeProgression(s))}");
