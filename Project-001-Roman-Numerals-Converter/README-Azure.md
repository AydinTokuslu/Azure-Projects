# Project-001 : Roman Numerals Converter Application (Python Flask) deployed on Azure Virtual Machine with ARM Template

## 🧩 Description
The **Roman Numerals Converter Application** converts a given number (1–3999) into its Roman numeral representation.  
It is coded in **Python Flask** and deployed as a web application on an **Azure Virtual Machine (Ubuntu 22.04 LTS)** using an **Azure ARM Template**.

---

## 🧠 Problem Statement

![Project_001](Project_001_.png)

- Your company plans to create a web platform for unit converters and formula tools.  
  The Roman Numerals Converter is the first part of this project.  
  You are tasked with developing and deploying it on **Microsoft Azure**.

- As the first step, you will write a **Python Flask** application that converts a number (1–3999) into Roman numerals.  
  The conversion rules are the same as in the AWS version:

```
Roman numerals are represented by seven symbols: I, V, X, L, C, D, and M.
- Symbol   Value
- I         1
- V         5
- X         10
- L         50
- C         100
- D         500
- M         1000
```

Conversion logic and invalid input handling remain identical.

---

## 🧱 Infrastructure Overview (Azure)

You will deploy the Flask app on **Azure Virtual Machine** using an **ARM Template** that automates the setup:

### Components
- **Azure Virtual Network (VNet)** and **Subnet**
- **Network Security Group (NSG)** allowing inbound traffic:
  - TCP 22 → SSH access
  - TCP 80 → HTTP web access
- **Public IP Address** (Standard SKU, Static)
- **Network Interface (NIC)** associated with the VM
- **Ubuntu 22.04 LTS Virtual Machine**
- **Cloud-init (customData)** installs Python3, Flask, Git and deploys app from GitHub

### User parameters
- `adminUsername` → SSH username  
- `adminPublicKey` → your SSH public key (for secure access)  
- `vmSize` → default: `Standard_B1s`  
- `location` → Azure region (default: resource group location)

---

## ⚙️ Deployment Steps (Azure Portal)

### **Step 1:** Open Azure Portal  
Go to **Create a resource → Template deployment (deploy using custom template)**.

### **Step 2:** Upload the ARM Template  
Load your `roman-numbers-arm-standardpip.json` file.

### **Step 3:** Fill in parameters  
- `adminUsername`: e.g., `aydin`  
- `adminPublicKey`: paste your SSH public key  
- `location`: choose your Azure region  

### **Step 4:** Review + Create  
Deploy the stack. Azure will create all resources automatically.

### **Step 5:** Access the Application  
After deployment, go to **Outputs → websiteURL**  
Example:  
```
http://20.125.xxx.xxx
```
You’ll see the Flask-based Roman Numerals Converter page.

---

## 🪄 Project Structure

```
001-roman-numerals-converter
|----app.py
|----templates/
|     |----index.html
|     |----result.html
|----roman-numbers-arm-standardpip.json  # ARM Template for Azure
|----README-Azure.md                     # Project documentation
```

---

## 🎯 Expected Outcome

![Project 001 Snapshot](project-001-snapshot.png)

By the end of this project, you will have learned how to:

- Design algorithms for Roman numeral conversion  
- Build and serve web apps with Python Flask  
- Deploy infrastructure using **Azure ARM Templates**  
- Configure **Azure Network Security Groups**  
- Manage **SSH access and cloud-init** for app deployment  
- Use **Git & GitHub** for version control  

---

## 🧰 Technologies Covered
- Python 3
- Flask Web Framework
- Azure Virtual Machines
- Azure Resource Manager (ARM)
- Azure Portal Deployment
- Azure Networking (NSG, VNet, Public IP)
- Git & GitHub

---

## 🚀 Steps to Solution

1. Clone or download the project repository.  
2. Review the Python Flask application (`app.py` and templates).  
3. Deploy the Azure ARM template via Azure Portal.  
4. Wait until all resources are provisioned.  
5. Access the web app via the **Public IP** shown in the outputs.

---

## 💬 Notes
- You can customize the app by setting a developer name in HTML templates.  
- To make the app start automatically after reboot, you can create a `systemd` service.  
- For production setups, use **Application Gateway** or **Azure App Service** instead of a single VM.

---

## 📚 Resources
- [Python Flask Documentation](https://flask.palletsprojects.com/)
- [Azure ARM Templates Guide](https://learn.microsoft.com/azure/azure-resource-manager/templates/)
- [Cloud-init in Azure](https://learn.microsoft.com/azure/virtual-machines/linux/using-cloud-init)
- [Azure Portal](https://portal.azure.com)
