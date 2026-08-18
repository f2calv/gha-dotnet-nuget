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

oidc_response=$(curl --silent --show-error --fail-with-body \
  --header "Authorization: bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" \
  "${ACTIONS_ID_TOKEN_REQUEST_URL}&audience=$(jq -rn --arg a "$NUGET_AUDIENCE" '$a|@uri')")
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
  --data "$(jq -nc --arg u "$NUGET_USER" '{username: $u, tokenType: "ApiKey"}')")
api_key=$(jq -r '.apiKey // empty' <<<"$exchange_response")
if [[ -z "$api_key" ]]; then
  echo "::error title=Trusted Publishing::nuget.org did not return an apiKey. Check the policy owner, repository, workflow filename and environment on nuget.org."
  exit 1
fi
echo "::add-mask::$api_key"

echo "NUGETORG_API_KEY=$api_key" >> "$GITHUB_ENV"
echo "Short-lived nuget.org API key acquired for user $NUGET_USER, expires $(jq -r '.expires // "unknown"' <<<"$exchange_response")"
