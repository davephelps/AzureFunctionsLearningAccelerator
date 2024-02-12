# Challenge 4.4 - Azure Function Protected with Microsoft Entra ID and Managed Identity

For this challenge, we will create a new Azure Function (when deploying to Azure, create a new Function App), called the Orchestrator, which will trigger from the Service Bus topic using *User Assigned Managed Identity*. It will then call a second Function App (*Fulilment*) that will be protected with Microsoft Entra ID. We will use the Managed Identity of the Orchestrator Function App to call the Fulfilment service.

## Service Bus Trigger

Create a new Azure Function called the *Orchestrator* that triggers from the Service Bus topic (*OrderTopic*) created earlier. It should use User Assigned Managed Identity to access the Service Bus instance.

Test locally (using the developer account configured earlier). Remember to make sure the developer account has been asssigned the *Service Bus Data Reader* role on either the Service Bus namespace or the individual Service Bus Topic.

Deploy to Azure and test.

# Fulfilment Service - Create a New Function App

Create another Azure Function using Visual Studio called *Fulfilment* that has an HTTP POST Trigger. Test locally and deploy to Azure being sure to create a new Function App. No other configuration is necessary at this point.

## Protect with Microsoft Entra Id

In order to enable Microsoft Entra Id authentication and authorisation for a Function App, we need to create a security boundary in Microsoft Entra Id. This security boundary is an *App Registration* and allows the Function App to leverage Microsoft Entra Id to secure inbound requests.

Azure Functions has a feature called *EasyAuth* (App Service and Logic Apps Standard also have this feature) which can create the necessary *App Registration* configuration in Microsoft Entra Id automatically, but we will configure it manually in this lab to understand the mechanics of how security works with Microsoft Entra Id.

The first thing we need to do is create an App Registration in Microsoft Entra Id.  We will use this App Registration to secure the Fulfilment Function.

From the Azure Portal, search for *Microsoft Entra ID*, then click on *App Registrations*. Create an Application Registration (redirect Uri does not need to be set):

![Register Application](<../images/Register%20Backend%20App%20Registration%20for%20Function%20App.png>)

Each Application Registration has an **Application ID Uri**, which by default is a GUID value. It's best to change this to something more meaningful so when the application is validating the request, it will be clear on the permission being checked. To set the **Application ID Uri** click on Application ID Uri on the overview page of the Application Registration.

![Set Application ID Uri](<../images/Application%20ID%20URI.png>)

Then set the value, which is typically in the format **https://yourtenant.onmicrosoft.com/business_function/service**. **Make a note of this as it will be required later**. An example is below:

![Application ID Uri](<../images/Application%20ID%20URI%20Set.png>)

The next step is to configure the Function App to use the Application Registration just created.

### Function App Configuration (Fuliflment Function App)

Navigate to the Fulfilment Function App and select *Authentication* (under *settings*). From here click *Add Provider*, then select *Microsoft* and select the App Registration created earlier. Leave all other settings as they are and click *Add* to save the configuration.

![Add Identity Provider](<../images/Function App - Add Identity Provider.png>)

We can now apply security validation by adding a check for the audience, which is the *Application ID Uri* created earlier. Under *Authentication*, click on the Edit button for the Microsoft Identity Provider, and set the *Allowed Token Audience* to the *Application ID Uri*:

![Set Token Audience](<../images/Function App - Add Token Audience.png>)

We have now configured our Function App to use Microsoft Entra Id security.

### Validate Security Configuration

To show the function is now protected with Microsoft Entra Id, test the function in Azure by calling it through PostMan. The call should fail with a security error as we have not yet obtained a token from Microsoft Entra Id to pass to our function.

## Testing the Function using Microsoft Entra ID

As we are now using Microsoft Entra ID to authorise the Fulfilment function, we no longer require the default function key we need to pass in the URL to authorise the request. To remove this requirement, change the *AuthorizationLevel* to *Anonymous*, as below, and deploy the updated function to Azure.

```
[HttpTrigger(AuthorizationLevel.Anonymous, "get", "post", Route = null)] HttpRequest req,

```

### Create App Registration to for Testing
In order to test the Fulfilment service when it is deployed to Azure, we need to pass a valid token we have obtained from Microsoft Entra ID. We then pass this to the function when we test from PostMan.

Create another App Registration we will use to represent a test client to call the Fulfilment Function. The name needs to be unique, so use your initials as part of the name. This Application Registration will simulate the Orchestrator fetching a token using Managed Identity.

First, create an App Registration, but this time there is no need to set the Application ID Url. Just create as single tenant and **make a note of the Application (client) ID on the Overview page as it will be required later**. "Application ID" and "Client ID" are the same thing and can be used interchangeably.

![Client Id](<../images/Client - Application ID.png>)

Click the *Certificates & Secrets* link, and click *New Client Secret* where a secret can be created. **Make a note of the secret as it is only displayed once and will be required later**.

![Client Secret](<../images/Client - secret.png>)

### Test Obtaining a Token with PostMan

There is a Postman collection available in the repo [Postman Collection](<../Postman Collections/Sales Collection.postman_collection.json>).

