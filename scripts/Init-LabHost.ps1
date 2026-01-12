# 1. Check/Install Chocolatey
if (Get-Command choco -ErrorAction SilentlyContinue) {
    Write-Host "Chocolatey is already installed. Checking for upgrades..." -ForegroundColor Cyan
    choco upgrade chocolatey -y
} else {
    Write-Host "Installing Chocolatey..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force; 
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; 
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

# 2. Force Hypervisor to launch at boot (Fixes Docker + VMware conflict)
$bcd = bcdedit | Select-String "hypervisorlaunchtype"
if ($bcd -notmatch "Auto") {
    Write-Host "Setting hypervisor launch type to Auto..." -ForegroundColor Yellow
    bcdedit /set hypervisorlaunchtype auto
    $restartRequired = $true
}

# 3. List of DevOps Tools to manage
$tools = @("vmware-workstation", "docker-desktop", "terraform", "packer")

foreach ($tool in $tools) {
    # Check if the package is already installed via choco
    $chk = choco list --local-only $tool
    if ($chk -match $tool) {
        Write-Host "$tool is already installed. Attempting upgrade..." -ForegroundColor Cyan
        choco upgrade $tool -y
    } else {
        Write-Host "Installing $tool..." -ForegroundColor Yellow
        choco install $tool -y
    }
}

# 4. Enable Windows Features (Idempotent Check)
$features = @("Microsoft-Windows-Subsystem-Linux", "VirtualMachinePlatform", "HypervisorPlatform")

foreach ($feature in $features) {
    $status = Get-WindowsOptionalFeature -Online -FeatureName $feature
    if ($status.State -eq "Enabled") {
        Write-Host "Feature '$feature' is already enabled." -ForegroundColor Green
    } else {
        Write-Host "Enabling '$feature'..." -ForegroundColor Yellow
        Enable-WindowsOptionalFeature -Online -FeatureName $feature -All -NoRestart
        $restartRequired = $true
    }
}

# 5. Configure VMware REST API as a Windows Service
$TaskName = "VMware-Rest-API"
$WorkstationPath = "C:\Program Files (x86)\VMware\VMware Workstation"
# Credentials loaded from environment variables (set in .env file)
$User = if ($env:VMWARE_API_USER) { $env:VMWARE_API_USER } else { "admin" }
$Pass = if ($env:VMWARE_API_PASSWORD) { $env:VMWARE_API_PASSWORD } else { throw "VMWARE_API_PASSWORD environment variable not set. Please set it before running this script." }

if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Write-Host "Scheduled Task '$TaskName' already exists. Skipping..." -ForegroundColor Green
} else {
    Write-Host "Creating Scheduled Task for VMware API..." -ForegroundColor Yellow
    # if you forget credentials run & "C:\Program Files (x86)\VMware\VMware Workstation\vmrest.exe" -C 
    $Action = New-ScheduledTaskAction -Execute "$WorkstationPath\vmrest.exe"
    $Trigger = New-ScheduledTaskTrigger -AtLogOn
    Register-ScheduledTask -Action $Action -Trigger $trigger -TaskName $TaskName -User "SYSTEM" -Force
}

# 6. Final Message
if ($restartRequired) {
    Write-Host "Setup complete. A RESTART is required to finalize Windows Features." -ForegroundColor Red -BackgroundColor White
} else {
    Write-Host "Setup complete. No restart required. Your lab environment is ready!" -ForegroundColor Green
}