# DevOps Lab - Automated Infrastructure on VMware Workstation

A complete DevOps lab environment that uses **Packer** to build Windows Server gold images, **Terraform** to provision VMs on VMware Workstation, and **Ansible** to configure SQL Server 2022 - all orchestrated through **Gitness CI/CD pipelines**.

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
2. Place it in `C:\DevOps-Lab\packer\iso\` directory
3. Rename it to `windows_server_2022.iso`

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
packer build .
```

This creates `output-win2022/Win2022-Gold.vmx` - your template VM.

### Step 7: Start Services

```powershell
# Start Gitness (CI/CD Platform)
cd C:\DevOps-Lab\gitness
docker-compose up -d

# Start VMware REST API (if not auto-started)
& "C:\Program Files (x86)\VMware\VMware Workstation\vmrest.exe"
```

Verify services are running:
- Gitness: http://localhost:3000
- VMware API: http://localhost:8697/api/vms

### Step 8: Configure Gitness Repository

1. Open http://localhost:3000
2. Create an account and sign in
3. Create a new project (e.g., "DevOps-Lab")
4. Import or create a repository pointing to `C:\DevOps-Lab`

### Step 9: Create and Run the Pipeline

1. In Gitness, go to your repository
2. Navigate to **Pipelines** > **New Pipeline**
3. Select "Use existing YAML" and point to `.harness/pipeline.yaml`
4. Configure pipeline secrets for environment variables:
   - `VMWARE_PASSWORD` → Your VMware API password
   - `ANSIBLE_PASSWORD` → Your Windows admin password
   - `SQL_SA_PASSWORD` → Your SQL SA password
5. Click **Run Pipeline**

The pipeline will automatically:
1. Run pre-flight health checks
2. Provision VMs with Terraform
3. Wait for WinRM availability (up to 5 minutes)
4. Configure SQL Server with Ansible
5. Run smoke tests to verify deployment

### Step 10: Destroy Infrastructure (When Done)

To tear down all VMs, create a new pipeline run using `.harness/destroy_lab_pipeline.yaml` or run it from Gitness.

---

## Pipeline Stages

The main pipeline (`.harness/pipeline.yaml`) executes these stages:

```
┌─────────────────────┐
│  Pre-Flight Check   │  Verify VMware API, Terraform, Gold Image
└─────────┬───────────┘
          │
┌─────────▼───────────┐
│ Infrastructure Build│  terraform init → terraform apply
└─────────┬───────────┘
          │
┌─────────▼───────────┐
│   Wait for WinRM    │  Poll port 5985 until VMs are ready
└─────────┬───────────┘
          │
┌─────────▼───────────┐
│  Ansible SQL Setup  │  Install & configure SQL Server 2022
└─────────┬───────────┘
          │
┌─────────▼───────────┐
│    Smoke Tests      │  Verify SQL connectivity
└─────────────────────┘
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
│   ├── iso/              # Place Windows ISO here
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

## Troubleshooting

### Pipeline fails at health check
```powershell
# Ensure VMware REST API is running
Get-Process vmrest -ErrorAction SilentlyContinue
& "C:\Program Files (x86)\VMware\VMware Workstation\vmrest.exe"
```

### Pipeline fails at Terraform
```powershell
# Re-configure vmrest credentials
& "C:\Program Files (x86)\VMware\VMware Workstation\vmrest.exe" -C
# Ensure password matches TF_VAR_vmware_password
```

### Pipeline times out waiting for WinRM
- Check if VMs booted successfully in VMware Workstation
- Verify WinRM is enabled in the gold image
- Check Windows Firewall allows port 5985

### Docker/VMware conflict
```powershell
bcdedit /set hypervisorlaunchtype auto
# Restart PC
```

### Gitness container not starting
```powershell
cd C:\DevOps-Lab\gitness
docker-compose down
docker-compose up -d
docker logs gitness
```

---

## Cleanup

**Option 1: Run destroy pipeline from Gitness**
1. Create new pipeline using `.harness/destroy_lab_pipeline.yaml`
2. Run the pipeline

**Option 2: Full cleanup including Gitness**
```powershell
.\scripts\Windown-LabJunk.ps1
```

---

## Security Notes

- Never commit `.env` files to version control
- Configure pipeline secrets in Gitness instead of hardcoding
- The `.env.example` file contains placeholder passwords only
- Change all default passwords before production use
- The lab uses unencrypted WinRM for simplicity - not suitable for production
