# Challenge 2.4 - Working with Service Bus

Azure Service Bus is an enterprise grade, fully managed message broker that offers a number of key benefits to enterprise, mission critical applications.

Some key benefits of Service Bus are:

- Decoupling of services, for example if requests are being received at a rate higher than they can be processed by a backend process
- Publish and Subscribe - submitting a single request to a Service Bus *topic* which can then be delivered to multiple subscribers
- Load Balancing - having multiple listeners to a single queue, where each subscriber is a worker that processes requests

 More details can be found [here](https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-messaging-overview)

## Azure Service Bus Topic Output Binding
Once the document has been stored in the database configured through an output binding, we need to trigger a backend process (the *OrderOrchestrator*), implemented as another Azure Function. To trigger the *OrderOrchestrator*, we will write a message to a Service Bus Topic. 

Using the Azure Portal, create a Service Bus instance using the Standard tier (the Basic tier does not support topics), then create create a topic called *ContosoOrder* and a subscription called *ContosoOrderSubscription*.

Create a Service Bus output binding for the *ContosoOrder* function created in the previous lab. You will need the topic, topic subscription and connection string.

An example Service Bus output binding is as follows, which writes to a topic called *ContosoOrder*. The connection string is called *sbconn* and needs to be added to *local.settings.json*. The connection string can be located on the overview page of the Service Bus instance in the Azure Portal.

```c#
        [FunctionName("ContosoOrder")]
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Function, "post", Route = "orders/{location:alpha}")] HttpRequest req,
            [ServiceBus("ContosoOrder", Connection = "sbconn")] IAsyncCollector<CustomerOrderDetail> sbOutMessage,
            ILogger log,
            string location)
        {
            log.LogInformation($"C# HTTP trigger function processed a request. Location {location}");
```



Test locally using Postman and use Service Bus Explorer to verify the message has been written to the topic.

## Azure Service Bus Topic Trigger

For this challenge, Contoso Retail need to call a fulfilment service with the order payload, triggered from the topic created in the previous challenge. Create a new Function App that will trigger from the Service Bus topic and then call the fulfilment service.

### Fulfilment Service
The fulfilment service doesn't exist, so we will create a dummy Azure Function. Create a new Function App with a single HTTP POST trigger that receives the order JSON payload and the order number as part of the path. For example:

https://yourfulfilmentservice/api/order/4

The service needs to return delivery identifier (GUID), tracking Identifier (GUID) and a 200 OK response, for example:

    {
        "deliveryId" : "fd777641-649e-416e-847e-83f65265ba23",
        "trackingId" : "4d9452ed-876c-426c-9628-5c381bd01f7f"
    }

Deployment Fulfilment function to Azure, then navigate to the function using the Azure Portal and make a note of the Function URL to be used in the following section.

### Service Bus Trigger
We now need to create a the Orchestator function to trigger from the service bus topic and call the fulilment service using HTTP.

The following high level diagram shows the flow:
![Functions Flow](<../images/Functions Flow.png>)

The orchestrator function will need a Service Bus topic trigger and use the *System.Net.Http.HttpClient* class to call the Fulfilment function. Ensure the URL for the Fulfilment function is stored in App Settings and not hard coded into the call. Once the setting has been creating in local.settings.json, it can be read in the following way:

*string fulfilmentUrl = System.Environment.GetEnvironmentVariable("FulfilmentUrl");*

Test the process from the start and view the data in Application Insights.  Application Map should now show the end to end flow including the two additional functions. 



