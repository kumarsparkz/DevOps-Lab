# 1. Check Core DevOps Tool Versions
Write-Host "--- Tool Versions ---" -ForegroundColor Cyan
choco --version; docker --version; terraform --version; packer --version

# 2. Verify Windows Features are Enabled
Write-Host "`n--- Windows Features ---" -ForegroundColor Cyan
Get-WindowsOptionalFeature -Online | Where-Object { 
    $_.FeatureName -match "HypervisorPlatform|VirtualMachinePlatform|Microsoft-Windows-Subsystem-Linux" 
} | Select-Object FeatureName, State

# 3. Verify VMware API Service is Listening
Write-Host "`n--- VMware API Status ---" -ForegroundColor Cyan
Test-NetConnection -ComputerName 127.0.0.1 -Port 8697