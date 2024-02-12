# Overview

For this set of challenges we will build a series of Azure Functions for a website backend, *Contoso Retail*. The functions will integrate with Azure Cosmos DB, Azure SQL Database, Azure Service Bus and HTTP REST services. The architecture is as follows:

![Architecture](<images/Architecture_Summary.png>)

The order process starts with an Azure Function (*CreateOrder*), triggered by an HTTP POST request. This function has two output bindings, one for an Azure Service Bus queue (or topic) and one for Azure Cosmos DB or Azure SQL Database. 

There is a second Azure Function (the *Orchestrator* in a separate Function App) which triggers from the message arriving on a Service Bus topic. The *Orchestator* function sends an HTTP POST to a third Function App, the *Fulfilment* service.

The labs will also cover securing Azure Functions, Service Bus, Azure SQL Database, monitoring and deployment.

## Topics Covered ##

- Creating Azure Functions
- Triggers, input and output bindings
- Azure Function Routes
- Development with Visual Studio
- Securing Service Bus with Microsoft Entra ID
- Securing HTTP endpoints with Microsoft Entra ID
- Securing Azure SQL Database with Microsoft Entra ID
- Monitoring with Application Insights, writing custom queries, creating Dashboards and Workbooks
- Deployment using Bicep templates and Azure DevOps
