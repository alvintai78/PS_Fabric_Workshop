# Workshop Guide

Title: Microsoft Fabric Public-Sector Analytics Workshop

Duration: Half day

Audience: Data engineers

Scenario: Citizen Service Operations Analytics for a generic public-sector organization.

## Objectives

Participants will build a Fabric analytics flow that includes:

1. Lakehouse
2. Semantic model
3. Power BI report
4. Real-Time Intelligence
5. Ontology / Fabric IQ
6. Fabric Data Agent

## Definition Of Done

The workshop is complete only when participants can demonstrate these outputs:

| Area | Required Output | Evidence |
| --- | --- | --- |
| Lakehouse | `CitizenServiceLH` with the approved synthetic tables | Tables can be opened and queried |
| Semantic model | `CitizenServiceModel` with relationships and measures | Model view shows relationships; measures return values |
| Power BI report | `Citizen Service Operations Report` | At least five report pages or sections answer the required business questions |
| Real-Time Intelligence | Event flow for service request events | KQL query, dashboard tile, and alert condition exist |
| Ontology / Fabric IQ | `CitizenServiceOntology` | Entity types, properties, keys, data bindings, and relationships are reviewed |
| Fabric Data Agent | `CitizenServiceDataAgent` | Agent answers approved operational questions from configured Fabric sources |

Capstone validation:

1. Pick one synthetic service request.
2. Locate it in the lakehouse.
3. Show how it contributes to semantic model measures.
4. Show it in a Power BI visual.
5. Show related events or SLA risk in Real-Time Intelligence.
6. Explain its business meaning through ontology entities and relationships.
7. Ask the data agent a governed question that references the same service, agency, SLA, or feedback context.

## Agenda

| Time | Module | Outcome |
| --- | --- | --- |
| 0:00-0:15 | Setup | Confirm access, capacity, workspace, preview settings |
| 0:15-1:00 | Lakehouse | Create lakehouse and load synthetic tables |
| 1:00-1:40 | Semantic model | Create relationships and measures |
| 1:40-2:10 | Power BI report | Build operational report pages |
| 2:10-3:00 | Real-Time Intelligence | Create event flow, dashboard, alert |
| 3:00-3:35 | Ontology / Fabric IQ | Create or generate ontology, bind data |
| 3:35-4:00 | Fabric Data Agent | Connect data sources and test Q&A |

## Prerequisites

Confirm these before running the workshop:

- A Microsoft Fabric-enabled workspace and capacity.
- Required workspace permissions.
- Access to create lakehouse, semantic model, Power BI report, Real-Time Intelligence items, ontology, and data agent.
- Ontology / Fabric IQ preview enabled where required.
- Graph tenant setting enabled if using ontology graph.
- Fabric Data Agent tenant settings and capacity requirements reviewed.

Microsoft Learn references:

- Workspaces: https://learn.microsoft.com/fabric/fundamentals/create-workspaces
- Capacity: https://learn.microsoft.com/fabric/enterprise/licenses#capacity
- Lakehouse prerequisites: https://learn.microsoft.com/fabric/data-engineering/create-lakehouse
- Real-Time Intelligence prerequisites: https://learn.microsoft.com/fabric/real-time-intelligence/tutorial-introduction
- Ontology tenant settings: https://learn.microsoft.com/fabric/iq/ontology/overview-tenant-settings
- Data Agent prerequisites: https://learn.microsoft.com/fabric/data-science/how-to-create-data-agent

## Dataset

Use the schema in [../data-schemas/dataset-structure.md](../data-schemas/dataset-structure.md).

Generated synthetic CSV files are available in [../data/](../data/). Participants should load these files unless the facilitator chooses the smaller manual starter-row path. Do not use real citizen, government-sensitive, or operationally sensitive data.

## Module 1: Lakehouse

Goal: Create a lakehouse and load the synthetic public-sector service data.

High-level steps:

1. Open the Fabric workspace.
2. Create a lakehouse.
3. Create or load the dimension and fact tables from the approved schema.
4. Validate that the tables are visible in the lakehouse.
5. Use the SQL analytics endpoint to inspect tables where appropriate.

Completion criteria:

- All required tables from the dataset structure exist.
- Fact tables contain rows for at least service requests, feedback, and events.
- Dimension keys match fact table foreign keys.
- A participant can inspect or query at least one fact table.

Recommended item names:

- Workspace: `Fabric_PublicSector_Workshop`
- Lakehouse: `CitizenServiceLH`

Microsoft Learn source:

