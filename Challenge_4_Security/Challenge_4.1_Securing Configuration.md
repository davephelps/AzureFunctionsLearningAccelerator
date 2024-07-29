# Challenge 4.1 - Securing Configuration Settings

## Summary
In this lab we will take  sensitive configuration values such as Service Bus and Cosmos connection strings, store them in KeyVault and reference them from the Function App Configuration.


# KeyVault Configuration
Create an instance of KeyVault in the Standard tier, making sure to select the Access Configuration to RBAC (Role Based Access Control).

![KeyVault Config](<images/Keyvault Access Configuration.png>)

Ensure you add your own username to have permission to administer secrets by navigating to Access Control and adding yourself to the Key Vault Administrator role:

![Add Role Assignment](<images/KeyVault - Add Role Assignment.png>)

Create a new secret value for the Service Bus Connection string:

![Create Secret](<images/KeyVault - Create Secret.png>)

Grant access to allow the Function App to have read access to the secret by clicking the secret then clicking Access control (IAM) and adding the Function App Managed Identity as a Key Vault Secrets User:

![Secret Role](<images/KeyVault - Add Role Assingment Secret.png>)

Click on the secret then click on the version and copy the secret identifier:

![Secret Identifier](<images/KeyVault - Secret Identifier.png>)

Now we need to add a *KeyVault Reference* in our Function App to read the value from the secret. Navigate to the Function App, Configuration Settings, then to the configuration item that needs to be protected, for example the ServiceBusConnection.

Paste the identifier uri, in the following format:

@Microsoft.KeyVault(SecretUri=https://contosokeyvaultdp.vault.azure.net/secrets/ServiceBusConnection/6a24a61624caa8ac46507f1148347)

When the settings are saved, the setting should be visible as a KeyVault reference:
![KeyVault Reference](<images/Function App - KeyVauly Reference.png>)

The the function to ensure it is working.

## Enable KeyVault Private Endpoint
For an additional challenge, try enabling a private endpoint for KeyVault and disable public access. 

The Orchestator Function App should already be VNET enabled from the networking challenge, so if the private endpoint is created in the same VNET, the connectivity should work.

Once the private endpoint has been enabled, stop and start the Orchestrator Function App then navigate to the Configuration Settings. The KeyVault reference created earlier should be enabled without any errors.

Test the solution end to end to ensure the Orchestrator Function still executes without error.

