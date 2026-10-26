#!/usr/bin/env bash
# ==============================================================================
# ssh-lab.sh - Connect to the Docker Learning Lab EC2 instance via SSH
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$(cd "${SCRIPT_DIR}/../terraform" && pwd)"

# Retrieve metadata from Terraform
INSTANCE_ID=$(terraform -chdir="${TERRAFORM_DIR}" output -raw instance_id 2>/dev/null || true)
AWS_REGION=$(terraform -chdir="${TERRAFORM_DIR}" output -raw aws_region 2>/dev/null || echo "ap-south-1")
KEY_PATH=$(terraform -chdir="${TERRAFORM_DIR}" output -raw private_key_path 2>/dev/null || echo "")

if [[ -z "${INSTANCE_ID}" ]]; then
  echo "❌ Error: Could not find Terraform state or instance_id."
  echo "Please deploy first using: ./scripts/create-lab.sh"
  exit 1
fi

# Verify instance running status
STATE=$(aws ec2 describe-instances \
  --instance-ids "${INSTANCE_ID}" \
  --region "${AWS_REGION}" \
  --query "Reservations[0].Instances[0].State.Name" \
  --output text 2>/dev/null || echo "unknown")

if [[ "${STATE}" != "running" ]]; then
  echo "⚠️  Instance ${INSTANCE_ID} is currently in '${STATE}' state."
  read -rp "Would you like to start it now? [y/N]: " START_NOW
  if [[ "${START_NOW}" =~ ^[Yy]$ ]]; then
    "${SCRIPT_DIR}/start-lab.sh"
  else
    echo "Aborting SSH connection. Start the lab when ready with: ./scripts/start-lab.sh"
    exit 1
  fi
fi

# Query the live public IP from AWS
PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids "${INSTANCE_ID}" \
  --region "${AWS_REGION}" \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text)

if [[ -z "${PUBLIC_IP}" || "${PUBLIC_IP}" == "None" ]]; then
  echo "❌ Error: No public IP address found for instance ${INSTANCE_ID}."
  exit 1
fi

# Fix key file path if relative
if [[ "${KEY_PATH}" != /* && "${KEY_PATH}" != ~* ]]; then
  KEY_PATH="${TERRAFORM_DIR}/${KEY_PATH}"
fi

if [[ ! -f "${KEY_PATH}" ]]; then
  echo "❌ Error: Private key file not found at: ${KEY_PATH}"
  exit 1
fi

# Set proper private key permissions
chmod 400 "${KEY_PATH}" 2>/dev/null || true

echo "============================================================"
echo "Connecting to Docker Lab: ubuntu@${PUBLIC_IP}"
echo "Key file: ${KEY_PATH}"
echo "============================================================"

exec ssh -o StrictHostKeyChecking=accept-new -i "${KEY_PATH}" "ubuntu@${PUBLIC_IP}" "$@"
