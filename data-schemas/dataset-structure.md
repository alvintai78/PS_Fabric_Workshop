# Dataset Structure

Scenario: Citizen Service Operations Analytics for a generic public-sector organization.

The dataset is synthetic. It must not contain real citizen, agency-sensitive, or operationally sensitive data.

Generated CSV files are available in [../data/](../data/). The generator is [../scripts/generate_sample_data.py](../scripts/generate_sample_data.py).

Participants can load the generated CSV files directly, or manually create smaller samples using the structure below.

## Star Schema

Recommended model:

- `FactServiceRequest` connects to `DimAgency`, `DimService`, `DimDate`, `DimChannel`, and `DimSLA`.
- `FactCitizenFeedback` connects to `FactServiceRequest`, `DimDate`, and optionally `DimService`.
- `FactServiceEventStream` supports Real-Time Intelligence and can be landed in Eventhouse or Lakehouse depending on the lab path.

## DimAgency

| Column | Type | Notes |
| --- | --- | --- |
| AgencyId | Text | Primary key, for example `AGY001` |
| AgencyName | Text | Synthetic agency name |
| TeamId | Text | Team key |
| TeamName | Text | Synthetic team name |
| ServiceDomain | Text | Example: Transport, Housing, Grants, Licensing |
| Region | Text | Example: Central, East, West, North, North-East |

Starter rows:

| AgencyId | AgencyName | TeamId | TeamName | ServiceDomain | Region |
| --- | --- | --- | --- | --- | --- |
| AGY001 | Digital Services Office | TM001 | Citizen Portal Team | Digital Services | Central |
| AGY002 | Municipal Services Group | TM002 | Case Operations Team | Municipal Services | East |
| AGY003 | Business Licensing Office | TM003 | Licensing Review Team | Licensing | West |

## DimService

| Column | Type | Notes |
| --- | --- | --- |
| ServiceId | Text | Primary key |
| ServiceType | Text | Example: Permit Application |
| ServiceCategory | Text | Example: Licensing |
| DigitalMaturityLevel | Text | Example: Basic, Integrated, Proactive |
| IsCriticalService | Boolean | True or false |

Starter rows:

| ServiceId | ServiceType | ServiceCategory | DigitalMaturityLevel | IsCriticalService |
| --- | --- | --- | --- | --- |
| SVC001 | Permit Application | Licensing | Integrated | True |
| SVC002 | Service Feedback | Citizen Experience | Basic | False |
| SVC003 | Grant Status Check | Grants | Proactive | True |
| SVC004 | Facility Issue Report | Municipal Services | Integrated | True |

## DimChannel

| Column | Type | Notes |
| --- | --- | --- |
| ChannelId | Text | Primary key |
| ChannelName | Text | Web, Mobile App, Call Centre, Service Centre, Chatbot |
| ChannelType | Text | Digital, Assisted, Physical |

Starter rows:

| ChannelId | ChannelName | ChannelType |
| --- | --- | --- |
| CH001 | Web | Digital |
| CH002 | Mobile App | Digital |
| CH003 | Call Centre | Assisted |
| CH004 | Service Centre | Physical |
| CH005 | Chatbot | Digital |

## DimDate

| Column | Type | Notes |
| --- | --- | --- |
| DateKey | Integer | Format `YYYYMMDD` |
| Date | Date | Calendar date |
| Year | Integer | Calendar year |
| Quarter | Text | Example: Q1 |
| MonthNumber | Integer | 1 to 12 |
| MonthName | Text | Month name |
| WeekdayName | Text | Day name |
| IsWeekend | Boolean | True or false |
| IsPublicHoliday | Boolean | Synthetic flag for reporting |

## DimSLA

| Column | Type | Notes |
| --- | --- | --- |
| SLAId | Text | Primary key |
| ServiceId | Text | Foreign key to `DimService` |
| Priority | Text | Low, Normal, High, Urgent |
| TargetResolutionHours | Integer | SLA target |
| EscalationThresholdHours | Integer | Alert threshold |

Starter rows:

