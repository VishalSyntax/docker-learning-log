# ==============================================================================
# Security Module Variables
# ==============================================================================

variable "project_name" {
  description = "Project name prefix used for resource naming"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the security group will be created"
  type        = string
}

variable "allowed_cidr" {
  description = "Allowed CIDR block for inbound traffic (e.g., your public IP /32 or 0.0.0.0/0)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "common_tags" {
  description = "Common tags applied to all security resources"
  type        = map(string)
  default     = {}
}
