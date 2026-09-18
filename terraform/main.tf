terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "lamp" {
  name     = "lamp-rg"
  location = "swedencentral"
}

resource "azurerm_virtual_network" "lamp" {
  name                = "lamp-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.lamp.location
  resource_group_name = azurerm_resource_group.lamp.name
}

resource "azurerm_subnet" "lamp" {
  name                 = "lamp-subnet"
  resource_group_name  = azurerm_resource_group.lamp.name
  virtual_network_name = azurerm_virtual_network.lamp.name
  address_prefixes     = ["10.0.1.0/24"]
}