| SLAId | ServiceId | Priority | TargetResolutionHours | EscalationThresholdHours |
| --- | --- | --- | --- | --- |
| SLA001 | SVC001 | Normal | 72 | 48 |
| SLA002 | SVC001 | Urgent | 24 | 12 |
| SLA003 | SVC004 | High | 48 | 24 |
| SLA004 | SVC003 | Normal | 48 | 24 |

## FactServiceRequest

| Column | Type | Notes |
| --- | --- | --- |
| RequestId | Text | Primary key |
| DateKey | Integer | Submitted date key |
| ServiceId | Text | Foreign key |
| AgencyId | Text | Foreign key |
| ChannelId | Text | Foreign key |
| SLAId | Text | Foreign key |
| CitizenSegment | Text | Synthetic segment, not personal data |
| SubmittedDateTime | DateTime | Submission timestamp |
| ResolvedDateTime | DateTime | Blank if unresolved |
| Status | Text | New, In Progress, Pending Citizen, Resolved, Closed |
| Priority | Text | Low, Normal, High, Urgent |
| AssignedTeam | Text | Synthetic team name |
| ResolutionHours | Decimal | Calculated or entered |
| IsSLABreached | Boolean | True when resolution exceeds SLA |
| BacklogFlag | Boolean | True for open items |

Starter rows:

| RequestId | DateKey | ServiceId | AgencyId | ChannelId | SLAId | CitizenSegment | SubmittedDateTime | ResolvedDateTime | Status | Priority | AssignedTeam | ResolutionHours | IsSLABreached | BacklogFlag |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| REQ000001 | 20260501 | SVC001 | AGY003 | CH001 | SLA001 | Resident | 2026-05-01 09:15 | 2026-05-03 11:30 | Closed | Normal | Licensing Review Team | 50.25 | False | False |
| REQ000002 | 20260501 | SVC004 | AGY002 | CH002 | SLA003 | Resident | 2026-05-01 10:40 |  | In Progress | High | Case Operations Team |  | False | True |
| REQ000003 | 20260502 | SVC003 | AGY001 | CH005 | SLA004 | Business User | 2026-05-02 14:05 | 2026-05-05 16:10 | Closed | Normal | Citizen Portal Team | 74.08 | True | False |

## FactCitizenFeedback

| Column | Type | Notes |
| --- | --- | --- |
| FeedbackId | Text | Primary key |
| RequestId | Text | Foreign key |
| DateKey | Integer | Feedback date key |
| Rating | Integer | 1 to 5 |
| FeedbackCategory | Text | Wait Time, Usability, Clarity, Staff Support, Outcome |
| Sentiment | Text | Positive, Neutral, Negative |
| FeedbackDateTime | DateTime | Timestamp |

Starter rows:

| FeedbackId | RequestId | DateKey | Rating | FeedbackCategory | Sentiment | FeedbackDateTime |
| --- | --- | --- | --- | --- | --- | --- |
| FB000001 | REQ000001 | 20260503 | 4 | Clarity | Positive | 2026-05-03 12:05 |
| FB000002 | REQ000003 | 20260505 | 2 | Wait Time | Negative | 2026-05-05 17:00 |

## FactServiceEventStream

This is the generated historical event dataset for lakehouse reconciliation. A CSV file is not a streaming source by itself. For the Real-Time Intelligence lab, use the Azure Function HTTP event generator and connect Fabric Eventstream with the HTTP source connector.

The dataset is intentionally related to the lakehouse model through shared keys:

| Event stream column | Related table | Related column |
| --- | --- | --- |
| RequestId | FactServiceRequest | RequestId |
| ServiceId | DimService | ServiceId |
| AgencyId | DimAgency | AgencyId |
| ChannelId | DimChannel | ChannelId |

Keep [../data/FactServiceEventStream.csv](../data/FactServiceEventStream.csv) in the lakehouse model for reconciliation. For real-time streaming, deploy the Azure Function HTTP event generator in [../rti-streaming/azure-function-http-bridge/](../rti-streaming/azure-function-http-bridge/) and configure Fabric Eventstream **HTTP** source to poll the Function endpoint.

