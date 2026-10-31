# ==============================================================================
# EC2 Module Outputs
# ==============================================================================

output "instance_id" {
  description = "The EC2 instance ID"
  value       = aws_instance.docker_lab.id
}

output "public_ip" {
  description = "The public IPv4 address assigned to the EC2 instance"
  value       = aws_instance.docker_lab.public_ip
}

output "public_dns" {
  description = "The public DNS name assigned to the EC2 instance"
  value       = aws_instance.docker_lab.public_dns
}

output "private_ip" {
  description = "The private IPv4 address of the EC2 instance"
  value       = aws_instance.docker_lab.private_ip
}

output "key_name" {
  description = "Name of the key pair used by the instance"
  value       = local.key_name
}

output "private_key_path" {
  description = "Path to the local private key pem file"
  value       = local.key_path
}
