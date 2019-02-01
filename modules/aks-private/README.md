# AKS Private
This terraform module creates a Kubernetes CLuster using Azure Kuberetes Service that offers Kubernetes managed

## References
https://www.terraform.io/docs/providers/azurerm/auth/service_principal_client_secret.html#creating-a-service-principal-in-the-azure-portal

https://github.com/kubernetes/kubernetes/issues/58759

https://docs.microsoft.com/en-us/azure/aks/aad-integration

https://github.com/jcorioland/aks-rbac-azure-ad

## Notes
- Most resources are named with `${module.name}-${module.env}

## Usage
main.tf
```hcl

terraform {
  backend "azurerm" {
    storage_account_name = "abcd1234"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}

module "staging-cluster" {
    source = "../path/to/this/folder"
    name = "sighup"
    env = "staging"


}
```

## Authentication
.env
```
export ARM_CLIENT_ID=00000000-0000-0000-0000-000000000000
export ARM_CLIENT_SECRET="00000000-0000-0000-0000-000000000000"
export ARM_SUBSCRIPTION_ID=00000000-0000-0000-0000-000000000000
export ARM_TENANT_ID=00000000-0000-0000-0000-000000000000
```
