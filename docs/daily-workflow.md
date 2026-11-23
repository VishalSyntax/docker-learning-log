# Daily Docker Learning Workflow

This document outlines my daily routine for studying Docker on AWS. The entire workflow is designed around simplicity, zero friction, and strict cost control. I don't need to rebuild infrastructure every morning or recreate AMIs; I just start my machine, do my hands-on practice, push my work, and turn it off.

---

## 🌅 Morning Routine: Starting the Lab

Whenever I'm ready to study, I open my terminal in this project repository and run:

### Step 1: Start the EC2 Instance
```bash
# On Linux / macOS / Git Bash:
./scripts/start-lab.sh

# On Windows PowerShell:
.\scripts\start-lab.ps1
```

**What happens behind the scenes**:
1. The script reads the EC2 `instance_id` directly from my local Terraform state.
2. It sends an API call via AWS CLI (`aws ec2 start-instances`).
3. It waits until AWS reports that the instance is in the `running` state (~15-30 seconds).
4. Because AWS assigns a dynamic public IPv4 upon starting an instance without an Elastic IP, the script automatically queries AWS for the newly assigned public IP and displays it on screen.

### Step 2: Connect via SSH
```bash
# On Linux / macOS / Git Bash:
./scripts/ssh-lab.sh

# On Windows PowerShell:
.\scripts\ssh-lab.ps1
```

**What happens behind the scenes**:
1. The script retrieves the live public IP and locates the local `.pem` private key generated during setup.
2. It opens an interactive SSH terminal connected directly to `ubuntu@<public-ip>`.
3. If I forget to run `start-lab.sh` first, the script detects that the server is stopped and prompts me: `"Would you like to start it now? [y/N]"`.

### Step 3: Check Lab Status (Anytime)
If I ever want to verify whether my server is running or check its IP address without connecting, I run:

```bash
# On Linux / macOS / Git Bash:
./scripts/status.sh

# On Windows PowerShell:
.\scripts\status.ps1
```

---

## 🐳 Hands-on Practice Session

Inside the server, I keep my exercises inside `~/workspace`:

```bash
cd ~/workspace
```

Because my EBS root volume persists across start/stop cycles:
- All Docker images I pulled yesterday (e.g., `redis`, `postgres`, `nginx`, `node:alpine`) are still present in my local Docker cache (`docker images`). I don't waste time re-downloading them every single day.
- Any Docker volumes (`docker volume ls`) and containers with my test data remain exactly as I left them.
- Any Git repositories, Dockerfiles, and compose files I created are still sitting in my workspace directory.

### Quick Sanity Checks During Practice:
```bash
# View running containers
docker ps

# View all containers (including stopped)
docker ps -a

# View saved container images
docker images

# Check disk space usage
df -h
docker system df
```

---

## 🌙 End of Day Routine: Wrapping Up & Saving Costs

When I finish my study session for the day, I follow these steps to make sure nothing is lost and no unnecessary AWS charges are incurred.

### Step 1: Commit and Push Notes / Code
From inside the EC2 instance or on my workstation:
1. Export any Dockerfiles, compose stacks, or notes.
2. Commit and push changes to my GitHub repository.

```bash
git add .
git commit -m "Day X: Learned Docker multi-stage builds and volumes"
git push origin main
```

### Step 2: Exit SSH
```bash
exit
```

### Step 3: Stop the EC2 Instance
Back in my local workstation terminal, I run:

```bash
# On Linux / macOS / Git Bash:
./scripts/stop-lab.sh

# On Windows PowerShell:
.\scripts\stop-lab.ps1
```

**What happens behind the scenes**:
1. The script issues `aws ec2 stop-instances`.
2. It waits until the instance transitions to `stopped` state.
3. Once stopped, AWS stops charging for compute vCPU and RAM.
4. AWS releases the dynamic public IPv4 address, so I don't incur AWS's $0.005/hr IPv4 charge.
5. My EBS root volume remains intact, preserving all my files and container layers for tomorrow.

---

## 🚨 Emergency Recovery Workflow

If I accidentally break my Linux configuration, mess up iptables, corrupt Docker's storage driver, or fill up disk space completely, I don't have to troubleshoot for hours. Since the entire infrastructure is declared as code, I can destroy and rebuild it in under 3 minutes:

### 1. Destroy Broken Infrastructure
```bash
# On Linux / macOS / Git Bash:
./scripts/destroy-lab.sh

# On Windows PowerShell:
.\scripts\destroy-lab.ps1
```
*(The script asks you to confirm by typing `destroy` to prevent accidental deletions.)*

### 2. Re-create Clean Infrastructure
```bash
# On Linux / macOS / Git Bash:
./scripts/create-lab.sh

# On Windows PowerShell:
.\scripts\create-lab.ps1
```

Within 2 minutes, I have a brand-new, fresh Ubuntu server with Docker cleanly installed and ready to go. This gives me total freedom to experiment without being afraid of breaking things!
