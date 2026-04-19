# ─────────────────────────────────────────────
# infrastructure/terraform/main.tf
# Provisions all Azure resources for FinSight AI
# Run: terraform init && terraform apply
# ─────────────────────────────────────────────

terraform {
  required_version = ">= 1.7"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.48"
    }
  }
  # Store state in Azure Blob (recommended for teams)
  # Uncomment after creating the storage account manually once
  # backend "azurerm" {
  #   resource_group_name  = "finsight-rg"
  #   storage_account_name = "finsighttfstate"
  #   container_name       = "tfstate"
  #   key                  = "finsight.terraform.tfstate"
  # }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# ── Resource Group ────────────────────────────
resource "azurerm_resource_group" "finsight" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# ── ADLS Gen2 Storage Account ─────────────────
resource "azurerm_storage_account" "adls" {
  name                     = var.adls_account_name
  resource_group_name      = azurerm_resource_group.finsight.name
  location                 = azurerm_resource_group.finsight.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true   # Hierarchical namespace = ADLS Gen2
  min_tls_version          = "TLS1_2"
  tags                     = local.common_tags
}

resource "azurerm_storage_container" "finsight" {
  name                  = "finsight"
  storage_account_name  = azurerm_storage_account.adls.name
  container_access_type = "private"
}

# Bronze / Silver / Gold directory structure
resource "azurerm_storage_blob" "bronze_placeholder" {
  name                   = "bronze/.keep"
  storage_account_name   = azurerm_storage_account.adls.name
  storage_container_name = azurerm_storage_container.finsight.name
  type                   = "Block"
  source_content         = ""
}

resource "azurerm_storage_blob" "silver_placeholder" {
  name                   = "silver/.keep"
  storage_account_name   = azurerm_storage_account.adls.name
  storage_container_name = azurerm_storage_container.finsight.name
  type                   = "Block"
  source_content         = ""
}

resource "azurerm_storage_blob" "gold_placeholder" {
  name                   = "gold/.keep"
  storage_account_name   = azurerm_storage_account.adls.name
  storage_container_name = azurerm_storage_container.finsight.name
  type                   = "Block"
  source_content         = ""
}

# ── Azure Key Vault ───────────────────────────
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "finsight" {
  name                        = "${var.prefix}-kv"
  location                    = azurerm_resource_group.finsight.location
  resource_group_name         = azurerm_resource_group.finsight.name
  enabled_for_disk_encryption = false
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    secret_permissions = ["Get", "List", "Set", "Delete", "Purge"]
  }

  tags = local.common_tags
}

# Store all API keys as Key Vault secrets
resource "azurerm_key_vault_secret" "polygon_key" {
  name         = "polygon-api-key"
  value        = var.polygon_api_key
  key_vault_id = azurerm_key_vault.finsight.id
}

resource "azurerm_key_vault_secret" "newsapi_key" {
  name         = "newsapi-api-key"
  value        = var.newsapi_api_key
  key_vault_id = azurerm_key_vault.finsight.id
}

resource "azurerm_key_vault_secret" "openai_key" {
  name         = "openai-api-key"
  value        = var.openai_api_key
  key_vault_id = azurerm_key_vault.finsight.id
}

# ── Databricks Workspace ──────────────────────
resource "azurerm_databricks_workspace" "finsight" {
  name                        = "${var.prefix}-databricks"
  resource_group_name         = azurerm_resource_group.finsight.name
  location                    = azurerm_resource_group.finsight.location
  sku                         = "premium"   # Premium required for Unity Catalog + Mosaic AI
  managed_resource_group_name = "${var.prefix}-databricks-managed"
  tags                        = local.common_tags
}

# ── Azure Data Factory ────────────────────────
resource "azurerm_data_factory" "finsight" {
  name                = "${var.prefix}-adf"
  location            = azurerm_resource_group.finsight.location
  resource_group_name = azurerm_resource_group.finsight.name

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

# Grant ADF identity access to ADLS
resource "azurerm_role_assignment" "adf_adls" {
  scope                = azurerm_storage_account.adls.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_data_factory.finsight.identity[0].principal_id
}

# ── Azure Container Registry (for FastAPI Docker) ─
resource "azurerm_container_registry" "finsight" {
  name                = "${var.prefix}acr"
  resource_group_name = azurerm_resource_group.finsight.name
  location            = azurerm_resource_group.finsight.location
  sku                 = "Basic"
  admin_enabled       = true
  tags                = local.common_tags
}

# ── Azure Container Apps (FastAPI hosting) ────
resource "azurerm_log_analytics_workspace" "finsight" {
  name                = "${var.prefix}-logs"
  location            = azurerm_resource_group.finsight.location
  resource_group_name = azurerm_resource_group.finsight.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.common_tags
}

resource "azurerm_container_app_environment" "finsight" {
  name                       = "${var.prefix}-container-env"
  location                   = azurerm_resource_group.finsight.location
  resource_group_name        = azurerm_resource_group.finsight.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.finsight.id
  tags                       = local.common_tags
}

locals {
  common_tags = {
    project     = "finsight-ai"
    environment = var.environment
    owner       = "vennila-senthilkumar"
    managed_by  = "terraform"
  }
}
