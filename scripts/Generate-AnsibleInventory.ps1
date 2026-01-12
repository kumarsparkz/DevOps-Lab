Write-Host "--- 🌉 Generating Ansible Inventory from Terraform 🌉 ---" -ForegroundColor Cyan

# 1. Get the JSON output from Terraform
cd C:\DevOps-Lab\terraform
$tfOutput = terraform output -json | ConvertFrom-Json

# 2. Extract IPs (handling the 'vm_ips' nested object)
$ips = $tfOutput.vm_ips.value

# 3. Create the YAML content
$inventory = @"
all:
  children:
    windows:
      hosts:
        sql_server:
          ansible_host: $($ips.sql)
        app_server:
          ansible_host: $($ips.app)
      vars:
        ansible_user: Administrator
        ansible_password: Password123!
        ansible_connection: winrm
        ansible_winrm_server_cert_validation: ignore
    linux:
      hosts:
        linux_node:
          ansible_host: $($ips.linux)
      vars:
        ansible_user: root
"@

# 4. Save to the Ansible folder
$inventory | Out-File -FilePath "C:\DevOps-Lab\ansible\inventory.yaml" -Encoding utf8

Write-Host "✅ Inventory generated at C:\DevOps-Lab\ansible\inventory.yaml" -ForegroundColor Green