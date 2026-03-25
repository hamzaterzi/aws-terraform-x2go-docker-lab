output "public_ip" {
  value = aws_eip.desktop_ip.public_ip
}

output "ssh_command" {
  value = "ssh -i devops-key.pem ubuntu@${aws_eip.desktop_ip.public_ip}"
}

output "x2go_host" {
  value = aws_eip.desktop_ip.public_ip
}
