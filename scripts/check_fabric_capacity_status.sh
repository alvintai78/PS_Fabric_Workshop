#!/usr/bin/env bash
# Display the status of Microsoft Fabric capacities in an Azure subscription.
#
# Usage:
#   ./scripts/check_fabric_capacity_status.sh [options]
#
# Options:
#   -s, --subscription ID_OR_NAME   Azure subscription (defaults to current).
#   -p, --resource-group-prefix P   Show only resource groups with this prefix.
#       --json                      Print the filtered Azure response as JSON.
#       --no-color                  Disable color in table output.
#   -h, --help                      Show this help.
set -euo pipefail

API_VERSION="2023-11-01"
SUBSCRIPTION="${AZURE_SUBSCRIPTION_ID:-}"
RESOURCE_GROUP_PREFIX=""
OUTPUT_JSON=false
USE_COLOR=true

usage() {
  sed -n '2,13s/^# \{0,1\}//p' "$0"
}

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

while (($# > 0)); do
  case "$1" in
    -s | --subscription)
      (($# >= 2)) || fail "$1 requires a value"
      SUBSCRIPTION="$2"
      shift 2
      ;;
    -p | --resource-group-prefix)
      (($# >= 2)) || fail "$1 requires a value"
      RESOURCE_GROUP_PREFIX="$2"
      shift 2
      ;;
    --json)
      OUTPUT_JSON=true
      shift
      ;;
    --no-color)
      USE_COLOR=false
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      fail "unknown option: $1"
      ;;
  esac
done

command -v az >/dev/null 2>&1 || fail "Azure CLI (az) is required"
command -v jq >/dev/null 2>&1 || fail "jq is required"

az account show --output none 2>/dev/null ||
  fail "not signed in to Azure; run 'az login' first"

if [[ -z "$SUBSCRIPTION" ]]; then
  SUBSCRIPTION="$(az account show --query id --output tsv)"
fi

ACCOUNT_JSON="$(az account show --subscription "$SUBSCRIPTION" --output json 2>/dev/null)" ||
  fail "cannot access subscription '$SUBSCRIPTION'"
SUBSCRIPTION_ID="$(jq -r '.id' <<<"$ACCOUNT_JSON")"
SUBSCRIPTION_NAME="$(jq -r '.name' <<<"$ACCOUNT_JSON")"
TENANT_ID="$(jq -r '.tenantId' <<<"$ACCOUNT_JSON")"

CAPACITIES_JSON="$(
  az rest \
    --method get \
    --url "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/providers/Microsoft.Fabric/capacities?api-version=${API_VERSION}" \
    --output json
)" || fail "failed to retrieve Fabric capacities"

FILTERED_JSON="$(
  jq \
    --arg prefix "$RESOURCE_GROUP_PREFIX" \
    '[
      .value[]
      | .resourceGroup = (.id | split("/")[4])
      | select($prefix == "" or (.resourceGroup | startswith($prefix)))
    ]
    | sort_by(.resourceGroup, .name)' \
    <<<"$CAPACITIES_JSON"
)"

if [[ "$OUTPUT_JSON" == true ]]; then
  jq '.' <<<"$FILTERED_JSON"
  exit 0
fi

if [[ ! -t 1 || "${NO_COLOR:-}" != "" ]]; then
  USE_COLOR=false
fi

if [[ "$USE_COLOR" == true ]]; then
  BOLD=$'\033[1m'
  GREEN=$'\033[32m'
  YELLOW=$'\033[33m'
  RED=$'\033[31m'
  CYAN=$'\033[36m'
  RESET=$'\033[0m'
else
  BOLD=""
  GREEN=""
  YELLOW=""
  RED=""
  CYAN=""
  RESET=""
fi

TOTAL="$(jq 'length' <<<"$FILTERED_JSON")"
ACTIVE="$(jq '[.[] | select(.properties.state == "Active")] | length' <<<"$FILTERED_JSON")"
PAUSED="$(jq '[.[] | select(.properties.state == "Paused")] | length' <<<"$FILTERED_JSON")"
FAILED="$(jq '[.[] | select(.properties.state == "Failed" or .properties.provisioningState == "Failed")] | length' <<<"$FILTERED_JSON")"
OTHER=$((TOTAL - ACTIVE - PAUSED - FAILED))

printf '%sMicrosoft Fabric Capacity Status%s\n' "$BOLD" "$RESET"
printf 'Subscription : %s (%s)\n' "$SUBSCRIPTION_NAME" "$SUBSCRIPTION_ID"
printf 'Tenant       : %s\n' "$TENANT_ID"
if [[ -n "$RESOURCE_GROUP_PREFIX" ]]; then
  printf 'RG prefix    : %s\n' "$RESOURCE_GROUP_PREFIX"
fi
printf 'Checked      : %s\n\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')"

if ((TOTAL == 0)); then
  printf '%sNo Fabric capacities found.%s\n' "$YELLOW" "$RESET"
  exit 0
fi

printf '%-4s %-20s %-20s %-5s %-14s %-13s %-13s\n' \
  "#" "RESOURCE GROUP" "CAPACITY" "SKU" "LOCATION" "PROVISIONING" "STATE"
printf '%-4s %-20s %-20s %-5s %-14s %-13s %-13s\n' \
  "----" "--------------------" "--------------------" "-----" \
  "--------------" "-------------" "-------------"

ROW_NUMBER=0
while IFS=$'\t' read -r RESOURCE_GROUP NAME SKU LOCATION PROVISIONING STATE; do
  ROW_NUMBER=$((ROW_NUMBER + 1))
  case "$STATE" in
    Active)
      STATE_COLOR="$GREEN"
      ;;
    Paused)
      STATE_COLOR="$YELLOW"
      ;;
    Failed)
      STATE_COLOR="$RED"
      ;;
    *)
      STATE_COLOR="$CYAN"
      ;;
  esac

  printf '%-4s %-20s %-20s %-5s %-14s %-13s %s%-13s%s\n' \
    "$ROW_NUMBER" "$RESOURCE_GROUP" "$NAME" "$SKU" "$LOCATION" \
    "$PROVISIONING" "$STATE_COLOR" "$STATE" "$RESET"
done < <(
  jq -r '
    .[]
    | [
        .resourceGroup,
        .name,
        (.sku.name // "-"),
        (.location // "-"),
        (.properties.provisioningState // "Unknown"),
        (.properties.state // "Unknown")
      ]
    | @tsv
  ' <<<"$FILTERED_JSON"
)

printf '\n%sSummary%s  Total: %d  %sActive: %d%s  %sPaused: %d%s  %sFailed: %d%s  Other: %d\n' \
  "$BOLD" "$RESET" "$TOTAL" \
  "$GREEN" "$ACTIVE" "$RESET" \
  "$YELLOW" "$PAUSED" "$RESET" \
  "$RED" "$FAILED" "$RESET" \
  "$OTHER"

if ((ACTIVE > 0)); then
  printf '%sWarning: %d capacit%s currently active and may incur charges.%s\n' \
    "$YELLOW" "$ACTIVE" "$([[ "$ACTIVE" -eq 1 ]] && printf 'y is' || printf 'ies are')" "$RESET"
fi

if ((FAILED > 0)); then
  exit 2
fi
