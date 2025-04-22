resource "aws_vpc" "consumer" {
  provider             = aws.consumer
  cidr_block           = "10.11.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "consumer-vpc" }
}

resource "aws_subnet" "consumer" {
  provider                = aws.consumer
  vpc_id                  = aws_vpc.consumer.id
  cidr_block              = "10.11.1.0/24"
  availability_zone       = "eu-west-1a"
  map_public_ip_on_launch = true
  tags                    = { Name = "consumer-subnet" }
}

resource "aws_internet_gateway" "consumer" {
  provider = aws.consumer
  vpc_id   = aws_vpc.consumer.id
}

resource "aws_route_table" "consumer" {
  provider = aws.consumer
  vpc_id   = aws_vpc.consumer.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.consumer.id
  }
}

resource "aws_route_table_association" "consumer" {
  provider       = aws.consumer
  subnet_id      = aws_subnet.consumer.id
  route_table_id = aws_route_table.consumer.id
}

resource "aws_security_group" "consumer_sg" {
  provider = aws.consumer
  name     = "consumer-sg"
  vpc_id   = aws_vpc.consumer.id

  # allow SSH to the endpoint's ENIs
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

  tags = { Name = "consumer-sg" }
}

resource "aws_instance" "consumer" {
  provider               = aws.consumer
  ami                    = "ami-04169656fea786776"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.consumer.id
  key_name               = "<YOUR-SSH-KEY-NAME>"
  vpc_security_group_ids = [aws_security_group.consumer_sg.id]
  tags                   = { Name = "consumer-ec2" }
}

resource "aws_vpc_endpoint" "consumer_endpoint" {
  provider            = aws.consumer
  vpc_id              = aws_vpc.consumer.id
  subnet_ids          = [aws_subnet.consumer.id]
  vpc_endpoint_type   = "Interface"
  service_name        = aws_vpc_endpoint_service.privatelink.service_name
  security_group_ids  = [aws_security_group.consumer_sg.id]
  private_dns_enabled = false
}