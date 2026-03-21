# GitHub Action: .NET Build/Test/Pack/Push

This GitHub Action builds .NET class libraries and pushes the packages to both the official NuGet feed and also GitHub Packages. This action by default is expecting to find a single .NET solution file (.sln) in the base of your repository - and one or more class libraries with `<IsPackable>true</IsPackable>` set in the csproj file(s).

Note: `<IsPackable>true</IsPackable>` is a default setting in a csproj file, so be sure to disable IsPackable for other projects via a `Directory.Builds.Props` file else these other projects will be pushed to the NuGet feed as well!

Currently configured for these .NET versions:

- .NET 8.0.x
- .NET 9.0.x
- .NET 10.0.x

## Examples

```yaml
steps:

# Minimal usage example will create packages but not push them.
- uses: f2calv/gha-dotnet-nuget@v2
  with:
    version: 1.2.3

# Create packages and push to GitHub Packages feed.
- uses: f2calv/gha-dotnet-nuget@v2
  with:
    version: 1.2.3
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

# Complete usage example creates packages and pushes to both NuGet and GitHub Packages feed.
- uses: f2calv/gha-dotnet-nuget@v2
  with:
    version: 1.2.3
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    NUGET_API_KEY: ${{ secrets.NUGET_API_KEY }}
    configuration: Release
```

Some working examples of this action in active use in my own public repositories, the following projects use this action via a shared [re-usable workflow](https://github.com/f2calv/gha-workflows/blob/main/.github/workflows/dotnet-publish-nuget.yml):

- [gha-dotnet-nuget-test](https://github.com/f2calv/gha-dotnet-nuget-test) - (this project can be used as a template of best practise if required)
- [CasCap.Apis.GooglePhotos](https://github.com/f2calv/CasCap.Apis.GooglePhotos)
- [CasCap.GooglePhotosCli](https://github.com/f2calv/CasCap.Apis.GooglePhotos)
- [yamlizr](https://github.com/f2calv/yamlizr)

These projects use this action directly due to a non-standard testing process:

- [CasCap.Common](https://github.com/f2calv/CasCap.Common) - uses this action [directly](https://github.com/f2calv/CasCap.Common/blob/main/.github/workflows/ci.yml).

## Inputs

| Input | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `version` | string | ✅ | | NuGet package version e.g. `1.2.301-feature-my-feature.12` |
| `GITHUB_TOKEN` | string | | | GitHub token to push to GitHub Packages e.g. `${{ secrets.GITHUB_TOKEN }}` |
| `NUGET_API_KEY` | string | | | NuGet API key for nuget.org e.g. `${{ secrets.NUGET_API_KEY }}`. Without this the nuget.org push step is skipped. |
| `checkout` | boolean | | `true` | Checkout the current repository |
| `configuration` | string | | `Release` | .NET build configuration e.g. `Debug` or `Release` |
| `solution-name` | string | | | Specify exactly which .NET solution or project to build when multiple exist e.g. `MySolution.sln` or `MyProject.csproj` |
| `push` | boolean | | `true` | Push packages to NuGet feeds |
| `push-preview` | boolean | | `false` | Push a pre-release package from a non-default branch |
| `execute-tests` | boolean | | `true` | Execute unit tests |
| `code-coverage` | boolean | | `true` | Execute code coverage tools |
| `dotnet-restore-args` | string | | | Optional extra arguments for `dotnet restore` |
| `dotnet-build-args` | string | | | Optional extra arguments for `dotnet build` |
| `dotnet-test-args` | string | | | Optional extra arguments for `dotnet test` |
| `dotnet-pack-args` | string | | | Optional extra arguments for `dotnet pack` |
| `dotnet-push-args` | string | | | Optional extra arguments for `dotnet nuget push` |

## Outputs

| Output | Description |
|--------|-------------|
| `configuration` | Final build configuration used e.g. `Debug` or `Release`. Note: when `configuration` is passed via `workflow_dispatch` the value may be an empty string, so this output always provides a valid non-empty value. |
