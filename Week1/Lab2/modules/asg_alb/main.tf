# 1. Fetch Latest Ubuntu 24.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

# Local formatted tags matching FinOps policy (Dev / Prod)
locals {
  env_tag     = title(var.environment) # "Dev" or "Prod"
  service_tag = "webserver"
}

# 2. Launch Template (LT)
resource "aws_launch_template" "web" {
  name_prefix   = "${var.environment}-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [var.security_group_id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              echo "<h1>Welcome to ${var.environment} Web Server via ALB + ASG!</h1>" > index.html
              python3 -m http.server 80 &
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.environment}-asg-instance"
      Environment = local.env_tag
      Service     = local.service_tag
      ManagedBy   = "Terraform"
    }
  }
}

# 3. Application Load Balancer (ALB)
resource "aws_lb" "web" {
  name               = "${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = var.subnet_ids

  tags = {
    Name        = "${var.environment}-alb"
    Environment = local.env_tag
    Service     = local.service_tag
    ManagedBy   = "Terraform"
  }
}

# 4. Target Group (TG)
resource "aws_lb_target_group" "web" {
  name     = "${var.environment}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "${var.environment}-tg"
    Environment = local.env_tag
    Service     = local.service_tag
    ManagedBy   = "Terraform"
  }
}

# 5. ALB Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# 6. Auto Scaling Group (ASG)
resource "aws_autoscaling_group" "web" {
  name_prefix         = "${var.environment}-asg-"
  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = [aws_lb_target_group.web.arn]
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  health_check_type         = "ELB"
  health_check_grace_period = 300

  tag {
    key                 = "Environment"
    value               = local.env_tag
    propagate_at_launch = true
  }

  tag {
    key                 = "Service"
    value               = local.service_tag
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
