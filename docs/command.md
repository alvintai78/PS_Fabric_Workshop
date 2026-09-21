./scripts/check_fabric_capacity_status.sh \
  --subscription 0422f447-88de-4ecb-8320-c528c69160c0 \
  --resource-group-prefix rg_singapore-

  # Use current Azure subscription
./scripts/check_fabric_capacity_status.sh

# Disable terminal colors
./scripts/check_fabric_capacity_status.sh --no-color

# Machine-readable output
./scripts/check_fabric_capacity_status.sh --json

# Show help
./scripts/check_fabric_capacity_status.sh --help