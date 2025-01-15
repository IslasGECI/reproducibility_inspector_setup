resource "azurerm_resource_group" "inspector" {
  name     = "inspector-resources"
  location = "West US 2"
}

resource "azurerm_virtual_network" "inspector" {
  name                = "inspector-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.inspector.location
  resource_group_name = azurerm_resource_group.inspector.name
}

resource "azurerm_subnet" "inspector" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.inspector.name
  virtual_network_name = azurerm_virtual_network.inspector.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "inspector" {
  name                = "inspector-public-ip"
  location            = azurerm_resource_group.inspector.location
  resource_group_name = azurerm_resource_group.inspector.name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "inspector" {
  name                = "inspector-nic"
  location            = azurerm_resource_group.inspector.location
  resource_group_name = azurerm_resource_group.inspector.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.inspector.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.inspector.id
  }
}

resource "azurerm_linux_virtual_machine" "inspector" {
  name                = "inspector"
  resource_group_name = azurerm_resource_group.inspector.name
  location            = azurerm_resource_group.inspector.location
  size                = "Standard_D2as_v4"
  admin_username      = "ciencia_datos"
  network_interface_ids = [
    azurerm_network_interface.inspector.id,
  ]

  admin_ssh_key {
    username   = "ciencia_datos"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 128
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

data "azurerm_public_ip" "inspector" {
  name                = azurerm_public_ip.inspector.name
  resource_group_name = azurerm_linux_virtual_machine.inspector.resource_group_name
}

output "inspector_ip" {
  value = data.azurerm_public_ip.inspector.ip_address
}
