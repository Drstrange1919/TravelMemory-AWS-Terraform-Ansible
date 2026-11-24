#!/usr/bin/env bash
# Deploy TravelMemory infrastructure and app with an explicit billing confirmation.
set -Eeuo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

bash "$ROOT/scripts/preflight.sh"

info 'Building a SAVED Terraform plan; this does NOT create AWS infrastructure'
cd "$TF"
terraform plan -input=false -out=tfplan -no-color >/dev/null
chmod 600 tfplan
terraform show -json tfplan | python3 "$ROOT/scripts/plan_summary.py"
printf '\nCOST WARNING: This lab provisions two EC2 servers, an AWS NAT Gateway, EBS volumes and public IPv4 addresses.\n'
printf 'They can consume AWS promotional credits every hour. A $12 budget is ONLY an alert, not a hard stop.\n'
printf 'Review the $12 budget email notifications in AWS before continuing.\n'
printf 'If provisioning fails midway, run bash scripts/cleanup.sh to delete partially created infrastructure.\n\n'
read -r -p 'Type DEPLOY to apply this Terraform plan and start incurring AWS usage charges: ' confirmation
[[ "$confirmation" == DEPLOY ]] || fail 'Deployment cancelled. Plan is saved at terraform/tfplan.'

info 'Applying saved Terraform plan to NEW AWS account with IAM user travelmemory-admin'
terraform apply -input=false tfplan
info 'Creating dynamic Ansible inventory from AWS outputs'
terraform output -json > "$ANSIBLE/terraform-output.json"
chmod 600 "$ANSIBLE/terraform-output.json"
python3 "$ROOT/scripts/generate_inventory.py" --key "$KEY"

# SSH key has a passphrase in the user's setup. ssh-add will ask for it (not echoed).
info 'Starting a temporary SSH agent. If asked, enter the passphrase for your Ubuntu SSH key.'
eval "$(ssh-agent -s)" >/dev/null
trap 'ssh-agent -k >/dev/null 2>&1 || true' EXIT
ssh-add "$KEY" || fail 'Could not unlock SSH key. The AWS infrastructure remains running; rerun this script after fixing SSH.'

info 'Testing SSH to both EC2 servers through the public web EC2 jump host'
cd "$ANSIBLE"
connected=false
for attempt in $(seq 1 15); do
    if ansible all -m ping >/dev/null 2>&1; then connected=true; break; fi
    echo "SSH connection not ready yet; attempt ${attempt}/15"
    sleep 20
done
if [[ "$connected" != true ]]; then
    echo 'SSH test failed; run: cd ansible && ansible all -m ping'
    fail 'Infrastructure is running and may cost money. Fix SSH or run bash scripts/cleanup.sh from project root.'
fi
ansible all -m ping

info 'Preparing distinct MongoDB passwords (stored only locally with private permissions)'
secret_file="$ROOT/.travelmemory-secrets"
if [[ -f "$secret_file" ]]; then
    [[ "$(stat -c %a "$secret_file")" == 600 ]] || fail "Unsafe permissions on $secret_file. Run: chmod 600 '$secret_file'"
    # A previously saved app/database needs the ORIGINAL passwords on every re-run.
    source "$secret_file"
else
    umask 077
    MONGO_ADMIN_PASSWORD="$(python3 -c 'import secrets;print(secrets.token_hex(24))')"
    MONGO_APP_PASSWORD="$(python3 -c 'import secrets;print(secrets.token_hex(24))')"
    printf 'MONGO_ADMIN_PASSWORD=%q\nMONGO_APP_PASSWORD=%q\n' "$MONGO_ADMIN_PASSWORD" "$MONGO_APP_PASSWORD" > "$secret_file"
    chmod 600 "$secret_file"
fi
export MONGO_ADMIN_PASSWORD MONGO_APP_PASSWORD

info 'Ansible: configure private MongoDB first, then deploy the Express backend and React frontend'
ansible-playbook site.yml

info 'Checking deployed application'
bash "$ROOT/scripts/verify.sh"
info 'Deployment completed. Capture your assignment screenshots, then run bash scripts/cleanup.sh when finished.'
