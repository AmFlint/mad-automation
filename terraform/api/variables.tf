variable "api_instance_type" {
  type = string
  default = "t2.micro"
  description = "Instance type to use for API instances"
}

variable "api_instance_count" {
  type = number
  default = 1
  description = "Number of instances to create for the API"
}

variable "api_ami" {
  type = string
  description = "Image to use for API instances (e.g. Ubuntu, Debian)"
}

variable "api_key_name" {
  type = string
  description = "AWS Key name (SSH) to use for the API instances"
}

// API Load Balancer

variable "api_lb_instance_type" {
  type = string
  default = "t2.micro"
  description = "Instance type to use for API instances"
}

variable "api_lb_ami" {
  type = string
  description = "Image to use for API instances (e.g. Ubuntu, Debian)"
}

variable "api_lb_key_name" {
  type = string
  description = "AWS Key name (SSH) to use for the API instances"
}

// REDIS

variable "api_redis_cache_type" {
  type = string
  default = "cache.t2.micro"
  description = "Cache type (machines) to use for Redis back-end"
}

variable "api_redis_node_count" {
  type = string
  default = 1
  description = "Number of nodes to use for Redis instance"
}

variable "api_redis_port" {
  type = number
  default = 6379
  description = "Port on which Redis Server should listen"
}

variable "api_redis_version" {
  type = string
  default = "3.2.10"
  description = "Version of Redis"
}
