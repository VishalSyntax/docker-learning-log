#!/usr/bin/env bash
# ==============================================================================
# create-lab.sh - Initialize and deploy the Docker Learning Lab infrastructure
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$(cd "${SCRIPT_DIR}/../terraform" && pwd)"

echo "============================================================"
echo "      🚀 Initializing Docker Learning Lab Deployment        "
echo "============================================================"
echo "Terraform Directory: ${TERRAFORM_DIR}"
echo ""

cd "${TERRAFORM_DIR}"

# Check prerequisites
if ! command -v terraform &> /dev/null; then
  echo "❌ Error: 'terraform' CLI is not installed or not in PATH."
  exit 1
fi

if ! command -v aws &> /dev/null; then
  echo "❌ Error: 'aws' CLI is not installed or not in PATH."
  exit 1
fi

# Step 1: Terraform Init
echo "▶ Step 1/4: Initializing Terraform..."
terraform init

# Step 2: Terraform Validate
echo ""
echo "▶ Step 2/4: Validating Terraform configuration..."
terraform validate

# Step 3: Terraform Plan
echo ""
echo "▶ Step 3/4: Creating execution plan..."
terraform plan -out=tfplan

# Step 4: Confirmation & Apply
echo ""
echo "▶ Step 4/4: Ready to apply infrastructure."
read -rp "Proceed with deploying the infrastructure to AWS? [y/N]: " CONFIRM
if [[ "${CONFIRM}" =~ ^[Yy]$ ]]; then
  echo "Applying plan..."
  terraform apply tfplan
  rm -f tfplan

  # Secure private key file permissions if generated
  KEY_FILE=$(terraform output -raw private_key_path 2>/dev/null || echo "")
  if [[ -n "${KEY_FILE}" && -f "${KEY_FILE}" ]]; then
    chmod 400 "${KEY_FILE}" 2>/dev/null || true
  fi

  echo ""
  echo "============================================================"
  echo "  ✅ Docker Learning Lab Infrastructure Created Successfully!"
  echo "============================================================"
  echo ""
  terraform output
  echo ""
  echo "Next steps:"
  echo "1. Wait 1-2 minutes for user-data bootstrap script to complete installation."
  echo "2. Connect to your instance with:  ./scripts/ssh-lab.sh"
  echo "3. Check status anytime with:     ./scripts/status.sh"
  echo "4. When done for the day:         ./scripts/stop-lab.sh"
else
  echo "Deployment cancelled by user. Removing temporary plan file."
  rm -f tfplan
  exit 0
fi
