# GitHub Action: .NET Build/Test/Pack/Publish

> Note: this a beta action so prone to change, use with caution.

This GitHub Action builds multi-targetted .NET libraries and pushes the packages to both the official NuGet and also the GitHub Actions packages feeds. This action is expecting to find a single .NET solution file (.sln) in the base of your repository - and one or more class libraries with `<IsPackable>true</IsPackable>` set in the csproj file.

Note: `<IsPackable>true</IsPackable>` is a default setting in a csproj file, so be sure to disable IsPackable for other projects via a `Directory.Builds.Props` file else these other projects will be pushed to the NuGet feed as well!

Currently configured for the LTS versions;

- .NET Core 3.1
- .NET 6.0

## Examples

Minimal usage example;

```yaml
steps:

- uses: f2calv/gha-dotnet-nuget@main
  with:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

Complete usage example;

```yaml
steps:

- uses: f2calv/gha-dotnet-nuget@main
  id: dotnet
  with:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    NUGET_API_KEY: ${{ secrets.GITHUB_TOKEN }}
    BuildConfiguration: Release
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

- run: |
    echo "SemVer=${{ steps.dotnet.outputs.SemVer }}"
    echo "FullSemVer=${{ steps.dotnet.outputs.FullSemVer }}"
    echo "BuildConfiguration=${{ steps.dotnet.outputs.BuildConfiguration }}"
```

Here are fully working examples of this action in active use in my own public repositories;

- [gha-dotnet-nuget-test](https://github.com/f2calv/gha-dotnet-nuget-test) - uses this action via a [re-usable workflow](https://github.com/f2calv/gha-workflows/blob/main/.github/workflows/dotnet-publish-nuget-v1.yml) (this project can be used as a template of best practise if required)
- [CasCap.Common](https://github.com/f2calv/gha-dotnet-nuget-test) - uses this action [directly](https://github.com/f2calv/CasCap.Common/blob/main/.github/workflows/ci.yml).
- [CasCap.Apis.GooglePhotos](https://github.com/f2calv/CasCap.Apis.GooglePhotos) - uses this action via a [re-usable workflow](https://github.com/f2calv/gha-workflows/blob/main/.github/workflows/dotnet-publish-nuget-v1.yml).
- [CasCap.GooglePhotosCli](https://github.com/f2calv/CasCap.Apis.GooglePhotos) - uses this action via a [re-usable workflow](https://github.com/f2calv/gha-workflows/blob/main/.github/workflows/dotnet-publish-nuget-v1.yml).
- [yamlizr](https://github.com/f2calv/yamlizr) - uses this action via a [re-usable workflow](https://github.com/f2calv/gha-workflows/blob/main/.github/workflows/dotnet-publish-nuget-v1.yml).

## Inputs

- GITHUB_TOKEN, built-in GitHub Actions token i.e. `${{ secrets.GITHUB_TOKEN }}`, required parameter.
- NUGET_API_KEY, API key for your public NuGet account i.e. `${{ secrets.NUGET_API_KEY }}`, without this the NuGet package publish steps will be skipped.
- BuildConfiguration, .NET Build configuration parameter i.e. `Debug` or `Release`, default is `Release`
- PublishPreview, publish a pre-release package from a non-default branch - i.e. `true` or `false`, default is `false`

## Outputs

- SemVer, a simple semantic version created by the [GitVersion](https://github.com/GitTools/GitVersion) tool, i.e. 1.2.3
- FullSemVer, full semantic version plus branch name created by [GitVersion](https://github.com/GitTools/GitVersion) tool, i.e. 1.2.3-feature-bugfix-123
- BuildConfiguration, final build configuration that was used in the build, i.e. `Debug` or `Release`
  Note: Why? When passing in BuildConfiguration via a `workflow_dispatch` there is the potential for the inbound parameter to be an empty string.