| Column | Type | Notes |
| --- | --- | --- |
| EventId | Text | Primary key |
| RequestId | Text | Related request |
| EventDateTime | DateTime | Event timestamp |
| ServiceId | Text | Related service |
| AgencyId | Text | Related agency |
| ChannelId | Text | Related channel |
| EventType | Text | Submitted, Assigned, StatusChanged, Escalated, Resolved |
| Status | Text | Current status |
| ProcessingDurationSeconds | Integer | Duration since previous event or stage |
| SLAElapsedPercent | Decimal | Percent of SLA consumed |

Starter rows:

| EventId | RequestId | EventDateTime | ServiceId | AgencyId | ChannelId | EventType | Status | ProcessingDurationSeconds | SLAElapsedPercent |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| EVT000001 | REQ000001 | 2026-05-01 09:15 | SVC001 | AGY003 | CH001 | Submitted | New | 0 | 0 |
| EVT000002 | REQ000001 | 2026-05-01 10:05 | SVC001 | AGY003 | CH001 | Assigned | In Progress | 3000 | 1.2 |
| EVT000003 | REQ000002 | 2026-05-01 10:40 | SVC004 | AGY002 | CH002 | Submitted | New | 0 | 0 |

## Recommended Volume For A Strong Report

The generated dataset already includes enough rows to show distribution and trends:

- `FactServiceRequest`: 10,000 rows over 12 months
- `FactServiceEventStream`: 32,672 event rows
- `FactCitizenFeedback`: 3,000 rows
- Dimensions: 5 to 365 rows each

Keep the values synthetic. Do not use real citizen data.

## Data Variation Rules

Use these rules when manually creating or expanding the sample data. The goal is to make the Power BI report show clear patterns, exceptions, and operational stories.

### Date And Demand Pattern

- Cover at least 12 months of request history.
- Make weekday volume higher than weekend volume.
- Add 2 to 3 visible monthly demand peaks.
- Add one short spike period for Real-Time Intelligence, for example a 2-hour increase in submitted events.
- Flag a few public holidays in `DimDate` so participants can compare holiday and nonholiday demand.

### Agency And Service Mix

- Use at least 5 agencies and 8 services for a better report.
- Make one agency responsible for the highest backlog.
- Make one service category responsible for most SLA breaches.
- Include both critical and noncritical services.
- Ensure every service has at least one matching SLA row.

### Status Distribution

Recommended `FactServiceRequest[Status]` mix:

| Status | Suggested Share |
| --- | --- |
| Closed / Resolved | 65-75% |
| In Progress | 12-18% |
| Pending Citizen | 5-10% |
| New | 3-7% |

### Priority Distribution

Recommended `FactServiceRequest[Priority]` mix:

| Priority | Suggested Share |
| --- | --- |
| Low | 10-15% |
| Normal | 55-65% |
| High | 15-25% |
| Urgent | 3-8% |

### SLA And Feedback Pattern

- Set overall SLA breach rate around 12-20%.
- Make urgent requests less common but more visible in SLA-risk reporting.
- Make negative feedback more likely when `IsSLABreached` is true.
- Keep average citizen rating between 3.4 and 4.2 overall.
- Create at least one low-performing service with lower ratings and higher breach rate.

### Channel Pattern

- Digital channels should represent most requests.
- Include enough assisted and physical channel rows to compare channel performance.
- Make Chatbot or Mobile App show faster average resolution for some services.
- Make Call Centre or Service Centre show higher volume for complex services.

## Power BI Report Requirements

Build the report so each page answers a clear operational question.

### Page 1: Executive Overview

Question: How healthy are citizen service operations overall?

Required visuals:

- KPI cards: Total Requests, Open Backlog, SLA Breach Rate, Average Resolution Hours, Average Citizen Rating
- Line chart: Requests by month
- Bar chart: SLA breaches by agency
- Donut or bar chart: Requests by channel
- Table or matrix: Top 10 services by backlog

### Page 2: Agency Performance

Question: Which agencies and teams need attention?

Required visuals:

