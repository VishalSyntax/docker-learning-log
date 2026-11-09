# ==============================================================================
# Security Module - Security Group & Ingress/Egress Rules
# ==============================================================================

resource "aws_security_group" "docker_lab_sg" {
  name        = "${var.project_name}-sg"
  description = "Security group for Docker learning lab EC2 instance"
  vpc_id      = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-sg"
    }
  )
}

# Ingress Rules for learning lab services
# Ports: 22 (SSH), 80 (HTTP), 443 (HTTPS), 8080, 8081, 3000 (Node/React), 5000 (Flask/Registry)
locals {
  ingress_rules = [
    { port = 22,   description = "SSH administrative access" },
    { port = 80,   description = "HTTP web traffic" },
    { port = 443,  description = "HTTPS secure web traffic" },
    { port = 8080, description = "Container web applications / proxy / Jenkins" },
    { port = 8081, description = "Secondary container services / tools" },
    { port = 3000, description = "Frontend apps (React/Next.js/Grafana)" },
    { port = 5000, description = "Backend APIs (Flask/Python/Docker Registry)" }
  ]
}

resource "aws_vpc_security_group_ingress_rule" "rules" {
  for_each = { for rule in local.ingress_rules : rule.port => rule }

  security_group_id = aws_security_group.docker_lab_sg.id
  cidr_ipv4         = var.allowed_cidr
  from_port         = each.value.port
  to_port           = each.value.port
  ip_protocol       = "tcp"
  description       = each.value.description

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-ingress-${each.key}"
    }
  )
}

# Egress Rule - Allow all outbound traffic for package updates and Docker image pulls
resource "aws_vpc_security_group_egress_rule" "allow_all_outbound" {
  security_group_id = aws_security_group.docker_lab_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound IPv4 traffic"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-egress-all"
    }
  )
}
