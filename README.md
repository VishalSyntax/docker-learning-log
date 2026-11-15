# 🐳 Docker Learning Log on AWS

A cost-optimized, automated, Infrastructure-as-Code (Terraform) learning environment for mastering Docker and DevOps on AWS.

---

## 📌 Project Overview

This repository contains my personal hands-on laboratory for learning Docker on an Amazon Web Services (AWS) EC2 instance. Instead of running containers locally or manually setting up virtual machines in the AWS Management Console, I built this entire environment using **Terraform** and automated the daily lifecycle using **shell and PowerShell scripts**.

### Core Principles of This Lab:
- **Build Once, Use Daily**: The infrastructure is provisioned only once via Terraform.
- **Start / Stop Daily Lifecycle**: No need to terminate or create AMIs every day. The EC2 instance is started in the morning with a single command and stopped in the evening, keeping all containers, Docker images, and configuration intact while cutting monthly compute costs by >84%.
- **Zero Cost When Stopped (Compute & IP)**: While stopped, compute vCPU/RAM charges drop to **$0.00**, and dynamic public IPv4 addresses are released to avoid AWS IPv4 hourly charges.
- **Full Automation**: Includes one-click scripts in both Bash (`.sh`) and PowerShell (`.ps1`) for starting, stopping, SSHing, checking status, and tearing down the lab.

---

## 💡 Why I Created This Project

When I started learning Docker, I noticed two common pitfalls:
1. **Running Docker Desktop locally**: While convenient, running Docker on a local laptop does not teach cloud networking, firewall rules, remote SSH administration, or real-world Linux server environments.
2. **Leaving cloud instances running**: Running an EC2 instance 24/7 can quickly rack up unexpected AWS bills. On the other hand, tearing down the instance and recreating AMIs every day takes too much time, wastes bandwidth re-downloading container images, and introduces friction into daily learning.

I created this repository to solve both problems: a production-grade, modular cloud lab that starts in 20 seconds, preserves all my Docker layers between sessions, and costs approximately **$3.15 per month** when used for 2 hours a day.

---

## 🏛 Architecture Diagram

The lab provisions a dedicated, isolated Virtual Private Cloud (VPC) with public routing and security controls in `ap-south-1` (Mumbai):

```text
+-----------------------------------------------------------------------------------------+
|                                      AWS Cloud                                          |
|  Region: ap-south-1 (Mumbai)                                                            |
|                                                                                         |
|  +-----------------------------------------------------------------------------------+  |
|  | Custom VPC: 10.0.0.0/16 (docker-learning-log-vpc)                                 |  |
|  |                                                                                   |  |
|  |   +-----------------------------------------------------------------------------+ |  |
|  |   | Internet Gateway: docker-learning-log-igw                                   | |  |
|  |   | (Routes 0.0.0.0/0 traffic to/from the Public Internet)                      | |  |
|  |   +-----------------------------------------------------------------------------+ |  |
|  |                                          ▲                                        |  |
|  |                                          │                                        |  |
|  |   +-----------------------------------------------------------------------------+ |  |
|  |   | Route Table: docker-learning-log-public-rt                                  | |  |
|  |   | Destination: 0.0.0.0/0  -->  Target: igw-xxxxxxxx                           | |  |
|  |   +-----------------------------------------------------------------------------+ |  |
|  |                                          ▲                                        |  |
|  |                                          │ (Associated)                           |  |
|  |   +-----------------------------------------------------------------------------+ |  |
|  |   | Public Subnet: 10.0.1.0/24 (ap-south-1a)                                    | |  |
|  |   |                                                                             | |  |
|  |   |   +-----------------------------------------------------------------------+ | |  |
|  |   |   | Security Group: docker-learning-log-sg                                | | |  |
|  |   |   | Ingress Ports: 22 (SSH), 80/443 (Web), 8080, 8081, 3000, 5000         | | |  |
|  |   |   | Egress: All Outbound IPv4 (0.0.0.0/0)                                 | | |  |
|  |   |   |                                                                       | | |  |
|  |   |   |   +---------------------------------------------------------------+   | | |  |
|  |   |   |   | EC2 Instance: docker-learning-log-instance                    |   | | |  |
|  |   |   |   | • OS: Canonical Ubuntu 24.04 LTS (Noble Numbat)               |   | | |  |
|  |   |   |   | • Type: t3.small (2 vCPU, 2 GiB RAM)                          |   | | |  |
|  |   |   |   | • Dynamic Public IPv4 (auto-queried on start)                 |   | | |  |
|  |   |   |   | • Key Pair: 4096-bit RSA (auto-generated)                     |   | | |  |
|  |   |   |   |                                                               |   | | |  |
|  |   |   |   | Storage:                                                      |   | | |  |
|  |   |   |   | • 20 GiB gp3 Encrypted Root EBS Volume                        |   | | |  |
|  |   |   |   |   (Holds Docker images, containers, and notes)                |   | | |  |
|  |   |   |   +---------------------------------------------------------------+   | | |  |
|  |   |   +-----------------------------------------------------------------------+ | |  |
|  |   +-----------------------------------------------------------------------------+ |  |
|  +-----------------------------------------------------------------------------------+  |
+-----------------------------------------------------------------------------------------+
                                          ▲
                                          │ SSH (Port 22) / HTTP & Container Ports
                                          │
                            +-----------------------------+
                            | Local Workstation (Admin)   |
                            | (PowerShell / Bash Scripts) |
                            +-----------------------------+
```

