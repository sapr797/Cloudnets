# Домашнее задание 1: Yandex Cloud Infrastructure as Code (Terraform)

## Описание задания
Создание инфраструктуры в Yandex Cloud с использованием Terraform:
- VPC с публичной и приватной подсетями
- NAT-инстанс для доступа в интернет из приватной сети
- Бастион-хост (публичная ВМ) для подключения к приватной ВМ
- Приватная ВМ без публильного IP

## Архитектура
┌─────────────────┐
│ Internet │
└────────┬────────┘
│
┌────────┴────────┐
│ NAT Instance │
│ (public-ip) │
└────────┬────────┘
│
┌─────────────────────────────────────────────┼──────────────────────────────────┐
│ VPC: main-vpc │ │
│ │ │
│ ┌──────────────────────────┐ ┌─────────┴─────────┐ ┌─────────────────┐ │
│ │ Public Subnet │ │ Private Subnet │ │ Private Subnet │ │
│ │ 192.168.10.0/24 │ │ 192.168.20.0/24 │ │ (routed) │ │
│ │ │ │ │ │ │ │
│ │ ┌────────────────────┐ │ │ ┌─────────────┐ │ │ │ │
│ │ │ Public VM │◄─┼─────┼─►│ Private VM │ │ │ │ │
│ │ │ (bastion) │ │ │ │ (no public) │ │ │ │ │
│ │ │ 89.169.151.163 │ │ │ │ 192.168.20.29│ │ │ │ │
│ │ └────────────────────┘ │ │ └─────────────┘ │ │ │ │
│ │ │ │ ▲ │ │ │ │
│ │ ┌────────────────────┐ │ │ │ │ │ │ │
│ │ │ NAT Instance │ │ │ route table │ │ │ │
│ │ │ 192.168.10.254 │ │ │ 0.0.0.0/0 │ │ │ │
│ │ │ (IP forwarding) │ │ │ via NAT │ │ │ │
│ │ └────────────────────┘ │ │ │ │ │ │
│ │ │ │ │ │ │ │
│ └──────────────────────────┘ └───────────────────┘ └─────────────────┘ │
│ │
└─────────────────────────────────────────────────────────────────────────────────┘

## Предварительные требования

### 1. Установленное ПО
- Terraform (>= 1.5.0)
- Yandex Cloud CLI (yc)
- SSH клиент

### 2. Настройка аутентификации

