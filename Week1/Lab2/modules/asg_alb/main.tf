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

  # ✅ FIXED USER DATA: Safely fetches IMDSv2 tokens and handles Python web directories
  user_data = base64encode(<<-EOF
              #!/bin/bash
              # Isolate the serving directory layout
              mkdir -p /var/www/html
              cd /var/www/html

              # Fetch IMDSv2 token for authenticated metadata access
              TOKEN=$(curl -s -X PUT "http://169.254.169" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

              # ✅ FIXED PATHS: Explicitly targets the metadata endpoints
              INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169)
              AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169)

              # Build beautiful index landing layout file
              cat <<HTML > index.html
              <!DOCTYPE html>
              <html>
              <head>
                  <title>dev Infrastructure</title>
                  <style>
                      body { font-family: 'Segoe UI', Arial, sans-serif; text-align: center; margin-top: 120px; background: #f0f2f5; color: #333; }
                      .card { background: white; padding: 40px; display: inline-block; border-radius: 12px; box-shadow: 0 4px 15px rgba(0,0,0,0.08); border-top: 5px solid #ff9900; }
                      h1 { color: #232f3e; margin-bottom: 20px; }
                      p { font-size: 1.1em; margin: 10px 0; }
                      span { font-weight: bold; background: #e7f3ff; color: #0066cc; padding: 4px 8px; border-radius: 4px; font-family: monospace; }
                  </style>
              </head>
              <body>
                  <div class="card">
                      <h1>Welcome to dev Web Server via ALB + ASG! 🚀</h1>
                      <p>Active Instance ID: <span>$INSTANCE_ID</span></p>
                      <p>Availability Zone: <span>$AZ</span></p>
                  </div>
              </body>
              </html>
              HTML

              # Fire up background web engine instance on port 80 targeting our path
              python3 -m http.server 80 --directory /var/www/html &
              EOF
  )


  # Ensures the IMDSv2 metadata endpoints are queryable inside the instance block
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

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
    interval            = 15 # Optimized from 30 to make rolling refreshes deploy faster
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

  # ✅ ADDED THIS BLOCK: Directs AWS to execute zero-downtime in-place rolling instance changes
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 60 # Small warmup footprint since Python starts instantly
    }
    triggers = ["launch_template"]
  }

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
