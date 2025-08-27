#!/bin/bash
# Patch OIDC example with your Entra ID configuration
set -euo pipefail

NAMESPACE=${NAMESPACE:-oidc}

if [[ -z "${TENANT_ID:-}" || -z "${USER_GROUP_ID:-}" || -z "${ADMIN_GROUP_ID:-}" || -z "${CLIENT_ID:-}" || -z "${CLIENT_SECRET:-}" ]]; then
  echo "Usage: TENANT_ID=... USER_GROUP_ID=... ADMIN_GROUP_ID=... CLIENT_ID=... CLIENT_SECRET=... $0" >&2
  exit 1
fi

kubectl patch AccessControlPolicy.microgateway.airlock.com webserver -n "$NAMESPACE" --type='json' -p="[
  {\"op\": \"replace\", \"path\": \"/spec/policies/1/authorization/requireAll/0/oidc/claim/value/matcher/contains\", \"value\": \"$USER_GROUP_ID\"},
  {\"op\": \"replace\", \"path\": \"/spec/policies/2/authorization/requireAll/0/oidc/claim/value/matcher/contains\", \"value\": \"$ADMIN_GROUP_ID\"}
]"

kubectl patch JWKS webserver -n "$NAMESPACE" --type='json' -p="[
  {\"op\": \"replace\", \"path\": \"/spec/provider/remote/uri\", \"value\": \"https://login.microsoftonline.com/$TENANT_ID/discovery/v2.0/keys\"}
]"

kubectl patch secret oidc-client-password -n "$NAMESPACE" --type='json' -p="[
  {
    \"op\": \"replace\",
    \"path\": \"/data/client.secret\",
    \"value\": \"$(echo -n "$CLIENT_SECRET" | base64 | tr -d '\n')\"
  }
]"

kubectl patch OIDCProvider webserver -n "$NAMESPACE" --type='json' -p="[
  {\"op\": \"replace\", \"path\": \"/spec/static/issuer\", \"value\": \"https://login.microsoftonline.com/$TENANT_ID/v2.0\"},
  {\"op\": \"replace\", \"path\": \"/spec/static/endpoints/authorization/uri\", \"value\": \"https://login.microsoftonline.com/$TENANT_ID/oauth2/v2.0/authorize\"},
  {\"op\": \"replace\", \"path\": \"/spec/static/endpoints/token/uri\", \"value\": \"https://login.microsoftonline.com/$TENANT_ID/oauth2/v2.0/token\"}
]"

for rp in webserver-admin webserver-user; do
  kubectl patch OIDCRelyingParty "$rp" -n "$NAMESPACE" --type='json' -p="[
    {\"op\": \"replace\", \"path\": \"/spec/clientID\", \"value\": \"$CLIENT_ID\"}
  ]"
done