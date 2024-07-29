
# Challenge 5.1 - Monitoring with Azure Application Insights

For this challenge, we will use Azure Application Insights to monitor our end to end solution.

When an Application Insights enabled service (e.g., Function App, Logic App, API Management etc.) makes a call to another service, it injects a correlation header which allows the second service to join into the end-to-end trace. Application Map (a feature of Application Insights) shows how services interact with each other at runtime. For example, here is an end to end view of a request that flows from Azure API Management to a Logic App, which writes to a queue, which is then processed by an Azure Function, which writes to a queue, which is picked up by another Azure Function: 

![Application Map](<../images/Application Map.png>)

As you can imagine, when services are chained together like this, *Application Map* is particularly useful to understand the behaviour of the application at runtime.

To view the Application Map for your application, navigate to the instance of Application Insights configured and from the left hand menu, select *Application Map*. The various services invoked in the end to end application journey should then be displayed. Each can then be drilled into to view any errors, performance characteristics etc. As well as the Function Apps, queues/topics and SQL database should also be represented in the view.

# Enabling Application Insights for Azure Functions
When an Azure Function is deployed from Visual Studio or Visual Studio Code, there is an option to create a new Application Insights instance. Typically, an Application Insights instance would be shared across a number of services, which makes querying the data more straightforward. The boundary is often (but not always) what would be considered *the application*, including services that make up the application, integrations etc.

Note: it takes between 30 seconds and and 2 minutes for the logs to arrive in Application Insights.

See the section below for Cost Considerations when using Application Insights.

In our scenario, we have the *ContosoOrder* Function App which writes to a Service Bus topic and also writes to Azure SQL. A second Function App, the *Orchestrator* reads the message from the Service Bus topic, then calls a third Function App, the *Fulilment* service.

Edit the configuration of each of the Function Apps and set the *APPLICATIONINSIGHTS_CONNECTION_STRING* value to *Connection String* for the Application Insights instance to be shared across the services:

![Connection String](<../images/Application Insights Connection String.png>)

# Application Insights Tables and Queries

Application insights writes data to a number of *tables*, which is how Application Map is able to build a runtime view.

The following tables are the key tables

- Requests - when a Function, Logic App or API Management receive a request, an entry is written to this table
- Exceptions - errors that occur when the service is running are written to
- Traces - trace data from Functions and Logic Apps are written to this table. This includes traces from the Function Runtime and application logging (LogInformation for example)
- Dependencies - where a service makes a call to another service, an entry is written here. For example, writing to Service Bus

## Query Examples

If all services use Application Insights, Kusto (the query language behind Application Insights) can be used to gain rich insights by creating custom queries. Services are joined together as an end-to-end trace using the *operation_id* field. For example, the following will show all calls from API Management to the backend and any other services (i.e., an end to end trace) using Application Insights for a given single operation_Id :

Before we start some labs, here are a few examples of some queries.

To see all requests, most recent first, enter the following:

```
requests
| order by timestamp desc
```

When a request is received by the first service in the chain, in our case the *ContosoOrder* function, a field called *operation_Id* is created. This field contains a value that is written to all subsequent services within the end to end flow that are Application Insights enabled. So, if we look at recent runs, for example:

![Operation Id](<../images/Application Insights - Operation Id.png>)

When can then issue a query for one specific end to end journey:

```
requests
| where operation_Id == 'e90e395fd61baa268bd106f90347e39b'
| order by timestamp desc
```
Which yields the following results:

![Query End to End](<../images/Application Insights - Query on Operation Id.png>)

The results show the *ContosoOrder* function running first, then the *Orchestrator* and finally the *Fulfilment* function.

Click on the different rows to see the data recorded.

# Logging Custom Data - Lab
In this lab we will cover a number of queries to gain insights from the data logged. Try them in your own environment by navigating to Application Insights and clicking *Logs* to enter the query designer. Try editing the queries to gain new insights.

Application Insights provides a lot of detail about running services by default, but real insights are realised when custom, business context data is also logged. In our example, logging the order Id, Product Name and order quantity could be very useful.

To log custom data to Application Insights, the following is a straightforward way:
```c#
            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            dynamic data = JsonConvert.DeserializeObject(requestBody);

            string productName = data.productName;
            string orderId = data.id;
            string quantity = data.quantity;

            Activity.Current.AddTag("ProductName", productName);
            Activity.Current.AddTag("OrderId", orderId);
            Activity.Current.AddTag("Quantity", quantity);
```
*Activity.Current.AddTag* will create a custom entry in the Application Insights telemetry. For in-process Functions, the custom data is added to the *Requests* table. For isolated Functions however, custom data logged using *AddTag* is written to the *Dependencies* table, so an additional join is required.

