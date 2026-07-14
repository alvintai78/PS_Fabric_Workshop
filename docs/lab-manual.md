# Lab Manual

Workshop: Microsoft Fabric Public-Sector Analytics

Scenario: Citizen Service Operations Analytics

Use only synthetic data.

## Lab 0: Environment Check

Estimated time: 15 minutes

Checklist:

- Sign in to Microsoft Fabric.
- Confirm the workspace is backed by Fabric-enabled capacity.
- Confirm required workspace permissions.
- Confirm access to Lakehouse, Power BI, Real-Time Intelligence, Ontology / Fabric IQ, and Data Agent.
- Confirm preview settings required for Ontology / Fabric IQ and Graph, where applicable.

Exit criteria:

- Workspace and capacity are confirmed.
- The facilitator knows whether Ontology / Fabric IQ can run live or must be shown as a guided walkthrough due to tenant settings.

References:

- https://learn.microsoft.com/fabric/fundamentals/create-workspaces
- https://learn.microsoft.com/fabric/enterprise/licenses#capacity
- https://learn.microsoft.com/fabric/iq/ontology/overview-tenant-settings
- https://learn.microsoft.com/fabric/data-science/how-to-create-data-agent

## Lab 1: Create Lakehouse And Tables

Estimated time: 45 minutes

Goal: Create the lakehouse foundation.

Steps:

1. Open the Fabric workspace.
2. Create a lakehouse named `CitizenServiceLH`.
3. Load the CSV files from [../data/](../data/).
4. Use the table definitions in [../data-schemas/dataset-structure.md](../data-schemas/dataset-structure.md) to verify column names and data types.
5. If the trainer wants a smaller exercise, use the starter rows in the schema document instead.
6. Validate that tables are available in the lakehouse.

Tables:

- DimAgency
- DimService
- DimChannel
- DimDate
- DimSLA
- FactServiceRequest
- FactCitizenFeedback
- FactServiceEventStream

Validation:

- Confirm each table exists.
- Confirm key columns are populated.
- Confirm fact tables reference dimension keys.

Exit criteria:

- `CitizenServiceLH` exists.
- All eight required tables are present.
- At least one fact table can be inspected or queried.
- Participants can explain which tables are facts and which are dimensions.

References:

- https://learn.microsoft.com/fabric/data-engineering/tutorial-build-lakehouse
- https://learn.microsoft.com/fabric/data-engineering/create-lakehouse

## Lab 2: Create Semantic Model

Estimated time: 40 minutes

Goal: Create a report-ready semantic model.

Steps:

1. Create a semantic model from lakehouse tables.
2. Name it `CitizenServiceModel`.
3. Add the required fact and dimension tables.
4. Create relationships.
5. Create a dedicated measure table.
6. Add core measures.
7. Save the model.

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

When you select **New table**, Fabric requires a table expression with at least one column. Create a small measure table first:

```dax
_Measures = DATATABLE("MeasureGroup", STRING, {{"Service Operations"}})
```

After the table is created, select `_Measures`, then create the measures below. The `MeasureGroup` column is only a dummy column for creating the table; hide it from report view if the option is available.

Measures:

```dax
Total Requests = COUNTROWS(FactServiceRequest)
Open Backlog = CALCULATE(COUNTROWS(FactServiceRequest), FactServiceRequest[BacklogFlag] = TRUE())
SLA Breach Count = CALCULATE(COUNTROWS(FactServiceRequest), FactServiceRequest[IsSLABreached] = TRUE())
SLA Breach Rate = DIVIDE([SLA Breach Count], [Total Requests])
Average Resolution Hours = AVERAGE(FactServiceRequest[ResolutionHours])
Average Citizen Rating = AVERAGE(FactCitizenFeedback[Rating])
```

Exit criteria:

- `CitizenServiceModel` exists.
- Required relationships are visible in model view.
- `_Measures` table exists.
- Measures return values.
- Filtering by agency, service, channel, date, and priority works.

Reference:

- https://learn.microsoft.com/power-bi/fundamentals/fabric-get-started#create-a-semantic-model-in-the-lakehouse

## Lab 3: Build Power BI Report

Estimated time: 30 minutes

Goal: Build a report that looks useful with the dataset.

Steps:

1. Create a report from `CitizenServiceModel`.
2. Create an Executive Overview page.
3. Add KPI cards for total requests, backlog, SLA breach rate, average resolution hours, and average rating.
4. Add trend chart for requests by month.
5. Add agency performance chart.
6. Add channel distribution chart.
7. Save the report as `Citizen Service Operations Report`.

