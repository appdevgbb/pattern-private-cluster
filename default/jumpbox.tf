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
    sku       = "win11-23h2-pro"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  # Enable boot diagnostics
  boot_diagnostics {
  }
}

# Install Azure CLI and kubectl via Custom Script Extension
resource "azurerm_virtual_machine_extension" "jumpbox_tools" {
  name                 = "InstallTools"
  virtual_machine_id   = azurerm_windows_virtual_machine.jumpbox.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = jsonencode({
    commandToExecute = <<-EOT
      powershell -ExecutionPolicy Unrestricted -Command "
        # Install Chocolatey
        Set-ExecutionPolicy Bypass -Scope Process -Force;
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'));
        
        # Install Azure CLI
        choco install azure-cli -y;
        
        # Install kubectl
        choco install kubernetes-cli -y;
        
        # Install VS Code
        choco install vscode -y;
        
        # Enable WSL2
        dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart;
        dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart;
        
        # Download and install WSL2 kernel update
        Invoke-WebRequest -Uri https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi -OutFile wsl_update_x64.msi;
        Start-Process msiexec.exe -Wait -ArgumentList '/i wsl_update_x64.msi /quiet';
        Remove-Item wsl_update_x64.msi;
        
        # Set WSL2 as default
        wsl --set-default-version 2;
        
        # Install Ubuntu (will complete after reboot)
        wsl --install -d Ubuntu-22.04 --no-launch;
        
        # Refresh environment variables
        refreshenv;
        
        # Note: VM needs to be restarted for WSL2 to be fully functional
      "
    EOT
  })

  tags = var.tags
}
