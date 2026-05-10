terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.130"
    }
  }
}

provider "yandex" {
  #zone = var.yandex_zone
  cloud_id                 = "cloud-alexalex755"
  folder_id                = "b1go4rn3uqvj8a794kvi"
  zone                     = "ru-central1-a"
}
