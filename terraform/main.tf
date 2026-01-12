terraform {
  required_providers {
    vmworkstation = {
      source = "elsudano/vmworkstation"
    }
  }
}

provider "vmworkstation" {
  user     = var.vmware_user
  password = var.vmware_password
  url      = var.vmware_url
}

resource "vmworkstation_vm" "lab_vms" {
  for_each = var.vms # This is the "Magic Loop"

  name            = each.value.name
  processors      = each.value.cpus
  memory          = each.value.memory
  source_path     = each.value.template == "win" ? var.win_template : var.linux_template
  
  # This ensures the VMs start automatically
  state           = "poweredOn"

  network_adapter {
    type          = "nat"
    adapter_type  = "e1000e"
  }
}

# This output creates a JSON object mapping VM names to their IP addresses
output "vm_ips" {
  value = {
    for name, vm in vmworkstation_vm.lab_vms : name => vm.ip_address
  }
  description = "The IP addresses of the deployed lab VMs"
}