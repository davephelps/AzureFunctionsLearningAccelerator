
# Challenge 4.5  - Azure Function Protected with Microsoft Entra ID Application Roles

When an App Registration is created in Azure AD, by default *all* clients in the tenant are able obtain an access token to call the API being secured. In order to narrow down the authorisation to clients, *roles* can be used.

### Create Roles

Roles are created in the App Registration for the Function App (the Fulfilment Function App in our case) and clients are then granted access to those roles (the Orchestrator in our case), which can then be checked within the application being secured. The audience will also only be present in the JWT if the client has been granted access to a role. Examples of roles are being able to read sales data or create sales data.

Create roles through **App Roles** in the App Registration, then click Add New Role where the role can be created:

![Create Role](<../images/Create Role.png>)

### Assign Roles to the Client Application ###

Using the App Registration created earlier for testing, navigate to API Permissions, then click "Add a Permission".

Within *APIs my organization uses*, enter the name of the Fulfilment Application Registration. When it appears in the search results, click it which will display the *Application Permissions* sceen. Select *Application Permissions* then select the role created earlier and click "Add Permissions", as follows:

![Assign Role Permission](<../images/Assign Role Permission.png>)

You should then see the permission listed against the Test Application Registration:
![View Application Permissions](images/Contoso%20Client%20Permissions%20View.png)

Although the permission is listed, permission has not yet been granted. To do this, login as an Azure AD Administrator and click "Grant admin consent". For automated scenarios, or where Azure AD Admin is not appropriate, see [here](https://learn.microsoft.com/en-us/graph/permissions-grant-via-msgraph?pivots=grant-application-permissions&tabs=http) for details on how to automate this without Admin consent. Once permission has been granted, there should be a green tick to indicate the permission:

![PErmission Granted](<../images/Permission Granted.png>)

Navigate to PostMan and fetch the token from Azure AD, paste it into jwt.ms and view the roles in the token:

![Roles](<../images/JWT Roles.png>)

We can now restrict access so that only clients that have roles granted are able to fetch a token.
