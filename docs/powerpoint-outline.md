# PowerPoint Outline

Title: Microsoft Fabric Workshop for Public-Sector Data Engineers

Audience: Data engineers

Duration: Half day

Scenario: Citizen Service Operations Analytics

## Slide 1: Title

Microsoft Fabric Public-Sector Analytics Workshop

## Slide 2: Workshop Outcomes

By the end, participants will have:

- Created a lakehouse
- Loaded synthetic public-sector service data
- Created a semantic model
- Built a Power BI report
- Built a Real-Time Intelligence flow
- Created an ontology / Fabric IQ layer
- Created and tested a Fabric Data Agent

## Slide 3: Scenario

Citizen Service Operations Analytics:

- Track digital service requests
- Monitor SLA performance
- Understand channel demand
- Analyze citizen feedback
- Detect operational spikes
- Ask governed questions with a data agent

## Slide 4: Microsoft Learn Source Policy

All workshop steps are aligned to Microsoft Learn.

Key references:

- Lakehouse: https://learn.microsoft.com/fabric/data-engineering/tutorial-build-lakehouse
- Power BI / semantic model: https://learn.microsoft.com/power-bi/fundamentals/fabric-get-started
- Real-Time Intelligence: https://learn.microsoft.com/fabric/real-time-intelligence/tutorial-introduction
- Fabric IQ: https://learn.microsoft.com/fabric/iq/overview
- Ontology: https://learn.microsoft.com/fabric/iq/ontology/overview
- Data Agent: https://learn.microsoft.com/fabric/data-science/how-to-create-data-agent

## Slide 5: Architecture

Flow:

1. Synthetic service data
2. Lakehouse tables
3. Semantic model
4. Power BI report
5. Eventstream / Eventhouse / KQL
6. Ontology business layer
7. Fabric Data Agent

## Slide 6: Prerequisites

Confirm before workshop:

- Fabric-enabled workspace and capacity
- Contributor or higher workspace permissions where required
- Access to Power BI/Fabric experience
- Real-Time Intelligence access
- Ontology / Fabric IQ preview enabled
- Graph setting enabled if using ontology graph
- Data Agent prerequisites and tenant settings reviewed

References:

- https://learn.microsoft.com/fabric/fundamentals/create-workspaces
- https://learn.microsoft.com/fabric/enterprise/licenses#capacity
- https://learn.microsoft.com/fabric/iq/ontology/overview-tenant-settings
- https://learn.microsoft.com/fabric/data-science/how-to-create-data-agent

## Slide 7: Dataset

Tables:

- FactServiceRequest
- FactServiceEventStream
- FactCitizenFeedback
- DimAgency
- DimService
- DimDate
- DimChannel
- DimSLA

## Slide 8: Module 1 - Lakehouse

Outcome:

- Create lakehouse
- Load synthetic data into tables
- Validate tables

Source:

- https://learn.microsoft.com/fabric/data-engineering/tutorial-build-lakehouse

## Slide 9: Module 2 - Semantic Model

Outcome:

- Create semantic model from lakehouse tables
- Define relationships
- Add basic measures

Source:

- https://learn.microsoft.com/power-bi/fundamentals/fabric-get-started#create-a-semantic-model-in-the-lakehouse

## Slide 10: Module 3 - Power BI Report

Suggested pages:

- Executive Overview
- Agency Performance
- Service Demand
- Citizen Experience
- Real-Time Operations

Sources:

- https://learn.microsoft.com/fabric/fundamentals/building-reports
- https://learn.microsoft.com/power-bi/fundamentals/fabric-get-started#autocreate-a-report

## Slide 11: Module 4 - Real-Time Intelligence

Outcome:

- Create real-time flow
- Transform events
- Query with KQL
- Create dashboard and alert

Source:

- https://learn.microsoft.com/fabric/real-time-intelligence/tutorial-introduction

## Slide 12: Module 5 - Ontology / Fabric IQ

Outcome:

- Define business vocabulary
- Create entity types
- Bind data
- Review relationships

Sources:

- https://learn.microsoft.com/fabric/iq/overview
- https://learn.microsoft.com/fabric/iq/ontology/overview
- https://learn.microsoft.com/fabric/iq/ontology/tutorial-1-create-ontology
- https://learn.microsoft.com/fabric/iq/ontology/how-to-bind-data

## Slide 13: Module 6 - Fabric Data Agent

Outcome:

- Create data agent
- Add data sources
- Add instructions
- Add example queries where supported
- Test business questions

Sources:

- https://learn.microsoft.com/fabric/data-science/how-to-create-data-agent
- https://learn.microsoft.com/fabric/data-science/data-agent-add-datasources
- https://learn.microsoft.com/fabric/data-science/data-agent-configurations

## Slide 14: Capstone Questions

Examples:

- Which services are breaching SLA this week?
- Which agency has the largest open backlog?
- Which channel has the highest growth in requests?
- Which service has the lowest feedback rating?
- Are there live spikes in service request volume?

## Slide 15: Wrap-Up

Review:

- Lakehouse for data engineering storage
- Semantic model for governed metrics
- Power BI for reporting
- Real-Time Intelligence for operational monitoring
- Ontology for business meaning
- Data Agent for natural-language Q&A
