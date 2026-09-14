// Lesson 12: DateTime, decimal, System.IO and HttpClient, the C# side of each Java example.
using System.Globalization;
using System.Net;
using System.Net.Sockets;
using System.Text;

static class L12
{
    public static void Run()
    {
        Dates();
        Decimals();
        FilesAndText();
        Http().GetAwaiter().GetResult();
    }

    static void Dates()
    {
        Console.WriteLine("== dates");
        // TimeZoneInfo accepts IANA ids on every OS since .NET 6.
        var paris = TimeZoneInfo.FindSystemTimeZoneById("Europe/Paris");
        var noon = new DateTimeOffset(2026, 9, 13, 12, 0, 0, TimeSpan.Zero);
        Console.WriteLine($"in Paris: {TimeZoneInfo.ConvertTime(noon, paris):o}");

        Console.WriteLine($"a month after January 31: {new DateOnly(2026, 1, 31).AddMonths(1):yyyy-MM-dd}");
        try { _ = new DateOnly(2026, 2, 30); }
        catch (ArgumentOutOfRangeException e) { Console.WriteLine($"ArgumentOutOfRangeException: {e.Message}"); }

        // DateTimeOffset has an offset, not a zone: adding a day keeps +01:00 across the change to summer time.
        var saturdayNoon = new DateTimeOffset(2026, 3, 28, 12, 0, 0, TimeSpan.FromHours(1));
        Console.WriteLine($"AddDays(1): {saturdayNoon.AddDays(1):o}, in Paris: {TimeZoneInfo.ConvertTime(saturdayNoon.AddDays(1), paris):o}");

        // A local time that doesn't exist throws; one that happens twice gets the standard offset.
        try { TimeZoneInfo.ConvertTimeToUtc(new DateTime(2026, 3, 29, 2, 30, 0), paris); }
        catch (ArgumentException e) { Console.WriteLine($"ArgumentException: {e.Message}"); }
        Console.WriteLine($"02:30 on October 25: offset {paris.GetUtcOffset(new DateTime(2026, 10, 25, 2, 30, 0))}");

        // DateTime.Parse turns a UTC time into the machine's local time.
        Console.WriteLine($"DateTime.Parse(\"...Z\").Kind: {DateTime.Parse("2026-09-13T12:00:00Z", CultureInfo.InvariantCulture).Kind}");

        // In .NET, Y isn't a format specifier: it is copied as is.
        Console.WriteLine($"YYYY: {new DateTime(2026, 12, 31).ToString("YYYY-MM-dd", CultureInfo.InvariantCulture)}");
    }

    static void Decimals()
    {
        Console.WriteLine("== decimals");
        Console.WriteLine($"(decimal)0.1: {(decimal)0.1}");
        Console.WriteLine($"10.50m + 0.5m = {10.50m + 0.5m}");
        Console.WriteLine($"1.10m * 3 = {1.10m * 3}");

        // == and Equals ignore the scale.
        Console.WriteLine($"2.0m == 2.00m: {2.0m == 2.00m}, Equals: {2.0m.Equals(2.00m)}");
        Console.WriteLine($"HashSet count: {new HashSet<decimal> { 2.0m, 2.00m }.Count}");

        // Division rounds to 28 or 29 significant digits.
        decimal one = 1m;
        Console.WriteLine($"1m / 3m: {one / 3m}");

        // Math.Round rounds halves to even by default, for decimal and double.
        Console.WriteLine($"Math.Round(2.345m, 2): {Math.Round(2.345m, 2)}, AwayFromZero: {Math.Round(2.345m, 2, MidpointRounding.AwayFromZero)}");
        Console.WriteLine($"Math.Round(2.5): {Math.Round(2.5)}, Math.Round(-2.5): {Math.Round(-2.5)}");

        decimal max = decimal.MaxValue;
        try { _ = max + one; }
        catch (OverflowException e) { Console.WriteLine($"OverflowException: {e.Message}"); }
    }

