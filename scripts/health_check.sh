#!/bin/bash
set -e

echo "--- 🟢 STARTING LAB HEALTH CHECK 🟢 ---"

# 1. Check if Terraform is available
if command -v terraform &> /dev/null; then
    echo "✅ Terraform: $(terraform version -short)"
else
    echo "❌ Terraform not found"
    exit 1
fi

# 2. Check if VMware API (vmrest) is reachable on the Host
# We use host.docker.internal to talk to your Windows 11 host from inside the Gitness container
echo "Testing VMware API connectivity..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://host.docker.internal:8697/api/ || echo "000")

if [ "$HTTP_CODE" -eq 401 ]; then
    echo "✅ VMware API: Reachable (Authentication required as expected)"
elif [ "$HTTP_CODE" -eq 200 ]; then
    echo "✅ VMware API: Reachable and Authenticated"
else
    echo "❌ VMware API: Unreachable (Status: $HTTP_CODE). Is vmrest.exe running?"
    exit 1
fi

# 3. Verify Packer Template exists
# Update this path to where your Packer output actually lives
default = "C:/DevOps-Lab/packer/output-win2022/Win2022-Gold.vmx"
if [ -f "$TEMPLATE_PATH" ]; then
    echo "✅ Gold Image: Found at $TEMPLATE_PATH"
else
    echo "⚠️  Gold Image: Not found. Ensure Packer build is finished."
fi

# Check Host RAM availability via a PowerShell call from the container
echo "Checking Host RAM Capacity..."
AVAILABLE_RAM=$(curl -s http://host.docker.internal:8697/api/v1/host/memory | jq '.available')
echo "✅ Host Available RAM: $AVAILABLE_RAM MB"

echo "--- 🚀 HEALTH CHECK PASSED: READY FOR DEPLOYMENT 🚀 ---"