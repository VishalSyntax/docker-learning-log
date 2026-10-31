# ==============================================================================
# Root Outputs
# ==============================================================================

output "aws_region" {
  description = "The AWS Region where resources are deployed"
  value       = var.aws_region
}

output "instance_id" {
  description = "The EC2 Instance ID (used by automation scripts)"
  value       = module.ec2.instance_id
}

output "public_ip" {
  description = "The Public IPv4 Address of the EC2 Instance"
  value       = module.ec2.public_ip
}

output "public_dns" {
  description = "The Public DNS hostname of the EC2 Instance"
  value       = module.ec2.public_dns
}

output "key_name" {
  description = "The SSH Key Pair name used by EC2"
  value       = module.ec2.key_name
}

output "private_key_path" {
  description = "Path to the SSH Private Key file"
  value       = module.ec2.private_key_path
}

output "ssh_command" {
  description = "Ready-to-use SSH connection command"
  value       = "ssh -i ${module.ec2.private_key_path} ubuntu@${module.ec2.public_ip}"
}
