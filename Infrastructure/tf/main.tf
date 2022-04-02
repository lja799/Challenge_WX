#########################################################################
# Deploys the BestApiEver to Azure WebApps for Containers
#########################################################################

terraform {
  backend "azurerm" {
    resource_group_name  = "Terraform"
    storage_account_name = "terraformstate01234"
    container_name       = "infra-terraform-state"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

locals {
  identities = {
    webapp = {
      "tenant_id"     = azurerm_linux_web_app.webapp.identity[0].tenant_id
      "principal_id"  = azurerm_linux_web_app.webapp.identity[0].principal_id
    }
    webapp_slot = {
      "tenant_id"     = azurerm_linux_web_app_slot.webapp_slot.identity[0].tenant_id
      "principal_id"  = azurerm_linux_web_app_slot.webapp_slot.identity[0].principal_id
    }
  }
}

data "azurerm_client_config" "current" {}

#########################################################################
# Resources
#########################################################################

resource "azurerm_resource_group" "rg" {
  name     = "rg-bestapiever"
  location = "Australia SouthEast"
}

resource "azurerm_key_vault" "key_vault" {
  name                        = "kv-bestapievervault01"
  resource_group_name         = azurerm_resource_group.rg.name
  location                    = azurerm_resource_group.rg.location
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
      "Create"
    ]

    secret_permissions = [
      "Set",
      "Get",
      "Delete",
      "Purge",
      "Recover"
    ]
  }
}

resource "azurerm_key_vault_secret" "secret" {
  name         = "APIKEY"
  value        = var.apikey_secret
  key_vault_id = azurerm_key_vault.key_vault.id
}

resource "azurerm_key_vault_access_policy" "kv_access_policy" {
  for_each     = local.identities
  key_vault_id = azurerm_key_vault.key_vault.id
  tenant_id    = each.value["tenant_id"]
  object_id    = each.value["principal_id"]

  key_permissions = [
    "Get",
  ]

  secret_permissions = [
    "Get",
  ]
}

resource "azurerm_service_plan" "app_plan" {
  name                = "bestever-plan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "S1"
}

resource "azurerm_linux_web_app" "webapp" {
  name                = "bestapiever01"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.app_plan.id

  site_config {
    always_on           = true
    health_check_path   = var.health_check
    application_stack  {
      docker_image      = var.docker_image
      docker_image_tag  = var.docker_image_tag
    }
  }

  app_settings = {
    APIKEY = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault.key_vault.vault_uri}secrets/${azurerm_key_vault_secret.secret.name}/)"
  }

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [
      site_config[0].application_stack[0].docker_image_tag
    ]
  }
}

resource "azurerm_linux_web_app_slot" "webapp_slot" {
  name           = "preview"
  app_service_id = azurerm_linux_web_app.webapp.id

 site_config {
    always_on           = true
    health_check_path   = var.health_check
    application_stack  {
      docker_image      = var.docker_image
      docker_image_tag  = var.docker_image_tag
    }
  }

  app_settings = {
    APIKEY = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault.key_vault.vault_uri}secrets/${azurerm_key_vault_secret.secret.name}/)"
  }

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [
      site_config[0].application_stack[0].docker_image_tag
    ]
  }
}