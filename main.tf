resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}

resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = random_pet.rg_name.id
  tags = {
    needed-until-date = "01/01/2024"
    JIRA              = "NA"
    tag-std           = "v1.0"
    appid-or-sso      = "tiag5267"
  }
}

# Create virtual network #1
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet1"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create subnet
resource "azurerm_subnet" "subnet1" {
  name                 = "subnet1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create subnet for Firewall
resource "azurerm_subnet" "subnet2" {
    name                 = "AzureFirewallSubnet"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = ["10.0.2.0/24"]

}

# Create virtual network #2
resource "azurerm_virtual_network" "vnet2" {
  name                = "vnet2"
  address_space       = ["192.168.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create subnet
resource "azurerm_subnet" "subnet3" {
  name                 = "subnet3"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet2.name
  address_prefixes     = ["192.168.1.0/24"]
}

# Create virtual network #3
resource "azurerm_virtual_network" "vnet3" {
  name                = "vnet3"
  address_space       = ["172.16.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create subnet
resource "azurerm_subnet" "subnet4" {
  name                 = "subnet4"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet3.name
  address_prefixes     = ["172.16.1.0/24"]
}

# Create public IPs #1
resource "azurerm_public_ip" "pip1" {
  name                = "vmpip1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rule #1
resource "azurerm_network_security_group" "nsg1" {
  name                = "vm1nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface #1
resource "azurerm_network_interface" "nic1" {
  name                = "vmnic1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "vmnicconfiguration"
    subnet_id                     = azurerm_subnet.subnet3.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip1.id
  }
}

# Connect the security group to the network interface #1
resource "azurerm_network_interface_security_group_association" "nsgnic1" {
  network_interface_id      = azurerm_network_interface.nic1.id
  network_security_group_id = azurerm_network_security_group.nsg1.id
}

# Create public IPs #2
resource "azurerm_public_ip" "pip2" {
  name                = "vmpip2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rule #2
resource "azurerm_network_security_group" "nsg2" {
  name                = "vm2nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface #2
resource "azurerm_network_interface" "nic2" {
  name                = "vmnic2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "vm2nicconfiguration"
    subnet_id                     = azurerm_subnet.subnet4.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip2.id
  }
}

# Connect the security group to the network interface #1
resource "azurerm_network_interface_security_group_association" "nsgnic2" {
  network_interface_id      = azurerm_network_interface.nic2.id
  network_security_group_id = azurerm_network_security_group.nsg2.id
}

# Generate random text for a unique storage account name
resource "random_id" "random_id" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rg.name
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "my_storage_account" {
  name                     = "diag${random_id.random_id.hex}"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create (and display) an SSH key #1
resource "tls_private_key" "vm_ssh1" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create virtual machine #1
resource "azurerm_linux_virtual_machine" "vm1" {
  name                  = "vm1"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic1.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "myOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = "vm1"
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.vm_ssh1.public_key_openssh
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.my_storage_account.primary_blob_endpoint
  }
}

# Create (and display) an SSH key #2
resource "tls_private_key" "vm_ssh2" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create virtual machine #2
resource "azurerm_linux_virtual_machine" "vm2" {
  name                  = "vm2"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic2.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "myOsDisk2"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = "vm2"
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.vm_ssh2.public_key_openssh
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.my_storage_account.primary_blob_endpoint
  }
}


#resource "azurerm_subnet" "example" {
  #name                 = "AzureFirewallSubnet"
  #resource_group_name  = azurerm_resource_group.rg.name
  #virtual_network_name = azurerm_virtual_network.vnet.name
 # address_prefixes     = ["10.0.1.0/24"]
#}

resource "azurerm_public_ip" "pip3" {
  name                = "testpip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "azfw" {
  name                = "testfirewall"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.subnet2.id
    public_ip_address_id = azurerm_public_ip.pip3.id
  }
}

#End, for now