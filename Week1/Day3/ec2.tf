# Data source: Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# SSH Key Pair
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file("${path.module}/keys/terraform-key.pub")

  tags = {
    Name = "deployer-key"
  }
}

# EC2 Instance with Nginx
resource "aws_instance" "nginx" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.main[0].id
  vpc_security_group_ids = [aws_security_group.web.id] # ✅ Fixed: Use correct SG
  key_name               = aws_key_pair.deployer.key_name

  user_data = <<-EOF
              #!/bin/bash
              # Update system
              yum update -y
              
              # Install nginx
              amazon-linux-extras install nginx1 -y
              
              # Start and enable nginx
              systemctl start nginx
              systemctl enable nginx
              
              # Create custom index page
              cat > /usr/share/nginx/html/index.html << 'HTML'
              <!DOCTYPE html>
              <html>
              <head>
                  <title>Terraform Nginx</title>
                  <style>
                      body { 
                          font-family: Arial, sans-serif; 
                          text-align: center; 
                          padding: 50px;
                          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                          color: white;
                      }
                      h1 { font-size: 3em; margin: 0; }
                      p { font-size: 1.2em; }
                      .box { 
                          background: rgba(255,255,255,0.1); 
                          padding: 20px; 
                          border-radius: 10px; 
                          margin: 20px auto;
                          max-width: 600px;
                      }
                  </style>
              </head>
              <body>
                  <h1>Terraform + Nginx</h1>
                  <div class="box">
                      <p><strong>Status:</strong> Running Successfully!</p>
                      <p><strong>Instance ID:</strong> $(ec2-metadata --instance-id | cut -d ' ' -f 2)</p>
                      <p><strong>Availability Zone:</strong> $(ec2-metadata --availability-zone | cut -d ' ' -f 2)</p>
                      <p><strong>Local IP:</strong> $(ec2-metadata --local-ipv4 | cut -d ' ' -f 2)</p>
                  </div>
              </body>
              </html>
              HTML
              
              # Log completion
              echo "User data completed at $(date)" > /var/log/userdata-complete.log
              EOF

  tags = {
    Name = "nginx-server"
  }
}

# Elastic IP
resource "aws_eip" "web_eip" {
  instance = aws_instance.nginx.id
  domain   = "vpc"

  tags = {
    Name = "web-eip"
  }

  depends_on = [aws_internet_gateway.gw]
}