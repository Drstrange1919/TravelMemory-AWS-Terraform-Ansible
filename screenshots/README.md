# Screenshot checklist for assignment

Add your REAL screenshots after deployment. The project generator did not deploy to your AWS account, so there are no fabricated screenshots.

1. `01-terraform-apply.png` - `terraform apply` completion and resource count (hide account data as needed).
2. `02-vpc-subnets.png` - VPC and public/private subnet names.
3. `03-ec2-instances.png` - running EC2 web and DB (private DB with no public IPv4).
4. `04-security-groups.png` - web SSH restricted to your /32; MongoDB 27017 only from web SG.
5. `05-ansible-recap.png` - successful `ansible-playbook` recap.
6. `06-travelmemory-home.png` - app homepage opened by public EC2 IP.
7. `07-create-travel-memory.png` - new trip entry saved via UI.
8. `08-trip-list.png` - saved entry visible after refresh (proves persistence).
9. `09-api-health.png` - `/health` JSON showing `db: connected`.

Avoid screenshots that show any private key, AWS secret, MongoDB password, or Terraform state.
