#!/usr/bin/env bash
# ==============================================================================
# stop-lab.sh - Stop the Docker Learning Lab EC2 instance and wait until stopped
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$(cd "${SCRIPT_DIR}/../terraform" && pwd)"

echo "============================================================"
echo "          🛑 Stopping Docker Learning Lab Instance          "
echo "============================================================"

# Read instance ID and region from Terraform output
INSTANCE_ID=$(terraform -chdir="${TERRAFORM_DIR}" output -raw instance_id 2>/dev/null || true)
AWS_REGION=$(terraform -chdir="${TERRAFORM_DIR}" output -raw aws_region 2>/dev/null || echo "ap-south-1")

if [[ -z "${INSTANCE_ID}" ]]; then
  echo "❌ Error: Could not retrieve instance_id from Terraform output."
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

if [[ "${CURRENT_STATE}" == "stopped" ]]; then
  echo "✅ Instance is already stopped. Compute billing is paused."
  exit 0
fi

echo "▶ Requesting EC2 instance stop..."
aws ec2 stop-instances --instance-ids "${INSTANCE_ID}" --region "${AWS_REGION}" > /dev/null

echo "⏳ Waiting for instance to transition to 'stopped' state (this takes ~30-60s)..."
aws ec2 wait instance-stopped --instance-ids "${INSTANCE_ID}" --region "${AWS_REGION}"

echo ""
echo "============================================================"
echo "  ✅ Instance is now STOPPED!"
echo "============================================================"
echo "💡 Cost-Saving Summary:"
echo "• EC2 Compute (vCPU & RAM):  $0.00 / hour (PAUSED)"
echo "• Public IPv4 Address:        $0.00 / hour (RELEASED)"
echo "• EBS Root Volume (20GB gp3): ~$0.05 / day (Keeps your containers & files safe)"
echo ""
echo "To resume your learning session tomorrow, simply run: ./scripts/start-lab.sh"
echo "============================================================"
