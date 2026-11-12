#!/usr/bin/env bash
# ==============================================================================
# start-lab.sh - Start the Docker Learning Lab EC2 instance and wait until ready
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$(cd "${SCRIPT_DIR}/../terraform" && pwd)"

echo "============================================================"
echo "          ⚡ Starting Docker Learning Lab Instance          "
echo "============================================================"

# Read instance ID and region from Terraform output
INSTANCE_ID=$(terraform -chdir="${TERRAFORM_DIR}" output -raw instance_id 2>/dev/null || true)
AWS_REGION=$(terraform -chdir="${TERRAFORM_DIR}" output -raw aws_region 2>/dev/null || echo "ap-south-1")

if [[ -z "${INSTANCE_ID}" ]]; then
  echo "❌ Error: Could not retrieve instance_id from Terraform output."
  echo "Make sure the lab has been created with: ./scripts/create-lab.sh"
  exit 1
fi

echo "Instance ID: ${INSTANCE_ID}"
echo "AWS Region:  ${AWS_REGION}"
echo ""

# Check current state
CURRENT_STATE=$(aws ec2 describe-instances \
  --instance-ids "${INSTANCE_ID}" \
  --region "${AWS_REGION}" \
  --query "Reservations[0].Instances[0].State.Name" \
  --output text 2>/dev/null || echo "unknown")

echo "Current instance state: ${CURRENT_STATE}"

if [[ "${CURRENT_STATE}" == "running" ]]; then
  echo "✅ Instance is already running."
else
  echo "▶ Requesting EC2 instance start..."
  aws ec2 start-instances --instance-ids "${INSTANCE_ID}" --region "${AWS_REGION}" > /dev/null
  echo "⏳ Waiting for instance to transition to 'running' state (this takes ~15-30s)..."
  aws ec2 wait instance-running --instance-ids "${INSTANCE_ID}" --region "${AWS_REGION}"
  echo "✅ Instance is now RUNNING!"
fi

# Fetch new live Public IP & Public DNS
PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids "${INSTANCE_ID}" \
  --region "${AWS_REGION}" \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text)

PUBLIC_DNS=$(aws ec2 describe-instances \
  --instance-ids "${INSTANCE_ID}" \
  --region "${AWS_REGION}" \
  --query "Reservations[0].Instances[0].PublicDnsName" \
  --output text)

KEY_PATH=$(terraform -chdir="${TERRAFORM_DIR}" output -raw private_key_path 2>/dev/null || echo "")

echo ""
echo "============================================================"
echo "  🎉 Lab Ready! Connection Details:"
echo "============================================================"
echo "  Public IP:     ${PUBLIC_IP}"
echo "  Public DNS:    ${PUBLIC_DNS:-None}"
if [[ -n "${KEY_PATH}" ]]; then
  echo "  SSH Key:       ${KEY_PATH}"
  echo "  Connect via:   ssh -i ${KEY_PATH} ubuntu@${PUBLIC_IP}"
  echo "                 or simply run: ./scripts/ssh-lab.sh"
fi
echo "============================================================"
