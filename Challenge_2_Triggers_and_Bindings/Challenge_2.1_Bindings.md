# Challenge 2.1 - Bindings

Any solution will need to integrate with other systems and services, such as databases, queues, events etc. Azure Functions makes this easier through the use of *bindings*, without the need to write the plumbing to integrate with each service. Bindings are available in two modes, input and output. For example, bindings can be configured for HTTP request/response, Service Bus messages or databases such as Azure Cosmos DB and SQL. Bindings can be used together, such as accepting a Service Bus message from an input binding and creating a database record using an Azure Cosmos DB output binding. Multiple output bindings can also be used, for example writing to Cosmos DB and a Service Bus queue or topic.

At the time of writing, the following are the bindings available in Azure Functions:

- Blob storage
- Azure Cosmos DB
- Azure Data Explorer
- Azure SQL
- Dapr4
- Event Grid
- Event Hubs
- HTTP & webhooks
- Kafka3
- Mobile Apps
- Notification Hubs
- Queue storage
- Redis
- RabbitMQ3
- SendGrid
- Service Bus
- SignalR
- Table storage
- Timer
- Twilio

## Bindings Challenge
In Challenge 2, we will use an output binding to write to a database. There are two challenges, Azure Cosmos DB and Azure SQL Database. You can select to implement the bindings for Azure SQL Database, Cosmos challenge or both.

**Note: challenge 5 covers securing Azure SQL Database with Microsoft Entra ID, so if this is of interest, be sure to follow Challenge 2, Bindings for Azure SQL Database.** 