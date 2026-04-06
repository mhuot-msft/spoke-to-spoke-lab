using './main.bicep'

param location = 'centralus'
param adminUsername = 'azureuser'
param adminPublicKey = '<SSH_PUBLIC_KEY>'
param allowedSshSourceIp = '<YOUR_IP_ADDRESS>'
param storageAccountSuffix = '<UNIQUE_SUFFIX>'
