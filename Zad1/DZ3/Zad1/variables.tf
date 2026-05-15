variable "cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
  default     = "b1g36426920rk8dvvn2r"
}

variable "folder_id" {
  description = "Yandex Cloud Folder ID"
  type        = string
  default     = "b1gsq7mn8r0m1g4qf15j"
}

variable "zone" {
  description = "Availability zone"
  type        = string
  default     = "ru-central1-a"
}

variable "oauth_token" {
  description = "Yandex Cloud OAuth token"
  type        = string
  sensitive   = true
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "cloudnets"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dz3"
}

variable "domain_name" {
  description = "Domain name for CDN resource (e.g., example.com)"
  type        = string
}
