# Synthetic Workshop Data

This folder contains generated synthetic CSV files for the Microsoft Fabric public-sector workshop.

The data supports the Citizen Service Operations Analytics scenario and is intended for lakehouse loading, semantic modeling, Power BI reporting, Real-Time Intelligence, ontology, and data agent labs.

## Files

| File | Rows | Purpose |
| --- | ---: | --- |
| DimAgency.csv | 8 | Agency, team, domain, and region dimension |
| DimService.csv | 12 | Service type, category, maturity, and critical-service dimension |
| DimChannel.csv | 5 | Channel dimension |
| DimDate.csv | 365 | Date dimension from 2025-06-01 to 2026-05-31 |
| DimSLA.csv | 48 | SLA target by service and priority |
| FactServiceRequest.csv | 10,000 | Historical service request fact table |
| FactCitizenFeedback.csv | 3,000 | Citizen feedback fact table |
| FactServiceEventStream.csv | 32,672 | Event-style fact table for Real-Time Intelligence |

## Regenerate

From the repository root:

```bash
python3 scripts/generate_sample_data.py
```

The generator uses a fixed random seed, so output is reproducible.

## Data Policy

All records are synthetic. Do not replace them with real citizen, agency-sensitive, or operationally sensitive data unless the workshop has formal data approval.
