# Challenge 2.3 - Working with Cosmos DB

Contoso Retail need to store sales order requests to a database and have a preference for NoSQL such as Azure Cosmos DB. 

For this challenge we will update the *ContosoOrder* function o use Azure Functions *output bindings* to store the order request . Azure Functions bindings provide an easy way of integrating with various services and databases without writing code. Bindings are available in two modes, input and output. For example, bindings can be configured for HTTP request/response, Service Bus messages or databases. Bindings can be used together, so for example accepting a Service Bus message from an input binding and then creating a database record using an output binding. Multiple bindings can be created, with a mix of input and input bindings. There can also be multiple of each, so the function can trigger from multiple sources. This provides great flexibility to execute the same business logic when the message may arrive from more than one source.

For this challenge we will use the existing *ContosoOrder* function created in challenge 1 that accepts an order as an HTTP request. We will update the function to add a Cosmos DB output binding to create the database record.

First, create a Cosmos DB instance in the Azure Portal. When creating Cosmos DB, select the database type as *Azure Cosmos DB for NoSQL*

![Cosmos DB](<../images/Cosmos Create.png>)

Once Cosmos DB has been created, create a new Database called *ContosoSales* and a new collection called *orders*. For the *partition key*, make it **/region**. Partitions is Cosmos DB are a key concept for increasing performance through horizontal scaling. For more details see [this link ](https://learn.microsoft.com/en-us/azure/cosmos-db/partitioning-overview)

![Cosmos Database](<../images/Create Cosmos Database.png>)

Once the Cosmos DB instance has been created, we can add the output binding for CosmosDB to our existing function.

Please see [this link](https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-cosmosdb-v2-output?tabs=python-v2%2Cin-process%2Cnodejs-v4%2Cextensionv4&pivots=programming-language-csharp) for details on how to create a Cosmos DB output binding. The binding should look similar to the following:

![CosmosDB Trigger](<../images/CosmosDB Trigger.png>)

Configure the output binding to use the Cosmos DB instance, database and collection created earlier. The Connection String will be required, which can be found under the *Keys* section of the Cosmos DB instance in the Portal. A configuration setting will also need to be added. 

Test locally using Postman using the same payload as before and validate the document is stored in Cosmos DB using *Data Explorer*, available in the Overview page of the Cosmos DB instance in the Portal.

Once the solution is working, deploy to Azure and test using Postman. The connection string will need to be configured when deployed to the portal, which can be done through Visual Studio once the deployment is complete, as follows:

![Application Settings](<../images/Application Settings in Visual Studio.png>)

