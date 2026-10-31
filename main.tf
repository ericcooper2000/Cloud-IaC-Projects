terraform {
  # This block pulls from the terraform registry which providers and version information is needed.

  required_providers {
    aws =  {
      source = "hashicorp/aws"
      version = "4.16.0"
    }
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=3.8.0"
    }
    google = {
      source  =  "hashicorp/google"
      version = "4.23.0"
    }
  }
}

# Provider blocks to tell what regions, features, and credentials each cloud provider needs.

provider "aws" {
  region = "eu-west-1"
}

provider "azurerm" {
  features {}
}

provider "google" {
  region = "us-central1"
  project = "(project-id)"
  credentials = "(Credentials)"

}

# deploying a resource group in azure.

resource "azurerm_resource_group" "cloudwars" {
  name = "sec510-cloudwars"
  location = "eastasia"
}