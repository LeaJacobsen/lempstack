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

resource "azurerm_public_ip" "lamp" {
  name                = "lamp-public-ip"
  location            = azurerm_resource_group.lamp.location
  resource_group_name = azurerm_resource_group.lamp.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "lamp" {
  name                = "lamp-nic"
  location            = azurerm_resource_group.lamp.location
  resource_group_name = azurerm_resource_group.lamp.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.lamp.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.lamp.id
  }
}

resource "azurerm_network_interface_security_group_association" "lamp" {
  network_interface_id      = azurerm_network_interface.lamp.id
  network_security_group_id = azurerm_network_security_group.lamp.id
}

resource "azurerm_linux_virtual_machine" "lamp" {
  name                = "lamp-vm"
  resource_group_name = azurerm_resource_group.lamp.name
  location            = azurerm_resource_group.lamp.location
  size                = "Standard_D2as_v5"
  admin_username      = "lampadmin"


  network_interface_ids = [
    azurerm_network_interface.lamp.id,
  ]

  disable_password_authentication = true
  custom_data = base64encode(local.cloud_init)

  admin_ssh_key {
    username   = "lampadmin"
    public_key = file("/home/lea/.ssh/id_ed25519.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

   locals {
     cloud_init = templatefile("${path.module}/cloud-init.tftpl", {
       docker_compose_b64 = base64encode(file("${path.module}/../docker-compose.yml"))
       env_b64             = base64encode(file("${path.module}/../.env"))
       app_index_b64        = base64encode(file("${path.module}/../app/index.php"))
       nginx_conf_b64       = base64encode(file("${path.module}/../nginx/default.conf"))
       php_dockerfile_b64   = base64encode(file("${path.module}/../php/Dockerfile"))
       varnish_vcl_b64      = base64encode(file("${path.module}/../varnish/default.vcl"))
     })
   }

resource "azurerm_managed_disk" "media" {
  name                 = "lamp-media-disk"
  location             = azurerm_resource_group.lamp.location
  resource_group_name  = azurerm_resource_group.lamp.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 32
}

resource "azurerm_virtual_machine_data_disk_attachment" "media" {
  managed_disk_id    = azurerm_managed_disk.media.id
  virtual_machine_id = azurerm_linux_virtual_machine.lamp.id
  lun                = "10"
  caching            = "ReadWrite"
}

