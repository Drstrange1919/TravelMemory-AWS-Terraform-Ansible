#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
info 'TravelMemory local + AWS deployment preflight (no billable resources created)'
for cmd in terraform ansible ansible-playbook python3 curl ssh-add aws; do require "$cmd"; done
aws_check
project_check
python3 "$ROOT/scripts/sync_public_ip.py"
check_budget
info 'Validating Terraform configuration'
cd "$TF"
terraform init -input=false -no-color >/dev/null
terraform fmt -check || fail 'Terraform formatting issue; run: cd terraform && terraform fmt'
terraform validate -no-color
info 'Current EC2 sizes from terraform.tfvars'
grep -E '^[[:space:]]*(web_instance_type|db_instance_type|aws_region|admin_ip_cidr|key_name)[[:space:]]*=' "$TF/terraform.tfvars"
if ! grep -Eq '^[[:space:]]*web_instance_type[[:space:]]*=[[:space:]]*"t3.small"' "$TF/terraform.tfvars" || \
   ! grep -Eq '^[[:space:]]*db_instance_type[[:space:]]*=[[:space:]]*"t3.small"' "$TF/terraform.tfvars"; then
    fail 'Both EC2 sizes must be t3.small for this low-cost kit. Edit terraform/terraform.tfvars and rerun.'
fi
info 'Preflight passed. No infrastructure was created by this script.'
