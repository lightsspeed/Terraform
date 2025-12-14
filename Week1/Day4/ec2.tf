# ec2.tf - EC2 instances and related resources

# SSH Key Pair
resource "aws_key_pair" "deployer" {
  key_name   = var.ssh_key_name
  public_key = file("${path.module}/keys/terraform-key.pub")

  tags = merge(
    var.common_tags,
    {
      Name = var.ssh_key_name
    }
  )
}

# EC2 Instance
resource "aws_instance" "nginx" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.main[0].id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = aws_key_pair.deployer.key_name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install nginx1 -y
              systemctl start nginx
              systemctl enable nginx
              
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
                  <h1>🚀 Terraform + Nginx</h1>
                  <div class="box">
                      <p><strong>Status:</strong> Running!</p>
                      <p><strong>Project:</strong> ${var.project_name}</p>
                  </div>
              </body>
              </html>
              HTML
              
              echo "Setup complete" > /var/log/userdata-complete.log
              EOF

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-nginx-server"
    }
  )
}

# Elastic IP
resource "aws_eip" "web_eip" {
  instance = aws_instance.nginx.id
  domain   = "vpc"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-eip"
    }
  )

  depends_on = [aws_internet_gateway.gw]
}