#!/usr/bin/env bash
# Common safety checks for TravelMemory project scripts.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF="$ROOT/terraform"
ANSIBLE="$ROOT/ansible"
KEY="$HOME/.ssh/travelmemory-aws-key"
export AWS_PROFILE=travelmemory-deploy
export AWS_DEFAULT_REGION=ap-south-1
EXPECTED_ACCOUNT=829290477642
EXPECTED_ARN="arn:aws:iam::${EXPECTED_ACCOUNT}:user/travelmemory-admin"
BUDGET_NAME=TravelMemory-Lab-Budget

fail() { printf '\nERROR: %s\n' "$*" >&2; exit 1; }
info() { printf '\n==> %s\n' "$*"; }
require() { command -v "$1" >/dev/null 2>&1 || fail "Missing: $1"; }
aws_check() {
    require aws
    if [[ -n "${AWS_ACCESS_KEY_ID:-}" || -n "${AWS_SECRET_ACCESS_KEY:-}" || -n "${AWS_SESSION_TOKEN:-}" ]]; then
      fail 'AWS credential environment variables are set. Unset them first; use the travelmemory-deploy login profile.'
    fi
    local arn
    arn="$(aws sts get-caller-identity --query Arn --output text 2>/dev/null)" || fail 'AWS login missing or expired. Run: aws login --profile travelmemory-deploy --region ap-south-1 --remote'
    [[ "$arn" == "$EXPECTED_ARN" ]] || fail "Wrong AWS identity: $arn. Expected $EXPECTED_ARN"
    info 'AWS identity verified: IAM user travelmemory-admin, new account ending 7642'
}

project_check() {
    [[ -f "$TF/main.tf" && -f "$TF/terraform.tfvars" && -f "$ANSIBLE/site.yml" ]] || fail 'Run this from the original extracted TravelMemory project; essential files are missing.'
    [[ -f "$KEY" && -f "$KEY.pub" ]] || fail "Missing SSH key pair at $KEY and $KEY.pub"
    local mode
    mode="$(stat -c %a "$KEY")"
    [[ "$mode" == 600 || "$mode" == 400 ]] || fail "SSH private key permissions $mode are unsafe. Run chmod 600 '$KEY'"
    local key_name
    key_name="$(aws ec2 describe-key-pairs --key-names travelmemory-aws-key --region ap-south-1 --query 'KeyPairs[0].KeyName' --output text 2>/dev/null)" || fail 'EC2 key pair travelmemory-aws-key not found in Mumbai'
    [[ "$key_name" == travelmemory-aws-key ]] || fail 'Unexpected EC2 key name'
    info 'EC2 SSH public key confirmed in Mumbai'
}

check_budget() {
    info 'Checking AWS budget (the budget is an alert, NOT a spending cap)'
    if aws budgets describe-budget --account-id "$EXPECTED_ACCOUNT" --budget-name "$BUDGET_NAME" \
         --query 'Budget.[BudgetName,BudgetLimit.Amount,BudgetLimit.Unit]' --output text; then
      local notices
      if notices="$(aws budgets describe-notifications-for-budget --account-id "$EXPECTED_ACCOUNT" --budget-name "$BUDGET_NAME" --query 'Notifications | length(@)' --output text 2>/dev/null)"; then
        if [[ "$notices" == 0 ]]; then
          echo 'WARNING: no budget notifications are configured. Configure AND verify email alerts in AWS Budgets.' >&2
        else
          echo "Budget notification rules: $notices. Check that your recipient email is verified."
        fi
      else
        echo 'Could not check notification rules via CLI; confirm email alerts in AWS Console.'
      fi
    else
      echo 'WARNING: Could not read the AWS budget. Confirm the $12 budget and email alerts in the console.' >&2
    fi
}
