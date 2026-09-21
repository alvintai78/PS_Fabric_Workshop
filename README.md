# Microsoft Fabric Public-Sector Workshop

Half-day Microsoft Fabric workshop for data engineers, using a generic GovTech Singapore public-sector scenario: Citizen Service Operations Analytics.

## Scope

Participants build an end-to-end analytics flow. The workshop is only complete when each output below is produced and validated.

| Area | Participant Output | Validation |
| --- | --- | --- |
| Lakehouse | `CitizenServiceLH` with synthetic public-sector dimension and fact tables | Tables are visible, populated, and queryable |
| Semantic model | `CitizenServiceModel` built from lakehouse tables | Relationships and core DAX measures are created |
| Power BI report | `Citizen Service Operations Report` | Report includes executive, agency, service demand, citizen experience, and real-time operations views |
| Real-Time Intelligence | Eventstream/Eventhouse flow for service request events | KQL query, dashboard visual, and alert condition are created |
| Ontology / Fabric IQ | `CitizenServiceOntology` with public-sector business entities | Entity types, keys, properties, data bindings, and relationships are reviewed |
| Fabric Data Agent | `CitizenServiceDataAgent` connected to approved Fabric data sources | Agent answers approved operational questions using governed data sources |

Workshop capstone question:

> Can a data engineer trace one synthetic citizen service request from lakehouse storage, through semantic modeling and reporting, into real-time monitoring, ontology context, and data-agent Q&A?

## Deliverables

- [docs/workshop-guide.md](docs/workshop-guide.md)
- [docs/lab-manual.md](docs/lab-manual.md)
- [docs/powerpoint-outline.md](docs/powerpoint-outline.md)
- [data-schemas/dataset-structure.md](data-schemas/dataset-structure.md)
- [data/](data/) synthetic CSV dataset files
- [scripts/generate_sample_data.py](scripts/generate_sample_data.py) deterministic data generator
- [scripts/check_fabric_capacity_status.sh](scripts/check_fabric_capacity_status.sh) Fabric capacity status checker

## Check Fabric Capacity Status

Prerequisites:

- Azure CLI authenticated with `az login`
- Access to read the target subscription's Fabric capacities
- `jq`

Check every Fabric capacity in the current Azure subscription:

```bash
./scripts/check_fabric_capacity_status.sh
```

Check the workshop capacities in a specific subscription:

```bash
./scripts/check_fabric_capacity_status.sh \
  --subscription 0422f447-88de-4ecb-8320-c528c69160c0 \
  --resource-group-prefix rg_singapore-
```

Use `--no-color` for logs or `--json` for machine-readable output. The script
returns exit code `2` when at least one capacity or provisioning operation is
in a failed state.

## Dataset

The workshop includes generated synthetic CSV files:

| File | Rows |
| --- | ---: |
| [data/DimAgency.csv](data/DimAgency.csv) | 8 |
| [data/DimService.csv](data/DimService.csv) | 12 |
| [data/DimChannel.csv](data/DimChannel.csv) | 5 |
| [data/DimDate.csv](data/DimDate.csv) | 365 |
| [data/DimSLA.csv](data/DimSLA.csv) | 48 |
| [data/FactServiceRequest.csv](data/FactServiceRequest.csv) | 10,000 |
| [data/FactCitizenFeedback.csv](data/FactCitizenFeedback.csv) | 3,000 |
| [data/FactServiceEventStream.csv](data/FactServiceEventStream.csv) | 32,672 |

The data is fully synthetic and contains no real citizen or government-sensitive data.

To regenerate the CSVs:

```bash
python3 scripts/generate_sample_data.py
```

## Source Policy

Workshop steps are grounded in Microsoft Learn. Do not add Fabric product steps unless they are verified against Learn documentation.

Primary sources:

- https://learn.microsoft.com/fabric/data-engineering/tutorial-build-lakehouse
- https://learn.microsoft.com/power-bi/fundamentals/fabric-get-started
- https://learn.microsoft.com/fabric/fundamentals/building-reports
- https://learn.microsoft.com/fabric/real-time-intelligence/tutorial-introduction
- https://learn.microsoft.com/fabric/iq/overview
- https://learn.microsoft.com/fabric/iq/ontology/overview
- https://learn.microsoft.com/fabric/data-science/how-to-create-data-agent