- The PostMan collection makes use of *Environment variables* to automatically copy the token and put it in the Authorization header. For this to work successfully, create a new Environment (left hand side of PostMan) and create a variable called *SalesToken*. Switch to that environment (top right of PostMan) before fetching the token.

- Click on the test named **Contoso Sales - Get Token**, then configure the values as follows:

- Set the URL by changing **your_tenant_id** to the ID of your tenant. This can be found by navigating to Microsoft Entra Id and clicking the **Overview** page and copying **Tenant ID**:

- scope - this is Application ID URL created in the Fulfilment Function App Registration with **/.default** appended. For example, https://yourtenant.onmicrosoft.com/sales/fulfilment/.default
- client_id - this is the Client ID copied from the Test Client Application Registration just created
- client_secret - this is the secret created earlier from the Test Client Application Registration
- grant_type - this is set to *client_credentials* and represents the OAUTH2 flow for one system talking to another (i.e., no user present) 

Click **Send** and the token should be returned:

![JWT Token](<../images/Postman JWT Raw.png>)

The token is encoded, so the easiest way to view it is to open a browser and navigate to [https://jwt.ms](https://jwt.ms), then paste the token content (i.e., the access_token part of the response) into the website. The token should then be decoded showing all the claims in the JWT. Note the **audience** which is the value configured against the Fulfilment Function App Registration. Also note the **appid** which is the Client ID of the Client App Registration..

The *audience* value in the JWT will be checked by the Fulfilment function using the Function validation we created earlier.

### Test the Function from PostMan using a Microsoft Entra Id Token

The next step is to test the Fulfilment function by passing the JWT to the Function. Click on the test called **Contoso Sales - Microsoft Entra Id** and click **Send**. The JWT is automatically copied from the previous PostMan step using Postman *variables* and the call should be successful.

The token has a lifetime, so after a period of time it will expire and a new token will need to be retrieved.

You may be wondering what's to stop anyone from creating a token such as the one returned from Microsoft Entra Id and just passing it to the function. When a token is returned from Microsoft Entra Id it is *digitally signed* by Microsoft Entra Id using a private certificate that only Microsoft Entra Id has. The first step the authorisation framework takes is to validate the signature using the Microsoft Entra Id public key so it knows the token can only have been issued by Microsoft Entra Id.

## Calling Function App using Managed Identity

In the previous scenario we used an App Registration to represent a test client, which involved creating the App Registration and making a note of the Client ID and Secret values. With Managed Identity, this is abstracted, allowing services to call Microsoft Entra Id secured services with an identity that is managed by Microsoft Entra Id. There is no need to create an App Registration and manage secrets.

## Obtain a Token from the Orchestrator Function App

In this scenario, we will update the Orchestrator Function to use Managed Identity and request a token from Microsoft Entra Id. That token will then be passed to the Fulfilment service.

Ensure User Managed Identity is enabled for the Orchestrator Function App. As discussed earlier, this can be the same User Assigned Managed Identity as used previously, just be aware of implications of sharing User Assigned Managed Identities (as discussed earlier in this section).

Next, we need to update our code to fetch the token. To make things easier to configure, the following are set in application settings:

- AudienceId - This is the "Application ID Uri" visible in the overview page of the Application Registration created earlier for the Fuliflment function EasyAuth configuration
- FulfilmentUrl - This is the URL of the Fulfilment function

The following also need to be configured in application settings, but are required by the Identity runtime to correctly identify the User Assigned Managed Identity:

- AZURE_CLIENT_ID - Set this to the Client Id of the User Assigned Managed Identity assigned to the Orchestrator function
- AZURE_TENANT_ID - The tenant ID of the Azure Tenant

The *Azure.Identity* NuGet package will need to be added to the project. Take the latest stable version.

The following code fetches a token from Microsoft Entra ID and calls the *Fulfilment* function, passing the token in the *Authorization* header:

```c#
    public class Orchestrator
    {
        private static readonly HttpClient httpClient = new HttpClient();

        [FunctionName("Orchestrator")]
        async static public Task Run(
            [ServiceBusTrigger("contosoorder", "contosoordersubscription2", Connection = "sbconn")] string myQueueItem,
            ILogger log)
        {
            log.LogInformation("Orchestrator: processed a request.");

            string fulfilmentUrl = System.Environment.GetEnvironmentVariable("FulfilmentUrl");
            string audienceId = System.Environment.GetEnvironmentVariable("AudienceId");
            log.LogInformation($"Orchestrator: Got audience of {audienceId}");
            log.LogInformation($"Orchestrator: Got Fulfilment URL of {fulfilmentUrl}");

            var tokenCredential = new DefaultAzureCredential();
            var accessToken =  await tokenCredential.GetTokenAsync(
                new TokenRequestContext(scopes: new string[] { audienceId + "/.default" }) { }
            );

            string token = accessToken.Token;

            // Don't log access tokens but uncomment below to view the token
            // log.LogInformation($"Orchestrator: Got access token: {token}");

            httpClient.DefaultRequestHeaders.Authorization =
                    new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token);

            var resp = await httpClient.GetAsync(fulfilmentUrl);
            resp.EnsureSuccessStatusCode();

            var jsonResponse = await resp.Content.ReadAsStringAsync();
            log.LogInformation($"Orchestrator: Got response: {jsonResponse}");
        }
    }
```
Deploy the function to Azure and test.

## Restrict Access to Fulfilment Function

When an App Registration is created in Microsoft Entra Id, by default *all* clients in the tenant are able obtain an access token to call the service being secured. To restrict access to just specific clients, we can have two options:

- Create application *roles*, for example *create_orders* or *read_orders*, then grant permission for clients to specific roles. We an then disable access for any clients that do not have a role granted. This option requires a Microsoft Entra ID Administrator to approve the roles. For a lab on creating roles and granting access, see the following lab [here](Challenge_6.2_HTTP_Secure_with_roles.md)
- Configure the Function App itself to only allow specific clients. This option does not require Admin consent, but does mean an update to the Function App each time a new client is added

### Configuration of Function App to Restrict Access

At the time of writing, it is not possible to configure restrictions through the Azure Portal, instead we have to use the REST API or Bicep.

We will use the Azure REST API to configure the Fulfilment Function to restrict access for the App Registration we used to test from PostMan and the Managed Identity configured for the Orchestrator Function.

First, we need to edit [this file](config/easyauth.json) for the Fulfilment function settings specific to your deployment.

Edit the file and replace the settings contained in curly braces as follows.


- your_region - for example, northeurope
- openIdIssuer - the tenant id is the value for tenant id in the overview page of Microsoft Entra ID
- clientId - this is the "Application (client) ID" value in the overview page of the Application Registration created earlier for the EasyAuth configuration
- applicationid uri - this the "Application ID Uri" visible in the overview page of the Application Registration created earlier for the EasyAuth configuration

There is also a section called *defaultAuthorizationPolicy*, which has two json objects, *allowedPrincipals* and *allowedApplications*. Both allow restriction of the calling client, either by using the client id or the object id, and both can be an array to restric multiple clients. If the *allowedPrincipals* element is present, this must be used and will override anything in the *allowedApplications* object, so use one or the other, not both. In our case we will add the client id of the Application Id used to test from PostMan and the Client Id of the User Assigned Managed Identity for the Orchestrator Function. This is so we can test both scenarios.

```
    "defaultAuthorizationPolicy": {
        "allowedPrincipals": {
            "identities": [
                "{object id to restrict}",
                "{object id to restrict}"
                ]
        },
        "allowedApplications": [
            "{client id to restrict}",
            "{client id to restrict}"
        ]
    }
```


Once the file has been saved we need to use the Azure CLI to deploy the changes. Azure CLI can be used in a variety of ways, including from Visual Studio, Visual Studio Code and the Azure Portal CLI. We will use Visual Studio.

Open Visual Studio and start a new Terminal by selecting *Terminal* from the *View* menu.

When the terminal has loaded, login to Azure typing *az login* and logging in with your Azure credentials.

Once logged in, change directory to the *Challenge_3_Security_HTTP* folder and enter the following command, substituting your values:

```
az rest --method put --uri https://management.azure.com/subscriptions/your subscription id/resourcegroups/your resource group/providers/Microsoft.Web/sites/your fulfiment function app/config/authsettingsV2?api-version=2021-02-01 --body 'config/@easyauth.json'
```
*az rest* is a command that is part of the Azure CLI, that once logged in, will automatically add the authorization header. This makes it easier to call the Azure Management API to make REST based calls to manage Azure Services.

If the call succeeds, we are ready to test. Go to PostMan, request a new token and call the Fulfilment service. If testing from Postman succeeds, we can test the end to end scenario in azure. Trigger the *ContosoOrder* function and validate the Orchestrator function has succeeded 

This demonstrates both scenarios have been configured so that only *they* are allowed to call the Fulfilment service.

### Test the Function from Visual Studio using a local account

So far, we have tested the Microsoft Entra ID protected *Fulfilment* Function App only when it is deployed to Azure, as that is where the managed identity is configured. We can also test locally by running from Visual Studio. For this to succeed, we need to simulate the Managed Identity. As we are not using an Azure Service that has built in RBAC (such as Service Bus), we cannot use a user account and instead need to use a service principal with a client id and secret, in the same way we tested from PostMan.

To do this, open a Terminal and login with the credentials for the Client App Registration used to test from PostMan, as follows:

```
az login --service-principal  -u "client_id of app registraiton"   --password "Secret of app registration"  --tenant "your tenant id" --scope https://yourtenant.onmicrosoft.com/services/functions/fulfilment/.default --allow-no-subscriptions
```
If this succeeds, we can run the project locally and test in one of two ways:

- Just run the Fulfilment service and test from PostMan in the same way we tested before, but this time use the local url
- Test end to end by running *all* functions projects locally and triggering the *ContosoOrder* function. With this approach, bear in mind that if the solution is deployed to Azure, both the deployed solution *and* the local project will be using the same queues and topics. To test locally simply stop the Function Apps running in Azure so they will no longer consume messages from queues and topic subscriptions.

