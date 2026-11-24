# Deployment of a MERN Application using Terraform and Ansible on AWS

**Course assignment:** Deployment of MERN TravelMemory application on AWS
**Author:** [YOUR NAME]
**Date completed:** [DATE]
**GitHub repository:** [YOUR GITHUB REPOSITORY URL]
**Deployment status:** **PENDING LIVE AWS TEST — replace this only after successful deployment**

---

## 1. Objective

Deploy the assigned [TravelMemory](https://github.com/UnpredictablePrashant/TravelMemory) MERN application on Amazon Web Services. Use Terraform to build the infrastructure and Ansible to install, configure and deploy the MongoDB, Express, React and Node.js components. Demonstrate that a browser can save and retrieve travel memories.

## 2. Technologies

| Layer | Technology | Responsibility |
|---|---|---|
| Infrastructure as code | Terraform | VPC, subnets, routes, NAT Gateway, EC2, security and IAM |
| Cloud provider | AWS | Compute/network infrastructure |
| Configuration management | Ansible | Configure the two EC2 servers and application deployment |
| Web server | Nginx | Serves React SPA and proxies API endpoints |
| Backend | Node.js + Express | Handles HTTP API requests |
| Frontend | React | Provides travel memory user interface |
| Database | MongoDB 8 | Stores submitted trip data |
| Operating system | Ubuntu 24.04 | Runs web and MongoDB instances |

## 3. Proposed architecture

```text
Browser -> EC2 public IP, port 80 -> Nginx -> React files
                                          -> Express API :3001
                                                |
                                                v
                                        MongoDB :27017
                                        (private subnet)

Internet Gateway -> public subnet -> web EC2 (bastion)
NAT Gateway -> private subnet outbound package updates
SSH: local computer -> web public IP -> DB private IP (ProxyJump)
```

- AWS VPC CIDR: `10.20.0.0/16`.
- Public subnet: `10.20.1.0/24` with an Internet Gateway default route.
- Private subnet: `10.20.2.0/24` with an outbound NAT Gateway default route.
- A public web EC2 instance contains Nginx, Node/Express and the compiled React application.
- A private database EC2 instance contains MongoDB with authentication; it has no public IPv4.
- The web security group permits inbound HTTP 80 globally and SSH 22 only from the administrator's `/32` IP.
- The database security group permits 27017 and SSH 22 from the web instance's security group only.
- The instances attach an IAM instance profile with managed Systems Manager permissions.

## 4. Terraform implementation

Terraform files are in `terraform/`. The project defines provider requirements, user-supplied region/IP/key values, VPC, subnets, route tables, gateways, security groups, IAM role/profile, two encrypted EBS-backed EC2 instances and useful outputs. Official Canonical Ubuntu 24.04 x86_64 AMIs are selected via AWS provider filters. EC2 metadata uses IMDSv2.

**Commands executed:**

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
terraform output
```

**Record actual infrastructure evidence:**

| Resource | ID / IP / name after deployment |
|---|---|
| AWS region | [FILL] |
| VPC ID | [FILL] |
| Web instance ID | [FILL] |
| Web public IPv4 | [FILL] |
| DB instance ID | [FILL] |
| DB private IPv4 | [FILL] |
| NAT Gateway ID | [FILL] |

**Screenshot:** `screenshots/01-terraform-apply.png` and `02-vpc-subnets.png`.

## 5. Ansible configuration

Ansible config `ansible/site.yml` runs the database play first, then the web play.

**Database tasks**

1. Install MongoDB official Community Edition 8 packages on private Ubuntu.
2. Bootstrap one admin user (`tm_admin`) and one application user (`tm_app`) with `readWrite` access to the `travelmemory` database.
3. Enable MongoDB authentication and bind only to localhost and the instance's private IP.
4. Start and enable `mongod` with systemd.

**Web tasks**

1. Install official Node.js 22 packages, Git and Nginx.
2. Clone the given TravelMemory repository into `/opt/travelmemory`.
3. Install Express backend dependencies, provide an authenticated private MongoDB URI in a protected `.env` file, and start backend using systemd.
4. Set `REACT_APP_BACKEND_URL=http://WEB_PUBLIC_IP` for React; install dependencies and compile a production build.
5. Copy build assets to `/var/www/travelmemory` and set up Nginx reverse proxy for `/trip`, `/uploads`, `/health` and `/hello`.
6. Verify end-to-end HTTP `/health` response with Ansible.

**Commands executed:**

```bash
terraform output -json > ../ansible/terraform-output.json
python3 scripts/generate_inventory.py --key ~/.ssh/travelmemory-aws-key.pem
cd ansible
ansible all -m ping
# Read the README for non-echoed password input.
ansible-playbook site.yml
```

**Screenshot:** `screenshots/05-ansible-recap.png`.

## 6. Application flow and component interaction

1. The user's browser requests `http://WEB_PUBLIC_IP/`.
2. Nginx returns the prebuilt React application.
3. React sends GET/POST requests to paths such as `/trip` on the same public origin.
4. Nginx proxies the requests to Express at `127.0.0.1:3001` on the web instance.
5. Express uses Mongoose and its `MONGO_URI` to authenticate to MongoDB on `10.20.2.x:27017`.
6. MongoDB returns trip data to Express, which sends JSON back through Nginx to React.
7. After refresh, saved trip data remains available in the database.

## 7. Security controls and limitations

- Restrict administrator SSH to a single public IP (`/32`).
- Do not expose MongoDB or Node API ports publicly; Nginx exposes only HTTP 80.
- Access private database SSH through the web EC2 jump host; private key remains on the administrator's computer.
- Enforce MongoDB authorization and least-privilege application user.
- Store MongoDB passwords outside version control (in local environment variables and restricted config on the web EC2).
- Encrypt root EBS volumes and require IMDSv2.
- **Lab limitation:** HTTP-only website (no TLS certificate or domain). This is for learning and not a fully production-hardened service. There is no high availability, backups or automatic failover.

## 8. Testing and demonstration (fill after LIVE deployment)

| Verification | Expected result | Actual result / evidence |
|---|---|---|
| Terraform apply | Resources created | [PENDING] |
| Both SSH targets | `pong` | [PENDING] |
| Web homepage | React UI displays | [PENDING] |
| Create new trip | Success / saved | [PENDING] |
| Refresh trip listing | Trip persists | [PENDING] |
| `GET /health` | `{"status":"ok","db":"connected"}` | [PENDING] |
| DB public IPv4 | Not assigned | [PENDING] |
| Web SSH ingress | Your `/32` only | [PENDING] |

**Screenshots to insert:**

- `[INSERT: screenshots/03-ec2-instances.png]`
- `[INSERT: screenshots/04-security-groups.png]`
- `[INSERT: screenshots/06-travelmemory-home.png]`
- `[INSERT: screenshots/07-create-travel-memory.png]`
- `[INSERT: screenshots/08-trip-list.png]`
- `[INSERT: screenshots/09-api-health.png]`

## 9. Issues encountered and resolution

Record actual problems and how you resolved them, with commands and screenshots. Do **not** invent issues or success results.

- Issue: [FILL]
- Cause: [FILL]
- Resolution and retest: [FILL]

## 10. Cleanup and costs

The NAT Gateway, Elastic IP, EC2 and storage may all incur charges. A budget alert should be configured before deployment. Once screenshots have been captured and the assignment is done, run `terraform destroy`, confirm that AWS resources were deleted, and note that removing the database volume destroys the test data.

**Final cleanup date/time:** [FILL]

## 11. Conclusion

**Complete after real verification:** Describe whether TravelMemory was successfully deployed, how Terraform and Ansible worked together, how React/Express/MongoDB communicated, what you learned, and any remaining limitations. Avoid describing an unverified deployment as completed.

## 12. References

- Assigned source code: https://github.com/UnpredictablePrashant/TravelMemory
- MongoDB install: https://www.mongodb.com/docs/v8.0/tutorial/install-mongodb-on-ubuntu/
- Terraform AWS tutorial: https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-create
- AWS NAT pricing: https://docs.aws.amazon.com/vpc/latest/userguide/nat-gateway-pricing.html
