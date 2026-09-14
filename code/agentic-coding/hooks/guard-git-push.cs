// PreToolUse hook: refuses a shell command that runs "git push" with an option that deletes or rewrites
// remote branches. It reads the tool call as JSON on stdin; exit code 2 blocks the call, and stderr tells the agent why.
// Run it with: dotnet run guard-git-push.cs < call.json
using System.Text;
using System.Text.Json;

string command;
try
{
    using var input = JsonDocument.Parse(Console.In.ReadToEnd());
    // Claude Code and Codex both send the shell command as tool_input.command
    command = input.RootElement.TryGetProperty("tool_input", out var toolInput)
        && toolInput.TryGetProperty("command", out var value)
        && value.ValueKind == JsonValueKind.String
            ? value.GetString()!
            : "";
}
catch (JsonException e)
{
    // Exit code 1 is a non-blocking error: the agent goes on, and the user sees the message
    Console.Error.WriteLine($"guard-git-push: stdin is not JSON: {e.Message}");
    return 1;
}

foreach (var words in Shell.SimpleCommands(command))
{
    if (Git.DangerousPush(words) is { } reason)
    {
        Console.Error.WriteLine($"Blocked by guard-git-push: `{string.Join(' ', words)}` {reason}. Ask the user to run it.");
        return 2;
    }
}
return 0;

static class Git
{
    // Options of "git push" that delete or overwrite commits on the remote
    private static readonly string[] LongOptions = ["--delete", "--force", "--mirror", "--prune"];

    public static string? DangerousPush(List<string> words)
    {
        var i = 0;
        while (i < words.Count && words[i].Contains('=') && !words[i].StartsWith('-'))
        {
            i++; // environment assignments: GIT_TRACE=1 git push
        }
        if (i < words.Count && words[i] is "sh" or "bash" or "zsh" && i + 2 < words.Count && words[i + 1] == "-c")
        {
            // bash -c "git push --force": check the inner command too
            return Shell.SimpleCommands(words[i + 2]).Select(DangerousPush).FirstOrDefault(r => r is not null);
        }
        if (i >= words.Count || Path.GetFileNameWithoutExtension(words[i]) != "git")
        {
            return null;
        }
        i++;
        // Global options before the subcommand: git -C dir -c key=value push
        while (i < words.Count && words[i].StartsWith('-'))
        {
            i += words[i] is "-C" or "-c" ? 2 : 1;
        }
        if (i >= words.Count || words[i] != "push")
        {
            return null;
        }
        foreach (var word in words.Skip(i + 1))
        {
            if (LongOptions.Any(option => word == option || word.StartsWith(option + "-") || word.StartsWith(option + "=")))
            {
                return $"uses {word.Split('=')[0]}";
            }
            if (word.Length > 1 && word[0] == '-' && word[1] != '-' && word.Skip(1).Any(c => c is 'f' or 'd'))
            {
                return $"uses {word}";
            }
            if (word.StartsWith('+'))
            {
                return $"force-pushes the refspec {word}";
            }
            if (word.StartsWith(':'))
            {
                return $"deletes the remote ref {word[1..]}";
            }
        }
        return null;
    }
}

static class Shell
{
    // Splits a command line into simple commands, and each one into words, the way a POSIX shell quotes them.
    // Separators: newline ; & | && ||. Here-document bodies (<<EOF … EOF) are text, not commands.
    // Not handled: $(…), backquotes, functions, aliases. A hook is a guard rail, not a security boundary.
    public static IEnumerable<List<string>> SimpleCommands(string line)
    {
        var words = new List<string>();
        var word = new StringBuilder();
        var inWord = false;
        string? pendingHereDoc = null;
        for (var i = 0; i < line.Length; i++)
        {
            var c = line[i];
            if (c == '\'' || c == '"')
            {
                var end = line.IndexOf(c, i + 1);
                end = end < 0 ? line.Length : end;
                word.Append(line, i + 1, end - i - 1);
                inWord = true;
                i = end;
            }
            else if (c == '\\' && i + 1 < line.Length)
            {
                word.Append(line[++i]);
                inWord = true;
            }
            else if (c is ' ' or '\t' or '\r')
            {
                EndWord();
            }
            else if (c is '\n' or ';' or '&' or '|')
            {
                EndWord();
                if (words.Count > 0)
                {
                    yield return words;
                    words = [];
                }
                if (c == '\n' && pendingHereDoc is not null)
                {
                    // Skip the body, up to the line that holds only the delimiter
                    var bodyEnd = line.IndexOf("\n" + pendingHereDoc + "\n", i, StringComparison.Ordinal);
                    i = bodyEnd < 0 ? line.Length : bodyEnd + pendingHereDoc.Length + 1;
                    pendingHereDoc = null;
                }
            }
            else if (c == '<' && i + 1 < line.Length && line[i + 1] == '<')
            {
                EndWord();
                i += 2;
                if (i < line.Length && line[i] == '-') i++;
                while (i < line.Length && line[i] == ' ') i++;
                var start = i;
                while (i < line.Length && !char.IsWhiteSpace(line[i]) && line[i] is not ';' and not '&' and not '|') i++;
                pendingHereDoc = line[start..i].Trim('\'', '"');
                i--;
            }
            else
            {
                word.Append(c);
                inWord = true;
            }
        }
        EndWord();
        if (words.Count > 0)
        {
            yield return words;
        }

        void EndWord()
        {
            if (inWord)
            {
                words.Add(word.ToString());
                word.Clear();
                inWord = false;
            }
        }
    }
}
