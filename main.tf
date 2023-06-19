## declare provider
provider "azurerm" {
  features {}
}

## declare resource group
resource "azurerm_resource_group" "resgroup" {
  name     = "coursework-resource"
  location = "West Europe"
}

resource "azurerm_availability_set" "coursework" {
  name                = "coursework"
  location            = azurerm_resource_group.resgroup.location
  resource_group_name = azurerm_resource_group.resgroup.name
}

## declare virtual network
resource "azurerm_virtual_network" "virtualnet" {
  name                = "virtualNetwork"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.resgroup.location
  resource_group_name = azurerm_resource_group.resgroup.name
}


## declare subnetwork
resource "azurerm_subnet" "subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.resgroup.name
  virtual_network_name = azurerm_virtual_network.virtualnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

## declare ipv4 address
resource "azurerm_public_ip" "ipaddress" {
  name                = "publicIp"
  resource_group_name = azurerm_resource_group.resgroup.name
  location            = azurerm_resource_group.resgroup.location
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
}

## declare network interface
resource "azurerm_network_interface" "networkinterface" {
  name                = "networkInterface"
  location            = azurerm_resource_group.resgroup.location
  resource_group_name = azurerm_resource_group.resgroup.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.ipaddress.id
  }
}

## declare virtual machine
resource "azurerm_linux_virtual_machine" "coursework" {
  name                = "coursework-machine"
  resource_group_name = azurerm_resource_group.resgroup.name
  location            = azurerm_resource_group.resgroup.location
  size                = "Standard_F2"
  admin_username      = "olehvol"
  admin_password      = "09.04.2001"
  disable_password_authentication = false
  availability_set_id = azurerm_availability_set.coursework.id
  network_interface_ids = [
    azurerm_network_interface.networkinterface.id
  ]


  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  } 
}

## output public ip address of vm
output "public_ip_address" {
  value = "${resource.azurerm_public_ip.ipaddress.*.ip_address}"
}
