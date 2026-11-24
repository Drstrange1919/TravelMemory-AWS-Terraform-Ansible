#!/usr/bin/env python3
"""Restrict SSH to the WSL public IPv4 /32, updating only terraform.tfvars."""
from pathlib import Path
import ipaddress, re, subprocess, sys
f = Path(__file__).resolve().parent.parent / 'terraform' / 'terraform.tfvars'
text = f.read_text(encoding='utf-8')
res = subprocess.run(['curl','-4','--max-time','15','-fsS','https://checkip.amazonaws.com'],capture_output=True,text=True)
if res.returncode:
    sys.exit('Cannot read your public IP. Check internet connection. Terraform settings unchanged.')
ip = str(ipaddress.IPv4Address(res.stdout.strip()))
pat = re.compile(r'(?m)^(\s*admin_ip_cidr\s*=\s*)"([^"]+)"')
matches = list(pat.finditer(text))
if len(matches) != 1:
    sys.exit('Expected exactly one admin_ip_cidr line in terraform.tfvars. No file changes made.')
current = matches[0].group(2)
new = f'{ip}/32'
if current != new:
    text = pat.sub(lambda m: m.group(1) + '"' + new + '"', text, count=1)
    f.write_text(text,encoding='utf-8')
    print(f'SSH CIDR updated from {current} to {new} (only one public IP is allowed).')
else:
    print(f'SSH CIDR verified: {new}')
