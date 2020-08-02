provider "aws" {
  profile = "default"
  version = "~> 2.70"
  region = "us-east-2"
}
resource "aws_instance" "homework_EC2" {
  ami           = "ami-0a54aef4ef3b5f881"
  instance_type = "t2.micro"
  key_name      = "MyLaptop"
  subnet_id     =aws_subnet.homework_public_subnet.id
  associate_public_ip_address = true
  tags = {
    Name = "homework"
  }
  depends_on = [aws_internet_gateway.gw]
  connection {
    type = "ssh"
    user = "ec2-user"
    private_key = file("~/.ssh/id_rsa.pub")
    host = self.public_ip
  }
  provisioner "remote-exec" {
      inline =[
        "sudo yum update",
        "sudo yum install nginx -y",
        "sudo systemctl start nginx",
        "sudo systemctl enable nginx"
      ]
  }
}


resource "aws_vpc" "homework_VPC" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "homework_vpc"
  }
}
resource "aws_subnet" "homework_public_subnet" {
  vpc_id     = aws_vpc.homework_VPC.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "homework_subnet_pub"
  }
}
resource "aws_subnet" "homework_private_subnet" {
  vpc_id     = aws_vpc.homework_VPC.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "homework_subnet_private"
  }
}
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.homework_VPC.id

  tags = {
    Name = "homework_internetGw"
  }
}
resource "aws_route_table" "r" {
  vpc_id = aws_vpc.homework_VPC.id

  route {
    cidr_block = "10.0.1.0/24"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "homework_route_table"
  }
}
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.homework_public_subnet.id
  route_table_id = aws_route_table.r.id
}
resource "aws_security_group" "allow_tls" {
  name        = "homework_sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.homework_VPC.id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}