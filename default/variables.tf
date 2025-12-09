variable "subscription_id" {
  description = "The Azure subscription ID to deploy resources to."
  type        = string
}

variable "location" {
  description = "The Azure region to deploy resources to."
  type        = string
}

variable "cluster_name" {
  description = "The name of the AKS cluster."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group."
  type        = string
}

variable "kubernetes_version" {
  description = "The Kubernetes version for the AKS cluster. Check https://learn.microsoft.com/azure/aks/supported-kubernetes-versions for supported versions."
  type        = string
}

variable "storage_account_name" {
  description = "Base name for the Cloud Shell storage account. A unique suffix will be appended automatically."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,18}$", var.storage_account_name))
    error_message = "Storage account base name must be 3-18 lowercase alphanumeric characters (suffix will be added)."
  }
}

variable "relay_namespace_name" {
  description = "Base name for the Azure Relay namespace for Cloud Shell. A unique suffix will be appended automatically."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{6,44}$", var.relay_namespace_name))
    error_message = "Relay namespace base name must be 6-44 alphanumeric characters or hyphens (suffix will be added)."
  }
}

variable "acr_name" {
  description = "Base name for the Azure Container Registry. A unique suffix will be appended automatically."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9]{5,44}$", var.acr_name))
    error_message = "ACR base name must be 5-44 alphanumeric characters (suffix will be added)."
  }
}

variable "aks_admin_group_object_ids" {
  description = "List of Azure AD group object IDs that will have admin access to the AKS cluster."
  type        = list(string)
  default     = []
}

variable "default_node_vm_size" {
  description = "The VM size for the default node pool."
  type        = string
  default     = "Standard_DS2_v2"
}

variable "default_node_count" {
  description = "The number of nodes in the default node pool."
  type        = number
  default     = 1

  validation {
    condition     = var.default_node_count >= 1 && var.default_node_count <= 100
    error_message = "Node count must be between 1 and 100."
  }
}

variable "aks_sku_tier" {
  description = "The SKU tier for AKS. Use 'Free' for dev/test or 'Standard' for production with Uptime SLA."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Free", "Standard", "Premium"], var.aks_sku_tier)
    error_message = "SKU tier must be 'Free', 'Standard', or 'Premium'."
  }
}

variable "vnet_address_space" {
  description = "The address space for the virtual network (e.g., '10.1.0.0/16')."
  type        = string
  default     = "10.1.0.0/16"

  validation {
    condition     = can(cidrhost(var.vnet_address_space, 0))
    error_message = "Must be a valid CIDR block."
  }
}

variable "pod_cidr" {
  description = "The CIDR block for pod IP addresses (Azure CNI Overlay)."
  type        = string
  default     = "10.244.0.0/16"

  validation {
    condition     = can(cidrhost(var.pod_cidr, 0))
    error_message = "Must be a valid CIDR block."
  }
}

variable "service_cidr" {
  description = "The CIDR block for Kubernetes service IPs."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.service_cidr, 0))
    error_message = "Must be a valid CIDR block."
  }
}

variable "dns_service_ip" {
  description = "The IP address for the Kubernetes DNS service (must be within service_cidr)."
  type        = string
  default     = "10.0.0.10"

  validation {
    condition     = can(regex("^(\\d{1,3}\\.){3}\\d{1,3}$", var.dns_service_ip))
    error_message = "Must be a valid IP address."
  }
}

variable "log_analytics_retention_days" {
  description = "The number of days to retain logs in the Log Analytics workspace."
  type        = number
  default     = 30

  validation {
    condition     = var.log_analytics_retention_days >= 30 && var.log_analytics_retention_days <= 730
    error_message = "Retention days must be between 30 and 730."
  }
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "name_suffix" {
  description = "Suffix for globally unique resource names (ACR, Storage, Relay). Leave empty to auto-generate from subscription ID."
  type        = string
  default     = ""

  validation {
    condition     = var.name_suffix == "" || can(regex("^[a-z0-9]{1,10}$", var.name_suffix))
    error_message = "Name suffix must be 1-10 lowercase alphanumeric characters."
  }
}
