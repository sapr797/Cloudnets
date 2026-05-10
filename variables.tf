variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "cloudnets"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "dz2"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.10.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Public subnet CIDR"
  type        = string
  default     = "10.10.1.0/24"
}

variable "private_subnet_cidr" {
  description = "Private subnet CIDR"
  type        = string
  default     = "10.10.2.0/24"
}

variable "availability_zone" {
  description = "Availability Zone"
  type        = string
  default     = "eu-north-1a"
}

variable "vm_username" {
  description = "VM username"
  type        = string
  default     = "ubuntu"
}

variable "private_key_path" {
  description = "Path to private SSH key"
  type        = string
  default     = "~/.ssh/aws_key"
}

variable "public_key_path" {
  description = "Path to public SSH key"
  type        = string
  default     = "~/.ssh/aws_key.pub"
}

variable "ami_id" {
  description = "Ubuntu 22.04 LTS AMI ID for eu-north-1"
  type        = string
  default     = "ami-0ff5917e3341b238e"  # Ubuntu 22.04 LTS
}
