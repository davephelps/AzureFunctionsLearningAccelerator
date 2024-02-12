# Challenge 4.2 - Create a Managed Identity and Authorise Access to Service Bus

In this challenge we will create a Managed Identity, to be used by the *CreateOrder* function app to access a Service Bus topic called *ContosoOrder*.

First, create the an HTTP triggered Azure Function called *CreateOrder* that has an output binding to a Service Bus Topic. Validate this works successfully by testing locally, then deploy to Azure to a new Function App.

If creating a new Service Bus namespace, make sure to select the Standard version as  Basic does not support topics.

## Managed Identity

A common challenge for developers is the management of secrets, credentials, certificates, and keys used to secure communication between services. Managed identities eliminate the need for developers to manage these credentials.

Here are some of the benefits of using managed identities:

- You don't need to manage credentials. Credentials aren’t even accessible to you.
- You can use managed identities to authenticate to any resource that supports Microsoft Entra (Azure AD) authentication, including your own applications
- Managed identities can be used at no extra cost

There are two types of Managed Identity - System Assigned and User Assigned:

- With System Assigned, the Managed Identity is specific to the service using it. For example, if an Azure Function were to use Managed Identity to connect to Service Bus, the Managed Identity could only be used by that function. If the function is deleted, the Managed Identity is deleted. The downside of this approach is that permissions granted to the Managed Identity would need to be added each time the Function is created
- User Assigned Managed Identity is created independently of  the Azure Resource that is using it. User Assigned Managed Identity can be created, permissions assigned and can then remain as a separate resource to be used by one or more services. The advantage of User Assigned Managed Identity is the Managed Identity can exist even if the services using it are deleted. Permissions can be granted once, rather than having to potentially apply them multiple times as services are re-created or new ones created.


### Sharing Managed Identities

As mentioned above, User Assigned Managed Identities can by their very nature, be shared between a number of different serivces. Care should be taken when sharing Managed Identities:

- There can be unintended consequences of identity sharing however. For example, one Azure Function could need access to Service Bus and Azure SQL, but another Azure Function may only need access to Azure Storage. If we update the User Assigned Managed Identity to have access to all three services, it means both Azure Functions have access services they do not need access to
- Sharing identities can cause not only security risks but also mistakes can happen during configuration where services accidentally access resources they should not be able to
- Think very carefully about the scope of Managed Identities, how they are re-used and the services they have access to
- It can make perfect sense to have a single User Assigned Managed Identity used by a single service as the MI can exist regardless of the function being deleted/re-created. Where organisations have security teams that control resource access, User Assigned Managed Identity is of real benefit

It is possible to restrict access to who/which identities are able to assign a Managed Identity to a service. The following role can be used:

![Managed Identity RBAC](<../images/Managed Identity - Assign Role (restrict access to MI).png>)

For Azure Managed Identity best practice, please review [this link](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/managed-identity-best-practice-recommendations)


## Create a Managed Identity

We will create a User Assigned Managed Identity using the Azure Portal (automation through CI/CD is covered in [this lab](../Challenge_6_Deployment/Challenge_6_Deployment.md)).

To create a User Assigned Managed Identity, navigate to the Azure Portal and search for Managed Identities. From here, a new User Assigned Managed Identity can be created.

**Be sure to make the name unique by adding your initials or another way of making it unique**. If multiple Managed Identities are created with the same display name in the same tenant, assigning permissions to Azure SQL Database can fail due to the duplicate name.

![User Assigned MI](<../images/Create User Assigned MI.png>)

