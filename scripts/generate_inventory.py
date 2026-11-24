#!/usr/bin/env python3
"""Convert Terraform outputs to a 2-host Ansible inventory + SSH jump config."""
import argparse
import json
from pathlib import Path
import ipaddress

ROOT = Path(__file__).resolve().parent.parent
p = argparse.ArgumentParser(description=__doc__)
p.add_argument('--output-json', default=str(ROOT / 'ansible' / 'terraform-output.json'))
p.add_argument('--key', default='~/.ssh/travelmemory-aws-key.pem', help='Path to private PEM key')
args = p.parse_args()

outputs = json.loads(Path(args.output_json).read_text(encoding='utf-8'))
web_ip = str(ipaddress.IPv4Address(outputs['web_public_ip']['value']))
db_ip = str(ipaddress.IPv4Address(outputs['db_private_ip']['value']))
key = Path(args.key).expanduser().resolve()
if not key.is_file():
    p.error(f'Private key does not exist: {key} (copy it from Windows Downloads to ~/.ssh first)')
ansible = ROOT / 'ansible'
config = (ansible / 'ssh_config').resolve()
ssh_content = f"""Host {web_ip}
    HostName {web_ip}
    User ubuntu
    IdentityFile {key}
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new

Host {db_ip}
    HostName {db_ip}
    User ubuntu
    IdentityFile {key}
    IdentitiesOnly yes
    ProxyJump ubuntu@{web_ip}
    StrictHostKeyChecking accept-new
"""
config.write_text(ssh_content, encoding='utf-8')
config.chmod(0o600)
inventory = f"""[web]
web1 ansible_host={web_ip}

[database]
db1 ansible_host={db_ip}

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file={key}
ansible_ssh_common_args='-F {config}'
"""
(ansible / 'inventory.ini').write_text(inventory, encoding='utf-8')
print(f'Inventory created: {ansible / "inventory.ini"}')
print(f'SSH jump configuration created: {config}')
print(f'Web IP: {web_ip} | DB private IP: {db_ip} | Key: {key}')
print('NEXT: cd ansible && ansible all -m ping')
