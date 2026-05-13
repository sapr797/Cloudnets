variable "yc_token" {
  description = "Yandex Cloud OAuth token"
  type        = string
  sensitive   = true
}

variable "yc_cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
}

variable "yc_folder_id" {
  description = "Yandex Cloud Folder ID"
  type        = string
}

variable "vpc_name" {
  description = "VPC name"
  type        = string
  default     = "k8s-mysql-vpc"
}

variable "mysql_password" {
  description = "MySQL admin password"
  type        = string
  sensitive   = true
}

#variable "k8s_kms_key_id" {
  #description = "Existing KMS key ID for Kubernetes encryption"
  #type        = string
#}
