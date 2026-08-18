#!/bin/bash
# Exchanges a GitHub Actions OIDC id-token for a short-lived nuget.org API key (Trusted Publishing).
# Required environment variables: NUGET_USER, NUGET_AUDIENCE, NUGET_TOKEN_ENDPOINT, GITHUB_ENV,
# ACTIONS_ID_TOKEN_REQUEST_URL, ACTIONS_ID_TOKEN_REQUEST_TOKEN

# Validate required environment variables before enabling strict mode
for var in NUGET_USER NUGET_AUDIENCE NUGET_TOKEN_ENDPOINT GITHUB_ENV ACTIONS_ID_TOKEN_REQUEST_URL ACTIONS_ID_TOKEN_REQUEST_TOKEN; do
  if [[ -z "${!var:-}" ]]; then
    echo "::error::Required environment variable $var is not set."
    exit 1
  fi
done

set -euo pipefail

#Note: --fail-with-body writes the error body to stdout, but command substitution captures it
#and set -e would abort at the assignment, discarding the one thing worth reading. Trapping the
#status with '|| { ... }' keeps set -e out of the way so the body can be echoed.
oidc_response=$(curl --silent --show-error --fail-with-body \
  --header "Authorization: Bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" \
  "${ACTIONS_ID_TOKEN_REQUEST_URL}&audience=$(jq -rn --arg a "$NUGET_AUDIENCE" '$a|@uri')") || {
  rc=$?
  echo "::error title=OIDC::GitHub refused the id-token request (curl exit $rc)."
  echo "Response: $oidc_response"
  exit 1
}
oidc_token=$(jq -r '.value // empty' <<<"$oidc_response")
if [[ -z "$oidc_token" ]]; then
  echo "::error title=OIDC::GitHub did not return an id token."
  exit 1
fi
echo "::add-mask::$oidc_token"

exchange_response=$(curl --silent --show-error --fail-with-body \
  --request POST "$NUGET_TOKEN_ENDPOINT" \
  --header "Authorization: Bearer $oidc_token" \
  --header "Content-Type: application/json" \
  --header "User-Agent: f2calv/gha-dotnet-nuget" \
  --data "$(jq -nc --arg u "$NUGET_USER" '{username: $u, tokenType: "ApiKey"}')") || {
  rc=$?
  reason=$(jq -r '.error // empty' <<<"$exchange_response" 2>/dev/null || true)
  echo "::error title=Trusted Publishing::nuget.org rejected the token exchange (curl exit $rc)."
  echo "Response: ${reason:-$exchange_response}"
  echo "nuget-user must be the nuget.org username of the policy CREATOR, not the package owner."
  echo "The policy's repository owner, repository name, workflow filename and environment must all match this run."
  echo "Request was: POST $NUGET_TOKEN_ENDPOINT username=$NUGET_USER audience=$NUGET_AUDIENCE"
  exit 1
}
api_key=$(jq -r '.apiKey // empty' <<<"$exchange_response")
if [[ -z "$api_key" ]]; then
  echo "::error title=Trusted Publishing::nuget.org returned 200 but no apiKey. Response: $exchange_response"
  exit 1
fi
echo "::add-mask::$api_key"

echo "NUGETORG_API_KEY=$api_key" >> "$GITHUB_ENV"
echo "Short-lived nuget.org API key acquired for user $NUGET_USER, expires $(jq -r '.expires // "unknown"' <<<"$exchange_response")"
