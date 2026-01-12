# DevOps Lab - Automated Infrastructure on VMware Workstation

A complete DevOps lab environment that uses **Packer** to build Windows Server gold images, **Terraform** to provision VMs on VMware Workstation, and **Ansible** to configure SQL Server 2022.

## Architecture Overview

| Component | Purpose | Resources |
|-----------|---------|-----------|
| **Gitness** | CI/CD Pipeline Engine | 2GB RAM (Docker) |
| **SRV-SQL-01** | SQL Server 2022 | 48GB RAM, 4 vCPU |
| **SRV-APP-01** | Application Server | 16GB RAM, 2 vCPU |
| **SRV-LNX-01** | Linux Node | 8GB RAM, 2 vCPU |

**Host Requirements:** Windows 10/11 Pro with 96GB+ RAM, 500GB+ SSD

---

## Quick Start Guide

### Step 1: Clone the Repository

```powershell
cd C:\
git clone https://github.com/kumarsparkz/DevOps-Lab.git
cd DevOps-Lab
```

### Step 2: Configure Environment Variables

```powershell
# Copy the example environment file
Copy-Item .env.example .env

# Edit .env with your passwords
notepad .env
```

Update these values in `.env`:
```bash
VMWARE_API_PASSWORD=YourSecurePassword123!
TF_VAR_vmware_password=YourSecurePassword123!
ANSIBLE_PASSWORD=YourSecurePassword123!
SQL_SA_PASSWORD=YourSecureSqlPassword123!
PKR_VAR_winrm_password=YourSecurePassword123!
```

### Step 3: Run the Host Initialization Script

```powershell
# Load environment variables
Get-Content .env | ForEach-Object {
  if ($_ -match '^([^#][^=]+)=(.*)$') {
    [Environment]::SetEnvironmentVariable($matches[1], $matches[2], 'Process')
  }
}

# Run the initialization script (requires Admin)
Set-ExecutionPolicy Bypass -Scope Process -Force
.\scripts\Init-LabHost.ps1
```

This script will:
- Install Chocolatey package manager
- Install VMware Workstation, Docker Desktop, Terraform, and Packer
- Enable required Windows features (WSL2, Hyper-V Platform)
- Configure VMware REST API as a scheduled task

**Restart your PC after this step.**

### Step 4: Configure VMware REST API Credentials

After restart, set up vmrest credentials:

```powershell
& "C:\Program Files (x86)\VMware\VMware Workstation\vmrest.exe" -C
```

Enter the same username/password you set in `.env` for `VMWARE_API_USER` and `VMWARE_API_PASSWORD`.

### Step 5: Download Windows Server 2022 ISO

1. Download the evaluation ISO from [Microsoft Evaluation Center](https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2022)
2. Place it in `C:\DevOps-Lab\packer\` directory
3. Update the ISO path in `packer/win2022.pkr.hcl` if needed

### Step 6: Build the Gold Image with Packer

```powershell
cd C:\DevOps-Lab\packer

# Load environment variables
Get-Content ..\.env | ForEach-Object {
  if ($_ -match '^([^#][^=]+)=(.*)$') {
    [Environment]::SetEnvironmentVariable($matches[1], $matches[2], 'Process')
  }
}

# Initialize and build
packer init win2022.pkr.hcl
packer build win2022.pkr.hcl
```

This creates `output-win2022/Win2022-Gold.vmx` - your template VM.

### Step 7: Start Gitness (CI/CD Platform)

```powershell
cd C:\DevOps-Lab\gitness
docker-compose up -d
```

Access Gitness at: http://localhost:3000

### Step 8: Start VMware REST API

```powershell
# Start the REST API (or it starts automatically on login via scheduled task)
& "C:\Program Files (x86)\VMware\VMware Workstation\vmrest.exe"
```

Verify it's running: http://localhost:8697/api/vms

### Step 9: Deploy Infrastructure with Terraform

```powershell
cd C:\DevOps-Lab\terraform

# Load environment variables
Get-Content ..\.env | ForEach-Object {
  if ($_ -match '^([^#][^=]+)=(.*)$') {
    [Environment]::SetEnvironmentVariable($matches[1], $matches[2], 'Process')
  }
}

terraform init
terraform plan
terraform apply -auto-approve
```

### Step 10: Configure VMs with Ansible

After VMs boot and WinRM is available:

```powershell
cd C:\DevOps-Lab\ansible

# Update inventory.ini with actual VM IPs from Terraform output
# Then run the playbook

# From WSL or a Linux container:
ansible-playbook -i inventory.ini site.yml
```

---

## Directory Structure

```
C:\DevOps-Lab\
├── .env.example          # Environment variable template
├── .gitignore            # Git ignore rules
├── README.md             # This file
├── .harness/             # CI/CD Pipeline definitions
│   ├── pipeline.yaml     # Main deployment pipeline
│   └── destroy_lab_pipeline.yaml
├── ansible/              # Configuration management
│   ├── inventory.ini     # Host inventory
│   ├── site.yml          # Main playbook
│   ├── smoke_test.ps1    # SQL verification script
│   └── roles/
│       └── sql_server/   # SQL Server role
├── gitness/              # CI/CD platform
│   └── docker-compose.yml
├── packer/               # Image building
│   ├── win2022.pkr.hcl   # Packer template
│   ├── scripts/          # Setup scripts
│   └── output-win2022/   # Built VM (gitignored)
├── scripts/              # Utility scripts
│   ├── Init-LabHost.ps1  # Host setup script
│   ├── health_check.sh   # Environment verification
│   └── Windown-LabJunk.ps1  # Cleanup script
└── terraform/            # Infrastructure as Code
    ├── main.tf           # VM definitions
    ├── variables.tf      # Variable declarations
    └── terraform.tfvars  # Variable values
```

---

## Running the Full Pipeline

Once everything is set up, you can run the entire deployment from Gitness:

1. Open http://localhost:3000
2. Create a new repository pointing to `C:\DevOps-Lab`
3. Create a pipeline using `.harness/pipeline.yaml`
4. Run the pipeline

The pipeline will:
1. Run health checks
2. Provision VMs with Terraform
3. Wait for WinRM availability
4. Configure SQL Server with Ansible
5. Run smoke tests

---

## Troubleshooting

### VMware REST API not responding
```powershell
# Check if vmrest is running
Get-Process vmrest -ErrorAction SilentlyContinue

# Restart it
& "C:\Program Files (x86)\VMware\VMware Workstation\vmrest.exe"
```

### Docker/VMware conflict
```powershell
# Ensure hypervisor is set correctly
bcdedit /set hypervisorlaunchtype auto
# Restart PC
```

### WinRM not available on VMs
```powershell
# On the VM, run:
winrm quickconfig -quiet
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
```

### Terraform authentication failed
```powershell
# Re-configure vmrest credentials
& "C:\Program Files (x86)\VMware\VMware Workstation\vmrest.exe" -C
# Ensure password matches TF_VAR_vmware_password in .env
```

---

## Cleanup

To destroy all lab VMs:

```powershell
cd C:\DevOps-Lab\terraform
terraform destroy -auto-approve
```

To remove everything including Gitness:

```powershell
.\scripts\Windown-LabJunk.ps1
```

---

## Security Notes

- Never commit `.env` files to version control
- The `.env.example` file contains placeholder passwords only
- Change all default passwords before production use
- The lab uses unencrypted WinRM for simplicity - not suitable for production
