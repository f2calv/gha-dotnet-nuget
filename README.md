# GitHub Action: .NET Build/Test/Pack/Publish

This GitHub Action builds .NET class libraries and pushes the packages to both the official NuGet feed and also GitHub Actions packages. This action by default is expecting to find a single .NET solution file (.sln) in the base of your repository - and one or more class libraries with `<IsPackable>true</IsPackable>` set in the csproj file(s).

Note: `<IsPackable>true</IsPackable>` is a default setting in a csproj file, so be sure to disable IsPackable for other projects via a `Directory.Builds.Props` file else these other projects will be pushed to the NuGet feed as well!

Currently configured for these .NET versions;

- .NET 8.0.x
- .NET 9.0.x

## Examples



```yaml
steps:

#Minimal usage example will create packages but not push them.
- uses: f2calv/gha-dotnet-nuget@v2
  with:
    version: 1.2.3

#Create packages and push to GitHub packages feed.
- uses: f2calv/gha-dotnet-nuget@v2
  with:
    version: 1.2.3
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

#Complete usage example creates packages and pushes to both NuGet and GitHub packages feed.
- uses: f2calv/gha-dotnet-nuget@v2
  with:
    version: 1.2.3
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    NUGET_API_KEY: ${{ secrets.GITHUB_TOKEN }}
    configuration: Release
```

Some working examples of this action in active use in my own public repositories, the following projects use this action via a shared [re-usable workflow](https://github.com/f2calv/gha-workflows/blob/main/.github/workflows/dotnet-publish-nuget.yml);

- [gha-dotnet-nuget-test](https://github.com/f2calv/gha-dotnet-nuget-test) - (this project can be used as a template of best practise if required)
- [CasCap.Apis.GooglePhotos](https://github.com/f2calv/CasCap.Apis.GooglePhotos)
- [CasCap.GooglePhotosCli](https://github.com/f2calv/CasCap.Apis.GooglePhotos)
- [yamlizr](https://github.com/f2calv/yamlizr)

These projects use this action directly due to a non-standard testing process;

- [CasCap.Common](https://github.com/f2calv/gha-dotnet-nuget-test) - uses this action [directly](https://github.com/f2calv/CasCap.Common/blob/main/.github/workflows/ci.yml).

## Inputs

- version, NuGet package version e.g. 1.2.301-feature-my-feature.12, required parameter.
- GITHUB_TOKEN, built-in GitHub Actions token i.e. `${{ secrets.GITHUB_TOKEN }}`.
- NUGET_API_KEY, API key for your public NuGet account i.e. `${{ secrets.NUGET_API_KEY }}`, without this the NuGet package push steps will be skipped.
- configuration, .NET Configuration e.g. Debug or Release
- solution-name, Specify exactly which .NET solution or project to build when multiple exist. e.g. MySolution.sln or MyProject.csproj
- push-preview, push a pre-release package from a non-default branch - i.e. `true` or `false`, default is `false`

## Outputs

- configuration, final build configuration that was used in the build, i.e. `Debug` or `Release`
  Note: Why? When passing in configuration via a `workflow_dispatch` there is the potential for the inbound parameter to be an empty string so we set a value and output it.
