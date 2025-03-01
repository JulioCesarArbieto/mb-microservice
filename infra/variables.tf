variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "client_id" {
  description = "Azure Client ID"
  type        = string
}

variable "client_secret" {
  description = "Azure Client Secret"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
}

variable "resource_group_name" {
  description = "Nombre del grupo de recursos"
  type        = string
  default     = "mibanco-rg"
}

variable "location" {
  description = "Ubicación de los recursos en Azure"
  type        = string
  default     = "East US"
}

variable "aks_node_count" {
  description = "Cantidad de nodos en AKS"
  type        = number
  default     = 1
}

variable "aks_vm_size" {
  description = "Tamaño de la VM en AKS"
  type        = string
  default     = "Standard_DS2_v2"
}