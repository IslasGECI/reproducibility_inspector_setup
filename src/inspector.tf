variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "West US 2"
}

variable "resource_group_name" {
  description = "Name of the Azure resource group."
  type        = string
  default     = "inspector-resources"
}

variable "vm_size" {
  description = "Azure Virtual Machine size."
  type        = string
  default     = "Standard_D2as_v4"
}

variable "admin_username" {
  description = "Administrator account for the VM."
  type        = string
  default     = "ciencia_datos"
}

variable "source_image_reference" {
  description = "Source image used to create the VM."
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })

  default = {
    publisher = "canonical"
    offer     = "ubuntu-26_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

resource "azurerm_resource_group" "inspector" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "inspector" {
  name                = "inspector-network"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "inspector" {
  name                 = "internal"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.inspector.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "inspector" {
  name                = "inspector-public-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "inspector" {
  name                = "inspector-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.inspector.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.inspector.id
  }
}

resource "azurerm_linux_virtual_machine" "inspector" {
  name                = "inspector"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.inspector.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 128
  }

  source_image_reference {
    publisher = var.source_image_reference.publisher
    offer     = var.source_image_reference.offer
    sku       = var.source_image_reference.sku
    version   = var.source_image_reference.version
  }
}

data "azurerm_public_ip" "inspector" {
  name                = azurerm_public_ip.inspector.name
  resource_group_name = azurerm_linux_virtual_machine.inspector.resource_group_name
}

output "inspector_ip" {
  value = data.azurerm_public_ip.inspector.ip_address
}
