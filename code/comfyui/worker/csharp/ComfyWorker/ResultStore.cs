using System.Security.Cryptography;
using System.Text.Json;
using System.Text.Json.Nodes;

namespace Learn.Comfy.Worker;

/// <summary>
/// Results on a shared directory, one folder per job id. It is also what makes the worker idempotent:
/// done.json says a job is finished, and a claim file, created with FileMode.CreateNew, lets only one
/// worker run a job at a time. In production this would be object storage and a database row with a unique key.
/// </summary>
public sealed class ResultStore(string root)
{
    public string Root => root;

    string JobDir(string jobId) => Path.Combine(root, jobId);

    public bool IsDone(string jobId) => File.Exists(Path.Combine(JobDir(jobId), "done.json"));

    /// <summary>True if this worker now owns the job. A claim older than its lease is taken over: its worker died.</summary>
    public bool TryClaim(string jobId, string owner, TimeSpan lease)
    {
        Directory.CreateDirectory(JobDir(jobId));
        string path = Path.Combine(JobDir(jobId), "claim");
        for (int tries = 0; tries < 2; tries++)
        {
            try
            {
                // CreateNew fails if the file exists, atomically, on every OS and on most network file systems.
                using var file = new FileStream(path, FileMode.CreateNew, FileAccess.Write);
                JsonSerializer.Serialize(file, new JsonObject { ["owner"] = owner, ["expires"] = DateTimeOffset.UtcNow.Add(lease) });
                return true;
            }
            catch (IOException) when (File.Exists(path))
            {
                var claim = ReadClaim(path);
                if (claim is null || claim.Value.Expires > DateTimeOffset.UtcNow) return false;
                File.Delete(path); // expired: try once more
            }
        }
        return false;
    }

    static (string Owner, DateTimeOffset Expires)? ReadClaim(string path)
    {
        try
        {
            var json = JsonNode.Parse(File.ReadAllText(path))!;
            return (json["owner"]!.GetValue<string>(), json["expires"]!.GetValue<DateTimeOffset>());
        }
        catch (Exception e) when (e is IOException or JsonException or InvalidOperationException)
        {
            return null; // being written by its owner, or already gone
        }
    }

    public void ReleaseClaim(string jobId, string owner)
    {
        string path = Path.Combine(JobDir(jobId), "claim");
        if (ReadClaim(path) is { } claim && claim.Owner == owner) File.Delete(path);
    }

    /// <summary>Writes an output file under a temporary name first: a crash never leaves a half file that looks finished.</summary>
    public async Task<StoredFile> SaveFileAsync(string jobId, string node, string name, byte[] bytes, CancellationToken cancel)
    {
        string dir = Path.Combine(JobDir(jobId), "outputs");
        Directory.CreateDirectory(dir);
        string final = Path.Combine(dir, $"{node}-{Path.GetFileName(name)}");
        string temp = final + ".partial";
        await File.WriteAllBytesAsync(temp, bytes, cancel);
        File.Move(temp, final, overwrite: true);
        return new StoredFile(node, Path.GetFileName(final), bytes.Length, Convert.ToHexStringLower(SHA256.HashData(bytes))[..16]);
    }

    public void Complete(string jobId, string owner, string instance, int attempt, IReadOnlyList<StoredFile> files)
    {
        var done = new JsonObject
        {
            ["job"] = jobId,
            ["worker"] = owner,
            ["gpu"] = instance,
            ["attempts"] = attempt,
            ["files"] = new JsonArray(files.Select(f => (JsonNode)new JsonObject { ["node"] = f.Node, ["name"] = f.Name, ["bytes"] = f.Bytes, ["sha256"] = f.Sha256 }).ToArray()),
        };
        string path = Path.Combine(JobDir(jobId), "done.json");
        File.WriteAllText(path + ".partial", done.ToJsonString(new JsonSerializerOptions { WriteIndented = true }));
        File.Move(path + ".partial", path, overwrite: true);
        ReleaseClaim(jobId, owner);
    }

    public void Fail(string jobId, string owner, string reason)
    {
        File.WriteAllText(Path.Combine(JobDir(jobId), "failed.txt"), reason + Environment.NewLine);
        ReleaseClaim(jobId, owner);
    }
}
