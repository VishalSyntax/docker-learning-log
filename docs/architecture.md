# Architecture & Design Overview

This document details the architectural decisions and infrastructure topology of my Docker Learning Lab. I intentionally built this using standard cloud engineering design patterns rather than launching a default instance in the default VPC.

---

## Architecture Diagram

Here is a visual map of how the cloud resources fit together inside AWS:

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
|  |   |   | Ingress: 22 (SSH), 80/443 (Web), 8080, 8081, 3000, 5000               | | |  |
|  |   |   | Egress:  All Outbound IPv4 (0.0.0.0/0)                                | | |  |
|  |   |   |                                                                       | | |  |
|  |   |   |   +---------------------------------------------------------------+   | | |  |
|  |   |   |   | EC2 Instance: docker-learning-log-instance                    |   | | |  |
|  |   |   |   | • OS: Canonical Ubuntu 24.04 LTS (x86_64)                     |   | | |  |
|  |   |   |   | • Type: t3.small (2 vCPU, 2 GiB RAM)                          |   | | |  |
|  |   |   |   | • Dynamic Public IPv4 (reallocated on start)                  |   | | |  |
|  |   |   |   | • SSH Key: 4096-bit RSA (docker-learning-log-key)             |   | | |  |
|  |   |   |   |                                                               |   | | |  |
|  |   |   |   | Attached Storage:                                             |   | | |  |
|  |   |   |   | • 20 GiB gp3 Encrypted Root EBS Volume                        |   | | |  |
|  |   |   |   |   (Holds Docker images, containers, logs, & workspace)        |   | | |  |
|  |   |   |   +---------------------------------------------------------------+   | | |  |
|  |   |   +-----------------------------------------------------------------------+ | |  |
|  |   +-----------------------------------------------------------------------------+ |  |
|  +-----------------------------------------------------------------------------------+  |
+-----------------------------------------------------------------------------------------+
                                          ▲
                                          │ SSH (Port 22) / Web (Port 80/3000/5000/8080)
                                          │
                            +-----------------------------+
                            | My Local Computer (Admin)   |
                            | (PowerShell / Bash Scripts) |
                            +-----------------------------+
```

---

## Architectural Components

### 1. Dedicated VPC (`10.0.0.0/16`)
Instead of launching resources into the AWS Default VPC (which is often cluttered and shares default security groups), I provision a dedicated Virtual Private Cloud named `docker-learning-log-vpc`.
- **Isolation**: My Docker lab is completely isolated from other projects.
- **DNS Support**: Both `enable_dns_support` and `enable_dns_hostnames` are enabled so my instance receives public and private DNS records.
- **Predictable IP Space**: `10.0.0.0/16` gives me 65,536 private IP addresses to grow into if I ever want to add worker nodes or container clusters later.

### 2. Public Subnet (`10.0.1.0/24`)
- Located in Availability Zone `ap-south-1a`.
- `map_public_ip_on_launch = true` ensures that when the EC2 instance boots, AWS assigns an automatic public IPv4 address so I can access it over the internet.

### 3. Internet Gateway & Public Route Table
- The **Internet Gateway (IGW)** acts as the bidirectional gateway between my VPC and the outside internet.
- The **Route Table** defines a route: `0.0.0.0/0` targeting the IGW. This gives the instance internet connectivity to download Docker images from Docker Hub, install Linux packages via `apt`, and let me connect over SSH.

### 4. Security Group Design
The security group (`docker-learning-log-sg`) acts as a stateful virtual firewall at the instance level. I selected specific ports tailored to Docker learning:

| Port | Protocol | Purpose in My Docker Labs |
|------|----------|---------------------------|
| `22` | TCP | SSH terminal management |
| `80` | TCP | Standard HTTP web server testing (Nginx, Apache) |
| `443` | TCP | Secure HTTPS web servers and SSL reverse proxies |
| `8080` | TCP | Common container application port (Spring Boot, Jenkins, Traefik) |
| `8081` | TCP | Secondary container or mock service port |
| `3000` | TCP | Frontend apps (Node.js, Express, React, Grafana dashboards) |
| `5000` | TCP | Python Flask / FastAPI backends, and local Docker Registry |

**Egress Rule**: All outbound traffic (`0.0.0.0/0`) is allowed so Docker can pull base images from Docker Hub, Quay, and GitHub Container Registry.

### 5. Compute & Storage (EC2 + gp3 EBS)
- **AMI**: Official Canonical Ubuntu 24.04 LTS (Noble Numbat) 64-bit x86_64 image, dynamically retrieved using an `aws_ami` data source.
- **Instance Type**: `t3.small` (2 vCPUs, 2 GiB memory, up to 5 Gbps network bandwidth). This provides the right balance for running containers like databases and web servers without encountering OOM crashes.
- **Root EBS Volume**: 20 GiB `gp3` SSD with encryption enabled at rest. `gp3` provides 3,000 baseline IOPS and 125 MB/s baseline throughput regardless of volume size, making package installation and container layer extraction very snappy.

---

## Why I Used a Modular Terraform Structure

Rather than stuffing everything into a single monolithic `main.tf`, I split the project into three distinct Terraform modules:

```text
terraform/
├── modules/
│   ├── network/      # Manages VPC, Subnet, IGW, Route Table
│   ├── security/     # Manages Security Groups and Rules
│   └── ec2/          # Manages AMI lookup, SSH Key, Instance, EBS
```

### Why this modular structure is better:
1. **Separation of Concerns**: Networking logic (CIDRs, routing) is decoupled from compute logic (instance type, AMIs, storage).
2. **Reusability**: If I want to launch a second test instance or an alternative worker node in the future, I can simply invoke `module "ec2"` again without rewriting VPC logic.
3. **Maintainability**: When I want to add a new open port for a Docker exercise, I only modify `modules/security/`, with zero risk of breaking VPC routing.
4. **Professional DevOps Best Practices**: Real-world production Terraform projects always use modular architectures with clean inputs (`variables.tf`) and outputs (`outputs.tf`).
