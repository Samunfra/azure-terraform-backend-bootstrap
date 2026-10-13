#!/bin/bash

# Create a remote Terraform backend on Azure (Storage Account + Blob Container).

# This script is run before Terraform because Terraform needs the backend
# to store its state before it can manage the infrastructure.

# Prerequisites: Azure CLI installed and logged in.
# You also need permission to create role assignments.

#immediately stops the script if a command fails
set -e

# Basic variables
RESOURCE_GROUP_NAME="rg-tfstate"
LOCATION="westeurope"
CONTAINER_NAME="tfstate"

# Storage account names must be unique worldwide
STORAGE_ACCOUNT_NAME="abcdetfstateproject1"

echo "=== Creating Terraform backend ==="

#Get the current Azure subscription
SUBSCRIPTION_ID=$(az account show --query id -o tsv) 
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)

echo "Using subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"

# Get the current Azure user
MY_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv)

# Create the Resource Group
echo "Creating Resource Group..."
az group create \
  --name "$RESOURCE_GROUP_NAME" \
  --location "$LOCATION" \
  --output none

# Create the storage account with secure transport
# and anonymous blob access disabled
echo "Creating Storage Account..."
az storage account create \
  --name "$STORAGE_ACCOUNT_NAME" \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --min-tls-version TLS1_2 \
  --https-only true \
  --allow-blob-public-access false \
  --output none

# Enable blob versioning
echo "Enabling Blob versioning..."
az storage account blob-service-properties update \
  --account-name "$STORAGE_ACCOUNT_NAME" \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --enable-versioning true \
  --output none

# Get the storage account resource ID
STORAGE_ID=$(az storage account show \
  --name "$STORAGE_ACCOUNT_NAME" \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --query id \
  -o tsv)

# Check if the current user already has the required role
ROLE_EXISTS=$(az role assignment list \
  --assignee "$MY_OBJECT_ID" \
  --scope "$STORAGE_ID" \
  --role "Storage Blob Data Contributor" \
  --query "[].id" \
  -o tsv)

if [ -z "$ROLE_EXISTS" ]; then

  echo "Storage Blob Data Contributor role not found."
  echo "Assigning role..."

  az role assignment create \
    --role "Storage Blob Data Contributor" \
    --assignee "$MY_OBJECT_ID" \
    --scope "$STORAGE_ID" \
    --output none

else

  echo "Storage Blob Data Contributor role already exists."

fi

# Wait for RBAC permissions to become available
echo "Waiting for RBAC permissions..."

for i in {1..12}; do

  if az storage container create \
    --name "$CONTAINER_NAME" \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --auth-mode login \
    --output none 2>/dev/null; then

    echo "Blob permissions are ready."
    break

  fi

  echo "RBAC is not ready yet... waiting 10 seconds."
  sleep 10

done

# Final check
if ! az storage container show \
  --name "$CONTAINER_NAME" \
  --account-name "$STORAGE_ACCOUNT_NAME" \
  --auth-mode login \
  --output none 2>/dev/null; then

  echo "ERROR: Could not access the Blob container."
  echo "RBAC permissions may not have propagated yet."
  exit 1
fi

echo ""
echo "=== Terraform backend ready ==="
echo ""
echo "Resource Group:    $RESOURCE_GROUP_NAME"
echo "Storage Account:   $STORAGE_ACCOUNT_NAME"
echo "Container:         $CONTAINER_NAME"
echo ""
echo "Use this Storage Account name for your Terraform backend:"
echo "$STORAGE_ACCOUNT_NAME"