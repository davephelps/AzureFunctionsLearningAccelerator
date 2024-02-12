# Challenge 2.2 - Azure Function SQL Output Binding
In this challenge we will create a SQL Output Binding to write to an Azure SQL Database table from the ContsoOrder function. We will test locally and deploy to Azure using a traditional Azure SQL Database Connection String. Once we are happy our function is working, we will use Managed Identity to access the database from the CreateOrder function.

## Create a new Azure SQL Database
From the Azure Portal, create a new Azure SQL Database:

![Azure SQL Database](<../images/Marketplace - SQL.png>)

Under *Server*, make sure it is configured to create a *new* server. Click *Create New*, then set the Authentication Method to *Use both SQL and Microsoft Entra Authentication*. 

The reason to select two types of authentication is to ensure the function works correctly with the database using standard SQL Authentication before enabling Managed Identity. For a real project, we would only select the *Microsoft Entra Authentication* so we can be sure no connection strings are ever used with our database.

As we have two types of authentication, we need to create two admin accounts:

- Microsoft Entra ID account - click *Set Admin* and select *Microsoft Entra ID*. Use the account used to sign into the Azure Portal
- Azure SQL Database local database account - set the Admin login and password to something you can refer to later

![Azure SQL Database Entra](<../images/SQL Database Server Setup (Entra).png>)

Then configure the following settings.
- Workload environment - *Development*. Setting the Development option selects less powerful compute and other settings more aligned to a development environment
- Backup Storage Redundancy - *locally redundant backup storage*. For production scenarios, Zone Redundant or Geo redundant storage should be selected

    ![Azure SQL Database](<../images/SQL Database General Setup.png>)

Click *Next* to move to Networking and set the following settings:
- Connectivity Method - *Public Endpoint*

- Allow Azure Services to access this server - *Yes* 

Azure SQL Database will require a firewall rule to be configured for client connections, but by setting *Allow Azure Services to access this server* to *Yes*, we will allow Azure deployed services to access the database without an explicit firewall rule. Bear in mind, this is *all* services in Azure. 

If *Add current client IP address* is set to *Yes*, the development machine IP address will be added, allowing for the database to be viewed/updated etc.

![SQL Database Networking](<../images/SQL Database General Networking.png>)

Click *Review and Create* to create the Azure SQL Database and Server.

## Create an Azure SQL Database table
In order for our Azure Function to be able to store customer orders, we need to create a database table. The easiest way to do this is through Visual Studio using the *SQL Server Object Explorer*. Right click *SQL Server* and select *Add SQL Server*. Configure the login details using your Microsoft Entra ID account (the one configured as the SQL Admin account earlier) as below. Make sure to select the Authentication Type to *Microsoft Entra MFA*

![Visual Studio Add Server](<../images/Visual Studio - Login to SQL.png>)

If the connection doesn't succeed, make sure the client IP address of your development machine is added to the firewall rules of the Azure SQL Database Server. If *Microsoft Entra ID MFA* doesn't appear as an option, ensure you are using the latest version of Visual Studio.

The SQL Database should now be visible from the SQL Object Explorer, as follows:

![SQL Object Explorer](<../images/Visual Studio - SQL Object Explorer View.png>)

Navigate to the database created earlier, then right click *Tables* and select *Add new table* and add the columns below:

![Add New Table](<../images/Visual Studio - SQL Object Explorer, Add New Table.png>)

For the orderId column, we want this field to automatically increase by one each time a row is added, which we will do using an *Identity Column*. Set the following in the properties of the column:

![Set Identity Column](<../images/Visual Studio - SQL Object Explorer - Set Identity Column.png>)

Click Update (near the top) to create the table.

## Configure Azure Function Output Binding for SQL
As we have seen previously, Azure Functions has various *bindings* that make integrating with services and data sources easier. There is also a binding for Azure SQL Database, which we will configure as an output binding to write payload content we receive in the HTTP request to an Azure SQL Database table.

Ensure to add the following Nuget Package, or newer if available:

![SQL Nuget Package](<../images/Azure Functions SQL Nuget.png>)

First, we need to configure the output binding. The following example has an HTTP trigger and a SQL output binding. The table name is *CustomerOrder* and the connection string is *sqlconn*. The following example shows how a record is created and written to the database table.


```c#
    public static class ContosoOrder
    {
        [FunctionName("ContosoOrder")]
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Function, "post", Route = "PostFunction")] HttpRequest req,
            ILogger log,
            [Sql(commandText: "dbo.CustomerOrder", connectionStringSetting: "sqlConn")] 
                IAsyncCollector<CustomerOrderDetail> customerOrders)
        {
            log.LogInformation("C# HTTP trigger function processed a request.");

            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            dynamic data = JsonConvert.DeserializeObject(requestBody);

            CustomerOrderDetail order = new CustomerOrderDetail() { 
                MobileNumber = data.customer.mobile, 
                CustomerAddress = data.customer.address, 
                CustomerName = data.customer.name,
                CustomerEmail = data.customer.email,
                ProductId = data.productId,
                Quantity = data.quantity
            };

            await customerOrders.AddAsync(order);
            await customerOrders.FlushAsync();

            return new OkObjectResult(customerOrders);
        }
    }
    public class CustomerOrderDetail
    {
        public int orderId { get; set; }
        public string CustomerName { get; set; }
        public string CustomerAddress { get; set; }
        public string MobileNumber { get; set; }
        public string CustomerEmail { get; set; }
        public string ProductId { get; set; }
        public string Quantity { get; set; }
    }
```

To connect and authorise to Azure SQL Database we can use a SQL Database connection string, which contains a username and password, or we can use Microsoft Entra ID and Managed Identity. We will first connect with a connection string, then enable Managed Identity.

The connection string can be found by clicking *Connection Strings* in the Overview section of the Azure SQL Database:

![Connection String](<../images/Azure SQL Database Connection String.png>)

Copy the connection string from *ADO.NET (SQL authentication)* and set the following values:

- Initial Catalog - set this to the database name created earlier
- User ID - set this to the admin username created earlier
- Password - set this to the admin password created earlier

Add a configuration setting to local.settings.json called *sqlConn* (as configured in the binding) and set to the connection string.

Set a breakpoint in the function and press F5 to run. Use Postman to pass the payload (available [here](<../Sample Payload/sample_request-1.json>)), making sure to set the *Content-Type* to *application/json*.

Verify the data has been created by using the SQL Server Object Explorer, navigate to the *CustomerOrder* table, right click and select *View Data*.
