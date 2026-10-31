# ==============================================================================
# EC2 Module Variables
# ==============================================================================

variable "project_name" {
  description = "Project name prefix used for resource naming"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type (e.g. t3.small, t2.micro)"
  type        = string
  default     = "t3.small"
}

variable "public_subnet_id" {
  description = "Subnet ID where the EC2 instance will be launched"
  type        = string
}

variable "security_group_id" {
  description = "Security Group ID to attach to the instance"
  type        = string
}

variable "user_data" {
  description = "Bootstrap script passed as user data"
  type        = string
  default     = ""
}

variable "existing_key_pair_name" {
  description = "Optional name of an existing AWS Key Pair. If empty, a key pair is auto-generated."
  type        = string
  default     = ""
}

variable "existing_key_path" {
  description = "Path to existing private key file if existing_key_pair_name is used"
  type        = string
  default     = ""
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GiB"
  type        = number
  default     = 20
}

variable "common_tags" {
  description = "Common tags applied to all EC2 resources"
  type        = map(string)
  default     = {}
}
