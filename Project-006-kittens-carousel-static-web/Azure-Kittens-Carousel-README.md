# Project-006 : Kittens Carousel Static Website deployed on Azure Storage, Azure CDN and Azure DNS using ARM Template

## Description

Kittens Carousel is a **static website** hosted on **Azure Storage
(Static Website Hosting)**, delivered securely through **Azure CDN**,
and made publicly available via a **custom domain** configured in
**Azure DNS** --- all deployed automatically using an **Azure ARM
Template**.

## Problem Statement

![Project_006](Project_006.png)

Your company has developed a simple static web application named
**Kittens Carousel**, which showcases cute kitten images.\
Previously, it was demonstrated locally and on a virtual machine. Now,
you are required to deploy it in a **production-ready Azure
environment**.

You will:

-   Deploy the static web app to **Azure Storage Account** configured
    for static website hosting.
-   Distribute it globally through **Azure CDN** for performance and
    HTTPS support.
-   Manage the domain using **Azure DNS Zone**.
-   Automate the entire setup using an **Azure Resource Manager (ARM)
    Template**.

### Requirements

1.  When the web app starts, the user should see the `index.html` page.
2.  The application must be accessible via the company's domain using
    **Azure DNS** and **Azure CDN**.
3.  The ARM Template should:
    -   Create all new Azure resources automatically.
    -   Accept two parameters:
        -   DNS zone name (e.g., `devopsdreieich.online`)
        -   Full domain name for the web app (e.g.,
            `kittens.devopsdreieich.online`)
    -   Configure:
        -   A **Storage Account** with Static Website enabled.
        -   An **Azure CDN Profile and Endpoint** connected to the
            storage origin.
        -   A **CDN Custom Domain** secured with **Azure-managed HTTPS
            certificate**.
        -   A **DNS A/AAAA or CNAME Record** pointing to the CDN
            endpoint.
    -   Output:
        -   Full Domain Name of the Kittens Carousel Application
        -   CDN Endpoint Hostname
        -   Storage Account Name
4.  The application files should be uploaded to the storage account
    using the **Azure CLI**.

------------------------------------------------------------------------

## Project Skeleton

``` text
006-kittens-carousel-static-web-azure (folder)
│
│---- README.md              # This file
│---- arm-template.json      # ARM Template for deployment
│---- upload-script.sh       # Bash script to upload static files
│---- static-web
│       ├── index.html
│       ├── cat0.jpg
│       ├── cat1.jpg
│       └── cat2.jpg
```

------------------------------------------------------------------------

## Expected Outcome

![Project 006 : Kittens Carousel Application
Snapshot](./project-006-snapshot.png)

### By completing this project, you will learn:

-   Static Website Deployment on Azure
-   Azure Storage (Static Website)
-   Azure CDN configuration
-   Azure DNS management
-   ARM Template design and parameters
-   Bash scripting with Azure CLI
-   Git & GitHub for version control

------------------------------------------------------------------------

## Steps to Solution

1.  **Clone or download** this repository:

    ``` bash
    git clone https://github.com/<your-repo>/Azure-Projects.git
    ```

2.  **Create Resource Group**:

    ``` bash
    az group create --name kittens-rg --location westeurope
    ```

3.  **Deploy the ARM Template**:

    ``` bash
    az deployment group create      --name kittens-deploy      --resource-group kittens-rg      --template-file arm-template.json      --parameters dnsZoneName=devopsdreieich.online fullDomainName=kittens.devopsdreieich.online
    ```

4.  **Upload your static web files**:

    ``` bash
    az storage blob upload-batch      --account-name <yourStorageAccountName>      --destination '$web'      --source ./static-web
    ```

5.  **Browse your website** using:

        https://kittens.devopsdreieich.online

------------------------------------------------------------------------

## Notes

-   Replace `student_name` in `index.html` with your own name.
-   Use the `upload-script.sh` to automate upload via Azure CLI.
-   Make sure your domain is managed in **Azure DNS**.

------------------------------------------------------------------------

## Resources

-   [Azure Resource Manager (ARM)
    Templates](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/overview)
-   [Azure Storage Static Website
    Hosting](https://learn.microsoft.com/en-us/azure/storage/blobs/storage-blob-static-website)
-   [Azure CDN
    Documentation](https://learn.microsoft.com/en-us/azure/cdn/)
-   [Azure DNS
    Documentation](https://learn.microsoft.com/en-us/azure/dns/)
-   [Azure CLI Command
    Reference](https://learn.microsoft.com/en-us/cli/azure/)
