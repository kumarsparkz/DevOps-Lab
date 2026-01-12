variable "vmware_user" { default = "admin" }
variable "vmware_password" { default = "yourpassword" } # Match your vmrest.exe password

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