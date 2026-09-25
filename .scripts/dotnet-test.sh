#!/usr/bin/env bash
# Runs an MTP-native 'dotnet test' command and gathers cobertura reports for ReportGenerator.
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

global_json="$GITHUB_WORKSPACE/global.json"
if ! command -v jq >/dev/null 2>&1; then
  echo "::error::jq is required to validate global.json."
  exit 1
fi
if ! jq -e '.test.runner == "Microsoft.Testing.Platform"' "$global_json" >/dev/null 2>&1; then
  echo "::error::global.json must select test.runner=Microsoft.Testing.Platform."
  exit 1
fi

coverage_dir="$GITHUB_WORKSPACE/coverage"
coverage_filename=coverage.cobertura.xml

rm -rf "$coverage_dir"
mkdir -p "$coverage_dir"

cmd=(dotnet test)
case "$SOLUTION_NAME" in
  '') ;;
  *.sln | *.slnx) cmd+=(--solution "$SOLUTION_NAME") ;;
  *.csproj) cmd+=(--project "$SOLUTION_NAME") ;;
  *)
    echo "::error::solution-name '$SOLUTION_NAME' is not supported, expected a .sln, .slnx or .csproj file."
    exit 1
    ;;
esac

#A bare --coverage-output filename lands in each test project's own TestResults folder, which keeps the
#reports distinct when a solution contains more than one test project. They are gathered up afterwards.
#Note: --nologo makes xUnit v3 discovery report "Zero tests ran", so it is deliberately absent.
cmd+=(-c "$CONFIGURATION" --no-restore --no-build)
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