- Bar chart: Open backlog by agency
- Bar chart: SLA breach count by team
- Scatter chart: Average resolution hours vs citizen rating by agency
- Matrix: Agency, team, service domain, total requests, backlog, SLA breach rate

### Page 3: Service Demand

Question: Which services drive demand and how does demand change over time?

Required visuals:

- Line chart: Requests by month and service category
- Bar chart: Total requests by service type
- Heat map or matrix: Weekday by channel request volume
- Slicer: Critical service flag

### Page 4: Citizen Experience

Question: Where is citizen experience strongest or weakest?

Required visuals:

- KPI card: Average Citizen Rating
- Bar chart: Feedback count by category
- Stacked bar chart: Sentiment by service category
- Line chart: Average rating by month
- Matrix: Service type, rating, negative feedback count, SLA breach rate

### Page 5: Real-Time Operations

Question: Are live events showing spikes or SLA risk?

Required visuals:

- Time chart: Event count by 15-minute interval
- Bar chart: Events by event type
- Table: Requests with high `SLAElapsedPercent`
- KPI card: Events in last hour
- Alert-ready visual: submitted events above normal threshold

## Recommended Slicers

Use these slicers across report pages:

- Date range
- Agency
- Service domain
- Service category
- Service type
- Channel
- Priority
- Status
- Critical service flag
- Region

## Suggested Measures

Create these measures in the semantic model where supported.

```dax
Total Requests = COUNTROWS(FactServiceRequest)

Open Backlog =
CALCULATE(
	COUNTROWS(FactServiceRequest),
	FactServiceRequest[BacklogFlag] = TRUE()
)

Resolved Requests =
CALCULATE(
	COUNTROWS(FactServiceRequest),
	FactServiceRequest[Status] IN { "Resolved", "Closed" }
)

SLA Breach Count =
CALCULATE(
	COUNTROWS(FactServiceRequest),
	FactServiceRequest[IsSLABreached] = TRUE()
)

SLA Breach Rate =
DIVIDE([SLA Breach Count], [Total Requests])

Average Resolution Hours =
AVERAGE(FactServiceRequest[ResolutionHours])

Average Citizen Rating =
AVERAGE(FactCitizenFeedback[Rating])

Feedback Count =
COUNTROWS(FactCitizenFeedback)

Negative Feedback Count =
CALCULATE(
	COUNTROWS(FactCitizenFeedback),
	FactCitizenFeedback[Sentiment] = "Negative"
)

Negative Feedback Rate =
DIVIDE([Negative Feedback Count], [Feedback Count])

Events Count =
COUNTROWS(FactServiceEventStream)

Escalated Events =
CALCULATE(
	COUNTROWS(FactServiceEventStream),
	FactServiceEventStream[EventType] = "Escalated"
)

Average SLA Elapsed Percent =
AVERAGE(FactServiceEventStream[SLAElapsedPercent])
```

## Quality Checks Before Reporting

Before building the report, validate the dataset:

- Every fact row has matching dimension keys.
- Every request has a valid `ServiceId`, `AgencyId`, `ChannelId`, `DateKey`, and `SLAId`.
- Closed or resolved requests have `ResolvedDateTime` and `ResolutionHours`.
- Open requests have `BacklogFlag = True`.
- At least 10% of records have `IsSLABreached = True`.
- Feedback rows reference valid request IDs.
- Event rows include multiple event types and enough timestamps to show time-based trends.
- No column contains real personal data.

## Microsoft Learn References

- Lakehouse tutorial: https://learn.microsoft.com/fabric/data-engineering/tutorial-build-lakehouse
- Semantic model and report tutorial: https://learn.microsoft.com/power-bi/fundamentals/fabric-get-started
- Real-Time Intelligence tutorial: https://learn.microsoft.com/fabric/real-time-intelligence/tutorial-introduction
- Ontology overview: https://learn.microsoft.com/fabric/iq/ontology/overview
- Ontology data binding: https://learn.microsoft.com/fabric/iq/ontology/how-to-bind-data
- Fabric Data Agent: https://learn.microsoft.com/fabric/data-science/how-to-create-data-agent
