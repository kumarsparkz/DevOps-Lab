packer {
  required_plugins {
    vmware = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/vmware"
    }
  }
}

source "vmware-iso" "win2022" {
  iso_url          = "./iso/windows_server_2022.iso" # Update this path
  iso_checksum     = "none" # Use the actual SHA256 for production
  vm_name          = "Win2022-Gold"
  guest_os_type    = "windows2019srv-64" # VMware uses this for 2022
  
  # Performance Tuning for 96GB RAM Host
  memory           = 16384 
  cpus             = 4
  disk_size        = 61440 # 60GB
  disk_adapter_type = "nvme"
  
  # Communication
  communicator     = "winrm"
  winrm_username   = "Administrator"
  winrm_password   = "Password123!"
  
  # This tells Packer to look for your unattended install file
  floppy_files     = ["./scripts/autounattend.xml"]
}

build {
  sources = ["source.vmware-iso.win2022"]
  
  # This runs your Tool installation and Sysprep scripts
  provisioner "powershell" {
    scripts = [
      "./scripts/install-tools.ps1",
      "./scripts/setup.ps1"
    ]
  }
}