Using the above code snippet as a guide, update the *ContosoOrder* function to log ProductName, OrderId and Quantity. We can then write queries based on the custom data logged. 



To return the product name, we can use the following query:

```
requests
| where name =='ContosoOrder'
| join kind=leftouter ( dependencies
    | where type == 'InProc'
    | extend ProductName = customDimensions.ProductName
  ) on $left.id == $right.operation_ParentId
| order by timestamp desc
```

We can also retrieve the quantity for each product:

```
requests
| where name =='ContosoOrder'
| join kind=leftouter ( dependencies
    | where type == 'InProc'
    | extend ProductName = customDimensions.ProductName
    | extend Quantity = customDimensions.Quantity
  ) on $left.id == $right.operation_ParentId
| order by timestamp desc
```

![Product and Quantity](<../images/Application Insights - Query on Product and Quantity.png>)

We can then create a pie chart based on how many products were sold:

```
requests
| where name =='ContosoOrder'
| extend ProductName = customDimensions.ProductName
| extend Quantity = customDimensions.Quantity
| summarize Count=sum(toint(Quantity)) by tostring(ProductName)
| render piechart 
```
This yields the following results:

![Pie Chart](<../images/Application Insights - Pie Chart Product by Quantity.png>)

We can also query based on success of function calls:

```
requests
| where resultCode  != 0
| summarize count() by resultCode
| render piechart 
```
Which renders the following result:

![Result Code](<../images/Application Insights - Pie Chart Result Code.png>)

Where we record a custom identifier, in our case an order id, we can also return this in our query and therefore query on it. For example, here we are querying on order id 108:

```
requests
| where name =='ContosoOrder'
| extend ProductName = customDimensions.ProductName
| extend Quantity = customDimensions.Quantity
| extend OrderId = customDimensions.OrderId
| where OrderId == '108'
| order by timestamp desc
```

![Query on Order Id](<../images/Application Insights - Query on Order Id.png>)

Where a process covers multiple Function Apps and queues or topics, it would be useful to understand how long the end to end process takes so we can gain valuable business and performance insights. The following query demonstrates end to end processing time and shows useful business data to identify runs that haven't completed yet:

```
requests
| where name =='ContosoOrder'
| extend ProductName = customDimensions.ProductName
| extend OrderId = customDimensions.OrderId
| extend OrderId = customDimensions.OrderId
| join kind=leftouter (
    requests
    | where name == 'FulfilmentService'
    | extend orderCompleted=timestamp
  ) on operation_Id
|extend isComplete = iif(orderCompleted != '', true, false)
|extend timeTaken= datetime_diff('second', now(),timestamp)
|extend timenow=now()
| project ProductName,OrderId,timeTaken,orderReceived=timestamp, orderCompleted, isComplete, name ,timenow, operation_Id
| order by orderReceived desc
```
![End to End](<../images/Application Insights - End to End.png>)

Try querying on different things by logging different payload items, or showing a pie chart to show how long each function takes to execute on average.

# Live Metrics

Telemetry sent to Application Insights typically takes between 30 seconds and 1 minute to arrive, but there is a feature of Application Insights called *Live Metrics*. Live Metrics shows, in realtime, data such as requests received, exceptions and number of running servers. This can be very useful to understand how the application(s) are scaling out and back in. For example:

![Live Metrics](<../images/Application Insights - Live Metrics.png>)

View Live Metrics and see the servers running at the bottom of the screen. The servers running are for all servers across all plans enabled for this Application Insights instance. To only view a specific service, use the filter option, as follows:

![Live Metrics Filter](<../images/Application Insights - Live Metrics Filter.png>)

# Application Insights - Cost Considerations
Care should be taken to ensure that Application Insights is configured correctly to stay within budgets:

- For Azure Functions and Logic Apps, validate that the Traces table is required as a lot of runtime detail is written to this table. Through configuration of host.json (same for Logic Apps and Functions) runtime data can be sampled, thus reducing the amount of data written. Sampling should be used where a representative view of the logs is required
- Tables can also be excluded from monitoring completely, see this example how to configure sampling and exclude specific tables
- Application Insights Workspaces can also have a daily cap, thus reducing cost when a specific limit is reached. Care should be taken enabling this as important logs could be lost when the cap is met. Within any solution, there may be some services where their logs are more important than others, so in these cases consider using sampling, excluding tables or even more than one instance of Application Insights such that the cap can be configured differently. See [here](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/daily-cap) for details on setting a daily cap



