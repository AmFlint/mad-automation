resource "aws_instance" "client" {
  ami = var.client_ami
  instance_type = var.client_instance_type
  count = var.client_instance_count

  key_name = var.client_key_name

  security_groups = [aws_security_group.client_security_group.name]

  tags = {
    Name = "client"
  }
}

resource "aws_security_group" "client_security_group" {
  name        = "client_security_group"
  description = "security group for the client"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
