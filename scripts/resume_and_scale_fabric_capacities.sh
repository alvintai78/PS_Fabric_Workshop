#!/usr/bin/env bash
# Resume Microsoft Fabric capacities and scale them to F64.
#
# The script performs a dry run unless --execute is provided.
#
# Usage:
#   ./scripts/resume_and_scale_fabric_capacities.sh [options]
#
# Options:
#   -s, --subscription ID_OR_NAME   Azure subscription (defaults to current).
#   -p, --resource-group-prefix P   Only process resource groups with this prefix.
#       --execute                   Apply resume and scale operations.
#       --yes                       Skip the interactive confirmation.
#       --timeout SECONDS           Per-operation timeout (default: 1800).
#       --no-color                  Disable color in status output.
#   -h, --help                      Show this help.
set -euo pipefail

API_VERSION="2023-11-01"
TARGET_SKU="F64"
SUBSCRIPTION="${AZURE_SUBSCRIPTION_ID:-}"
RESOURCE_GROUP_PREFIX=""
EXECUTE=false
ASSUME_YES=false
TIMEOUT_SECONDS=1800
NO_COLOR=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATUS_SCRIPT="${SCRIPT_DIR}/check_fabric_capacity_status.sh"

usage() {
  sed -n '2,17s/^# \{0,1\}//p' "$0"
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
    --execute)
      EXECUTE=true
      shift
      ;;
    --yes)
      ASSUME_YES=true
      shift
      ;;
    --timeout)
      (($# >= 2)) || fail "$1 requires a value"
      TIMEOUT_SECONDS="$2"
      shift 2
      ;;
    --no-color)
      NO_COLOR=true
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

[[ "$TIMEOUT_SECONDS" =~ ^[1-9][0-9]*$ ]] ||
  fail "--timeout must be a positive integer"

command -v az >/dev/null 2>&1 || fail "Azure CLI (az) is required"
command -v jq >/dev/null 2>&1 || fail "jq is required"
[[ -x "$STATUS_SCRIPT" ]] || fail "status script is missing or not executable: $STATUS_SCRIPT"

az account show --output none 2>/dev/null ||
  fail "not signed in to Azure; run 'az login' first"

if [[ -z "$SUBSCRIPTION" ]]; then
  SUBSCRIPTION="$(az account show --query id --output tsv)"
fi

ACCOUNT_JSON="$(az account show --subscription "$SUBSCRIPTION" --output json 2>/dev/null)" ||
  fail "cannot access subscription '$SUBSCRIPTION'"
SUBSCRIPTION_ID="$(jq -r '.id' <<<"$ACCOUNT_JSON")"
SUBSCRIPTION_NAME="$(jq -r '.name' <<<"$ACCOUNT_JSON")"

STATUS_ARGS=(--subscription "$SUBSCRIPTION_ID")
if [[ -n "$RESOURCE_GROUP_PREFIX" ]]; then
  STATUS_ARGS+=(--resource-group-prefix "$RESOURCE_GROUP_PREFIX")
fi
if [[ "$NO_COLOR" == true ]]; then
  STATUS_ARGS+=(--no-color)
fi

CAPACITIES_JSON="$(
  "$STATUS_SCRIPT" "${STATUS_ARGS[@]}" --json
)" || fail "failed to retrieve Fabric capacities"

TOTAL="$(jq 'length' <<<"$CAPACITIES_JSON")"
((TOTAL > 0)) || fail "no Fabric capacities matched the requested scope"

ALREADY_F64="$(jq --arg sku "$TARGET_SKU" '[.[] | select(.sku.name == $sku)] | length' <<<"$CAPACITIES_JSON")"
PAUSED="$(jq '[.[] | select(.properties.state == "Paused")] | length' <<<"$CAPACITIES_JSON")"
ACTIVE="$(jq '[.[] | select(.properties.state == "Active")] | length' <<<"$CAPACITIES_JSON")"
FAILED="$(jq '[.[] | select(.properties.state == "Failed" or .properties.provisioningState == "Failed")] | length' <<<"$CAPACITIES_JSON")"

printf 'Microsoft Fabric F64 Scale Plan\n'
printf 'Subscription : %s (%s)\n' "$SUBSCRIPTION_NAME" "$SUBSCRIPTION_ID"
printf 'Target SKU   : %s\n' "$TARGET_SKU"
printf 'Capacities   : %d total, %d paused, %d active, %d already F64\n' \
  "$TOTAL" "$PAUSED" "$ACTIVE" "$ALREADY_F64"
if [[ -n "$RESOURCE_GROUP_PREFIX" ]]; then
  printf 'RG prefix    : %s\n' "$RESOURCE_GROUP_PREFIX"
fi
printf '\n'

"$STATUS_SCRIPT" "${STATUS_ARGS[@]}"

((FAILED == 0)) ||
  fail "one or more capacities are already in a failed state"

if [[ "$EXECUTE" != true ]]; then
  printf '\nDRY RUN: no capacities were changed.\n'
  printf 'Re-run with --execute to resume all matched capacities and scale them to %s.\n' "$TARGET_SKU"
  exit 0
fi

