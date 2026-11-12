#!/usr/bin/env bash
# ==============================================================================
# status.sh - Check current state and metadata of the Docker Learning Lab EC2
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$(cd "${SCRIPT_DIR}/../terraform" && pwd)"

echo "============================================================"
echo "          📊 Docker Learning Lab Status Overview           "
echo "============================================================"

# Read instance ID and region from Terraform output
INSTANCE_ID=$(terraform -chdir="${TERRAFORM_DIR}" output -raw instance_id 2>/dev/null || true)
AWS_REGION=$(terraform -chdir="${TERRAFORM_DIR}" output -raw aws_region 2>/dev/null || echo "ap-south-1")

if [[ -z "${INSTANCE_ID}" ]]; then
  echo "❌ Error: Could not retrieve instance_id from Terraform output."
  echo "The lab might not be deployed yet. Run: ./scripts/create-lab.sh"
  exit 1
fi

# Fetch instance details via AWS CLI in JSON format
INSTANCE_DATA=$(aws ec2 describe-instances \
  --instance-ids "${INSTANCE_ID}" \
  --region "${AWS_REGION}" \
  --query "Reservations[0].Instances[0]" \
  --output json 2>/dev/null || echo "{}")

if [[ "${INSTANCE_DATA}" == "{}" ]]; then
  echo "❌ Error: Could not fetch details for instance ${INSTANCE_ID} from AWS."
  exit 1
fi

# Parse fields
STATE=$(echo "${INSTANCE_DATA}" | grep -o '"Name": "[^"]*' | head -1 | cut -d'"' -f4 || echo "unknown")
INSTANCE_TYPE=$(echo "${INSTANCE_DATA}" | grep -o '"InstanceType": "[^"]*' | cut -d'"' -f4 || echo "unknown")
PUBLIC_IP=$(echo "${INSTANCE_DATA}" | grep -o '"PublicIpAddress": "[^"]*' | cut -d'"' -f4 || echo "N/A (Stopped)")
PRIVATE_IP=$(echo "${INSTANCE_DATA}" | grep -o '"PrivateIpAddress": "[^"]*' | cut -d'"' -f4 || echo "unknown")
LAUNCH_TIME=$(echo "${INSTANCE_DATA}" | grep -o '"LaunchTime": "[^"]*' | cut -d'"' -f4 || echo "unknown")

# Format output
echo "Instance ID:    ${INSTANCE_ID}"
echo "AWS Region:     ${AWS_REGION}"
echo "Instance Type:  ${INSTANCE_TYPE}"
echo "Private IP:     ${PRIVATE_IP}"
echo "Public IP:      ${PUBLIC_IP}"
echo "Launch Time:    ${LAUNCH_TIME}"
echo ""

case "${STATE}" in
  "running")
    echo "🟢 Status: RUNNING"
    echo "   Compute is ACTIVE. Docker environment is ready."
    echo "   Connect anytime: ./scripts/ssh-lab.sh"
    echo "   Stop when done:  ./scripts/stop-lab.sh"
    ;;
  "stopped")
    echo "🔴 Status: STOPPED"
    echo "   Compute is PAUSED ($0.00/hr). EBS volume preserved."
    echo "   To start lab:    ./scripts/start-lab.sh"
    ;;
  "stopping")
    echo "🟡 Status: STOPPING"
    echo "   Instance is shutting down cleanly..."
    ;;
  "pending")
    echo "🟡 Status: PENDING"
    echo "   Instance is booting up..."
    ;;
  *)
    echo "⚪ Status: ${STATE}"
    ;;
esac
echo "============================================================"
