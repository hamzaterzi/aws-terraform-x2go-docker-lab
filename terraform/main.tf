provider "aws" {
  region = var.aws_region
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_security_group" "x2go_sg" {
  name        = "x2go-desktop-sg"
  description = "Security group for X2Go Ubuntu desktop lab"

  ingress {
    description = "SSH / X2Go"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  
  }
  ingress {
  description = "HTTP"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "x2go-desktop-sg"
    Project     = var.project_name
    Environment = var.environment
    Owner       = var.owner
  }
}

resource "aws_instance" "desktop" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.x2go_sg.id]

  user_data = file("user-data.sh")

  tags = {
    Name        = "${var.project_name}-ec2"
    Project     = var.project_name
    Environment = var.environment
    Owner       = var.owner
  }
}

resource "aws_eip" "desktop_ip" {
  instance = aws_instance.desktop.id
  domain   = "vpc"

  tags = {
    Name        = "${var.project_name}-eip"
    Project     = var.project_name
    Environment = var.environment
    Owner       = var.owner
  }
}
