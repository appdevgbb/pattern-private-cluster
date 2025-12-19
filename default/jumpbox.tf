########################################
# Windows 11 Jumpbox
########################################

# Network Interface for Windows Jumpbox
resource "azurerm_network_interface" "jumpbox" {
  name                = "nic-jumpbox-${var.cluster_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.jumpservers.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Windows 11 Virtual Machine
resource "azurerm_windows_virtual_machine" "jumpbox" {
  name                = "vm-jumpbox-${var.cluster_name}"
  computer_name       = "jumpbox"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_D2s_v3"
  admin_username      = "azureuser"
  admin_password      = var.jumpbox_admin_password
  tags                = var.tags

  network_interface_ids = [
    azurerm_network_interface.jumpbox.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-11"
    sku       = "win11-24h2-ent"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  # Enable boot diagnostics
  boot_diagnostics {
  }
}

# Install Chocolatey
resource "azurerm_virtual_machine_run_command" "install_chocolatey" {
  name               = "install-chocolatey"
  location           = azurerm_resource_group.rg.location
  virtual_machine_id = azurerm_windows_virtual_machine.jumpbox.id
  
  source {
    script = "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
  }
  
  tags = var.tags
}

# Install Azure CLI
resource "azurerm_virtual_machine_run_command" "install_azure_cli" {
  name               = "install-azure-cli"
  location           = azurerm_resource_group.rg.location
  virtual_machine_id = azurerm_windows_virtual_machine.jumpbox.id
  
  depends_on = [azurerm_virtual_machine_run_command.install_chocolatey]
  
  source {
    script = "Start-Sleep -Seconds 30; C:\\ProgramData\\chocolatey\\bin\\choco.exe install azure-cli -y"
  }
  
  tags = var.tags
}

# Install VS Code
resource "azurerm_virtual_machine_run_command" "install_vscode" {
  name               = "install-vscode"
  location           = azurerm_resource_group.rg.location
  virtual_machine_id = azurerm_windows_virtual_machine.jumpbox.id
  
  depends_on = [azurerm_virtual_machine_run_command.install_azure_cli]
  
  source {
    script = "C:\\ProgramData\\chocolatey\\bin\\choco.exe install vscode -y"
  }
  
  tags = var.tags
}

# Enable WSL2 features
resource "azurerm_virtual_machine_run_command" "enable_wsl2_features" {
  name               = "enable-wsl2-features"
  location           = azurerm_resource_group.rg.location
  virtual_machine_id = azurerm_windows_virtual_machine.jumpbox.id
  
  depends_on = [azurerm_virtual_machine_run_command.install_vscode]
  
  source {
    script = "dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart; dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart"
  }
  
  tags = var.tags
}

# Install WSL2 kernel update
resource "azurerm_virtual_machine_run_command" "install_wsl2_kernel" {
  name               = "install-wsl2-kernel"
  location           = azurerm_resource_group.rg.location
  virtual_machine_id = azurerm_windows_virtual_machine.jumpbox.id
  
  depends_on = [azurerm_virtual_machine_run_command.enable_wsl2_features]
  
  source {
    script = "Invoke-WebRequest -Uri https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi -OutFile C:\\Windows\\TEMP\\wsl_update_x64.msi; Start-Process msiexec.exe -Wait -ArgumentList '/i C:\\Windows\\TEMP\\wsl_update_x64.msi /quiet /norestart'; Remove-Item C:\\Windows\\TEMP\\wsl_update_x64.msi -ErrorAction SilentlyContinue"
  }
  
  tags = var.tags
}

# Configure WSL2 and install Ubuntu
resource "azurerm_virtual_machine_run_command" "configure_wsl2" {
  name               = "configure-wsl2"
  location           = azurerm_resource_group.rg.location
  virtual_machine_id = azurerm_windows_virtual_machine.jumpbox.id
  
  depends_on = [azurerm_virtual_machine_run_command.install_wsl2_kernel]
  
  source {
    script = "wsl --set-default-version 2; wsl --update; wsl --install -d Ubuntu-24.04 --no-launch"
  }
  
  tags = var.tags
}
