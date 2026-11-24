#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
aws_check
[[ -f "$TF/terraform.tfstate" ]] || fail 'No local Terraform state found; deploy first.'
cd "$TF"
web_ip="$(terraform output -raw web_public_ip)"
db_ip="$(terraform output -raw db_private_ip)"
url="http://${web_ip}"
info "Web public endpoint: $url"
info "DB private IP: $db_ip (do NOT expose port 27017 publicly)"
info 'Checking application response and database-dependent health endpoint'
curl --connect-timeout 12 --max-time 25 -fsSI "$url/" || fail 'Web page not responding: check Nginx status and security group'
curl --connect-timeout 12 --max-time 25 -fsS "$url/health" || fail 'Health check failed: check MongoDB and Node.js logs'
printf '\nVisit %s to test creating and viewing a TravelMemory trip.\n' "$url"
printf 'Take screenshots of: AWS VPC/subnets, both EC2 instances, Terraform outputs, Ansible success and the working website.\n'
