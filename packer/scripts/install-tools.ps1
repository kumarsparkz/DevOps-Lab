# Locate the VMware Tools ISO (mounted automatically by Packer)
$driveLetter = (Get-PSDrive -PSProvider FileSystem | Where-Object { 
    Test-Path "$($_.Root)VMware-tools-setup.exe" -ErrorAction SilentlyContinue 
}).Root

if ($driveLetter) {
    Write-Host "Found VMware Tools at $driveLetter. Installing..."
    # /S = Silent, /v = pass arguments to MSI, /qn = quiet no UI, REBOOT=R = Suppress reboot
    Start-Process "$driveLetter\VMware-tools-setup.exe" -ArgumentList '/S /v "/qn REBOOT=R"' -Wait
} else {
    Write-Warning "VMware Tools installer not found!"
}

# Install SQL PowerShell module for Ansible memory configuration
Install-Module -Name SqlServer -AllowClobber -Force