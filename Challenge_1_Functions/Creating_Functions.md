# Challenge 1 - Create a REST API

Azure Functions provide a great way to create REST based APIs, for example backend processing from a website. For this challenge we will create an Azure Function API that accepts orders from a website, Contoso Retail.

We will use Visual Studio, although the steps are very similar if using Visual Studio Code.

# Pre-requisites

* Visual Studio 2022
* .NET 6.0 or above
* Azure Functions Core Tools v4 or above

## Create an Azure Functions project using Visual Studio 2022

First, Install the Azure Functions extension for Visual Studio through the Visual Studio Marketplace if not already installed.

Open Visual Studio and create a new Azure Functions project by selecting "File" > "New" > "Project" > "Azure Functions" and select "HTTP trigger" as the template for the new function.

 Azure Functions supports two types of runtime, *in-process* and *isolated*. In-Process functions run in the same process as the Function runtime, so application function code must be developed in a .NET version supported by the runtime. There is a lot more flexibility with the Isolated runtime, where the runtime dependencies do not affect the function code. For example, .NET Framework could be used for application code. There are some differences in how functions are developed when using Isolated, please see [this link](https://learn.microsoft.com/en-us/azure/azure-functions/dotnet-isolated-in-process-differences) for more details. For this challenge, please use **in process** as follows:

 ![Create Function App](<../images/Create Function.png>)

Define the function to respond to an HTTP POST method, accepting this [Sample File](<sample_request-1.json>) as the request payload.

The function should return an HTTP OK response, with a JSON payload containing the order id from the request and new GUID in a field called repsonseId, for example:

    {
        "orderId" : "1",
        "repsonseId" : "6B29FC40-CA47-1067-B31D-00DD010662DA"
    }

The function can be tested in a variety of ways, such as using Postman, available [here](https://www.postman.com). Alternatively, there is an extension for Visual Studio Code called RestClient, available [here](https://marketplace.visualstudio.com/items?itemName=humao.rest-client).

Test the function locally using Postman by running the project in debug mode (press F5) and sending [this message](<sample_request-1.json>) as the request payload. Set the payload and *Content-Type* header to *application/json*.


There is a Postman collection available in the repo [Postman Collection](<../Postman Collections/Sales Collection.postman_collection.json>) where the  test called **Contoso Sales - SAS URL** can be used. 

Be sure to set the function url to the url displayed when the function is executed locally, for example:
![Local Url](<../images/Local Url.png>)

Set a breakpoint to debug and step through the function code.

## Add a Route to the Function

The website could accept orders from all over the world. In order to know the location the order is being received from, add a *route* to the function to include a location in the path, for example:
https://myfunction.azurewebsites.net/api/country/UK 

The route can be added to the HTTP trigger as shown in the following example:

```c#
        [FunctionName("ContosoOrder")]
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Function, "post", Route = "country/{location:alpha}")] HttpRequest req,
            ILogger log,
            string location)
        {
            log.LogInformation($"C# HTTP trigger function processed a request. Location {location}");
```

Please see [this link](https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-http-webhook-trigger?tabs=python-v2%2Cin-process%2Cnodejs-v4%2Cfunctionsv2&pivots=programming-language-csharp) for details.

The country should also be returned in the response payload, for example:

    {
        "orderId" : "1",
        "repsonseId" : "6B29FC40-CA47-1067-B31D-00DD010662DA+",
        "country" : "UK"
    }

Test the function locally by pressing F5 and sending a request that includes the country in the path.

## Deploy the Azure Functions Project to Azure

Use the Visual Studio Azure Functions extension to publish the project to a Function App by right-clicking the project in the Solution Explorer and selecting *Publish*. Select *New Profile*, then *Azure* as the publish destination. The following shows how to select an existing Function App or create a new one. Press *Create New*.

![Publish Profile](<../images/Function - Publish Profile.png>)

Deploy using a Premium Functions hosting plan as this will be required for later challenges. An EP1 plan is the most cost effective but the plan can be deleted after this challenge to save costs. Note, the plan itself (and all related Function Apps), storage account and Application Insights need to be deleted for the cost to be zero.

![Create Resources](<../images/Function - Create Function.png>)

When the Function App has been created (or an existing one selected), click *Publish*

![Publish](<../images/Function - Publish Profile.png>)

Once deployed, navigate to the Function App in the Portal and the function should be visible in the Overview tab.

![Function Overview](<../images/Function Overview Azure.png>)

Copy the HTTP Url by selecting the function and clicking *Get Function Url*. Test using PostMan or RestClient (be sure to pass in the same payload and set the Content-Type header to application/json). If using PostMan, clone the request used to test locally and change the Url.

## Application Insights ##

Observability for any application is extremely important, and the Azure service *Application Insights* provides a wealth of features out of the box. There is a lab that covers Application Insights available [here](../Challenge_7_Monitoring/Challenge_4_Monitoring.md), but for now we can view Application Insights data for our deployed Function App directly from Visual Studio or from Azure.

### Application Insights - Visual Studio ###
From Visual Studio, use the Application Insights extension for Visual Studio to view live metrics and logs for the Azure Functions project by selecting "View" > "Other Windows" > "Application Insights Search" and selecting the Application Insights instance:

![Application Insights](<../images/App Insights Visual Studio.png>)

### Application Insights - Azure ###
To view Application Insights in Azure, either navigate directly to the Application Insights instance by name (using search in the Portal) or select it directly from the Function App:

![Application Insights](<../images/Function Application Insights.png>)

Click *Live Metrics* to see the Function telemetry in realtime, including how many servers are running, how many requests are executing, memory and CPU usage etc.

Data written to Application Insights from Azure Functions goes to the following tables:
- requests
- exceptions
- dependencies
- traces

Click on *Logs* and enter the query below to see recent data (note it can take a minute or so for Application Insights data to become available):

```
requests
| order by timestamp desc
```

This should yield results similar to the following:

![Logs](<../images/Functions App Insights Logs.png>)