# ==============================================================================
# EC2 Module - Compute Instance, AMI Resolution, SSH Key, and User Data
# ==============================================================================

# Dynamic lookup for official Canonical Ubuntu 24.04 LTS Noble Numbat AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical official owner ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# Auto-generate SSH Private Key if existing_key_pair_name is not provided
resource "tls_private_key" "lab_key" {
  count     = var.existing_key_pair_name == "" ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Register the generated public key with AWS
resource "aws_key_pair" "generated_key" {
  count      = var.existing_key_pair_name == "" ? 1 : 0
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.lab_key[0].public_key_openssh

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-key"
    }
  )
}

# Save private key to local .pem file in the terraform directory (gitignored)
resource "local_file" "private_key_pem" {
  count           = var.existing_key_pair_name == "" ? 1 : 0
  content         = tls_private_key.lab_key[0].private_key_pem
  filename        = "${path.root}/${var.project_name}-key.pem"
  file_permission = "0400"
}

locals {
  # Determine which key pair to use
  key_name = var.existing_key_pair_name != "" ? var.existing_key_pair_name : (length(aws_key_pair.generated_key) > 0 ? aws_key_pair.generated_key[0].key_name : "")
  key_path = var.existing_key_pair_name != "" ? var.existing_key_path : (length(local_file.private_key_pem) > 0 ? local_file.private_key_pem[0].filename : "")
}

# The EC2 Instance for Docker Learning Lab
resource "aws_instance" "docker_lab" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = local.key_name
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  associate_public_ip_address = true

  user_data                   = var.user_data
  user_data_replace_on_change = false

  # Root EBS volume configured with cost-effective gp3 storage
  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = true

    tags = merge(
      var.common_tags,
      {
        Name = "${var.project_name}-root-volume"
      }
    )
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-instance"
    }
  )

  lifecycle {
    ignore_changes = [
      ami
    ]
  }
}
