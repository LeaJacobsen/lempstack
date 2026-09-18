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

resource "azurerm_network_security_group" "lamp" {
  name                = "lamp-nsg"
  location            = azurerm_resource_group.lamp.location
  resource_group_name = azurerm_resource_group.lamp.name

  security_rule {
    name                       = "Allow-HTTP-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH-AdminOnly"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "185.73.72.112/32"
    destination_address_prefix = "*"
  }
}
