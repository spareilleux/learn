using Slugs;
using Xunit;

namespace Slugs.Tests;

public class SlugTests
{
    [Theory]
    [InlineData("Hello, Wörld!", "hello-world")]
    [InlineData("  GitHub   Actions  ", "github-actions")]
    [InlineData("C# 14 & .NET 10", "c-14-net-10")]
    [InlineData("", "")]
    public void From_builds_a_lowercase_ascii_slug(string text, string expected) =>
        Assert.Equal(expected, Slug.From(text));
}