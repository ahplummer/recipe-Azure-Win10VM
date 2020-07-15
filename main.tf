//#The main shebang. Note - if trivial amount of infra, just KISS, and put it all in here.
//#Modules can come along later. That just adds unnecessary complexity at this juncture.
//
resource "azurerm_resource_group" "workstation_rg" {
  name = var.WORKSTATION_RG
  location = var.LOCATION
}

resource "azurerm_virtual_network" "workstation_vnet" {
  name = "${var.resource_prefix}-vnet"
  location = azurerm_resource_group.workstation_rg.location
  resource_group_name = azurerm_resource_group.workstation_rg.name
  address_space = [var.workstation_address_space]
}

resource "azurerm_subnet" "workstation_subnet" {
  name = "${var.resource_prefix}-subnet"
  resource_group_name = azurerm_resource_group.workstation_rg.name
  virtual_network_name = azurerm_virtual_network.workstation_vnet.name
  address_prefix = var.workstation_address_prefix
}

resource "azurerm_network_interface" "workstation_nic" {
  name = "${var.WORKSTATION_NAME}-nic"
  location = azurerm_resource_group.workstation_rg.location
  resource_group_name = azurerm_resource_group.workstation_rg.name
  ip_configuration {
    name = "${var.WORKSTATION_NAME}-ip"
    subnet_id = azurerm_subnet.workstation_subnet.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id  = azurerm_public_ip.workstation_public_ip.id
  }
}

resource "azurerm_public_ip" "workstation_public_ip" {
  name = "${var.resource_prefix}-public-ip"
  location = azurerm_resource_group.workstation_rg.location
  resource_group_name = azurerm_resource_group.workstation_rg.name
  allocation_method = "Dynamic" #var.environment == "production" ? "Static" : "Dynamic" #needs uppercase
}

resource "azurerm_network_security_group" "workstation_nsg" {
  name = "${var.resource_prefix}-nsg"
  location = azurerm_resource_group.workstation_rg.location
  resource_group_name = azurerm_resource_group.workstation_rg.name
}

resource "azurerm_network_security_rule" "workstation_nsg_rule_rdp" {
  name = "RDP Inbound"
  priority = 100
  direction = "Inbound"
  access = "Allow"
  protocol = "Tcp"
  source_port_range = "*"
  destination_port_range = "3389"
  source_address_prefix = "*"
  destination_address_prefix = "*"
  resource_group_name = azurerm_resource_group.workstation_rg.name
  network_security_group_name = azurerm_network_security_group.workstation_nsg.name
}

resource "azurerm_network_interface_security_group_association" "workstation_nsg_association" {
  network_security_group_id = azurerm_network_security_group.workstation_nsg.id
  network_interface_id = azurerm_network_interface.workstation_nic.id
}

resource "azurerm_windows_virtual_machine" "workstation" {
  name  = var.WORKSTATION_NAME
  location = azurerm_resource_group.workstation_rg.location
  resource_group_name = azurerm_resource_group.workstation_rg.name
  network_interface_ids = [azurerm_network_interface.workstation_nic.id]
  size = "Standard_B2s"
  admin_username = var.USERNAME
  admin_password = var.PASSWORD
  timezone = var.TIMEZONE
  os_disk{
    caching = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_id = "/subscriptions/${var.SUBSCRIPTION_ID}/resourceGroups/${var.PACKER_RG}/providers/Microsoft.Compute/images/${var.PACKERNAME}"
}