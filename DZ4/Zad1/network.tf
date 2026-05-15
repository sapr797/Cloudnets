# VPC сеть
resource "yandex_vpc_network" "main" {
  name        = var.vpc_name
  description = "VPC для кластеров Kubernetes и MySQL"
}

# Public подсети для Kubernetes
resource "yandex_vpc_subnet" "public_a" {
  name           = "public-ru-central1-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["192.168.0.0/24"]
}

resource "yandex_vpc_subnet" "public_b" {
  name           = "public-ru-central1-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["192.168.1.0/24"]
}

resource "yandex_vpc_subnet" "public_d" {
  name           = "public-ru-central1-d"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["192.168.2.0/24"]
}

# Private подсети для MySQL
resource "yandex_vpc_subnet" "private_a" {
  name           = "private-ru-central1-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.0.0.0/24"]
}

resource "yandex_vpc_subnet" "private_b" {
  name           = "private-ru-central1-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.0.1.0/24"]
}

resource "yandex_vpc_subnet" "private_d" {
  name           = "private-ru-central1-d"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.0.2.0/24"]
}

# Security группа для MySQL
resource "yandex_vpc_security_group" "mysql_sg" {
  name        = "mysql-security-group"
  description = "Security group for MySQL cluster"
  network_id  = yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    description    = "MySQL"
    port           = 3306
    v4_cidr_blocks = ["192.168.0.0/16", "10.0.0.0/8"]
  }
}

# Security группа для Kubernetes
resource "yandex_vpc_security_group" "k8s_main" {
  name        = "k8s-main-sg"
  description = "Security group for Kubernetes cluster"
  network_id  = yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    description    = "Kubernetes API"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "NodePorts"
    port           = 30000
    to_port        = 32767
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "SSH"
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  egress {
    protocol       = "ANY"
    description    = "All egress"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
