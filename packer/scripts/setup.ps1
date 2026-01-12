# Stop WinRM briefly to finalize settings
net stop winrm

# Optional: Disable Windows Updates during the demo to save CPU/RAM
Set-Service wuauserv -StartupType Disabled

# SYSPREP: The most important command for cloning
# /oobe: Out-of-Box Experience (the welcome screen for the new clone)
# /generalize: Strips the hardware ID and SID
# /shutdown: Powers off so Packer can save the disk
& $env:SystemRoot\System32\Sysprep\Sysprep.exe /oobe /generalize /quiet /shutdown