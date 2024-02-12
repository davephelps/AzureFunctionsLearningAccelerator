# Challenge 8 - Continous Deployment of Functions and Related Services

# Overview
In the previous challenges you have been using Visual Studio to develop your functions, Azure portal to create the Azure resources, and then right click and publish your code to the Azure resources.

This was a good exercise to understand how these different Azure resources fit together, how can they be deployed etc.However, you will not be working this way when you are working on Enterprise Applications which needs to have full Development and Deployment Lifecycle.

In this challenge, we will automate Azure resources which you have created in the previous challenges, so these resources can be created in a repeatable and consistent way. 
This is often referred to as Infrastructure as Code, and there are a few different ways of representing Infrastructure as code.

1) Azure Bicep 
2) Azure Resource Manager templates (ARM Templates)
3) Terraform

In this challenge we will be using Bicep, and is a recommended approach if you are automating Azure resources. We will build resources into Modules (different .bicep files), so that you can compose these modules together in many different ways as you see fit to deploy into different environments.

We will then use Azure DevOps Pipelines (.yml files) to build and release these Bicep Modules, so the resources are deployed into your subscription. This is often referred to as Continuos Integration/Continuos Deployment (CI/CD)

# Task 0 - End goal

# Bicep
I have built the bicep files in modules which will deploy the following resources which you have been working for the past 2 days.

1) Azure Functions with the required configuration settings needed to access Service bus with managed identity.
2) Azure Service Bus
3) Azure SQL Server and Database
4) Azure User Assigned managed identity
5) Add this managed identity to the correct roles for Service bus and Azure function

![Bicep Files](<../images/bicepfolderstructure.png>)
![Bicep Visualiser](<../images/bicepvisual_overall.png>)

# Azure Pipelines
I have then created 2 Azure Pipelines which are called
1) DeployFunctionsInfrastructure.yml
2) PublishFunctionsCode.yml

The DeployFunctionsInfrastructure pipeline is responsible for creating all the Azure resources which I have listed previously. Typically 

The PublishFunctionsCode pipeline is responsible for publishing the code changes to Azure

The reason I separated them out is, typically you create the Infrastructure needed (like function apps, storage account) once, and you do not need to recreate them every time you publish a new code change.You can only run the PublishFunctionsCode pipeline every time you want to publish your changes. 

![Pipelines in ADO](<../images/azurepipelines.png>)

# Task 1 - Environment Readiness

Get your local environment ready for writing these .bicep files and to deploy these files.
1) Get Bicep Extension for Visual Studio or Visual Studio Code. This helps you author these Bicep files, with auto-completions, syntax checks etc.
2) Ensure your Azure CLI and Azure Bicep versions are up to date. https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#azure-cli
3) Optionally GitHub Copilot Chat is a extension which can be really useful to author these files.

# Task 2 - Create Bicep and BicepParam files

In this task, author a bicep file (you can call it AzureStorage.bicep), which will include 1 resources to be created:

1) Azure Storage Account

You can use the GitHub copilot chat to write this bicep file for you, or you can write it from the scratch using the Bicep extension. 

Secondly you will create a parameters file (with extension .bicepparam), which is used to pass different environmental parameters based on the environment you are deploying to. That way, your .bicep file will not have any changes per environment (dev, test, production), instead you will maintain one .bicepparam file per environment (AzureStorage_Dev.bicepparam, AzureStorage_Prod.bicepparam). https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/parameter-files?tabs=Bicep

# Task 3 - Deploy Bicep Files

Now that you have the Bicep and Bicepparam files ready, you need to deploy these to your Azure Subscription.

The easiest I find is to navigate to the terminal window in Visual Studio from your solution (Visual Studio --> View --> Terminal). 

![Visual studio terminal](<../images/terminalfromvs.png>)

You need to create a resource group, so that you can deploy your storage account which you authored in your bicep file to that resource group. (you can deploy this storage account to a existing Resource group as well, if you wish to)

1) To create a resource group

```
az group create --name <ResourceGroupName> --location <region>
Eg:
az group create --name rg-storageaccount-bicep --location westeurope
```

2) To deploy the Bicep file
   
```
az deployment group create --resource-group rg-storageaccount-bicep --parameters storageaccount.bicepparam
 ```

Note that, you are just passing the .bicepparam file to the command (the .bicepparam file internally refers to the .bicep file with the using command)

3) Navigate to the portal and Check that your resources have been created successfully.

4) Create multiple .bicepparam files, with different parameter values and test that you are able to run them as well. This way you will understand how you will parameterise in .bicep files all those parameters which you think will change based on environment, or based on user input.

5) Clean up the resources
 
# Task 4 - Use the Bicep files provided

By now, you have a understanding of how to author a .bicep file, how to pass parameters using .bicepparam files and finally how to deploy these bicep files using AZ CLI.

Next task is to review the bicep files which have been created for you. (You should find them under bicep folder).

