# Назначение роли iam.serviceAccounts.user сервисному аккаунту кластера
resource "yandex_resourcemanager_folder_iam_member" "k8s_master_iam_user" {
  folder_id = var.yc_folder_id
  role      = "iam.serviceAccounts.user"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_master.id}"
}
 #Назначение роли k8s.clusters.agent сервисному аккаунту кластера
resource "yandex_resourcemanager_folder_iam_member" "k8s_master_clusters_agent" {
  folder_id = var.yc_folder_id
  role      = "k8s.clusters.agent"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_master.id}"
}

# Назначение роли vpc.publicAdmin сервисному аккаунту кластера
resource "yandex_resourcemanager_folder_iam_member" "k8s_master_vpc_admin" {
  folder_id = var.yc_folder_id
  role      = "vpc.publicAdmin"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_master.id}"
}
