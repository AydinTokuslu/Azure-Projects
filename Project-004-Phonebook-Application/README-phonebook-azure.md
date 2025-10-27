
# Phonebook on Azure – Bicep (VMSS + Load Balancer)

This Bicep deploys:
- Standard Public IP
- Standard Load Balancer (port 80)
- Network Security Group (HTTP/SSH)
- Virtual Machine Scale Set (Ubuntu 22.04) with cloud-init to install and run the Phonebook Flask app behind Nginx
- Uses an **existing** subnet for the VMSS NICs

> **Note:** Supply your own MySQL connection string (for Azure Database for MySQL Flexible Server or any MySQL you manage).

## Parameters

- `vmSubnetId` (string, required): Existing subnet resource ID where VMSS instances will live  
  Example: `/subscriptions/<subId>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<vnet>/subnets/<subnet>`
- `sshPublicKey` (secureString, required): Your SSH public key
- `dbConnectionString` (secureString, required): Format like `mysql+pymysql://user:pass@host:3306/phonebook`
- `dnsLabel` (string, optional): If set, a DNS like `<label>.<region>.cloudapp.azure.com` will be created for the public IP
- `instanceCount`, `vmSku`, `adminUsername`, `appRepoUrl`, `appRepoRef`, `sshAllowedCidr` are customizable.

## Deploy

```bash
# 1) Variables
SUB=<your-subscription-id>
RG=<your-resource-group>
LOC=<azure-region>      # e.g. westeurope
SUBNETID=<subnet-resource-id>
DNSLABEL=<unique-dns-label>    # or leave empty

az account set -s $SUB

# 2) Create RG (if not exists)
az group create -n $RG -l $LOC

# 3) Deploy
az deployment group create -g $RG   -f phonebook-azure.bicep   -p vmSubnetId="$SUBNETID"      sshPublicKey="$(cat ~/.ssh/id_rsa.pub)"      dbConnectionString="mysql+pymysql://admin:StrongPassw0rd@myazmysql.mysql.database.azure.com:3306/phonebook"      dnsLabel="$DNSLABEL"
```

## App notes

- The VMSS cloud-init:
  - Installs Python, Git, Nginx
  - Clones `appRepoUrl` → `~/app` (user `app`)
  - Creates a Python venv, installs dependencies
  - Creates a systemd service that runs `gunicorn --bind 127.0.0.1:5000 wsgi:app`
  - Configures Nginx to reverse-proxy `http://127.0.0.1:5000` on port 80

- The Load Balancer health probe checks TCP 80 on instances.

- If your repo structure differs (module name, entrypoint), tweak the `customData` in `phonebook-azure.bicep` accordingly.

## Outputs
- `publicIp` – IP or FQDN of the public endpoint
- `lbPublicUrl` – ready-to-click `http://...` URL
