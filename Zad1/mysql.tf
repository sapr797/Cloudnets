# MySQL кластер
resource "yandex_mdb_mysql_cluster" "main" {
  name                = "netology-mysql-cluster"
  environment         = "PRESTABLE"
  network_id          = yandex_vpc_network.main.id
  version             = "8.0"
  deletion_protection = true

  resources {
    resource_preset_id = "s2.micro"
    disk_type_id       = "network-ssd"
    disk_size          = 20
  }

  backup_window_start {
    hours   = 23
    minutes = 59
  }

  maintenance_window {
    type = "ANYTIME"
  }

  host {
    zone             = "ru-central1-a"
    subnet_id        = yandex_vpc_subnet.private_a.id
    assign_public_ip = false
  }

  host {
    zone             = "ru-central1-b"
    subnet_id        = yandex_vpc_subnet.private_b.id
    assign_public_ip = false
  }

  host {
    zone             = "ru-central1-d"
    subnet_id        = yandex_vpc_subnet.private_d.id
    assign_public_ip = false
  }

  security_group_ids = [yandex_vpc_security_group.mysql_sg.id]
}

# База данных
resource "yandex_mdb_mysql_database" "main_db" {
  cluster_id = yandex_mdb_mysql_cluster.main.id
  name       = "netology_db"
}

# Пользователь
resource "yandex_mdb_mysql_user" "app_user" {
  cluster_id = yandex_mdb_mysql_cluster.main.id
  name       = "netology_user"
  password   = var.mysql_password

  permission {
    database_name = yandex_mdb_mysql_database.main_db.name
    roles         = ["ALL"]
  }
}
