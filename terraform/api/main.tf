resource "aws_instance" "api" {
  ami = var.api_ami
  instance_type = var.api_instance_type
  count = var.api_instance_count

  key_name = var.api_key_name

  security_groups = [aws_security_group.api_security_group.name]

  tags = {
    Name = "api"
  }
}

resource "aws_security_group" "api_security_group" {
  name        = "api_security_group"
  description = "security group for the APIs"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 3000
    to_port = 3000
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

resource "aws_eip" "api_load_balancer_ip" {
  instance = aws_instance.api_load_balancer.id
}

resource "aws_instance" "api_load_balancer" {
  ami = var.api_lb_ami
  instance_type = var.api_lb_instance_type

  key_name = var.api_lb_key_name

  security_groups = [aws_security_group.api-load-balancer.name]

  tags = {
    Name = "api_lb"
  }
}

resource "aws_security_group" "api-load-balancer" {
  name        = "api_lb_security_group"
  description = "security group for APIs Load balancer"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // Allow APIs to communicate to redis service
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

// REDIS

resource "aws_elasticache_cluster" "api-redis" {
  cluster_id           = "api-redis"
  engine               = "redis"
  node_type            = var.api_redis_cache_type
  num_cache_nodes      = var.api_redis_node_count
  parameter_group_name = "default.redis3.2"
  engine_version       = var.api_redis_version
  port                 = var.api_redis_port
  security_group_ids = [aws_security_group.api-redis.id]
}

resource "aws_security_group" "api-redis" {
  name        = "api_redis_security_group"
  description = "security group for Redis"

  // Allow APIs to communicate to redis service
  ingress {
    from_port = var.api_redis_port
    to_port = var.api_redis_port
    protocol = "tcp"
    security_groups = [aws_security_group.api_security_group.id]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
