#!/usr/bin/env bash
# Deploy the RTI HTTP event-generator Function App (Flex Consumption, secure
# identity-based storage + private endpoints) into a participant resource group.
#
# Mirrors the verified working stack in rg-sdp-fabric. Idempotent-ish: safe to
# re-run; existing resources are reused where possible.
#
# Usage: ./deploy_rti_function.sh <username> <resource-group> [subscription-id]
#   e.g. ./deploy_rti_function.sh binayak rg_binayak 00000000-0000-0000-0000-000000000000
#
# The subscription can be provided as the 3rd argument, via the AZURE_SUBSCRIPTION_ID
# environment variable, or it defaults to the current `az account` subscription.
set -euo pipefail

USER_NAME="${1:?username required}"
RG="${2:?resource group required}"

SUB="${3:-${AZURE_SUBSCRIPTION_ID:-$(az account show --query id -o tsv)}}"
: "${SUB:?subscription id required (pass as 3rd arg, set AZURE_SUBSCRIPTION_ID, or run az login)}"
LOCATION="${LOCATION:-westus3}"
ZIP="$(cd "$(dirname "$0")/.." && pwd)/rti-streaming/azure-function-http-bridge.zip"

VNET="vnet-${USER_NAME}"
INT_SUBNET="snet-func-integration"
PE_SUBNET="snet-private-endpoints"
UAMI="uami-${USER_NAME}"
# storage: <=24 chars, lowercase alphanumeric, globally unique
ST="st${USER_NAME}$(openssl rand -hex 3)"
ST="${ST:0:24}"
APP="func-rti-${USER_NAME}-$(openssl rand -hex 2)"
DEPLOY_CONTAINER="app-package"

echo "############################################################"
echo "# Deploying for ${USER_NAME} into ${RG}"
echo "#   VNet=${VNET}  Storage=${ST}  App=${APP}  UAMI=${UAMI}"
echo "############################################################"

az config set defaults.group="" >/dev/null 2>&1 || true

echo "=== 1. VNet + subnets ==="
az network vnet create -g "$RG" -n "$VNET" --subscription "$SUB" \
  --address-prefixes 172.0.0.0/16 \
  --subnet-name "$INT_SUBNET" --subnet-prefixes 172.0.1.0/24 -o none
az network vnet subnet update -g "$RG" --vnet-name "$VNET" -n "$INT_SUBNET" \
  --subscription "$SUB" --delegations Microsoft.App/environments -o none
az network vnet subnet create -g "$RG" --vnet-name "$VNET" -n "$PE_SUBNET" \
  --subscription "$SUB" --address-prefixes 172.0.2.0/24 -o none
echo "  subnets ready"

echo "=== 2. Storage account (secure: no shared key) ==="
az storage account create -g "$RG" -n "$ST" --subscription "$SUB" \
  --location "$LOCATION" --sku Standard_LRS --kind StorageV2 \
  --min-tls-version TLS1_2 --allow-shared-key-access false \
  --allow-blob-public-access false -o none
echo "  storage ${ST} created"

echo "=== 3. Deployment container (management-plane, works w/o public access) ==="
az storage container-rm create --storage-account "$ST" -g "$RG" \
  --subscription "$SUB" --name "$DEPLOY_CONTAINER" -o none
echo "  container ${DEPLOY_CONTAINER} created"

echo "=== 4. User-assigned managed identity ==="
az identity create -g "$RG" -n "$UAMI" --subscription "$SUB" --location "$LOCATION" -o none
UAMI_ID=$(az identity show -g "$RG" -n "$UAMI" --subscription "$SUB" --query id -o tsv)
UAMI_CLIENT=$(az identity show -g "$RG" -n "$UAMI" --subscription "$SUB" --query clientId -o tsv)
UAMI_PRINCIPAL=$(az identity show -g "$RG" -n "$UAMI" --subscription "$SUB" --query principalId -o tsv)
echo "  UAMI clientId=${UAMI_CLIENT}"

echo "=== 5. Role assignments (UAMI -> storage) ==="
STG_ID="/subscriptions/${SUB}/resourceGroups/${RG}/providers/Microsoft.Storage/storageAccounts/${ST}"
for ROLE in "Storage Blob Data Owner" "Storage Queue Data Contributor" "Storage Table Data Contributor"; do
  az role assignment create --assignee-object-id "$UAMI_PRINCIPAL" \
    --assignee-principal-type ServicePrincipal --role "$ROLE" \
    --scope "$STG_ID" -o none
  echo "  granted: $ROLE"
