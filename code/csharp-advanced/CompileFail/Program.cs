// Compiles every snippet the lessons show as rejected, each alone, and checks that the compiler reports
// the error named on its first line ("// expect: CS8345"). Usage: CompileFail <snippets folder>
using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.CSharp;

var folder = args.Length == 1 ? args[0] : "snippets";

// The SDK's implicit usings for a console project, as a separate file so that line numbers stay the snippet's
const string implicitUsings = """
    global using System;
    global using System.Collections.Generic;
    global using System.IO;
    global using System.Linq;
    global using System.Net.Http;
    global using System.Threading;
    global using System.Threading.Tasks;
    """;

// The assemblies of the running .NET runtime
var references = ((string)AppContext.GetData("TRUSTED_PLATFORM_ASSEMBLIES")!)
    .Split(Path.PathSeparator)
    .Where(path => Path.GetFileName(path).StartsWith("System.") || Path.GetFileName(path) is "mscorlib.dll" or "netstandard.dll")
    .Select(path => MetadataReference.CreateFromFile(path))
    .ToList();

var parseOptions = new CSharpParseOptions(LanguageVersion.CSharp14);
var status = 0;

foreach (var file in Directory.GetFiles(folder, "*.cs").Order(StringComparer.Ordinal))
{
    var name = Path.GetFileName(file);
    var text = File.ReadAllText(file).ReplaceLineEndings("\n");
    var expected = text.Split('\n')[0].Replace("// expect:", "").Trim();
    var compilation = CSharpCompilation.Create(
        Path.GetFileNameWithoutExtension(file),
        [
            CSharpSyntaxTree.ParseText(implicitUsings, parseOptions, "GlobalUsings.g.cs"),
            CSharpSyntaxTree.ParseText(text, parseOptions, name),
        ],
        references,
        new CSharpCompilationOptions(OutputKind.DynamicallyLinkedLibrary, nullableContextOptions: NullableContextOptions.Enable, allowUnsafe: true));

    // Emit, not only GetDiagnostics(): some errors, such as CS4007, come from the rewriting of async methods.
    // Keep the errors, and the warning a snippet expects if it expects one
    var errors = compilation.Emit(Stream.Null).Diagnostics
        .Where(d => d.Severity == DiagnosticSeverity.Error || d.Id == expected)
        .OrderBy(d => d.Location.SourceSpan.Start)
        .ToList();

    Console.WriteLine($"== {name}");
    foreach (var error in errors)
    {
        var position = error.Location.GetLineSpan().StartLinePosition;
        Console.WriteLine($"{name}({position.Line + 1},{position.Character + 1}): {error.Severity.ToString().ToLowerInvariant()} {error.Id}: {error.GetMessage()}");
    }

    if (!errors.Any(e => e.Id == expected))
    {
        Console.WriteLine($"FAIL: expected {expected}");
        status = 1;
    }
}

return status;
