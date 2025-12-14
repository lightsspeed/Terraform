#!/bin/bash

# Update system
yum update -y

# Install nginx
amazon-linux-extras install nginx1 -y

# Start nginx
systemctl start nginx
systemctl enable nginx

# Create custom index page
cat > /usr/share/nginx/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Welcome</title>
</head>
<body>
    <h1>Hello from Terraform!</h1>
    <p>Instance ID: $(ec2-metadata --instance-id | cut -d ' ' -f 2)</p>
    <p>Availability Zone: $(ec2-metadata --availability-zone | cut -d ' ' -f 2)</p>
</body>
</html>
EOF

# Set permissions
chmod 644 /usr/share/nginx/html/index.html

echo "Setup complete!" > /var/log/userdata.log