| File Name | Purpose  | 
| --------  | -------- | 
| azureFunction.bicep     | This file creates resource for FunctionApp, StorageAccount, ManagedIdentity, and the App Service Plan (Consumption) under which this Function App will run. Because FunctionApp depends on Storage Account and App Service plan, it made sense that they all are created in one .bicep file. Arguably, I could have had a different module (.bicep file) for creating ManagedIdentity - however in this case, I  clubbed it with Azure function creation.      | 
| serviceBus.bicep     | This file creates the servicebus namespace, and a queue called orders within that service bus namespace. You can update this file to fit your needs to create more queues, topics, subscriptions etc.     | 
| roleAssignment.bicep     | This file does the role assignment of giving permission for the user assigned managed identity the Service Bus Data Owner role (it could have been Service Bus Data Sender role)     | 
| main.bicep    | This is the file where I'm composing all the modules (Azure function, Service bus, role assignment etc) as needed by my project, and it is main.bicep file which will be deployed, which in turn invokes all the modules inside it and deploys them.     | 
| main.bicepparam     | This is the parameter file associated with the main.bicep and we pass all the required parameters through this file.    | 
| sqlServerandDB.bicep and sqlServerandDB.bicepparam    | This is a module to deploy SQL Server, SQL database, add the firewall rules, add the admin account etc. I could have very well invoked this module as well from the main.bicep, but I have chosen not to and keep the deployment of SQL Resources separately (there is no right or wrong, whatever fits your project's deployment needs)     | 

Now that you understand what each of these files do, you can either:
1) Deploy these bicep files (changing the parameter file as per your needs) directly
2) You can use the content in these bicep files to build your own, in a modular way as you see fit for your Application requirements.

*It is always good to have a discussion/debate around how these Bicep modules will be divided up, what sort of naming conventions will be used, how will you parameterise to different environments, where possible to standardise these modules etc.*

# To Deploy the provided Bicep files

Navigate to main.bicepparam and make the values in there unique. You can always write in the script to append the name with uniquestring(), but for now you can just append those names with you initials

Run the following command from the Terminal window
```
az deployment group create --resource-group rg-functions-sct --parameters main.bicepparam
```
To create SQL Server and Database, first change the parameters valye in sqlServerandDB.bicepparam
```
az deployment group create --resource-group rg-functions-sct --parameters sqlServerandDB.bicepparam
```
*you can optionally put the SQL resources in a different resource group, as it can be shared with other projects. In that case, create a different resource group and edit the az deployment group command to point to that new resource group*

# Task 5 - Create Azure DevOps Pipelines

Now that you have created the bicep files which is representing your infrastructure as code, you typically source control these files close to the Applications project - either in Github or Azure Devops Repos.

The point of creating Pipelines is to provide that continuos integration and continuos deployment. For instance, if you made some changes to the function code, and checked it in to Github - we can trigger a pipeline which can go and publish these changes to Azure (not to production, but to a test environment) automatically. This way, when any member of the team working on the project makes any changes and commits those changes, we trigger a pipeline to build and release their changes to a test environment - there by providing CI and CD. Refer to Development and Deployment best practices, or follow the practices which are for your organisation

As mentioned earlier - I have then created 2 Azure Pipelines which are called
1) DeployFunctionsInfrastructure.yml - to create the Azure Resources
2) PublishFunctionsCode.yml - to publish the code to these Azure resources

You can find them under AzureDevOpsPipelines folder in this repo

I would set the triggers to manual for DeployFunctionsInfrastructure.yml, so that every time a commit happens - this pipeline doesn't get triggered. For the PublishFunctionCode.yml, I would set it to trigger on commit to Main or a specified branch. 

# Create Service Principal and Service Connection for Azure DevOps

1) Sign in to your Azure DevOps (dev.azure.com)
2) Assuming you have Organisation in place, you can create a new Project within Azure DevOps.
3) You need to have a service connection, which will use Service Principal to give access for Azure DevOps to deploy into your Azure subscription.

To create a Service Principal, with owner role and scoped to a subscription level 

```
az ad sp create-for-rbac -n spprnonprodsubowner --role Owner --scopes /subscriptions/XXXXXX-7639-4619-b179-8bd9dcXXXXX
```

It will give you output like this, please copy and save it separately as we need this information when creating service connection in Azure DevOps.
```
{
"appId": "88XXXf6b-c2e5-475e-ba12-26XXXXXaf0",
"displayName": "spXXXXXrodsub",
"password": "0CgXXXXXXXXXX2w-lNCMc1XXav6",
"tenant": "16XX013-XX-468d-ac64-XXXXX"
}
```

To create Service Connection, navigate to Azure Devops --> Project --> Project Settings --> Service Connections

![ADO Service Connection](<../images/adoserviceconnection.png>)

![ADO Service Connection](<../images/adoserviceconnection2.png>)

![ADO Service Connection](<../images/adoserviceconnection3.png>)

![ADO Service Connection](<../images/adoserviceconnection4.png>)

Service Principal Key is the password from the ad ad sp create command output 

Service Principal ID is the appId

Subscription ID and Subscription Name should be part of your subscription, which you can find out

Tenant ID is the Tenant as shown from the output below.

Give a friendly name and description and click verify and save. This gives ADO access to Azure subscription to go and deploy resources.

```
{
"appId": "88XXXf6b-c2e5-475e-ba12-26XXXXXaf0",
"displayName": "spXXXXXrodsub",
"password": "0CgXXXXXXXXXX2w-lNCMc1XXav6",
"tenant": "16XX013-XX-468d-ac64-XXXXX"
}
```

# Create Azure Pipelines

Navigate to your Pipelines in Azure DevOps project and create new pipeline.

Select GitHub as the repository and pick the DeployFunctionsInfrastructure.yml file to create the Pipeline.

![ADO Pipeline](<../images/pipeline1.png>)
![ADO Pipeline](<../images/pipeline2.png>)

Repeat the steps above to create the second pipeline (PublishFunctionsCode.yml)

You can then run these pipelines.