More details can be found [here](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/how-manage-user-assigned-managed-identities?pivots=identity-mi-methods-azp#create-a-user-assigned-managed-identity) to create a User Assigned Managed Identity.

## Service Bus and Managed Identity

By default, Azure Service Bus uses a connection string to create a connection to a specific Service Bus instance, queue or topic. While this approach works, the connection string has to be stored securely by the application, which may create a security risk.

Service Bus supports Azure Role Base Access Control (RBAC), such that a Managed Identity can be granted a role to a Service Bus instance, queue or topic.

Navigate to the Service Bus instance created in the previous lab and select the *ContosoOrder* topic that the *CreateOrder* function is sending order messages to. Select the *ContosoOrder* topic, select *Access Control (IAM)*

![Service Bus Topic RBAC](<../images/Service Bus RBAC.png>)

Click *Add Role Assignment* and add add a *Service Bus Data Sender* role to the *User Assigned Managed Identity* just created:

![Add Role Assignment](<../images/Service Bus Add Role Assignment MI.png>)

Click on *Role Assignments* and the permission just created should be listed

## Azure Function Configuration

Now the permission has been granted for the UserAssigned Managed Identity we must configure the *ContosoOrder* function to use the User Assigned Managed Identity created above. We will configure this against the *ContosoOrder* function deployed to Azure, as follows:
![Add User MI](<../images/Azure Function - Add User MI.png>)

The *ContosoOrder* function now has permissions to send messages to the Service Bus topic. The final thing we need to do is configure the connection details to allow the function to access Service Bus using the User Assigned Managed Identity.

For the configuration setting name, copy the connection name from the service bus binding (i.e., the *Connection* parameter on the trigger or binding), append "__fullyQualifiedNamespace" (two underscores) and add to the configuration of the function deployed in Azure. For example, if the connection string configuration name is "sbconn" as follows, the configuration setting name would be "sbconn__fullyQualifiedNamespace":


```c#
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Function, "post", Route = "PostFunction")] HttpRequest req,
            [ServiceBus("contosoorder", Connection = "sbconn")] IAsyncCollector<CustomerOrderDetail> sbOutMessage,
```



For the configuration setting value, use the Service Bus *hostname*, found here:

![Service Bus Hostname](<../images/Service Bus Hostname.png>)

The final configuration should be similar to the following:

![Function Config](<../images/Function SB Config Azure.png>)

We also need to add the client id of the User Assigned Managed Identity to the configuration to indicate which identity to use as there may be more than one identity configured. In this case the name would be *sbconn__clientId* and the value would be the client id of the User Assigned Managed Identity, available from the overview page of the User Assigned Managed Identity:

![Managed Identity Properties](<../images/Azure Managed Identity Properties.png>)

The final configuration should look like the following:

![Client Id Configuration](<../images/Azure Function - User MI Client Id Config.png>)

Any existing config settings for Service Bus that use the connection string can now be removed.

Save the setting and test that the function is able to send messages to the service bus topic.

# Local Development

Managed Identity is a fantastic way to control authorisation to Azure resources when an Azure Function is deployed to Azure. If Managed Identity is enabled for the Function App during development, the local development machine will not have access to a Managed Identity.

However, Visual Studio has a feature that allows a developer account to be used from within Visual Studio to authorise against Azure services when running locally. Note, this is only applicable for Azure services where RBAC can be applied. For access to services with custom Microsoft Entra ID authorisation, see [this section](<../Challenge_3_Security_HTTP/Challenge_3_Managed_Identity for HTTP.md>)

Sign in with an Azure account using the *Azure Service Authentication* setting, found under Tools -> Options. This is most likely to be the same account a developer uses to sign in to the Azure Portal to view and edit Azure resources. For example:

![Visual Studio Developer Account](<../images/Visual Studio Developer Account.png>)

Make sure the account used to sign in with also has the correct role assigned to the Service Bus queue or topic. In our case, we are writing to a Service Bus queue, so add the *Service Bus Data Sender* role.

Update *local.settings.json* to reflect the changes tested in Azure, for example

```
{
    "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "dotnet",
    "sbconn__fullyQualifiedNamespace": "your service bus.servicebus.windows.net",
    "sbconn__clientId" : "your User Assigned Managed Identity Client Id",
    "AZURE_TENANT_ID": "Your tenant id"
  }
}
```

Sometimes, if more than one account has been used to sign in to Visual Studio, there may be errors when running locally similar to "System.Private.CoreLib: Put token failed. status-code: 401, status-description: InvalidIssuer"

To resolve this error, create a setting in local.settings.json called "AZURE_TENANT_ID" and set it to the tenant id of the developer account. The tenant id can be found by entering "Microsoft Entra ID" in the search bar of the Azure Portal and viewing the Overview tab.

Debug the function locally and set a breakpoint to see if the function is triggering from a message arriving on the topic.

More details on local development when Managed Identity is configured can be found [here](https://learn.microsoft.com/en-us/dotnet/azure/sdk/authentication/local-development-dev-accounts?tabs=azure-portal%2Csign-in-visual-studio%2Ccommand-line)
