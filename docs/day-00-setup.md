# Day 00: Setting Up My AWS Docker Lab

## Why I Started This Project

When I decided to get serious about learning Docker, I didn't want to just run containers locally on my laptop. Local Docker Desktop works for quick experiments, but it does not prepare me for how containers actually run in production environments—on cloud virtual machines, behind firewalls, inside custom VPCs, and managed through automated pipelines.

At the same time, I knew AWS bills can easily get out of hand if you leave resources running 24/7 or if you don't track what you provision. I needed an environment that:
1. Gives me a real Linux server in the cloud (Ubuntu 24.04 LTS).
2. Provisions completely through Infrastructure as Code (Terraform) so I can recreate it anytime.
3. Automatically installs Docker, Docker Compose, Git, AWS CLI, and essential debugging tools on boot.
4. Allows me to stop the server every evening so I only pay pennies for storage while keeping all my container images, volumes, and work intact.

This log records how I built my lab from scratch on Day 0.

---

## Prerequisites I Installed on My Computer

Before running anything, I made sure my local workstation had the following tools installed and working:

1. **AWS CLI v2**:
   - Verified with: `aws --version`
   - Configured my credentials using `aws configure`:
     - AWS Access Key ID
     - AWS Secret Access Key
     - Default region name: `ap-south-1` (Mumbai)
     - Default output format: `json`
   - Tested my identity with: `aws sts get-caller-identity`

2. **Terraform (v1.5+)**:
   - Verified with: `terraform -version`

3. **Git**:
   - Verified with: `git --version`

4. **SSH Client**:
   - Standard OpenSSH client (built into Windows PowerShell, Linux, and macOS).

---

## Step-by-Step Initial Setup

### Step 1: Clone the Repository
```bash
git clone https://github.com/your-username/docker-learning-log.git
cd docker-learning-log
```

### Step 2: Configure Lab Variables
I created my personal `terraform.tfvars` from the example template:
```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
```

Inside `terraform/terraform.tfvars`, I set:
- `aws_region = "ap-south-1"`
- `instance_type = "t3.small"` (2 vCPUs, 2 GiB RAM—giving me enough headroom to run multi-container applications without out-of-memory errors)
- `root_volume_size = 20` (20 GiB gp3 SSD, which holds plenty of base Docker images like `ubuntu`, `python`, `node`, `nginx`, and `postgres`)
- `allowed_cidr = "0.0.0.0/0"` (or my specific public IP from `https://checkip.amazonaws.com` for stricter security)

### Step 3: Run the Creation Script
Instead of manually typing out multiple Terraform commands, I ran the automated script:

**On Linux / macOS / Git Bash:**
```bash
chmod +x scripts/*.sh
./scripts/create-lab.sh
```

**On Windows PowerShell:**
```powershell
.\scripts\create-lab.ps1
```

Here is what the script did under the hood:
1. Ran `terraform init` to download the AWS, TLS, and Local providers.
2. Ran `terraform validate` to check the syntax of my modular Terraform code.
3. Ran `terraform plan` to show me what resources would be created.
4. Prompted me for confirmation, then executed `terraform apply`.
5. Created the VPC, subnet, internet gateway, route tables, and security group.
6. Generated a 4096-bit RSA SSH key pair, saved the private key locally as `terraform/docker-learning-log-key.pem`, and registered the public key with AWS.
7. Launched the EC2 instance and triggered `user_data.sh`.

### Step 4: Wait for Cloud-Init / User-Data to Complete
When EC2 boots up for the very first time, the `user_data.sh` script runs in the background as `root`. It updates packages, installs Docker CE from the official Docker apt repository, installs Docker Compose, Git, AWS CLI, and adds the `ubuntu` user to the `docker` group.

I waited about 90 seconds for this bootstrap process to finish.

### Step 5: Connect and Verify Docker
I connected to the lab using the SSH script:

```bash
# On Linux/macOS/Git Bash:
./scripts/ssh-lab.sh

# On Windows PowerShell:
.\scripts\ssh-lab.ps1
```

Once connected, I saw the custom welcome banner and ran these verification checks:

```bash
# 1. Check Docker daemon status
systemctl status docker --no-pager

# 2. Check Docker and Compose versions
docker --version
docker compose version

# 3. Verify non-root access (running without sudo)
docker ps

# 4. Run the classic hello-world container
docker run hello-world
```

The output printed:
```text
Hello from Docker!
This message shows that your installation appears to be working correctly.
```

I also checked `/var/log/user-data.log` on the instance to confirm all package installations succeeded without warnings:
```bash
cat /var/log/user-data.log | grep "Provisioning COMPLETED"
```

---

## Notes & Lessons Learned on Day 0

- **Why I chose `t3.small` instead of `t2.micro`**:
  While `t2.micro` is in the AWS Free Tier, it only has 1 GiB of RAM. The moment you run a database container (like PostgreSQL) alongside a backend app and an Nginx reverse proxy, 1 GiB runs out quickly and containers get killed by the Linux OOM (Out Of Memory) killer. `t3.small` gives me 2 vCPUs and 2 GiB RAM for about 2 cents an hour (~$0.0208/hr). Since I only run it 2 hours a day, it costs less than $1.30 per month in compute!
- **Auto-generated SSH Key**:
  Letting Terraform generate the SSH key with `tls_private_key` and output the `.pem` file directly into my repo (with `.gitignore` shielding it) made the onboarding frictionless. I didn't need to manually visit the AWS EC2 console to download a key.
- **Docker Group Membership**:
  Adding `ubuntu` to the `docker` group during user-data means I don't have to prepend `sudo` before every single `docker` command, which matches standard DevOps production environments.
