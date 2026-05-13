# Сервисный аккаунт для управления кластером
resource "yandex_iam_service_account" "k8s_cluster" {
  name = "k8s-cluster-sa"
}

# Роль для кластера
resource "yandex_resourcemanager_folder_iam_member" "k8s_cluster_editor" {
  folder_id = var.yc_folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_cluster.id}"
}

# Сервисный аккаунт для узлов
resource "yandex_iam_service_account" "k8s_node" {
  name = "k8s-node-sa"
}

# Роль для узлов (чтение из Container Registry)
resource "yandex_resourcemanager_folder_iam_member" "k8s_node_puller" {
  folder_id = var.yc_folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_node.id}"
}
