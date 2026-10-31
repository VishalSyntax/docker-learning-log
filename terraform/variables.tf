# ==============================================================================
# Root Terraform Variables
# ==============================================================================

variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "ap-south-1"
}

variable "availability_zone" {
  description = "Specific availability zone for the subnet (leave blank for default a-zone in region)"
  type        = string
  default     = "ap-south-1a"
}

variable "project_name" {
  description = "Base name applied to resources and tags"
  type        = string
  default     = "docker-learning-lab"
}

variable "environment" {
  description = "Environment tag (e.g. dev, lab)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the custom VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type for Docker lab"
  type        = string
  default     = "t3.small"
}

variable "allowed_cidr" {
  description = "Allowed CIDR IP for SSH and container ports (e.g., your IP x.x.x.x/32 or 0.0.0.0/0)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "existing_key_pair_name" {
  description = "Optional: Provide existing AWS EC2 Key Pair name. If empty, Terraform generates a new key pair and saves the .pem file locally."
  type        = string
  default     = ""
}

variable "existing_key_path" {
  description = "Optional: Path to private key file if existing_key_pair_name is provided"
  type        = string
  default     = ""
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GiB"
  type        = number
  default     = 20
}
