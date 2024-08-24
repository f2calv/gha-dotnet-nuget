# GitHub Action: .NET Build/Test/Pack/Publish

This GitHub Action builds .NET class libraries and pushes the packages to both the official NuGet feed and also GitHub Actions packages. This action by default is expecting to find a single .NET solution file (.sln) in the base of your repository - and one or more class libraries with `<IsPackable>true</IsPackable>` set in the csproj file(s).

Note: `<IsPackable>true</IsPackable>` is a default setting in a csproj file, so be sure to disable IsPackable for other projects via a `Directory.Builds.Props` file else these other projects will be pushed to the NuGet feed as well!

Currently configured for these .NET versions;

- .NET 8.0.x

## Examples

Minimal usage example;

```yaml
steps:

- uses: f2calv/gha-dotnet-nuget@v2
  with:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    version: 1.2.3
```

Complete usage example;

```yaml
steps:

- uses: f2calv/gha-dotnet-nuget@v2
  with:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    NUGET_API_KEY: ${{ secrets.GITHUB_TOKEN }}
    version: 1.2.3
    configuration: Release
```

Here are fully working examples of this action in active use in my own public repositories;

- [gha-dotnet-nuget-test](https://github.com/f2calv/gha-dotnet-nuget-test) - uses this action via a [re-usable workflow](https://github.com/f2calv/gha-workflows/blob/main/.github/workflows/dotnet-publish-nuget.yml) (this project can be used as a template of best practise if required)
- [CasCap.Common](https://github.com/f2calv/gha-dotnet-nuget-test) - uses this action [directly](https://github.com/f2calv/CasCap.Common/blob/main/.github/workflows/ci.yml).
- [CasCap.Apis.GooglePhotos](https://github.com/f2calv/CasCap.Apis.GooglePhotos) - uses this action via a [re-usable workflow](https://github.com/f2calv/gha-workflows/blob/main/.github/workflows/dotnet-publish-nuget.yml).
- [CasCap.GooglePhotosCli](https://github.com/f2calv/CasCap.Apis.GooglePhotos) - uses this action via a [re-usable workflow](https://github.com/f2calv/gha-workflows/blob/main/.github/workflows/dotnet-publish-nuget.yml).
- [yamlizr](https://github.com/f2calv/yamlizr) - uses this action via a [re-usable workflow](https://github.com/f2calv/gha-workflows/blob/main/.github/workflows/dotnet-publish-nuget.yml).

## Inputs

- GITHUB_TOKEN, built-in GitHub Actions token i.e. `${{ secrets.GITHUB_TOKEN }}`, required parameter.
- NUGET_API_KEY, API key for your public NuGet account i.e. `${{ secrets.NUGET_API_KEY }}`, without this the NuGet package publish steps will be skipped.
- version, NuGet package version e.g. 1.2.301-feature-my-feature.12
- configuration, .NET Configuration e.g. Debug or Release
- solution-name, Specify exactly which .NET solution or project to build when multiple exist. e.g. MySolution.sln or MyProject.csproj
- publish-preview, publish a pre-release package from a non-default branch - i.e. `true` or `false`, default is `false`

## Outputs

- configuration, final build configuration that was used in the build, i.e. `Debug` or `Release`
  Note: Why? When passing in BuildConfiguration via a `workflow_dispatch` there is the potential for the inbound parameter to be an empty string.
