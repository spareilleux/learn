using System.IdentityModel.Tokens.Jwt;
using System.Net.Http.Headers;
using System.Security.Claims;
using System.Security.Cryptography;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using static Advanced.Report;

namespace Advanced;

// Lesson 16: authentication establishes identity; authorization applies policy to that identity.
public static class Lesson16
{
    private const string Issuer = "https://issuer.course.invalid";
    private const string Audience = "csharp-advanced";
    private static readonly DateTime CourseNow = new(2026, 9, 21, 12, 0, 0, DateTimeKind.Utc);

    public static void Run() => RunAsync().GetAwaiter().GetResult();

    private static async Task RunAsync()
    {
        var signingKey = new SymmetricSecurityKey(RandomNumberGenerator.GetBytes(32));
        var wrongKey = new SymmetricSecurityKey(RandomNumberGenerator.GetBytes(32));
        var builder = WebApplication.CreateSlimBuilder(new WebApplicationOptions
        {
            ApplicationName = typeof(Lesson16).Assembly.FullName,
            Args = [],
        });
        builder.Logging.ClearProviders();
        builder.WebHost.ConfigureKestrel(options => options.Listen(System.Net.IPAddress.Loopback, 0));
        builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
            .AddJwtBearer(options =>
            {
                options.MapInboundClaims = false;
                options.RequireHttpsMetadata = false;
                options.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidIssuer = Issuer,
                    ValidAudience = Audience,
                    IssuerSigningKey = signingKey,
                    ValidateIssuer = true,
                    ValidateAudience = true,
                    ValidateIssuerSigningKey = true,
                    ValidateLifetime = true,
                    LifetimeValidator = (notBefore, expires, _, _) =>
                        notBefore <= CourseNow && expires > CourseNow,
                };
            });
        builder.Services.AddAuthorizationBuilder()
            .AddPolicy("CanReadScales", policy => policy.RequireClaim("scope", "scales.read"));

        await using var app = builder.Build();
        app.UseAuthentication();
        app.UseAuthorization();
        app.MapGet("/api/scales/C", () => Results.Text("C major"))
            .RequireAuthorization("CanReadScales");

        await app.StartAsync().WaitAsync(TimeSpan.FromSeconds(5));
        using var client = CourseWebHost.Client(app);

        Title("JWT bearer authentication rejects unusable credentials");
        Line($"missing token: {await Status(client, null)}");
        Line($"malformed token: {await Status(client, "not-a-jwt")}");
        Line($"expired token: {await Status(client, Token(signingKey, [new Claim("scope", "scales.read")], CourseNow.AddMinutes(-1)))}");
        Line($"wrong signature: {await Status(client, Token(wrongKey, [new Claim("scope", "scales.read")], CourseNow.AddMinutes(5)))}");

        Title("A policy distinguishes authenticated from authorized");
        Line($"without required claim: {await Status(client, Token(signingKey, [], CourseNow.AddMinutes(5)))}");
        var authorized = Token(signingKey, [new Claim("scope", "scales.read")], CourseNow.AddMinutes(5));
        using var response = await Send(client, authorized);
        Line($"with required claim: {(int)response.StatusCode} {await response.Content.ReadAsStringAsync()}");

        await app.StopAsync().WaitAsync(TimeSpan.FromSeconds(5));
    }

    private static string Token(SecurityKey key, IEnumerable<Claim> claims, DateTime expires)
    {
        var token = new JwtSecurityToken(
            issuer: Issuer,
            audience: Audience,
            claims: claims,
            notBefore: CourseNow.AddMinutes(-5),
            expires: expires,
            signingCredentials: new SigningCredentials(key, SecurityAlgorithms.HmacSha256));
        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    private static async Task<int> Status(HttpClient client, string? token)
    {
        using var response = await Send(client, token);
        return (int)response.StatusCode;
    }

    private static Task<HttpResponseMessage> Send(HttpClient client, string? token)
    {
        var request = new HttpRequestMessage(HttpMethod.Get, "/api/scales/C");
        if (token is not null)
        {
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        }

        return client.SendAsync(request);
    }
}
