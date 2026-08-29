resource "aws_security_group" "web_server_sg" {
  name        = "web-server-sg"
  description = "Security group for web servers with standalone rules"
  vpc_id      = var.vpc_id

  tags = {
    Name = "web-server-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_web" {
  security_group_id = aws_security_group.web_server_sg.id
  description       = "Allow HTTP traffic"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_https_web" {
  security_group_id = aws_security_group.web_server_sg.id
  description       = "Allow HTTPS traffic"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_web" {
  security_group_id = aws_security_group.web_server_sg.id
  description       = "Allow SSH connections"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_outbound_web" {
  security_group_id = aws_security_group.web_server_sg.id
  description       = "Allow all outbound traffic"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
