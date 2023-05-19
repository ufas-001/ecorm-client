terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>4.0"
    }
  }
}

provider "aws" {
  region     = "us-east-1"  # Replace with your desired AWS region
  /* access_key = var.aws_access_key
  secret_key = var.aws_secret_key */
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_vpc" "main" {
  default = true
}

data "aws_subnets" "main" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
}

resource "aws_security_group" "ecorm_client_sg" {
  name        = "ecorm client sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = data.aws_vpc.main.id

  ingress = [{
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    self             = false
    security_groups  = []
    }, {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    self             = false
    security_groups  = []
    }

  ]

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "ecorm_client_sg"
  }
}

resource "aws_instance" "ecorm_client" {
  ami           = data.aws_ami.ubuntu.id
  vpc_security_group_ids = [ aws_security_group.ecorm_client_sg.id ]
  key_name = "terraformkey"
  instance_type = "t2.micro"
  tags = {
    Name = "ecorm-client"
  }
}

output "ec2_instance_ip" {
  value = aws_instance.ecorm_client.public_ip
}