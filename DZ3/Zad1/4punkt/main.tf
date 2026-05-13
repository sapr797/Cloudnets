terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  folder_id = var.folder_id
  zone      = "ru-central1-a"
}

variable "folder_id" {
  default = "b1go4rn3uqvj8a794kvi"
}

# ============================================
# СУЩЕСТВУЮЩАЯ ИНФРАСТРУКТУРА (используем data)
# ============================================

data "yandex_vpc_subnet" "private" {
  subnet_id = "e9bh7jllhijv7b7gkohf"   # подсеть из вашей Instance Group
}
data "yandex_vpc_network" "main" {
  network_id = data.yandex_vpc_subnet.private.network_id   
}

# Группа безопасности для ALB (если у вас уже есть, можно заменить на data)
data "yandex_vpc_security_group" "alb_sg" {
  security_group_id  = "enpod0ehncpmuflhrnk1"

  #ingress {
    #protocol    = "TCP"
    #port        = 80
    #v4_cidr_blocks = ["0.0.0.0/0"]
    #description = "HTTP from internet"
  #}

  #egress {
    #protocol    = "ANY"
    #v4_cidr_blocks = ["0.0.0.0/0"]
    #from_port   = 0
    #to_port     = 65535
    #description = "Allow all outbound"
  #}
}

# ============================================
# S3 БАКЕТ И КАРТИНКА
# ============================================
resource "yandex_storage_bucket" "images" {
  bucket = "student-alb-bucket-20250511"
  anonymous_access_flags {
    read = true
  }
}

resource "yandex_storage_object" "picture" {
  bucket = yandex_storage_bucket.images.id
  key    = "my-picture.jpg"
  source = "./picture.jpg"
}

# ============================================
# APPLICATION LOAD BALANCER
# ============================================
resource "yandex_alb_target_group" "lamp_tg" {
  name = "lamp-tg"
}

resource "yandex_alb_backend_group" "lamp_bg" {
  name = "lamp-bg"

  http_backend {
    name             = "lamp-backend"
    port             = 80
    target_group_ids = [yandex_alb_target_group.lamp_tg.id]

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

resource "yandex_alb_http_router" "lamp_router" {
  name = "lamp-router"
}

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

resource "yandex_alb_load_balancer" "lamp_alb" {
  name        = "lamp-alb"
  network_id  = data.yandex_vpc_network.main.id
  security_group_ids = [data.yandex_vpc_security_group.alb_sg.id]
 
  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = data.yandex_vpc_subnet.private.id   
    }
  }

  listener {
    name = "http-listener"
    endpoint {
      address {
        external_ipv4_address {
         subnet_id = data.yandex_vpc_subnet.private.id
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

# ============================================
# СУЩЕСТВУЮЩАЯ INSTANCE GROUP (без изменений, кроме добавления application_load_balancer)
# ============================================
resource "yandex_compute_instance_group" "lamp_ig" {
  name                = "lamp-instance-group-alb"
  folder_id           = var.folder_id
  service_account_id  = "aje8ss2iqhb55i7df9ak"
  deletion_protection = false

  instance_template {
    platform_id = "standard-v2"
    resources {
      cores  = 2
      memory = 2
    }
    boot_disk {
      initialize_params {
        image_id = "fd827b91d99psvq5fjit"
        size     = 10
      }
    }
    network_interface {
      network_id = data.yandex_vpc_network.main.id
      subnet_ids = [data.yandex_vpc_subnet.private.id]
      security_group_ids = [data.yandex_vpc_security_group.alb_sg.id]
    }
    metadata = {
      user-data = <<-EOF
        #!/bin/bash
        apt-get update -y
        apt-get install -y apache2
        systemctl start apache2
        systemctl enable apache2
        cat > /var/www/html/index.html <<HTML
        <!DOCTYPE html>
        <html>
        <head><title>LAMP with ALB</title></head>
        <body>
          <h1>Welcome to LAMP Stack</h1>
          <p>Instance: $(hostname)</p>
          <img src="https://storage.yandexcloud.net/student-alb-bucket-20250511/my-picture.jpg" alt="Sample Image">
        </body>
        </html>
        HTML
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

  application_load_balancer {
    #security_group_ids = [data.yandex_vpc_security_group.alb_sg.id]
  }
}

# ============================================
# OUTPUTS
# ============================================
output "alb_ip" {
  value = yandex_alb_load_balancer.lamp_alb.listener[0].endpoint[0].address[0].external_ipv4_address[0].address
}

output "bucket_name" {
  value = yandex_storage_bucket.images.bucket
}

output "image_url" {
  value = "https://storage.yandexcloud.net/${yandex_storage_bucket.images.bucket}/${yandex_storage_object.picture.key}"
}