---

## 📁 Repository Structure

```text
docker-learning-log/
├── terraform/
│   ├── modules/
│   │   ├── network/                  # VPC, Subnet, Internet Gateway, Route Table
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   ├── security/                 # Security Group with Docker ingress ports
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   └── ec2/                      # AMI discovery, SSH key pair, EC2 instance, EBS
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   │
│   ├── main.tf                       # Module orchestration
│   ├── variables.tf                  # Root input variables
│   ├── outputs.tf                    # Root outputs (IP, Instance ID, SSH command)
│   ├── providers.tf                  # AWS provider and default tagging
│   ├── versions.tf                   # Terraform and provider version pins
│   ├── terraform.tfvars.example      # Config template
│   └── user_data.sh                  # Boot script (installs Docker, Compose, Git, AWS CLI)
│
├── scripts/
│   ├── create-lab.sh / .ps1          # Initializes and applies Terraform infrastructure
│   ├── start-lab.sh  / .ps1          # Starts EC2 and displays live dynamic IP
│   ├── stop-lab.sh   / .ps1          # Stops EC2 to pause compute and IPv4 billing
│   ├── ssh-lab.sh    / .ps1          # Automatically connects via SSH to running instance
│   ├── status.sh     / .ps1          # Checks current instance state and metadata
│   └── destroy-lab.sh / .ps1         # Tears down all AWS resources safely
│
├── docs/
│   ├── day-00-setup.md               # First-day setup log and verification steps
│   ├── daily-workflow.md             # Morning, evening, and recovery procedures
│   ├── architecture.md               # Deep dive into network and security architecture
│   └── cost-optimization.md          # Cost calculations and Start/Stop vs AMI analysis
│
├── screenshots/                      # Architecture diagrams and terminal outputs
│   └── .gitkeep
│
├── .gitignore                        # Excludes state files, keys (.pem), secrets
├── LICENSE                           # MIT License
├── README.md                         # Project documentation
└── prompt.md                         # Project blueprint and requirements
```

---

## 🛠 Tools Used

- **Cloud**: Amazon Web Services (AWS) — VPC, EC2, EBS (gp3), Internet Gateway, Security Groups.
- **Infrastructure as Code**: Terraform (v1.5+).
- **Operating System**: Ubuntu 24.04 LTS (Noble Numbat).
- **Container Engine**: Docker CE (latest) with Docker Compose V2 plugin.
- **Command Line**: AWS CLI v2, OpenSSH, Bash, PowerShell 7+.
- **Version Control**: Git & GitHub.
- **Admin Utilities**: `htop`, `tree`, `curl`, `wget`, `vim`, `nano`, `unzip`.

---

## 🚀 Setup Steps (Day 0)

### 1. Configure AWS CLI
Ensure your local machine has AWS credentials configured:
```bash
aws configure
aws sts get-caller-identity
```

### 2. Clone the Repository
```bash
git clone https://github.com/VishalSyntax/docker-learning-log.git
cd docker-learning-log
```

### 3. Customize Variables
Copy the example variables file:
```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
```
*(Optionally review `terraform/terraform.tfvars` to change region, instance type, or restrict your allowed IP address.)*

### 4. Create the Lab Infrastructure
Run the automated creation script:

**On Linux / macOS / Git Bash:**
```bash
chmod +x scripts/*.sh
./scripts/create-lab.sh
```

**On Windows PowerShell:**
```powershell
.\scripts\create-lab.ps1
```

The script runs `terraform init`, `terraform validate`, `terraform plan`, asks for your confirmation, and applies the plan. It also saves the generated private key (`docker-learning-log-key.pem`) locally.

---

