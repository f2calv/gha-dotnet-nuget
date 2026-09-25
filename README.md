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

# Push a pre-release package from a non-default branch, filtered to a specific package.
- uses: f2calv/gha-dotnet-nuget@v2
  with:
    version: 1.2.3-my-feature.4
    NUGET_API_KEY: ${{ secrets.NUGET_API_KEY }}
    push-preview: true
    package-filter: CasCap.Common.Caching
```

Trusted Publishing replaces the long-lived `NUGET_API_KEY` with a short-lived key exchanged from a GitHub Actions OIDC token. A composite action cannot request permissions, so the **calling job** must declare them:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      id-token: write #NuGet Trusted Publishing OIDC token
      contents: read
      packages: write #nuget.pkg.github.com
    steps:
      - uses: f2calv/gha-dotnet-nuget@v2
        with:
          version: 1.2.3
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          nuget-user: f2calv
```

The matching Trusted Publisher policy on nuget.org must name this repository, workflow filename and (if used) environment.

Some working examples of this action in active use in my own public repositories:

- [dotnet-nuget-test](https://github.com/f2calv/dotnet-nuget-test) - (this project can be used as a template of best practise if required)
- [CasCap.Common](https://github.com/f2calv/CasCap.Common)
- [CasCap.Api.Azure](https://github.com/f2calv/CasCap.Api.Azure)
- [CasCap.Api.GooglePhotos](https://github.com/f2calv/CasCap.Api.GooglePhotos)
- [SmartHaus](https://github.com/f2calv/SmartHaus)
- [yamlizr](https://github.com/f2calv/yamlizr)

## Inputs

| Input | Type | Required | Default | Description |
| ----- | ---- | -------- | ------- | ----------- |
| `version` | string | ✅ | | NuGet package version e.g. `1.2.301-feature-my-feature.12` |
| `GITHUB_TOKEN` | string | | | GitHub token to push to GitHub Packages e.g. `${{ secrets.GITHUB_TOKEN }}` |
| `nuget-user` | string | | | nuget.org profile username of the Trusted Publishing policy creator |
| `NUGET_API_KEY` | string | | | **DEPRECATED**, superseded by `nuget-user`. Ignored when `nuget-user` is set. |
| `checkout` | boolean | | `true` | Checkout the current repository |
| `checkout-ref` | string | | | Git ref to checkout e.g. `v1.2.3` or a commit SHA. Empty checks out the triggering ref. |
| `configuration` | string | | `Release` | .NET build configuration e.g. `Debug` or `Release` |
| `solution-name` | string | | | .NET solution or project to build e.g. `MySolution.slnx` or `MyProject.csproj`. Empty targets the working directory. |
| `push` | boolean | | `true` | Push packages to NuGet feeds |
| `push-preview` | boolean | | `false` | Push a pre-release NuGet package from a non-default branch. The version's SemVer pre-release suffix signals preview status to NuGet. |
| `execute-tests` | boolean | | `true` | Execute unit tests |
| `code-coverage` | boolean | | `true` | Execute code coverage tools |
| `dotnet-restore-args` | string | | | Optional extra arguments for `dotnet restore` |
| `dotnet-build-args` | string | | | Optional extra arguments for `dotnet build` |
| `dotnet-test-args` | string | | | Optional extra arguments for `dotnet test` |
| `dotnet-pack-args` | string | | | Optional extra arguments for `dotnet pack` |
| `dotnet-push-args` | string | | | Optional extra arguments for `dotnet nuget push` |
| `package-filter` | string | | | Comma-separated list of package ID prefixes to push e.g. `CasCap.Common.Caching,CasCap.Common.Extensions`. When empty all packages are pushed. |

`execute-tests` and `code-coverage` are opt-out controls. An empty value does not override their safe
defaults, and `execute-tests: false` is ignored on pull requests so a missing dispatch-only boolean
cannot silently remove the required test gate. Explicit opt-out remains available on other events.

## Push behaviour

| Scenario | nuget.org | GitHub Packages |
| --- | --- | --- |
| Default branch, `push: true` | ✅ | ✅ |
| Default branch, `push: false` | ❌ | ❌ |
| Non-default branch, `push-preview: true` | ✅ | ❌ |
| Non-default branch, `push-preview: false` | ❌ | ❌ |

Preview packages are only pushed to nuget.org — GitHub Packages is reserved for stable releases from the default branch. NuGet automatically recognises a package as pre-release when the version contains a SemVer pre-release suffix (e.g. `1.2.3-my-feature.4`).

Credential per feed:

- **nuget.org** — the short-lived key exchanged via Trusted Publishing when `nuget-user` is set, otherwise the deprecated `NUGET_API_KEY`. When neither is supplied the push is skipped with a warning.
- **GitHub Packages** — always `GITHUB_TOKEN`; Trusted Publishing does not apply.

### Package filtering

When `package-filter` is set, only `.nupkg` files whose filename starts with one of the specified prefixes are pushed. This is useful during preview pushes to avoid cluttering nuget.org with packages that haven't actually changed.

For example, if a solution produces `CasCap.Common.Caching`, `CasCap.Common.Extensions`, and `CasCap.Common.Serialization` packages, setting `package-filter: CasCap.Common.Caching` will push only the caching package.

## Testing and code coverage

The action requires [Microsoft.Testing.Platform](https://learn.microsoft.com/dotnet/core/testing/unit-testing-with-dotnet-test#mtp-mode-of-dotnet-test). Each consuming repository selects it in `global.json`:

```json
{
  "test": {
    "runner": "Microsoft.Testing.Platform"
  }
}
```

The action fails before testing when the file or selection is absent. VSTest fallback is deliberately
unsupported: `xunit.v3` 4.0.0 dropped the VSTest bridge, and this action follows the forward-only
.NET 10 test model.

MTP does not accept a positional path, so `solution-name` is translated into `--solution` (for `.sln` / `.slnx`) or `--project` (for `.csproj`). Any other value fails the step with an explicit error.

Coverage is collected by the [`Microsoft.Testing.Extensions.CodeCoverage`](https://learn.microsoft.com/dotnet/core/testing/unit-testing-platform-extensions-code-coverage) package, which each test project must reference. Remove these VSTest-era packages:

- `Microsoft.NET.Test.Sdk` — set `<OutputType>Exe</OutputType>` in the test project when removing it
- `xunit.runner.visualstudio`
- `coverlet.collector`
- `coverlet.msbuild`

### Coverage pipeline

1. `dotnet test` writes a cobertura report per test project and gathers the reports into `coverage/`.
2. `ReportGenerator` reads cobertura from `coverage/` and normalises it to lcov under `coveragereport/`.
3. Coveralls consumes the generated lcov, and `coveragereport/` is published as a build artifact.

## Outputs

| Output | Description |
| ------ | ----------- |
| `configuration` | Final build configuration used e.g. `Debug` or `Release`. Note: when `configuration` is passed via `workflow_dispatch` the value may be an empty string, so this output always provides a valid non-empty value. |
