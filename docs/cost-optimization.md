# Cost Optimization Strategy & Analysis

One of the primary goals of this project was to build a real cloud learning environment without getting surprise bills from AWS at the end of the month.

Many tutorials suggest either leaving an EC2 instance running 24/7 or taking an AMI snapshot at the end of each day and destroying the instance. In this document, I break down why both of those approaches are flawed and why the **Start/Stop EC2 workflow** is the most cost-effective and practical strategy for daily learning.

---

## 1. Why Start/Stop EC2 Beats the "Daily AMI" Workflow

Some people recommend creating a custom Amazon Machine Image (AMI) at the end of each study session, terminating the instance, and then launching a new instance from that AMI the next day. Here is why that workflow creates unnecessary overhead and higher costs:

| Factor | Daily AMI Creation Workflow | Start / Stop EC2 Workflow (This Project) | Winner |
|---|---|---|---|
| **Daily Effort** | High. Must create AMI, wait 5–10 mins, register AMI, terminate instance, update Terraform state or launch parameters next day. | Zero effort. Single script command: `./scripts/stop-lab.sh` and `./scripts/start-lab.sh`. | **Start/Stop** |
| **Time to Resume** | 5–10 minutes (waiting for AMI registration, provisioning new instance, binding IPs). | 15–30 seconds (EC2 switches from `stopped` to `running`). | **Start/Stop** |
| **Storage Cost** | Higher. Storing multiple AMIs and snapshot blocks on S3 accumulates storage costs and requires manual pruning. | Predictable and minimal. Exactly one 20 GiB gp3 volume. | **Start/Stop** |
| **Terraform State** | Messy. Constantly terminating and recreating instances alters Terraform state and requires complex dynamic AMI management. | Clean. Terraform manages the infrastructure once (`terraform apply`), then hands off daily lifecycle to AWS CLI. | **Start/Stop** |
| **Risk of Data Loss** | High. Forgetting to take an AMI before terminating destroys all uncommitted containers, images, and notes. | Very low. The EBS root volume remains safely attached in AWS; stopping an instance never deletes volume data. | **Start/Stop** |

---

## 2. AWS Cost Breakdown: Running vs. Stopped

Let's look at the actual pricing numbers in `ap-south-1` (Mumbai) for a `t3.small` instance with a 20 GiB gp3 root volume:

### Cost Components
- **`t3.small` Compute (2 vCPU, 2 GiB RAM)**: ~$0.0208 per hour
- **Public IPv4 Address (while running)**: ~$0.005 per hour (AWS charges for all public IPv4 addresses since Feb 2024)
- **gp3 EBS Storage (20 GiB)**: $0.08 per GiB-month = **$1.60 per month** (~$0.053 per day)

---

### Scenario A: Leaving EC2 Running 24/7 (30 Days)
If you forget to stop the server and leave it running all month:

- Compute: `720 hours * $0.0208` = **$14.98**
- Public IPv4: `720 hours * $0.005` = **$3.60**
- EBS Storage: `20 GiB * $0.08` = **$1.60**
- **Total Monthly Cost**: **~$20.18 / month**

---

### Scenario B: Our Daily Start/Stop Routine (2 Hours/Day, 30 Days)
If you practice 2 hours every evening and stop the server when done:

- Compute: `60 hours * $0.0208` = **$1.25**
- Public IPv4: `60 hours * $0.005` = **$0.30**
- EBS Storage: `20 GiB * $0.08` = **$1.60** (storage costs continue while stopped)
- **Total Monthly Cost**: **~$3.15 / month**

### 💰 Savings:
By stopping the instance when not in use, I save **over 84%** of the monthly bill, reducing my learning cost from ~$20 down to roughly **$3.15 per month** (less than the price of a cup of coffee)!

---

## 3. What Resources Continue Costing Money When Stopped?

It is critical to understand what AWS charges for when an EC2 instance is in the `stopped` state:

### ❌ What is FREE ($0.00) while stopped:
1. **EC2 Compute**: You are **not** billed for vCPU or RAM while an instance is stopped.
2. **Public IPv4 Address**: When an EC2 instance without an Elastic IP is stopped, AWS releases the dynamic public IP back into their pool. Because the IP is released, **you are not billed for public IPv4 while stopped**.
3. **Data Transfer**: Zero incoming or outgoing network traffic, so $0.00.

### ⚠️ What continues to cost money while stopped:
1. **EBS Volume Storage**: The root volume (20 GiB gp3) remains allocated in the AWS availability zone so that all your Docker images, containers, and Linux files are preserved.
   - 20 GiB × $0.08 / GiB-month = **$1.60 / month** (or roughly **$0.05 per day**).
2. **Elastic IPs (Why I deliberately avoided them)**:
   - If you allocate an Elastic IP (static public IP) and attach it to a stopped instance, AWS charges **$0.005 per hour** for an idle allocated IP (~$3.60/month).
   - **My architectural decision**: I chose **NOT** to use an Elastic IP. Instead, my `start-lab.sh` and `ssh-lab.sh` scripts automatically query the newly allocated dynamic public IP when the instance boots up. This completely eliminates idle Elastic IP charges!

---

## 4. Why This Project is Ideal for Learning DevOps Core Skills

This project isn't just about Docker; it forms an integrated hands-on DevOps foundation:

### 1. Docker
- Practice building multi-stage Dockerfiles.
- Experiment with bind mounts, named volumes, and persistent storage.
- Run multi-container setups using Docker Compose.
- Inspect container networking (`bridge`, `host`, custom networks) and port mappings.
- Clean up unused layers and dangling images with `docker system prune`.

### 2. Terraform (Infrastructure as Code)
- Learn modular Terraform architecture (`network`, `security`, `ec2`).
- Manage input variables, outputs, and local variables.
- Use dynamic data sources (`aws_ami`) to fetch the latest official Ubuntu release.
- Automate cryptographic keys (`tls_private_key`, `local_file`) directly within Terraform.
- Understand the complete resource lifecycle (`init`, `plan`, `apply`, `destroy`).

### 3. Linux Administration
- Work inside Ubuntu 24.04 LTS via SSH.
- Understand user permissions, POSIX groups, and granting non-root container management (`usermod -aG docker ubuntu`).
- Inspect system services with `systemctl` and read journal logs.
- Monitor resource consumption, memory, CPU, and disk space with `htop`, `df -h`, and `tree`.

### 4. AWS Cloud Engineering
- Master VPC networking fundamentals: subnets, CIDR blocks, route tables, and Internet Gateways.
- Build instance-level firewalls using Security Group ingress and egress rules.
- Leverage `user_data` (cloud-init) for automated server bootstrapping.
- Learn AWS CLI commands (`start-instances`, `stop-instances`, `describe-instances`, `wait`).

### 5. Git & DevOps Discipline
- Maintain an organized, professional GitHub repository with clear documentation and changelogs.
- Practice protecting sensitive credentials by crafting a strict `.gitignore` (ignoring `.tfstate`, private `.pem` keys, and local environment files).
- Build automated helper scripts in both Bash and PowerShell to eliminate repetitive manual tasks.
