using 'main.bicep'

param location = 'eastus2'
param adminUsername = 'azureuser'
param adminPublicKey = '<replace-with-your-ssh-public-key>'
param allowedSshSourceIp = '<replace-with-your-public-ip>'
param storageAccountSuffix = '<replace-with-unique-suffix>'
