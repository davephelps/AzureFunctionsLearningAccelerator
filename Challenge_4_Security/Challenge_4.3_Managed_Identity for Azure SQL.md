# Challenge 4.3 - Azure Function SQL Output Binding with Managed Identity
In this challenge we will use *Managed Identity* to access Azure SQL Database from the *CreateOrder* function.

## Configure Managed Identity
We will now configure the User Managed Identity created earlier to have access to the *ContosoRetail* database.

Make a note of the User Managed Identity *Name* and *Client Id*:

![Managed Identity Properties](<../images/Azure Managed Identity Properties.png>)

We now need to grant permission for the Managed Identity to have access to the ContosoRetail database. We will do this from the Visual Studio *SQL Server Object Explorer*, but this will only succeed if the logged in user is a Microsoft Entra ID account (you should be logged in using your developer identity which was configured as the Microsoft Entra ID SQL Admin earlier).

Right click the *ContosoRetail* database and select *New Query*.

Paste the following SQL statements into the new query, substituting *ContosoUserMI* with your User Assigned Managed Identity name:

```sql
CREATE USER [ContosoUserMI] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [ContosoUserMI]; 
ALTER ROLE db_datawriter ADD MEMBER [ContosoUserMI]; 
GO
```

Click the *Execute* button at the top of the query pane to run the script against the database. Ensure there are no errors displayed.

## Connection Configuration
Edit the SQL connection added eariler for SQL Authentication in *local.settings.json* as follows:

```
Server=your_database_name.database.windows.net; Authentication=Active Directory Default; Database=ContosoRetail; User Id=6d48bf12-81ae-4b0a-aea3...
```

The User Id above is the *Client Id* copied earlier from the overview section of the *User Assigned Managed Identity*. This is not required if using *System Assigned Managed Identity*, but is required to tell the runtime which managed identity to use if using User Assigned Managed Identity.

Note: Authentication is set to "Active Directory Default". This means the Azure Function will use Managed Identity when deployed to Azure and a local developer account when running locally (if configured in Visual Studio).

## Test Locally

To test locally, ensure the developer service account has been added to Visual Studio (as described in the Service Bus section on Local Development) and this account is the Microsoft Entra Id account for the database created earlier.

Set a breakpoint and press F5 to run and test locally using PostMan.

## Deploy to Azure and Test

Make sure the *User Assigned Managed Identity* has been configured against the *ContosoOrder* Function App in Azure, then deploy the changes to Azure using Visual Studio. No further changes should be necessary. Change the function URL in PostMan and test - a row should be visible in the database.
