data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = [var.ami_owner]

  filter {
    name   = "name"
    values = [var.ami_name_filter]
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = var.ssh_key_name
  public_key = file(pathexpand(var.ssh_public_key_path))

  tags = {
    Name = var.ssh_key_name
  }
}

resource "aws_instance" "ubuntu_web" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  availability_zone           = var.az
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  associate_public_ip_address = var.associate_public_ip
  key_name                    = aws_key_pair.deployer.key_name

  tags = {
    Name = "${var.instance_name}-webserver"
  }
}

resource "aws_ebs_volume" "example" {
  availability_zone = var.az
  size              = var.ebs_size

  tags = {
    Name = "${var.instance_name}-storage"
  }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name  = var.ebs_device_name
  volume_id    = aws_ebs_volume.example.id
  instance_id  = aws_instance.ubuntu_web.id
  force_detach = true
}
