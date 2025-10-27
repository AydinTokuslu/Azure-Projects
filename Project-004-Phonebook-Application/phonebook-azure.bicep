
@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Existing subnet resource ID where VMSS NICs will be placed, e.g., /subscriptions/xxx/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/app-subnet')
param vmSubnetId string

@description('Admin username for Linux VMs')
param adminUsername string = 'azureuser'

@description('SSH public key for the admin user')
@secure()
param sshPublicKey string

@description('Desired capacity (number of VM instances)')
@minValue(1)
@maxValue(100)
param instanceCount int = 2

@description('VM SKU for the scale set')
param vmSku string = 'Standard_B2s'

@description('Git repository containing the Phonebook app')
param appRepoUrl string = 'https://github.com/clarusway/phonebook-app.git'

@description('Branch or ref to checkout')
param appRepoRef string = 'main'

@description('DB connection string for the app (e.g., mysql+pymysql://user:pass@host:3306/phonebook)')
@secure()
param dbConnectionString string

@description('Restrict SSH to this CIDR (e.g., your public IP/32). Use 0.0.0.0/0 to allow all (not recommended).')
param sshAllowedCidr string = '0.0.0.0/0'

@description('DNS name label for the public IP (optional, must be globally unique if specified)')
param dnsLabel string = ''

var lbName = 'pb-lb'
var pipName = 'pb-pip'
var nsgName = 'pb-nsg'
var vmssName = 'pb-vmss'

resource pip 'Microsoft.Network/publicIPAddresses@2022-11-01' = {
  name: pipName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: empty(dnsLabel) ? null : {
      domainNameLabel: dnsLabel
    }
  }
}

resource lb 'Microsoft.Network/loadBalancers@2022-11-01' = {
  name: lbName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'fe'
        properties: {
          publicIPAddress: {
            id: pip.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'be'
      }
    ]
    loadBalancingRules: [
      {
        name: 'http-80'
        properties: {
          frontendIPConfiguration: {
            id: lb.properties.frontendIPConfigurations[0].id
          }
          backendAddressPool: {
            id: lb.properties.backendAddressPools[0].id
          }
          probe: {
            id: lb::probes[0].id
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          enableFloatingIP: false
          idleTimeoutInMinutes: 4
          loadDistribution: 'Default'
        }
      }
    ]
    probes: [
      {
        name: 'http'
        properties: {
          protocol: 'Tcp'
          port: 80
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2022-11-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'allow-http'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'allow-ssh'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: sshAllowedCidr
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource vmss 'Microsoft.Compute/virtualMachineScaleSets@2023-09-01' = {
  name: vmssName
  location: location
  sku: {
    name: vmSku
    capacity: instanceCount
    tier: 'Standard'
  }
  properties: {
    upgradePolicy: {
      mode: 'Rolling'
      rollingUpgradePolicy: {
        maxBatchInstancePercent: 20
        maxUnhealthyInstancePercent: 20
        maxUnhealthyUpgradedInstancePercent: 5
        pauseTimeBetweenBatches: 'PT0S'
      }
    }
    virtualMachineProfile: {
      osProfile: {
        computerNamePrefix: 'pbvm'
        adminUsername: adminUsername
        linuxConfiguration: {
          disablePasswordAuthentication: true
          ssh: {
            publicKeys: [
              {
                path: '/home/${adminUsername}/.ssh/authorized_keys'
                keyData: sshPublicKey
              }
            ]
          }
        }
        customData: base64('#cloud-config\npackage_update: true\npackages:\n  - git\n  - python3-pip\n  - python3-venv\n  - nginx\nruncmd:\n  - [ bash, -lc, \"set -euxo pipefail\" ]\n  - [ bash, -lc, \"sudo systemctl disable --now apache2 || true\" ]\n  - [ bash, -lc, \"sudo useradd -m -s /bin/bash app || true\" ]\n  - [ bash, -lc, \"sudo -u app bash -lc \\\"cd ~ && rm -rf app && git clone --depth=1 --branch ${appRepoRef} ${appRepoUrl} app\\\"\" ]\n  - [ bash, -lc, \"sudo -u app bash -lc 'cd ~/app && python3 -m venv .venv && source .venv/bin/activate && pip install --upgrade pip wheel && pip install -r requirements.txt || pip install flask pymysql sqlalchemy'\" ]\n  - [ bash, -lc, \"sudo tee /etc/systemd/system/phonebook.service > /dev/null <<'UNIT'\\n[Unit]\\nDescription=Phonebook Flask App\\nAfter=network-online.target\\nWants=network-online.target\\n\\n[Service]\\nUser=app\\nWorkingDirectory=/home/app/app\\nEnvironment=FLASK_APP=app.py\\nEnvironment=DB_CONNECTION=${dbConnectionString}\\nExecStart=/home/app/app/.venv/bin/python -m flask run --host=0.0.0.0 --port=80\\nRestart=always\\nRestartSec=5\\n\\n[Install]\\nWantedBy=multi-user.target\\nUNIT\" ]\n  - [ bash, -lc, \"sudo setcap 'cap_net_bind_service=+ep' /home/app/app/.venv/bin/python || true\" ]\n  - [ bash, -lc, \"sudo systemctl daemon-reload && sudo systemctl enable --now phonebook.service\" ]\n  - [ bash, -lc, \"sudo rm -f /etc/nginx/sites-enabled/default && echo 'server { listen 80 default_server; location / { proxy_pass http://127.0.0.1:80; proxy_set_header Host $host; proxy_set_header X-Real-IP $remote_addr; } }' | sudo tee /etc/nginx/sites-available/phonebook && sudo ln -sf /etc/nginx/sites-available/phonebook /etc/nginx/sites-enabled/ && sudo systemctl enable --now nginx\" ]\n')
      }
      storageProfile: {
        imageReference: {
          publisher: 'Canonical'
          offer: '0001-com-ubuntu-server-jammy'
          sku: '22_04-lts'
          version: 'latest'
        }
        osDisk: {
          createOption: 'FromImage'
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
          diskSizeGB: 30
        }
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: 'nic'
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: 'ipconfig'
                  properties: {
                    subnet: {
                      id: vmSubnetId
                    }
                    loadBalancerBackendAddressPools: [
                      {
                        id: lb.properties.backendAddressPools[0].id
                      }
                    ]
                  }
                }
              ]
              networkSecurityGroup: {
                id: nsg.id
              }
            }
          }
        ]
      }
      diagnosticsProfile: {
        bootDiagnostics: {
          enabled: true
        }
      }
    }
    overprovision: true
    singlePlacementGroup: true
  }
}

output publicIp string = pip.properties.dnsSettings != null ? '${pip.properties.dnsSettings.fqdn}' : pip.properties.ipAddress
output lbPublicUrl string = 'http://' + (pip.properties.dnsSettings != null ? '${pip.properties.dnsSettings.fqdn}' : pip.properties.ipAddress)
