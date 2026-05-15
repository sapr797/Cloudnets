# KMS ключ для шифрования
resource "yandex_kms_symmetric_key" "k8s_key" {
  name              = "k8s-secret-key"
  description       = "Key for Kubernetes secret encryption"
  default_algorithm = "AES_128"
  rotation_period   = "8760h"
}

# Зональный Kubernetes кластер
resource "yandex_kubernetes_cluster" "regional" {
  name        = "netology-k8s-cluster"
  description = "Zonal Kubernetes cluster"
  network_id  = yandex_vpc_network.main.id

  master {
    version    = "1.31"
    public_ip  = true
    zonal {
      zone      = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.public_a.id
    }
    security_group_ids = [yandex_vpc_security_group.k8s_main.id]
  }

  service_account_id      = yandex_iam_service_account.k8s_master.id
  node_service_account_id = yandex_iam_service_account.k8s_node.id

  kms_provider {
    key_id = yandex_kms_symmetric_key.k8s_key.id
  }

  depends_on = [
    yandex_resourcemanager_folder_iam_member.k8s_master_roles,
    yandex_resourcemanager_folder_iam_member.k8s_node_roles
  ]
}

# Группа узлов
resource "yandex_kubernetes_node_group" "main" {
  name       = "main-node-group"
  cluster_id = yandex_kubernetes_cluster.regional.id
  version    = "1.31"

  instance_template {
    platform_id = "standard-v3"

    network_interface {
      subnet_ids = [yandex_vpc_subnet.public_a.id]
    }

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
    fixed_scale {
      size = 2
    }
  }
}
