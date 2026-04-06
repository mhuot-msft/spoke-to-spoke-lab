using 'main.bicep'

param location = 'centralus'
param adminUsername = 'azureuser'
param adminPublicKey = '<replace-with-your-ssh-public-key>'
param allowedSshSourceIp = '<replace-with-your-public-ip>'
param storageAccountSuffix = '<replace-with-unique-suffix>'
