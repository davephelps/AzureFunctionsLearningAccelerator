param sqlServerName string
param sqlDatabaseName string
param location string = resourceGroup().location
param adminLogin string
param adminPassword string
param aadAdminLogin string
param aadAdminObjectId string
param clientIpStartRange string
param clientIpEndRange string
param firewallRuleName string

resource sqlServer 'Microsoft.Sql/servers@2020-08-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: adminLogin
    administratorLoginPassword: adminPassword
  }
}

resource aadAdmin 'Microsoft.Sql/servers/administrators@2020-08-01-preview' = {
  parent: sqlServer
  name: 'ActiveDirectory'
  properties: {
    administratorType: 'ActiveDirectory'
    login: aadAdminLogin
    sid: aadAdminObjectId
    tenantId: subscription().tenantId
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2020-08-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
}

resource firewallRule 'Microsoft.Sql/servers/firewallRules@2020-08-01-preview' = {
  parent: sqlServer
  name: firewallRuleName
  properties: {
    startIpAddress: clientIpStartRange
    endIpAddress: clientIpEndRange
  }
}
