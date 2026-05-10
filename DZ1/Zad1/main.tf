# Создаем VPC (сеть)
resource "yandex_vpc_network" "main" {
  name = "main-vpc"
}

# Публичная подсеть
resource "yandex_vpc_subnet" "public" {
  name           = "public"
  zone           = var.yandex_zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

# Приватная подсеть
resource "yandex_vpc_subnet" "private" {
  name           = "private"
  zone           = var.yandex_zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["192.168.20.0/24"]
  route_table_id = yandex_vpc_route_table.private.id
}

# NAT-инстанс (публичная подсеть)
resource "yandex_compute_instance" "nat" {
  name = "nat-instance"
  zone = var.yandex_zone

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.nat_image_id
      size     = 10
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.public.id
    nat       = true  # Публичный IP
    ip_address = "192.168.10.254"  # Фиксированный IP
  }

  metadata = {
    ssh-keys = "${var.vm_username}:${file(var.public_ssh_key_path)}"
  }
}

# Таблица маршрутизации для приватной подсети
resource "yandex_vpc_route_table" "private" {
  name       = "private-route-table"
  network_id = yandex_vpc_network.main.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = yandex_compute_instance.nat.network_interface[0].ip_address
  }
}

# Привязываем таблицу маршрутизации к приватной подсети
#resource "yandex_vpc_subnet" "private_routed" {
 # name           = yandex_vpc_subnet.private.name
  #zone           = yandex_vpc_subnet.private.zone
  #network_id     = yandex_vpc_subnet.private.network_id
  #v4_cidr_blocks = yandex_vpc_subnet.private.v4_cidr_blocks
  #route_table_id = yandex_vpc_route_table.private.id
#}

# Публичная ВМ (бастион-хост)
resource "yandex_compute_instance" "public_vm" {
  name = "public-vm"
  zone = var.yandex_zone

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd827b91d99psvq5fjit"  # Ubuntu 22.04 LTS
      size     = 10
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.public.id
    nat       = true  # Публичный IP
  }

  metadata = {
    ssh-keys = "${var.vm_username}:${file(var.public_ssh_key_path)}"
  }
}

# Приватная ВМ (без публичного IP)
resource "yandex_compute_instance" "private_vm" {
  name = "private-vm"
  zone = var.yandex_zone

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd827b91d99psvq5fjit"  # Ubuntu 22.04 LTS
      size     = 10
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.private.id
    nat       = false  # Без публичного IP
  }

  metadata = {
    ssh-keys = "${var.vm_username}:${file(var.public_ssh_key_path)}"
  }
}
