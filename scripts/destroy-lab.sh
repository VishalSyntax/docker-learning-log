#!/usr/bin/env bash
# ==============================================================================
# destroy-lab.sh - Tear down and remove all Docker Learning Lab infrastructure
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$(cd "${SCRIPT_DIR}/../terraform" && pwd)"

echo "============================================================"
echo "      ⚠️  DANGER ZONE: Destroy Docker Learning Lab          "
echo "============================================================"
echo "This will permanently terminate the EC2 instance, delete the"
echo "EBS volume, and remove all VPC networking components."
echo ""
echo "⚠️  ALL UNCOMMITTED DOCKER LAB DATA AND CONTAINERS WILL BE LOST!"
echo "Make sure you have pushed all your code & notes to GitHub."
echo "============================================================"
echo ""

read -rp "To confirm destruction, please type 'destroy': " CONFIRMATION

if [[ "${CONFIRMATION}" != "destroy" ]]; then
  echo "Confirmation mismatched. Aborting destroy process."
  exit 0
fi

echo ""
echo "▶ Proceeding with Terraform destruction..."
cd "${TERRAFORM_DIR}"
terraform destroy

echo ""
echo "============================================================"
echo "  ✅ All Docker Learning Lab cloud resources destroyed."
echo "  AWS billing for this lab is now completely stopped ($0.00)."
echo "============================================================"