if [[ "$ASSUME_YES" != true ]]; then
  [[ -t 0 ]] ||
    fail "interactive confirmation requires a terminal; use --yes for automation"

  printf '\nWARNING: This will make %d Fabric capacities active and scale them to %s.\n' \
    "$TOTAL" "$TARGET_SKU"
  printf 'Active F64 capacities can incur substantial Azure charges.\n'
  printf 'Type SCALE %d CAPACITIES TO %s to continue: ' "$TOTAL" "$TARGET_SKU"
  read -r CONFIRMATION
  [[ "$CONFIRMATION" == "SCALE ${TOTAL} CAPACITIES TO ${TARGET_SKU}" ]] ||
    fail "confirmation did not match; no changes were made"
fi

get_capacity() {
  local resource_id="$1"
  az rest \
    --method get \
    --url "https://management.azure.com${resource_id}?api-version=${API_VERSION}" \
    --output json
}

wait_for_active() {
  local resource_id="$1"
  local capacity_name="$2"
  local elapsed=0
  local state
  local provisioning_state

  while ((elapsed < TIMEOUT_SECONDS)); do
    CAPACITY_JSON="$(get_capacity "$resource_id")"
    state="$(jq -r '.properties.state // "Unknown"' <<<"$CAPACITY_JSON")"
    provisioning_state="$(jq -r '.properties.provisioningState // "Unknown"' <<<"$CAPACITY_JSON")"

    if [[ "$state" == "Active" && "$provisioning_state" == "Succeeded" ]]; then
      return 0
    fi
    if [[ "$state" == "Failed" || "$provisioning_state" == "Failed" ]]; then
      fail "${capacity_name} entered a failed state while resuming"
    fi

    sleep 10
    elapsed=$((elapsed + 10))
  done

  fail "timed out waiting for ${capacity_name} to become active"
}

wait_for_scale() {
  local resource_id="$1"
  local capacity_name="$2"
  local elapsed=0
  local sku
  local state
  local provisioning_state

  while ((elapsed < TIMEOUT_SECONDS)); do
    CAPACITY_JSON="$(get_capacity "$resource_id")"
    sku="$(jq -r '.sku.name // "Unknown"' <<<"$CAPACITY_JSON")"
    state="$(jq -r '.properties.state // "Unknown"' <<<"$CAPACITY_JSON")"
    provisioning_state="$(jq -r '.properties.provisioningState // "Unknown"' <<<"$CAPACITY_JSON")"

    if [[ "$sku" == "$TARGET_SKU" &&
      "$state" == "Active" &&
      "$provisioning_state" == "Succeeded" ]]; then
      return 0
    fi
    if [[ "$state" == "Failed" || "$provisioning_state" == "Failed" ]]; then
      fail "${capacity_name} entered a failed state while scaling"
    fi

    sleep 10
    elapsed=$((elapsed + 10))
  done

  fail "timed out waiting for ${capacity_name} to scale to ${TARGET_SKU}"
}

ROW_NUMBER=0
while IFS=$'\t' read -r RESOURCE_ID RESOURCE_GROUP NAME CURRENT_SKU CURRENT_STATE; do
  ROW_NUMBER=$((ROW_NUMBER + 1))
  printf '\n[%d/%d] %s (%s)\n' "$ROW_NUMBER" "$TOTAL" "$NAME" "$RESOURCE_GROUP"

  if [[ "$CURRENT_STATE" != "Active" ]]; then
    printf '  Resuming from %s...\n' "$CURRENT_STATE"
    az rest \
      --method post \
      --url "https://management.azure.com${RESOURCE_ID}/resume?api-version=${API_VERSION}" \
      --output none
    wait_for_active "$RESOURCE_ID" "$NAME"
  else
    printf '  Already active.\n'
  fi

  if [[ "$CURRENT_SKU" != "$TARGET_SKU" ]]; then
    printf '  Scaling from %s to %s...\n' "$CURRENT_SKU" "$TARGET_SKU"
    az rest \
      --method patch \
      --url "https://management.azure.com${RESOURCE_ID}?api-version=${API_VERSION}" \
      --headers 'Content-Type=application/json' \
      --body "{\"sku\":{\"name\":\"${TARGET_SKU}\",\"tier\":\"Fabric\"}}" \
      --output none
    wait_for_scale "$RESOURCE_ID" "$NAME"
  else
    printf '  Already on %s.\n' "$TARGET_SKU"
  fi

  printf '  VERIFIED: Active, %s, provisioning Succeeded.\n' "$TARGET_SKU"
done < <(
  jq -r '
    .[]
    | [
        .id,
        .resourceGroup,
        .name,
        (.sku.name // "Unknown"),
        (.properties.state // "Unknown")
      ]
    | @tsv
  ' <<<"$CAPACITIES_JSON"
)

printf '\nFinal capacity status\n'
"$STATUS_SCRIPT" "${STATUS_ARGS[@]}"

FINAL_JSON="$("$STATUS_SCRIPT" "${STATUS_ARGS[@]}" --json)"
FINAL_VALID="$(
  jq \
    --arg sku "$TARGET_SKU" \
    'all(.[];
      .sku.name == $sku and
      .properties.state == "Active" and
      .properties.provisioningState == "Succeeded"
    )' \
    <<<"$FINAL_JSON"
)"

[[ "$FINAL_VALID" == "true" ]] ||
  fail "final verification failed; inspect the status table above"

printf '\nSUCCESS: all %d matched capacities are Active on %s.\n' "$TOTAL" "$TARGET_SKU"