    static void FilesAndText()
    {
        Console.WriteLine("== files and text");
        var dir = Directory.CreateTempSubdirectory("l12");
        try
        {
            var notes = Path.Combine(dir.FullName, "notes.txt");
            File.WriteAllText(notes, "pen\npad\nink\n");
            Console.WriteLine($"ReadAllLines: [{string.Join(", ", File.ReadAllLines(notes))}]");
            Console.WriteLine($"lines starting with p: {File.ReadLines(notes).Count(line => line.StartsWith('p'))}");

            try { File.ReadAllText(Path.Combine(dir.FullName, "missing.txt")); }
            catch (FileNotFoundException e) { Console.WriteLine($"FileNotFoundException: {Path.GetFileName(e.FileName)}"); }
            Directory.CreateDirectory(dir.FullName);
            Console.WriteLine("CreateDirectory: no exception");
            try { Directory.Delete(dir.FullName); }
            catch (IOException e) { Console.WriteLine($"Delete: {e.GetType().Name}"); }

            // Invalid UTF-8 is replaced, not reported.
            var broken = Path.Combine(dir.FullName, "broken.txt");
            File.WriteAllBytes(broken, [(byte)'A', 0xFF, (byte)'B']);
            Console.WriteLine($"ReadAllText: [{string.Join(", ", File.ReadAllText(broken).Select(c => $"U+{(int)c:X4}"))}]");
        }
        finally
        {
            dir.Delete(recursive: true);
        }

        Console.WriteLine($"France: {1234.5.ToString("F2", CultureInfo.GetCultureInfo("fr-FR"))}");
        Console.WriteLine($"Invariant: {1234.5.ToString("F2", CultureInfo.InvariantCulture)}");
        Console.WriteLine($"Turkish lower case has a dotless i: {"TITLE".ToLower(CultureInfo.GetCultureInfo("tr-TR")) == "tıtle"}");
    }

    static async Task Http()
    {
        Console.WriteLine("== http");
        using var listener = new HttpListener();
        listener.Prefixes.Add($"http://127.0.0.1:{FreePort()}/");
        listener.Start();
        _ = Task.Run(() => Serve(listener));
        var base_ = listener.Prefixes.Single().TrimEnd('/');

        using var client = new HttpClient();
        Console.WriteLine($"default timeout: {client.Timeout}");
        var old = await client.GetAsync($"{base_}/old");
        Console.WriteLine($"GET /old: {(int)old.StatusCode} {await old.Content.ReadAsStringAsync()} from {old.RequestMessage!.RequestUri!.AbsolutePath}");

        var missing = await client.GetAsync($"{base_}/missing");
        Console.WriteLine($"GET /missing: {(int)missing.StatusCode}");
        try { await client.GetStringAsync($"{base_}/missing"); }
        catch (HttpRequestException e) { Console.WriteLine($"GetStringAsync: HttpRequestException: {e.Message}"); }

        using var impatient = new HttpClient { Timeout = TimeSpan.FromMilliseconds(100) };
        try { await impatient.GetAsync($"{base_}/slow"); }
        catch (TaskCanceledException e) { Console.WriteLine($"TaskCanceledException ({e.InnerException?.GetType().Name}): {e.Message}"); }

        using var noRedirects = new HttpClient(new HttpClientHandler { AllowAutoRedirect = false });
        var redirect = await noRedirects.GetAsync($"{base_}/old");
        Console.WriteLine($"GET /old without redirects: {(int)redirect.StatusCode}, Location: {redirect.Headers.Location}");
    }

    static int FreePort()
    {
        using var socket = new TcpListener(IPAddress.Loopback, 0);
        socket.Start();
        return ((IPEndPoint)socket.LocalEndpoint).Port;
    }

    static async Task Serve(HttpListener listener)
    {
        while (listener.IsListening)
        {
            HttpListenerContext context;
            try { context = await listener.GetContextAsync(); }
            catch (Exception) { return; }
            _ = Task.Run(async () =>
            {
                var response = context.Response;
                switch (context.Request.Url!.AbsolutePath)
                {
                    case "/old":
                        response.StatusCode = 302;
                        response.RedirectLocation = "/new";
                        break;
                    case "/new":
                        response.OutputStream.Write(Encoding.UTF8.GetBytes("moved here"));
                        break;
                    case "/slow":
                        await Task.Delay(1_000);
                        break;
                    default:
                        response.StatusCode = 404;
                        break;
                }
                try { response.Close(); } catch (Exception) { }
            });
        }
    }
}
