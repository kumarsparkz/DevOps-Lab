Write-Host "--- 🛡️ Enterprise Security Audit 🛡️ ---" -ForegroundColor Cyan

# 1. Check for GPO-enforced Execution Policy
$gpoPolicy = (Get-ExecutionPolicy -List | Where-Object { $_.Scope -eq 'MachinePolicy' -and $_.ExecutionPolicy -ne 'Undefined' })
if ($gpoPolicy) {
    Write-Warning "Corporate Group Policy detected: Execution Policy is forced to '$($gpoPolicy.ExecutionPolicy)'. You may need to run scripts with '-ExecutionPolicy Bypass'."
}

# 2. Check for Virtualization-Based Security (VBS) / Credential Guard
$dgInfo = Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard
if ($dgInfo.SecurityServicesRunning -contains 1) {
    Write-Host "ℹ️ VBS/Credential Guard is ACTIVE. VMware will run in Side-by-Side mode (Hyper-V)." -ForegroundColor Blue
}

# 3. Check if AppLocker or WDAC services are running
$appLocker = Get-Service -Name "appidsvc" -ErrorAction SilentlyContinue
if ($appLocker -and $appLocker.Status -eq 'Running') {
    Write-Warning "AppLocker service is running. If tools like 'terraform.exe' fail with 'Access Denied', check with your IT team for path exceptions for C:\DevOps-Lab."
}

# 4. Check for 'SYSTEM' account network restrictions (Enterprise Baseline)
Write-Host "ℹ️ Tip: If the VMware API (vmrest) fails to start, you may need to change the Scheduled Task to run as a Local Admin instead of 'SYSTEM'." -ForegroundColor Gray
Write-Host "--------------------------------------`n"

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
$tools = @(
    "vmware-workstation",
    "docker-desktop",
    "terraform",
    "packer",
    "windows-adk-oscdimg"  # Required for Packer to create CD ISO for Autounattend.xml
)

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

# 3b. Add oscdimg to PATH (required for Packer CD creation)
$oscdimgPath = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg"
if (Test-Path $oscdimgPath) {
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    if ($currentPath -notlike "*$oscdimgPath*") {
        Write-Host "Adding oscdimg to system PATH..." -ForegroundColor Yellow
        [Environment]::SetEnvironmentVariable("Path", "$currentPath;$oscdimgPath", "Machine")
        $env:Path = "$env:Path;$oscdimgPath"
        Write-Host "oscdimg added to PATH. You may need to restart PowerShell." -ForegroundColor Green
    } else {
        Write-Host "oscdimg already in PATH." -ForegroundColor Green
    }
} else {
    Write-Host "Warning: oscdimg not found at expected location. Packer may fail to create CD ISO." -ForegroundColor Yellow
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
