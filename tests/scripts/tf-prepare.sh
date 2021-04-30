#!/usr/bin/bash
set -e

#
# Shell Script
# - Terraform Prepare
#

echo "==> Switching directories..."
cd "$PIPELINE_WORKSPACE/s/tests/deployment"

echo "==> Authenticating cli..."
az login \
    --service-principal \
    --tenant "$ARM_TENANT_ID" \
    --username "$ARM_CLIENT_ID" \
    --password "$ARM_CLIENT_SECRET"

echo "==> Creating SPN and Role Assignments..."
ARM_CLIENT=$(az ad sp create-for-rbac \
    --name "ES-$TF_VERSION-$TF_AZ_VERSION" \
    --role "Owner" \
    --scope "/providers/Microsoft.Management/managementGroups/$ARM_TENANT_ID" \
    --create-cert \
    --only-show-errors
)

echo "==> Creating provider.tf with required_provider version and credentials..."
cat > provider.tf <<TFCONFIG
variable "client_certificate_path" {}
variable "client_certificate_password" {}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "$TF_AZ_VERSION"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id             = "$ARM_SUBSCRIPTION_ID"
  client_id                   = "$(echo "$ARM_CLIENT" | jq -r '.appId')"
  client_certificate_path     = var.client_certificate_path
  client_certificate_password = var.client_certificate_password
  tenant_id                   = "$(echo "$ARM_CLIENT" | jq -r '.tenant')"
}
TFCONFIG

echo "==> TF_VAR_CLIENT_CERTIFICATE_PATH - <redacted>"
VAR_CLIENT_CERTIFICATE_PATH=$(echo "$ARM_CLIENT" | jq -r '.fileWithCertAndPrivateKey')
echo "##vso[task.setvariable variable=TF_VAR_CLIENT_CERTIFICATE_PATH;]$VAR_CLIENT_CERTIFICATE_PATH"

echo "==> TF_VAR_CLIENT_CERTIFICATE_PASSWORD - <redacted>"
VAR_CLIENT_CERTIFICATE_PASSWORD=$(echo "$ARM_CLIENT" | jq -r '.client_certificate_password' | sed 's:^null$::g')
echo "##vso[task.setvariable variable=TF_VAR_CLIENT_CERTIFICATE_PASSWORD;]$VAR_CLIENT_CERTIFICATE_PASSWORD"

echo "==> Generating root id's..."
ROOT_ID_1="$RANDOM"
ROOT_ID_2="$RANDOM"
ROOT_ID_3="$RANDOM"

echo "==> Azure Root ID 1 - $ROOT_ID_1"
echo "##vso[task.setvariable variable=TF_ROOT_ID_1;]$ROOT_ID_1"

echo "==> Azure Root ID 2 - $ROOT_ID_2"
echo "##vso[task.setvariable variable=TF_ROOT_ID_2;]$ROOT_ID_2"

echo "==> Azure Root ID 3 - $ROOT_ID_3"
echo "##vso[task.setvariable variable=TF_ROOT_ID_3;]$ROOT_ID_3"

echo "==> Displaying environment variables..."
echo "==> Terraform Version - $TF_VERSION"
echo "==> Terraform Provider Version - $TF_AZ_VERSION"
echo "==> Terraform Variable (Root Name) - ES-$TF_VERSION-$TF_AZ_VERSION"
