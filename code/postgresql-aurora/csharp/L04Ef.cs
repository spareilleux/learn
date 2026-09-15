// Lesson 4: EF Core with the Npgsql provider, on GA's iconic chords
using Microsoft.EntityFrameworkCore;

namespace Learn.Pg;

// Mapped onto the table of sql/schema.sql: native arrays, no value converter
public class IconicChord
{
    public int Id { get; set; }
    public string Name { get; set; } = "";
    public string Artist { get; set; } = "";
    public short[] PitchClasses { get; set; } = [];
    public short[]? GuitarVoicing { get; set; }
    public List<string> AlternateNames { get; set; } = [];
}

public class ChordsContext : DbContext
{
    public DbSet<IconicChord> Chords => Set<IconicChord>();

    protected override void OnConfiguring(DbContextOptionsBuilder options) => options.UseNpgsql(Db.ConnectionString);

    protected override void OnModelCreating(ModelBuilder model) =>
        model.Entity<IconicChord>(entity =>
        {
            entity.ToTable("iconic_chords", "ga");
            entity.Property(c => c.Id).HasColumnName("chord_id");
            entity.Property(c => c.Name).HasColumnName("name");
            entity.Property(c => c.Artist).HasColumnName("artist");
            entity.Property(c => c.PitchClasses).HasColumnName("pitch_classes");
            entity.Property(c => c.GuitarVoicing).HasColumnName("guitar_voicing");
            entity.Property(c => c.AlternateNames).HasColumnName("alternate_names");
        });
}

// GA's entity and its configuration, from Common/GA.Infrastructure/Persistence/EntityFramework/MusicalKnowledgeDbContext.cs
// at commit 32f143c (MIT), reduced to the properties the lesson discusses
public class CachedIconicChord
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public List<int> PitchClasses { get; set; } = [];
    public List<int>? GuitarVoicing { get; set; }
    public List<string> AlternateNames { get; set; } = [];
    public DateTime LastUpdated { get; set; }
}

// EF Core builds a model once per context type: one class for each configuration
public abstract class GaStyleContext(bool withConverters) : DbContext
{
    public DbSet<CachedIconicChord> IconicChords => Set<CachedIconicChord>();

    protected override void OnConfiguring(DbContextOptionsBuilder options) => options.UseNpgsql(Db.ConnectionString);

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasDefaultSchema(withConverters ? "ef_ga" : "ef_native");
        modelBuilder.Entity<CachedIconicChord>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.Name);
            if (!withConverters)
            {
                return;
            }
            entity.Property(e => e.PitchClasses).HasConversion(
                v => string.Join(',', v),
                v => v.Split(',', StringSplitOptions.RemoveEmptyEntries).Select(int.Parse).ToList()
            );
            entity.Property(e => e.GuitarVoicing).HasConversion(
                v => v != null ? string.Join(',', v) : null,
                v => !string.IsNullOrEmpty(v)
                    ? v.Split(',', StringSplitOptions.RemoveEmptyEntries).Select(int.Parse).ToList()
                    : null
            );
            entity.Property(e => e.AlternateNames).HasConversion(
                v => string.Join('|', v),
                v => v.Split('|', StringSplitOptions.RemoveEmptyEntries).ToList()
            );
        });
    }
}

public class GaConvertersContext() : GaStyleContext(withConverters: true);

public class GaNativeContext() : GaStyleContext(withConverters: false);

static class L04Ef
{
    public static async Task Query()
    {
        await using var db = new ChordsContext();
        var withE = db.Chords
            .Where(c => c.PitchClasses.Contains((short)4) && c.GuitarVoicing != null)
            .OrderBy(c => c.Name)
            .Select(c => new { c.Name, c.GuitarVoicing, FirstAlias = c.AlternateNames[0] });
        Console.WriteLine(withE.ToQueryString());
        Console.WriteLine();
        foreach (var chord in await withE.ToListAsync())
        {
            Console.WriteLine($"{chord.Name}: [{string.Join(", ", chord.GuitarVoicing!)}] alias {chord.FirstAlias}");
        }
        Console.WriteLine();

        var aliases = db.Chords.Where(c => c.AlternateNames.Any(a => EF.Functions.ILike(a, "%beatles%"))).Select(c => c.Name);
        Console.WriteLine(aliases.ToQueryString());
        Console.WriteLine(string.Join(", ", await aliases.OrderBy(n => n).ToListAsync()));
    }

    public static async Task GaModel()
    {
        await using (var db = new GaConvertersContext())
        {
            Console.WriteLine("-- GA's configuration, with value converters");
            Console.WriteLine(db.Database.GenerateCreateScript().Trim());
            Console.WriteLine();
        }
        await using (var db = new GaNativeContext())
        {
            Console.WriteLine("-- the same entity, without converters");
            Console.WriteLine(db.Database.GenerateCreateScript().Trim());
            Console.WriteLine();
        }

        await using (var db = new GaNativeContext())
        {
            await db.Database.ExecuteSqlRawAsync("DROP SCHEMA IF EXISTS ef_native CASCADE");
            await db.Database.ExecuteSqlRawAsync(db.Database.GenerateCreateScript());
            db.IconicChords.Add(new CachedIconicChord
            {
                Name = "Hendrix Chord",
                PitchClasses = [4, 8, 11, 2, 7],
                GuitarVoicing = [0, 7, 6, 7, 8, 0],
                AlternateNames = ["Purple Haze Chord", "E7#9"],
                LastUpdated = DateTime.Now,
            });
            try
            {
                await db.SaveChangesAsync();
            }
            catch (DbUpdateException e)
            {
                Console.WriteLine($"{e.GetType().Name}: {e.Message}");
                Console.WriteLine($"  {e.InnerException!.GetType().Name}: {e.InnerException.Message}");
            }
        }

        // An empty string in a list: the array keeps it, GA's joined string loses it on the way back
        foreach (var db in new GaStyleContext[] { new GaNativeContext(), new GaConvertersContext() })
        {
            await using (db)
            {
                if (db is GaConvertersContext)
                {
                    await db.Database.ExecuteSqlRawAsync("DROP SCHEMA IF EXISTS ef_ga CASCADE");
                    await db.Database.ExecuteSqlRawAsync(db.Database.GenerateCreateScript());
                }
                db.IconicChords.Add(new CachedIconicChord
                {
                    Name = "Hendrix Chord",
                    PitchClasses = [4, 8, 11, 2, 7],
                    AlternateNames = ["Purple Haze Chord", "", "E7#9"],
                    LastUpdated = DateTime.UtcNow,
                });
                await db.SaveChangesAsync();
                var saved = await db.IconicChords.AsNoTracking().SingleAsync();
                Console.WriteLine($"{db.GetType().Name}: 3 alternate names saved, {saved.AlternateNames.Count} read back, LastUpdated.Kind={saved.LastUpdated.Kind}");
            }
        }
    }
}
