# Challenge 9 - Load Testing Azure Functions

## Summary
A key part of any solution delivery is ensuring it will scale to meet demand. Azure Functions have built-in auto- scaling, but can have dependencies such as databases and other services that may cause scalability to be  affected.

Azure Load Testing is a managed service that offers load simulation to test solutions for scalability requirements. This lab will provision Azure Load Testing to perform load tests against Azure Functions. In a real-life scenario, the function may be sending messages to Service Bus or calling other services. Azure Load Testing can test any HTTP endpoint although is not restricted to HTTP. Messages Queues such as Azure Service or Databases can also be configured for load testing.

### Provision Azure Load Testing
The first step is to create the Azure Load Testing Service. Through the Azure Portal, select Create a Resource and select *Azure Load Testing*. Select the same region where the Azure Function will be created (if not created already) and a resource group.

### Create an Azure Function
Create a new HTTP triggered Azure Function we can test that just returns a 200 OK response. Make a note of the function URL.

### Create an Azure Load Testing Test
Once the Load Testing service has been provisioned, create a new test by navigating to *Tests* and selecting *Create a URL-based test*. For the Test URL, enter the URL of the Function created earlier. There are many settings that can be applied to a load test which can be enabled by selecting *Enable Adanced Settings*. For this test, ensure this box is un-ticked.

Under the *Specify Load* section, select *Virtual Users* and for the number of virtual users, select 50. Leave the Test Duration at 120 seconds and the ramp up time at 0 seconds. Virtual users simulates a real user continually triggering the Azure Function over and over for the duration specificed. How quickly the function responds directly affects when the next call is made as the next trigger won't happen until the  previous one has completed.

The Test should look as follows:

![Load Testing](<../images/Load Testing - Test Settings.png>)

Run the test - you can view the statistics of the test run by clicking on the test, but also navigate to the Application Insights instance configured for the Function App and selecting *Live Metrics* to see the number of servers scaling out and the requests per second.

Experiment with entering higher numbers for the virtual users, making sure the test agent isn't overloaded (view Engine Health). To test very high volumes, add an additioanl test instance and change the number of virtual users.

Here is a sample response when testing with 400 users, which achieved results of around 4000 requests/second:

![Test Results](<../images/Load Testing - Test Results.png>)

### More Advanced Scenario - Setting the Payload and Header
The previous sample created a very simple test, but in reality we would need to pass a payload into to our function, set custom headers or configure other aspects of the test. 

For more details, see [this link](https://learn.microsoft.com/en-us/azure/load-testing/how-to-create-and-run-load-test-with-jmeter-script) for more details.

For this test, we will pass a JSON payload to our test and also set the Content-Type header. This can be done in two ways, first through the Azure Portal or through downlading the JMeter script and editing locally.

We will add the payload and set the header through the portal. First, edit the test created above select *Enable Advanced Settings*:

![Advanced Settings](<../images/Load Testing - Advanced Settings.png>)

Navigate to the *Test Plan* tab and click *Add Request* where the URL, method (POST/GET etc.), headers and payload can be set.

Set the URL to be to the URL of the Azure Function created earlier.

Change the method to HTTP POST, then set the *Data Type* to *JSON View*. Paste in a JSON payload, such as the one used earlier: 
[Sample Request](../Challenge_1_Functions/sample_request-1.json)

Here is an example of adding a payload:

![Add Payload](<../images/Load Testing - add Payload.png>)


Click Add, save the test and execute the test as discussed above.




