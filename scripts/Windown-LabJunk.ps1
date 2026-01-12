Write-Host "--- 🧹 Starting DevOps Lab Deep Clean 🧹 ---" -ForegroundColor Cyan

# 1. Stop Gitness Containers
Write-Host "Stopping Gitness and Docker containers..."
cd C:\Gitness-Lab
docker-compose down

# 2. Kill any orphaned VMware API processes
Write-Host "Closing VMware REST API..."
Get-Process vmrest -ErrorAction SilentlyContinue | Stop-Process -Force

# 3. Clean Terraform Temp Files
# This removes local provider binaries and state backups but KEEPS your main state
Write-Host "Cleaning Terraform workspace..."
Get-ChildItem -Path C:\DevOps-Lab\terraform -Include .terraform, .terraform.lock.hcl, *.tfstate.backup -Recurse | Remove-Item -Recurse -Force

# 4. Clean Packer Cache
# Packer downloads ISOs and keeps temp files; this clears the cache folder
Write-Host "Clearing Packer cache..."
if (Test-Path "C:\DevOps-Lab\packer\packer_cache") {
    Remove-Item -Path "C:\DevOps-Lab\packer\packer_cache" -Recurse -Force
}

# 5. Clean Ansible Retry Files
Write-Host "Removing Ansible retry files..."
Get-ChildItem -Path C:\DevOps-Lab\ansible -Filter *.retry -Recurse | Remove-Item -Force

# 6. Optional: Clear VMware "In-Memory" Temp Files
# Helps if a VM crashed and left a .lck (lock) file behind
Write-Host "Removing VMware lock files..."
Get-ChildItem -Path C:\VMs -Filter *.lck -Recurse | Remove-Item -Recurse -Force

Write-Host "--- ✨ Lab Workspace is Clean! ✨ ---" -ForegroundColor Green