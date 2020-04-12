resource "aws_instance" "web" {
  ami = var.web_ami
  instance_type = var.web_instance_type
  count = var.web_instance_count

  key_name = var.web_key_name

  security_groups = [aws_security_group.web_security_group.name]

  tags = {
    Name = "web"
  }
}

resource "aws_security_group" "web_security_group" {
  name        = "web_security_group"
  description = "security group for the web console"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port = 80
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

resource "aws_elb" "web_load_balancer" {
  name               = "web-load-balancer"
  availability_zones = ["eu-west-2a"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  instances                   = aws_instance.web.*.id
  cross_zone_load_balancing   = false
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "web-load-balancer"
  }
}
