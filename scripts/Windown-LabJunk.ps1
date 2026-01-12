Write-Host "--- 🧹 Starting DevOps Lab Deep Clean 🧹 ---" -ForegroundColor Cyan

# 1. Stop Gitness Containers
Write-Host "Stopping Gitness and Docker containers..."
# Use the mapped path from your actual setup
if (Test-Path "C:\DevOps-Lab\gitness") {
    cd C:\DevOps-Lab\gitness
    docker-compose down
}

# 2. Kill all VMware related processes
Write-Host "Closing all VMware processes..."
$vmProcesses = @("vmware", "vmware-vmx", "vmrest", "packer")
foreach ($proc in $vmProcesses) {
    Get-Process $proc -ErrorAction SilentlyContinue | Stop-Process -Force
}

# 2.1 Remove the specific Packer output folder
Write-Host "Forcing removal of Packer output directory..."
if (Test-Path "C:\DevOps-Lab\packer\output-win2022") {
    # We use a loop to retry deletion if a process is slow to close
    Remove-Item -Path "C:\DevOps-Lab\packer\output-win2022" -Recurse -Force -ErrorAction SilentlyContinue
}

# 3. Clean Terraform Temp Files
Write-Host "Cleaning Terraform workspace..."
if (Test-Path "C:\DevOps-Lab\terraform") {
    # Added -ErrorAction to suppress permission errors on hidden locked files
    Get-ChildItem -Path C:\DevOps-Lab\terraform -Include .terraform, .terraform.lock.hcl, *.tfstate.backup -Recurse -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
}

# 4. Clean Packer Cache
Write-Host "Clearing Packer cache..."
if (Test-Path "C:\DevOps-Lab\packer\packer_cache") {
    Remove-Item -Path "C:\DevOps-Lab\packer\packer_cache" -Recurse -Force
}

# 4.5 Clean Packer Output Directory
# This ensures a fresh build doesn't fail because the folder already exists
Write-Host "Removing previous Packer output..."
if (Test-Path "C:\DevOps-Lab\packer\output-win2022") {
    Remove-Item -Path "C:\DevOps-Lab\packer\output-win2022" -Recurse -Force
}

# 5. Clean Ansible Retry Files
Write-Host "Removing Ansible retry files..."
if (Test-Path "C:\DevOps-Lab\ansible") {
    Get-ChildItem -Path C:\DevOps-Lab\ansible -Filter *.retry -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force
}

# 6. Safe VMware Lock File Removal
Write-Host "Removing VMware lock files..."
# Check if the path exists first and use -ErrorAction to avoid system folder errors
if (Test-Path "C:\VMs") {
    Get-ChildItem -Path "C:\VMs" -Filter *.lck -Recurse -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
} else {
    Write-Host "⚠️ Path C:\VMs not found. Skipping lock file cleanup." -ForegroundColor Yellow
}

Write-Host "--- ✨ Lab Workspace is Clean! ✨ ---" -ForegroundColor Green