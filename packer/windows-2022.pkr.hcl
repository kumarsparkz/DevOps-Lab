packer {
  required_plugins {
    vmware = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/vmware"
    }
  }
}

source "vmware-iso" "win2022" {
  vm_name              = "Win2022-Gold"
  iso_url              = "./iso/WinServer2022.iso"
  iso_checksum         = "sha256:YOUR_ISO_HASH" # Get this from Microsoft's site
  communicator         = "winrm"
  winrm_username       = "Administrator"
  winrm_password       = "Password123!"
  
  # Hardware Settings (Optimized for your 96GB PC)
  cpus                 = 4
  memory               = 8192
  disk_size            = 61440 # 60GB
  guest_os_type        = "windows2019srvnext-64"
  
  # Automation files
  floppy_files         = ["./scripts/autounattend.xml"]
  
  # Shutdown command for final Sysprep
  shutdown_command     = "powershell -ExecutionPolicy Bypass -File C:/Windows/Setup/Scripts/cleanup.ps1"
}

build {
  sources = ["source.vmware-iso.win2022"]

  # Step 1: Install VMware Tools (Drivers for Disk/Network performance)
  provisioner "powershell" {
    script = "./scripts/install-tools.ps1"
  }

  # Step 2: Final Cleanup and Sysprep
  provisioner "powershell" {
    script = "./scripts/setup.ps1"
  }
}