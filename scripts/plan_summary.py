#!/usr/bin/env python3
"""Safe human-readable summary of a Terraform plan JSON stream; no secrets printed."""
import sys, json, collections
p = json.load(sys.stdin)
changes = [r for r in p.get('resource_changes', []) if any(a in r['change']['actions'] for a in ('create','delete','update'))]
count = collections.Counter()
for r in changes:
    actions = ','.join(r['change']['actions'])
    count[(r['type'],actions)] += 1
print('\nResource changes by type:')
for (kind,actions), n in sorted(count.items()): print(f'  {kind:44} {actions:18} {n}')
print('\nEC2 instances:')
for r in changes:
    if r['type'] == 'aws_instance':
        aft = r['change'].get('after') or {}
        print(f"  {r['address']}: {aft.get('instance_type','unknown')} (AMI may resolve after apply)")
print('\nNAT gateways:', sum(1 for r in changes if r['type']=='aws_nat_gateway' and 'create' in r['change']['actions']))
print('Total resources with changes:', len(changes))
