#!/usr/bin/env bash
# Destroy ONLY the resources recorded in this TravelMemory Terraform state.
set -Eeuo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
aws_check
[[ -f "$TF/terraform.tfstate" ]] || fail 'Terraform state file not found. Do not attempt manual partial cleanup without checking AWS Console.'
cd "$TF"
info 'The following resources are tracked by this project (not the rest of your AWS account):'
terraform state list || true
printf '\nThis WILL DELETE the TravelMemory NAT Gateway, EC2 instances, volumes, VPC and other state-managed resources.\n'
printf 'Any TravelMemory data on the instances/volumes will be LOST.\n'
read -r -p 'Type DESTROY to remove the TravelMemory AWS infrastructure: ' confirmation
[[ "$confirmation" == DESTROY ]] || fail 'Cleanup cancelled. Resources continue billing.'
terraform destroy -input=false -auto-approve
info 'Terraform destroy completed. Confirm EC2 instances/NAT Gateway/EIP are gone in AWS Console.'
