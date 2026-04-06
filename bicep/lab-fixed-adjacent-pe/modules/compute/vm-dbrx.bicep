param location string
param subnetId string
param adminUsername string
@secure()
param adminPublicKey string
param allowedSshSourceIp string
param tags object = {}

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: 'nsg-dbrx'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowSSH'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: allowedSshSourceIp
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
    ]
  }
}

resource pip 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: 'pip-dbrx'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2023-11-01' = {
  name: 'nic-dbrx'
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pip.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: 'vm-dbrx'
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v3'
    }
    osProfile: {
      computerName: 'vm-dbrx'
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: adminPublicKey
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

output vmPublicIp string = pip.properties.ipAddress
output vmPrincipalId string = vm.identity.principalId
