# Создаем VPC, если не существует
resource "yandex_vpc_network" "main" {
  name        = var.vpc_name
  description = "VPC для кластеров Kubernetes и MySQL"
}

# Public подсети для Kubernetes (в разных зонах)
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

# Private подсети для MySQL (в разных зонах)
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

# NAT Gateway для доступа private подсетей в интернет
resource "yandex_vpc_gateway" "nat_gateway" {
  name = "nat-gateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "private_route" {
  name       = "private-route-table"
  network_id = yandex_vpc_network.main.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}

