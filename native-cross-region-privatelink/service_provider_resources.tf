resource "aws_vpc" "service" {
  provider             = aws.provider
  cidr_block           = "10.10.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "service-vpc"
  }
}

resource "aws_subnet" "service" {
  provider                = aws.provider
  vpc_id                  = aws_vpc.service.id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "service-subnet"
  }
}

resource "aws_internet_gateway" "service" {
  provider = aws.provider
  vpc_id   = aws_vpc.service.id
}

resource "aws_route_table" "service" {
  provider = aws.provider
  vpc_id   = aws_vpc.service.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.service.id
  }
}

resource "aws_route_table_association" "service" {
  provider       = aws.provider
  subnet_id      = aws_subnet.service.id
  route_table_id = aws_route_table.service.id
}

resource "aws_security_group" "service_sg" {
  provider = aws.provider
  name     = "service-sg"
  vpc_id   = aws_vpc.service.id

  # allow SSH from consumer VPC subnet
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.11.1.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "service-sg"
  }
}

resource "aws_instance" "service" {
  provider               = aws.provider
  ami                    = "ami-0c94855ba95c71c99" # Amazon Linux 2 in us-east-1
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.service.id
  key_name               = "<YOUR-SSH-KEY-NAME>"
  vpc_security_group_ids = [aws_security_group.service_sg.id]
  tags = {
    Name = "service-ec2"
  }
}