done

echo "=== 6. Private DNS zones + links ==="
VNET_ID=$(az network vnet show -g "$RG" -n "$VNET" --subscription "$SUB" --query id -o tsv)
for svc in blob queue table; do
  ZONE="privatelink.${svc}.core.windows.net"
  az network private-dns zone create -g "$RG" -n "$ZONE" --subscription "$SUB" -o none
  az network private-dns link vnet create -g "$RG" -n "link-${svc}" \
    --zone-name "$ZONE" --virtual-network "$VNET_ID" --registration-enabled false \
    --subscription "$SUB" -o none
  echo "  zone+link: $ZONE"
done

echo "=== 7. Private endpoints (blob/queue/table) ==="
for svc in blob queue table; do
  PE="pe-${ST}-${svc}"
  ZONE="privatelink.${svc}.core.windows.net"
  az network private-endpoint create -g "$RG" -n "$PE" \
    --vnet-name "$VNET" --subnet "$PE_SUBNET" \
    --private-connection-resource-id "$STG_ID" --group-id "$svc" \
    --connection-name "conn-${svc}" --subscription "$SUB" -o none
  az network private-endpoint dns-zone-group create -g "$RG" \
    --endpoint-name "$PE" -n "zg-${svc}" \
    --private-dns-zone "$ZONE" --zone-name "$svc" --subscription "$SUB" -o none
  echo "  PE: $PE"
done

echo "=== 8. Create Flex Consumption Function App (identity-based) ==="
az functionapp create -g "$RG" -n "$APP" --subscription "$SUB" \
  --storage-account "$ST" \
  --flexconsumption-location "$LOCATION" \
  --runtime python --runtime-version 3.13 \
  --instance-memory 2048 \
  --deployment-storage-name "$ST" \
  --deployment-storage-container-name "$DEPLOY_CONTAINER" \
  --deployment-storage-auth-type UserAssignedIdentity \
  --deployment-storage-auth-value "$UAMI_ID" \
  --vnet "$VNET" --subnet "$INT_SUBNET" \
  --disable-app-insights true -o none
echo "  app created"

echo "=== 9. Assign UAMI to app + identity-based AzureWebJobsStorage ==="
az functionapp identity assign -g "$RG" -n "$APP" --subscription "$SUB" \
  --identities "$UAMI_ID" -o none
az functionapp config appsettings set -g "$RG" -n "$APP" --subscription "$SUB" --settings \
  "AzureWebJobsStorage__blobServiceUri=https://${ST}.blob.core.windows.net" \
  "AzureWebJobsStorage__queueServiceUri=https://${ST}.queue.core.windows.net" \
  "AzureWebJobsStorage__tableServiceUri=https://${ST}.table.core.windows.net" \
  "AzureWebJobsStorage__credential=managedidentity" \
  "AzureWebJobsStorage__clientId=${UAMI_CLIENT}" \
  "DEFAULT_BATCH_SIZE=25" -o none
az functionapp config appsettings delete -g "$RG" -n "$APP" --subscription "$SUB" \
  --setting-names AzureWebJobsStorage -o none 2>/dev/null || true
echo "  settings applied"

echo "=== 10. Deploy code (remote build via OneDeploy) ==="
az functionapp restart -g "$RG" -n "$APP" --subscription "$SUB" -o none
az functionapp deployment source config-zip -g "$RG" -n "$APP" \
  --subscription "$SUB" --src "$ZIP"
echo "  code deployed"

echo "=== 11. Restart + summary ==="
az functionapp restart -g "$RG" -n "$APP" --subscription "$SUB" -o none
HOST=$(az resource show --ids "/subscriptions/${SUB}/resourceGroups/${RG}/providers/Microsoft.Web/sites/${APP}" --subscription "$SUB" --query "properties.defaultHostName" -o tsv)
KEY=$(az functionapp keys list -g "$RG" -n "$APP" --subscription "$SUB" --query "functionKeys.default" -o tsv)
echo "DONE ${USER_NAME}"
echo "  URL: https://${HOST}/api/events?code=${KEY}&batchSize=25"
