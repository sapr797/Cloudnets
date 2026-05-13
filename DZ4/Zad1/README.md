# Домашнее задание: Кластеры Kubernetes и MySQL в Yandex Cloud

## Выполненные требования

### Задание 1. Yandex Cloud - MySQL кластер

#### ✅ 1.1 Кластер баз данных MySQL через Terraform
**Реализация:** Файл `mysql.tf`
```
resource "yandex_mdb_mysql_cluster" "main" {
  name                = "netology-mysql-cluster"
  environment         = "PRESTABLE"
  network_id          = yandex_vpc_network.main.id
  version             = "8.0"
  deletion_protection = true
}
✅ 1.2 Private подсети в разных зонах
Реализация: Файл network.tf

 1.3 Ноды MySQL в разных подсетях
Реализация: Файл mysql.tf - три хоста в разных зонах

✅ 1.4 Репликация с произвольным временем обслуживания
Реализация: Файл mysql.tf

✅ 1.5 Окружение Prestable, платформа Intel Broadwell 50% CPU, диск 20 ГБ
Реализация: Файл mysql.tf

✅ 1.6 Время начала резервного копирования 23:59
Реализация: Файл mysql.tf

✅ 1.7 Защита от непреднамеренного удаления
Реализация: Файл mysql.tf

✅ 1.8 Создание БД netology_db с логином и паролем
Реализация: Файл mysql.tf

Задание 2. Yandex Cloud - Kubernetes кластер
✅2.1 Public подсети в разных зонах
Реализация: Файл network.tf

✅2.2 Отдельный сервис-аккаунт с правами
Реализация: Файл iam.tf

# Роль editor для мастера
resource "yandex_resourcemanager_folder_iam_member" "k8s_master_roles" {
  role   = "editor"
  member = "serviceAccount:${yandex_iam_service_account.k8s_master.id}"
}

# Роль для pull образов
resource "yandex_resourcemanager_folder_iam_member" "k8s_node_roles" {
  role   = "container-registry.images.puller"
  member = "serviceAccount:${yandex_iam_service_account.k8s_node.id}"
}
⚠️ 1.11 Региональный мастер Kubernetes с нодами в трёх подсетях
Статус: Частично выполнено (создан зональный кластер из-за технических ограничений)

Реализация (зональный вариант): Файл k8s.tf

    zone      = "ru-central1-a"
    subnet_id = yandex_vpc_subnet.public_a.id

Проблема: Региональный кластер не создался из-за конфликта подсетей с диапазонами K8s. Рекомендуется использовать CIDR 10.x.x.x для публичных подсетей.

✅ 1.12 Шифрование ключом из KMS
Реализация: Файл k8s.tf

kms_provider {
  key_id = yandex_kms_symmetric_key.k8s-key.id
}
⚠️ 1.13 Группа узлов из трёх машин с автомасштабированием до шести
Статус: Частично выполнено (созданы 2 ноды без автомасштабирования)

Реализация (минимальная): Файл k8s.tf

 1.14 Подключение к кластеру через kubectl
Реализация:

yc managed-kubernetes cluster get-credentials netology-k8s-cluster --external
kubectl get nodes

Результат:
NAME                        STATUS   ROLES    VERSION
cl1857qq3b4jqni8f837-evik   Ready    <none>   v1.31.2
cl1857qq3b4jqni8f837-ypul   Ready    <none>   v1.31.2

❌ 1.15 Запуск phpMyAdmin и подключение к БД
Статус: Не выполнено из-за отсутствия доступа нод в интернет
Проблема: Ноды кластера находятся в приватных подсетях без NAT, не могут загрузить образ phpmyadmin.
Решения:
Добавить NAT шлюз для публичных подсетей
Использовать Docker на ВМ управления
Включить публичные IP для нод
Временное решение (для демонстрации):
# На ВМ управления
docker run -d --name phpmyadmin -p 8080:80 \
  -e PMA_HOST=rc1a-jc560f9ti5mvsdde.mdb.yandexcloud.net \
  -e PMA_USER=netology_user \
  -e PMA_PASSWORD=QtTStrong8 \
  phpmyadmin/phpmyadmin

❌ 1.16 Load Balancer для phpMyAdmin
Статус: Не выполнено (зависит от п.1.15)

Итоговая таблица выполнения
ПунктОписаниеСтатус
1.1-1.8MySQL кластер✅ Полностью
1.9Public подсети✅ Полностью
1.10Сервис-аккаунты✅ Полностью
1.11Региональный мастер⚠️ Частично
1.12KMS шифрование✅ Полностью
1.13Группа узлов 3→6⚠️ Частично
1.14kubectl доступ✅ Полностью
1.15phpMyAdmin❌ Не выполнено
1.16Load Balancer❌ Не выполнено
Что нужно доработать
Региональный кластер: Использовать CIDR 10.0.0.0/16 для публичных подсетей вместо 192.168.x.x
Автомасштабирование: Добавить auto_scale блок в node group
NAT для нод: Настроить NAT gateway для доступа в интернет
phpMyAdmin: После настройки NAT развернуть через Kubernetes

Команды для проверки
# Проверка кластера
kubectl get nodes

# Проверка MySQL
yc managed-mysql cluster list

# Проверка базы данных
kubectl run mysql-client --image=mysql:8.0 --rm -it --restart=Never -- \
  mysql -h rc1a-jc560f9ti5mvsdde.mdb.yandexcloud.net \
  -u netology_user -pQtTStrong8 -e "SHOW DATABASES;"

## Выполненные пункты задания

### ✅ MySQL кластер
- Private подсети в зонах a, b, d
- 3 хоста (master + 2 реплики) в разных подсетях
- Репликация с произвольным временем обслуживания (ANYTIME)
- Окружение PRESTABLE, платформа Intel Broadwell 50% CPU (s2.micro)
- Диск 20 ГБ (network-ssd)
- Резервное копирование в 23:59
- Защита от удаления (deletion_protection = true)
- База данных netology_db, пользователь netology_user

### ✅ Kubernetes кластер
- Public подсети в зонах a, b, d
- Отдельный сервис-аккаунт с правами (editor, container-registry.images.puller)
- Шифрование через KMS
- Доступ через kubectl

### ⚠️ Частично выполнено
- Региональный мастер (создан зональный из-за конфликта CIDR)
- Группа узлов (созданы 2 ноды, нет автомасштабирования 3→6)

### ❌ Не выполнено
- phpMyAdmin (ноды кластера не имеют доступа в интернет)

## Структура файлов
Zad1/
├── providers.tf # Провайдеры (Yandex Cloud, time)
├── variables.tf # Входные переменные
├── network.tf # VPC, подсети, NAT gateway
├── k8s.tf # Kubernetes кластер, node group, KMS
├── mysql.tf # MySQL кластер, БД, пользователь
├── iam.tf # Сервис-аккаунты и роли
├── iam-roles.tf # Дополнительные роли
├── README.md # Документация
└── .gitignore # Игнорируемые файлы

## Переменные (terraform.tfvars - не в git)
``/`
yc_token      = "your-oauth-token"
yc_cloud_id   = "your-cloud-id"
yc_folder_id  = "your-folder-id"
mysql_password = "your-password"

Команды для работы

# Инициализация
terraform init

# План
terraform plan

# Применение
terraform apply

# Уничтожение
terraform destroy

# Доступ к кластеру
yc managed-kubernetes cluster get-credentials netology-k8s-cluster --external
kubectl get nodes

Известные проблемы
Региональный мастер не создался - конфликт CIDR подсетей (192.168.x.x) с внутренними диапазонами K8s
Ноды не имеют доступа в интернет - требуется настройка NAT gateway
Автомасштабирование не настроено - требуется правка k8s.tf

Рекомендации по доработке
Изменить CIDR публичных подсетей на 10.0.0.0/16
Настроить NAT gateway для доступа нод в интернет
Добавить auto_scale в node group
