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
  default = "fd80mrhj8fl2oe87o4e1"  # NAT-instance image
}

variable "vm_username" {
  type    = string
  default = "yc-user"
}

# Путь к вашему публичному SSH ключу
variable "public_ssh_key_path" {
  type    = string
  default = "~/.ssh/id_ed25519_new.pub"
}
