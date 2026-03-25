variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "AWS key pair name"
  type        = string
  default     = "devops-key"
}

variable "allowed_ssh_cidr" {
  description = "Allowed SSH CIDR block"
  type        = string
  default     = "0.0.0.0/0"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "x2go-desktop-lab"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "Hamza"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "lab"
}
