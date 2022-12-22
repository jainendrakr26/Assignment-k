# Create a resource group
resource "azurerm_resource_group" "appgrp" {
  name     = "app-grp"
  location = "North Europe"
}

# Create a virtual network
resource "azurerm_virtual_network" "appvnet" {
  name                = "app-vnet"
  resource_group_name = azurerm_resource_group.appgrp.name
  location            = azurerm_resource_group.appgrp.location
  address_space       = ["10.0.0.0/16"]
  depends_on = [
    azurerm_resource_group.appgrp
  ]
}

# Create a subnet
resource "azurerm_subnet" "appsubnet" {
  name                 = "app-subnet"
  resource_group_name  = azurerm_resource_group.appgrp.name
  virtual_network_name = azurerm_virtual_network.appvnet.name
  address_prefixes     = ["10.0.1.0/24"]
  depends_on = [
    azurerm_virtual_network.appvnet
  ]
}

resource "azurerm_subnet" "websubnet" {
  name                 = "web-subnet"
  resource_group_name  = azurerm_resource_group.appgrp.name
  virtual_network_name = azurerm_virtual_network.appvnet.name
  address_prefixes     = ["10.0.2.0/24"]
  depends_on = [
    azurerm_virtual_network.appvnet
  ]
}

# Create a public IP address
resource "azurerm_public_ip" "apppip" {
  name                = "app-public-ip"
  resource_group_name = azurerm_resource_group.appgrp.name
  location            = azurerm_resource_group.appgrp.location
  allocation_method   = "Static"
  depends_on = [
    azurerm_resource_group.appgrp
  ]
}

# Create a network security group
resource "azurerm_network_security_group" "appnsg" {
  name                = "app-nsg"
  resource_group_name = azurerm_resource_group.appgrp.name
  location            = azurerm_resource_group.appgrp.location

  security_rule {
    name                       = "AllowRDP"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  depends_on = [
    azurerm_resource_group.appgrp
  ]
}

resource "azurerm_network_security_group" "webnsg" {
  name                = "web-nsg"
  resource_group_name = azurerm_resource_group.appgrp.name
  location            = azurerm_resource_group.appgrp.location

  security_rule {
    name                       = "AllowRDP"
    priority                   = 310
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  depends_on = [
    azurerm_resource_group.appgrp
  ]
}

#create a n/w interface for application
resource "azurerm_network_interface" "appnic" {
  name                = "app-nic"
  resource_group_name = azurerm_resource_group.appgrp.name
  location            = azurerm_resource_group.appgrp.location
  # network_security_group_id = azurerm_network_security_group.appnsg.id
  ip_configuration {
    name                          = "app-ip-config"
    subnet_id                     = azurerm_subnet.appsubnet.id
    private_ip_address_allocation = "Dynamic"
    #public_ip_address_id          = azurerm_public_ip.apppip.id
  }
  depends_on = [
    azurerm_subnet.appsubnet
  ]
}

resource "azurerm_network_interface" "webnic" {
  name                = "web-nic"
  resource_group_name = azurerm_resource_group.appgrp.name
  location            = azurerm_resource_group.appgrp.location
  # network_security_group_id = azurerm_network_security_group.appnsg.id
  ip_configuration {
    name                          = "web-ip-config"
    subnet_id                     = azurerm_subnet.websubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.apppip.id
  }
  depends_on = [
    azurerm_subnet.appsubnet
  ]
}

# Create a virtual machine for the application server
resource "azurerm_linux_virtual_machine" "appvm1" {
  name                            = "app-vm"
  resource_group_name             = azurerm_resource_group.appgrp.name
  location                        = azurerm_resource_group.appgrp.location
  size                            = "Standard_D2_v2"
  admin_username                  = "adminuser"
  admin_password = "Password@123"
  network_interface_ids           = [azurerm_network_interface.appnic.id]
  disable_password_authentication = false

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  os_disk {
    name                 = "myosdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

resource "azurerm_linux_virtual_machine" "webvm1" {
  name                            = "web-vm"
  resource_group_name             = azurerm_resource_group.appgrp.name
  location                        = azurerm_resource_group.appgrp.location
  size                            = "Standard_D2_v2"
  admin_username                  = "adminuser"
  admin_password = "Password@123"
  network_interface_ids           = [azurerm_network_interface.webnic.id]
  disable_password_authentication = false

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  os_disk {
    name                 = "myosdisk01"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

#storage-account
resource "azurerm_storage_account" "appsa" {
  name                     = "appsa213445566666"
  resource_group_name      = azurerm_resource_group.appgrp.name
  location                 = azurerm_resource_group.appgrp.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  depends_on = [
    azurerm_resource_group.appgrp
  ]
}

#create a ms-sql server
resource "azurerm_mssql_server" "appmssql" {
  name                         = "app-mssqlserver"
  resource_group_name          = azurerm_resource_group.appgrp.name
  location                     = azurerm_resource_group.appgrp.location
  version                      = "12.0"
  administrator_login          = "missadministrator"
  administrator_login_password = "thisIsKat11"
  minimum_tls_version          = "1.2"

  azuread_administrator {
    login_username = "AzureAD Admin"
    object_id      = "3df6a632-e0ce-44bf-8f10-a82f00fb5844"
  }
  depends_on = [
    azurerm_resource_group.appgrp
  ]
}

resource "azurerm_sql_database" "db" {
  name                = "db01"
  resource_group_name = azurerm_resource_group.appgrp.name
  location            = azurerm_resource_group.appgrp.location
  server_name         = azurerm_mssql_server.appmssql.name
}