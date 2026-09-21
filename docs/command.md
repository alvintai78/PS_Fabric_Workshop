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

## Dry Run F64 Scaling

```bash
./scripts/resume_and_scale_fabric_capacities.sh \
  --subscription 0422f447-88de-4ecb-8320-c528c69160c0 \
  --resource-group-prefix rg_singapore-
```

## Apply F64 Scaling

```bash
./scripts/resume_and_scale_fabric_capacities.sh \
  --subscription 0422f447-88de-4ecb-8320-c528c69160c0 \
  --resource-group-prefix rg_singapore- \
  --execute
```

## Non-Interactive F64 Scaling

```bash
./scripts/resume_and_scale_fabric_capacities.sh \
  --subscription 0422f447-88de-4ecb-8320-c528c69160c0 \
  --resource-group-prefix rg_singapore- \
  --execute \
  --yes
```