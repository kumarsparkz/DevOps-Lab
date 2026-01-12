packer {
  required_plugins {
    vmware = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/vmware"
    }
  }
}

variable "winrm_password" {
  description = "WinRM password for Windows admin"
  type        = string
  sensitive   = true
  default     = ""  # Set via PKR_VAR_winrm_password environment variable
}

variable "iso_checksum" {
  description = "SHA256 checksum of the Windows Server ISO"
  type        = string
  # Get checksum: certutil -hashfile windows_server_2022.iso SHA256
  default     = "sha256:3e4fa6d8507b554856fc9ca6079cc402df11a8b79344871669f0251535255325"
}

source "vmware-iso" "win2022" {
  # --- ISO and OS Configuration ---
  iso_url          = "./iso/windows_server_2022.iso"
  iso_checksum     = var.iso_checksum
  vm_name          = "Win2022-Gold"
  guest_os_type    = "windows2019srv-64" # Standard for WS2022

  # --- EFI & Boot Fixes ---
  headless          = false
  firmware          = "efi"
  boot_wait         = "2s"
  boot_key_interval = "100ms"
  # Navigate EFI Boot Manager: Down to CDROM, Enter to select, then spacebar for "Press any key"
  boot_command      = [
    "<spacebar>",              # Open boot menu
    "<wait1s>",
    "<down><down>",            # Navigate to SATA CDROM Drive
    "<enter>",                 # Select it
    "<wait3s>",                # Wait for "Press any key to boot from CD"
    "<spacebar><spacebar><spacebar>"  # Press key to boot from CD
  ]

  # --- Performance Tuning ---
  memory           = 16384
  cpus             = 4
  disk_size        = 61440
  disk_adapter_type = "nvme"

  # --- Communication ---
  communicator     = "winrm"
  winrm_username   = "Administrator"
  winrm_password   = var.winrm_password
  winrm_timeout    = "60m"              # Wait up to 60 min for Windows install

  # --- Shutdown ---
  shutdown_command = "shutdown /s /t 10 /f /d p:4:1 /c \"Packer Shutdown\""
  shutdown_timeout = "15m"

  # --- Automated Setup Files (use CD for EFI boot) ---
  cd_files         = ["./scripts/Autounattend.xml"]
  cd_label         = "OEMDRV"
}

build {
  sources = ["source.vmware-iso.win2022"]
  
  provisioner "powershell" {
    scripts = [
      "./scripts/install-tools.ps1",
      "./scripts/setup.ps1"
    ]
  }
}