variable "name" {
  description = "Cluster name"
}

variable "env" {
  description = "Cluster environment"
}

variable "kubernetes-version" {
  description = "Kubernetes version"
}

variable "infra-node-number" {
  description = "Number of nodes with label `beta.sighup.io/type: infra`"
}

variable "infra-node-type" {
  description = "Type of nodes with label `beta.sighup.io/type: infra`. See https://docs.microsoft.com/en-us/azure/virtual-machines/linux/sizes"
}

variable "app-node-number" {
  description = "Number of nodes without label `beta.sighup.io/type: infra`"
}

variable "app-node-type" {
  description = "Number of nodes without label `beta.sighup.io/type: infra`. See https://docs.microsoft.com/en-us/azure/virtual-machines/linux/sizes"
}

variable "ad-client-app-id" {
  description = "Application ID used to integrate `kubectl` with Azure AD. See  https://docs.microsoft.com/en-us/azure/aks/aad-integration"
}

variable "ad-server-app-id" {
  description = "Application ID used to get users and groups membership from Azure AD. See https://docs.microsoft.com/en-us/azure/aks/aad-integration"
}

variable "ad-server-app-secret" {
  description = "Application secret to get users and groups membership from Azure AD. See https://docs.microsoft.com/en-us/azure/aks/aad-integration"
}

variable "region" {
  description = "Azure region. See https://azure.microsoft.com/en-us/global-infrastructure/locations/"
}

variable "ssh_public_key" {
  description = "SSH public key to access bastion host and cluster nodes."
}

variable "vpc_cidr" {
  description = "Virtual network subnet, must be in RFC 1918 private address space."
}

variable "public_subnet_cidr" {
  description = "AKS cluster subnet, must be a subnet of `vpc_cidr`."
}

variable "bastion_subnet_cidr" {
  description = "Bastion host subnet, must be a subnet of `vpc_cidr`."
}

variable "public_subnet_endpoints" {
  default     = []
  description = "List of Service endpoints to associate with `public_subnet`. See https://www.terraform.io/docs/providers/azurerm/r/subnet.html#service_endpoints"
}

provider "azurerm" {}

provider "azuread" {}

resource "azurerm_resource_group" "main" {
  name     = "${var.name}-${var.env}"
  location = "${var.region}"
}