- https://learn.microsoft.com/fabric/data-engineering/tutorial-build-lakehouse
- https://learn.microsoft.com/fabric/data-engineering/create-lakehouse

## Module 2: Semantic Model

Goal: Create a semantic model from lakehouse tables.

Recommended model name:

- `CitizenServiceModel`

Relationships:

| From table column | To table column | Cardinality | Cross filter direction |
| --- | --- | --- | --- |
| FactServiceRequest[AgencyId] | DimAgency[AgencyId] | Many to one (*:1) | Single |
| FactServiceRequest[ServiceId] | DimService[ServiceId] | Many to one (*:1) | Single |
| FactServiceRequest[ChannelId] | DimChannel[ChannelId] | Many to one (*:1) | Single |
| FactServiceRequest[DateKey] | DimDate[DateKey] | Many to one (*:1) | Single |
| FactServiceRequest[SLAId] | DimSLA[SLAId] | Many to one (*:1) | Single |
| FactCitizenFeedback[RequestId] | FactServiceRequest[RequestId] | Many to one (*:1) | Single |

Measure table:

When using **New table** to create a dedicated measure table, Fabric requires at least one column. Create this table first:

```dax
_Measures = DATATABLE("MeasureGroup", STRING, {{"Service Operations"}})
```

Then select `_Measures` and create the measures below. The `MeasureGroup` column is only a dummy column and can be hidden from report view if the option is available.

Suggested measures:

```dax
Total Requests = COUNTROWS(FactServiceRequest)
Open Backlog = CALCULATE(COUNTROWS(FactServiceRequest), FactServiceRequest[BacklogFlag] = TRUE())
SLA Breach Count = CALCULATE(COUNTROWS(FactServiceRequest), FactServiceRequest[IsSLABreached] = TRUE())
Average Resolution Hours = AVERAGE(FactServiceRequest[ResolutionHours])
Average Citizen Rating = AVERAGE(FactCitizenFeedback[Rating])
```

Completion criteria:

- Relationships are created between fact and dimension tables.
- `_Measures` table is created for DAX measures.
- Core measures return nonblank results.
- The model supports filtering by date, agency, service, channel, priority, and status.

Microsoft Learn source:

- https://learn.microsoft.com/power-bi/fundamentals/fabric-get-started#create-a-semantic-model-in-the-lakehouse

## Module 3: Power BI Report

Goal: Build a useful operational report from the semantic model.

Recommended report name:

- `Citizen Service Operations Report`

Suggested pages:

1. Executive Overview
2. Agency Performance
3. Service Demand
4. Citizen Experience
5. Real-Time Operations

Suggested visuals:

- KPI cards: Total Requests, Open Backlog, SLA Breach Rate, Average Resolution Hours, Average Citizen Rating
- Line chart: Requests by month
- Bar chart: SLA breaches by agency
- Matrix: Agency, service, backlog, breach count
- Donut or bar chart: Requests by channel
- Trend chart: Feedback rating over time

Completion criteria:

- The Executive Overview page includes KPI cards and at least two trend or comparison visuals.
- Agency Performance identifies the agency or team with highest backlog or SLA breach count.
- Service Demand shows volume by service and time.
- Citizen Experience shows ratings, sentiment, and feedback categories.
- Real-Time Operations includes an event trend visual connected to event data or KQL output.

Microsoft Learn sources:

- https://learn.microsoft.com/fabric/fundamentals/building-reports
- https://learn.microsoft.com/power-bi/fundamentals/fabric-get-started#autocreate-a-report

## Module 4: Real-Time Intelligence

Goal: Monitor service request events and detect operational spikes.

Do not use a CSV file directly as a streaming source. [../data/FactServiceEventStream.csv](../data/FactServiceEventStream.csv) is historical event data for lakehouse reconciliation. For Real-Time Intelligence, deploy the Azure Function HTTP event generator in [../rti-streaming/azure-function-http-bridge/](../rti-streaming/azure-function-http-bridge/) and connect Fabric Eventstream to it with the **HTTP** source connector.

Recommended item names:

- Eventstream: `CitizenServiceEventsStream`
- Eventhouse or KQL database item: `CitizenServiceEventsEH`
- Dashboard: `CitizenServiceRTIDashboard`

High-level steps:

1. Set up the Real-Time Intelligence environment.
2. Create an Eventstream.
3. Deploy the Azure Function HTTP event generator.
4. Add an Eventstream **HTTP** source that polls the Function endpoint.
5. Route the HTTP source to Eventhouse/KQL database.
6. Query the event data with KQL.
7. Create a Real-Time dashboard.
8. Create an alert for request spikes or SLA risk.

