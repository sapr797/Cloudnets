# Используем существующую сеть
data "yandex_vpc_network" "existing" {
  name = "default"
}

# Публичная подсеть
resource "yandex_vpc_subnet" "public" {
  name           = "public-subnet-alb"
  zone           = "ru-central1-a"
  network_id     = data.yandex_vpc_network.existing.id
  v4_cidr_blocks = ["10.0.2.0/24"]  # другой CIDR чтобы не конфликтовать
}

# Security Group для ALB и ВМ
resource "yandex_vpc_security_group" "lamp_sg" {
  name        = "lamp-alb-sg"
  description = "Security group for ALB and instances"
  network_id  = data.yandex_vpc_network.existing.id

  ingress {
    protocol       = "TCP"
    description    = "HTTP from ALB"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol       = "TCP"
    description    = "Health check from ALB"
    v4_cidr_blocks = ["198.18.235.0/24", "198.18.248.0/24"]
    port           = 80
  }

  egress {
    protocol       = "ANY"
    description    = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

# Object Storage бакет (как в Zad1)
resource "yandex_storage_bucket" "images" {
  bucket = "my-unique-bucket-alb-20260510"

  grant {
    type        = "CanonicalUser"
    id          = "ajeqp9l1i50b3ifqk7af"
    permissions = ["FULL_CONTROL"]
  }

  grant {
    type        = "Group"
    uri         = "http://acs.amazonaws.com/groups/global/AllUsers"
    permissions = ["READ"]
  }
}

# Загрузка картинки
resource "yandex_storage_object" "picture" {
  bucket = yandex_storage_bucket.images.id
  key    = "my-picture.jpg"
  source = "./picture.jpg"
}

# === Application Load Balancer компоненты ===

# HTTP роутер
resource "yandex_alb_http_router" "lamp_router" {
  name = "lamp-router"
}

# Виртуальный хост
resource "yandex_alb_virtual_host" "lamp_host" {
  name           = "lamp-host"
  http_router_id = yandex_alb_http_router.lamp_router.id

  route {
    name = "default-route"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.lamp_bg.id
        timeout          = "60s"
      }
    }
  }
}

# Бэкенд группа с health check
resource "yandex_alb_backend_group" "lamp_bg" {
  name = "lamp-backend-group"

  http_backend {
    name = "lamp-backend"
    port = 80
    weight = 1

    load_balancing_config {
      panic_threshold = 50
    }

    target_group_ids = [yandex_alb_target_group.lamp_alb_tg.id]

    healthcheck {
      timeout  = "10s"
      interval = "2s"
      healthy_threshold   = 2
      unhealthy_threshold = 2

      http_healthcheck {
        path = "/"
      }
    }
  }
}

# Target Group для ALB
resource "yandex_alb_target_group" "lamp_alb_tg" {
  name = "lamp-alb-target-group"
}

# Application Load Balancer
resource "yandex_alb_load_balancer" "lamp_alb" {
  name               = "lamp-application-balancer"
  network_id         = data.yandex_vpc_network.existing.id
  security_group_ids = [yandex_vpc_security_group.lamp_sg.id]

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.public.id
    }
  }

  listener {
    name = "http-listener"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.lamp_router.id
      }
    }
  }
}

# Instance Group с LAMP шаблоном
resource "yandex_compute_instance_group" "lamp_ig" {
  name                = "lamp-instance-group-alb"
  folder_id           = var.folder_id
  service_account_id  = "ajeqp9l1i50b3ifqk7af"
  deletion_protection = false

  instance_template {
    platform_id = "standard-v2"

    resources {
      cores  = 2
      memory = 2
    }

    boot_disk {
      mode = "READ_WRITE"
      initialize_params {
        image_id = "fd827b91d99psvq5fjit"
        size     = 10
      }
    }

    network_interface {
      network_id         = data.yandex_vpc_network.existing.id
      subnet_ids         = [yandex_vpc_subnet.public.id]
      security_group_ids = [yandex_vpc_security_group.lamp_sg.id]
    }

    metadata = {
      user-data = <<-EOF
        #!/bin/bash
        apt-get update -y
        apt-get install -y apache2
        systemctl start apache2
        systemctl enable apache2

        cat > /var/www/html/index.html << HTML
        <!DOCTYPE html>
        <html>
        <head>
            <title>LAMP Stack with ALB</title>
            <style>
                body { font-family: Arial, sans-serif; text-align: center; margin-top: 50px; }
                img { max-width: 500px; border-radius: 10px; }
            </style>
        </head>
        <body>
            <h1>Welcome to LAMP Stack (ALB Version)</h1>
            <p>Instance: $(hostname)</p>
            <img src="https://storage.yandexcloud.net/my-unique-bucket-alb-20260510/my-picture.jpg" alt="Sample Image">
        </body>
        </html>
        HTML

        chmod 644 /var/www/html/index.html
        systemctl restart apache2
      EOF
    }
  }

  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  allocation_policy {
    zones = ["ru-central1-a"]
  }

  deploy_policy {
    max_unavailable = 1
    max_expansion   = 1
  }

  # Подключение к ALB target group
  application_load_balancer {
    #target_group_id = yandex_alb_target_group.lamp_alb_tg.id
  }
}

# Привязка target group к инстансам (после создания)
#resource "yandex_alb_target_group_attachment" "lamp_ig_attachment" {
  #target_group_id = yandex_alb_target_group.lamp_alb_tg.id
  #target {
    #ip_address   = yandex_compute_instance_group.lamp_ig.instances[*].network_interface[0].ip_address
    #subnet_id    = yandex_vpc_subnet.public.id
  #}
#}