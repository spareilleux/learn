using Npgsql;

namespace Learn.Pg;

static class Db
{
    // The server of server.sh; the course runs as postgres to keep the examples short (lesson 1 creates roles)
    public static string ConnectionString =>
        Environment.GetEnvironmentVariable("PG_CONNECTION")
        ?? "Host=localhost;Port=5432;Username=postgres;Password=learn;Database=learn;Application Name=learn-csharp";

    public static NpgsqlDataSource DataSource(string? extra = null) =>
        NpgsqlDataSource.Create(extra is null ? ConnectionString : $"{ConnectionString};{extra}");
}