Completion criteria:

- Event data can be queried by timestamp and event type.
- Event data can be tied back to lakehouse service requests using `RequestId`.
- A dashboard visual shows events over time.
- An alert condition is defined for a spike or SLA-risk pattern.

Example monitoring questions:

- Are service request submissions spiking by channel?
- Which services are approaching SLA limits?
- Which event types occur most often in the last hour?

Microsoft Learn sources:

- https://learn.microsoft.com/fabric/real-time-intelligence/tutorial-introduction
- https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/add-manage-eventstream-sources
- https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/add-source-http
- https://learn.microsoft.com/azure/azure-functions/functions-create-function-app-portal
- https://learn.microsoft.com/azure/azure-functions/deployment-zip-push
- https://learn.microsoft.com/training/modules/explore-event-streams-microsoft-fabric/
- https://learn.microsoft.com/training/modules/create-real-time-dashboards-microsoft-fabric/

## Module 5: Ontology / Fabric IQ

Goal: Add a business vocabulary and semantic context layer.

Important: Ontology and Fabric IQ are preview features in Microsoft Learn. Confirm tenant settings before this module.

Recommended ontology name:

- `CitizenServiceOntology`

Recommended entity types:

| Entity Type | Source |
| --- | --- |
| Agency | DimAgency |
| Team | DimAgency |
| Service | DimService |
| Request | FactServiceRequest |
| SLA | DimSLA |
| Channel | DimChannel |
| Feedback | FactCitizenFeedback |

Recommended relationships:

| Relationship | Meaning |
| --- | --- |
| Agency owns Service | Agency responsible for service domain |
| Team handles Request | Operational team handles a request |
| Request uses Channel | Citizen request came through a channel |
| Request governed by SLA | SLA target applies to request |
| Feedback describes Request | Feedback is linked to a completed request |

High-level steps from Learn:

1. Create an ontology item or generate one from a semantic model.
2. Create or verify entity types.
3. Bind entity properties to lakehouse tables or semantic model data.
4. Bind time-series data from Eventhouse where required.
5. Review keys, properties, and relationships.

Completion criteria:

- Entity types exist for Agency, Service, Request, SLA, Channel, Team, and Feedback.
- At least one entity type is bound to lakehouse data.
- At least one relationship is reviewed or configured.
- Preview limitations and tenant settings are acknowledged.

Microsoft Learn sources:

- https://learn.microsoft.com/fabric/iq/overview
- https://learn.microsoft.com/fabric/iq/ontology/overview
- https://learn.microsoft.com/fabric/iq/ontology/tutorial-1-create-ontology
- https://learn.microsoft.com/fabric/iq/ontology/how-to-bind-data

## Module 6: Fabric Data Agent

Goal: Create a governed conversational Q&A experience.

Recommended data agent name:

- `CitizenServiceDataAgent`

Recommended data sources, up to the supported limit:

- Lakehouse or SQL analytics endpoint tables
- Power BI semantic model
- Eventhouse KQL database
- Ontology

Data agent instructions:

```text
Use the approved Citizen Service Operations data sources to answer questions about service requests, SLA performance, backlog, channels, agencies, teams, feedback, and real-time operational events. Do not infer personal citizen data. Prefer semantic model measures for curated KPIs. Use Eventhouse/KQL data for real-time or time-series event questions. Use ontology when questions use business terms such as agency, service, request, SLA, team, and feedback.
```

Example questions:

- Which services are breaching SLA this week?
- Which agency has the highest open backlog?
- Which channel has the fastest growth in request volume?
- Which service has the lowest average citizen rating?
- Are there real-time spikes in submitted requests?

Use [data-agent-prompts.md](./data-agent-prompts.md) for copy/paste agent
instructions, table descriptions, a five-minute CIO demonstration, operational
follow-up prompts, and grounding tests.

Completion criteria:

- Data sources are added within the supported source limit.
- Relevant tables are selected.
- Agent instructions are added.
- At least three approved test questions return usable answers.

Microsoft Learn sources:

- https://learn.microsoft.com/fabric/data-science/concept-data-agent
- https://learn.microsoft.com/fabric/data-science/how-to-create-data-agent
- https://learn.microsoft.com/fabric/data-science/data-agent-add-datasources
- https://learn.microsoft.com/fabric/data-science/data-agent-configurations

## Closeout

Ask participants to demonstrate:

1. A lakehouse table query.
2. A semantic model relationship or measure.
3. One report page.
4. One real-time dashboard tile or alert.
5. One ontology entity and relationship.
6. One data agent answer with source data grounded in Fabric.
