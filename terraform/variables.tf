variable "vmware_user" {
  description = "VMware REST API username"
  default     = "admin"
}

variable "vmware_password" {
  description = "VMware REST API password"
  sensitive   = true
  default     = ""  # Set via environment variable TF_VAR_vmware_password
}

variable "vmware_url" {
  description = "VMware REST API URL"
  default     = "http://127.0.0.1:8697/api"
}

variable "win_template" {
  description = "Path to the Packer-generated Windows VMX"
  default     = "C:/DevOps-Lab/packer/output-win2022/Win2022-Gold.vmx"
}

variable "linux_template" {
  description = "Path to your Ubuntu VMX"
  default     = "C:/VMs/Templates/Ubuntu-Gold.vmx"
}

variable "vms" {
  type = map(object({
    name       = string
    memory     = number
    cpus       = number
    template   = string
  }))
}