Optional pages:

- Agency Performance
- Service Demand
- Citizen Experience
- Real-Time Operations

Exit criteria:

- Report is saved.
- Executive Overview contains KPI cards and trend visuals.
- Agency Performance identifies backlog or SLA issues.
- Citizen Experience shows rating or sentiment.
- Report uses slicers for date, agency, service, channel, priority, and status.

References:

- https://learn.microsoft.com/fabric/fundamentals/building-reports
- https://learn.microsoft.com/power-bi/fundamentals/fabric-get-started#autocreate-a-report

## Lab 4: Real-Time Intelligence

Estimated time: 50 minutes

Goal: Monitor service events.

Workshop path:

- Deploy the provided Python Azure Function as an HTTP event generator.
- Configure Fabric Eventstream with the **HTTP** source shown in the **Connect data source** screen.
- Fabric polls the Function endpoint and ingests the JSON response.
- Keep [../data/FactServiceEventStream.csv](../data/FactServiceEventStream.csv) in the lakehouse for reconciliation.

Relationship back to lakehouse:

| RTI event column | Related lakehouse table | Related column |
| --- | --- | --- |
| RequestId | FactServiceRequest | RequestId |
| ServiceId | DimService | ServiceId |
| AgencyId | DimAgency | AgencyId |
| ChannelId | DimChannel | ChannelId |

### Part A: Deploy The Azure Function HTTP Event Generator

The Python Function code is provided in [../rti-streaming/azure-function-http-bridge/function_app.py](../rti-streaming/azure-function-http-bridge/function_app.py). It generates synthetic service events when Fabric calls `/api/events`. A deployable zip package is provided at [../rti-streaming/azure-function-http-bridge.zip](../rti-streaming/azure-function-http-bridge.zip).

Prerequisites:

- Azure subscription access.
- Access to Azure portal.
- Access to Azure Cloud Shell.
- The deployment zip file [../rti-streaming/azure-function-http-bridge.zip](../rti-streaming/azure-function-http-bridge.zip).

Create the Function App in Azure portal:

1. Open https://portal.azure.com.
2. Select **Create a resource**.
3. Search for **Function App**.
4. Select **Function App**.
5. Select **Create**.
6. For **Hosting option**, choose **Consumption** unless your instructor specifies another option.
7. On the **Basics** page, use these values:

| Setting | Value |
| --- | --- |
| Subscription | Your workshop Azure subscription |
| Resource group | Create new, for example `rg-fabric-rti-workshop` |
| Function App name | Globally unique name, for example `func-fabric-rti-<your-initials>` |
| Runtime stack | Python |
| Version | Available Python version in the portal |
| Region | Region close to the Fabric capacity or workshop region |
| Operating system | Linux, if prompted |

8. Keep the default values for **Storage** and **Monitoring**, unless the instructor provides specific values.
9. Select **Review + create**.
10. Select **Create**.
11. Wait for deployment to finish.
12. Select **Go to resource**.

Configure Function App settings:

1. In the Function App, go to **Settings** > **Environment variables** or **Configuration**, depending on the portal UI.
2. Add this application setting:

| Setting | Value |
| --- | --- |
| `DEFAULT_BATCH_SIZE` | `25` |

3. Save the settings.
4. Wait for the Function App to restart.

Deploy the Function code using Azure portal:

Some customer environments do not allow Azure Cloud Shell, or require extra approval before Cloud Shell storage can be created. Use the Azure portal upload path as the default workshop deployment method.

1. In the Function App, go to **Deployment** > **Deployment Center**.
2. For **Source**, select **Publish files**.
3. Under **Publish files**, select **Browse**.
4. Choose [../rti-streaming/azure-function-http-bridge.zip](../rti-streaming/azure-function-http-bridge.zip).
5. Select **Save** to upload and deploy the package.
6. Wait for the deployment to complete.
7. Open **Logs** in the Deployment Center if you need to check deployment progress or errors.

Alternative: deploy the Function code using Azure Cloud Shell if Cloud Shell is available in the customer environment.

1. In Azure portal, select the **Cloud Shell** icon in the top toolbar.
2. Choose **Bash**.
3. If Cloud Shell asks to create storage, follow the prompt to create it.
4. Upload [../rti-streaming/azure-function-http-bridge.zip](../rti-streaming/azure-function-http-bridge.zip) into Cloud Shell.
5. In Cloud Shell, set these variables:

