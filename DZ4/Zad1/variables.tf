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

variable "mysql_password" {
  description = "MySQL admin password"
  type        = string
  sensitive   = true
}

variable "vpc_name" {
  description = "VPC network name"
  type        = string
  default     = "netology-vpc"
}
