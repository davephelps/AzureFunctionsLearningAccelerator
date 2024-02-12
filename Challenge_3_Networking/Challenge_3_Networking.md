# Challenge 3 - Enabling Private Networking with Functions

## Overview

Private networking is often a requirement for a lot of organisations using Azure. Although you can protect your Functions with managed identity, some organisations still feel that this is not sufficient to meet their security requirements. Therefore, it is crucial to be able to create and host Functions within your own virtual networks in Azure. This challenge will focus on this important aspect of enterprise architecture. 

## The Challenge

The *Orchestrator* and *Fulfilment* functions must now exist on a virtual network, with the *Fulfilment* function only accessible over a private IP address. 

![Networking Options in Functions](<../images/image.png>)

To read more about creating a Function with a private endpoint, please read [this link](https://learn.microsoft.com/en-us/azure/azure-functions/functions-create-vnet).

Before adding a private endpoint to the *Fulfilment* function, a virtual network will need to be created. [This link](https://learn.microsoft.com/en-us/azure/virtual-network/quick-create-portal) explains how to create a virtual network from the Azure Portal.

### Creating the Private Endpoint

Once you have an existing virtual network, you can use the portal to create the private endpoint: 

![private endpoint creation](<../images/image-1.png>)

For this challenge, you will want to make sure that the DNS is being managed by Azure.

Additionally, once your private endpoint is created. Make sure that you have public access turned off in your access restrictions. 

![Access restrictions](<../images/image-2.png>)

Test your Function to see what the fulfilment Function returns if you call it from postman. You should also test to see how the orchestrator function works with your fulfilment function.


### Accessing your private function

Now that you can only trigger your function from somewhere within your virtual network, you will need to integrate your orchestrator Function with the virtual network that has your private endpoint.

To do this, look to set up a new subnet for your orchestrator function and then add the Function to the virtual network. 


![Final solution diagram](<../images/image-3.png>)

## Bonus Challenge

Azure Service Bus also supports a private IP address, although this is only available in the *Premium* tier. Confiure a private IP address for Service Bus and test connectivity from the Azure Function.

Additionally, to automate creating a Function App with a private endpoint, review [this link](https://github.com/Azure-Samples/function-app-with-private-http-endpoint)

[Additional link for Bicep private endpoints](https://github.com/JimPaine/bicep-private-endpoints)


