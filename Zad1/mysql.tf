# Группа безопасности для MySQL
resource "yandex_vpc_security_group" "mysql_sg" {
  name        = "mysql-security-group"
  description = "Security group for MySQL cluster"
  network_id  = yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    description    = "MySQL"
    port           = 3306
    v4_cidr_blocks = ["192.168.0.0/16", "10.0.0.0/16"]
  }
}

# MySQL кластер с отказоустойчивой конфигурацией
resource "yandex_mdb_mysql_cluster" "main" {
  name                = "netology-mysql-cluster"
  environment         = "PRODUCTION"
  network_id          = yandex_vpc_network.main.id
  version             = "8.0"
  deletion_protection = true                  # Защита от удаления

  resources {
    resource_preset_id = "s2.micro"           # Intel Broadwell, 50% CPU
    disk_type_id       = "network-ssd"
    disk_size          = 10                    # 20 ГБ
  }
 

  # Резервное копирование в 23:59
  backup_window_start {
    hours   = 23
    minutes = 59
  }

  # Произвольное время обслуживания (ANYTIME)
  maintenance_window {
    type = "ANYTIME"
  }

  # Хосты в разных зонах и приватных подсетях
  host {
    zone      = "ru-central1-a"
    subnet_id = yandex_vpc_subnet.private_a.id
    assign_public_ip = false
  }

  host {
    zone      = "ru-central1-b"
    subnet_id = yandex_vpc_subnet.private_b.id
    assign_public_ip = false
  }

  host {
    zone      = "ru-central1-d"
    subnet_id = yandex_vpc_subnet.private_d.id
    assign_public_ip = false
  }

  security_group_ids = [yandex_vpc_security_group.mysql_sg.id]
}

# Ждём готовности кластера
resource "time_sleep" "wait_for_mysql" {
  create_duration = "60s"
  depends_on = [yandex_mdb_mysql_cluster.main]
}

# База данных (зависит от таймера)
resource "yandex_mdb_mysql_database" "main_db" {
  cluster_id = yandex_mdb_mysql_cluster.main.id
  name       = "netology_db"
  depends_on = [time_sleep.wait_for_mysql]
}
# Пользователь (зависит от БД)
resource "yandex_mdb_mysql_user" "app_user" {
  cluster_id = yandex_mdb_mysql_cluster.main.id
  name       = "netology_user"
  password   = var.mysql_password

  permission {
    database_name = yandex_mdb_mysql_database.main_db.name
    roles         = ["ALL"]
  }
  depends_on = [yandex_mdb_mysql_database.main_db]
}


