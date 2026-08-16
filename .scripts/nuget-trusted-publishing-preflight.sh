#!/bin/bash
# Fails fast if the calling job did not grant id-token: write, which OIDC token exchange requires.

if [[ -z "${ACTIONS_ID_TOKEN_REQUEST_URL:-}" || -z "${ACTIONS_ID_TOKEN_REQUEST_TOKEN:-}" ]]; then
  echo "::error title=OIDC unavailable::The calling job must declare permissions: id-token: write to use Trusted Publishing."
  exit 1
fi
