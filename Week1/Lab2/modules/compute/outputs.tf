output "instance_public_ip" {
  value = aws_instance.ubuntu_web.public_ip
}

output "instance_private_ip" {
  value = aws_instance.ubuntu_web.private_ip
}

output "instance_public_dns" {
  value = aws_instance.ubuntu_web.public_dns
}

output "ami_id_used" {
  value = data.aws_ami.ubuntu.id
}

output "ebs_volume_id" {
  value = aws_ebs_volume.example.id
}
