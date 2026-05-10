# Provider configuration
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                      = "eu-north-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true  
endpoints {
    ec2 = "http://localhost:4566"
   # vpc        = "http://localhost:4566"
    iam        = "http://localhost:4566"
    sts        = "http://localhost:4566"
    route53    = "http://localhost:4566"
  }
}

# Data source for local public IP (для security groups)
data "http" "myip" {
  url = "https://api.ipify.org"
}

# SSH ключ из файла
resource "aws_key_pair" "deployer" {
  key_name   = "${var.project_name}-${var.environment}-key"
  public_key = file(var.public_key_path)
}

# 1. VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-vpc"
    Environment = var.environment
    Project     = var.project_name
  }
}

# 2. Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}

# 3. Публичная подсеть
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-${var.environment}-public-subnet"
  }
}

# 4. Приватная подсеть
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.availability_zone

  tags = {
    Name = "${var.project_name}-${var.environment}-private-subnet"
  }
}

# 5. Elastic IP для NAT Gateway
#resource "aws_eip" "nat" {
  #domain = "vpc"

  #tags = {
    #Name = "${var.project_name}-${var.environment}-nat-eip"
  #}
#}

# 6. NAT Gateway (в публичной подсети)
#resource "aws_nat_gateway" "main" {
  #allocation_id = aws_eip.nat.id
  #subnet_id     = aws_subnet.public.id

  #tags = {
    #Name = "${var.project_name}-${var.environment}-nat-gw"
  #}

  #depends_on = [aws_internet_gateway.main]
#}

# 7. Route table для публичной подсети (через IGW)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-public-rt"
  }
}

# 8. Route table для приватной подсети (через NAT Gateway)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  #route {
    #cidr_block     = "0.0.0.0/16"
    #gateway_id = "local" # Локальный маршрут внутри VPC
    #nat_gateway_id = aws_nat_gateway.main.id
  #}

  tags = {
    Name = "${var.project_name}-${var.environment}-private-rt"
  }
}

# 9. Ассоциация route tables с подсетями
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# 10. Security Group для публичной ВМ (бастион)
resource "aws_security_group" "public_vm" {
  name        = "${var.project_name}-${var.environment}-public-sg"
  description = "Security group for public VM"
  vpc_id      = aws_vpc.main.id

  # SSH доступ
  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]
  }

  # Исходящий трафик разрешен весь
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-public-sg"
  }
}

# 11. Security Group для приватной ВМ
resource "aws_security_group" "private_vm" {
  name        = "${var.project_name}-${var.environment}-private-sg"
  description = "Security group for private VM"
  vpc_id      = aws_vpc.main.id

  # SSH доступ ТОЛЬКО из публичной ВМ
  ingress {
    description     = "SSH from public VM"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.public_vm.id]
  }

  # Исходящий трафик разрешен весь (через NAT)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-private-sg"
  }
}

# 12. Публичная ВМ (бастион-хост)
resource "aws_instance" "public_vm" {
  ami                    = var.ami_id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.public_vm.id]
  subnet_id              = aws_subnet.public.id
  associate_public_ip_address = true

  tags = {
    Name = "${var.project_name}-${var.environment}-public-vm"
  }
}

# 13. Приватная ВМ (без публичного IP)
resource "aws_instance" "private_vm" {
  ami                    = var.ami_id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.private_vm.id]
  subnet_id              = aws_subnet.private.id
  associate_public_ip_address = false

  tags = {
    Name = "${var.project_name}-${var.environment}-private-vm"
  }
}

# Для приватной ВМ нужно будет создать VPC Endpoint для SSM
# чтобы иметь возможность подключаться без публичного IP
resource "aws_vpc_endpoint" "ssm" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.private.id]
  security_group_ids = [aws_security_group.private_vm.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.project_name}-${var.environment}-ssm-endpoint"
  }
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.private.id]
  security_group_ids = [aws_security_group.private_vm.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.project_name}-${var.environment}-ssmmessages-endpoint"
  }
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.private.id]
  security_group_ids = [aws_security_group.private_vm.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.project_name}-${var.environment}-ec2messages-endpoint"
  }
}
