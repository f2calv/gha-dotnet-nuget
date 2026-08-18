#!/usr/bin/env bash
# Runs 'dotnet test' in Microsoft.Testing.Platform (MTP) mode and gathers the cobertura coverage
# reports produced by Microsoft.Testing.Extensions.CodeCoverage into $GITHUB_WORKSPACE/coverage.
# Required environment variables: CONFIGURATION, GITHUB_WORKSPACE
# Optional environment variables: SOLUTION_NAME, DOTNET_TEST_ARGS

# Validate required environment variables before enabling strict mode
for var in CONFIGURATION GITHUB_WORKSPACE; do
  if [[ -z "${!var:-}" ]]; then
    echo "::error::Required environment variable $var is not set."
    exit 1
  fi
done

set -euo pipefail

: "${SOLUTION_NAME:=}"
: "${DOTNET_TEST_ARGS:=}"

#MTP mode rejects a positional path, the target must be named with --solution or --project.
#An empty value is legitimate, dotnet test then discovers the solution/project in the working directory.
target_args=()
case "$SOLUTION_NAME" in
  '') ;;
  *.sln | *.slnx) target_args=(--solution "$SOLUTION_NAME") ;;
  *.csproj) target_args=(--project "$SOLUTION_NAME") ;;
  *)
    echo "::error::solution-name '$SOLUTION_NAME' is not supported, expected a .sln, .slnx or .csproj file."
    exit 1
    ;;
esac

coverage_dir="$GITHUB_WORKSPACE/coverage"
coverage_filename=coverage.cobertura.xml

rm -rf "$coverage_dir"
mkdir -p "$coverage_dir"

#coverlet.msbuild (-p:CollectCoverage) and --collect are VSTest-era and are silently ignored under MTP.
#A bare --coverage-output filename lands in each test project's own TestResults folder, which keeps the
#reports distinct when a solution contains more than one test project. They are gathered up afterwards.
cmd=(dotnet test)
cmd+=("${target_args[@]}")
cmd+=(-c "$CONFIGURATION" --no-restore --no-build --nologo)
cmd+=(--coverage --coverage-output-format cobertura --coverage-output "$coverage_filename")

#dotnet-test-args is a free-form string, word splitting it here is intentional.
extra_args=()
read -ra extra_args <<<"$DOTNET_TEST_ARGS"
cmd+=("${extra_args[@]}")

echo "${cmd[*]}"
"${cmd[@]}"

report_count=0
while IFS= read -r -d '' report; do
  #Flatten the workspace-relative path into the filename so reports from sibling projects cannot collide.
  relative_path="${report#"$GITHUB_WORKSPACE"/}"
  cp "$report" "$coverage_dir/${relative_path//\//-}"
  report_count=$((report_count + 1))
done < <(find "$GITHUB_WORKSPACE" -type f -name "$coverage_filename" -not -path "$coverage_dir/*" -print0)

if [[ $report_count -eq 0 ]]; then
  echo "::warning title=Code coverage::No $coverage_filename reports were produced, is Microsoft.Testing.Extensions.CodeCoverage referenced by the test project(s)?"
else
  echo "Gathered $report_count coverage report(s) into $coverage_dir"
fi