## ⚙️ Terraform Commands

If you prefer to run raw Terraform commands directly inside the `terraform/` folder:

```bash
cd terraform

# Initialize providers and modules
terraform init

# Validate configuration syntax
terraform validate

# Review execution plan
terraform plan

# Apply infrastructure changes
terraform apply

# View current outputs (Instance ID, IP, SSH command)
terraform output

# Tear down all resources
terraform destroy
```

---

## 📅 Daily Workflow

### 🌅 Start Learning
```bash
# 1. Start the EC2 instance
./scripts/start-lab.sh        # or .\scripts\start-lab.ps1

# 2. Connect via SSH
./scripts/ssh-lab.sh          # or .\scripts\ssh-lab.ps1
```

Inside the instance, your Docker images, containers, and workspace (`~/workspace`) are exactly where you left them:
```bash
cd ~/workspace
docker ps -a
docker images
```

### 🌙 Wrap Up & Stop Billing
```bash
# 1. Push any notes/code to your Git repository
git add . && git commit -m "My daily Docker progress" && git push

# 2. Exit the SSH session
exit

# 3. Stop the instance to pause AWS compute charges
./scripts/stop-lab.sh         # or .\scripts\stop-lab.ps1
```

### 🔍 Check Status Anytime
```bash
./scripts/status.sh           # or .\scripts\status.ps1
```

---

## 💰 Cost Optimization Strategy

| State | Compute (vCPU / RAM) | Public IPv4 Address | 20 GiB gp3 Storage | Total Monthly (Est.) |
|---|---|---|---|---|
| **Running 24/7** | $14.98 | $3.60 | $1.60 | **~$20.18 / mo** |
| **Start/Stop (2 hrs/day)** | **$1.25** | **$0.30** | **$1.60** | **~$3.15 / mo** |

### Why This Architecture Saves Money:
1. **Compute Pauses**: When the instance is stopped, AWS charges $0.00 for EC2 compute.
2. **No Idle Elastic IP Fees**: Instead of paying $0.005/hr for an idle Elastic IP, we use dynamic public IPv4 and our automation scripts auto-query the new IP when the instance boots.
3. **No Redundant AMI Storage**: We don't accumulate snapshot fees by taking daily AMIs. The single 20 GiB gp3 volume persists all data safely for ~$0.05/day.

*(For detailed breakdowns and comparison tables, see [docs/cost-optimization.md](docs/cost-optimization.md).)*

---

## 🔧 Troubleshooting

### 1. SSH Fails with "Permission denied (publickey)"
- Verify the instance is in the `running` state: `./scripts/status.sh`
- On Linux/macOS, check permissions on the `.pem` file: `chmod 400 terraform/docker-learning-log-key.pem`
- On Windows, the PowerShell script automatically fixes file ACLs using `icacls`.

### 2. `docker ps` returns "Permission denied while trying to connect to the Docker daemon"
- On initial launch, user-data adds `ubuntu` to the `docker` group.
- If you logged in before user-data completed, log out and reconnect (`exit` and `./scripts/ssh-lab.sh`) or run `newgrp docker`.

### 3. Check User-Data Installation Progress
To verify that the bootstrap script completed successfully on the instance:
```bash
cat /var/log/user-data.log
cat /var/log/user-data-completed
```

### 4. Container Port Unreachable in Browser
- Check that your container is bound to `0.0.0.0` (e.g., `docker run -d -p 8080:80 nginx`).
- Ensure the port is allowed in `terraform/modules/security/main.tf` (ports 22, 80, 443, 8080, 8081, 3000, and 5000 are pre-configured).

---

## 🎯 Future Learning Goals

- [x] Day 0: Infrastructure provisioning with Terraform & Docker bootstrap.
- [ ] Day 1: Docker CLI basics (`run`, `ps`, `exec`, `logs`, `stop`, `rm`).
- [ ] Day 2: Building custom Dockerfiles and optimizing image layers.
- [ ] Day 3: Multi-stage Docker builds for smaller, production-ready images.
- [ ] Day 4: Docker storage deep dive: bind mounts vs named volumes.
- [ ] Day 5: Container networking: bridge networks, DNS resolution, and port mapping.
- [ ] Day 6: Multi-container applications using Docker Compose (App + Redis + PostgreSQL).
- [ ] Day 7: Container security, non-root user execution, and vulnerability scanning.
- [ ] Day 8: Pushing images to Amazon Elastic Container Registry (ECR).
- [ ] Day 9: Transitioning from single-node Docker to container orchestration (ECS / EKS / K3s).

---

## 📜 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
