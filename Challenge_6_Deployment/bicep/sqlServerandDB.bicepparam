using 'sqlServerandDB.bicep'

param sqlServerName = 'pbsqlservertest123b'
param sqlDatabaseName = 'pbsqldntest123b'
param adminLogin = 'adminuser'
param adminPassword = 'adminpassword'
//aadadminlogin is the user principal in the Active directory
param aadAdminLogin = 'something@login.onmicrosoft.com'
//param aadAdminObjectId = '0eeeb77a-e526-40aa-96ab-556306758e20'
//aadadminobjectid is the object id of the user in Active directory
param aadAdminObjectId = '926a7a9f-36d0-49c4-XXXXX'
param firewallRuleName = 'clientIPRange'
param clientIpStartRange = '5.151.161.190'
param clientIpEndRange = '5.151.161.199'
