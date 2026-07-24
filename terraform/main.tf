data "azurerm_resource_group" "rg" {
  name = "rg-fbarry-student"
}

# Creation of the App Service Plan
resource "azurerm_service_plan" "plan" {
  name                = "plan-fbarry-monitoring"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "B1"
}

# 3. Creation of the Linux Web App
resource "azurerm_linux_web_app" "app" {
  name                = "app-fbarry-monitoring-unique"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.plan.id

  site_config {
    application_stack {
      python_version = "3.11"
    }
  }

  # # Environment variable forcing Azure to automatically build the Flask app
  app_settings = {
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
  }
}

# 1. Workspace Prometheus Managed
resource "azurerm_monitor_workspace" "amw" {
  name                = "amw-fbarry-monitoring"
  resource_group_name = "rg-fbarry-student"
  location            = "westeurope"
}

# 2. Net for VM Prometheus
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-monitoring"
  address_space       = ["10.0.0.0/16"]
  location            = "westeurope"
  resource_group_name = "rg-fbarry-student"
}

resource "azurerm_subnet" "subnet_prom" {
  name                 = "subnet-prometheus"
  resource_group_name  = "rg-fbarry-student"
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "pip" {
  name                = "pip-prometheus"
  resource_group_name = "rg-fbarry-student"
  location            = "westeurope"
  allocation_method   = "Dynamic"
}

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-prometheus"
  resource_group_name = "rg-fbarry-student"
  location            = "westeurope"

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

  security_rule {
    name                       = "Prometheus"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9090"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "nic" {
  name                = "nic-prometheus"
  resource_group_name = "rg-fbarry-student"
  location            = "westeurope"

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet_prom.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# 3. VM Prometheus with automation instal
resource "azurerm_linux_virtual_machine" "prometheus_vm" {
  name                = "vm-prometheus-fbarry"
  resource_group_name = "rg-fbarry-student"
  location            = "westeurope"
  size                = "Standard_D2s_v3"
  admin_username      = "azureuser"

  identity {
    type = "SystemAssigned"
  }

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  network_interface_ids = [azurerm_network_interface.nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y wget
    useradd --no-create-home --shell /bin/false prometheus
    wget https://github.com/prometheus/prometheus/releases/download/v3.12.0/prometheus-3.12.0.linux-amd64.tar.gz
    tar xvf prometheus-3.12.0.linux-amd64.tar.gz
    cp prometheus-3.12.0.linux-amd64/prometheus /usr/local/bin/
    mkdir -p /etc/prometheus
  EOF
  )
}

# 4. Attribution RBAC
resource "azurerm_role_assignment" "prometheus_publisher" {
  scope                = azurerm_monitor_workspace.amw.default_data_collection_rule_id
  role_definition_name = "Monitoring Metrics Publisher"
  principal_id         = azurerm_linux_virtual_machine.prometheus_vm.identity[0].principal_id
}

resource "azurerm_role_assignment" "prometheus_dce_reader" {
  scope                = azurerm_monitor_workspace.amw.default_data_collection_endpoint_id
  role_definition_name = "Monitoring Reader"
  principal_id         = azurerm_linux_virtual_machine.prometheus_vm.identity[0].principal_id
}

resource "azurerm_role_assignment" "prometheus_dcr_reader" {
  scope                = azurerm_monitor_workspace.amw.default_data_collection_rule_id
  role_definition_name = "Monitoring Reader"
  principal_id         = azurerm_linux_virtual_machine.prometheus_vm.identity[0].principal_id
}