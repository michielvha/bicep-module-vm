@allowed([
  'westeurope'
  'northeurope'
])
param location string
@allowed([
  'acceptance'
  'production'
  'integration'
])
param environment string
param purpose string
param vmAdmin string
param vmSize string

param bootStorage string
@secure()
param vmAdminPassword string
param osPublisher string
param osOffer string
param osSKU string
param osVersion string

var locShort = {
  westeurope: 'we'
  northeurope: 'ne'
}

var envShortMap = {
  integration: 'int'
  production: 'prd'
  acceptance: 'acc'
}
var envShort = envShortMap[environment]




var vnetName = 'vnet-${envShortMap[environment]}-${locShort[location]}'
var subnetName = '${purpose}-sn'
var subnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)

var vmName = 'vm-${envShortMap[environment]}-${locShort[location]}-${purpose}'
var nicName = '${vmName}-nic'
var pipName = '${vmName}-pip'

resource myStorage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: bootStorage
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource myPIP 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: pipName
  location:location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource myNIC 'Microsoft.Network/networkInterfaces@2023-05-01' = {
  name: nicName
  location:location
  properties:{
    ipConfigurations:[
      {
        name:'ipconfig'
        properties:{
          subnet:{
            id:subnetId
          }
          publicIPAddress:{
            id:myPIP.id
          }
        }
      }
    ]
  }
}

resource myVM 'Microsoft.Compute/virtualMachines@2025-04-01' = {
  name: vmName
  location: location
  properties: {
    osProfile: {
      adminPassword: vmAdminPassword
      adminUsername: vmAdmin
      computerName: vmName

    }
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: osPublisher
        offer: osOffer
        sku: osSKU
        version: osVersion
      }
      osDisk: {
        createOption: 'FromImage'
        name: 'osdisk'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: myNIC.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: myStorage.properties.primaryEndpoints.blob
      }
    }
  }
}
