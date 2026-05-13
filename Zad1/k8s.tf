# Сервис-аккаунты для Kubernetes
resource "yandex_iam_service_account" "k8s_master" {
  name        = "k8s-master-sa"
  description = "Service account for Kubernetes master"
}

#resource "yandex_iam_service_account" "k8s_node" {
  #name        = "k8s-node-sa"
  #description = "Service account for Kubernetes nodes"
#}

# Назначение ролей сервис-аккаунтам
resource "yandex_resourcemanager_folder_iam_member" "k8s_master_roles" {
  folder_id = var.yc_folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_master.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_node_roles" {
  folder_id = var.yc_folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_node.id}"
}

# Группы безопасности для Kubernetes
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
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
 
 ingress {
  description    = "SSH"
  protocol       = "TCP"
  v4_cidr_blocks = ["0.0.0.0/0"]
  port           = 22
}
}

# Региональный Kubernetes кластер
# Зональный Kubernetes кластер (работает в одной зоне)
resource "yandex_kubernetes_cluster" "regional" {
  name        = "netology-k8s-cluster"
  description = "Zonal Kubernetes cluster"
  network_id  = yandex_vpc_network.main.id

  master {
    version             = "1.31"
    public_ip           = true
    zonal {
      zone      = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.public_a.id
    }
    security_group_ids  = [yandex_vpc_security_group.k8s_main.id]
  }

  service_account_id      = yandex_iam_service_account.k8s_master.id
  node_service_account_id = yandex_iam_service_account.k8s_node.id

  kms_provider {
    key_id = yandex_kms_symmetric_key.k8s-key.id
  }

  depends_on = [
    yandex_resourcemanager_folder_iam_member.k8s_master_roles,
    yandex_resourcemanager_folder_iam_member.k8s_node_roles
  ]
}
#Группа узлов с автомасштабированием [citation:6]
resource "yandex_kubernetes_node_group" "main" {
  name       = "main-node-group"
  cluster_id = yandex_kubernetes_cluster.regional.id
  version    = "1.31"

  instance_template {
    platform_id = "standard-v3"
    network_interface {
      subnet_ids = [yandex_vpc_subnet.public_a.id, yandex_vpc_subnet.public_b.id, yandex_vpc_subnet.public_d.id]
    }
    #nat = true
    resources {
      memory = 4
      cores  = 2
    }
    boot_disk {
      size = 64
      type = "network-ssd"
    }
  }

  scale_policy {
    #auto_scale {
      #initial = 3
      #min     = 3
      #max     = 6
    fixed_scale {
      size = 2 
   }
  }

  allocation_policy {
    location { zone = "ru-central1-a" }
    location { zone = "ru-central1-b" }
    location { zone = "ru-central1-d" }
  }
}

  # Автомасштабирование: min 3, max 6 [citation:6]
  #scale_policy {
    #auto_scale {
      #min     = 3
      #max     = 6
      #initial = 3
    #}
  #}

  #allocation_policy {
    #location {
      #zone = "ru-central1-a"
    #}
    #location {
      #zone = "ru-central1-b"
    #}
    #location {
      #zone = "ru-central1-a"
    #}
  #}
#}

resource "yandex_kms_symmetric_key" "k8s-key" {
  name              = "k8s-secret-encryption-key" # Имя ключа
  description       = "Ключ для шифрования секретов в кластере Kubernetes"
  default_algorithm = "AES_128"
  rotation_period   = "8760h" # Период ротации, например, 1 год
}

# Создаем кластер Managed Service for Kubernetes
#resource "yandex_kubernetes_cluster" "zonal_cluster" {
  #name = "my-k8s-cluster"
  #network_id = yandex_vpc_network.main.id

  #master {
    #version = "1.30" 
    #public_ip = true
  #}

  # Указываем KMS ключ для шифрования секретов
  #kms_provider {
    #key_id = yandex_kms_symmetric_key.k8s-key.id
  #}

#}