```bash
RESOURCE_GROUP="rg-fabric-rti-workshop"
FUNCTION_APP="<your-function-app-name>"
ZIP_FILE="azure-function-http-bridge.zip"
```

6. Deploy the zip file:

```bash
az functionapp deployment source config-zip \
	--resource-group "$RESOURCE_GROUP" \
	--name "$FUNCTION_APP" \
	--src "$ZIP_FILE" \
	--build-remote true
```

7. Wait for the deployment command to finish.

Get the Function URL:

1. In Azure portal, open the Function App.
2. Select **Functions**.
3. Select `HttpToFabricEventstream`.
4. Select **Get function URL**.
5. Copy the default function URL.
6. The function URL should look similar to:

```text
https://<function-app-name>.azurewebsites.net/api/events?code=<function-key>
```

### Part B: Configure Fabric Eventstream HTTP Source

First validate the Function endpoint in a browser:

```text
https://<function-app-name>.azurewebsites.net/api/events?code=<function-key>&batchSize=5
```

You should see a JSON array of generated service events.

Then configure Fabric:

1. Open https://app.fabric.microsoft.com.
2. Open the workshop workspace.
3. Select **New item**.
4. Search for **Eventstream**.
5. Select **Eventstream**.
6. Name the item `CitizenServiceEventsStream`.
7. Select **Create**.
8. Select **Add source**.
9. Select **Connect data sources**.
10. In **Select a data source**, choose **HTTP**.
11. Select **Connect**.
12. If the example API page appears, select **Exit** to configure your own HTTP source.
13. Configure the HTTP source:

| Setting | Value |
| --- | --- |
| Source name | `CitizenServiceHTTPSource` |
| URL | `https://<function-app-name>.azurewebsites.net/api/events` |
| Authentication kind | API Key |
| API key | `<function-key>` |
| Request method | GET |
| Request interval (s) | `5` |

14. Add query parameters:

| Name | Value |
| --- | --- |
| `code` | `${apiKey}` |
| `batchSize` | `25` |

15. Select **Next**.
16. Review the connection.
17. Select **Add** or **Connect**.
18. Publish the Eventstream if the UI requires publishing.

### Part C: Add Eventhouse / KQL Destination

1. In the Eventstream canvas, select **Add destination**.
2. Select **Eventhouse** or **KQL database** destination, depending on the UI shown in the tenant.
3. Create or select an Eventhouse/KQL database named `CitizenServiceEventsEH`.
4. Set the destination table name to `FactServiceEventStream`.
5. Use the incoming JSON schema from the HTTP source. The expected fields are:
	- `EventId`
	- `RequestId`
	- `EventDateTime`
	- `ServiceId`
	- `AgencyId`
	- `ChannelId`
	- `EventType`
	- `Status`
	- `ProcessingDurationSeconds`
	- `SLAElapsedPercent`
6. Save or add the destination.
7. Publish the Eventstream if the UI requires publishing before data flows.

### Part D: Query Events In Eventhouse / KQL

1. Open `CitizenServiceEventsEH`.
2. Open the KQL database or queryset experience.
3. Run this query:

Example KQL intent:

```kusto
FactServiceEventStream
| summarize EventCount = count() by bin(EventDateTime, 15m), EventType
| order by EventDateTime asc
```

4. Run this query to show SLA-risk events:

```kusto
FactServiceEventStream
| where SLAElapsedPercent >= 80
| project EventDateTime, RequestId, ServiceId, AgencyId, ChannelId, EventType, Status, SLAElapsedPercent
| order by SLAElapsedPercent desc
```

### Part E: Create The Real-Time Dashboard

1. From the KQL query result, create or pin a visual to a Real-Time dashboard if the UI provides that option.
2. Name the dashboard `CitizenServiceRTIDashboard`.
3. Add a time chart showing `EventCount` by 15-minute interval.
4. Add a bar chart showing `EventCount` by `EventType`.
5. Add a table for high SLA elapsed events where `SLAElapsedPercent >= 80`.

### Part F: Create An Alert

1. Use a KQL query that identifies an operational risk, for example high SLA elapsed events:

```kusto
FactServiceEventStream
| where SLAElapsedPercent >= 90
| summarize HighRiskEvents = count() by bin(EventDateTime, 15m)
```

2. Create an alert from the query or dashboard experience where available.
3. Set the alert condition to trigger when `HighRiskEvents` is greater than `0`.
4. Name the alert `SLA Risk Event Alert`.

Example reconciliation check:

