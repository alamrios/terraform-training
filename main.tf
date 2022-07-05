terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.21.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.13.0"
    }
  }
}

provider "aws" {
    region = "us-east-1"
}

provider "docker" {}

variable "ssh_key_path" {}
variable "vpc_id" {}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file(var.ssh_key_path)
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
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
    Name = "allow_ssh"
  }
}

resource "aws_instance" "terraform_test" {
    ami = "ami-0439517b5e436bdab" # Ubuntu Focal LTS
    instance_type = "t3.micro"
    tags = {
      "Name" = "terraform-test-instance"
    }
    key_name = aws_key_pair.deployer.key_name
    vpc_security_group_ids = [
        aws_security_group.allow_ssh.id
    ]
}

#resource "aws_vpc" "terraform_vpc" {
#    cidr_block = "172.31.0.0/16"
#}

resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = false
}

resource "docker_container" "nginx" {
  image = docker_image.nginx.latest
  name  = "tutorial"
  ports {
    internal = 80
    external = 8000
  }
}

output "ip_instance" {
  value = aws_instance.terraform_test.public_ip
}

output "ssh" {
  value = "ssh -l ubuntu ${aws_instance.terraform_test.public_ip}"
}
