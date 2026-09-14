using System.ComponentModel;
using Microsoft.Extensions.Configuration;
using ModelContextProtocol;
using ModelContextProtocol.Server;

namespace LearnMcp;

[McpServerToolType]
public static class CourseTools
{
    [McpServerTool(Name = "course_outline", ReadOnly = true)]
    [Description("Lists the pages of a course of the learn site, in sidebar order: one line per page, file name and title.")]
    public static string CourseOutline(
        IConfiguration configuration,
        [Description("Course folder under src/content/docs, for example duckdb or ladybugdb")] string course)
    {
        // --docs <folder> on the server's command line, or the DOCS environment variable
        var docs = configuration["docs"]
            ?? throw new McpException("The server was started without --docs <folder>.");
        if (course.Length == 0 || course.Any(c => !(char.IsAsciiLetterLower(c) || char.IsAsciiDigit(c) || c == '-')))
        {
            throw new McpException($"'{course}' is not a course folder name.");
        }
        var folder = Path.Combine(docs, course);
        if (!Directory.Exists(folder))
        {
            throw new McpException($"No course '{course}' in the docs folder.");
        }

        var pages = Directory.EnumerateFiles(folder)
            .Where(file => file.EndsWith(".md") || file.EndsWith(".mdx"))
            .Select(file => (File: Path.GetFileName(file), Front: FrontMatter(file)))
            .OrderBy(page => page.Front.Order)
            .ThenBy(page => page.File, StringComparer.Ordinal)
            .Select(page => $"{page.File}: {page.Front.Title}");
        // One string: a string[] would come back as JSON, with non-ASCII characters escaped
        return string.Join('\n', pages);
    }

    private static (int Order, string Title) FrontMatter(string file)
    {
        var lines = File.ReadLines(file).Skip(1).TakeWhile(line => line != "---").ToList();
        var title = lines.FirstOrDefault(line => line.StartsWith("title:"))?["title:".Length..].Trim() ?? "";
        var order = lines.Select(line => line.Trim())
            .FirstOrDefault(line => line.StartsWith("order:"))?["order:".Length..].Trim();
        return (int.TryParse(order, out var value) ? value : int.MaxValue, title);
    }
}
