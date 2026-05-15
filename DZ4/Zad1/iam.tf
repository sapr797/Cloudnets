# Сервисный аккаунт для Kubernetes мастера
resource "yandex_iam_service_account" "k8s_master" {
  name        = "k8s-master-sa"
  description = "Service account for Kubernetes master"
}

# Сервисный аккаунт для узлов Kubernetes
resource "yandex_iam_service_account" "k8s_node" {
  name        = "k8s-node-sa"
  description = "Service account for Kubernetes nodes"
}

# Роль editor для мастера
resource "yandex_resourcemanager_folder_iam_member" "k8s_master_roles" {
  folder_id = var.yc_folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_master.id}"
}

# Роль для узлов (pull образов)
resource "yandex_resourcemanager_folder_iam_member" "k8s_node_roles" {
  folder_id = var.yc_folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_node.id}"
}

# Роль iam.serviceAccounts.user
resource "yandex_resourcemanager_folder_iam_member" "k8s_master_iam_user" {
  folder_id = var.yc_folder_id
  role      = "iam.serviceAccounts.user"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_master.id}"
}
