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
  # These lines prevent the "No Media" timeout you are seeing
  headless         = false               # Keep this false so you can see the boot happen
  firmware         = "efi"               # Better for NVMe stability
  boot_wait        = "5s"                # Increased wait to ensure VMware console is ready
  boot_command     = ["<spacebar><spacebar><spacebar>"] # Multiple hits to ensure capture
  
  # --- Performance Tuning for 96GB RAM Host ---
  memory           = 16384               
  cpus             = 4                   
  disk_size        = 61440               
  disk_adapter_type = "nvme"             
  
  # --- Communication ---
  communicator     = "winrm"
  winrm_username   = "Administrator"
  winrm_password   = var.winrm_password     
  
  # --- Automated Setup Files ---
  floppy_files     = ["./scripts/autounattend.xml"] 
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