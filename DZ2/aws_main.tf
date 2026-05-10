# ============================================
# AWS Infrastructure
# ============================================

# Данные о текущем регионе и зонах доступности
data "aws_availability_zones" "available" {
  state = "available"
}

# Создание VPC
resource "aws_vpc" "main" {
  cidr_block           = var.aws_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "main-vpc"
  }
}

# Интернет-шлюз
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

# ============================================
# Публичная подсеть
# ============================================

# Публичная подсеть
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.aws_public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true  # Автоматическое присвоение публичного IP

  tags = {
    Name = "public-subnet"
  }
}

# Таблица маршрутизации для публичной подсети
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Привязка таблицы маршрутизации к публичной подсети
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ============================================
# Security Group
# ============================================

resource "aws_security_group" "main" {
  name        = "main-sg"
  description = "Allow SSH and ICMP"
  vpc_id      = aws_vpc.main.id

  # SSH доступ
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ICMP (ping)
  ingress {
    description = "ICMP from anywhere"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Исходящий трафик разрешен весь
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "main-security-group"
  }
}

# ============================================
# NAT Gateway (публичная подсеть)
# ============================================

# Elastic IP для NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "nat-eip"
  }
}

# NAT Gateway в публичной подсети
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "main-nat-gateway"
  }

  depends_on = [aws_internet_gateway.main]
}

# ============================================
# Приватная подсеть
# ============================================

# Приватная подсеть
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.aws_private_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "private-subnet"
  }
}

# Таблица маршрутизации для приватной подсети (трафик через NAT Gateway)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "private-route-table"
  }
}

# Привязка таблицы маршрутизации к приватной подсети
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# ============================================
# Виртуальные машины (EC2)
# ============================================

# SSH ключ (используем существующий публичный ключ)
resource "aws_key_pair" "main" {
  key_name   = "main-key"
  public_key = file(var.public_ssh_key_path)
}

# Публичная ВМ (бастион-хост)
resource "aws_instance" "public_vm" {
  ami                    = var.aws_ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.main.id]
  key_name               = aws_key_pair.main.key_name

  associate_public_ip_address = true

  tags = {
    Name = "public-vm"
  }
}

# Приватная ВМ (без публичного IP)
resource "aws_instance" "private_vm" {
  ami                    = var.aws_ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.main.id]
  key_name               = aws_key_pair.main.key_name

  associate_public_ip_address = false

  tags = {
    Name = "private-vm"
  }
}
