resource "random_pet" "rg-name" {
  prefix = var.resource_group_name_prefix
}

#To create resource group
resource "azurerm_resource_group" "rg" {
  name     = random_pet.rg-name.id
  location = var.resource_group_location
}

#create key1 for VM1
resource "tls_private_key" "ubuntu_key1" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

#create key2 for VM2
resource "tls_private_key" "ubuntu_key2" {
  algorithm = "RSA"
  rsa_bits  = 4094
}

#storing the created key1 in file ubuntukey1
resource "local_file" "ubuntukey1" {
  filename = "ubuntukey1.pem"
  content  = tls_private_key.ubuntu_key1.private_key_pem
}

#storing the created key1 in file ubuntukey1
resource "local_file" "ubuntukey2" {
  filename = "ubuntukey2.pem"
  content  = tls_private_key.ubuntu_key2.private_key_pem
}

# Create virtual network
resource "azurerm_virtual_network" "myterraformnetwork" {
  name                = "myVnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create subnet1
resource "azurerm_subnet" "myterraformsubnet1" {
  name                 = "mySubnet1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.myterraformnetwork.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create subnet2 
resource "azurerm_subnet" "myterraformsubnet2" {
  name                 = "mySubnet2"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.myterraformnetwork.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "myterraformpublicip1" {
  name                = "myPublicIP1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Create public IPs
resource "azurerm_public_ip" "myterraformpublicip2" {
  name                = "myPublicIP2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "nI1" {
  name                = "ni-nic1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal1"
    subnet_id                     = azurerm_subnet.myterraformsubnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.myterraformpublicip1.id
  }
}
resource "azurerm_network_interface" "nI2" {
  name                = "ni-nic2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal2"
    subnet_id                     = azurerm_subnet.myterraformsubnet2.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.myterraformpublicip2.id
  }
}

#create virtual machine
resource "azurerm_linux_virtual_machine" "virtual_machine_1" {
  name                = "VM1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_F2"
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.nI1.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.ubuntu_key1.public_key_openssh
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  os_disk {
    name    = "myosdisk1"
    caching = "ReadWrite"
    #create_option     = "FromImage"
    storage_account_type = "Standard_LRS"
  }

}

resource "azurerm_linux_virtual_machine" "virtual_machine_2" {
  name                = "VM2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.nI2.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = tls_private_key.ubuntu_key2.public_key_openssh
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  os_disk {
    name    = "myosdisk2"
    caching = "ReadWrite"
    #create_option     = "FromImage"
    storage_account_type = "Standard_LRS"
  }
}
# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg2" {
  name                = "myNetworkSecurityGroup2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  
    security_rule {
    name                       = "ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
   security_rule {
    name                       = "http"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "10.0.2.0/24"
  }


}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "connection" {
  network_interface_id      = azurerm_network_interface.nI2.id
  network_security_group_id = azurerm_network_security_group.myterraformnsg2.id
}
