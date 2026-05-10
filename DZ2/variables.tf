# Yandex Cloud variables
variable "yandex_zone" {
  type    = string
  default = "ru-central1-a"
}

variable "public_subnet_cidr" {
  type    = string
  default = "192.168.10.0/24"
}

variable "private_subnet_cidr" {
  type    = string
  default = "192.168.20.0/24"
}

variable "nat_image_id" {
  type    = string
  default = "fd80mrhj8fl2oe87o4e1"
}

variable "vm_username" {
  type    = string
  default = "ubuntu"
}

variable "public_ssh_key_path" {
  type    = string
  default = "~/.ssh/id_ed25519.pub"
}

# AWS variables
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "aws_public_subnet_cidr" {
  type    = string
  default = "10.10.1.0/24"
}

variable "aws_private_subnet_cidr" {
  type    = string
  default = "10.10.2.0/24"
}

variable "aws_ami" {
  type    = string
  default = "ami-0c7217cdde317cfec" # Ubuntu 22.04 LTS (us-east-1)
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}
