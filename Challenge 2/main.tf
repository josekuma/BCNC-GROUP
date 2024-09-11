provider "azurerm" {
  features {}
}

provider "helm" {
  # Assumes the Helm provider is configured by the caller
}

# Variables for Source and Destination Registries
variable "source_acr" {
  default = "reference.azurecr.io"
}

variable "destination_acr" {
  default = "instance.azurecr.io"
}

variable "subscription_id" {
  default = "c9e7611c-d508-4-f-aede-0bedfabc1560"
}

variable "chart_name" {
  description = "The name of the Helm chart to copy"
}

variable "chart_version" {
  description = "The version of the Helm chart to copy"
  default     = "latest"  # Optional: set to a specific version if needed
}

# Azure Container Registry for destination (instance)
resource "azurerm_container_registry" "instance_acr" {
  name                = "instanceacr"
  resource_group_name = "your-resource-group"   # replace with your resource group
  location            = "West Europe"
  sku                 = "Basic"
  admin_enabled       = true

  lifecycle {
    ignore_changes = [admin_enabled]
  }
}

# Use `null_resource` to perform Helm chart import and copy operations using `az acr` commands
resource "null_resource" "copy_helm_chart" {
  provisioner "local-exec" {
    command = <<EOT
      # Login to the source ACR
      az acr login --name ${var.source_acr}

      # Pull the chart from the source registry
      helm pull oci://${var.source_acr}/helm/${var.chart_name} --version ${var.chart_version}

      # Push the chart to the destination registry
      az acr login --name ${var.destination_acr}
      helm push ${var.chart_name}-${var.chart_version}.tgz oci://${var.destination_acr}/helm
    EOT
  }

  triggers = {
    always_run = "${timestamp()}"  # Ensures this resource runs every time Terraform is applied
  }
}

# Output the ACR login URL and other useful information
output "source_acr_login" {
  value = "az acr login --name ${var.source_acr}"
}

output "destination_acr_login" {
  value = "az acr login --name ${var.destination_acr}"
}

output "helm_chart_copy_command" {
  value = "Helm chart ${var.chart_name} version ${var.chart_version} has been copied from ${var.source_acr} to ${var.destination_acr}"
}