1. In the lakehouse or SQL analytics endpoint, find one request:

```sql
SELECT TOP 1 RequestId, ServiceId, AgencyId, ChannelId, Status
FROM FactServiceRequest;
```

2. In Eventhouse/KQL, use the same `RequestId` to find the related events:

```kusto
FactServiceEventStream
| where RequestId == "REQ000001"
| project EventDateTime, RequestId, ServiceId, AgencyId, ChannelId, EventType, Status, SLAElapsedPercent
| order by EventDateTime asc
```

Validation:

- Dashboard shows event trend.
- Query returns event counts by time.
- A selected `RequestId` can be found in both `FactServiceRequest` and `FactServiceEventStream`.
- Alert condition is defined.

Exit criteria:

- Event data is queryable by timestamp.
- Event data can be tied back to lakehouse service requests using `RequestId`.
- A dashboard or visual shows event count over time.
- An alert condition is configured for event spike or SLA risk.

References:

- https://learn.microsoft.com/fabric/real-time-intelligence/tutorial-introduction
- https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/add-manage-eventstream-sources
- https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/add-source-http
- https://learn.microsoft.com/azure/azure-functions/functions-create-function-app-portal
- https://learn.microsoft.com/azure/azure-functions/deployment-zip-push
- https://learn.microsoft.com/azure/azure-functions/functions-how-to-use-azure-function-app-settings
- https://learn.microsoft.com/training/modules/explore-event-streams-microsoft-fabric/
- https://learn.microsoft.com/training/modules/query-data-kql-database-microsoft-fabric/

## Lab 5: Ontology / Fabric IQ

Estimated time: 35 minutes

Goal: Define business meaning for the public-sector scenario.

Important: Ontology / Fabric IQ is preview in Microsoft Learn. Run this lab only when tenant settings are enabled.

Steps:

1. Create ontology item or generate from semantic model.
2. Name it `CitizenServiceOntology`.
3. Add or verify entity types.
4. Bind static data from lakehouse tables.
5. Bind time-series data from Eventhouse where required.
6. Define or review relationships.
7. Validate entity keys and properties.

Entity types:

- Agency
- Team
- Service
- Request
- SLA
- Channel
- Feedback

Exit criteria:

- `CitizenServiceOntology` exists, if tenant settings allow live creation.
- Required entity types are created or reviewed.
- At least one data binding is configured or demonstrated from Microsoft Learn steps.
- At least one relationship is reviewed.

References:

- https://learn.microsoft.com/fabric/iq/ontology/overview
- https://learn.microsoft.com/fabric/iq/ontology/tutorial-1-create-ontology
- https://learn.microsoft.com/fabric/iq/ontology/how-to-bind-data

## Lab 6: Fabric Data Agent

Estimated time: 25 minutes

Goal: Build conversational Q&A over approved data sources.

Steps:

1. Create a Fabric Data Agent named `CitizenServiceDataAgent`.
2. Add approved data sources.
3. Select relevant tables.
4. Add data agent instructions.
5. Add data source descriptions.
6. Add example queries where supported.
7. Test the agent with operational questions.

Recommended sources:

- `CitizenServiceLH`
- `CitizenServiceModel`
- Eventhouse/KQL database from Lab 4
- `CitizenServiceOntology`

Agent instruction draft:

```text
Answer questions about synthetic citizen service operations only. Use curated semantic model measures for KPI questions. Use lakehouse tables for detailed service request analysis. Use Eventhouse/KQL for real-time event questions. Use ontology when users ask with business terms such as agency, service, request, SLA, channel, team, or feedback. Do not invent personal citizen data.
```

Test questions:

- Which services are breaching SLA this week?
- Which agency has the highest open backlog?
- Which channel has the highest request volume?
- Which service has the lowest citizen rating?
- Are live service events increasing in the last hour?

Exit criteria:

- `CitizenServiceDataAgent` exists.
- Approved data sources are added.
- Instructions are configured.
- At least three test questions return usable answers grounded in configured sources.

References:

- https://learn.microsoft.com/fabric/data-science/concept-data-agent
- https://learn.microsoft.com/fabric/data-science/how-to-create-data-agent
- https://learn.microsoft.com/fabric/data-science/data-agent-add-datasources
- https://learn.microsoft.com/fabric/data-science/data-agent-configurations

## Final Validation

Each participant should show:

- Lakehouse tables created
- Semantic model relationships and measures
- Power BI report page
- Real-Time dashboard or query
- Ontology entity and binding
- Data Agent answer to one approved question
