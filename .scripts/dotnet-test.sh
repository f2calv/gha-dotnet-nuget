#!/usr/bin/env bash
# Runs 'dotnet test' in whichever test runner mode the consuming repository has opted into and leaves
# coverage reports in $GITHUB_WORKSPACE/coverage for the ReportGenerator step to pick up.
# Microsoft.Testing.Platform (MTP) mode is selected by a global.json 'test.runner' opt-in and emits
# cobertura; every other repository keeps the legacy VSTest command line and emits coverlet lcov.
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

mtp_runner=Microsoft.Testing.Platform
global_json="$GITHUB_WORKSPACE/global.json"

#Runner detection is advisory, never fatal - a missing file, missing key, malformed JSON or a missing jq
#all mean "not opted in", which selects the backward compatible VSTest command line.
test_runner=''
if [[ ! -f "$global_json" ]]; then
  detection_reason="no global.json found at $global_json"
elif ! command -v jq >/dev/null 2>&1; then
  detection_reason="jq is unavailable so global.json could not be parsed"
elif ! test_runner=$(jq -er '.test.runner' "$global_json" 2>/dev/null); then
  test_runner=''
  detection_reason="global.json declares no .test.runner value (or is not valid JSON)"
else
  detection_reason="global.json declares .test.runner = $test_runner"
fi

coverage_dir="$GITHUB_WORKSPACE/coverage"
coverage_filename=coverage.cobertura.xml

rm -rf "$coverage_dir"
mkdir -p "$coverage_dir"

cmd=(dotnet test)

if [[ "$test_runner" == "$mtp_runner" ]]; then
  echo "Test runner mode: $mtp_runner ($detection_reason)"

  #MTP mode rejects a positional path, the target must be named with --solution or --project.
  #An empty value is legitimate, dotnet test then discovers the solution/project in the working directory.
  case "$SOLUTION_NAME" in
    '') ;;
    *.sln | *.slnx) cmd+=(--solution "$SOLUTION_NAME") ;;
    *.csproj) cmd+=(--project "$SOLUTION_NAME") ;;
    *)
      echo "::error::solution-name '$SOLUTION_NAME' is not supported, expected a .sln, .slnx or .csproj file."
      exit 1
      ;;
  esac

  #coverlet.msbuild (-p:CollectCoverage) and --collect are VSTest-era and are silently ignored under MTP.
  #A bare --coverage-output filename lands in each test project's own TestResults folder, which keeps the
  #reports distinct when a solution contains more than one test project. They are gathered up afterwards.
  #Note: --nologo is deliberately absent. In MTP mode it makes discovery report "Zero tests ran"
  #and exit 5, even though the same command without it runs the tests. Verified by bisection.
  cmd+=(-c "$CONFIGURATION" --no-restore --no-build)
  cmd+=(--coverage --coverage-output-format cobertura --coverage-output "$coverage_filename")
else
  echo "Test runner mode: VSTest ($detection_reason), opt into $mtp_runner by adding a test.runner entry to global.json."

  #VSTest mode takes the target as a bare positional path, an empty value discovers it in the working directory.
  if [[ -n "$SOLUTION_NAME" ]]; then
    cmd+=("$SOLUTION_NAME")
  fi

  #--nologo only breaks discovery under MTP, it is correct here. coverlet.msbuild writes lcov straight
  #into $coverage_dir so there is nothing to gather afterwards.
  cmd+=(-c "$CONFIGURATION" --no-restore --nologo --no-build)
  cmd+=(-p:CollectCoverage=true -p:CoverletOutputFormat=lcov -p:CoverletOutput="$coverage_dir/")
fi

#dotnet-test-args is a free-form string, word splitting it here is intentional.
extra_args=()
read -ra extra_args <<<"$DOTNET_TEST_ARGS"
cmd+=("${extra_args[@]}")

echo "${cmd[*]}"
"${cmd[@]}"

#Only MTP scatters its reports across the test projects, coverlet already wrote lcov into $coverage_dir.
if [[ "$test_runner" != "$mtp_runner" ]]; then
  exit 0
fi

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