```
# Установка YC CLI
curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash

# Авторизация
yc init

# Создание сервисного аккаунта
yc iam service-account create --name terraform-sa --folder-id <YOUR_FOLDER_ID>

# Создание ключа
yc iam key create --service-account-name terraform-sa --output key.json
3. SSH ключи
# Создание SSH ключа (если нет)
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_news -N ""
Структура проекта
Zad1/
├── main.tf              # Основная конфигурация ресурсов
├── variables.tf         # Переменные
├── outputs.tf          # Выходные данные
├── terraform.tfvars    # Значения переменных (не включается в git)
└── README.md           
Развертывание инфраструктуры
1. Клонирование репозитория
git clone git@github.com:sapr797/Cloudnets.git
cd Cloudnets/DZ1/Zad1
2. Настройка переменных
Создайте файл terraform.tfvars:
# Аутентификация
service_account_key_file = "key.json"
cloud_id                 = "your_cloud_id"
folder_id                = "your_folder_id"

# SSH
vm_username              = "ubuntu"
public_ssh_key_path      = "/home/ubuntu/.ssh/id_ed25519_news.pub"

# Подсети
public_subnet_cidr       = "192.168.10.0/24"
private_subnet_cidr      = "192.168.20.0/24"
yandex_zone              = "ru-central1-a"
3. Инициализация и применение
# Инициализация Terraform
terraform init

# Просмотр плана
terraform plan

# Применение конфигурации
terraform apply -auto-approve
Проверка работоспособности
1. Просмотр выходных данных
terraform output
Пример вывода:
nat_instance_ip = "111.88.246.171"
private_vm_ip = "192.168.20.29"
public_vm_ip = "89.169.151.163"
ssh_to_private_vm_through_public_command = "ssh -J ubuntu@89.169.151.163 ubuntu@192.168.20.29"
2. Подключение к ВМ
# Подключение к публичной ВМ
ssh ubuntu@$(terraform output -raw public_vm_ip)

# Подключение к приватной ВМ через публичную
ssh -J ubuntu@$(terraform output -raw public_vm_ip) ubuntu@$(terraform output -raw private_vm_ip)
3. Проверка интернета с приватной ВМ
# Проверка доступности интернета
ping 8.8.8.8

# Проверка внешнего IP (должен показать IP NAT-инстанса)
curl ifconfig.me
Настройка NAT-инстанса (если не настроен автоматически)
# Подключение к NAT-инстансу
ssh ubuntu@$(terraform output -raw nat_instance_ip)

# Включение IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf

# Настройка NAT
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo netfilter-persistent save
Используемые ресурсы
Ресурс Тип Описание
yandex_vpc_networknetworkVPC сеть main-vpc
yandex_vpc_subnetsubnetПубличная и приватная подсети
yandex_vpc_route_tableroute_tableМаршрутизация приватной подсети
yandex_compute_instanceinstanceNAT-инстанс, публичная ВМ, приватная ВМ
Удаление инфраструктуры

# Уничтожение всех ресурсов
terraform destroy -auto-approve
Устранение неполадок
Ошибка: "SSH key not found"
# Проверьте наличие ключа
ls -la ~/.ssh/id_ed25519_news.pub

# Создайте ключ если отсутствует
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_news -N ""
Ошибка: "CIDR has allocated addresses"
Нельзя изменить CIDR существующей подсети с активными ресурсами. Используйте terraform destroy и затем terraform apply.
Нет доступа к интернету с приватной ВМ
Проверrа настроек NAT:
# На NAT-инстансе
sudo sysctl net.ipv4.ip_forward
sudo iptables -t nat -L -n -v
Результаты
✅ VPC создана
✅ Публичная подсеть 192.168.10.0/24
✅ NAT-инстанс с адресом 192.168.10.254
✅ Публичная ВМ с доступом в интернет
✅ Приватная подсеть 192.168.20.0/24
✅ Route table с маршрутом через NAT
✅ Приватная ВМ с внутренним IP
✅ Доступ к приватной ВМ через публичную ВМ
✅ У приватной ВМ есть доступ в интернет через NAT

Настройка NAT-инстанса:

1. Проблема: Изначально приватная ВМ (192.168.20.29) недоступна 
   из публичной сети (100% packet loss) (09.png)

2. Решение: На NAT-инстансе выполнены следующие настройки:
   - Включена IP-маршрутизация (net.ipv4.ip_forward=1)
   - Настроен masquerading через iptables
   - Правила сохранены для перезагрузки (010.png)

3. Результат:
   - Приватная ВМ стала доступна (0% packet loss)
   - Появился доступ в интернет (ping 8.8.8.8 успешен)
   - Трафик выходит через IP NAT-инстанса (curl ifconfig.me 
     показывает 89.169.151.163 - внешний IP NAT-инстанса) (011.png)

Скриншот 010.png: "Прямой доступ в интернет с NAT-инстанса"
   ubuntu@fhm6b9urgnk4880dr5ng:~$ curl ifconfig.me
    89.169.151.163
Подпись: NAT-инстанс имеет собственный публичный IP 89.169.151.163

Скриншот 011.png: "Доступ в интернет через NAT с приватной ВМ"
  ubuntu@fhmp09p5s431qbdaule2:~$ curl ifconfig.me 
  111.88.246.171
Подпись: Приватная ВМ выходит в интернет через NAT, поэтому показывает внешний IP NAT-инстанса (111.88.246.171)

## Демонстрация работы NAT
1. **NAT-инстанс (публичная ВМ):**
   - Имеет собственный публичный IP: `89.169.151.163`
   - При запросе `curl ifconfig.me` возвращается его IP

2. **Приватная ВМ:**
   - Не имеет собственного публичного IP
   - Весь трафик маршрутизируется через NAT-инстанс
   - При запросе `curl ifconfig.me` возвращается IP NAT-инстанса (`111.88.246.171`)
   - Это доказывает, что трафик действительно проходит через NAT

3. **Вывод:** NAT работает корректно - приватная ВМ имеет доступ в интернет, 
     но её IP адрес скрыт за IP NAT-инстанса.

Автор
[Alex] - [sapr797]

Лицензия
MIT
