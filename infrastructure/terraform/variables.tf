# infrastructure/terraform/variables.tf

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
  default     = "finsight-rg"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

variable "prefix" {
  description = "Short prefix for all resource names"
  type        = string
  default     = "finsight"
}

variable "adls_account_name" {
  description = "ADLS Gen2 storage account name (globally unique, lowercase, 3-24 chars)"
  type        = string
  default     = "finsightadls"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Must be dev, staging, or prod."
  }
}

# Secrets — never hardcode, pass via -var or tfvars file
variable "polygon_api_key" {
  description = "Polygon.io API key"
  type        = string
  sensitive   = true
}

variable "newsapi_api_key" {
  description = "NewsAPI key"
  type        = string
  sensitive   = true
}

variable "openai_api_key" {
  description = "OpenAI API key"
  type        = string
  sensitive   = true
}
