namespace Fixture.Package.Tests.Tests.Unit;

public sealed class VersionTextTests
{
    [Theory]
    [InlineData("1.2.3", "v1.2.3")]
    [InlineData(" 1.2.3 ", "v1.2.3")]
    [InlineData("", "unversioned")]
    [InlineData(null, "unversioned")]
    public void Format(string? version, string expected) =>
        Assert.Equal(expected, VersionText.Format(version));
}
