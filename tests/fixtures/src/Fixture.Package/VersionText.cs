namespace Fixture.Package;

/// <summary>Formats a build version for display.</summary>
public static class VersionText
{
    /// <summary>Returns <paramref name="version"/> prefixed with <c>v</c>, or <c>unversioned</c> when blank.</summary>
    public static string Format(string? version) =>
        string.IsNullOrWhiteSpace(version) ? "unversioned" : $"v{version.Trim()}";
}
