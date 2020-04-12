provider "aws" {
  version = "~> 2.0"
  region  = "eu-west-2"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_key_pair" "mad-key" {
  key_name = "mad"
  public_key = file(var.ssh_public_key_file)
}

module "api" {
  source = "./api"

  api_key_name = aws_key_pair.mad-key.key_name
  api_instance_type = "t2.micro"
  api_ami = data.aws_ami.ubuntu.id
  api_instance_count = 2

  api_lb_key_name = aws_key_pair.mad-key.key_name
  api_lb_instance_type = "t2.micro"
  api_lb_ami = data.aws_ami.ubuntu.id
}

module "web" {
  source = "./web"

  web_key_name = aws_key_pair.mad-key.key_name
  web_instance_type = "t2.micro"
  web_ami = data.aws_ami.ubuntu.id
  web_instance_count = 2
}

module "client" {
  source = "./client"

  client_key_name = aws_key_pair.mad-key.key_name
  client_instance_type = "t2.micro"
  client_ami = data.aws_ami.ubuntu.id
  client_instance_count = 2
}
