# Azure Hands-on: Phonebook Application (Python Flask) deployed on Azure Load Balancer with Virtual Machine Scale Set and Azure Database for MySQL using ARM Template (or Bicep)

## Description

The Phonebook Application will be deployed as a web app using **Python Flask**, hosted on **Azure Virtual Machine Scale Set (VMSS)** behind an **Azure Load Balancer**, and connected to **Azure Database for MySQL Flexible Server**.  
All resources will be created and configured automatically using **Azure Resource Manager (ARM) Template** or **Bicep**.

---

## Architecture Overview

```
                ┌───────────────────────────┐
                │ Azure Load Balancer       │
                │ (Public Frontend - Port 80)│
                └──────────────┬────────────┘
                               │
          ┌────────────────────┴────────────────────┐
          │ Azure VM Scale Set (2-3 Instances)      │
          │  - Flask App via cloud-init             │
          │  - Nginx + Gunicorn optional            │
          └────────────────────┬────────────────────┘
                               │
                 ┌─────────────┴─────────────┐
                 │ Azure Database for MySQL  │
                 │ (Flexible Server)         │
                 └───────────────────────────┘
```

---

## Step 1 – Create Resource Group

```bash
az group create --name PhonebookRG --location "Sweden Central"
```

---

## Step 2 – Create Azure Database for MySQL Flexible Server

```bash
az mysql flexible-server create   --name phonebookmysql   --resource-group PhonebookRG   --location "Sweden Central"   --admin-user phoneadmin   --admin-password StrongP@ssw0rd!   --sku-name Standard_B1ms   --tier Burstable   --storage-size 20   --version 8.0   --public-access 0.0.0.0-255.255.255.255
```

Collect connection info (hostname, username, password) — will be used in Flask `app.py`.

---

## Step 3 – Prepare `cloud-init` Script (userdata equivalent)

Save the following as `cloud-init.txt`:

```bash
#cloud-config
package_update: true
packages:
  - python3
  - python3-pip
  - git
runcmd:
  - pip3 install flask pymysql
  - mkdir -p /home/azureuser/phonebook/templates
  - cd /home/azureuser/phonebook
  - wget -P templates https://raw.githubusercontent.com/AydinTokuslu/my-aws-projects/main/aws/Project-004-Phonebook-Application/templates/index.html
  - wget -P templates https://raw.githubusercontent.com/AydinTokuslu/my-aws-projects/main/aws/Project-004-Phonebook-Application/templates/add-update.html
  - wget -P templates https://raw.githubusercontent.com/AydinTokuslu/my-aws-projects/main/aws/Project-004-Phonebook-Application/templates/delete.html
  - wget https://raw.githubusercontent.com/AydinTokuslu/my-aws-projects/main/aws/Project-004-Phonebook-Application/app.py
  - sed -i 's/localhost/<MYSQL_HOST>/g' app.py
  - nohup python3 app.py &
```

Replace `<MYSQL_HOST>` with your MySQL flexible server’s FQDN.

---

## Step 4 – Create Load Balancer and Scale Set

```bash
az network vnet create --name phonebook-vnet --resource-group PhonebookRG --subnet-name phonebook-subnet

az network public-ip create --resource-group PhonebookRG --name phonebook-ip --sku Standard --allocation-method static

az network lb create   --resource-group PhonebookRG   --name phonebook-lb   --frontend-ip-name phonebookFrontEnd   --backend-pool-name phonebookBackEnd   --public-ip-address phonebook-ip

az network lb probe create   --resource-group PhonebookRG   --lb-name phonebook-lb   --name httpProbe   --protocol tcp   --port 80

az network lb rule create   --resource-group PhonebookRG   --lb-name phonebook-lb   --name httpRule   --protocol tcp   --frontend-port 80   --backend-port 80   --frontend-ip-name phonebookFrontEnd   --backend-pool-name phonebookBackEnd   --probe-name httpProbe
```

Then create the VM Scale Set:

```bash
az vmss create   --resource-group PhonebookRG   --name phonebook-vmss   --image Ubuntu2204   --upgrade-policy-mode automatic   --instance-count 2   --admin-username azureuser   --generate-ssh-keys   --custom-data cloud-init.txt   --vnet-name phonebook-vnet   --subnet phonebook-subnet   --lb phonebook-lb   --backend-pool-name phonebookBackEnd
```

---

## Step 5 – Get Public IP and Test

```bash
az network public-ip show   --name phonebook-ip   --resource-group PhonebookRG   --query ipAddress   --output tsv
```

Then visit:

```
http://<PUBLIC_IP>:80
```

You should see the Phonebook app running on Flask.

---

## Step 6 – Clean Up

```bash
az group delete --name PhonebookRG --yes --no-wait
```

---

## Summary

| AWS Resource / Concept           | Azure Equivalent                            |
|----------------------------------|---------------------------------------------|
| EC2 Launch Template + ASG        | Virtual Machine Scale Set                   |
| Application Load Balancer (ALB)  | Azure Load Balancer                         |
| RDS MySQL                        | Azure Database for MySQL Flexible Server    |
| CloudFormation Template          | ARM Template / Bicep                        |
| Security Groups                  | NSG + Load Balancer Rules                   |
| User Data                        | Cloud-init (customData)                     |
