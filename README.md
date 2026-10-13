# Azure Terraform Backend Bootstrap

## Overview

This project contains a Bash script to create a remote Terraform backend on Azure.

The script creates an Azure Storage Account and a Blob Container to store Terraform state files. It also configures blob versioning and assigns the required RBAC role to the current Azure user.

The goal is to automate the initial setup before running Terraform.

## What does the script do?

- Creates an Azure Resource Group.
- Creates a Storage Account with HTTPS required and anonymous blob access disabled.
- Enables blob versioning.
- Assigns the `Storage Blob Data Contributor` role to the current Azure user if needed.
- Creates the Blob Container and retries if the permissions are not ready yet.
- Checks that the container is accessible before finishing.

## Prerequisites

Before running the script, make sure you have:

- An Azure subscription.
- Azure CLI installed.
- Bash available.
- An Azure account logged in with `az login`.
- Permissions to create Azure resources and assign RBAC roles.

## Configuration

Before running the script, edit the variables at the beginning of `bootstrap.sh`:

```bash
RESOURCE_GROUP_NAME="Name of the Azure resource group"
LOCATION="Azure region where the resources will be created"
CONTAINER_NAME="Name of the blob container you will use to store the Terraform state"
STORAGE_ACCOUNT_NAME="Name of the Azure storage account"
```

You can check the script for examples of how these variables are used.

**Important:** Azure Storage Account names must be unique worldwide. The name must contain between 3 and 24 lowercase letters or numbers. Replace the example name with an available name before running the script.

## Usage

Log in to Azure:

```bash
az login
```

Make the script executable and run it:

```bash
chmod +x bootstrap.sh
./bootstrap.sh
```

The script will create the required Azure resources and check that the Blob Container is accessible.

## Notes

This script is intended for the initial backend setup. It does not deploy any infrastructure managed by Terraform.

After the backend is created, it can be configured in a Terraform project using the AzureRM backend.

The script is designed for an interactive Azure CLI login using a user account. The required permissions must be available in the selected Azure subscription.

## Possible improvements

- Improve error handling and logging.
- Add network restrictions for the Storage Account.

## Disclaimer

This is a personal learning project to practise Bash scripting, Azure administration and Terraform backend configuration. Test it in a development environment before using it in production.
